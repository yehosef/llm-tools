# Claude CLI Reference

**Audited against:** Claude Code `2.1.292`, official Claude Code / Claude Platform docs, and live test calls on October 7, 2026. Alias resolution verified live: `fable` → `claude-fable-5-1`, `opus` → `claude-opus-5-5`, `sonnet` → `claude-sonnet-5-5`, `haiku` → `claude-haiku-4-5-20251001`, `best` → `claude-fable-5-1`, `default` → `claude-opus-5-5`.

## Installation

See [README.md](../../../README.md#prerequisites) for installation instructions.

Quick: `npm install -g @anthropic-ai/claude-code` (or `claude install` for the native build)

## Authentication

- Run `claude` interactively and use `/login`
- Or set `ANTHROPIC_API_KEY` environment variable
- `claude auth` - manage authentication (`claude auth status` prints JSON)
- `claude setup-token` - set up long-lived auth token (requires Claude subscription)

## Non-Interactive Usage

```bash
# Print mode - execute and exit
claude -p "Your prompt here"

# With model selection
claude -p "prompt" --model opus
claude -p "prompt" --model sonnet
claude -p "prompt" --model haiku
claude -p "prompt" --model fable

# Full model names also work
claude -p "prompt" --model claude-opus-5-5

# From stdin (avoids argv limits; piped stdin is capped at 10 MB)
claude -p "Review this code" < file.py

# JSON output (answer is in .result; also total_cost_usd, modelUsage, session_id)
claude -p "prompt" --output-format json

# Structured output: the parsed object lands in .structured_output
claude -p "List 3 bugs" --output-format json \
  --json-schema '{"type":"object","properties":{"bugs":{"type":"array","items":{"type":"string"}}},"required":["bugs"]}' \
  < code.py | jq '.structured_output.bugs'

# With budget limit
claude -p "prompt" --max-budget-usd 1.00

# Custom system prompt
claude -p "prompt" --system-prompt "You are a security expert"

# Effort level (low/medium/high/xhigh/max) — pass it explicitly; defaults vary by model and doc page
claude -p "prompt" --effort high
claude -p "prompt" --effort xhigh
claude -p "prompt" --effort max
```

⚠️ **Stdin gotcha:** `claude -p` reads stdin whenever it isn't a terminal and waits for it to close (verified: `sleep 20 | claude -p "…"` took 20s). When you aren't feeding input, add `< /dev/null`. Codex behaves the same way.

### Lean second-opinion calls

Every `claude -p` call loads Claude Code's full harness: system prompt, built-in tools, CLAUDE.md, skills, plugins and MCP servers. In testing (Oct 7, 2026, a setup with several MCP servers) a trivial prompt sent **~29K input tokens**. For a pure text review of content you pipe in, strip the harness:

```bash
# ~2.5K input tokens; works with subscription (OAuth) login
claude -p "Review this code:" --model sonnet --safe-mode --tools '' < file.py

# Same, but Claude can still open image/PDF paths named in the prompt (~7–9K tokens)
claude -p "What's wrong in ./shot.png?" --model sonnet --safe-mode --tools Read < /dev/null
```

- `--safe-mode` turns off CLAUDE.md, skills, plugins, hooks and MCP servers but keeps auth, so it gives a clean, unbiased context.
- ⚠️ **Don't use `--tools ''` on its own.** With MCP servers configured, it raised the prompt to **~161K tokens** in testing, apparently by loading every MCP tool definition up front. Always pair it with `--safe-mode` or `--strict-mcp-config`.
- `--bare` also strips the harness, but it accepts only `ANTHROPIC_API_KEY` / `apiKeyHelper` auth, not a subscription login. The docs say `--bare` will become the default for `-p` in a future release.

## All Options

| Flag | Description |
|------|-------------|
| `-p, --print` | Non-interactive mode (required for scripting). Skips the workspace trust dialog — only run in directories you trust |
| `--model <model>` | Model alias or full name. Aliases: `fable`, `best`, `opus`, `sonnet`, `haiku`, `opusplan`, `default`, plus `[1m]` variants |
| `--effort <level>` | `low`, `medium`, `high`, `xhigh`, `max` (Haiku 4.5 has no effort control) |
| `--fallback-model <models>` | Fallback if primary is overloaded/unavailable; comma-separated list tried in order; primary re-tried each turn |
| `--output-format <format>` | `text`, `json`, `stream-json` (only with `--print`) |
| `--input-format <format>` | `text` (default), `stream-json` |
| `--json-schema <schema>` | JSON Schema for structured output → `.structured_output` in JSON output |
| `--max-budget-usd <amount>` | Spending limit (only with `--print`) |
| `--system-prompt <prompt>` | Replace the system prompt |
| `--append-system-prompt <prompt>` | Append to default system prompt |
| `--system-prompt-file` / `--append-system-prompt-file <file>` | File variants (hidden from `--help`, still accepted — verified) |
| `--system-prompt-snapshot <on\|off>` | `on` (default): system prompt recorded on first request and reused verbatim on resume; `off` re-renders every request |
| `--exclude-dynamic-system-prompt-sections` | Move per-machine context (cwd, env, git status) into the first user message for better cache reuse |
| `--tools <tools...>` | Built-in tools available: `""` (none — see warning above), `"default"`, or names (`"Bash,Edit,Read"`) |
| `--allowed-tools` / `--disallowed-tools <tools...>` | Allow/deny rules (e.g. `"Bash(git *) Edit"`) |
| `--permission-mode <mode>` | `manual`, `plan`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions` |
| `--permission-prompts <target>` | With `--print`: `host` (default; SDK host or `--permission-prompt-tool` answers) or `none` (anything that would prompt is denied) |
| `--restricted` | Removes command-running tools and WebFetch (unless named in `--tools`), ignores user/project/local settings, confines file tools to working dirs, refuses `bypassPermissions` |
| `--safe-mode` | Disable all customizations (CLAUDE.md, skills, plugins, hooks, MCP, agents, output styles…) but keep auth, model, built-in tools, permissions |
| `--bare` | Minimal mode (skips hooks, LSP, plugin sync, auto-memory, CLAUDE.md discovery, keychain). Auth strictly `ANTHROPIC_API_KEY` or `apiKeyHelper` |
| `--dangerously-skip-permissions` | Bypass all permission checks (⚠️ sandboxes with no internet only) |
| `--allow-dangerously-skip-permissions` | Make bypass available without enabling it |
| `--add-dir <dirs>` | Additional directories for tool access |
| `--mcp-config <configs>` | MCP servers from JSON files or strings |
| `--strict-mcp-config` | Only use MCP servers from `--mcp-config` |
| `--settings <file-or-json>` | Additional settings |
| `--setting-sources <sources>` | Which setting sources to load: `user`, `project`, `local` |
| `--agent <agent>` | Agent for the session |
| `--agents <json-or-file>` | Define custom agents as JSON (with `--print`, may be a file path) |
| `--plugin-dir <path>` / `--plugin-url <url>` | Load a plugin (dir or .zip) for this session only (repeatable) |
| `--disable-slash-commands` | Disable all skills |
| `--autocompact <auto\|tokens>` | Auto-compact window (100k–1M tokens) |
| `-c, --continue` | Continue most recent conversation in this directory |
| `-r, --resume [value]` | Resume by session ID or picker |
| `--fork-session` | New session ID when resuming (with `-r`/`-c`) |
| `--from-pr [value]` | Resume a session linked to a PR |
| `--session-id <uuid>` | Use specific session ID |
| `-n, --name <name>` | Session display name |
| `--no-session-persistence` | Don't save session (only with `--print`) |
| `-w, --worktree [name]` / `--tmux` | Run in a new git worktree (optionally in tmux) |
| `--bg, --background` | Start as a background session; prints an id for `attach`/`logs`/`stop`/`rm`. Cannot be combined with `-p` |
| `--cloud [desc\|id\|url]` | Create or attach to a cloud session (`--remote` is a deprecated alias) |
| `--environment <id>` | New cloud session on a self-hosted environment |
| `--teleport [session]` | Resume a teleport session |
| `--desktop` | Open in the Claude Desktop app |
| `--remote-control [name]` | Interactive session with Remote Control |
| `--file <specs...>` | Download API file resources at startup (`file_id:relative_path`) — not for local files |
| `--betas <betas>` | Beta headers (API key users only) |
| `--brief` | Enable `SendUserMessage` tool |
| `--include-partial-messages` / `--include-hook-events` / `--forward-subagent-text` / `--replay-user-messages` | stream-json extras |
| `--prompt-suggestions [bool]` | Emit a predicted next prompt in print/SDK mode |
| `--chrome` / `--no-chrome`, `--ide` | Integrations |
| `--verbose`, `-d, --debug [filter]`, `--debug-file <path>` | Diagnostics |

## Commands

```bash
claude                  # Interactive mode
claude -p "prompt"      # Print mode
claude agents           # Manage background agents (--json [--all] for scripting)
claude attach <id>      # Open a background session in this terminal
claude logs <id>        # Print a background session's recent output
claude stop <id>        # Stop a background session (alias: kill)
claude rm <id>          # Delete a background session (and its worktree when safe)
claude respawn [id]     # Restart background session(s) on the current version
claude auth             # Manage authentication
claude auto-mode        # Inspect/reset auto-mode classifier config
claude doctor           # Health check
claude import [source]  # Import config from codex, gemini, or cursor (--dry-run)
claude install          # Install native build (stable, latest, or version)
claude mcp              # MCP management
claude plugin           # Plugin management
claude purge [path]     # Delete all Claude Code state for a project (replaces `claude project purge`)
claude setup-token      # Long-lived auth token
claude update           # Update
claude gateway          # Enterprise auth/telemetry gateway
claude ultrareview      # Cloud multi-agent code review of the branch/PR (--json, --post, --timeout)
```

## Available Models

**Current aliases on the Anthropic API** (prices per 1M tokens in/out, from Anthropic's model docs):

| Alias | Model (ID) | Released | Context / max output | Price | Use for |
|-------|-----------|----------|----------------------|-------|---------|
| `fable` | Fable 5.1 (`claude-fable-5-1`) | Sep 1, 2026 | 1M / 128K | $10 / $50 | Longest-running, hardest autonomous work. Never the default |
| `opus` | Opus 5.5 (`claude-opus-5-5`) | Sep 22, 2026 | 1M / 128K | $4 / $20 | Complex reasoning, security review. **The `default` on all plans** |
| `sonnet` | Sonnet 5.5 (`claude-sonnet-5-5`) | Sep 28, 2026 | 1M / 128K | $2 / $10 | Daily coding, balanced reviews |
| `haiku` | Haiku 4.5 (`claude-haiku-4-5-20251001`) | Oct 2025 | 200K / 64K | $1 / $5 | Fast, cheap checks. No effort control |

- `best` → Fable if your organization has access, else Opus. `opusplan` → Opus in plan mode, Sonnet otherwise (a plain `-p` call resolves to Sonnet).
- Haiku 4.5 retires no sooner than Oct 15, 2026; Anthropic said on Sep 28 that Haiku 5.5 "will join the Claude 5.5 family in the coming weeks". Re-check `haiku` before relying on it.
- **Older IDs still work** (verified): `claude-fable-5`, `claude-opus-5`, `claude-opus-4-8`, `claude-sonnet-5`. Also active: `claude-opus-4-7`, `claude-sonnet-4-6`. Sonnet 4.5 is deprecated (retires Nov 30, 2026).
- Opus 5.5 is cheaper than Opus 5 ($5/$25), so routing to `opus` costs less than it did in August.

**Third-party providers resolve aliases differently:** Bedrock and Vertex map `sonnet` to Sonnet 4.5; Foundry maps `opus` to Opus 4.6. Pin full IDs or set `ANTHROPIC_DEFAULT_OPUS_MODEL` / `ANTHROPIC_DEFAULT_SONNET_MODEL` / `ANTHROPIC_DEFAULT_FABLE_MODEL`.

**Fast mode:** Opus 5.5 fast mode is up to 2.5× faster at $8/$40 per 1M. Toggle with `/fast` in an interactive session. There is **no `--fast` CLI flag** (verified: `unknown option`); in `-p` JSON output, `fast_mode_state` reports `off` with reason `sdk_opt_in_required`.

**1M context:** on the Anthropic API, Fable 5/5.1, Sonnet 5+, and Opus 4.7+ run with 1M context on **every plan, including Pro**, with no `[1m]` suffix (verified: `modelUsage.contextWindow` = 1000000 for `opus`, `sonnet`, `fable`). Only Opus 4.6 / Sonnet 4.6 still need `[1m]`. Fable usage may bill to usage credits depending on plan. `CLAUDE_CODE_DISABLE_1M_CONTEXT=1` forces 200K.

**Effort:** all current Opus/Sonnet/Fable models accept `low`→`max`. Claude Code's docs say Opus 5.5 and Sonnet 5.5 default to `medium`, while the Sonnet 5.5 launch post says `high` — pass `--effort` explicitly when it matters.

**Per-call overhead:** a trivial `claude -p` call costs roughly $0.005 (Sonnet, warm cache) to $0.15 (Opus, cold cache) and ~$0.60 for Fable on a cold cache, mostly the harness prompt. Use the lean flags above for many small calls.

## Permission Modes

- `manual` - Normal permission prompts (formerly `default`, still accepted)
- `plan` - Read-only planning
- `acceptEdits` - Auto-accept file edits + common filesystem commands (trusted repos only)
- `auto` - Classifier-backed auto-approval (Max/Team/Enterprise/API, Anthropic API only; Team/Enterprise need admin enablement)
- `dontAsk` - ⚠️ Only pre-approved tools run; everything else denied (locked-down CI)
- `bypassPermissions` - ⚠️ Skip all checks (isolated containers/VMs only)

**In scripts, pass `--permission-mode` explicitly.** Per the docs, the starting mode for `-p` depends on whether Claude Code can fetch feature flags (third-party providers or telemetry off start in `auto`). Add `--permission-prompts none` so anything that would prompt is denied instead of waiting.

## Session Management

```bash
# Continue most recent conversation
claude -c -p "Follow up question"

# Resume by session ID (or interactive picker)
claude -r <session-id> -p "What about the auth module?"
claude -r  # Opens picker

# Fork a session (new ID, preserves context)
claude -c --fork-session -p "Try a different approach"

# Resume from a PR
claude --from-pr 123

# Worktree session (isolated git branch)
claude -w my-feature "Implement the feature"

# Background session (not combinable with -p)
claude --bg "Refactor the auth module"   # prints an id
claude agents --json                     # list active sessions
claude logs <id>; claude attach <id>
```

With `-p`, a background subagent keeps the process alive until it finishes (10-minute idle cap, `CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS`); background Bash commands are killed ~5s after the result.

## Agents

```bash
# Use a named agent
claude --agent reviewer

# Define inline agents (or, with -p, pass a JSON file path)
claude --agents '{"reviewer": {"description": "Reviews code", "prompt": "You are a code reviewer"}}'
```

## Common Patterns

```bash
# Quick review with opus (stdin avoids argv limits)
claude -p "Review this code:" --model opus < main.py

# Cheap, clean-context second opinion
claude -p "Second opinion on this plan:" --model sonnet --safe-mode --tools '' < plan.md

# Structured output
claude -p "List issues in this code" --output-format json \
  --json-schema '{"type":"object","properties":{"issues":{"type":"array","items":{"type":"string"}}},"required":["issues"]}' \
  < code.py | jq '.structured_output.issues'

# Budget-limited task
claude -p "Analyze this codebase" --max-budget-usd 5.00

# Custom persona
claude -p "Review for security:" --system-prompt "You are a security auditor" < api.py

# Deep reasoning
claude -p "Find subtle bugs in:" --model opus --effort xhigh < complex.py
claude -p "Find subtle bugs in:" --model opus --effort max < complex.py   # slower, can overthink

# 1M context for large inputs
claude -p "Review entire codebase:" --model opus < all-source.txt

# Ephemeral session (no persistence)
claude -p "Quick check:" --no-session-persistence < file.py

# Image / PDF input — no -i flag; name the path in the prompt and the Read tool loads it
claude -p "Describe what's in ./screenshot.png"
claude -p "Compare ./before.png and ./after.png — what changed?"
```

## Multimodal Capabilities

| Modality | Input | Output (generation) |
|----------|-------|---------------------|
| Image (PNG/JPG/GIF/WebP; SVG/HEIC/TIFF attach since 2.1.288) | ✅ Path in prompt → Read tool; paste/drag-drop in interactive mode | ❌ Not native |
| PDF | ✅ Read tool; short PDFs read whole, longer ones in 20-page ranges (needs `pdftoppm` from poppler) | ❌ |
| Audio | ❌ (voice dictation only, interactive) | ❌ |
| Video | ❌ | ❌ |

**Image input mechanisms:**
- **Headless (`-p`):** reference the file path in the prompt — the Read tool loads it (keep `Read` available if you restrict `--tools`). Files must be inside the working directory or an `--add-dir` path.
- **Interactive:** paste from clipboard or drag-drop.
- **Programmatic stdin:** `--input-format stream-json` accepts base64 image content blocks — the only way to send image bytes without a file on disk.

**Image generation:** not built in. Have Claude write **SVG**, or add an image-generation **MCP server** via `--mcp-config`. For raster images in a multi-tool setup, route to Codex (built-in `image_gen`).

**Audio/video:** no current Claude model accepts audio or video.

## Use Cases for Fresh Claude Context

- Current conversation has too much context
- Need opus-level reasoning on something specific
- Want an unbiased second opinion (use `--safe-mode` so your CLAUDE.md/skills don't steer it)
- Testing different system prompts

## Troubleshooting

### Authentication Errors
- **"Not authenticated"**: Run `claude auth` or `claude` interactively and use `/login`
- **"API key invalid"**: Check `ANTHROPIC_API_KEY`
- **`--bare` fails with a subscription login**: `--bare` needs an API key; use `--safe-mode` instead
- **"Rate limit exceeded"**: Wait and retry, or reduce request frequency

### Common Issues
- **Command not found**: `npm install -g @anthropic-ai/claude-code`
- **Hangs with no output**: stdin is an open pipe — add `< /dev/null`
- **Huge token usage on tiny prompts**: you used `--tools ''` without `--safe-mode`/`--strict-mcp-config`, or MCP servers/CLAUDE.md are loaded — see "Lean second-opinion calls"
- **`unknown option '--fast'`**: fast mode is `/fast` in interactive sessions only
- **Model not available**: check the alias table; on Bedrock/Vertex/Foundry pin full IDs
- **Budget exceeded**: raise `--max-budget-usd` or start a new session

### Fallback Strategy
If Claude is unavailable, use Codex with its default model (`gpt-6.1-sol`) for quality or `-m gpt-6-luna` for speed. Gemini is a fallback only for supported enterprise or paid API-key accounts.
