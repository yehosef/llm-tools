# Gemini CLI Reference

## Installation

See [README.md](../../../README.md#prerequisites) for installation instructions.

Quick install options:
- `npm install -g @google/gemini-cli`
- `npx @google/gemini-cli` (no install)
- `brew install gemini-cli`
- `sudo port install gemini-cli` (MacPorts)

Version channels: `@latest`, `@preview`, `@nightly`

## Authentication

1. **Google Login** (recommended): Run `gemini` and follow prompts. Free tier: ~60 req/min, ~1000 req/day (CLI-specific quota)
2. **API Key**: Set `GEMINI_API_KEY` environment variable. Free tier varies by model (5-15 RPM, Flash models only for free). Pro models require paid access.
3. **Vertex AI**: Set `GOOGLE_API_KEY` + `GOOGLE_GENAI_USE_VERTEXAI=true` for enterprise/scalable use

## Non-Interactive Usage

```bash
# Preferred: -p triggers headless/non-interactive mode
gemini -p "Your prompt here"

# With model selection
gemini -p -m flash "prompt"
gemini -p -m pro "prompt"

# JSON output for parsing
gemini -p -o json "prompt"

# Auto-approve all tool actions
# ⚠️  WARNING: Only use in trusted repos with no secrets
gemini -p --approval-mode=yolo "prompt"

# Execute prompt then continue interactive
gemini -i "initial prompt"

# With stdin (context appended to prompt)
gemini -p "Review this code:" < file.py
```

**Important:** `-p/--prompt` is **not deprecated** — it is the documented way to run Gemini in non-interactive mode. The CLI defaults to **interactive** mode when stdin is a TTY; bare positional arguments (e.g., `gemini "prompt"`) will launch an interactive session pre-seeded with the prompt. When stdin is redirected (e.g., `< file.py` or a pipe), Gemini detects non-TTY and runs headless either way, but using `-p` explicitly is portable and reliable.

## All Options

| Flag | Short | Description |
|------|-------|-------------|
| `--prompt <prompt>` | `-p` | **Run in non-interactive (headless) mode** with the given prompt. Appended to stdin if any. |
| `--prompt-interactive <prompt>` | `-i` | Execute prompt then continue interactive |
| `--model <model>` | `-m` | Model to use (default: `auto`) |
| `--output-format <format>` | `-o` | Output: `text`, `json`, `stream-json` |
| `--approval-mode <mode>` | | `default` (prompt for approval), `auto_edit` (auto-approve edits), `yolo` (auto-approve all), `plan` (read-only mode) |
| `--yolo` | `-y` | Auto-approve all actions (equivalent to `--approval-mode=yolo`) |
| `--sandbox` | `-s` | Run in sandbox mode |
| `--resume <session>` | `-r` | Resume session: `latest` or index number |
| `--list-sessions` | | List available sessions |
| `--delete-session <id>` | | Delete session by index number |
| `--worktree [name]` | `-w` | Start in a new git worktree (name auto-generated if omitted; requires `experimental.worktrees` enabled) |
| `--debug` | `-d` | Debug mode (F12 opens debug console) |
| `--policy <files>` | | Additional policy files or directories (comma-separated or repeated) |
| `--admin-policy <files>` | | Additional admin policy files or directories |
| `--allowed-mcp-server-names <names>` | | Allowed MCP servers |
| `--allowed-tools <tools>` | | **Deprecated** - use Policy Engine |
| `--include-directories <dirs>` | | Additional workspace directories (comma-separated or repeated) |
| `--extensions <list>` | `-e` | Extensions to use |
| `--list-extensions` | `-l` | List available extensions |
| `--screen-reader` | | Accessibility mode |
| `--raw-output` | | Disable output sanitization (⚠️ security risk if model output is untrusted — allows ANSI escape sequences) |
| `--accept-raw-output-risk` | | Suppress the security warning for `--raw-output` |
| `--acp` | | Start agent in ACP mode |
| `--experimental-acp` | | **Deprecated** — use `--acp` |

**Note:** Positional arguments (`gemini "prompt"`) work for interactive mode with a pre-seeded prompt, or non-interactive when stdin is redirected. Scripts should always use `gemini -p "prompt"` explicitly.

## Subcommands

```bash
gemini mcp <cmd>          # add / remove / list / enable / disable
gemini extensions <cmd>   # install / uninstall / list / update / enable / disable / link / new / validate / config  (alias: extension)
gemini skills <cmd>       # list [--all] / enable / disable / install / link / uninstall  (alias: skill)
gemini hooks <cmd>        # migrate  (migrate hooks from Claude Code)
```

## Slash Commands (Interactive)

`/about`, `/auth`, `/bug`, `/chat` (alias `/resume`), `/clear`, `/commands`, `/compress`, `/copy`, `/directory` (alias `/dir`), `/docs`, `/editor`, `/extensions`, `/help` (alias `/?`), `/hooks`, `/ide`, `/init`, `/mcp`, `/memory`, `/model`, `/permissions`, `/plan`, `/policies`, `/privacy`, `/quit` (alias `/exit`), `/restore`, `/rewind`, `/settings`, `/shells` (alias `/bashes`), `/setup-github`, `/skills`, `/stats`, `/terminal-setup`, `/theme`, `/tools`, `/vim`

## Available Models

**Model Selection Modes:**
- **Auto (Gemini 3)** - Paid/Ultra subscribers. Routes between `gemini-2.5-flash` (simple prompts) and `gemini-3.1-pro-preview` (complex prompts).
- **Auto (Gemini 2.5)** - Default for most users. Routes between `gemini-2.5-flash` (simple) and `gemini-2.5-pro` (complex).
- **Manual** - Select specific model via `/model` or `-m` flag

**Gemini 3.x (Current, all still in preview — GA not yet announced):**
- `gemini-3.1-pro-preview` - Most capable, best reasoning (1M input, 64K output)
- `gemini-3-flash-preview` - Fast, good balance (1M input, 64K output)
- `gemini-3.1-flash-lite-preview` - Cheapest/fastest, 2.5x faster TTFT (1M input, 64K output). Released March 3, 2026.

**Gemini 2.5 (Stable; deprecation June 17, 2026 on Gemini API, October 16, 2026 on Vertex AI):**
- `gemini-2.5-pro` - Production stable, complex reasoning (1M input)
- `gemini-2.5-flash` - Production stable, fast (1M input)
- `gemini-2.5-flash-lite` - Ultra-efficient, cost-optimized

**Shorthand aliases (verified working in CLI 0.37.1):** `-m pro` → `gemini-3.1-pro-preview`, `-m flash` → `gemini-3-flash-preview`, `-m flash-lite` → `gemini-3.1-flash-lite-preview`. These are documented behavior but may be partial-match shortcuts; prefer full model IDs for reliability.

**Default:** `auto` — routing tier depends on subscription. **Critical:** If you do not have paid Gemini 3 access, `auto` falls back to Gemini 2.5 routing, not Gemini 3.

**Context Windows:** All current models support 1M token input context and 64K output.

**Note:** `/model` does not override sub-agent model selection.

## Built-in Tools

| Tool | Description |
|------|-------------|
| `run_shell_command` | Shell commands (interactive/background) |
| `glob` | File pattern matching |
| `grep_search` | Regex content search |
| `read_file` / `read_many_files` | Read files (text, images, audio, PDF) |
| `list_directory` | List files/dirs |
| `replace` | Text replacement in files |
| `write_file` | Create/overwrite files |
| `google_web_search` | Google Search grounding |
| `web_fetch` | URL content retrieval |
| `ask_user` | Request clarification |
| `save_memory` | Persist facts to GEMINI.md |
| `enter_plan_mode` / `exit_plan_mode` | Planning workflow |
| `activate_skill` | Load specialized skills |

## Sandbox Methods

1. **macOS Seatbelt** (`sandbox-exec`) - Built-in, lightweight
2. **Docker** - Cross-platform container
3. **Podman** - Cross-platform container
4. **gVisor/runsc** - Linux only, strongest isolation
5. **LXC/LXD** - Linux only (experimental)

Configure via `GEMINI_SANDBOX` env var: `true`/`false`/`docker`/`podman`/`sandbox-exec`/`runsc`/`lxc`

## Key Environment Variables

| Variable | Description |
|----------|-------------|
| `GEMINI_API_KEY` | API key |
| `GEMINI_MODEL` | Default model |
| `GEMINI_SANDBOX` | Sandbox configuration |
| `GEMINI_SYSTEM_MD` | Custom system prompt |
| `GEMINI_CLI_HOME` | Config directory override |
| `GOOGLE_API_KEY` | Google Cloud API key (Vertex AI) |
| `GOOGLE_CLOUD_PROJECT` | GCP project ID |
| `GOOGLE_GENAI_USE_VERTEXAI` | Enable Vertex AI |
| `NO_COLOR` | Disable color output |

## Strengths

- **1M token context window** - matches gpt-5.4 and Claude Opus 4.7 / Sonnet 4.6
- **Free tier** - available via Google login (~60 req/min CLI quota). API key free tier is more limited (Flash models only, 5-15 RPM)
- **Good at research/analysis** - different training data than Claude
- **Rich tool ecosystem** - built-in search, planning, skills

## Common Patterns

```bash
# Validate a plan (stdin avoids argv limits)
gemini -p "Review this plan for issues:" < plan.md

# Get JSON output
gemini -p -o json "List 3 improvements for:" < code.py

# Auto-approve for scripting
gemini -p --approval-mode=yolo "Refactor this:" < file.py

# Plan mode (read-only — safe exploration)
gemini -p --approval-mode=plan "What would you change in this code?" < file.py

# Resume latest session
gemini -r latest

# Use specific model
gemini -p -m pro "Complex analysis:" < data.txt

# Start in isolated git worktree (requires experimental.worktrees enabled)
gemini -w my-feature-branch

# Image / multimodal input — no dedicated flag; reference path in prompt
# and the built-in read_file tool loads it (supports images, audio, PDF).
# File must live inside the workspace or an --include-directories path.
gemini -p "Describe what's in ./screenshot.png"
gemini -p "Compare ./before.png and ./after.png — what changed?"
```

## Troubleshooting

### Authentication Errors
- **"Not authenticated"**: Run `gemini` interactively and login with Google
- **"API key invalid"**: Check `GEMINI_API_KEY` environment variable
- **"Quota exceeded"**: Wait for rate limit reset (60 req/min, 1000 req/day on free tier)

### Common Issues
- **Command not found**: Run `npm install -g @google/gemini-cli` or `brew install gemini-cli`
- **Model not available**: Some models require API key access vs free tier. Try default model first
- **Timeout on large prompts**: 1M context is large but still has processing limits

### Rate Limits
- Google login (CLI): ~60 requests/minute, ~1000 requests/day
- API key free tier: 5-15 RPM depending on model (Flash models only for free; Pro requires paid)
- Vertex AI: Separate quota per project

### Fallback Strategy
If Gemini is unavailable, try Claude with `--model sonnet` for similar speed, or Codex for code-specific tasks.
