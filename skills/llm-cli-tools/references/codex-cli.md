# Codex CLI Reference

## Installation

See [README.md](../../../README.md#prerequisites) for installation instructions.

Quick: `npm install -g @openai/codex` or `brew install codex`

**Version check:** `codex --version` may hang in some environments (known issue). Use `codex exec -V` instead — it returns immediately (e.g. `codex-cli-exec 0.125.0`).

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
codex exec -m gpt-5.4 "prompt"
codex exec -m o3 "prompt"

# With stdin file content (appended as <stdin> block)
codex exec "Review this code:" < file.py

# Full auto mode (workspace-write sandbox, minimal prompts)
# ⚠️  WARNING: Only use in trusted repos with no secrets
codex exec --full-auto "prompt"

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
| `--full-auto` | | Convenience: `-a on-request --sandbox workspace-write` |
| `--dangerously-bypass-approvals-and-sandbox` | | Skip all confirmation prompts and sandboxing. ⚠️ Intended only for externally-sandboxed environments. |
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

> **Note on `--yolo`:** OpenAI's CLI reference page documents `--yolo` as an alias for `--dangerously-bypass-approvals-and-sandbox`, but it is **not** present in every installed build (not present in `codex-cli 0.125.0` on macOS). Prefer `--dangerously-bypass-approvals-and-sandbox` for portability.

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
codex apply            # Apply latest diff from cloud task (alias: a)
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
```

## Sandbox Modes

- `read-only` - Can only read files (safest, **recommended**)
- `workspace-write` - Can write to workspace
- `danger-full-access` - ⚠️ Full system access (avoid unless necessary)

## Approval Policies

- `untrusted` - Only trusted commands run without approval (**recommended**)
- `on-failure` - ⚠️ DEPRECATED. Run everything; escalate only on failure. Prefer `on-request` (interactive) or `never` (non-interactive).
- `on-request` - Model decides when to ask
- `never` - ⚠️ Never ask (dangerous)

## Available Models

**Current (available in Codex CLI):**
- `gpt-5.5` - **Newest flagship** - available in Codex when signed in via ChatGPT (not API-key auth). Recommended for complex coding, computer use, knowledge work. Context window: presumed to match the gpt-5.4 family (~1M input, 128K output) but not yet confirmed publicly — verify in your account.
- `gpt-5.4` - **Default (API-key auth)** - 1.05M total window (922K input + 128K output), native computer use. Use if `gpt-5.5` isn't available in your account.
- `gpt-5.4-mini` - Fast/efficient, 400K context (128K output), ~2x faster at ~1/3 cost
- `gpt-5.3-codex` - Code-specialized (powers gpt-5.4 coding capabilities), 400K context (128K output)
- `gpt-5.3-codex-spark` - Near-instant real-time coding. Research preview, ChatGPT Pro only; not available via API key. 128K context, text-only.

**Reasoning Models:**
- `o3` - Most capable reasoning model
- `o4-mini` - Lighter reasoning model. ⚠️ Retired from ChatGPT (Feb 2026) but still available via API and Codex CLI.

**API-only (NOT available via Codex CLI):**
- `gpt-5.4-nano` - Lightest/cheapest, 400K context. OpenAI API only; not in Codex CLI model list.

**Note:** Default (no -m) uses `gpt-5.4` (with API key) or `gpt-5.5` (with ChatGPT auth). Use `-m o3` for complex reasoning tasks, `-m gpt-5.4-mini` for speed/cost savings.

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

# With reasoning model
codex exec -m o3 "Optimize this algorithm:" < algo.py

# Full auto for scripting
codex exec --full-auto "Fix the tests in this file:" < test.py

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
- o3 and gpt-5 models may have stricter limits

### Fallback Strategy
If Codex is unavailable, try Claude with `--model opus` for similar code review quality, or Gemini for speed.
