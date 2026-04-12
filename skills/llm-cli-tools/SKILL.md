---
name: llm-cli-tools
description: Multi-model LLM orchestration - route tasks to the right model, run in parallel, synthesize results. Use when complex tasks benefit from multiple AI perspectives or when specific models have advantages.
---

# Multi-Model LLM Orchestration

Coordinate Gemini, Codex, and Claude CLI tools.

## Quick Start (Simple Usage)

Most requests are simple - just run the models and show results:

```bash
# "Review this with Gemini" (stdin works as context)
gemini "Review this code:" < file.py

# "Check with Codex" (stdin appended as <stdin> block)
codex exec "Review this code:" < file.py

# "Review with Gemini and Claude" (parallel, all support stdin)
gemini "Review:" < file.py > /tmp/g.txt &
claude -p "Review:" --model sonnet < file.py > /tmp/cl.txt &
wait
cat /tmp/g.txt /tmp/cl.txt

# "Get a second opinion with Claude"
claude -p "Review:" --model sonnet < file.py
```

**All three tools support stdin with positional prompts.** `tool "prompt" < file` works for Gemini, Codex, and Claude.

**That's it for simple requests.** Advanced patterns (routing, escalation, consensus) are below for complex tasks.

---

## ⚠️ Security Notes

**Cross-provider data**: Multi-model orchestration sends code to multiple vendors (Google, OpenAI, Anthropic). Before using parallel patterns:
- Check your org's data policies
- Don't send secrets, credentials, or PII
- Consider if code is proprietary/sensitive

**Auto-approval modes**: Avoid `--yolo`, `--full-auto`, `bypassPermissions` unless in a trusted, isolated environment with no secrets.

---

## When to Use Advanced Patterns

- Complex tasks benefiting from multiple perspectives
- Specific models have clear advantages (see routing table)
- User asks for "consensus", "parallel review", or "multiple opinions"
- Large context that exceeds single-model limits
- Need validation or cross-checking

## Task Routing

| Task Type | Primary | Why | Backup |
|-----------|---------|-----|--------|
| Large context (>200k) | Gemini or Codex | All have ~1M context | Claude opus (1M) |
| Code review | Codex (`gpt-5.4`) | 1M context + code-specialized | Claude opus |
| Security audit | Claude opus | Thorough analysis | Codex o3 |
| Quick validation | Gemini (free) | Fast, no cost | Codex `gpt-5.4-mini` |
| Reasoning/logic | Codex o3 | Reasoning model | Claude opus `--effort max` |
| Research | Gemini (`-m pro`) | Large context + web | Claude opus |
| Full-repo review | Codex (`gpt-5.4`) | 1M context + coding | Gemini 3.1 pro |

## Parallel Execution

Run multiple models simultaneously for consensus or speed:

```bash
# Parallel review - all three support stdin
gemini "Review this code:" < code.py > /tmp/gemini.txt &
codex exec "Review this code:" < code.py > /tmp/codex.txt &
claude -p "Review this code:" --model sonnet < code.py > /tmp/claude.txt &
wait
# Synthesize results from all three files
```

For structured output, use JSON mode:

```bash
gemini -o json "Find bugs:" < code.py > /tmp/gemini.json &
codex exec --json "Find bugs:" < code.py > /tmp/codex.json &
wait
# Claude: use --output-format json
```

## Result Synthesis

| Agreement | Confidence | Action |
|-----------|------------|--------|
| 3/3 agree | HIGH | Accept result |
| 2/3 agree | MEDIUM | Note dissent, likely accept |
| All differ | LOW | Use reasoning model (o3) as tiebreaker |

When synthesizing:
1. Identify common findings across models
2. Flag unique insights from individual models
3. Note disagreements and which model dissents
4. Use reasoning model to resolve conflicts if needed

```bash
# Tie-breaker: feed conflicting outputs to reasoning model
codex exec -m o3 "Gemini found X, Codex found Y. Which is correct and why?"
```

## Error Recovery

```
Primary fails → Try backup from routing table
Rate limited → Wait + retry with backoff
Auth missing → Skip tool, note in output
All fail → Return partial results with caveats
```

Check tool availability:

```bash
# Verify tool is available before use
command -v gemini >/dev/null && gemini "prompt" || echo "Gemini not available"
```

## Context Window Sizes

| Tool | Model | Input | Output |
|------|-------|-------|--------|
| Gemini | `gemini-3.1-pro-preview` | 1M tokens | 64K tokens |
| Gemini | `gemini-3-flash-preview` | 1M tokens | 64K tokens |
| Gemini | `gemini-2.5-pro` / `flash` | 1M tokens | 64K tokens |
| Codex | `gpt-5.4` | 922K tokens | 128K tokens |
| Codex | `gpt-5.4-mini` | 400K tokens | 128K tokens |
| Codex | `gpt-5.3-codex` | 400K tokens | 128K tokens |
| Claude | `opus` (4.6) | 1M tokens | 128K tokens |
| Claude | `sonnet` (4.6) | 1M tokens | 64K tokens |
| Claude | `haiku` (4.5) | 200K tokens | 64K tokens |

**All three tools support ~1M context.** Gemini (all models), Codex gpt-5.4, and Claude Opus/Sonnet 4.6 all support 1M input.

**For large context tasks (code review, log analysis, full-repo review):**
```bash
# All plans — 1M context for Opus/Sonnet 4.6
claude -p "Review:" --model opus < all-source.txt
```

