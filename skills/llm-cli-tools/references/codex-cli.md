# Codex CLI Reference

## Installation

```bash
npm install -g @openai/codex
# or
brew install --cask codex
```

## Authentication

First run prompts for login:
- ChatGPT account login, OR
- OpenAI API key (set `OPENAI_API_KEY`)

## Non-Interactive Usage

### Execute a Prompt
```bash
codex exec "Your prompt here"
```

This is the primary non-interactive mode. The `exec` subcommand runs the prompt and exits.

## Key Subcommands

| Command | Description |
|---------|-------------|
| `codex` | Interactive TUI mode |
| `codex exec "prompt"` | Non-interactive execution |
| `codex review` | Code review mode |
| `codex login` | Manage authentication |
| `codex resume` | Resume previous session |
| `codex apply` | Apply latest diff from agent |

## Common Use Cases

### Code Review
```bash
codex exec "Review this code for bugs and security issues:

$(cat src/main.py)"
```

### Find Patterns Claude Might Miss
```bash
codex exec "What patterns or improvements would you suggest for this code?

$(cat src/app.py)"
```

### Get OpenAI Perspective
```bash
codex exec "What are the tradeoffs of this approach from an engineering perspective?

$(cat approach.md)"
```

### Non-Interactive Code Review
```bash
codex review
```

## Strengths

- **Strong at code patterns** - Different model architecture
- **Good at finding bugs** - Different perspective than Claude
- **Integrated with OpenAI ecosystem** - Access to GPT-4o, o1 models

## Platform Support

- macOS: Full support
- Linux: Full support
- Windows: Via WSL only (experimental)

## Usage Limits

- Depends on OpenAI account type
- Check usage: https://platform.openai.com/account/usage
- No direct CLI command for remaining credits

## Error Handling

- **Not logged in**: Run `codex login` or `codex` to authenticate
- **API key issues**: Check OPENAI_API_KEY is set
- **Rate limits**: Wait and retry

## Differences from Claude

- Uses GPT-4o or o1 models (not Claude)
- Different reasoning patterns
- May catch issues Claude misses, and vice versa
- Good for cross-validation
