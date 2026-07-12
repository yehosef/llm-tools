# Claude CLI Reference

**Audited against:** Claude Code `2.1.207` and official Claude Code documentation on July 12, 2026. Alias resolution verified live (`sonnet` → `claude-sonnet-5`).

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
claude -p "prompt" --model fable

# Full model names also work
claude -p "prompt" --model claude-opus-4-8

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
claude -p "prompt" --effort xhigh
claude -p "prompt" --effort max
```

## All Options

| Flag | Description |
|------|-------------|
| `-p, --print` | Non-interactive mode (required for scripting) |
| `--model <model>` | Model alias or full name. Current aliases include `fable`, `best`, `opus`, `sonnet`, `haiku`, `opusplan`, `default`, and `[1m]` variants |
| `--effort <level>` | Effort level: `low`, `medium`, `high`, `xhigh`, `max`; support and defaults vary by model |
| `--fallback-model <model>` | Fallback if primary overloaded (only with `--print`) |
| `--output-format <format>` | `text`, `json`, `stream-json` |
| `--input-format <format>` | Input: `text` (default), `stream-json` |
| `--json-schema <schema>` | JSON schema for structured output |
| `--max-budget-usd <amount>` | Spending limit (only with `--print`) |
| `--system-prompt <prompt>` | Custom system prompt |
| `--append-system-prompt <prompt>` | Append to default system prompt |
| `--system-prompt-file <file>` | Replace the default system prompt with file contents |
| `--append-system-prompt-file <file>` | Append file contents to the default system prompt |
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
| `--bare` | Minimal mode: skip hooks, LSP, plugin sync, attribution, auto-memory, background prefetches, keychain reads, CLAUDE.md auto-discovery. Sets `CLAUDE_CODE_SIMPLE=1`. Auth is strictly `ANTHROPIC_API_KEY` or `apiKeyHelper` via `--settings`. Skills still resolve via `/skill-name`. |
| `--mcp-debug` | **[DEPRECATED]** Use `--debug` instead. |
| `--chrome` / `--no-chrome` | Enable/disable Chrome integration |
| `--ide` | Auto-connect to IDE on startup if exactly one valid IDE is available |
| `--settings <file-or-json>` | Additional settings from file or JSON string |
| `--setting-sources <sources>` | Setting sources to load: `user`, `project`, `local` |
| `--plugin-dir <paths>` | Load plugins from directories (repeatable) |
| `--plugin-url <url>` | Fetch a plugin ZIP for this session (repeatable) |
| `--disable-slash-commands` | Disable all skills |
| `--safe-mode` | Disable customizations for troubleshooting while retaining auth, model selection, built-in tools, and permissions |
| `--prompt-suggestions [bool]` | Emit a predicted next prompt in print/SDK mode |
| `-w, --worktree [name]` | Create git worktree for this session |
| `--tmux` | Create tmux session for worktree (requires `--worktree`) |
| `--include-hook-events` | Include all hook lifecycle events (requires `--output-format=stream-json`) |
| `--include-partial-messages` | Include partial message chunks as they arrive (requires `--print` + `--output-format=stream-json`) |
| `--replay-user-messages` | Re-emit user messages from stdin on stdout (requires `--input-format=stream-json` + `--output-format=stream-json`) |
| `--remote-control-session-name-prefix <prefix>` | Prefix for auto-generated Remote Control session names |
| `--bg, --background` | Start the session as a background agent |
| `--ax-screen-reader` | Screen-reader friendly output (flat text, no decorative borders) |
| `--remote-control [name]` | Start an interactive session with Remote Control |
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
claude project          # Manage project state, including purge
claude ultrareview      # Cloud-hosted multi-agent code review
```

## Available Models

**Current aliases on the Anthropic API:**
- `fable` → **Claude Fable 5** (`claude-fable-5`) — longest-running and hardest autonomous tasks. Requires Claude Code 2.1.170+ and is not the default.
- `best` → Fable 5 where the organization has access; otherwise latest Opus.
- `opus` → **Claude Opus 4.8** (`claude-opus-4-8`) — complex reasoning. Requires Claude Code 2.1.154+.
- `sonnet` → **Claude Sonnet 5** (`claude-sonnet-5`) — daily coding; near-Opus quality on coding/agentic work at Sonnet cost. Adaptive thinking on by default; supports `xhigh` effort.
- `haiku` → **Claude Haiku 4.5** — fast and efficient for simple tasks.

