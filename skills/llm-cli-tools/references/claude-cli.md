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

# Effort level (low/medium/high/xhigh/max)
claude -p "prompt" --effort high
claude -p "prompt" --effort xhigh  # Opus 4.7 only, recommended default for agentic tasks
claude -p "prompt" --effort max    # Deepest reasoning (any supported model)
```

## All Options

| Flag | Description |
|------|-------------|
| `-p, --print` | Non-interactive mode (required for scripting) |
| `--model <model>` | Model: `opus`, `sonnet`, `haiku`, `opusplan`, `best`, `default` or full name |
| `--effort <level>` | Effort level: `low`, `medium`, `high`, `xhigh`, `max`. `xhigh` is Opus-4.7-only (silently degrades to `high` on older models). |
| `--fallback-model <model>` | Fallback if primary overloaded (only with `--print`) |
| `--output-format <format>` | `text`, `json`, `stream-json` |
| `--input-format <format>` | Input: `text` (default), `stream-json` |
| `--json-schema <schema>` | JSON schema for structured output |
| `--max-budget-usd <amount>` | Spending limit (only with `--print`) |
| `--system-prompt <prompt>` | Custom system prompt |
| `--append-system-prompt <prompt>` | Append to default system prompt |
| `--exclude-dynamic-system-prompt-sections` | Move per-machine context (cwd, env, memory paths, git status) from the system prompt into the first user message; improves cross-user cache reuse. Default-prompt only. |
| `-c, --continue` | Continue most recent conversation |
| `-r, --resume [value]` | Resume by session ID or interactive picker |
| `--fork-session` | Fork into new session when resuming (use with `-r` or `-c`) |
| `--from-pr [value]` | Resume session linked to a PR (by number/URL or interactive picker) |
| `--session-id <uuid>` | Use specific session ID |
| `-n, --name <name>` | Display name for the session (shown in prompt box, /resume picker, terminal title) |
| `--no-session-persistence` | Don't save session to disk (only with `--print`) |
| `--permission-mode <mode>` | `default`, `plan`, `acceptEdits`, `bypassPermissions`, `dontAsk`, `auto` |
| `--dangerously-skip-permissions` | Bypass all permission checks (⚠️ dangerous) |
| `--allow-dangerously-skip-permissions` | Enable `--dangerously-skip-permissions` as an available option without auto-enabling it |
| `--add-dir <dirs>` | Additional directories for tool access |
| `--allowed-tools <tools>` | Allowed tools (e.g., `"Bash(git:*) Edit"`) |
| `--disallowed-tools <tools>` | Denied tools |
| `--tools <tools>` | Specify available tools: `""` (none), `"default"` (all), or tool names |
| `--file <specs...>` | File resources to download at startup. Format: `file_id:relative_path` |
| `--mcp-config <configs>` | MCP server config from JSON files or strings (space-separated) |
| `--strict-mcp-config` | Only use MCP servers from `--mcp-config`, ignore all others |
| `--agent <agent>` | Agent for the current session |
| `--agents <json>` | Define custom agents as JSON |
| `--betas <betas>` | Beta headers for API requests (API key users only) |
| `--brief` | Enable `SendUserMessage` tool for agent-to-user communication |
| `--bare` | Minimal mode: skip hooks, LSP, plugin sync, auto-memory, keychain reads, CLAUDE.md auto-discovery. Sets `CLAUDE_CODE_SIMPLE=1`. Auth is strictly `ANTHROPIC_API_KEY` or `apiKeyHelper`. |
| `--chrome` / `--no-chrome` | Enable/disable Chrome integration |
| `--ide` | Auto-connect to IDE on startup if exactly one valid IDE is available |
| `--settings <file-or-json>` | Additional settings from file or JSON string |
| `--setting-sources <sources>` | Setting sources to load: `user`, `project`, `local` |
| `--plugin-dir <paths>` | Load plugins from directories (repeatable) |
| `--disable-slash-commands` | Disable all skills |
| `-w, --worktree [name]` | Create git worktree for this session |
| `--tmux` | Create tmux session for worktree (requires `--worktree`) |
| `--include-hook-events` | Include all hook lifecycle events (requires `--output-format=stream-json`) |
| `--include-partial-messages` | Include partial message chunks as they arrive (requires `--print` + `--output-format=stream-json`) |
| `--replay-user-messages` | Re-emit user messages from stdin on stdout (requires `--input-format=stream-json` + `--output-format=stream-json`) |
| `--remote-control-session-name-prefix <prefix>` | Prefix for auto-generated Remote Control session names |
| `--verbose` | Override verbose mode from config |
| `-d, --debug [filter]` | Debug mode with optional category filter |
| `--debug-file <path>` | Write debug logs to file |

## Commands

```bash
claude                  # Interactive mode
claude -p "prompt"      # Print mode
claude agents           # List configured agents
claude auth             # Manage authentication
claude auto-mode        # Inspect auto-mode classifier configuration
claude doctor           # Health check
claude install          # Install native build (stable, latest, or version)
claude mcp              # MCP management
claude plugin           # Plugin management
claude setup-token      # Set up long-lived auth token
claude update           # Check for updates
```

## Available Models

**Current flagship (Claude 4.7):**
- `opus` → **Claude Opus 4.7** (`claude-opus-4-7`) — most capable, step-change improvement in agentic coding over Opus 4.6. Requires Claude Code v2.1.111+. 1M context, 128K output.

**Claude 4.6:**
- `sonnet` → **Claude Sonnet 4.6** (`claude-sonnet-4-6`) — best balance of speed/quality. 1M context, 64K output. Still the workhorse default for most automated tasks.

**Claude 4.5:**
- `haiku` → **Claude Haiku 4.5** (`claude-haiku-4-5-20251001`) — fastest for simple tasks. 200K context, 64K output.

**Additional aliases:**
- `opusplan` — uses Opus in plan mode, switches to Sonnet for execution
- `best` — equivalent to `opus`
- `default` — clears model override (resolves based on your plan: Opus 4.7 for Max/Team Premium, Sonnet 4.6 for Pro/Standard/API)
- `opus[1m]`, `sonnet[1m]` — explicit 1M-context variants (for plans where 1M is opt-in)

**Full Model IDs (authoritative):**
- `claude-opus-4-7`
- `claude-sonnet-4-6`
- `claude-haiku-4-5-20251001` (dated snapshot; `claude-haiku-4-5` also works as a floating alias)

**1M Context availability:**
- Max/Team/Enterprise: Opus 1M included, Sonnet 1M requires additional usage
- Pro / Team Standard: both require additional usage above 200K
- API key: full 1M access at standard token pricing (no premium beyond 200K)

**Tokenizer note:** Opus 4.7 uses a new tokenizer (~555K English words ≈ 1M tokens, vs ~750K words for Sonnet 4.6). "1M context" means different amounts of text in each model.

**Note:** For security reviews, use `opus`. For speed, use `sonnet`. Use `--effort xhigh` with `opus` for the recommended agentic default; `--effort max` for deepest reasoning (slower). `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING=1` only affects Opus 4.6 and Sonnet — Opus 4.7 always uses adaptive reasoning.

## Permission Modes

- `default` - Normal permission prompts (**recommended**)
- `plan` - Planning mode only (read-only)
- `auto` - Automatic permission decisions (requires Team plan + recent Sonnet/Opus model)
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

# xhigh effort (Opus 4.7 recommended default for agentic tasks)
claude -p "Find subtle bugs in:" --model opus --effort xhigh < complex.py

# Max effort reasoning (deepest analysis, slower, can overthink)
claude -p "Find subtle bugs in:" --model opus --effort max < complex.py

# 1M context for large files (all plans)
claude -p "Review entire codebase:" --model opus < all-source.txt

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
If Claude is unavailable, try Gemini with default model for speed, or Codex with `-m gpt-5.4` for quality.
