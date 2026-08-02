# Codex CLI Reference

## Installation

See [README.md](../../../README.md#prerequisites) for installation instructions.

Quick: `npm install -g @openai/codex` or `brew install codex`

**Audited against:** Codex CLI `0.146.0` (live model catalog via `codex debug models`) and the official Codex docs on August 2, 2026. Official docs now live at `learn.chatgpt.com/docs` (developers.openai.com redirects there).

## Authentication

- `codex login` - ChatGPT OAuth (Plus, Pro, Business, Team, Edu, Enterprise)
- `codex login --device-auth` - Device code flow
- `codex login --with-api-key` - Read API key from stdin
- `codex login status` - Check auth status
- `codex logout` - Remove credentials
- Config: `credential_store` = `file` (default) | `keyring` | `auto`

## Non-Interactive Usage

```bash
# Execute prompt non-interactively
codex exec "Your prompt here"
codex e "Your prompt here"  # alias

# With specific model
codex exec -m gpt-5.6-sol "prompt"
codex exec -m gpt-5.6-luna "prompt"

# With stdin file content (appended as <stdin> block)
codex exec "Review this code:" < file.py

# Allow workspace edits explicitly
codex exec --sandbox workspace-write "prompt"

# With image input
codex exec -i screenshot.png "What's in this image?"

# Code review (dedicated subcommand)
codex exec review

# Resume previous non-interactive session
codex exec resume

# Ignore user config or rules (useful for isolated CI runs)
codex exec --ignore-user-config --ignore-rules "prompt"
```

## All Options

### Global Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--model <model>` | `-m` | Model to use |
| `--sandbox <mode>` | `-s` | `read-only`, `workspace-write`, `danger-full-access` |
| `--ask-for-approval <policy>` | `-a` | `untrusted`, `on-failure` (DEPRECATED), `on-request`, `never` |
| `--dangerously-bypass-approvals-and-sandbox` | | Skip all confirmation prompts and sandboxing. ⚠️ Intended only for externally-sandboxed environments. |
| `--dangerously-bypass-hook-trust` | | Run enabled hooks without persisted trust. Use only in automation that already vets hook sources. |
| `--image <file>` | `-i` | Attach image(s) to prompt |
| `--cd <dir>` | `-C` | Set working directory |
| `--add-dir <dir>` | | Additional writable directories |
| `--search` | | Enable live web search tool (available in both interactive TUI and `codex exec`) |
| `--config <key=value>` | `-c` | Override config values (repeatable) |
| `--oss` | | Use local open-source model provider |
| `--local-provider <provider>` | | `lmstudio` or `ollama` (pair with `--oss`) |
| `--profile <name>` | `-p` | Use config profile |
| `--no-alt-screen` | | Disable TUI alternate screen |
| `--enable <feature>` | | Force-enable feature flag (repeatable) |
| `--disable <feature>` | | Force-disable feature flag (repeatable) |
| `--remote <addr>` | | Connect TUI to remote app server (`ws://` or `wss://`) |
| `--remote-auth-token-env <var>` | | Env var containing bearer token for remote server |
| `--strict-config` | | Error when config contains fields unknown to this CLI version |

> **Deprecated automation shortcut:** `codex exec --full-auto` remains as a compatibility flag but prints a warning. New scripts should use an explicit sandbox such as `--sandbox workspace-write`. The official reference documents `--yolo` as an alias for `--dangerously-bypass-approvals-and-sandbox`, but some builds omit the alias from `--help`; prefer the long flag for portability.

### `codex exec` Additional Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--json` | | JSONL output (includes reasoning-token usage) |
| `--output-last-message <file>` | `-o` | Write final message to file |
| `--output-schema <file>` | | JSON Schema for structured response |
| `--ephemeral` | | Skip session persistence |
| `--skip-git-repo-check` | | Allow non-git directories |
| `--ignore-user-config` | | Do not load `~/.codex/config.toml` (auth still uses `CODEX_HOME`) |
| `--ignore-rules` | | Do not load user or project `.rules` files |
| `--color <mode>` | | `always`, `never`, `auto` |

## Commands

```bash
codex                  # Interactive TUI session
codex exec "prompt"    # Non-interactive execution (alias: e)
codex exec resume      # Resume non-interactive session
codex exec review      # Dedicated code review (subcommand of exec)
codex review           # Top-level code review subcommand
codex login            # Authenticate
codex login status     # Check auth status
codex logout           # Remove credentials
codex resume           # Resume interactive session
codex fork             # Fork previous session into new thread
codex archive          # Archive a saved session
codex unarchive        # Restore an archived session
codex delete           # Permanently delete a saved session
codex apply            # Apply latest diff from cloud task (alias: a)
codex doctor           # Diagnose installation, auth, config, and runtime
codex update           # Update Codex CLI
codex sandbox          # Run command in sandbox
codex debug            # Debugging tools
codex completion       # Shell completions (bash/zsh/fish/powershell/elvish)

# MCP server management
codex mcp add          # Register MCP server
codex mcp get          # Show MCP server config
codex mcp list         # List MCP servers
codex mcp login        # OAuth login for HTTP MCP server
codex mcp logout       # Remove MCP OAuth credentials
codex mcp remove       # Delete MCP server

# Feature flags
codex features list    # Show all feature flags
codex features enable  # Enable a feature flag
codex features disable # Disable a feature flag

# Cloud tasks (experimental)
codex cloud            # Cloud task management
codex cloud exec       # Submit a new Codex Cloud task without launching the TUI
codex cloud status     # Show status of a Codex Cloud task
codex cloud list       # List recent cloud tasks
codex cloud apply      # Apply diff for a cloud task locally
codex cloud diff       # Show unified diff for a cloud task

# Desktop & servers
codex app              # Launch desktop app (macOS; downloads installer if missing)
codex app-server       # Local app server (experimental)
codex exec-server      # Standalone exec-server service (experimental, added in 0.119.0)
codex mcp-server       # Run Codex as MCP server (stdio, experimental)

# Plugin management
codex plugin marketplace add      # Add marketplace repository (GitHub, git URL, local dir, or marketplace.json URL)
codex plugin marketplace upgrade  # Upgrade configured marketplace
codex plugin marketplace remove   # Remove marketplace

# Remote app-server control
codex remote-control start
codex remote-control stop
```

## Sandbox Modes

- `read-only` - Can only read files (safest, **recommended**)
- `workspace-write` - Can write to workspace
- `danger-full-access` - ⚠️ Full system access (avoid unless necessary)

## Approval Policies

- `untrusted` - Only trusted commands run without approval (**recommended**)
- `on-failure` - ⚠️ DEPRECATED (removed from `--help` as of 0.146.0). Prefer `on-request` (interactive) or `never` (non-interactive).
- `on-request` - Model decides when to ask
- `never` - ⚠️ Never ask (dangerous)

## Available Models

**Current — GPT-5.6 family (GA July 9, 2026).** OpenAI split generation number from capability tier: Sol (flagship) / Terra (balanced) / Luna (fast). All three are multimodal (text + image), support a "fast" speed tier, and are available with both ChatGPT and API-key authentication.

| Model | Role | Reasoning efforts | Context (CLI catalog) | API price (per 1M in/out) |
|-------|------|-------------------|----------------------|---------------------------|
| `gpt-5.6-sol` | Flagship — hardest coding, deep debugging, research, long agentic runs | low/medium/high/xhigh/max/**ultra** | 272K | $5 / $30 |
| `gpt-5.6-terra` | Everyday workhorse — balanced cost/capability (≈ old gpt-5.5 quality, cheaper) | low/medium/high/xhigh/max/**ultra** | 272K | $2.50 / $15 |
| `gpt-5.6-luna` | Fast and cheap — quick edits, subagents, high-volume | low/medium/high/xhigh/max | 272K | $1 / $6 |

- Default reasoning effort: `low` for Sol, `medium` for Terra/Luna (per the live catalog as of Aug 2, 2026 — Sol's default dropped from `medium`). `ultra` (Sol/Terra only) is maximum reasoning **with automatic task delegation** to subagents.
- **Context caveat — got worse, not better:** the API spec for GPT-5.6 advertises 1.05M input / 128K output, but the Codex CLI cap was cut from 372K to **272K** raw (~258K effective) on July 13, 2026, formalized in v0.144.6. The 272K boundary tracks a billing tier (above it, requests price at 2× input / 1.5× output), not a technical limit. Restoration requests (openai/codex#31860, #32806, #34619) remain open. Treat ~250K effective as the practical CLI limit.

**Legacy options (still in the catalog):**
- `gpt-5.5` - Previous flagship (272K context in CLI). Fine as a fallback.
- `gpt-5.4` - Older flagship; the one model with a 1M max window in the CLI catalog. **Retires from Codex Aug 31, 2026** (ChatGPT auth) — migrate to `gpt-5.6-terra`.
- `gpt-5.4-mini` - Small/cheap. **Retires Aug 31, 2026** — migrate to `gpt-5.6-luna`.
- `gpt-5.3-codex-spark` - Near-instant real-time coding, ChatGPT Pro research preview. No longer appears in the standard-account catalog (access-dependent).

`gpt-5.2` and `gpt-5.3-codex` are deprecated for ChatGPT sign-in. Avoid them in new examples. A hidden `codex-auto-review` model backs the review subcommands.

**Note:** Without `-m`, Codex selects a recommended model for the account (currently resolves to `gpt-5.6-sol` at `low` for standard accounts). Use `codex debug models` to inspect the effective catalog and `codex debug models --bundled` to inspect the catalog shipped with the binary. Set reasoning effort via `/model` (interactive) or `model_reasoning_effort` in `config.toml`.

## Multimodal Capabilities

| Modality | Input | Output (generation) |
|----------|-------|---------------------|
| Image (PNG/JPEG/GIF/WebP) | ✅ `-i/--image` flag (repeatable); paste in TUI | ✅ Built-in `image_gen` tool (gpt-image-2) |
| Audio | ✅ Local audio file inputs (since v0.145.0); realtime voice mode in TUI | ❌ No TTS output tool |
| Video | ❌ | ❌ |
| PDF | ❌ No native PDF attach (convert to images or paste text) | ❌ |

**Image input:** all three GPT-5.6 models (Sol/Terra/Luna) accept images. Attach explicitly — Codex won't browse for images on its own. Keep files under ~5MB.

```bash
codex exec -i screenshot.png "What's wrong in this UI?"
codex exec -i before.png -i after.png "What changed between these?"
```

**Image generation:** built into the CLI as the `image_gen` tool (bundled `imagegen` skill), backed by **gpt-image-2** — no separate API key needed. Invoke via natural language ("generate an image of..."), `$imagegen`, or `/skills`. Output lands in `~/.codex/generated_images/`.

```bash
codex exec "Generate a 1024x1024 hero image of a lighthouse at dawn, save it here" --sandbox workspace-write
```

**Audio:** v0.145.0 (July 21, 2026) added audio file inputs and realtime V3 streaming; the TUI also supports push-to-talk dictation and full two-way realtime voice (WebRTC, config via `[realtime]` in config.toml).

⚠️ **`-i` flag collision:** in Codex `-i` = `--image`; in Gemini `-i` = `--prompt-interactive`. Don't copy commands between tools blindly.

## Config File (`~/.codex/config.toml`)

Key options:

| Key | Values | Description |
|-----|--------|-------------|
| `model` | string | Default model |
| `service_tier` | `flex` / `fast` | Processing tier |
| `model_reasoning_effort` | varies | Reasoning intensity |
| `model_reasoning_summary` | `auto`/`concise`/`detailed`/`none` | Reasoning output |
| `model_verbosity` | `low`/`medium`/`high` | Output detail |
| `approval_policy` | untrusted/on-request/never | Approval rules |
| `sandbox_mode` | read-only/workspace-write/danger-full-access | Sandbox |
| `history.persistence` | `save-all`/`none` | Session saving |
| `tools.web_search` | `disabled`/`cached`/`live` | Web search mode |
| `permissions.network.enabled` | boolean | Network proxy |
| `permissions.network.allowed_domains` | list | Domain allowlist |
| `features.multi_agent` | boolean | Multi-agent tools |
| `features.undo` | boolean | Undo support |
| `features.fast_mode` | boolean | Fast mode |

## Common Patterns

```bash
# Code review with stdin (file appended as <stdin> block)
codex exec "Review this for bugs:" < main.py

# Code review (dedicated subcommand)
codex exec review

# Flagship model for hard problems
codex exec -m gpt-5.6-sol "Optimize this algorithm:" < algo.py

# Cheap/fast model for light tasks
codex exec -m gpt-5.6-luna "Add type hints:" < utils.py

# Allow edits for scripting
codex exec --sandbox workspace-write "Fix the tests in this file:" < test.py

# Safe read-only analysis
codex exec -s read-only "Analyze the architecture of this codebase"

# JSON output for parsing
codex exec --json "Find bugs:" < code.py

# Shell completions
codex completion bash >> ~/.bashrc
codex completion fish > ~/.config/fish/completions/codex.fish
```

## Troubleshooting

### Authentication Errors
- **"Not authenticated"**: Run `codex login` to authenticate
- **"API key invalid"**: Check `OPENAI_API_KEY` or use `codex login --with-api-key`
- **"Rate limit exceeded"**: Wait and retry, or check OpenAI usage limits

### Common Issues
- **Command not found**: Run `npm install -g @openai/codex` or `brew install codex`
- **Model not available**: Some models require specific API access. Try default model as fallback
- **Sandbox permission denied**: Adjust `-s` sandbox mode or use `--add-dir` for additional access

### Rate Limits
- Rate limits vary by OpenAI tier. Check platform.openai.com for your quota
- Larger models and high reasoning effort may have stricter limits

### Fallback Strategy
If Codex is unavailable, try Claude with `--model opus` (or `--model sonnet` for everyday work) for similar code review quality. Gemini is a fallback only for supported enterprise or paid API-key accounts.
