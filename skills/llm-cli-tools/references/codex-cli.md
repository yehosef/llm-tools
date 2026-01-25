# Codex CLI Reference

## Installation

See [README.md](../../../README.md#prerequisites) for installation instructions.

Quick: `npm install -g @openai/codex` or `brew install --cask codex`

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

## Available Models (Updated 2026-01)

**Best for Code Review:**
- `gpt-5.2-codex` - **Recommended** - Latest Codex, based on GPT-5 (confirmed working)
- `o3` - OpenAI reasoning model (may require specific access)

**General Purpose:**
- `gpt-4o` - GPT-4 Omni
- `o3-mini` - Lighter reasoning model

**Note:** `gpt-5.2-codex` is the most capable for code review tasks. Use `-m gpt-5.2-codex` for best results.

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

## Troubleshooting

### Authentication Errors
- **"Not authenticated"**: Run `codex login` to authenticate with OpenAI
- **"API key invalid"**: Check `OPENAI_API_KEY` environment variable
- **"Rate limit exceeded"**: Wait and retry, or check OpenAI usage limits

### Common Issues
- **Command not found**: Run `npm install -g @openai/codex` or `brew install --cask codex`
- **Model not available**: Some models (o3) may require specific API access. Try `gpt-4o` as fallback
- **Sandbox permission denied**: Adjust `-s` sandbox mode or use `--add-dir` for additional access

### Rate Limits
- Rate limits vary by OpenAI tier. Check platform.openai.com for your quota
- o3 and gpt-5 models may have stricter limits than gpt-4o

### Fallback Strategy
If Codex is unavailable, try Claude with `--model opus` for similar code review quality, or Gemini for speed.
