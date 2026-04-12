# LLM CLI Tools - Project Instructions

## What This Is

A Claude Code **skill/plugin** for multi-model LLM orchestration. This is a documentation/knowledge project — no runtime code, no dependencies. The skill teaches Claude Code how to coordinate Gemini, Codex, and Claude CLI tools.

## Project Structure

- `skills/llm-cli-tools/SKILL.md` — Core skill document (loaded into Claude Code context)
- `skills/llm-cli-tools/references/` — Per-tool CLI references (claude, codex, gemini, orchestration patterns)
- `skills/llm-cli-tools/test/validate.sh` — Smoke tests validating documented patterns against real tools
- `.claude-plugin/` — Plugin marketplace manifest (`plugin.json`, `marketplace.json`)
- `assets/` — Marketing/design assets (not functional)

## Key Conventions

- **All content is markdown** — changes are documentation changes, not code changes
- **Version** lives in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` — keep in sync
- **Model information gets stale fast** — always verify against current CLI `--help` output before updating
- **Stdin behavior** — All three tools (Gemini, Codex, Claude) support stdin with positional prompts. Validate with `test/validate.sh` if behavior changes

## Updating Model References

When CLI tools update their models:
1. Update the relevant `references/<tool>-cli.md`
2. Update routing tables in `SKILL.md` (Quick Reference, Task Routing, Model Selection, Context Windows)
3. Update `README.md` task routing and supported tools tables
4. Run `bash skills/llm-cli-tools/test/validate.sh` from a plain terminal (not inside Claude Code)

## Testing

```bash
# Run from plain terminal (Claude tests are skipped inside Claude Code)
bash skills/llm-cli-tools/test/validate.sh
```

Tests validate: tool availability, basic invocation, stdin behavior (critical), model availability, JSON output. Tests skip gracefully if a tool isn't installed.

## Common Tasks

- **Bump version**: Update `version` in both `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
- **Add new CLI tool**: See `CONTRIBUTING.md` for the checklist
- **Verify patterns work**: Run validate.sh, check exit code (0 = all pass)
