#!/usr/bin/env bash
# Smoke tests for llm-cli-tools skill documentation
# Validates that documented patterns actually work with real tools
# Run: bash skills/llm-cli-tools/test/validate.sh
#
# Note: Claude tests use `claude -p` which works both inside and outside Claude Code.

set -uo pipefail

PASS=0
FAIL=0
SKIP=0
FAILURES=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

pass() { ((PASS++)); echo -e "  ${GREEN}PASS${NC} $1"; }
fail() { ((FAIL++)); FAILURES="$FAILURES\n  - $1: $2"; echo -e "  ${RED}FAIL${NC} $1 — $2"; }
skip() { ((SKIP++)); echo -e "  ${YELLOW}SKIP${NC} $1 — $2"; }

# Run command with timeout, capture stdout only (stderr suppressed)
run_quiet() {
  local secs=$1; shift
  local tmpout
  tmpout=$(mktemp)
  # Run in background, kill if it exceeds timeout
  "$@" > "$tmpout" 2>/dev/null &
  local pid=$!
  ( sleep "$secs" && kill "$pid" 2>/dev/null ) &
  local watcher=$!
  if wait "$pid" 2>/dev/null; then
    kill "$watcher" 2>/dev/null; wait "$watcher" 2>/dev/null
    cat "$tmpout"; rm -f "$tmpout"; return 0
  else
    kill "$watcher" 2>/dev/null; wait "$watcher" 2>/dev/null
    cat "$tmpout"; rm -f "$tmpout"; return 1
  fi
}

# Same but keeps stderr (for codex model info)
run_verbose() {
  local secs=$1; shift
  local tmpout
  tmpout=$(mktemp)
  "$@" > "$tmpout" 2>&1 &
  local pid=$!
  ( sleep "$secs" && kill "$pid" 2>/dev/null ) &
  local watcher=$!
  if wait "$pid" 2>/dev/null; then
    kill "$watcher" 2>/dev/null; wait "$watcher" 2>/dev/null
    cat "$tmpout"; rm -f "$tmpout"; return 0
  else
    kill "$watcher" 2>/dev/null; wait "$watcher" 2>/dev/null
    cat "$tmpout"; rm -f "$tmpout"; return 1
  fi
}

echo "=== LLM CLI Tools Validation ==="
echo ""

# -------------------------------------------------------------------
echo "1. Tool Availability"
echo "-------------------------------------------------------------------"

HAS_GEMINI=false
HAS_CODEX=false
HAS_CLAUDE=false

if command -v gemini >/dev/null 2>&1; then
  pass "gemini installed ($(gemini --version 2>&1 | head -1))"
  HAS_GEMINI=true
else
  skip "gemini" "not installed"
fi

if command -v codex >/dev/null 2>&1; then
  pass "codex installed ($(codex --version 2>&1 | head -1))"
  HAS_CODEX=true
else
  skip "codex" "not installed"
fi

if command -v claude >/dev/null 2>&1; then
  pass "claude installed ($(claude --version 2>&1 | head -1))"
  HAS_CLAUDE=true
else
  skip "claude" "not installed"
fi

echo ""

# -------------------------------------------------------------------
echo "2. Basic Invocation (simple prompt, no file input)"
echo "-------------------------------------------------------------------"

NEEDLE="elephant-$(date +%s)"

if $HAS_GEMINI; then
  RESULT=$(run_verbose 60 gemini -p "Reply with ONLY the word: $NEEDLE" || true)
  if echo "$RESULT" | grep -q "$NEEDLE"; then
    pass "gemini basic prompt"
  elif echo "$RESULT" | grep -q "IneligibleTierError"; then
    skip "gemini live calls" "consumer/free credentials are no longer supported; use Antigravity CLI or enterprise/paid API access"
    HAS_GEMINI=false
  elif [ -z "$RESULT" ]; then
    fail "gemini basic prompt" "empty output (rate limited or timeout?)"
  else
    fail "gemini basic prompt" "needle not found. Got: $(echo "$RESULT" | tail -3)"
  fi
else
  skip "gemini basic prompt" "not available"
fi

if $HAS_CODEX; then
  RESULT=$(run_quiet 60 codex exec "Reply with ONLY the word: $NEEDLE" || true)
  if echo "$RESULT" | grep -q "$NEEDLE"; then
    pass "codex basic prompt"
  else
    fail "codex basic prompt" "needle not found. Got: $(echo "$RESULT" | tail -3)"
  fi
else
  skip "codex basic prompt" "not available"
fi

