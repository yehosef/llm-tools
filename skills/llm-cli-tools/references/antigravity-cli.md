# Antigravity CLI Reference (`agy`)

Google's terminal coding agent — the successor to Gemini CLI for **individual accounts** (free, Google AI Pro, Google AI Ultra), which lost Gemini CLI access on June 18, 2026. Unlike Gemini CLI, it is **multi-vendor**: it serves Gemini, Claude, and GPT-OSS models under one Google login.

**Audited against:** Antigravity CLI `1.1.9` (`agy --version`) with a signed-in individual account on August 2, 2026 — flags from local `--help`; headless invocation, stdin behavior, `@file` handling, and the model list all verified live.

## Installation

```bash
# Official installer (macOS/Linux)
curl -fsSL https://antigravity.google/cli/install.sh | bash

# Homebrew (installs binary as `agy`)
brew install --cask antigravity-cli

# Self-update (brew-installed builds can lag; update in place)
agy update
```

Windows: `irm https://antigravity.google/cli/install.ps1 | iex`. Installer flags: `--skip-aliases`, `--skip-path`.

## Authentication

- Run `agy` with no arguments — it tries silent auth via the OS keyring (macOS Keychain etc.), else opens a browser for Google sign-in.
- Over SSH: prints an authorization URL; paste the code back into the terminal.
- No API-key mode — auth is tied to your Google account and its Antigravity quota.

## Non-Interactive Usage

```bash
# Print mode - execute and exit
agy -p "Your prompt here"

# Model + effort selection
agy -p "prompt" --model "Gemini 3.5 Flash" --effort high

# JSON output (single object: conversation_id, status, response, usage, ...)
agy -p "prompt" --output-format json

# Structured output with schema (string or file path)
agy -p "List 3 bugs" --json-schema schema.json

# Streaming events for CI (init / step_update / result, one JSON per line)
agy -p "prompt" --output-format stream-json

# Continue most recent conversation / resume by ID
agy -c "Follow-up question"
agy --conversation <id> "Follow-up"

# Plan mode (read-only) or auto-accept edits
agy -p "prompt" --mode plan
agy -p "prompt" --mode accept-edits
```

Headless runs are stateless by default; the JSON output's `conversation_id` feeds `--conversation` for resumption. Non-zero exit on failure with `status` = `ERROR` / `CANCELED` / `INTERRUPTED` / `INVALID`.

### ⚠️ No stdin support (verified Aug 2, 2026)

**`agy -p "prompt" < file` does NOT work** — piped/redirected stdin is silently ignored, unlike Gemini, Codex, and Claude. The generic `tool "prompt" < file` pattern from the other references does not apply. Feed files via `@file` references instead:

```bash
# ✗ WRONG — agy never sees file.py
agy -p "Review this code:" < file.py

# ✓ RIGHT — @file reference (needs headless permissions, see below)
agy -p "Review @file.py" --sandbox --dangerously-skip-permissions
```

### ⚠️ Headless permissions (verified Aug 2, 2026)

Headless mode cannot prompt for tool approval, so tools are **soft-denied by default** — even reading an `@file` triggers a `read_file`/`command` tool call that gets auto-denied ("a tool required the ... permission that headless mode cannot prompt for"). Pure-text prompts work without any of this. For file access or tool use in scripts, either:

- Add allow-rules under `permissions.allow` in `~/.gemini/antigravity-cli/settings.json` (e.g. `read_file(<target>)`), or
- Pass `--dangerously-skip-permissions` (pair with `--sandbox` to keep terminal restrictions on).

## All Options

