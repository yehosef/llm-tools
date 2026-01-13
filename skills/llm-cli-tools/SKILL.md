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

| Tool | Command | Best For |
|------|---------|----------|
| Gemini | `gemini "prompt"` | Large context (1M tokens), research |
| Codex | `codex exec "prompt"` | Code review, OpenAI perspective |
| Claude | `claude -p "prompt"` | Fresh context, different model tier |

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