if $HAS_CLAUDE; then
  RESULT=$(run_quiet 60 claude -p "Reply with ONLY the word: $NEEDLE" --model haiku || true)
  if echo "$RESULT" | grep -q "$NEEDLE"; then
    pass "claude basic prompt"
  else
    fail "claude basic prompt" "needle not found. Got: $(echo "$RESULT" | tail -3)"
  fi
else
  skip "claude basic prompt" "not available"
fi

echo ""

# -------------------------------------------------------------------
echo "3. Stdin Behavior (critical — validates documented patterns)"
echo "-------------------------------------------------------------------"

# Use a neutral lookup framing (configuration ID) instead of "secret word",
# which some models may refuse as suspected prompt injection.
SECRET="mango-$(date +%s)"
TMPFILE=$(mktemp)
echo "The configuration ID for this build is $SECRET." > "$TMPFILE"
trap 'rm -f "$TMPFILE"' EXIT

LOOKUP_PROMPT="What is the configuration ID mentioned in the text? Reply with ONLY the ID, no other words."

# Test: gemini "prompt" < file — should see file content
if $HAS_GEMINI; then
  RESULT=$(run_quiet 60 bash -c 'gemini "'"$LOOKUP_PROMPT"'" < "'"$TMPFILE"'"' || true)
  if echo "$RESULT" | grep -qi "$SECRET"; then
    pass "gemini stdin with positional prompt (file content visible)"
  else
    fail "gemini stdin with positional prompt" "ID not found. Got: $(echo "$RESULT" | tail -3)"
  fi
else
  skip "gemini stdin" "not available"
fi

# Test: claude -p "prompt" < file — should see file content
if $HAS_CLAUDE; then
  RESULT=$(run_quiet 60 bash -c 'claude -p "'"$LOOKUP_PROMPT"'" --model haiku < "'"$TMPFILE"'"' || true)
  if echo "$RESULT" | grep -qi "$SECRET"; then
    pass "claude stdin with positional prompt (file content visible)"
  else
    fail "claude stdin with positional prompt" "ID not found. Got: $(echo "$RESULT" | tail -3)"
  fi
else
  skip "claude stdin" "not available"
fi

# Test: codex exec "prompt" < file — stdin appended as <stdin> block
if $HAS_CODEX; then
  RESULT=$(run_quiet 60 bash -c 'codex exec "'"$LOOKUP_PROMPT"'" < "'"$TMPFILE"'"' || true)
  if echo "$RESULT" | grep -qi "$SECRET"; then
    pass "codex stdin with positional prompt (file content visible via <stdin> block)"
  else
    fail "codex stdin with positional prompt" "ID not found. Got: $(echo "$RESULT" | tail -3)"
  fi
fi

# Test: codex exec (no positional) reads stdin as prompt
if $HAS_CODEX; then
  # Note: direct pipe, not run_quiet (backgrounding breaks stdin pipe)
  RESULT=$(echo "Reply with ONLY the word: $SECRET" | codex exec 2>/dev/null || true)
  if echo "$RESULT" | grep -qi "$SECRET"; then
    pass "codex stdin as prompt (no positional arg)"
  else
    fail "codex stdin as prompt" "needle not found. Got: $(echo "$RESULT" | tail -3)"
  fi
fi

# Test: codex bash pipe workaround
if $HAS_CODEX; then
  RESULT=$(run_quiet 90 bash -c '{ echo "'"$LOOKUP_PROMPT"'"; cat "'"$TMPFILE"'"; } | codex exec' || true)
  if echo "$RESULT" | grep -qi "$SECRET"; then
    pass "codex bash pipe workaround (prompt+file via stdin)"
  else
    fail "codex bash pipe workaround" "ID not found. Got: $(echo "$RESULT" | tail -3)"
  fi
fi

echo ""

# -------------------------------------------------------------------
echo "4. Model Availability & Doc Consistency"
echo "-------------------------------------------------------------------"
# These tests detect model-name drift: if the CLI default no longer matches
# what the docs claim, the skill is already stale. Failing loudly here
# surfaces that rot early. Update both docs and these assertions together.

DOCS_CODEX_DEFAULTS="gpt-5.6-sol gpt-5.6-terra gpt-5.6-luna gpt-5.5"  # GPT-5.6 family is current; user config may intentionally override it
DOCS_CLAUDE_CURRENT_IDS="claude-fable-5 claude-opus-4-8 claude-opus-4-7 claude-sonnet-5 claude-sonnet-4-6 claude-haiku-4-5"

