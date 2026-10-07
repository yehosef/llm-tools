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
  ( sleep "$secs" && kill "$pid" 2>/dev/null ) >/dev/null 2>&1 &
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
  ( sleep "$secs" && kill "$pid" 2>/dev/null ) >/dev/null 2>&1 &
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

HAS_AGY=false
if command -v agy >/dev/null 2>&1; then
  pass "agy installed ($(agy --version 2>&1 | head -1))"
  # Live tests need a signed-in session; `agy models` fails fast when signed out
  AGY_MODELS=$(run_verbose 15 agy models || true)
  if [ -n "$AGY_MODELS" ] && ! echo "$AGY_MODELS" | grep -qi "sign in"; then
    HAS_AGY=true
  else
    skip "agy live calls" "not signed in — run \`agy\` once to authenticate"
  fi
else
  skip "agy (Antigravity)" "not installed"
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

if $HAS_AGY; then
  RESULT=$(run_quiet 90 agy -p "Reply with ONLY the word: $NEEDLE" || true)
  if echo "$RESULT" | grep -q "$NEEDLE"; then
    pass "agy basic prompt"
  else
    fail "agy basic prompt" "needle not found. Got: $(echo "$RESULT" | tail -3)"
  fi
else
  skip "agy basic prompt" "not available or not signed in"
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

# Test: agy does NOT read stdin (verified 2026-08-02) — docs say use @file instead.
# If this ever starts passing content through, the docs are stale.
if $HAS_AGY; then
  RESULT=$(run_quiet 90 bash -c 'agy -p "'"$LOOKUP_PROMPT"'" < "'"$TMPFILE"'"' || true)
  if echo "$RESULT" | grep -qi "$SECRET"; then
    fail "agy stdin (docs say unsupported)" "stdin now reaches the model — update antigravity-cli.md and SKILL.md stdin tables"
  else
    pass "agy ignores stdin (matches documented behavior — use @file instead)"
  fi
fi

echo ""

# -------------------------------------------------------------------
echo "4. Model Availability & Doc Consistency"
echo "-------------------------------------------------------------------"
# These tests detect model-name drift: if the CLI default no longer matches
# what the docs claim, the skill is already stale. Failing loudly here
# surfaces that rot early. Update both docs and these assertions together.

# Verified 2026-10-07 (Codex 0.160.1, Claude Code 2.1.292)
DOCS_CODEX_ACCOUNT_DEFAULT="gpt-6.1-sol"   # what `codex exec` picks with no `model` in config.toml
DOCS_CODEX_KNOWN="gpt-6.1-sol gpt-6-astra gpt-6-sol gpt-6-luna gpt-5.6-sol gpt-5.6-terra gpt-5.6-luna"  # a user config may pick any of these
# alias=expected-full-id (fable skipped: ~10x the cost of sonnet per call)
DOCS_CLAUDE_ALIASES="opus=claude-opus-5-5 sonnet=claude-sonnet-5-5 haiku=claude-haiku-4-5-20251001"
# Lean flags documented in claude-cli.md for cheap, clean-context calls
CLAUDE_LEAN="--safe-mode --tools '' --no-session-persistence"

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
  # Account default, ignoring ~/.codex/config.toml (which may pin an older model on purpose)
  RESULT=$(run_verbose 60 codex exec --ignore-user-config --skip-git-repo-check -s read-only "Say OK" || true)
  MODEL=$(echo "$RESULT" | grep "^model:" | head -1 | sed 's/model: //')
  if [ "$MODEL" = "$DOCS_CODEX_ACCOUNT_DEFAULT" ]; then
    pass "codex account default model ($MODEL matches docs)"
  elif [ -n "$MODEL" ]; then
    fail "codex account default model" "got '$MODEL', docs say $DOCS_CODEX_ACCOUNT_DEFAULT — update SKILL.md/codex-cli.md/README.md"
  else
    fail "codex account default model" "could not detect model from output"
  fi

  # Every documented current model must still be in the live catalog
  CATALOG=$(codex debug models 2>/dev/null | grep -oE '"slug":"[^"]+"' | sed 's/"slug":"//; s/"$//' | tr '\n' ' ')
  if [ -n "$CATALOG" ]; then
    MISSING=""
    for want in $DOCS_CODEX_KNOWN; do
      echo " $CATALOG " | grep -q " $want " || MISSING="$MISSING $want"
    done
    if [ -z "$MISSING" ]; then
      pass "codex catalog contains all documented models"
    else
      fail "codex catalog" "documented but missing:$MISSING — update codex-cli.md"
    fi
  else
    skip "codex catalog" "\`codex debug models\` returned nothing"
  fi

  # --search is a global flag: `codex --search exec` parses, `codex exec --search` does not
  if codex --search exec --help >/dev/null 2>&1 && ! codex exec --search --help >/dev/null 2>&1; then
    pass "codex --search must precede exec (matches docs)"
  else
    fail "codex --search placement" "parsing changed — update the web-search examples"
  fi

  # Removed flags the docs tell people not to use
  if codex exec --full-auto --help >/dev/null 2>&1; then
    fail "codex --full-auto" "flag is accepted again — docs say it was removed"
  else
    pass "codex exec --full-auto rejected (matches docs)"
  fi
