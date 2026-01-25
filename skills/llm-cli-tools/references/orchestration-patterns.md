# Advanced Orchestration Patterns

Detailed patterns for multi-model LLM orchestration.

## Parallel Execution Patterns

### Fire-and-Wait (Consensus)

Run all models in parallel, wait for all, synthesize results.

```bash
#!/bin/bash
PROMPT="$1"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT INT TERM

# Fire all models
gemini "$PROMPT" > "$TMPDIR/gemini.txt" 2>&1 &
PID_G=$!
codex exec "$PROMPT" > "$TMPDIR/codex.txt" 2>&1 &
PID_C=$!
claude -p "$PROMPT" --model sonnet > "$TMPDIR/claude.txt" 2>&1 &
PID_CL=$!

# Wait and check exit status
wait $PID_G; ST_G=$?
wait $PID_C; ST_C=$?
wait $PID_CL; ST_CL=$?

[ $ST_G -ne 0 ] && echo "Warning: Gemini failed (exit $ST_G)"
[ $ST_C -ne 0 ] && echo "Warning: Codex failed (exit $ST_C)"
[ $ST_CL -ne 0 ] && echo "Warning: Claude failed (exit $ST_CL)"

# Results available in $TMPDIR
echo "=== Gemini ===" && cat "$TMPDIR/gemini.txt"
echo "=== Codex ===" && cat "$TMPDIR/codex.txt"
echo "=== Claude ===" && cat "$TMPDIR/claude.txt"
```

### Race (First Wins)

Use first successful response, cancel others.

```bash
#!/bin/bash
PROMPT="$1"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT INT TERM

# Each model writes to its own file (avoids clobbering)
gemini "$PROMPT" > "$TMPDIR/gemini.txt" 2>/dev/null &
PID_G=$!
codex exec "$PROMPT" > "$TMPDIR/codex.txt" 2>/dev/null &
PID_C=$!
claude -p "$PROMPT" > "$TMPDIR/claude.txt" 2>/dev/null &
PID_CL=$!

# Wait for first to complete with content
while true; do
  for model in gemini codex claude; do
    if [ -s "$TMPDIR/$model.txt" ]; then
      echo "Winner: $model"
      cat "$TMPDIR/$model.txt"
      kill $PID_G $PID_C $PID_CL 2>/dev/null
      exit 0
    fi
  done
  sleep 0.1
done
```

### Cascade (Filter → Deep)

Fast model filters, quality model analyzes.

```bash
# Step 1: Fast filter with Gemini (free) - stdin avoids argv limits
ISSUES=$(gemini "List potential issues in this code, one per line:" < code.py)

# Step 2: If issues found, deep analysis with Claude
if [ -n "$ISSUES" ]; then
  claude -p "Analyze these issues in detail: $ISSUES" --model opus
else
  echo "No issues found"
fi
```

## Context Management

### Stdin for Large Content

```bash
# Use stdin directly - avoids argv limits and temp file management
gemini "Analyze this code:" < largefile.py

# Or use here-string for variables
gemini "Analyze:" <<< "$CONTENT"
```

### JSON Output for Structured Results

```bash
# Get structured output (stdin for large files)
gemini -o json "Find bugs:" < code.py > bugs.json
# Claude uses --output-format json

# Parse with jq
jq '.bugs[] | .severity' bugs.json

# Pass to another model
BUGS=$(cat bugs.json)
claude -p "Prioritize these bugs: $BUGS" --model opus
```

### Passing Context Between Tools

```bash
# Model A analyzes (stdin for file content)
ANALYSIS=$(gemini "Analyze architecture:" < design.md)

# Model B reviews analysis
REVIEW=$(codex exec "Review this analysis: $ANALYSIS")

# Model C synthesizes
claude -p "Synthesize: Analysis=$ANALYSIS Review=$REVIEW" --model opus
```

## Budget Optimization

### Free Tier First Strategy

```bash
# Always try Gemini first (free tier)
RESULT=$(gemini "$PROMPT" 2>/dev/null)

# Only escalate if needed
if [ $? -ne 0 ] || [ -z "$RESULT" ]; then
  RESULT=$(codex exec -m gpt-4o "$PROMPT")  # Cheaper than gpt-5
fi

echo "$RESULT"
```

### Cost-Aware Routing

```bash
# Estimate complexity
TOKENS=$(wc -w <<< "$CONTENT")

if [ "$TOKENS" -lt 1000 ]; then
  # Small content: use free Gemini
  gemini "$PROMPT"
elif [ "$TOKENS" -lt 100000 ]; then
  # Medium: use fast models
  codex exec -m gpt-4o "$PROMPT"
else
  # Large: must use Gemini (1M context)
  gemini "$PROMPT"
fi
```

