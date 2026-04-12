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

# Wrapper: run command, save exit code
run_model() {
  local name="$1"; shift
  "$@" > "$TMPDIR/$name.txt" 2>/dev/null
  echo $? > "$TMPDIR/$name.exit"
}

run_model gemini gemini "$PROMPT" &
PID_G=$!
run_model codex codex exec "$PROMPT" &
PID_C=$!
run_model claude claude -p "$PROMPT" &
PID_CL=$!

# Wait for first SUCCESS (exit 0 + non-empty output)
while true; do
  for model in gemini codex claude; do
    if [ -f "$TMPDIR/$model.exit" ]; then
      EXIT_CODE=$(cat "$TMPDIR/$model.exit")
      if [ "$EXIT_CODE" -eq 0 ] && [ -s "$TMPDIR/$model.txt" ]; then
        echo "Winner: $model"
        cat "$TMPDIR/$model.txt"
        kill $PID_G $PID_C $PID_CL 2>/dev/null
        wait 2>/dev/null
        exit 0
      fi
    fi
  done

  # Check if all failed
  if [ -f "$TMPDIR/gemini.exit" ] && [ -f "$TMPDIR/codex.exit" ] && [ -f "$TMPDIR/claude.exit" ]; then
    echo "All models failed" >&2
    exit 1
  fi
  sleep 0.1
done
```

### Cascade (Filter → Deep)

Fast model filters, quality model analyzes.

```bash
# Step 1: Fast filter with Gemini (free) - stdin avoids argv limits
ISSUES=$(gemini "List potential issues in this code, one per line:" < code.py)

# Step 2: If issues found, deep analysis with Claude (use heredoc for safety)
if [ -n "$ISSUES" ]; then
  claude -p "Analyze these issues in detail:" --model opus <<< "$ISSUES"
else
  echo "No issues found"
fi
```

## Feeding Files and Directories

### Stdin Behavior

All three tools support stdin with positional prompts:

| Tool | `"prompt" < file` | `< file` (no prompt arg) |
|------|-------------------|--------------------------|
| Gemini | File content appended as context ✅ | File content becomes prompt ✅ |
| Claude | File content appended as context ✅ | File content becomes prompt ✅ |
| Codex | File appended as `<stdin>` block ✅ | File content becomes prompt ✅ |

### Single File

```bash
# All three tools support stdin with positional prompts
gemini "Review:" < file.py
codex exec "Review:" < file.py
claude -p "Review:" < file.py
```

### Multiple Files with Headers

```bash
# All tools support piped stdin with positional prompts
find src -name "*.py" -exec sh -c 'echo "=== {} ==="; cat {}' \; | gemini "Review:"
find src -name "*.py" -exec sh -c 'echo "=== {} ==="; cat {}' \; | codex exec "Review:"
find src -name "*.py" -exec sh -c 'echo "=== {} ==="; cat {}' \; | claude -p "Review:"

# Using bash glob (simpler but less control)
for f in src/**/*.py; do echo "=== $f ==="; cat "$f"; done | gemini "Review:"
```

### Smart File Collection

```bash
# Exclude tests, vendor, generated files
find src -name "*.py" \
  ! -path "*/test*" \
  ! -path "*/vendor/*" \
  ! -path "*/__pycache__/*" \
  ! -name "*.generated.*" \
  -exec sh -c 'echo "=== {} ==="; cat {}' \; > /tmp/src-bundle.txt

# Check size before sending
CHARS=$(wc -c < /tmp/src-bundle.txt)
TOKENS=$((CHARS / 4))
echo "Estimated: ${TOKENS} tokens"

# Route to appropriate model based on size
if [ "$TOKENS" -gt 200000 ]; then
  echo "Large codebase, using 1M-context model..."
  gemini "Review this codebase for bugs and improvements:" < /tmp/src-bundle.txt
else
  claude -p "Review this codebase:" --model opus < /tmp/src-bundle.txt
fi
```

### Git-Aware File Selection

```bash
# Only changed files (great for PR review)
git diff --name-only main | xargs -I{} sh -c 'echo "=== {} ==="; cat {}' | \
  gemini "Review these changes:"

