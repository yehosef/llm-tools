---
name: llm-cli-tools
description: Multi-model LLM orchestration - route tasks to the right model, run in parallel, synthesize results. Use when complex tasks benefit from multiple AI perspectives or when specific models have advantages.
---

# Multi-Model LLM Orchestration

Coordinate Gemini, Codex, and Claude for complex tasks.

## When to Use

- Complex tasks benefiting from multiple perspectives
- Specific models have clear advantages (see routing table)
- User asks for "consensus", "parallel review", or "multiple opinions"
- Large context that exceeds single-model limits
- Need validation or cross-checking

## Task Routing

| Task Type | Primary | Why | Backup |
|-----------|---------|-----|--------|
| Large context (>200k) | Gemini | 1M token window | Split for Claude |
| Code review | Codex (`gpt-5.2-codex`) | Code-specialized | Claude opus |
| Security audit | Claude opus | Thorough analysis | Codex o3 |
| Quick validation | Gemini (free) | Fast, no cost | Codex gpt-4o |
| Reasoning/logic | Codex o3 | Reasoning model | Claude opus |
| Research | Gemini (`-m pro`) | Large context + web | Claude opus |

## Parallel Execution

Run multiple models simultaneously for consensus or speed:

```bash
# Parallel review - all 3 models (stdin avoids argv limits on large files)
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

## Quick Reference

| Tool | Command | Best For |
|------|---------|----------|
| Gemini | `gemini "prompt"` | 1M context, research, free tier |
| Codex | `codex exec "prompt"` | Code review, GPT-5 reasoning |
| Claude | `claude -p "prompt"` | Fresh context, security analysis |

## Model Selection

| Tool | Quality | Fast | Reasoning |
|------|---------|------|-----------|
| Gemini | `-m pro` | `-m flash` (default) | pro |
| Codex | `-m gpt-5.2-codex` | default | `-m o3` |
| Claude | `--model opus` | `--model sonnet` | opus |

**Full model names:** Gemini: `gemini-3-pro-preview`, `gemini-3-flash-preview`. Codex: `gpt-5.2-codex`, `o3`, `o4-mini`. Claude: `opus`, `sonnet`, `haiku`.

## Common Patterns

### Pattern 1: Consensus Review
Ask all 3 models the same question, compare answers, flag disagreements.

```bash
# Use stdin to avoid argv limits on large files
gemini "Review this code for bugs:" < code.py > /tmp/g.txt &
codex exec "Review this code for bugs:" < code.py > /tmp/c.txt &
claude -p "Review this code for bugs:" < code.py > /tmp/cl.txt &
wait
```

### Pattern 2: Specialist Dispatch
Route to best model for task type (see routing table above).

```bash
# Security audit → Claude opus (stdin for large files)
claude -p "Security audit:" --model opus < api.py

# Large file analysis → Gemini
gemini "Analyze this log:" < large-log.txt

# Code optimization → Codex
codex exec -m gpt-5.2-codex "Optimize this code:" < perf.py
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
Use Gemini for 1M context, summarize, then query other models.

```bash
# Gemini handles large context (use stdin for large files)
SUMMARY=$(gemini "Summarize key points:" < huge-file.txt)
# Other models work with summary
claude -p "Analyze this summary: $SUMMARY" --model opus
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
