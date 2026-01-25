# LLM CLI Tools

A Claude Code skill/plugin for **multi-model LLM orchestration** - route tasks to the right model, run in parallel, synthesize results.

## What This Does

This skill teaches Claude Code how to coordinate multiple LLM CLI tools (Gemini, Codex, Claude) for complex tasks:

- **Task Routing**: Send tasks to the model best suited for them
- **Parallel Execution**: Run multiple models simultaneously for consensus
- **Result Synthesis**: Compare, merge, and build consensus from multiple responses
- **Error Recovery**: Fallback chains when tools fail

When you say things like:

- "Review this code with multiple models"
- "Get consensus on this approach"
- "Use Gemini for the large file, then analyze with Claude"
- "Validate this with Codex"

Claude will orchestrate the appropriate tools and synthesize the results.

## Task Routing

| Task Type | Primary Model | Why |
|-----------|---------------|-----|
| Large context (>200k) | Gemini | 1M token window |
| Code review | Codex (gpt-5.2-codex) | Code-specialized |
| Security audit | Claude opus | Thorough analysis |
| Quick validation | Gemini | Free tier |
| Reasoning/logic | Codex o3 | Reasoning model |

## Supported Tools

| Tool | Provider | Best For |
|------|----------|----------|
| `gemini` | Google | Large context (1M tokens), research, free tier |
| `codex` | OpenAI | Code review, GPT-5 reasoning, o3 for logic |
| `claude` | Anthropic | Fresh context, security analysis |

## Installation

### Option 1: Plugin Marketplace (Recommended)

```bash
# In Claude Code, run:
/plugin marketplace add yehosef/llm-tools
/plugin install llm-tools
```

### Option 2: Direct Symlink

```bash
# Clone the repo
git clone https://github.com/yehosef/llm-tools.git

# Symlink the skill
ln -s /path/to/llm-tools/skills/llm-cli-tools ~/.claude/skills/llm-cli-tools
```

## Prerequisites

Install the CLI tools you want to use:

```bash
# Gemini
npm install -g @google/gemini-cli

# Codex
npm install -g @openai/codex

# Claude (usually already installed)
npm install -g @anthropic-ai/claude-code
```

Then authenticate each tool:
- **Gemini**: Run `gemini` and login with Google
- **Codex**: Run `codex` and login with OpenAI/ChatGPT
- **Claude**: Run `claude` and use `/login`

## Usage Examples

Once installed, ask Claude to orchestrate multiple models:

```
"Review this code with all three models and summarize findings"

"Get consensus from Gemini and Codex on this approach"

"Use Gemini for the large log file, then have Claude analyze the summary"

"Run a security audit with Claude opus"
```

Claude will automatically:
1. Route to the appropriate model(s)
2. Run in parallel when beneficial
3. Synthesize and compare results
4. Handle errors with fallbacks

## How It Works

This is a **skill** (not a command wrapper). It provides Claude with knowledge about:

- How to call each CLI tool non-interactively
- When to use each tool (task routing table)
- How to run parallel execution
- How to synthesize results from multiple models
- Error recovery and fallback chains

Claude then uses this knowledge + Bash to orchestrate the tools as needed.

## File Structure

```
llm-tools/
├── .claude-plugin/
│   ├── marketplace.json         # Marketplace manifest
│   └── plugin.json              # Plugin manifest
├── skills/
│   └── llm-cli-tools/
│       ├── SKILL.md             # Main skill knowledge
│       └── references/
│           ├── claude-cli.md    # Claude CLI details
│           ├── gemini-cli.md    # Gemini CLI details
│           ├── codex-cli.md     # Codex CLI details
│           └── orchestration-patterns.md  # Advanced patterns
└── README.md
```

## License

BSD