# Changed files with diff context
git diff main | codex exec "Review this diff for bugs:"

# Recently modified files
find src -name "*.py" -mtime -7 \
  -exec sh -c 'echo "=== {} ==="; cat {}' \; | gemini "Review recent changes:"

# Staged files only
git diff --cached | claude -p "Review staged changes:" --model opus

# Codex dedicated code review (reviews current repo)
codex exec review
```

### Git-Diff as Input (PR Review)

```bash
# All tools support piped diff directly
git diff main | gemini "Review this diff for bugs:"
git diff main | codex exec "Review this diff for bugs:"
git diff main | claude -p "Review:" --model opus
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
# Note: codex --json outputs JSONL (one event per line), not single JSON

# Parse with jq
jq '.bugs[] | .severity' bugs.json

# Pass to another model (use stdin for safety)
claude -p "Prioritize these bugs:" --model opus < bugs.json
```

### Passing Context Between Tools

```bash
# Model A analyzes (stdin for file content)
ANALYSIS=$(gemini "Analyze architecture:" < design.md)

# Model B reviews analysis
REVIEW=$(codex exec "Review this analysis:" <<< "$ANALYSIS")

# Model C synthesizes (use temp file for multiple large vars)
{ echo "=== Analysis ==="; echo "$ANALYSIS"; echo "=== Review ==="; echo "$REVIEW"; } > /tmp/context.txt
claude -p "Synthesize these:" --model opus < /tmp/context.txt
```

## Budget Optimization

### Free Tier First Strategy

```bash
# Always try Gemini first (free tier)
RESULT=$(gemini "$PROMPT" 2>/dev/null)

# Only escalate if needed
if [ $? -ne 0 ] || [ -z "$RESULT" ]; then
  RESULT=$(codex exec "$PROMPT")  # Cheaper than gpt-5
fi

echo "$RESULT"
```

### Cost-Aware Routing

```bash
# Estimate token count (~0.75 tokens per word)
WORDS=$(wc -w <<< "$CONTENT")

if [ "$WORDS" -lt 1000 ]; then
  # Small content: use free Gemini
  gemini "$PROMPT"
elif [ "$WORDS" -lt 130000 ]; then
  # Medium (<~100K tokens): any model works
  codex exec "$PROMPT"
else
  # Large (>100K tokens): use 1M-context models
  # Gemini (free) or Codex gpt-5.4 (922K input)
  gemini "$PROMPT"
fi
```

### Context-Aware Model Selection

All three tools support ~1M token context windows (Gemini, Codex gpt-5.4, Claude Opus/Sonnet 4.6). Route large inputs accordingly:

```bash
#!/bin/bash
# context_route.sh - Pick model based on input size
INPUT_FILE="$1"
PROMPT="$2"

# Estimate tokens (~0.75 tokens per word, ~4 chars per token)
CHARS=$(wc -c < "$INPUT_FILE")
EST_TOKENS=$((CHARS / 4))

if [ "$EST_TOKENS" -gt 150000 ]; then
  # Large input: must use 1M-context model
  echo "Large input (~${EST_TOKENS} tokens), using 1M-context model..."
  gemini "$PROMPT" < "$INPUT_FILE" || \
    codex exec -m gpt-5.4 "$PROMPT" < "$INPUT_FILE"
elif [ "$EST_TOKENS" -gt 50000 ]; then
  # Medium: Gemini or Claude (both support stdin)
  gemini "$PROMPT" < "$INPUT_FILE"
else
  # Small: any model works, prefer free
  gemini "$PROMPT" < "$INPUT_FILE"