fi

if $HAS_CLAUDE; then
  # Each alias must resolve to the documented full ID (read from modelUsage in JSON output)
  for pair in $DOCS_CLAUDE_ALIASES; do
    alias=${pair%%=*}; want=${pair#*=}
    RESULT=$(run_quiet 60 bash -c "claude -p 'Reply ONLY: OK' --model $alias --output-format json $CLAUDE_LEAN < /dev/null" || true)
    # modelUsage keys only (a "canonicalModel" field also carries an undated ID)
    GOT=$(echo "$RESULT" | grep -oE '"claude-(fable|opus|sonnet|haiku)-[0-9a-z-]+":\{"inputTokens"' | cut -d'"' -f2 | sort -u | tr '\n' ' ' | sed 's/ $//')
    if [ "$GOT" = "$want" ]; then
      pass "claude alias $alias → $GOT"
    elif [ -n "$GOT" ]; then
      fail "claude alias $alias" "resolves to '$GOT', docs say $want — refresh claude-cli.md and SKILL.md"
    else
      skip "claude alias $alias" "could not parse modelUsage from JSON output"
    fi
  done

  # Assert --effort exposes xhigh in the current CLI.
  if claude --help 2>&1 | tr '\n' ' ' | grep -q -- "--effort.*xhigh"; then
    pass "claude --effort supports xhigh"
  else
    fail "claude --effort xhigh" "not in help — docs claim xhigh support, CLI disagrees"
  fi

  # Lean mode keeps the prompt small (docs claim ~2.5K tokens vs ~29K default)
  RESULT=$(run_quiet 60 bash -c "claude -p 'Reply ONLY: OK' --model haiku --output-format json $CLAUDE_LEAN < /dev/null" || true)
  TOKENS=$(echo "$RESULT" | grep -oE '"(input_tokens|cache_creation_input_tokens|cache_read_input_tokens)":[0-9]+' | head -3 | grep -oE '[0-9]+$' | paste -sd+ - | bc 2>/dev/null)
  if [ -n "$TOKENS" ] && [ "$TOKENS" -lt 10000 ]; then
    pass "claude lean mode prompt is small (~$TOKENS input tokens)"
  elif [ -n "$TOKENS" ]; then
    fail "claude lean mode" "$TOKENS input tokens — docs promise <10K with --safe-mode --tools ''"
  else
    skip "claude lean mode" "could not parse usage"
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

  # --json-schema result lands in .structured_output (docs and escalation pattern rely on this)
  SCHEMA='{"type":"object","properties":{"status":{"type":"string"}},"required":["status"]}'
  RESULT=$(run_quiet 60 bash -c "claude -p 'Set status to ok' --model haiku --output-format json --json-schema '$SCHEMA' $CLAUDE_LEAN < /dev/null" || true)
  if echo "$RESULT" | grep -q '"structured_output":{"status"'; then
    pass "claude --json-schema → .structured_output"
  else
    fail "claude --json-schema" "no structured_output.status: $(echo "$RESULT" | tail -c 200)"
  fi
fi

if $HAS_CODEX; then
  # --output-schema + -o writes one JSON object (docs use this instead of parsing --json JSONL)
  CX_SCHEMA=$(mktemp); CX_OUT=$(mktemp)
  echo '{"type":"object","properties":{"status":{"type":"string"}},"required":["status"],"additionalProperties":false}' > "$CX_SCHEMA"
  run_quiet 90 codex exec --skip-git-repo-check -s read-only -m gpt-6-luna --output-schema "$CX_SCHEMA" -o "$CX_OUT" "Set status to ok" >/dev/null || true
  if grep -q '"status"' "$CX_OUT" 2>/dev/null; then
    pass "codex --output-schema + -o writes JSON object"
  else
    fail "codex --output-schema" "no status key in output file: $(head -c 200 "$CX_OUT" 2>/dev/null)"
  fi
  rm -f "$CX_SCHEMA" "$CX_OUT"
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
