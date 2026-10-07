---
name: llm-cli-tools
description: Multi-model LLM orchestration - route tasks to the right model, run in parallel, synthesize results. Use whenever the user mentions Gemini, Codex, ChatGPT / GPT / OpenAI models, Claude CLI, or Antigravity (agy) - e.g. "review this with gemini", "check with codex", "ask ChatGPT", "what does GPT think", "ask agy", "get a second opinion from another model" - or when complex tasks benefit from multiple AI perspectives or specific models have advantages. Also use when the user asks to generate, draw, or edit a raster image (photo, illustration, logo, icon, hero image, mockup, sprite, transparent PNG) - Claude can't make bitmaps, but Codex has built-in image generation.
---

# Multi-Model LLM Orchestration

Coordinate Gemini, Codex (OpenAI / ChatGPT models), and Claude CLI tools.

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

# "Get a second opinion with Claude" (clean context: no CLAUDE.md/skills/MCP, ~2.5K-token prompt)
claude -p "Review:" --model sonnet --safe-mode --tools '' < file.py
```

**All three tools support stdin with positional prompts.** `tool "prompt" < file` works for Gemini, Codex, and Claude. **Antigravity (`agy`) does not** — it silently ignores stdin; use `@file` references instead (see `references/antigravity-cli.md`).

**Gemini `-p` is required for headless mode.** Without `-p`, `gemini "prompt"` starts *interactive* mode when stdin is a TTY. When stdin is redirected (e.g., `< file.py` or a pipe), Gemini auto-detects non-interactive and works either way — but `-p` is the documented, reliable form. Scripts should always use `gemini -p "prompt"`.

**Not feeding stdin? Close it.** `codex exec` and `claude -p` both wait for stdin to close when it isn't a terminal. If the caller's stdin is an open pipe they hang, so add `< /dev/null` when there's no input file.

### "Make me an image" → Codex

Claude can't generate raster images. Codex can, with no extra setup or API key (built-in `image_gen` tool, gpt-image-2):

```bash
# Generate — needs workspace-write so Codex can copy the result into the project (~1 min)
codex exec --sandbox workspace-write \
  "Generate a 1024x1024 flat minimalist icon of a lighthouse, save it as ./assets/lighthouse.png" < /dev/null

# Edit an existing image — attach it with -i AFTER the prompt, save under a new name
codex exec --sandbox workspace-write \
  "Make the background transparent and the door green. Save as ./assets/lighthouse-v2.png" \
  -i assets/lighthouse.png < /dev/null
```

- Name the output path in the prompt. Without one, the file stays under `~/.codex/generated_images/<session>/`.
- One call per distinct image. For variants, say how many and list the filenames.
- Afterwards, look at the result yourself (Read the PNG) before reporting back, and iterate with one targeted change per call.
- For icons/diagrams that should be SVG or match an existing vector set in the repo, write SVG directly instead.

**That's it for simple requests.** Advanced patterns (routing, escalation, consensus) are below for complex tasks.

---

## ⚠️ Security Notes

**Cross-provider data**: Multi-model orchestration sends code to multiple vendors (Google, OpenAI, Anthropic). Before using parallel patterns:
- Check your org's data policies
- Don't send secrets, credentials, or PII
- Consider if code is proprietary/sensitive

**Auto-approval modes**: Avoid `--yolo`, `--dangerously-bypass-approvals-and-sandbox`, `bypassPermissions`, and Antigravity's `--dangerously-skip-permissions` / `always-proceed` unless in a trusted, isolated environment with no secrets. Codex `--full-auto` has been removed; use an explicit `--sandbox` (and `--approve-for-me` for reviewer-model approvals).

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
| Large context (>250k) | Claude opus/sonnet | 1M context on every plan (Anthropic API); Codex CLI defaults to 272K | Codex with `-c model_context_window=872000` (higher cost); Gemini 3.1 Pro / 3.6 Flash (1M) for enterprise/API users |
| Code review | Codex (default `gpt-6.1-sol`, or `codex exec review --uncommitted`) | Current Codex workhorse; dedicated review subcommand | Claude opus or sonnet |
| Security audit | Claude opus `--effort xhigh` | Thorough analysis (Opus 5.5) | Codex `gpt-6-astra` (Plus/Pro) or `gpt-6.1-sol` at high/xhigh |
| Quick validation | Codex `gpt-6-luna` or Claude haiku | Fast, lower-cost options | Gemini `gemini-3.5-flash-lite` where available |
| Reasoning/logic | Claude opus or Codex `gpt-6-astra` | Frontier reasoning tiers | Codex `gpt-6.1-sol` at high effort; Gemini `gemini-3.1-pro-preview` |
| Long autonomous work | Claude fable (Fable 5.1) | Built for long-horizon agentic runs | Codex `gpt-6.1-sol` or `gpt-6-astra` with `ultra` effort (auto task delegation) |
| Research | Codex `codex --search exec` (flag goes before `exec`) | Native live web search | Gemini (Google Search grounding) for enterprise/API users |
| Full-repo review | Claude opus (1M) or Codex (≤272K default, ≤872K raised) | Context size vs coding specialization tradeoff | Gemini 3.1 Pro (1M) |
| Image input | Codex (`"prompt" -i screenshot.png`) | Native flag, fastest path | Claude/Gemini (path or `@file` in prompt) |
| Image generation | Codex (built-in `image_gen`, gpt-image-2) | Works out of the box, no extension needed | Gemini `nanobanana` extension (`/generate`) |
| Audio input | Gemini (`@meeting.mp3`) | Full audio understanding | None native — Codex/Claude can't hear audio (Codex may shell out to a local whisper if installed) |
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
# bugs.schema.json: {"type":"object","properties":{"bugs":{"type":"array","items":{"type":"string"}}},"required":["bugs"],"additionalProperties":false}
gemini -p -o json "Find bugs:" < code.py > /tmp/gemini.json &
codex exec --output-schema bugs.schema.json -o /tmp/codex.json "Find bugs:" < code.py > /dev/null &
claude -p "Find bugs:" --output-format json --json-schema "$(cat bugs.schema.json)" < code.py \
  | jq '.structured_output' > /tmp/claude.json &
wait
# Codex --json is a JSONL event stream, not one document — use --output-schema + -o for a parseable answer
# Claude --output-format json without a schema puts the answer text in .result
```

