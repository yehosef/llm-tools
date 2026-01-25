---
name: llm-cli-tools
description: Use other LLM CLI tools (Gemini, Codex, Claude) for validation, second opinions, and cross-checking work. Trigger when user asks to validate something with another model, get a second opinion, cross-check with Gemini/Codex/Claude, or compare approaches across different LLMs.
---

# LLM CLI Tools

Invoke external LLM CLIs for validation and second opinions.

## When to Use

- User asks to "validate with Gemini/Codex"
- User wants a "second opinion" from another model
- User asks to "cross-check" or compare approaches

## Quick Reference

| Tool | Command | Best Model | Best For |
|------|---------|------------|----------|
| Gemini | `gemini "prompt"` | default (Gemini 3 Flash) | Large context (1M tokens), research |
| Codex | `codex exec -m gpt-5.2-codex "prompt"` | `gpt-5.2-codex` | Code review, GPT-5 reasoning |
| Claude | `claude -p "prompt" --model opus` | `opus` | Thorough security analysis |

## Best Models for Code Review (2026-01)

| Tool | Quality Model | Fast Model |
|------|---------------|------------|
| **Gemini** | `-m gemini-3-pro` | default (Gemini 3 Flash) |
| **Codex** | `-m gpt-5.2-codex` | `-m gpt-4o` |
| **Claude** | `--model opus` | `--model sonnet` |

## Basic Usage

```bash
# Gemini
gemini "Review this for issues: $(cat file.md)"

# Codex
codex exec "Find bugs in: $(cat code.py)"

# Claude (fresh context, specific model)
claude -p "Second opinion: $(cat plan.md)" --model opus
```

## Detailed Options

See references for models, flags, and advanced usage:
- `references/gemini-cli.md` - models, output formats, YOLO mode
- `references/codex-cli.md` - models (o3, gpt-4o), sandbox modes
- `references/claude-cli.md` - models, JSON schema, budget limits
