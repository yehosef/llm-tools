# Gemini CLI Reference

> **Consumer transition:** As of June 18, 2026, Gemini CLI no longer serves requests for free users or Google AI Pro/Ultra subscribers. Google directs those users to Antigravity CLI. Gemini CLI remains supported for Gemini Code Assist Standard/Enterprise and paid Gemini or Enterprise Agent Platform API keys.

**Audited against:** Gemini CLI `0.45.2` (installed) plus upstream release notes and Gemini API docs on August 2, 2026. **Upstream is at `0.53.1`** (July 31, 2026) — recent releases are mostly security/infra hardening; flags and multimodal behavior are unchanged since 0.45.x. Update with `npm install -g @google/gemini-cli` if you have working (enterprise/API-key) access.

## Installation

See [README.md](../../../README.md#prerequisites) for installation instructions.

Quick install options:
- `npm install -g @google/gemini-cli`
- `npx @google/gemini-cli` (no install)
- `brew install gemini-cli`
- `sudo port install gemini-cli` (MacPorts)

Version channels: `@latest`, `@preview`, `@nightly`

## Authentication

1. **Enterprise Google Login**: Run `gemini` and follow prompts. Consumer/free and Google AI Pro/Ultra access ended June 18, 2026.
2. **Paid API Key**: Set `GEMINI_API_KEY`. Gemini CLI remains accessible through paid Gemini and Enterprise Agent Platform API keys.
3. **Vertex AI**: Set `GOOGLE_API_KEY` + `GOOGLE_GENAI_USE_VERTEXAI=true` for enterprise/scalable use

## Non-Interactive Usage

```bash
# Preferred: -p triggers headless/non-interactive mode
gemini -p "Your prompt here"

# With model selection
gemini -p -m gemini-3.6-flash "prompt"
gemini -p -m gemini-3.1-pro-preview "prompt"

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
| `--session-file <file>` | | Load a session from a JSON file |
| `--session-id <uuid>` | | Start a session with an explicit UUID |
| `--list-sessions` | | List available sessions |
| `--delete-session <id>` | | Delete session by index number |
| `--worktree [name]` | `-w` | Start in a new git worktree (name auto-generated if omitted; requires `experimental.worktrees` enabled) |
| `--skip-trust` | | Trust the current workspace for this session |
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
gemini gemma <cmd>        # setup / start / stop / status / logs for local Gemma routing
```

## Slash Commands (Interactive)

`/about`, `/auth`, `/bug`, `/chat` (alias `/resume`), `/clear`, `/commands`, `/compress`, `/copy`, `/directory` (alias `/dir`), `/docs`, `/editor`, `/extensions`, `/help` (alias `/?`), `/hooks`, `/ide`, `/init`, `/mcp`, `/memory`, `/model`, `/permissions`, `/plan`, `/policies`, `/privacy`, `/quit` (alias `/exit`), `/restore`, `/rewind`, `/settings`, `/shells` (alias `/bashes`), `/setup-github`, `/skills`, `/stats`, `/terminal-setup`, `/theme`, `/tools`, `/vim`

## Available Models

**Current lineup (August 2026), for accounts with valid access:**

| Model ID | Status | Role | Context | Price (per 1M in/out) |
|----------|--------|------|---------|----------------------|
| `gemini-3.1-pro-preview` | Preview (current top) | Deepest reasoning, hardest analysis | 1M in / 64K out | $2–4 / $12–18 (tiered at 200K) |
| `gemini-3.6-flash` | GA (July 21, 2026) | New workhorse — ~17% lower token usage than 3.5 Flash | 1M in / 64K out | — (check current pricing) |
| `gemini-3.5-flash` | GA | Agentic coding loops, strong multimodal understanding | 1M in / 64K out | $1.50 / $9 |
| `gemini-3.5-flash-lite` | GA (July 21, 2026) | Cheapest/fastest current-gen (~350 tok/s) | 1M in / 64K out | — (check current pricing) |
| `gemini-3.1-flash-lite` | GA | Previous cheap tier; quick tasks | 1M in / 64K out | $0.25 / $1.50 |
| `gemini-2.5-pro` / `-flash` / `-flash-lite` | Legacy | Auto-routing fallbacks; 2.5-flash-lite is cheapest overall ($0.10/$0.40) | 1M in | — |

⚠️ `gemini-3-pro-preview` was **shut down March 9, 2026** — use `gemini-3.1-pro-preview` instead. Gemini 3.5 Pro is still partner-testing only (no public ID). `temperature`/`top_p`/`top_k` are deprecated on `gemini-3.6-flash` and `gemini-3.5-flash-lite`. Gemini 3 "Deep Think" is consumer-app-only (no CLI/API model ID); do not route to it. `gemini-3.5-flash-cyber` exists but is restricted to a government/trusted-partner pilot.

All Gemini 3.x models are multimodal: text, image, video, audio, and PDF input (text output only).

**Model Selection Modes:**
- **Auto (Gemini 3)** - Routes simple prompts to Flash-tier and complex prompts to Pro-tier models available to the account. Default (`-m` defaults to `auto`).
- **Auto (Gemini 2.5)** - Routes between Gemini 2.5 Pro and Flash where still available.
- **Manual** - Select a specific model via `/model` or `-m`.

**Recommendation:** Use `auto` unless reproducibility requires a pinned model. Pin `gemini-3.1-pro-preview` for complex reasoning, `gemini-3.6-flash` for everyday work, and `gemini-3.5-flash-lite` for the cheapest/fastest tier. Availability is account-dependent; inspect `/model` for the authoritative list for the current account.

**Quota behavior:** On daily quota exhaustion the CLI prompts to fall back to `gemini-2.5-pro`, retry with backoff, or stop — there is no silent automatic Flash fallback.

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

## Multimodal Capabilities

The strongest multimodal input story of the three tools — the only one that takes audio and video.

| Modality | Input | Output (generation) |
|----------|-------|---------------------|
| Image | ✅ `@file.png` in prompt, or path → `read_file`/`read_many_files` | ✅ Official `nanobanana` extension |
| PDF | ✅ `@file.pdf` / read tools | — |
| Audio (mp3, wav) | ✅ `@file.mp3` / `read_many_files` | ⚠️ No official TTS extension (API-only models exist) |
| Video (mp4, mov) | ✅ `@file.mp4` / `read_many_files` | ❌ Veo is API-only, no official CLI extension |

**Input mechanisms** (identical in interactive and `-p` mode):
- `@path/to/file` inline in the prompt — injects the file as a prompt part. Works with globs and directories (`@src/`), respects `.gitignore`. Handles images, PDF, audio, video.
- Plain path in the prompt — the model calls `read_file`/`read_many_files` itself. For non-text media, `read_many_files` is the more reliable path (plain `read_file` has historically failed on some audio formats).
- Files must live inside the workspace or an `--include-directories` path. No dedicated attach flag.

```bash
gemini -p "Describe @screenshot.png"
gemini -p "Transcribe and summarize @meeting.mp3"
gemini -p "What happens in @demo.mp4? List the UI issues you see."
gemini -p "Compare @before.png and @after.png — what changed?"
```

**Image generation** — via the official `nanobanana` extension (not core CLI):

```bash
gemini extensions install https://github.com/gemini-cli-extensions/nanobanana
```

Provides `/generate`, `/edit`, `/restore`, `/icon`, `/pattern`, `/story`, `/diagram`, and free-form `/nanobanana`. Select the model with the `NANOBANANA_MODEL` env var:
- `gemini-3.1-flash-image` — "Nano Banana 2", current default tier
- `gemini-3-pro-image` — "Nano Banana Pro", highest quality
- `gemini-2.5-flash-image` — original Nano Banana

⚠️ The extension README may still show `-preview` suffixed IDs; those were retired June 25, 2026 — use the GA names above when scripting.

**Audio/video generation:** TTS models (`gemini-2.5-*-preview-tts`) and Veo 3.1 (video) exist in the Gemini API but have no official CLI extension — only community wrappers. Treat as API-only.

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

- **Large context support** - useful for repository and document analysis
- **Enterprise and paid API access** - consumer/free access moved to Antigravity CLI on June 18, 2026
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
gemini -p -m gemini-3.1-pro-preview "Complex analysis:" < data.txt
gemini -p -m gemini-3.5-flash-lite "Quick check:" < data.txt

# Start in isolated git worktree (requires experimental.worktrees enabled)
gemini -w my-feature-branch

# Image / multimodal input — use @file syntax or a plain path (see
# "Multimodal Capabilities" above; supports images, PDF, audio, video).
gemini -p "Describe @screenshot.png"
gemini -p "Compare @before.png and @after.png — what changed?"
```

## Troubleshooting

### Authentication Errors
- **"Not authenticated"**: Run `gemini` interactively and login with Google
- **"API key invalid"**: Check `GEMINI_API_KEY` environment variable
- **"Quota exceeded"**: Check the quota attached to the enterprise license or paid API project

### Common Issues
- **Command not found**: Run `npm install -g @google/gemini-cli` or `brew install gemini-cli`
- **Model not available**: Model access depends on license, provider, and API project. Try `auto` or inspect `/model`
- **Timeout on large prompts**: 1M context is large but still has processing limits

### Rate Limits
- Enterprise Google login: quota depends on the organization's Gemini Code Assist license
- Paid API key: quota depends on the Gemini API project and model
- Vertex AI: Separate quota per project

### Fallback Strategy
For consumer accounts, migrate to Antigravity CLI. If Gemini is unavailable in an orchestration workflow, try Claude with `--model sonnet` for similar speed or Codex for code-specific tasks.