## Result Synthesis

| Agreement | Confidence | Action |
|-----------|------------|--------|
| 3/3 agree | HIGH | Accept result |
| 2/3 agree | MEDIUM | Note dissent, likely accept |
| All differ | LOW | Use a frontier reasoning model (Claude opus, or Codex `gpt-6-astra` / `gpt-6.1-sol` at high effort) as tiebreaker |

When synthesizing:
1. Identify common findings across models
2. Flag unique insights from individual models
3. Note disagreements and which model dissents
4. Use reasoning model to resolve conflicts if needed

```bash
# Tie-breaker: feed conflicting outputs to reasoning model
codex exec -c model_reasoning_effort='"high"' "Gemini found X, Codex found Y. Which is correct and why?" < /dev/null
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
| Codex | `gpt-6.1-sol` / `gpt-6-astra` / `gpt-6-sol` / `gpt-6-luna` | 272K tokens by default in the CLI; up to 872K with `-c model_context_window=872000` (API spec 1.05M) | 128K tokens |
| Claude | `fable` (Fable 5.1) | 1M tokens* | 128K tokens |
| Claude | `opus` (Opus 5.5) | 1M tokens* | 128K tokens |
| Claude | `sonnet` (Sonnet 5.5) | 1M tokens* | 128K tokens |
| Claude | `haiku` (4.5) | 200K tokens | 64K tokens |

*On the Anthropic API, Fable 5.x, Sonnet 5+ and Opus 4.7+ get 1M context on every plan, Pro included, with no `[1m]` suffix (per Claude Code docs; 1M confirmed live on Oct 7, 2026). On Bedrock/Vertex/Foundry, check the resolved model.

**Claude and Gemini reach 1M context; Codex CLI defaults to 272K.** Raising Codex to 872K via `model_context_window` reportedly works (openai/codex#47805, ~828K usable), but on API billing any request over 272K input tokens is charged 2× input / 1.5× output. Gemini CLI stopped serving consumer/free, Google AI Pro, and Google AI Ultra accounts on June 18, 2026; enterprise licenses and paid API-key access remain supported. Individual accounts get Gemini models through **Antigravity CLI** (`agy`) instead — see `references/antigravity-cli.md`.

**For large context tasks (code review, log analysis, full-repo review):**
```bash
# 1M context with the current Opus alias
claude -p "Review:" --model opus < all-source.txt
```

**Auto-routing by size:** If input fits in ~200K, any model works. 200K–250K: any current model except Claude haiku. Above ~250K, use Claude Opus/Sonnet (1M) or Gemini 3.x on a plan that includes 1M context; Codex only with a raised `model_context_window` (default ~258K usable).

## Feeding Files to Models

### Multimodal: What Each Tool Can Do

**Input:**

| Modality | Gemini | Codex | Claude |
|----------|--------|-------|--------|
| Image | ✅ `@file.png` or path in prompt | ✅ `-i / --image` flag | ✅ path in prompt (Read tool; keep `Read` if you restrict `--tools`) |
| PDF | ✅ `@file.pdf` | ❌ | ✅ path in prompt (Read tool) |
| Audio | ✅ `@file.mp3` (mp3/wav) | ❌ not native (realtime voice in TUI only) | ❌ |
| Video | ✅ `@file.mp4` (mp4/mov) | ❌ | ❌ |

**Generation (output):**

| Modality | Gemini | Codex | Claude |
|----------|--------|-------|--------|
| Image | ✅ `nanobanana` extension (`/generate`, `/edit`, …) | ✅ built-in `image_gen` tool (gpt-image-2, no setup) | ❌ (SVG authoring or image-gen MCP server only) |
| Audio (TTS) | ⚠️ API-only, no official extension | ❌ | ❌ |
| Video | ⚠️ Veo is API-only | ❌ | ❌ |

```bash
# Image input
codex exec "What's wrong in this UI?" -i shot.png   # prompt BEFORE -i (see warning below)
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

