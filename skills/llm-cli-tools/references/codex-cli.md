# Codex CLI Reference

## Installation

```bash
npm install -g @openai/codex
# or
brew install --cask codex
```

## Authentication

Run `codex login` or set `OPENAI_API_KEY` environment variable.

## Non-Interactive Usage

```bash
# Execute prompt non-interactively
codex exec "Your prompt here"
codex e "Your prompt here"  # alias

# Code review mode
codex review

# With specific model
codex exec -m o3 "prompt"
codex exec -m gpt-4o "prompt"

# Full auto mode (workspace-write sandbox, minimal prompts)
codex exec --full-auto "prompt"

# With image input
codex exec -i screenshot.png "What's in this image?"
```

## All Options

| Flag | Description |
|------|-------------|
| `-m, --model <model>` | Model to use (o3, gpt-4o, etc.) |
| `-s, --sandbox <mode>` | `read-only`, `workspace-write`, `danger-full-access` |
| `-a, --ask-for-approval <policy>` | `untrusted`, `on-failure`, `on-request`, `never` |
| `--full-auto` | Convenience: `-a on-request --sandbox workspace-write` |
| `-i, --image <file>` | Attach image(s) to prompt |
| `-C, --cd <dir>` | Set working directory |
| `--add-dir <dir>` | Additional writable directories |
| `--search` | Enable web search tool |
| `-c, --config <key=value>` | Override config values |
| `--oss` | Use local model (LM Studio/Ollama) |
| `--local-provider <provider>` | `lmstudio` or `ollama` |
| `-p, --profile <name>` | Use config profile |

## Commands

```bash
codex exec "prompt"     # Non-interactive execution
codex review            # Code review mode
codex login             # Authenticate
codex logout            # Remove credentials
codex resume            # Resume previous session
codex apply             # Apply latest diff as git apply
codex sandbox           # Run in sandbox
codex mcp               # MCP server management
```

## Sandbox Modes

- `read-only` - Can only read files (safest)
- `workspace-write` - Can write to workspace
- `danger-full-access` - Full system access (dangerous)

## Approval Policies

- `untrusted` - Only trusted commands run without approval
- `on-failure` - Ask only if command fails
- `on-request` - Model decides when to ask
- `never` - Never ask (dangerous)

## Available Models

- `o3`, `o3-mini` - OpenAI reasoning models
- `gpt-4o` - GPT-4 Omni
- `gpt-5.2-codex` - Latest Codex model
- Check config for current default

## Common Patterns

```bash
# Quick code review
codex exec "Review this for bugs: $(cat main.py)"

# With specific model
codex exec -m o3 "Optimize this algorithm: $(cat algo.py)"

# Full auto for scripting
codex exec --full-auto "Fix the tests in this file: $(cat test.py)"

# Safe read-only analysis
codex exec -s read-only "Analyze the architecture of this codebase"
```