| Flag | Description |
|------|-------------|
| `-p, --print, --prompt` | Run a single prompt non-interactively and print the response |
| `-i, --prompt-interactive` | Run an initial prompt, then stay interactive (same meaning as Gemini's `-i` — **not** an image flag) |
| `--model <slug>` | Model for the session (stable slugs since 1.1.5; list via `agy models`) |
| `--effort <level>` | Reasoning effort: `low`, `medium`, `high` |
| `--agent <agent>` | Agent for the session (list via `agy agents`) |
| `--output-format <fmt>` | Print-mode output: `text` (default), `json`, `stream-json` |
| `--json-schema <str\|file>` | Enforce structured output (for stream-json, applies to final result) |
| `-c, --continue` | Continue the most recent conversation |
| `--conversation <id>` | Resume a conversation by ID |
| `--print-timeout <dur>` | Max wait in print mode (default `5m0s`) |
| `--mode <mode>` | Agent execution mode: `accept-edits`, `plan` |
| `--sandbox` | Run with terminal sandbox restrictions |
| `--dangerously-skip-permissions` | ⚠️ Auto-approve all tool permission requests |
| `--add-dir <dir>` | Add a directory to the workspace (repeatable) |
| `--log-file <path>` | Override CLI log file path |

## Subcommands

```bash
agy models       # List available models (requires sign-in)
agy agents       # List available agents (alias: agent)
agy plugin       # install / uninstall / list / enable / disable (alias: plugins)
agy update       # Update CLI in place
agy changelog    # Release notes
agy install      # Configure PATH/shell settings
```

## Available Models

Multi-vendor catalog. Live `agy models` output (individual account, verified Aug 2, 2026):

```
gemini-3.6-flash-high / -medium / -low
gemini-3.5-flash-high / -medium / -low
gemini-3.1-pro-high / -low
claude-sonnet-4-6
claude-opus-4-6-thinking
gpt-oss-120b-medium
```

Slugs bake the effort level in (`-high`/`-medium`/`-low`) and are accepted by `--model`. `gemini-3.6-flash` (GA July 21, 2026) is present — Antigravity tracks current Gemini releases. The Claude versions trail the Anthropic API's current lineup (Sonnet 5 / Opus 5) — for frontier Claude, use the `claude` CLI directly.

## Quotas

- Individual tiers get a **weekly compute allowance** (replacing Gemini CLI's old 1,000 req/day), split into per-model quotas.
- `/usage` (alias `/quota`) in an interactive session opens a TUI showing remaining requests/tokens per model.

## Permission Modes

Set via `/config` interactively:

- `request-review` - Prompt for approval (default, **recommended**)
- `proceed-in-sandbox` - Auto-execute in an isolated container
- `always-proceed` - ⚠️ Fully autonomous
- `strict` - Read-only

Settings persist in `~/.gemini/antigravity-cli/settings.json`.

## Multimodal

- `@file` references in prompts attach files, including images (e.g. extract data from `.png` invoices) — same pattern as Gemini CLI. Exact modality limits (audio/video) are not formally documented for `agy`; verified support is text and images.
- No image/audio/video generation.

## MCP & Plugins

- MCP servers supported, including OAuth-authenticated ones (Salesforce, Atlassian, ...); servers initialize in parallel.
- `agy plugin install ...` manages plugins.

## Interactive Extras

- Slash commands: `/help`, `/model`, `/effort`, `/config` (`/settings`), `/usage` (`/quota`), `/artifact`, `/quit`
- `!` in the message box toggles shell mode.

## Troubleshooting

- **"Please sign in to view available models"**: run `agy` with no args to trigger the sign-in flow.
- **Gemini CLI `IneligibleTierError`**: expected for individual accounts since June 18, 2026 — Antigravity CLI is the replacement path.
- **Stale binary from brew**: the cask can trail releases; `agy update` self-updates.

## Role in Multi-Model Orchestration

Use `agy` as the **Gemini-family lane for individual (non-enterprise) accounts** — the other references' `gemini -p` patterns map to `agy -p` with flag changes (`-o json` → `--output-format json`; no `--approval-mode`, use `--mode`/`--sandbox`). Caveats:

- **No stdin** — replace `< file` patterns with `@file` references plus headless permission handling (see above). This breaks drop-in reuse of the parallel/consensus snippets in SKILL.md; adapt them per tool.
- Weekly quota makes it a poor choice for high-volume automated loops.
- Its Claude/GPT-OSS models are older tiers — route frontier work to `claude`/`codex` directly.
