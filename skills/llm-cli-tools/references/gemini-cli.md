# Gemini CLI Reference

## Installation

See [README.md](../../../README.md#prerequisites) for installation instructions.

Quick: `npm install -g @google/gemini-cli`

## Authentication

1. **Google Login** (recommended): Run `gemini` and follow prompts. Free tier: 60 req/min, 1000 req/day
2. **API Key**: Set `GEMINI_API_KEY` environment variable

## Non-Interactive Usage

```bash
# Basic - positional prompt (preferred)
gemini "Your prompt here"

# With model selection
gemini -m gemini-2.0-flash "prompt"
gemini -m gemini-2.0-pro "prompt"

# JSON output for parsing
gemini -o json "prompt"

# YOLO mode - auto-approve all tool actions
gemini -y "prompt"
gemini --yolo "prompt"
gemini --approval-mode yolo "prompt"
```

## All Options

| Flag | Description |
|------|-------------|
| `-m, --model <model>` | Model to use |
| `-o, --output-format <format>` | Output: `text`, `json`, `stream-json` |
| `-y, --yolo` | Auto-approve all actions |
| `--approval-mode <mode>` | `default`, `auto_edit`, `yolo` |
| `-s, --sandbox` | Run in sandbox mode |
| `-i, --prompt-interactive` | Execute prompt then continue interactive |
| `-r, --resume <session>` | Resume session: `latest` or index number |
| `--list-sessions` | List available sessions |
| `-d, --debug` | Debug mode |
| `--allowed-tools <tools>` | Tools allowed without confirmation |
| `--include-directories <dirs>` | Additional workspace directories |
| `-e, --extensions <list>` | Extensions to use |
| `-l, --list-extensions` | List available extensions |

## Commands

```bash
gemini mcp              # Manage MCP servers
gemini extensions       # Manage extensions
```

## Available Models (Updated 2026-01)

**Current Generation (Gemini 3):**
- `gemini-3-flash` - **Recommended** - Fast, current default (1M token context)
- `gemini-3-pro` - Most capable reasoning model

**Previous Generation (Gemini 2.5):**
- `gemini-2.5-pro` - Production stable, complex reasoning
- `gemini-2.5-flash` - Fast production model

**Legacy (Gemini 2.0):**
- `gemini-2.0-flash` - Budget/legacy support
- `gemini-2.0-flash-lite` - Ultra-efficient

**Note:** Default model (no -m flag) uses Gemini 3 Flash. Some model names may require API access vs free tier. Check `gemini --help` for currently available models.

## Strengths

- **1M token context window** - largest available
- **Free tier** - 1000 req/day with Google login
- **Good at research/analysis** - different training data than Claude

## Common Patterns

```bash
# Validate a plan
gemini "Review this plan for issues: $(cat plan.md)"

# Get JSON output
gemini -o json "List 3 improvements for: $(cat code.py)"

# Auto-approve for scripting
gemini -y "Refactor this: $(cat file.py)"
```

## Troubleshooting

### Authentication Errors
- **"Not authenticated"**: Run `gemini` interactively and login with Google
- **"API key invalid"**: Check `GEMINI_API_KEY` environment variable
- **"Quota exceeded"**: Wait for rate limit reset (60 req/min, 1000 req/day on free tier)

### Common Issues
- **Command not found**: Run `npm install -g @google/gemini-cli`
- **Model not available**: Some models require API key access vs free tier. Try default model first
- **Timeout on large prompts**: 1M context is large but still has processing limits

### Rate Limits
- Free tier: 60 requests/minute, 1000 requests/day
- API key tier: Check Google AI Studio for your quota

### Fallback Strategy
If Gemini is unavailable, try Claude with `--model sonnet` for similar speed, or Codex with `-m gpt-4o`.