⚠️ **Codex `-i` eats the prompt:** `-i/--image` takes multiple values, so `codex exec -i shot.png "prompt"` reads the prompt as a second image path and fails with "No prompt provided via stdin". Put the prompt first (`codex exec "prompt" -i shot.png`) or use `--image=shot.png` (comma-separate several).

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

Codex and Claude read stdin until it closes whenever it isn't a terminal — with no input file, pass `< /dev/null` so an inherited open pipe can't stall them.

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
| Codex | `codex resume --last` / `codex exec resume --last "prompt"` | `codex fork` / `codex exec fork <id>` | `codex resume` (picker), `codex agents` |
| Claude | `claude -c` / `claude -r <id>` | `claude -c --fork-session` | `claude -r` (picker) |

**For large codebase review:** Use `gemini -i "prompt"` to load context and stay interactive, or resume later with `gemini -r latest`. Gemini retains sessions for 30 days. Claude supports `--from-pr` to resume sessions linked to PRs.

## Quick Reference

| Tool | Command | Best For |
|------|---------|----------|
| Gemini | `gemini -p "prompt" < file` | 1M context, video/audio/PDF input, image gen (nanobanana), research — for supported enterprise/API accounts |
| Codex | `codex exec "prompt" < file` | ChatGPT/OpenAI models: code review and agentic coding (GPT-6 family), image gen (built-in), live web search |
| Claude | `claude -p "prompt" < file` | Fresh context, security analysis, 1M-context review, long autonomous work |
| Antigravity | `agy -p "prompt"` | Gemini-family lane for individual Google accounts (post-June 2026); multi-vendor (Gemini/Claude 4.6/GPT-OSS), weekly quota |

## Model Selection

| Tool | Quality | Fast | Reasoning |
|------|---------|------|-----------|
| Gemini | `-m gemini-3.1-pro-preview` | `-m gemini-3.6-flash` or `-m gemini-3.5-flash-lite` | `gemini-3.1-pro-preview` |
| Codex | default (`gpt-6.1-sol`) or `-m gpt-6-astra` (Plus/Pro) | `-m gpt-6-luna` | `-c model_reasoning_effort='"xhigh"'` (also `max`, `ultra`) |
| Claude | `--model opus` (or `fable` for long autonomous runs) | `--model sonnet` or `--model haiku` | `--model opus --effort xhigh` |

**Current model snapshot:**
- **Codex (verified Oct 7, 2026, CLI 0.160.1):** GPT-6 family — `gpt-6.1-sol` (default workhorse, Sep 29), `gpt-6-astra` (frontier, Sep 3; Plus/Pro), `gpt-6-sol` (previous workhorse), `gpt-6-luna` (fast/cheap). The GPT-5.6 Sol/Terra/Luna models are still listed as older options; `gpt-5.5` retires Oct 14, 2026; `gpt-5.4` is gone. A `model` in `~/.codex/config.toml` overrides the default.
- **Claude (verified Oct 7, 2026, Claude Code 2.1.292):** `fable` → Fable 5.1, `opus` → Opus 5.5 (also `default`), `sonnet` → Sonnet 5.5, `haiku` → Haiku 4.5 (Haiku 5.5 announced, not yet shipped). Prefer aliases unless reproducibility requires pinning a full ID.
- **Gemini (last checked Aug 2026):** `auto` routing by default; current IDs are `gemini-3.1-pro-preview`, `gemini-3.6-flash` (GA July 21), `gemini-3.5-flash`, `gemini-3.5-flash-lite` (access is account-dependent).

**Effort levels:** Claude `low`→`max` (Haiku has none); Codex `low`→`max`, plus `ultra` (auto task delegation) on Sol/Astra. Defaults differ by model and the docs disagree on some, so pass effort explicitly when it matters.

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

# Code optimization → Codex (default gpt-6.1-sol)
codex exec "Optimize this code:" < perf.py
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

# Codex: default 272K; raise the window for bigger inputs (costs more above 272K)
codex exec -c model_context_window=872000 "Review this large codebase:" < all-source.txt

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
| Codex | Subscription/API dependent | API per 1M in/out: `gpt-6-luna` $0.10/$0.50, `gpt-6.1-sol` $2/$10, `gpt-6-astra` $10/$50. Over 272K input: 2×/1.5× |
| Claude | Subscription/API dependent | API per 1M in/out: haiku $1/$5, sonnet $2/$10, opus $4/$20, fable $10/$50. Each `claude -p` call also carries ~25–30K tokens of harness prompt unless you use `--safe-mode --tools ''` |

Strategy: Choose based on account access, data policy, and task complexity. Do not assume Gemini CLI is free or available to consumer accounts.

## Detailed References

- `references/gemini-cli.md` - Gemini CLI details
- `references/codex-cli.md` - Codex CLI details
- `references/claude-cli.md` - Claude CLI details
- `references/antigravity-cli.md` - Antigravity CLI (`agy`) — Gemini-family access for individual Google accounts
- `references/orchestration-patterns.md` - Advanced patterns
