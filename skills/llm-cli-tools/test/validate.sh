#!/usr/bin/env bash
# Smoke tests for llm-cli-tools skill documentation
# Validates that documented patterns actually work with real tools
# Run: bash skills/llm-cli-tools/test/validate.sh
#
# Note: Claude tests are skipped when run inside a Claude Code session.
# Run from a plain terminal to test Claude too.

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
  if [ -n "${CLAUDECODE:-}" ]; then
    skip "claude" "inside Claude Code session (run from plain terminal to test)"
    HAS_CLAUDE=false
  else
    pass "claude installed ($(claude --version 2>&1 | head -1))"
    HAS_CLAUDE=true
  fi
else
  skip "claude" "not installed"
fi

echo ""

# -------------------------------------------------------------------
echo "2. Basic Invocation (simple prompt, no file input)"
echo "-------------------------------------------------------------------"

NEEDLE="elephant-$(date +%s)"

if $HAS_GEMINI; then
  RESULT=$(run_quiet 60 gemini "Reply with ONLY the word: $NEEDLE" || true)
  if echo "$RESULT" | grep -q "$NEEDLE"; then
    pass "gemini basic prompt"
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

SECRET="mango-$(date +%s)"
TMPFILE=$(mktemp)
echo "The secret word is $SECRET" > "$TMPFILE"
trap 'rm -f "$TMPFILE"' EXIT

# Test: gemini "prompt" < file — should see file content
if $HAS_GEMINI; then
  RESULT=$(run_quiet 60 bash -c 'gemini "What is the secret word in the text? Reply with ONLY that word." < "'"$TMPFILE"'"' || true)
  if echo "$RESULT" | grep -qi "$SECRET"; then
    pass "gemini stdin with positional prompt (file content visible)"
  else
    fail "gemini stdin with positional prompt" "secret not found. Got: $(echo "$RESULT" | tail -3)"
  fi
else
  skip "gemini stdin" "not available"
fi

# Test: claude -p "prompt" < file — should see file content
if $HAS_CLAUDE; then
  RESULT=$(run_quiet 60 bash -c 'claude -p "What is the secret word in the text? Reply with ONLY that word." --model haiku < "'"$TMPFILE"'"' || true)
  if echo "$RESULT" | grep -qi "$SECRET"; then
    pass "claude stdin with positional prompt (file content visible)"
  else
    fail "claude stdin with positional prompt" "secret not found. Got: $(echo "$RESULT" | tail -3)"
  fi
else
  skip "claude stdin" "not available"
fi

# Test: codex exec "prompt" < file — should IGNORE file (documented caveat)
if $HAS_CODEX; then
  RESULT=$(run_quiet 60 bash -c 'codex exec "What is the secret word in the text I provided? Reply ONLY that word, or none if no text." < "'"$TMPFILE"'"' || true)
  if echo "$RESULT" | grep -qi "$SECRET"; then
    fail "codex stdin with positional prompt" "found secret — stdin behavior may have changed! Docs say it should be ignored"
  else
    pass "codex stdin with positional prompt (file correctly ignored — matches docs)"
  fi
fi

# Test: codex exec (no positional) reads stdin as prompt
if $HAS_CODEX; then
  # Note: direct pipe, not run_quiet (backgrounding breaks stdin pipe)
  RESULT=$(echo "Reply with ONLY the word: $SECRET" | codex exec 2>/dev/null || true)
  if echo "$RESULT" | grep -qi "$SECRET"; then
    pass "codex stdin as prompt (no positional arg)"
  else
    fail "codex stdin as prompt" "secret not found. Got: $(echo "$RESULT" | tail -3)"
  fi
fi

# Test: codex bash pipe workaround
if $HAS_CODEX; then
  RESULT=$(run_quiet 90 bash -c '{ echo "What is the secret word? Reply with ONLY that word."; cat "'"$TMPFILE"'"; } | codex exec' || true)
  if echo "$RESULT" | grep -qi "$SECRET"; then
    pass "codex bash pipe workaround (prompt+file via stdin)"
  else
    fail "codex bash pipe workaround" "secret not found. Got: $(echo "$RESULT" | tail -3)"
  fi
fi

echo ""

# -------------------------------------------------------------------
echo "4. Model Availability"
echo "-------------------------------------------------------------------"

if $HAS_GEMINI; then
  RESULT=$(run_quiet 60 gemini "Say OK" || true)
  if echo "$RESULT" | grep -qi "ok"; then
    pass "gemini default model"
  elif [ -z "$RESULT" ]; then
    skip "gemini default model" "empty response (rate limited?)"
  else
    fail "gemini default model" "unexpected: $(echo "$RESULT" | tail -3)"
  fi
fi

if $HAS_CODEX; then
  RESULT=$(run_verbose 60 codex exec "Say OK" || true)
  MODEL=$(echo "$RESULT" | grep "^model:" | head -1 | sed 's/model: //')
  if [ -n "$MODEL" ]; then
    pass "codex default model ($MODEL)"
  else
    fail "codex default model" "could not detect model"
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
if [ $SKIP -gt 0 ] && [ -n "${CLAUDECODE:-}" ]; then
  echo ""
  echo "Note: Claude tests skipped (inside Claude Code). Run from plain terminal for full coverage."
fi

exit $FAIL