**Auto-routing by size:** If input fits in ~200K, any model works. Above 200K, use Gemini, Codex gpt-5.4, or Claude Opus/Sonnet.

## Feeding Files to Models

### Stdin Support

All three tools support stdin with positional prompts:

| Tool | `"prompt" < file.py` | How it works |
|------|---------------------|-------------|
| Gemini | ✅ | Stdin appended as context |
| Claude | ✅ | Stdin appended as context |
| Codex | ✅ | Stdin appended as `<stdin>` block |

### Single File

```bash
# All three tools work the same way
gemini "Review:" < file.py
codex exec "Review:" < file.py
claude -p "Review:" --model opus < file.py
```

### Multiple Files

```bash
# Multiple files with headers (works for all tools)
find src -name "*.py" -exec sh -c 'echo "=== {} ==="; cat {}' \; | gemini "Review this codebase:"
find src -name "*.py" -exec sh -c 'echo "=== {} ==="; cat {}' \; | codex exec "Review this codebase:"
find src -name "*.py" -exec sh -c 'echo "=== {} ==="; cat {}' \; | claude -p "Review:" --model opus

# With size check (estimate tokens before sending)
CHARS=$(find src -name "*.py" -exec cat {} + | wc -c)
echo "~$((CHARS / 4)) tokens"  # If >900K, too large even for 1M models
```

## Session Reuse (Keep Context)

All tools support session persistence - build context once, ask follow-ups without re-sending files:

| Tool | Resume | Fork | List Sessions |
|------|--------|------|---------------|
| Gemini | `gemini -r latest` | N/A | `gemini --list-sessions` |
| Codex | `codex resume` | `codex fork` | N/A (auto-saved) |
| Claude | `claude -c` / `claude -r <id>` | `claude -c --fork-session` | `claude -r` (picker) |

**For large codebase review:** Use `gemini -i "prompt"` to load context and stay interactive, or resume later with `gemini -r latest`. Gemini retains sessions for 30 days. Claude supports `--from-pr` to resume sessions linked to PRs.

## Quick Reference

| Tool | Command | Best For |
|------|---------|----------|
| Gemini | `gemini "prompt" < file` | 1M context, research, free tier |
| Codex | `codex exec "prompt" < file` | Code review, 1M context (gpt-5.4) |
| Claude | `claude -p "prompt" < file` | Fresh context, security analysis |

## Model Selection

| Tool | Quality | Fast | Reasoning |
|------|---------|------|-----------|
| Gemini | `-m pro` | `-m flash` | pro |
| Codex | `-m gpt-5.4` (default) | `-m gpt-5.4-mini` | `-m o3` |
| Claude | `--model opus` | `--model sonnet` | `--model opus --effort max` |

**Full model names:** Gemini: `gemini-3.1-pro-preview`, `gemini-3-flash-preview`, `gemini-3.1-flash-lite-preview`. Codex: `gpt-5.4` (default), `gpt-5.4-mini`, `gpt-5.3-codex`, `o3`, `o4-mini`. Claude: `opus` (4.6), `sonnet` (4.6), `haiku` (4.5).

## Common Patterns

### Pattern 1: Consensus Review
Ask all 3 models the same question, compare answers, flag disagreements.

```bash
# All three support stdin
gemini "Review this code for bugs:" < code.py > /tmp/g.txt &
codex exec "Review this code for bugs:" < code.py > /tmp/c.txt &
claude -p "Review this code for bugs:" < code.py > /tmp/cl.txt &
wait
```

### Pattern 2: Specialist Dispatch
Route to best model for task type (see routing table above).

```bash
# Security audit → Claude opus
claude -p "Security audit:" --model opus < api.py

# Large file analysis → Gemini
gemini "Analyze this log:" < large-log.txt

# Code optimization → Codex
codex exec -m gpt-5.4 "Optimize this code:" < perf.py
```

### Pattern 3: Fallback Chain
Try primary → if fails → try backup → if fails → report.

```bash
gemini "prompt" 2>/dev/null || \
  codex exec "prompt" 2>/dev/null || \
  echo "All tools failed"
```

**Note:** Exit code alone doesn't catch all failures—some models return 0 with error text. For critical tasks, validate output content.

### Pattern 4: Large Context Handling
All three tools support ~1M token context. Use any for large files.

```bash
# Gemini handles large context (free tier)
gemini "Review this large codebase:" < all-source.txt

# Codex gpt-5.4 (1M context, code-specialized)
codex exec "Review this large codebase:" < all-source.txt

# Claude opus (1M context)
claude -p "Review:" --model opus < all-source.txt

# Cascade: fast summary → deep analysis
SUMMARY=$(gemini "Summarize key points:" < huge-file.txt)
claude -p "Analyze this summary:" --model opus <<< "$SUMMARY"
```

## Budget Awareness

| Tool | Free Tier | Cost Notes |
|------|-----------|------------|
| Gemini | Yes | Use first for cost savings |
| Codex | Limited | o3 is expensive |
| Claude | No | Per-token billing |

Strategy: Start with Gemini (free), escalate to paid models only when needed.

## Detailed References

- `references/gemini-cli.md` - Gemini CLI details
- `references/codex-cli.md` - Codex CLI details
- `references/claude-cli.md` - Claude CLI details
- `references/orchestration-patterns.md` - Advanced patterns
