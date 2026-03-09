# Claude CLI Reference

## Installation

See [README.md](../../../README.md#prerequisites) for installation instructions.

Quick: `npm install -g @anthropic-ai/claude-code`

## Authentication

- Run `claude` interactively and use `/login`
- Or set `ANTHROPIC_API_KEY` environment variable
- `claude auth` - manage authentication
- `claude setup-token` - set up long-lived auth token (requires Claude subscription)

## Non-Interactive Usage

```bash
# Print mode - execute and exit
claude -p "Your prompt here"

# With model selection
claude -p "prompt" --model opus
claude -p "prompt" --model sonnet
claude -p "prompt" --model haiku

# Full model names also work
claude -p "prompt" --model claude-sonnet-4-6

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

# Effort level (low/medium/high)
claude -p "prompt" --effort high

# Enable 1M context window (beta)
claude -p "prompt" --betas context-1m-2025-08-07
```

## All Options

| Flag | Description |
|------|-------------|
| `-p, --print` | Non-interactive mode (required for scripting) |
| `--model <model>` | Model: `opus`, `sonnet`, `haiku` or full name |
| `--effort <level>` | Effort level: `low`, `medium`, `high` |
| `--output-format <format>` | `text`, `json`, `stream-json` |
| `--input-format <format>` | Input: `text` (default), `stream-json` |
| `--json-schema <schema>` | JSON schema for structured output |
| `--max-budget-usd <amount>` | Spending limit (only with `--print`) |
| `--system-prompt <prompt>` | Custom system prompt |
| `--append-system-prompt <prompt>` | Append to default system prompt |
| `-c, --continue` | Continue most recent conversation |
| `-r, --resume [value]` | Resume by session ID or interactive picker |
| `--fork-session` | Fork into new session when resuming (use with `-r` or `-c`) |
| `--from-pr [value]` | Resume session linked to a PR (by number/URL or interactive picker) |
| `--session-id <uuid>` | Use specific session ID |
| `--no-session-persistence` | Don't save session to disk (only with `--print`) |
| `--permission-mode <mode>` | `default`, `plan`, `acceptEdits`, `bypassPermissions`, `dontAsk`, `auto` |
| `--fallback-model <model>` | Fallback if primary overloaded (only with `--print`) |
| `--add-dir <dirs>` | Additional directories for tool access |
| `--allowed-tools <tools>` | Allowed tools (e.g., `"Bash(git:*) Edit"`) |
| `--disallowed-tools <tools>` | Denied tools |
| `--tools <tools>` | Specify available tools: `""` (none), `"default"` (all), or tool names |
| `--mcp-config <configs>` | MCP server config from JSON files or strings (space-separated) |
| `--strict-mcp-config` | Only use MCP servers from `--mcp-config`, ignore all others |
| `--agent <agent>` | Agent for the current session |
| `--agents <json>` | Define custom agents as JSON |
| `--betas <betas>` | Beta headers for API requests (API key users only) |
| `--chrome` / `--no-chrome` | Enable/disable Chrome integration |
| `--settings <file-or-json>` | Additional settings from file or JSON string |
| `--setting-sources <sources>` | Setting sources to load: `user`, `project`, `local` |
| `--plugin-dir <paths>` | Load plugins from directories (repeatable) |
| `--disable-slash-commands` | Disable all skills |
| `-w, --worktree [name]` | Create git worktree for this session |
| `--tmux` | Create tmux session for worktree (requires `--worktree`) |
| `--verbose` | Override verbose mode from config |
| `-d, --debug [filter]` | Debug mode with optional category filter |
| `--debug-file <path>` | Write debug logs to file |

## Commands

```bash
claude                  # Interactive mode
claude -p "prompt"      # Print mode
claude agents           # List configured agents
claude auth             # Manage authentication
claude doctor           # Health check
claude install          # Install native build (stable, latest, or version)
claude mcp              # MCP management
claude plugin           # Plugin management
claude setup-token      # Set up long-lived auth token
claude update           # Check for updates
```

## Available Models

**Claude 4.6 (Latest):**
- `opus` - **Best for code review** - Claude Opus 4.6, most capable (200K context, 1M in beta, 128K output)
- `sonnet` - **Default** - Claude Sonnet 4.6, best balance of speed/quality (200K context, 1M in beta, 64K output)

**Claude 4.5:**
- `haiku` - Claude Haiku 4.5, fastest for simple tasks

**Full Model IDs:**
- `claude-opus-4-6`
- `claude-sonnet-4-6`
- `claude-haiku-4-5-20251001`

**1M Context (Beta):** Opus 4.6 and Sonnet 4.6 support 1M token context via `--betas context-1m-2025-08-07`.

**Note:** For security reviews, use `opus`. For speed, use `sonnet` (default).

## Permission Modes

- `default` - Normal permission prompts (**recommended**)
- `plan` - Planning mode only (read-only)
- `auto` - Automatic permission decisions
- `acceptEdits` - Auto-accept file edits (use in trusted repos only)
- `bypassPermissions` - ⚠️ Skip all checks (dangerous, avoid)
- `dontAsk` - ⚠️ Never prompt (dangerous, avoid)

## Session Management

```bash
# Continue most recent conversation
claude -c "Follow up question"

# Resume by session ID (or interactive picker)
claude -r <session-id>
claude -r  # Opens picker

# Fork a session (new ID, preserves context)
claude -c --fork-session "Try a different approach"

# Resume from a PR
claude --from-pr 123
claude --from-pr  # Interactive picker

# Worktree session (isolated git branch)
claude -w my-feature "Implement the feature"
claude -w my-feature --tmux  # With tmux pane
```

## Agents

```bash
# Use a named agent
claude --agent reviewer

# Define inline agents
claude --agents '{"reviewer": {"description": "Reviews code", "prompt": "You are a code reviewer"}}'

# List configured agents
claude agents
```

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

# High effort reasoning
claude -p "Find subtle bugs in:" --model opus --effort high < complex.py

# 1M context for large files (beta)
claude -p "Review entire codebase:" --betas context-1m-2025-08-07 --model opus < all-source.txt

# Worktree for isolated work
claude -w feature-branch "Implement auth module"

# Ephemeral session (no persistence)
claude -p "Quick check:" --no-session-persistence < file.py
```

## Use Cases for Fresh Claude Context

- Current conversation has too much context
- Need opus-level reasoning on something specific
- Want unbiased second opinion
- Testing different system prompts

## Troubleshooting

### Authentication Errors
- **"Not authenticated"**: Run `claude auth` or `claude` interactively and use `/login`
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
If Claude is unavailable, try Gemini with default model for speed, or Codex with `-m gpt-5.3-codex` for quality.