**Additional aliases:**
- `opusplan` — uses Opus during plan mode and Sonnet for execution.
- `default` — clears the override and resolves by account/provider.
- `opus[1m]`, `sonnet[1m]` — explicit 1M-context variants (for plans where 1M is opt-in). `[1m]` can also be appended to full model names (e.g. `claude-opus-4-7[1m]`).

**Key full model IDs:**
- `claude-fable-5`
- `claude-opus-4-8`
- `claude-opus-4-7`
- `claude-sonnet-5`
- `claude-sonnet-4-6` (previous-generation Sonnet, still active)
- `claude-haiku-4-5-20251001` (dated snapshot; `claude-haiku-4-5` also works as a floating alias)

Aliases vary by provider. On Claude Platform on AWS, `opus` currently resolves to Opus 4.7; Bedrock, Vertex, and Foundry may resolve aliases to older versions unless full model IDs or `ANTHROPIC_DEFAULT_*_MODEL` overrides are configured.

**1M Context availability:**
- Max, Team, and Enterprise: Opus 1M included with subscription; Sonnet 1M requires extra usage
- Pro: both require extra usage
- API / pay-as-you-go: full access, standard token pricing (no premium beyond 200K)
- To disable 1M context entirely: `CLAUDE_CODE_DISABLE_1M_CONTEXT=1`

**Effort:** `low`, `medium`, `high`, `xhigh`, and `max` are accepted by current Claude Code. Capability and defaults vary by model and provider, so avoid hard-coding fallback behavior in automation.

**Note:** Use `fable` for long autonomous tasks, `opus` for complex reasoning and security review, `sonnet` for balanced daily work (Sonnet 5 handles most coding at near-Opus quality), and `haiku` for speed.

**Sonnet 5 specifics:** 1M context window, 128K max output, new tokenizer (~30% more tokens for the same text than Sonnet 4.6 — re-estimate token budgets), full `low`→`max` effort range including `xhigh`.

## Permission Modes

- `default` - Normal permission prompts (**recommended**)
- `plan` - Planning mode only (read-only, no edits)
- `acceptEdits` - Auto-accept file edits + common filesystem commands (use in trusted repos only)
- `auto` - Classifier-backed auto-approval; requires: Max/Team/Enterprise/API plan (not Pro), Sonnet 4.6+ or Opus 4.6+, Anthropic API only (not Bedrock/Vertex/Foundry). Team/Enterprise also requires admin to enable it.
- `dontAsk` - ⚠️ Only pre-approved tools run; everything else is denied (for locked-down CI)
- `bypassPermissions` - ⚠️ Skip all checks (dangerous — isolated containers/VMs only; requires `--dangerously-skip-permissions` or `--allow-dangerously-skip-permissions` at startup)

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

# xhigh effort
claude -p "Find subtle bugs in:" --model opus --effort xhigh < complex.py

# Max effort reasoning (deepest analysis, slower, can overthink)
claude -p "Find subtle bugs in:" --model opus --effort max < complex.py

# 1M context for large files where the account supports it
claude -p "Review entire codebase:" --model opus < all-source.txt

# Worktree for isolated work
claude -w feature-branch "Implement auth module"

# Ephemeral session (no persistence)
claude -p "Quick check:" --no-session-persistence < file.py

# Image / multimodal input — no dedicated -i flag in the CLI for local images.
# Reference the path in the prompt; Claude's Read tool fetches it (supports images, PDF).
claude -p "Describe what's in ./screenshot.png"
claude -p "Compare ./before.png and ./after.png — what changed?"

# --file is for API-uploaded file resources (file_id:path), not local file attach.
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
If Claude is unavailable, try Gemini with default model for speed, or Codex with `-m gpt-5.6-sol` for quality.
