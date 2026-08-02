---
name: llm-cli-tools
description: Multi-model LLM orchestration - route tasks to the right model, run in parallel, synthesize results. Use whenever the user mentions Gemini, Codex, Claude CLI, or Antigravity (agy) - e.g. "review this with gemini", "check with codex", "ask agy", "get a second opinion from another model" - or when complex tasks benefit from multiple AI perspectives or specific models have advantages.
---

# Multi-Model LLM Orchestration

Coordinate Gemini, Codex, and Claude CLI tools.

## Quick Start (Simple Usage)

Most requests are simple - just run the models and show results:

```bash
# "Review this with Gemini" (stdin works as context)
gemini -p "Review this code:" < file.py

# "Check with Codex" (stdin appended as <stdin> block)
codex exec "Review this code:" < file.py

# "Review with Gemini and Claude" (parallel, all support stdin)
gemini -p "Review:" < file.py > /tmp/g.txt &
claude -p "Review:" --model sonnet < file.py > /tmp/cl.txt &
wait
cat /tmp/g.txt /tmp/cl.txt

# "Get a second opinion with Claude"
claude -p "Review:" --model sonnet < file.py
```

**All three tools support stdin with positional prompts.** `tool "prompt" < file` works for Gemini, Codex, and Claude. **Antigravity (`agy`) does not** — it silently ignores stdin; use `@file` references instead (see `references/antigravity-cli.md`).

**Gemini `-p` is required for headless mode.** Without `-p`, `gemini "prompt"` starts *interactive* mode when stdin is a TTY. When stdin is redirected (e.g., `< file.py` or a pipe), Gemini auto-detects non-interactive and works either way — but `-p` is the documented, reliable form. Scripts should always use `gemini -p "prompt"`.

**That's it for simple requests.** Advanced patterns (routing, escalation, consensus) are below for complex tasks.

---

## ⚠️ Security Notes

**Cross-provider data**: Multi-model orchestration sends code to multiple vendors (Google, OpenAI, Anthropic). Before using parallel patterns:
- Check your org's data policies
- Don't send secrets, credentials, or PII
- Consider if code is proprietary/sensitive

**Auto-approval modes**: Avoid `--yolo`, `--dangerously-bypass-approvals-and-sandbox`, `bypassPermissions`, and Antigravity's `--dangerously-skip-permissions` / `always-proceed` unless in a trusted, isolated environment with no secrets. Codex `--full-auto` is deprecated; use an explicit sandbox.

---

## When to Use Advanced Patterns

- Complex tasks benefiting from multiple perspectives
- Specific models have clear advantages (see routing table)
- User asks for "consensus", "parallel review", or "multiple opinions"
- Large context that exceeds single-model limits
- Need validation or cross-checking

## Task Routing

| Task Type | Primary | Why | Backup |
|-----------|---------|-----|--------|
| Large context (>250k) | Claude opus/sonnet | 1M context on eligible plans; Codex CLI now caps at 272K | Gemini 3.1 Pro / 3.6 Flash (1M) for enterprise/API users |
| Code review | Codex (`gpt-5.6-sol`) | Current frontier coding model | Claude opus or sonnet |
| Security audit | Claude opus `--effort xhigh` | Thorough analysis (Opus 5 on Anthropic API) | Codex `gpt-5.6-sol` (high/xhigh) |
| Quick validation | Codex `gpt-5.6-luna` or Claude haiku | Fast, lower-cost options | Gemini `gemini-3.5-flash-lite` where available |
| Reasoning/logic | Claude opus or Codex `gpt-5.6-sol` | Strong general reasoning | Gemini `gemini-3.1-pro-preview` |
| Long autonomous work | Claude fable | Built for long-horizon agentic runs | Codex `gpt-5.6-sol` with `ultra` effort (auto task delegation) |
| Research | Codex `gpt-5.6-sol --search` | Native live web search | Gemini (Google Search grounding) for enterprise/API users |
| Full-repo review | Claude opus (1M) or Codex `gpt-5.6-sol` (≤272K) | Context size vs coding specialization tradeoff | Gemini 3.1 Pro (1M) |
| Image input | Codex (`-i screenshot.png`) | Native flag, fastest path | Claude/Gemini (path or `@file` in prompt) |
| Image generation | Codex (built-in `image_gen`, gpt-image-2) | Works out of the box, no extension needed | Gemini `nanobanana` extension (`/generate`) |
| Audio input | Gemini (`@meeting.mp3`) | Full audio understanding | Codex (audio file inputs since v0.145) |
| Video / PDF input | Gemini (`@demo.mp4`, `@doc.pdf`) | Only tool with video input; strong multimodal | Claude (PDF/images via Read) — video: none |

