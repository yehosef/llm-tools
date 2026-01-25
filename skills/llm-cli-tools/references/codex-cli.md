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
| `--json` | Output events as JSONL |
| `--output-schema <file>` | JSON Schema for structured response |

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

**Codex-Optimized:**
- `gpt-5.2-codex` - **Default** - Latest Codex, optimized for agentic coding
- `gpt-5.1-codex` - Previous generation
- `codex-mini-latest` - Smaller, cost-effective

**Reasoning Models:**
- `o3` - Most capable reasoning model
- `o4-mini` - Fast, cost-efficient reasoning

**General Purpose:**
- `gpt-5.2` - Flagship model (supports reasoning effort: low/medium/high/xhigh)
- `gpt-5-mini` - Smaller, faster

**Note:** Default (no -m) uses `gpt-5.2-codex`. Use `-m o3` for complex reasoning tasks.

## Common Patterns

```bash
# Quick code review (stdin avoids argv limits)
codex exec "Review this for bugs:" < main.py

# With specific model
codex exec -m o3 "Optimize this algorithm:" < algo.py

# Full auto for scripting
codex exec --full-auto "Fix the tests in this file:" < test.py

# Safe read-only analysis
codex exec -s read-only "Analyze the architecture of this codebase"

# JSON output for parsing
codex exec --json "Find bugs:" < code.py
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