### Complexity-Based Routing (3-Tier)

Route tasks to appropriate model tier based on complexity, not just size.

**Tier 1 - Fast/Cheap** (simple tasks):
- Syntax checks, formatting, simple validation
- Use: `gemini -m flash`, `claude --model haiku`, `codex exec`

**Tier 2 - Balanced** (medium complexity):
- Code review, refactoring suggestions, documentation
- Use: `gemini -m pro`, `claude --model sonnet`, `codex exec -m gpt-5.2`

**Tier 3 - Quality** (complex reasoning):
- Architecture decisions, security audits, complex debugging
- Use: `gemini -m pro`, `claude --model opus`, `codex exec -m o3`

```bash
#!/bin/bash
# complexity_route.sh - Route based on task complexity

TASK_TYPE="$1"
PROMPT="$2"

case "$TASK_TYPE" in
  "format"|"lint"|"validate"|"simple")
    # Tier 1: Fast/cheap
    gemini -m flash "$PROMPT" || claude -p "$PROMPT" --model haiku
    ;;
  "review"|"refactor"|"document"|"medium")
    # Tier 2: Balanced
    claude -p "$PROMPT" --model sonnet
    ;;
  "security"|"architecture"|"debug"|"complex")
    # Tier 3: Quality - use reasoning model
    codex exec -m o3 "$PROMPT" || claude -p "$PROMPT" --model opus
    ;;
  *)
    # Default: balanced
    claude -p "$PROMPT" --model sonnet
    ;;
esac
```

**Auto-detect complexity** (heuristic):

```bash
detect_complexity() {
  local prompt="$1"

  # Tier 3 keywords
  if echo "$prompt" | grep -qiE "security|vulnerability|architect|design|debug|why|explain.*complex"; then
    echo "complex"
    return
  fi

  # Tier 1 keywords
  if echo "$prompt" | grep -qiE "format|lint|syntax|typo|simple|quick"; then
    echo "simple"
    return
  fi

  # Default: medium
  echo "medium"
}

COMPLEXITY=$(detect_complexity "$PROMPT")
./complexity_route.sh "$COMPLEXITY" "$PROMPT"
```

### Quota Tracking

Track usage to avoid hitting limits:

```bash
# Simple counter file with in-place update (avoids duplicate lines)
QUOTA_FILE=~/.llm-quota
TODAY=$(date +%Y-%m-%d)

# Read current count
COUNT=$(grep "^$TODAY:" "$QUOTA_FILE" 2>/dev/null | tail -1 | cut -d: -f2 || echo 0)
COUNT=$((COUNT + 1))

# Update in place or append
if grep -q "^$TODAY:" "$QUOTA_FILE" 2>/dev/null; then
  sed -i '' "s/^$TODAY:.*/$TODAY:$COUNT/" "$QUOTA_FILE"
else
  echo "$TODAY:$COUNT" >> "$QUOTA_FILE"
fi

# Warn if high
if [ "$COUNT" -gt 100 ]; then
  echo "Warning: High usage today ($COUNT calls)"
fi
```

## Session Patterns

### Multi-Turn with Single Model

For extended conversations, use session mode:

```bash
# Codex session (maintains context)
codex  # Enters interactive mode

# Claude conversation
claude  # Starts new session with history
```

### Handoff Between Models

```bash
# Start with fast model for initial analysis (stdin for file)
INITIAL=$(gemini "Summarize:" < data.txt)

# Hand off to reasoning model for deep analysis
DEEP=$(codex exec -m o3 "Given this summary: $INITIAL, what are the implications?")

# Final synthesis with quality model
claude -p "Create final report from: $DEEP" --model opus
```

### Context Preservation Across Models

```bash
# Save conversation context
CONTEXT_FILE=~/.llm-context

# Each model adds to context (stdin for file input)
gemini "Analyze:" < code.py | tee -a "$CONTEXT_FILE"
echo "---" >> "$CONTEXT_FILE"

codex exec "Review:" < code.py | tee -a "$CONTEXT_FILE"
echo "---" >> "$CONTEXT_FILE"

# Final model sees all previous context
claude -p "Synthesize previous analyses:" --model opus < "$CONTEXT_FILE"
```

## Error Handling

### Retry with Exponential Backoff

```bash
# Pass command directly (no eval, safer)
retry_with_backoff() {
  local max_attempts=3
  local delay=1

  for ((i=1; i<=max_attempts; i++)); do
    "$@" && return 0
    echo "Attempt $i failed, waiting ${delay}s..."
    sleep $delay
    delay=$((delay * 2))
  done
  return 1
}

# Usage: pass command as separate args, not quoted string
retry_with_backoff gemini "prompt"
```