## Parallel Execution

Run multiple models simultaneously for consensus or speed:

```bash
# Parallel review - all three support stdin
gemini -p "Review this code:" < code.py > /tmp/gemini.txt &
codex exec "Review this code:" < code.py > /tmp/codex.txt &
claude -p "Review this code:" --model sonnet < code.py > /tmp/claude.txt &
wait
# Synthesize results from all three files
```

For structured output, use JSON mode:

```bash
gemini -p -o json "Find bugs:" < code.py > /tmp/gemini.json &
codex exec --json "Find bugs:" < code.py > /tmp/codex.json &
wait
# Claude: use --output-format json
# Note: codex --json emits JSONL events (one per line), not a single JSON document
```

## Result Synthesis

| Agreement | Confidence | Action |
|-----------|------------|--------|
| 3/3 agree | HIGH | Accept result |
| 2/3 agree | MEDIUM | Note dissent, likely accept |
| All differ | LOW | Use a frontier reasoning model (Claude opus or `gpt-5.6-sol` at high effort) as tiebreaker |

When synthesizing:
1. Identify common findings across models
2. Flag unique insights from individual models
3. Note disagreements and which model dissents
4. Use reasoning model to resolve conflicts if needed

```bash
# Tie-breaker: feed conflicting outputs to reasoning model
codex exec -m gpt-5.6-sol "Gemini found X, Codex found Y. Which is correct and why?"
```

## Error Recovery

```
Primary fails → Try backup from routing table
Rate limited → Wait + retry with backoff
Auth missing → Skip tool, note in output
All fail → Return partial results with caveats
```

Check tool availability:

```bash
# Verify tool is available before use
command -v gemini >/dev/null && gemini -p "prompt" || echo "Gemini not available"
```

## Context Window Sizes

| Tool | Model | Input | Output |
|------|-------|-------|--------|
| Gemini | `gemini-3.1-pro-preview` / `gemini-3.6-flash` / `gemini-3.5-flash-lite` | 1M tokens | 64K tokens |
| Codex | `gpt-5.6-sol` / `-terra` / `-luna` | 272K tokens (CLI cap since July 13, 2026; API spec is 1.05M) | 128K tokens |
| Codex | `gpt-5.4` (legacy — retires Aug 31, 2026) | Up to 1M tokens | 128K tokens |
| Claude | `fable` (Fable 5) | 1M tokens | 128K tokens |
| Claude | `opus` (Opus 5 on Anthropic API) | 1M tokens* | 128K tokens |
| Claude | `sonnet` (Sonnet 5) | 1M tokens* | 128K tokens |
| Claude | `haiku` (4.5) | 200K tokens | 64K tokens |

*Claude 1M availability depends on model, provider, and plan. Fable 5, Opus 5, and Opus 4.8 use 1M context on the Anthropic API. Subscription access and Sonnet 1M may require usage credits.

