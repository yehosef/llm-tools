# Claude CLI Reference

## Installation

See [README.md](../../../README.md#prerequisites) for installation instructions.

Quick: `npm install -g @anthropic-ai/claude-code`

## Authentication

Run `claude` interactively and use `/login`, or set `ANTHROPIC_API_KEY`.

## Non-Interactive Usage

```bash
# Print mode - execute and exit
claude -p "Your prompt here"

# With model selection
claude -p "prompt" --model opus
claude -p "prompt" --model sonnet
claude -p "prompt" --model haiku

# Full model names also work
claude -p "prompt" --model claude-sonnet-4-5-20250929

# JSON output
claude -p "prompt" --output-format json

# Structured output with schema
claude -p "List 3 bugs" --json-schema '{"type":"array","items":{"type":"string"}}'

# From stdin (avoids argv limits on large files)
claude -p "Review this code" < file.py

# With budget limit
claude -p "prompt" --max-budget-usd 1.00

# Custom system prompt
claude -p "prompt" --system-prompt "You are a security expert"
```

## All Options

| Flag | Description |
|------|-------------|
| `-p, --print` | Non-interactive mode (required for scripting) |
| `--model <model>` | Model: `opus`, `sonnet`, `haiku` or full name |
| `--output-format <format>` | `text`, `json`, `stream-json` |
| `--json-schema <schema>` | JSON schema for structured output |
| `--max-budget-usd <amount>` | Spending limit |
| `--system-prompt <prompt>` | Custom system prompt |
| `--append-system-prompt <prompt>` | Append to default system prompt |
| `-c, --continue` | Continue most recent conversation |
| `-r, --resume <session>` | Resume by session ID |
| `--permission-mode <mode>` | `default`, `plan`, `acceptEdits`, `bypassPermissions`, `dontAsk` |
| `--fallback-model <model>` | Fallback if primary overloaded |
| `--add-dir <dirs>` | Additional directories for tool access |
| `--allowed-tools <tools>` | Allowed tools (e.g., "Bash(git:*) Edit") |
| `--disallowed-tools <tools>` | Denied tools |
| `--mcp-config <config>` | MCP server configuration |
| `-d, --debug [filter]` | Debug mode |

## Commands

```bash
claude                  # Interactive mode
claude -p "prompt"      # Print mode
claude doctor           # Health check
claude mcp              # MCP management
claude plugin           # Plugin management
claude update           # Check for updates
```

## Available Models

**Claude 4.5 (Latest):**
- `opus` - **Best for code review** - Claude Opus 4.5, most capable
- `sonnet` - **Default** - Claude Sonnet 4.5, best balance of speed/quality
- `haiku` - Claude Haiku 4.5, fastest for simple tasks

**Full Model Names:**
- `claude-opus-4-5-20251101`
- `claude-sonnet-4-5-20250929`
- `claude-haiku-4-5-20251001`

**Note:** For security reviews, use `opus`. For speed, use `sonnet` (default).

## Permission Modes

- `default` - Normal permission prompts
- `plan` - Planning mode only
- `acceptEdits` - Auto-accept file edits
- `bypassPermissions` - Skip all checks (dangerous)
- `dontAsk` - Never prompt

## Common Patterns

```bash
# Quick review with opus (stdin avoids argv limits)
claude -p "Review this code:" --model opus < main.py

# Structured output
claude -p "List issues in:" --output-format json < code.py

# Budget-limited task
claude -p "Analyze this codebase" --max-budget-usd 5.00

# Fresh context (no history)
claude -p "Second opinion on:" --model sonnet < plan.md

# Custom persona
claude -p "Review for security:" --system-prompt "You are a security auditor" < api.py
```

## Use Cases for Fresh Claude Context

- Current conversation has too much context
- Need opus-level reasoning on something specific
- Want unbiased second opinion
- Testing different system prompts

## Troubleshooting

### Authentication Errors
- **"Not authenticated"**: Run `claude` interactively and use `/login`
- **"API key invalid"**: Check `ANTHROPIC_API_KEY` environment variable
- **"Rate limit exceeded"**: Wait and retry, or reduce request frequency

### Common Issues
- **Command not found**: Run `npm install -g @anthropic-ai/claude-code`
- **Model not available**: Verify model name (use `opus`, `sonnet`, or `haiku`)
- **Budget exceeded**: Increase `--max-budget-usd` or start new session

### Rate Limits
- Rate limits vary by API tier. Check console.anthropic.com for your quota
- Use `--max-budget-usd` to control spending per request

### Fallback Strategy
If Claude is unavailable, try Gemini with default model for speed, or Codex with `-m gpt-5.2-codex` for quality.