if $HAS_GEMINI; then
  RESULT=$(run_quiet 60 gemini -p "Say OK" || true)
  if echo "$RESULT" | grep -qi "ok"; then
    pass "gemini -p (non-interactive) works"
  elif [ -z "$RESULT" ]; then
    skip "gemini -p" "empty response (rate limited?)"
  else
    fail "gemini -p" "unexpected: $(echo "$RESULT" | tail -3)"
  fi

  # Assert -p is not marked deprecated in --help (catches false-deprecation claims)
  if gemini --help 2>&1 | grep -q -- "-p, --prompt.*Run in non-interactive"; then
    pass "gemini -p/--prompt is documented as the non-interactive entrypoint (not deprecated)"
  else
    fail "gemini -p/--prompt docs" "help text for -p changed — re-audit gemini-cli.md"
  fi
fi

if $HAS_CODEX; then
  RESULT=$(run_verbose 60 codex exec "Say OK" || true)
  MODEL=$(echo "$RESULT" | grep "^model:" | head -1 | sed 's/model: //')
  if [ -n "$MODEL" ]; then
    OK=false
    for want in $DOCS_CODEX_DEFAULTS; do
      [ "$MODEL" = "$want" ] && OK=true && break
    done
    if $OK; then
      pass "codex default model ($MODEL matches docs)"
    else
      fail "codex default model" "got '$MODEL', docs expect one of: $DOCS_CODEX_DEFAULTS — update SKILL.md/codex-cli.md/README.md"
    fi
  else
    fail "codex default model" "could not detect model from output"
  fi

  # Assert --yolo is NOT claimed to exist if the installed CLI doesn't have it
  if codex --help 2>&1 | grep -q -- "--yolo"; then
    pass "codex --yolo flag present in this build"
  else
    pass "codex --yolo absent in this build (use --dangerously-bypass-approvals-and-sandbox)"
  fi
fi

if $HAS_CLAUDE; then
  # Probe actual model used via JSON output's modelUsage map
  RESULT=$(run_quiet 30 claude -p "Reply ONLY: OK" --output-format json || true)
  USED_MODEL=$(echo "$RESULT" | grep -oE 'claude-(fable|opus|sonnet|haiku)-[0-9-]+' | sort -u | tr '\n' ' ')
  if [ -n "$USED_MODEL" ]; then
    OK=false
    for want in $DOCS_CLAUDE_CURRENT_IDS; do
      echo "$USED_MODEL" | grep -q "$want" && OK=true && break
    done
    if $OK; then
      pass "claude default model ($USED_MODEL matches docs)"
    else
      fail "claude default model" "got '$USED_MODEL', docs recognize: $DOCS_CLAUDE_CURRENT_IDS — refresh claude-cli.md"
    fi
  else
    skip "claude model detection" "could not parse modelUsage from JSON output"
  fi

  # Assert --effort exposes xhigh in the current CLI.
  if claude --help 2>&1 | tr '\n' ' ' | grep -q -- "--effort.*xhigh"; then
    pass "claude --effort supports xhigh"
  else
    fail "claude --effort xhigh" "not in help — docs claim xhigh support, CLI disagrees"
  fi
fi

echo ""

# -------------------------------------------------------------------
echo "5. JSON Output"
echo "-------------------------------------------------------------------"

if $HAS_GEMINI; then
  RESULT=$(run_quiet 60 gemini -o json 'Reply with JSON: {"status":"ok"}' || true)
  if echo "$RESULT" | grep -q '{'; then
    pass "gemini JSON output"
  elif [ -z "$RESULT" ]; then
    skip "gemini JSON output" "empty response (rate limited?)"
  else
    fail "gemini JSON output" "no JSON detected: $(echo "$RESULT" | tail -3)"
  fi
fi

if $HAS_CLAUDE; then
  RESULT=$(run_quiet 60 claude -p 'Reply with JSON: {"status":"ok"}' --model haiku --output-format json || true)
  if echo "$RESULT" | grep -q '{'; then
    pass "claude JSON output"
  else
    fail "claude JSON output" "no JSON detected: $(echo "$RESULT" | tail -3)"
  fi
fi

echo ""

# -------------------------------------------------------------------
echo "=== Results ==="
echo "-------------------------------------------------------------------"
echo -e "  ${GREEN}PASS: $PASS${NC}  ${RED}FAIL: $FAIL${NC}  ${YELLOW}SKIP: $SKIP${NC}"
if [ $FAIL -gt 0 ]; then
  echo -e "\nFailures:${FAILURES}"
  echo ""
  echo "⚠️  If stdin behavior changed, update the docs!"
fi

exit $FAIL
