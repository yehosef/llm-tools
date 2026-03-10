# Codex CLI Reference

## Installation

See [README.md](../../../README.md#prerequisites) for installation instructions.

Quick: `npm install -g @openai/codex` or `brew install codex`

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

# Full auto mode (workspace-write sandbox, minimal prompts)
# ⚠️  WARNING: Only use in trusted repos with no secrets
codex exec --full-auto "prompt"

# With image input
codex exec -i screenshot.png "What's in this image?"

# Resume previous non-interactive session
codex exec resume
```

## All Options

### Global Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--model <model>` | `-m` | Model to use |
| `--sandbox <mode>` | `-s` | `read-only`, `workspace-write`, `danger-full-access` |
| `--ask-for-approval <policy>` | `-a` | `untrusted`, `on-request`, `never` |
| `--full-auto` | | Convenience: `-a on-request --sandbox workspace-write` |
| `--image <file>` | `-i` | Attach image(s) to prompt |
| `--cd <dir>` | `-C` | Set working directory |
| `--add-dir <dir>` | | Additional writable directories |
| `--search` | | Enable web search tool |
| `--config <key=value>` | `-c` | Override config values (repeatable) |
| `--oss` | | Use local model (Ollama) |
| `--profile <name>` | `-p` | Use config profile |
| `--no-alt-screen` | | Disable TUI alternate screen |
| `--enable <feature>` | | Force-enable feature flag (repeatable) |
| `--disable <feature>` | | Force-disable feature flag (repeatable) |
| `--yolo` | | Bypass all safety checks (alias for `--dangerously-bypass-approvals-and-sandbox`) |

### `codex exec` Additional Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--json` | | JSONL output |
| `--output-last-message <file>` | `-o` | Write final message to file |
| `--output-schema <file>` | | JSON Schema for structured response |
| `--ephemeral` | | Skip session persistence |
| `--skip-git-repo-check` | | Allow non-git directories |
| `--color <mode>` | | `always`, `never`, `auto` |

## Commands

```bash
codex                  # Interactive TUI session
codex exec "prompt"    # Non-interactive execution (alias: e)
codex exec resume      # Resume non-interactive session
codex login            # Authenticate
codex login status     # Check auth status
codex logout           # Remove credentials
codex resume           # Resume interactive session
codex fork             # Fork previous session into new thread
codex apply            # Apply latest diff from cloud task (alias: a)
codex sandbox          # Run command in sandbox
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
codex cloud list       # List recent cloud tasks (--json, --limit 1-20)

# Desktop & server
codex app              # Launch desktop app (macOS)
codex app-server       # Local app server (experimental)
codex mcp-server       # Run Codex as MCP server (experimental)
```

## Sandbox Modes

- `read-only` - Can only read files (safest, **recommended**)
- `workspace-write` - Can write to workspace
- `danger-full-access` - ⚠️ Full system access (avoid unless necessary)

## Approval Policies

- `untrusted` - Only trusted commands run without approval (**recommended**)
- `on-request` - Model decides when to ask
- `never` - ⚠️ Never ask (dangerous)

## Available Models

**Latest:**
- `gpt-5.4` - **Flagship** - Latest model, 1.05M context (922K input + 128K output), native computer use
- `gpt-5.3-codex` - Industry-leading coding model
- `gpt-5.3-codex-spark` - Near-instant real-time coding (ChatGPT Pro only)

**Previous Generation (still available):**
- `gpt-5.2-codex` - Previous default coding model
- `gpt-5.2` - Previous flagship (supports reasoning effort: low/medium/high/xhigh)
- `gpt-5.1-codex` / `gpt-5.1-codex-max` / `gpt-5.1` - Older
- `gpt-5-codex` / `gpt-5-codex-mini` / `gpt-5` - Legacy

**Reasoning Models:**
- `o3` - Most capable reasoning model

**Note:** Default (no -m) uses `gpt-5.4`. Use `-m o3` for complex reasoning tasks, `-m gpt-5.3-codex` for code-specialized work.

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
# Quick code review (embed file in prompt for small files)
codex exec "Review this for bugs: $(cat main.py)"

# For larger files: pipe prompt+file as stdin (no positional arg)
bash -c '{ echo "Review this for bugs:"; cat main.py; } | codex exec'

# With reasoning model
codex exec -m o3 "Optimize this algorithm: $(cat algo.py)"

# Full auto for scripting
codex exec --full-auto "Fix the tests in this file: $(cat test.py)"

# Safe read-only analysis
codex exec -s read-only "Analyze the architecture of this codebase"

# JSON output for parsing
bash -c '{ echo "Find bugs:"; cat code.py; } | codex exec --json'

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
