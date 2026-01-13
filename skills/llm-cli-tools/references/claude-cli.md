# Claude CLI Reference

## Installation

```bash
npm install -g @anthropic-ai/claude-code
```

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

# From stdin
cat file.py | claude -p "Review this code"

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

- `opus` / `claude-opus-4-5-20251101` - Most capable
- `sonnet` / `claude-sonnet-4-5-20250929` - Balanced
- `haiku` / `claude-haiku-4-5-20251001` - Fastest

## Permission Modes

- `default` - Normal permission prompts
- `plan` - Planning mode only
- `acceptEdits` - Auto-accept file edits
- `bypassPermissions` - Skip all checks (dangerous)
- `dontAsk` - Never prompt

## Common Patterns

```bash
# Quick review with opus
claude -p "Review this code: $(cat main.py)" --model opus

# Structured output
claude -p "List issues in: $(cat code.py)" --output-format json

# Budget-limited task
claude -p "Analyze this codebase" --max-budget-usd 5.00

# Fresh context (no history)
claude -p "Second opinion on: $(cat plan.md)" --model sonnet

# Custom persona
claude -p "Review for security: $(cat api.py)" --system-prompt "You are a security auditor"
```

## Use Cases for Fresh Claude Context

- Current conversation has too much context
- Need opus-level reasoning on something specific
- Want unbiased second opinion
- Testing different system prompts
