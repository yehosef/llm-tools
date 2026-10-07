# Codex CLI Reference

## Installation

See [README.md](../../../README.md#prerequisites) for installation instructions.

Quick: `npm install -g @openai/codex` or `brew install codex`

**Audited against:** Codex CLI `0.160.1` (live `--help`, live model catalog via `codex debug models`, live test calls) and the official Codex docs at `learn.chatgpt.com/docs` on October 7, 2026.

## Authentication

- `codex login` - ChatGPT OAuth (Plus, Pro, Business, Team, Edu, Enterprise)
- `codex login --device-auth` - Device code flow
- `codex login --with-api-key` - Read API key from stdin
- `codex login status` - Check auth status
- `codex logout` - Remove credentials
- CI: set `CODEX_API_KEY` for non-interactive runs
- Config: `credential_store` = `file` (default) | `keyring` | `auto`

## Non-Interactive Usage

```bash
# Execute prompt non-interactively
codex exec "Your prompt here"
codex e "Your prompt here"  # alias

# With specific model
codex exec -m gpt-6.1-sol "prompt"
codex exec -m gpt-6-luna "prompt"

# With stdin file content (appended as <stdin> block)
codex exec "Review this code:" < file.py

# Read-only analysis (safest)
codex exec -s read-only "Analyze the architecture of this codebase"

# Allow workspace edits explicitly
codex exec --sandbox workspace-write "prompt"

# With image input — prompt BEFORE -i (-i takes multiple values and would swallow the prompt)
codex exec "What's in this image?" -i screenshot.png
codex exec --image=screenshot.png "What's in this image?"   # = form is also safe

# Live web search: --search is a GLOBAL flag — it must come BEFORE `exec`
codex --search exec "What changed in Django 6.1?"
codex exec -c web_search='"live"' "What changed in Django 6.1?"   # equivalent

# Structured output: JSON Schema in, final message to a file
codex exec --output-schema schema.json -o result.json "Find bugs:" < code.py

# Code review of the current repo (dedicated subcommand)
codex exec review --uncommitted
codex exec review --base main

# Resume / fork a non-interactive session
codex exec resume --last "Now check the tests"
codex exec fork <session-id> "Try a different approach"

# Ignore user config or rules (useful for isolated CI runs)
codex exec --ignore-user-config --ignore-rules "prompt"
```

⚠️ **Stdin gotcha:** `codex exec` reads stdin whenever stdin is not a terminal, and waits for it to close. If the caller's stdin is a pipe that stays open, Codex sits there until it closes (verified: `sleep 20 | codex exec "…"` took 20s longer). When you are not feeding input, add `< /dev/null`. Claude `-p` behaves the same way.

⚠️ **`codex exec` never prompts for approval.** It runs with approval policy `never`: anything the sandbox doesn't allow fails and the failure goes back to the model. `-a/--ask-for-approval` is not accepted by `codex exec` (only by the interactive `codex`). Use `--approve-for-me` to send approval requests to an automatic reviewer model instead.

## All Options

### Flags accepted by both `codex` and `codex exec`

| Flag | Short | Description |
|------|-------|-------------|
| `--model <model>` | `-m` | Model to use |
| `--sandbox <mode>` | `-s` | `read-only`, `workspace-write`, `danger-full-access` |
| `--approve-for-me` | | Send approval requests to an automatic reviewer model (`codex-auto-review`); uses the `workspace-write` sandbox |
| `--dangerously-bypass-approvals-and-sandbox` | | Skip all confirmation prompts and sandboxing. ⚠️ Only for externally sandboxed environments. |
| `--dangerously-bypass-hook-trust` | | Run enabled hooks without persisted trust. Only for automation that already vets hook sources. |
| `--image <file>...` | `-i` | Attach image(s); takes several values (comma-separated or repeated). Put the prompt **before** `-i` or use `--image=file` |
| `--cd <dir>` | `-C` | Set working directory |
| `--add-dir <dir>` | | Additional writable directories |
| `--worktree` | | Run the session in a new managed git worktree |
| `--config <key=value>` | `-c` | Override config values (repeatable; value parsed as TOML) |
| `--profile <name>` | `-p` | Layer `$CODEX_HOME/<name>.config.toml` on top of the base config |
| `--oss` | | Use local open-source model provider |
| `--local-provider <provider>` | | `lmstudio` or `ollama` (pair with `--oss`) |
| `--enable <feature>` / `--disable <feature>` | | Force a feature flag on/off (repeatable) |
| `--strict-config` | | Error when config contains fields unknown to this CLI version |

### Interactive-only flags (`codex`, not `codex exec`)

| Flag | Short | Description |
|------|-------|-------------|
| `--ask-for-approval <policy>` | `-a` | `on-request` (model decides when to ask) or `never`. `untrusted` and `on-failure` were removed. |
| `--search` | | Enable live web search. Also works for exec when placed before the subcommand: `codex --search exec …` |
| `--no-alt-screen` | | Inline TUI, preserves scrollback |
| `--no-daemon` | | Run without the shared background app-server |
| `--remote <addr>` | | Connect TUI to a remote app server (`ws://`, `wss://`, `unix://`) |
| `--remote-auth-token-env <var>` | | Env var holding the bearer token for `--remote` |

> **Removed:** `codex exec --full-auto` now errors (`unexpected argument`) — use `--sandbox workspace-write`. `--yolo` is not in this build's `--help`; use the long `--dangerously-bypass-approvals-and-sandbox` flag.

### `codex exec` Additional Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--json` | | JSONL event stream: `thread.started`, `turn.started`, `item.completed` (item types include `agent_message`, `command_execution`, `web_search`), `turn.completed`, `error` |
| `--output-last-message <file>` | `-o` | Write the final message to a file — simplest way to capture the answer |
| `--output-schema <file>` | | JSON Schema the final response must match (combine with `-o`) |
| `--ephemeral` | | Skip session persistence |
| `--skip-git-repo-check` | | Allow non-git directories |
| `--ignore-user-config` | | Do not load `$CODEX_HOME/config.toml` (auth still uses `CODEX_HOME`) |
| `--ignore-rules` | | Do not load user or project `.rules` files |
| `--color <mode>` | | `always`, `never`, `auto` |

```bash
# Extract just the answer from the JSONL stream
codex exec --json "prompt" < /dev/null | jq -r 'select(.type=="item.completed" and .item.type=="agent_message") | .item.text'
```

## Commands

```bash
codex                  # Interactive TUI session
codex exec "prompt"    # Non-interactive execution (alias: e)
codex exec resume      # Resume a non-interactive session (--last or <id>)
codex exec fork <id>   # Fork a session into a new one
codex exec review      # Code review of the current repo (--uncommitted / --base / --commit)
codex review           # Same review, top-level form
codex login            # Authenticate
codex logout           # Remove credentials
codex resume           # Resume interactive session (picker; --last for most recent)
codex fork             # Fork interactive session (picker; --last for most recent)
codex agents           # Browse all agent sessions on the shared local app-server
codex queue --thread <id> --message "…"   # Queue a message for an existing session
codex archive | unarchive | delete        # Manage saved sessions
codex migrate-rollouts # Migrate legacy local sessions to paginated history
codex apply            # Apply latest diff from Codex agent (alias: a)
codex doctor           # Diagnose installation, auth, config, runtime
codex update           # Update Codex CLI
codex sandbox          # Run a command in the Codex sandbox
codex debug models     # Raw model catalog as JSON (slugs, efforts, context sizes)
codex features list    # Feature flags (enable/disable via --enable/--disable)
codex completion       # Shell completions (bash/zsh/fish/powershell/elvish)

# MCP servers Codex uses
codex mcp add <name> -- <command> [args...]   # stdio server
codex mcp add <name> --url <url>              # streamable HTTP server
codex mcp list | get | remove | login | logout

# Cloud tasks (experimental)
codex cloud exec | status | list | apply | diff

# Plugins
codex plugin add | list | remove
codex plugin marketplace add | list | upgrade | remove

# Desktop & servers
codex app              # Launch desktop app (macOS)
codex app-server       # Local app server (experimental)
codex exec-server      # Standalone exec-server (experimental)
codex remote-control start | stop | pair
```

`codex mcp-server` (running Codex itself as an MCP server) was removed in 0.154; the docs point to `codex app-server` instead.

## Sandbox Modes

- `read-only` - Can only read files (safest, **recommended** for review/analysis)
- `workspace-write` - Can write to the workspace
- `danger-full-access` - ⚠️ Full system access (avoid unless necessary)

## Available Models

**Current — GPT-6 family.** Live catalog on Oct 7, 2026 (`codex debug models`, CLI 0.160.1), launch dates from the Codex changelog, API list prices from OpenAI's pricing page.

| Model | Role | Reasoning efforts (default) | API price per 1M in/out |
|-------|------|-----------------------------|-------------------------|
| `gpt-6.1-sol` | **Default.** Workhorse for coding and everyday work; "near-Astra performance at lower cost" (Sep 29, 2026) | low → max, **ultra** (default `low`) | $2 / $10 |
| `gpt-6-astra` | Frontier tier for the hardest work (Sep 3, 2026). In Codex on Plus/Pro; needs CLI ≥ 0.153 | low → max, **ultra** (default `low`) | $10 / $50 |
| `gpt-6-sol` | Previous-generation workhorse (Sep 22, 2026) | low → max, **ultra** (default `medium`) | $2 / $10 |
| `gpt-6-luna` | Fast and cheap — quick edits, subagents, high-volume (Sep 22, 2026) | low → max (default `medium`) | $0.10 / $0.50 |

- All take text + image input, support a `fast` speed tier ("2× speed, increased usage"), and work with ChatGPT and API-key auth.
- `ultra` = maximum reasoning **with automatic task delegation** to subagents (Sol and Astra only).
- There is no GPT-6 Terra. For everyday work use `gpt-6.1-sol` (same price as `gpt-6-sol`); `gpt-6-luna` covers the cheap end.

**Older, still in the catalog:** `gpt-5.6-sol`, `gpt-5.6-terra`, `gpt-5.6-luna` (no retirement date announced). `gpt-5.5` is hidden and **retires Oct 14, 2026**.
**Gone:** `gpt-5.4` / `gpt-5.4-mini` (retired Aug 31, 2026, removed from the catalog in 0.158), `gpt-5.3-codex-spark` (retired Sep 14, 2026). A hidden `codex-auto-review` model backs `--approve-for-me` and the review subcommands.

**Without `-m`**, Codex uses the account's recommended model — `gpt-6.1-sol` for a standard account (verified with `--ignore-user-config`). A `model` set in `~/.codex/config.toml` overrides that. Set reasoning effort via `/model` (interactive), `model_reasoning_effort` in config, or `-c model_reasoning_effort='"high"'` per call.

### Context window

- **CLI default: 272K tokens** (`context_window: 272000`, 95% usable ≈ 258K). Treat ~250K as the practical input limit.
- **Can be raised to 872K** with `-c model_context_window=872000` (the catalog's `max_context_window`). The key is a documented config option and the CLI accepts it; that it works up to ~828K effective (higher values are clamped) comes from a user report in openai/codex#47805 (Sept 2026), not from OpenAI.
- **Cost above 272K:** on API billing, a request with more than 272K input tokens is charged 2× input and 1.5× output for the whole request. How it counts against ChatGPT plan usage is undocumented.
- API spec for the GPT-6 family: 1.05M input / 128K output. Requests to restore a larger default (openai/codex#31860, #34619) are still open.

```bash
# Large input past the 272K default (expect higher cost)
codex exec -c model_context_window=872000 "Review this codebase:" < all-src.txt
```

## Multimodal Capabilities

| Modality | Input | Output (generation) |
|----------|-------|---------------------|
| Image (PNG/JPEG/GIF/WebP) | ✅ `-i/--image` flag (repeatable); paste in TUI | ✅ Built-in `image_gen` tool (gpt-image-2) |
| Audio | ❌ Not native in `exec` — catalog lists text + image only. Asked to transcribe, Codex goes looking for a local tool such as whisper and runs that. Realtime voice exists in the TUI only. | ❌ No TTS tool |
| Video | ❌ | ❌ |
| PDF | ❌ No native PDF attach (convert to images or text first) | ❌ |

⚠️ **`-i` swallows the prompt.** `-i/--image <FILE>...` accepts several values, so in `codex exec -i shot.png "prompt"` the prompt becomes a second image path, and Codex exits with "No prompt provided via stdin" (verified 0.160.1). Put the prompt before `-i`, or use `--image=shot.png`.

**Image input:** every current model accepts images. Attach explicitly — Codex won't browse for images on its own. Keep files under ~5MB.

```bash
codex exec "What's wrong in this UI?" -i screenshot.png
codex exec "What changed between these?" -i before.png,after.png
```

**Image generation:** built in as the `image_gen` tool (feature `image_generation`, on by default), backed by **gpt-image-2** — works with ChatGPT login, no `OPENAI_API_KEY` needed. A bundled `imagegen` skill (`~/.codex/skills/.system/imagegen/`) steers it; ask in plain language or with `$imagegen`.

Verified Oct 7, 2026 (CLI 0.160.1), a 1024×1024 icon took ~70s:
- The image is generated into `~/.codex/generated_images/<session-id>/…png`, then Codex **copies it to the path you name** in the prompt. That copy needs `--sandbox workspace-write`; under `read-only` it can only report the `~/.codex` path.
- **Edits:** put the prompt first, then attach the source with `-i`. Codex saves edits under a new name rather than overwriting unless you say to replace. Verified: a transparent-background + recolor edit came back as RGBA with real alpha, but at 1254×1254 instead of the source's 1024×1024 — state exact dimensions if they matter.
- **Transparent backgrounds:** ask for one explicitly (supported since 0.158).
- **Several images:** one `image_gen` call per distinct asset; name every output file.
- Not for SVG/vector work or icons that must match an existing vector set — the skill itself says to edit those as code.
- A fallback `scripts/image_gen.py` CLI path exists in the skill, but it needs `OPENAI_API_KEY`; the built-in tool is the default.

```bash
# Generate into the project
codex exec --sandbox workspace-write \
  "Generate a 1024x1024 hero image of a lighthouse at dawn, save it as ./public/hero.png" < /dev/null

# Edit / restyle an existing image (prompt before -i)
codex exec --sandbox workspace-write \
  "Same scene at night with a starry sky. Save as ./public/hero-night.png" -i public/hero.png < /dev/null

# Transparent cutout
codex exec --sandbox workspace-write \
  "Generate a 512x512 game sprite of a red fox, transparent background, save as ./sprites/fox.png" < /dev/null
```

⚠️ **`-i` flag collision:** in Codex `-i` = `--image`; in Gemini `-i` = `--prompt-interactive`. Don't copy commands between tools blindly.

## Config File (`~/.codex/config.toml`)

Key options:

| Key | Values | Description |
|-----|--------|-------------|
| `model` | string | Default model (overrides the account default) |
| `model_reasoning_effort` | `low`…`max`/`ultra` | Reasoning intensity |
| `model_reasoning_summary` | `auto`/`concise`/`detailed`/`none` | Reasoning output |
| `model_verbosity` | `low`/`medium`/`high` | Output detail |
| `model_context_window` | integer (≤ 872000) | Raise the 272K default context |
| `model_auto_compact_token_limit` | integer | When to auto-compact |
| `service_tier` | e.g. `fast` | Processing tier (fast = 2× speed, more usage) |
| `approval_policy` | `on-request`/`never` | Approval rules (interactive) |
| `sandbox_mode` | read-only/workspace-write/danger-full-access | Sandbox |
| `web_search` | `disabled`/`cached` (default)/`live` | Web search mode |
| `history.persistence` | `save-all`/`none` | Session saving |
| `features.multi_agent` | boolean | Multi-agent tools (on by default) |
| `features.fast_mode` | boolean | Fast mode |
| `tools.update_plan.enabled` | boolean | Planning tool (off by default since 0.152) |

Profiles: `-p <name>` layers `$CODEX_HOME/<name>.config.toml` over the base config.

## Common Patterns

```bash
# Code review with stdin (file appended as <stdin> block)
codex exec -s read-only "Review this for bugs:" < main.py

# Review uncommitted changes in the current repo
codex exec review --uncommitted

# Default model at higher effort for hard problems
codex exec -c model_reasoning_effort='"high"' "Find the race condition:" < worker.py

# Frontier model for the hardest problems
codex exec -m gpt-6-astra "Optimize this algorithm:" < algo.py

# Cheap/fast model for light tasks
codex exec -m gpt-6-luna "Add type hints:" < utils.py

# Allow edits for scripting
codex exec --sandbox workspace-write "Fix the failing tests"

# Structured result for parsing
codex exec --output-schema bugs.schema.json -o bugs.json "Find bugs:" < code.py
jq '.bugs[]' bugs.json

# No input to feed? Close stdin so Codex doesn't wait on it
codex exec "Summarize the README" < /dev/null
```

## Troubleshooting

### Authentication Errors
- **"Not authenticated"**: Run `codex login`
- **"API key invalid"**: Check `CODEX_API_KEY` / `OPENAI_API_KEY`, or use `codex login --with-api-key`
- **"Rate limit exceeded"**: Wait and retry, or check usage limits

### Common Issues
- **Command not found**: `npm install -g @openai/codex` or `brew install codex`
- **`unexpected argument '--search'`**: put `--search` before `exec` (`codex --search exec …`) or use `-c web_search='"live"'`
- **`unexpected argument '-a'` / `'--full-auto'`**: neither exists on `codex exec`; pick a `--sandbox` (and `--approve-for-me` if you want automatic approvals)
- **Hangs with no output**: stdin is an open pipe — add `< /dev/null`
- **Model not available**: some models (e.g. `gpt-6-astra`) depend on plan; check `codex debug models`
- **Sandbox permission denied**: change `-s` or add `--add-dir`

### Fallback Strategy
If Codex is unavailable, use Claude with `--model opus` (or `--model sonnet` for everyday work) for similar code-review quality. Gemini is a fallback only for supported enterprise or paid API-key accounts.
