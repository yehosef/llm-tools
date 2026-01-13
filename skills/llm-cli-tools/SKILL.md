---
name: llm-cli-tools
description: Use other LLM CLI tools (Gemini, Codex, Claude) for validation, second opinions, and cross-checking work. Trigger when user asks to validate something with another model, get a second opinion, cross-check with Gemini/Codex/Claude, or compare approaches across different LLMs.
---

# LLM CLI Tools

Use external LLM command-line tools to validate work, get second opinions, and cross-check code or plans with different models.

## When to Use This Skill

- User asks to "validate this with Gemini/Codex"
- User wants a "second opinion" from another model
- User asks to "cross-check" or "verify" with a different LLM
- User wants to compare approaches across models
- User explicitly names gemini, codex, or asks for a fresh claude context

## Available Tools

### Gemini CLI (Google)
**Best for:** Long context analysis (1M token window), research tasks, alternative perspectives

```bash
# Simple prompt
gemini "Your prompt here"

# With specific model
gemini -m gemini-2.0-flash "Your prompt here"

# Available models: gemini-2.0-flash (default), gemini-2.0-pro
```

**Strengths:** Largest context window, good at reasoning, different training data than Claude
**Auth:** Login with Google account or GEMINI_API_KEY env var
**Rate limits:** 60 req/min, 1000 req/day on free tier

### Codex CLI (OpenAI)
**Best for:** Code review, finding bugs, OpenAI's perspective on implementation

```bash
# Non-interactive execution
codex exec "Your prompt here"
```

**Strengths:** Strong at code patterns, different model architecture perspective
**Auth:** OpenAI API key or ChatGPT login
**Note:** Uses GPT-4o or o1 models depending on configuration

### Claude CLI (Anthropic)
**Best for:** Getting a fresh context, using a different Claude model, parallel validation

```bash
# Simple prompt with print mode (non-interactive)
claude -p "Your prompt here"

# With specific model
claude -p "Your prompt here" --model opus
claude -p "Your prompt here" --model sonnet
claude -p "Your prompt here" --model haiku

# Read from stdin
cat file.txt | claude -p "Review this code"
```

**Strengths:** Fresh context (no conversation history), can use different model tier
**When to use:** When current conversation has too much context, need opus-level reasoning on something specific

## Check Tool Availability

Before using a tool, verify it's installed:

```bash
which gemini codex claude 2>/dev/null
```

## Usage Patterns

### Validate a Plan
```bash
gemini "Review this implementation plan and identify potential issues, blind spots, or improvements:

$(cat plan.md)"
```

### Cross-check Code
```bash
codex exec "Review this code for bugs, security issues, and improvements:

$(cat src/main.py)"
```

### Get Second Opinion on Approach
```bash
claude -p "I'm considering this approach. What are the tradeoffs and alternatives?

$(cat approach.md)" --model opus
```

### Compare Perspectives
Run the same prompt through multiple tools and synthesize:
1. Run through Gemini
2. Run through Codex
3. Compare and highlight differences

## Best Practices

1. **Be specific in prompts** - External tools don't have our conversation context
2. **Include relevant code/content** - Pass file contents directly in the prompt
3. **Ask for structured output** - Request bullet points, pros/cons, or specific format
4. **Handle errors gracefully** - If a tool isn't installed, inform the user

## Error Handling

If a command fails:
- **"command not found"** - Tool not installed. Tell user how to install it.
- **Authentication error** - Tool needs login/API key. Guide user to authenticate.
- **Rate limit** - Wait and retry, or suggest using a different tool.
- **Timeout** - Prompt may be too long. Suggest summarizing or chunking.

## Tool Installation (if needed)

```bash
# Gemini
npm install -g @google/gemini-cli

# Codex
npm install -g @openai/codex

# Claude (usually already installed if using Claude Code)
npm install -g @anthropic-ai/claude-code
```

## References

For detailed CLI options and advanced usage:
- See `references/gemini-cli.md`
- See `references/codex-cli.md`
- See `references/claude-cli.md`