fi
```

**For full-repo review**, concatenate relevant files and use a 1M-context model:

```bash
# Concatenate source files for full-repo review
find src -name "*.py" -exec cat {} + > /tmp/all-src.txt
gemini "Review this codebase for bugs and improvements:" < /tmp/all-src.txt
# Or with Codex for code-specialized review
codex exec -m gpt-5.4 "Review this codebase:" < /tmp/all-src.txt
```

### Complexity-Based Routing (3-Tier)

Route tasks to appropriate model tier based on complexity, not just size.

**Tier 1 - Fast/Cheap** (simple tasks):
- Syntax checks, formatting, simple validation
- Use: `gemini -m flash`, `claude --model haiku`, `codex exec`

**Tier 2 - Balanced** (medium complexity):
- Code review, refactoring suggestions, documentation
- Use: `gemini -m pro`, `claude --model sonnet`, `codex exec -m gpt-5.4`

**Tier 3 - Quality** (complex reasoning):
- Architecture decisions, security audits, complex debugging
- Use: `gemini -m pro`, `claude --model opus --effort max`, `codex exec -m o3`

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

### Session Reuse (Keep Context Alive)

All three tools support session persistence. Use this to build up codebase context once, then ask follow-up questions without re-sending files.

**Gemini sessions:**

```bash
# Start a review session - Gemini learns your codebase
gemini "Review the architecture of this project"

# Later, resume the same session (keeps all context)
gemini -r latest "Now focus on the error handling patterns"

# Or resume by index or UUID
gemini --list-sessions              # See all saved sessions
gemini -r 3 "What about the tests?" # Resume session #3
gemini --delete-session 5           # Clean up old sessions

# Sessions retained 30 days by default
```

**Codex sessions:**

```bash
# Interactive session builds context
codex  # Start interactive, explore codebase

# Resume later with full context preserved
codex resume

# Fork a session to explore a tangent without losing the original
codex fork

# Non-interactive sessions can also be resumed
codex exec "Review src/" && codex exec resume "Now check the tests"
```

**Claude sessions:**

```bash
# Continue most recent conversation
claude -c "Follow up on the review"

# Resume specific session by ID
claude -r <session-id> "What about the auth module?"
```

### Session Strategy for Large Reviews

Use sessions to avoid re-uploading large codebases:

```bash
# Step 1: Load codebase into session (use 1M-context model)
find src -name "*.py" -exec cat {} + | gemini -i "Learn this codebase. Summarize the architecture."
# -i flag: execute prompt then stay interactive for follow-ups

# Step 2: Ask targeted questions within same session (context preserved)
# (interactive mode continues, or resume later with -r latest)

# Step 3: Resume days later, context still there
gemini -r latest "Are there any race conditions in the async handlers?"
```

### Multi-Turn with Single Model

For extended conversations, use session mode:

```bash
# Codex session (maintains context)
codex  # Enters interactive mode

# Claude conversation
claude  # Starts new session with history

# Gemini with initial prompt then interactive
gemini -i "Review this project for security issues"
```

### Handoff Between Models

```bash
# Start with fast model for initial analysis (stdin for file)
INITIAL=$(gemini "Summarize:" < data.txt)

# Hand off to reasoning model for deep analysis
DEEP=$(codex exec -m o3 "Given this summary, what are the implications?" <<< "$INITIAL")

# Final synthesis with quality model (heredoc for safety)
claude -p "Create final report from:" --model opus <<< "$DEEP"
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

## Web Search Grounding

Both Gemini and Codex have built-in web search for real-time information.

```bash
# Gemini - Google Search grounding (built-in tool, auto-used)
gemini "What are the latest security advisories for Django 5.x?"

# Codex - web search (explicit flag)
codex exec --search "What's the recommended way to handle auth in Next.js 15?"

# Combine: research with web, then code with context
RESEARCH=$(gemini "Latest best practices for Python async error handling")
{ echo "$RESEARCH"; cat async_handler.py; } | codex exec "Apply these practices to our code:"
```

## MCP Server Sharing

All three tools support MCP (Model Context Protocol) servers. Configure once, use across tools.

```bash
# Codex MCP management
codex mcp add my-server --command "node server.js"
codex mcp list
codex mcp remove my-server

# Gemini MCP (via extensions)
gemini  # then /mcp to manage

# Claude MCP (via config)
claude --mcp-config mcp-servers.json -p "Use the database tool to query users"

# Run Codex itself as an MCP server for other tools
codex mcp-server  # experimental
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
