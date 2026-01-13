# Gemini CLI Reference

## Installation

```bash
npm install -g @google/gemini-cli
```

## Authentication

Two options:
1. **Google Login** (recommended for personal use):
   - Run `gemini` and follow login prompts
   - Free tier: 60 req/min, 1000 req/day

2. **API Key**:
   - Get key from Google AI Studio
   - Set `GEMINI_API_KEY` environment variable

## Non-Interactive Usage

### Basic Usage
```bash
gemini "Your prompt here"
```

### With Model Selection
```bash
gemini -m gemini-2.0-flash "prompt"   # Fast, default
gemini -m gemini-2.0-pro "prompt"     # More capable
```

### Headless/Script Mode
```bash
gemini "prompt" --output-format json
```

### YOLO Mode (Auto-approve all actions)
```bash
gemini -y "prompt"
gemini --yolo "prompt"
```

## Key Flags

| Flag | Description |
|------|-------------|
| `-m, --model` | Model to use |
| `-y, --yolo` | Auto-approve all actions |
| `--output-format` | Output format: json for structured |
| `-i, --prompt-interactive` | Execute prompt then stay interactive |
| `-s, --sandbox` | Run in sandbox mode |
| `--approval-mode` | default, auto_edit, or yolo |

## In-CLI Commands

If running interactively:
- `/help` - Show help
- `/clear` - Clear screen
- `/compress` - Summarize context to save tokens
- `/copy` - Copy last output
- `/settings` - Configure behavior

## Common Use Cases

### Validate a Plan (Large Context)
```bash
gemini "Review this implementation plan. What issues or blind spots do you see?

$(cat plan.md)"
```

### Research/Analysis
```bash
gemini "Analyze this codebase structure and suggest improvements:

$(find src -name '*.py' -exec head -20 {} \;)"
```

### Get Alternative Perspective
```bash
gemini "What would be a different approach to solve this problem?

$(cat problem.md)"
```

## Strengths

- **1M token context window** - Can handle very large inputs
- **Good at research tasks** - Different training data than Claude
- **Free tier available** - 1000 requests/day with Google login

## Usage Limits

- Free tier: 60 req/min, 1000 req/day
- Check usage in Google Cloud Console or AI Studio
- No direct CLI command for usage stats

## Error Handling

- **Not authenticated**: Run `gemini` interactively to login
- **Rate limit**: Wait a minute, or use API key for higher limits
- **Model not found**: Check available models with `gemini --help`