### Graceful Degradation

```bash
# Try best model, fall back gracefully
get_response() {
  local prompt="$1"

  # Try Claude opus first
  claude -p "$prompt" --model opus 2>/dev/null && return 0

  # Fall back to Codex
  codex exec "$prompt" 2>/dev/null && return 0

  # Fall back to Gemini
  gemini "$prompt" 2>/dev/null && return 0

  # All failed
  echo "Error: All models unavailable"
  return 1
}
```

### Timeout Handling

```bash
# Run with timeout (GNU coreutils)
timeout 30 gemini "prompt" || echo "Gemini timed out"

# Parallel with individual timeouts
timeout 30 gemini "prompt" > /tmp/g.txt &
timeout 45 codex exec "prompt" > /tmp/c.txt &
wait
```

**macOS note:** `timeout` requires coreutils (`brew install coreutils`, then use `gtimeout`). Alternative without coreutils:

```bash
# Timeout alternative for macOS (no coreutils)
( gemini "prompt" ) & PID=$!
( sleep 30; kill $PID 2>/dev/null ) &
wait $PID
```

## Validation Patterns

### Cross-Model Validation

```bash
# Get answers from two models
A=$(gemini "What is 2+2?")
B=$(codex exec "What is 2+2?")

# Compare
if [ "$A" = "$B" ]; then
  echo "Validated: $A"
else
  echo "Disagreement: Gemini=$A, Codex=$B"
  # Use third model as tiebreaker
  claude -p "Gemini says '$A', Codex says '$B'. Which is correct?" --model opus
fi
```

### Confidence Scoring

```bash
# Ask models to rate confidence (stdin for file)
gemini -o json "Rate your confidence (0-100) in this code review:" < code.py > /tmp/g.json
codex exec --json "Rate your confidence (0-100) in this code review:" < code.py > /tmp/c.json

# Parse and compare
G_CONF=$(jq '.confidence' /tmp/g.json)
C_CONF=$(jq '.confidence' /tmp/c.json)

echo "Gemini confidence: $G_CONF%"
echo "Codex confidence: $C_CONF%"
```

### Confidence Escalation

If a fast model reports low confidence, automatically escalate to a more capable model.

```bash
#!/bin/bash
# confidence_escalate.sh - Escalate on low confidence

PROMPT="$1"
THRESHOLD=${2:-70}  # Default: escalate if <70% confident
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT INT TERM

# Step 1: Try fast model with confidence request
gemini -o json "Answer this and rate your confidence 0-100:
$PROMPT
Respond as JSON: {\"answer\": \"...\", \"confidence\": N}" > "$TMPDIR/fast.json" 2>/dev/null

CONFIDENCE=$(jq -r '.confidence // 0' "$TMPDIR/fast.json" 2>/dev/null)
ANSWER=$(jq -r '.answer // empty' "$TMPDIR/fast.json" 2>/dev/null)

# Step 2: Check confidence threshold
if [ -n "$CONFIDENCE" ] && [ "$CONFIDENCE" -ge "$THRESHOLD" ]; then
  echo "Fast model confident ($CONFIDENCE%): $ANSWER"
  exit 0
fi

echo "Low confidence ($CONFIDENCE%), escalating to opus..."

# Step 3: Escalate to quality model
claude -p "$PROMPT" --model opus
```

**Multi-tier escalation chain:**

```bash
#!/bin/bash
# escalation_chain.sh - Progressive escalation

PROMPT="$1"
THRESHOLD=70

# Tier 1: Free/fast
echo "Trying Gemini flash..."
RESULT=$(gemini -o json "Rate confidence 0-100 and answer: $PROMPT" 2>/dev/null)
CONF=$(echo "$RESULT" | jq -r '.confidence // 0')

if [ "$CONF" -ge "$THRESHOLD" ]; then
  echo "$RESULT" | jq -r '.answer'
  exit 0
fi

# Tier 2: Balanced
echo "Escalating to Sonnet (confidence was $CONF%)..."
RESULT=$(claude -p "Rate confidence 0-100 and answer: $PROMPT" --model sonnet --output-format json 2>/dev/null)
CONF=$(echo "$RESULT" | jq -r '.confidence // 0')

if [ "$CONF" -ge "$THRESHOLD" ]; then
  echo "$RESULT" | jq -r '.answer'
  exit 0
fi

# Tier 3: Quality (final)
echo "Escalating to Opus (confidence was $CONF%)..."
claude -p "$PROMPT" --model opus
```

**When to use confidence escalation:**
- Code review where mistakes are costly
- Security analysis requiring thoroughness
- Decisions with downstream impact
- When fast models frequently say "I'm not sure"
