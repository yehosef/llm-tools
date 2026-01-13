# Gemini CLI Reference

## Installation

```bash
npm install -g @google/gemini-cli
```

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

## Available Models

- `gemini-2.0-flash` - Fast, default
- `gemini-2.0-pro` - More capable
- Check latest: `gemini --help`

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
