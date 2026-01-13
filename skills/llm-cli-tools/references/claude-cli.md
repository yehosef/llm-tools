# Claude CLI Reference

## Installation

```bash
npm install -g @anthropic-ai/claude-code
```

## Authentication

Claude CLI uses your existing Claude Code authentication or API key:
- Interactive login: Run `claude` and use `/login`
- API key: Set `ANTHROPIC_API_KEY` environment variable

## Non-Interactive Usage

### Basic Print Mode
```bash
claude -p "Your prompt here"
```

### With Model Selection
```bash
claude -p "prompt" --model opus    # Claude Opus (most capable)
claude -p "prompt" --model sonnet  # Claude Sonnet (balanced)
claude -p "prompt" --model haiku   # Claude Haiku (fastest)
```

### Reading from Stdin
```bash
cat code.py | claude -p "Review this code"
echo "Explain this" | claude -p
```

### Output Formats
```bash
claude -p "prompt" --output-format text   # Default
claude -p "prompt" --output-format json   # Structured JSON
```

## Key Flags

| Flag | Description |
|------|-------------|
| `-p, --print` | Print mode - non-interactive, outputs and exits |
| `--model <model>` | Select model: opus, sonnet, haiku |
| `--output-format <format>` | Output format: text, json, stream-json |
| `--max-budget-usd <amount>` | Maximum spend limit |
| `--system-prompt <prompt>` | Custom system prompt |
| `-c, --continue` | Continue most recent conversation |

## Common Use Cases

### Fresh Context Validation
```bash
claude -p "Review this plan for issues: $(cat plan.md)" --model opus
```

### Quick Code Check
```bash
cat src/main.py | claude -p "Find bugs in this code" --model sonnet
```

### Get Different Model Perspective
```bash
# If main conversation is sonnet, get opus opinion
claude -p "What are the tradeoffs of this approach? $(cat approach.md)" --model opus
```

## Usage Limits

Check usage at: https://console.anthropic.com/settings/plans
- No CLI command to check remaining credits
- Monitor through Anthropic dashboard

## Error Handling

- **Not logged in**: Run `claude` interactively, then `/login`
- **API key issues**: Check ANTHROPIC_API_KEY is set correctly
- **Rate limits**: Wait and retry, or reduce request size