**Claude and Gemini reach 1M context; current Codex GPT-5.6 sessions cap at 272K in the CLI** — cut from 372K on July 13, 2026 (billing-tier boundary; openai/codex#34619 tracks restoration). The older `gpt-5.4` still reaches 1M there but retires Aug 31, 2026. Gemini CLI stopped serving consumer/free, Google AI Pro, and Google AI Ultra accounts on June 18, 2026; enterprise licenses and paid API-key access remain supported. Individual accounts get Gemini models through **Antigravity CLI** (`agy`) instead — see `references/antigravity-cli.md`.

**For large context tasks (code review, log analysis, full-repo review):**
```bash
# 1M context with the current Opus alias
claude -p "Review:" --model opus < all-source.txt
```

**Auto-routing by size:** If input fits in ~200K, any model works. 200K–250K: any current model except Claude haiku. Above ~250K, use Claude Opus/Sonnet or Gemini 3.x on a plan that includes 1M context (Codex GPT-5.6 caps at 272K raw, ~250K practical).

## Feeding Files to Models

### Multimodal: What Each Tool Can Do

**Input:**

| Modality | Gemini | Codex | Claude |
|----------|--------|-------|--------|
| Image | ✅ `@file.png` or path in prompt | ✅ `-i / --image` flag | ✅ path in prompt (Read tool) |
| PDF | ✅ `@file.pdf` | ❌ | ✅ path in prompt (Read tool) |
| Audio | ✅ `@file.mp3` (mp3/wav) | ✅ audio files (v0.145+); realtime voice in TUI | ❌ |
| Video | ✅ `@file.mp4` (mp4/mov) | ❌ | ❌ |

**Generation (output):**

| Modality | Gemini | Codex | Claude |
|----------|--------|-------|--------|
| Image | ✅ `nanobanana` extension (`/generate`, `/edit`, …) | ✅ built-in `image_gen` tool (gpt-image-2, no setup) | ❌ (SVG authoring or image-gen MCP server only) |
| Audio (TTS) | ⚠️ API-only, no official extension | ❌ | ❌ |
| Video | ⚠️ Veo is API-only | ❌ | ❌ |

```bash
# Image input
codex exec -i shot.png "What's wrong in this UI?"
gemini -p "Describe @shot.png"
claude -p "Describe what's in ./shot.png"

# Audio / video / PDF input → Gemini
gemini -p "Transcribe and summarize @meeting.mp3"
gemini -p "List UI issues you see in @demo.mp4"

# Image generation
codex exec "Generate a 1024x1024 lighthouse logo, save it here" --sandbox workspace-write
# Gemini: gemini extensions install https://github.com/gemini-cli-extensions/nanobanana
#         then /generate inside a session (model via NANOBANANA_MODEL env var)
```

⚠️ **`-i` flag collision:** In **Codex**, `-i` means `--image`. In **Gemini**, `-i` means `--prompt-interactive` (run prompt then stay interactive). Don't confuse them — copying a Codex command to Gemini won't attach an image.

For Gemini and Claude, the file must live inside the workspace (or, for Gemini, an `--include-directories` path). Codex generated images land in `~/.codex/generated_images/`. See the per-tool references for details.

### Stdin Support

All three tools support stdin with positional prompts:

| Tool | `"prompt" < file.py` | How it works |
|------|---------------------|-------------|
| Gemini | ✅ | Stdin appended as context |
| Claude | ✅ | Stdin appended as context |
| Codex | ✅ | Stdin appended as `<stdin>` block |
| Antigravity | ❌ | Stdin silently ignored — use `@file` references |

### Single File

```bash
# All three tools work the same way
gemini -p "Review:" < file.py
codex exec "Review:" < file.py
claude -p "Review:" --model opus < file.py
```

### Multiple Files

```bash
# Multiple files with headers (works for all tools)
find src -name "*.py" -exec sh -c 'echo "=== {} ==="; cat {}' \; | gemini -p "Review this codebase:"
find src -name "*.py" -exec sh -c 'echo "=== {} ==="; cat {}' \; | codex exec "Review this codebase:"
find src -name "*.py" -exec sh -c 'echo "=== {} ==="; cat {}' \; | claude -p "Review:" --model opus

# With size check (estimate tokens before sending)
CHARS=$(find src -name "*.py" -exec cat {} + | wc -c)
echo "~$((CHARS / 4)) tokens"  # If >900K, too large even for 1M models
```

## Session Reuse (Keep Context)

All tools support session persistence - build context once, ask follow-ups without re-sending files:

| Tool | Resume | Fork | List Sessions |
|------|--------|------|---------------|
| Gemini | `gemini -r latest` | N/A | `gemini --list-sessions` |
| Codex | `codex resume` | `codex fork` | N/A (auto-saved) |
| Claude | `claude -c` / `claude -r <id>` | `claude -c --fork-session` | `claude -r` (picker) |

**For large codebase review:** Use `gemini -i "prompt"` to load context and stay interactive, or resume later with `gemini -r latest`. Gemini retains sessions for 30 days. Claude supports `--from-pr` to resume sessions linked to PRs.

## Quick Reference

| Tool | Command | Best For |
|------|---------|----------|
| Gemini | `gemini -p "prompt" < file` | 1M context, video/audio/PDF input, image gen (nanobanana), research — for supported enterprise/API accounts |
| Codex | `codex exec "prompt" < file` | Code review and agentic coding (GPT-5.6 family), image gen (built-in), audio input |
| Claude | `claude -p "prompt" < file` | Fresh context, security analysis, 1M-context review, long autonomous work |
| Antigravity | `agy -p "prompt"` | Gemini-family lane for individual Google accounts (post-June 2026); multi-vendor (Gemini/Claude 4.6/GPT-OSS), weekly quota |

## Model Selection

| Tool | Quality | Fast | Reasoning |
|------|---------|------|-----------|
| Gemini | `-m gemini-3.1-pro-preview` | `-m gemini-3.6-flash` or `-m gemini-3.5-flash-lite` | `gemini-3.1-pro-preview` |
| Codex | `-m gpt-5.6-sol` | `-m gpt-5.6-luna` | `-m gpt-5.6-sol` with `xhigh`/`max`/`ultra` reasoning effort in config |
| Claude | `--model fable` or `--model opus` | `--model sonnet` or `--model haiku` | `--model opus --effort xhigh` |

**Current model snapshot (August 2026):** Gemini: `auto` routing by default; current IDs are `gemini-3.1-pro-preview`, `gemini-3.6-flash` (GA July 21), `gemini-3.5-flash`, `gemini-3.5-flash-lite` (access is account-dependent). Codex: the GPT-5.6 family launched July 9, 2026 — `gpt-5.6-sol` (flagship, the default for most accounts, default effort now `low`), `gpt-5.6-terra` (balanced), `gpt-5.6-luna` (fast/cheap); `gpt-5.5` is legacy and `gpt-5.4`/`gpt-5.4-mini` retire Aug 31, 2026. Claude: `fable` (Fable 5), `opus` (Opus 5, launched late July 2026), `sonnet` (Sonnet 5), and `haiku` (Haiku 4.5). Prefer aliases unless reproducibility requires pinning a full ID.

**Claude effort levels:** `low`, `medium`, `high`, `xhigh`, `max`. Support and defaults vary by active model; use `claude --help` and `/model` for the current account.

## Common Patterns

### Pattern 1: Consensus Review
Ask all 3 models the same question, compare answers, flag disagreements.

```bash
# All three support stdin
gemini -p "Review this code for bugs:" < code.py > /tmp/g.txt &
codex exec "Review this code for bugs:" < code.py > /tmp/c.txt &
claude -p "Review this code for bugs:" < code.py > /tmp/cl.txt &
wait
```

### Pattern 2: Specialist Dispatch
Route to best model for task type (see routing table above).

```bash
# Security audit → current Claude opus
claude -p "Security audit:" --model opus --effort xhigh < api.py

# Large file analysis → Gemini
gemini -p "Analyze this log:" < large-log.txt

# Code optimization → Codex
codex exec -m gpt-5.6-sol "Optimize this code:" < perf.py
```

### Pattern 3: Fallback Chain
Try primary → if fails → try backup → if fails → report.

```bash
gemini -p "prompt" 2>/dev/null || \
  codex exec "prompt" 2>/dev/null || \
  echo "All tools failed"
```

**Note:** Exit code alone doesn't catch all failures—some models return 0 with error text. For critical tasks, validate output content.

### Pattern 4: Large Context Handling
All three tool families have models with large context windows, but model and account access differ. Verify availability before routing near-limit inputs.

```bash
# Gemini handles large context for supported enterprise/API accounts
gemini -p "Review this large codebase:" < all-source.txt

# Codex recommended model
codex exec "Review this large codebase:" < all-source.txt

# Claude opus (1M context where available)
claude -p "Review:" --model opus < all-source.txt

# Cascade: fast summary → deep analysis
SUMMARY=$(gemini -p "Summarize key points:" < huge-file.txt)
claude -p "Analyze this summary:" --model opus <<< "$SUMMARY"
```

## Budget Awareness

| Tool | Access | Cost Notes |
|------|-----------|------------|
| Gemini | Consumer access ended June 18, 2026 | Enterprise licenses and paid API-key access remain; `gemini-3.5-flash-lite` is the cheapest current-gen tier |
| Codex | Subscription/API dependent | Use `gpt-5.6-luna` ($1/$6 per 1M) or `-terra` ($2.50/$15) for lighter work; `-sol` is $5/$30 |
| Claude | Subscription/API dependent | Haiku/Sonnet are typically cheaper than Opus/Fable |

Strategy: Choose based on account access, data policy, and task complexity. Do not assume Gemini CLI is free or available to consumer accounts.

## Detailed References

- `references/gemini-cli.md` - Gemini CLI details
- `references/codex-cli.md` - Codex CLI details
- `references/claude-cli.md` - Claude CLI details
- `references/antigravity-cli.md` - Antigravity CLI (`agy`) — Gemini-family access for individual Google accounts
- `references/orchestration-patterns.md` - Advanced patterns
