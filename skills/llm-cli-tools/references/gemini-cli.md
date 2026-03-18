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

1. **Google Login** (recommended): Run `gemini` and follow prompts. Free tier: 60 req/min, 1000 req/day
2. **API Key**: Set `GEMINI_API_KEY` environment variable. 1000 req/day free with Gemini 3
3. **Vertex AI**: Set `GOOGLE_API_KEY` + `GOOGLE_GENAI_USE_VERTEXAI=true` for enterprise/scalable use

## Non-Interactive Usage

```bash
# Basic - positional prompt (preferred)
gemini "Your prompt here"

# With model selection
gemini -m flash "prompt"
gemini -m pro "prompt"

# JSON output for parsing
gemini -o json "prompt"

# Auto-approve all tool actions
# ⚠️  WARNING: Only use in trusted repos with no secrets
gemini --approval-mode=yolo "prompt"

# Execute prompt then continue interactive
gemini -i "initial prompt"
```

## All Options

| Flag | Short | Description |
|------|-------|-------------|
| `--model <model>` | `-m` | Model to use (default: `auto`) |
| `--output-format <format>` | `-o` | Output: `text`, `json`, `stream-json` |
| `--approval-mode <mode>` | | `default`, `auto_edit`, `yolo` |
| `--yolo` | `-y` | **Deprecated** - use `--approval-mode=yolo` |
| `--sandbox` | `-s` | Run in sandbox mode |
| `--prompt-interactive <prompt>` | `-i` | Execute prompt then continue interactive |
| `--resume <session>` | `-r` | Resume session: `latest`, index, or UUID |
| `--list-sessions` | | List available sessions |
| `--delete-session <id>` | | Delete session by index or UUID |
| `--debug` | `-d` | Debug mode |
| `--allowed-mcp-server-names <names>` | | Allowed MCP servers |
| `--allowed-tools <tools>` | | **Deprecated** - use Policy Engine |
| `--include-directories <dirs>` | | Additional workspace directories (max 5) |
| `--extensions <list>` | `-e` | Extensions to use |
| `--list-extensions` | `-l` | List available extensions |
| `--screen-reader` | | Accessibility mode |
| `--experimental-acp` | | ACP mode (experimental) |
| `--experimental-zed-integration` | | Zed editor integration (experimental) |

**Note:** `--prompt` / `-p` is deprecated. Use positional arguments instead: `gemini "prompt"`

## Slash Commands (Interactive)

`/about`, `/auth`, `/bug`, `/chat` (alias `/resume`), `/clear`, `/commands`, `/compress`, `/copy`, `/directory` (alias `/dir`), `/docs`, `/editor`, `/extensions`, `/help` (alias `/?`), `/hooks`, `/ide`, `/init`, `/mcp`, `/memory`, `/model`, `/permissions`, `/plan`, `/policies`, `/privacy`, `/quit` (alias `/exit`), `/restore`, `/rewind`, `/settings`, `/shells` (alias `/bashes`), `/setup-github`, `/skills`, `/stats`, `/terminal-setup`, `/theme`, `/tools`, `/vim`

## Available Models

**Model Selection Modes:**
- **Auto (Gemini 3)** - Default. System chooses best Gemini 3 model for task
- **Auto (Gemini 2.5)** - System chooses best Gemini 2.5 model
- **Manual** - Select specific model via `/model` or `-m` flag

**Gemini 3.1 (Latest):**
- `gemini-3.1-pro-preview` - Latest, replaces 3.0 Pro (1M input, 64K output)

**Gemini 3 (Current):**
- `gemini-3-flash-preview` - Fast, current generation (1M input, 64K output)
- `gemini-3.1-flash-lite-preview` - Cheapest/fastest, 2.5x faster TTFT vs 2.5 Flash (1M input, 64K output)
- ~~`gemini-3-pro-preview`~~ - **Deprecated March 9, 2026** - use `gemini-3.1-pro-preview`

**Gemini 2.5 (Stable, deprecating June 2026):**
- `gemini-2.5-pro` - Production stable, complex reasoning (1M input)
- `gemini-2.5-flash` - Production stable, fast (1M input)
- `gemini-2.5-flash-lite` - Ultra-efficient, cost-optimized

**Aliases:** `-m pro`, `-m flash`, `-m flash-lite` for latest versions.

**Context Windows:** All current models support 1M token input context. Output varies (64K for Gemini 3).

**Note:** Gemini 2.0 models deprecated. Gemini 2.5 models scheduled for deprecation June 2026. `/model` does not override sub-agent model selection.

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

- **1M token context window** - matches gpt-5.4, largest available
- **Free tier** - 60 req/min, 1000 req/day with Google login
- **Good at research/analysis** - different training data than Claude
- **Rich tool ecosystem** - built-in search, planning, skills

## Common Patterns

```bash
# Validate a plan (stdin avoids argv limits)
gemini "Review this plan for issues:" < plan.md

# Get JSON output
gemini -o json "List 3 improvements for:" < code.py

# Auto-approve for scripting (--yolo / -y is deprecated)
gemini --approval-mode=yolo "Refactor this:" < file.py

# Resume latest session
gemini -r latest

# Use specific model
gemini -m pro "Complex analysis:" < data.txt
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
- Free tier: 60 requests/minute, 1000 requests/day
- API key tier: Check Google AI Studio for your quota
- Vertex AI: Separate quota per project

### Fallback Strategy
If Gemini is unavailable, try Claude with `--model sonnet` for similar speed, or Codex for code-specific tasks.
