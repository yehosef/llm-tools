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
| Large context (>250k) | Claude opus/sonnet or supported Gemini accounts | 1M context on eligible plans (Codex CLI now caps at 272K) |
| Code review | Codex (`gpt-5.6-sol`) | Current frontier Codex coding model |
| Security audit | Claude opus (`--effort xhigh`) | Thorough analysis |
| Quick validation | Codex `gpt-5.6-luna` or Claude haiku | Fast, lower-cost options |
| Reasoning/logic | Claude opus or Codex `gpt-5.6-sol` | Strong general reasoning |
| Long autonomous work | Claude fable | Built for long-horizon agentic runs |
| Image generation | Codex (built-in `image_gen`) or Gemini (`nanobanana` extension) | Claude has no native image generation |
| Audio/video input | Gemini (`@file.mp3`, `@file.mp4`) | Only tool with video input; Codex takes audio too (v0.145+) |

## Supported Tools

| Tool | Provider | Best For |
|------|----------|----------|
| `gemini` | Google | 1M context, video/audio/PDF input, image generation (nanobanana), research — for enterprise/paid API-key users (Gemini 3.1 Pro / 3.6 Flash) |
| `codex` | OpenAI | Code review and agentic coding with the GPT-5.6 family (Sol/Terra/Luna); built-in image generation and audio input |
| `claude` | Anthropic | Security analysis, long-running work with Fable 5, Opus 5 reasoning, and Sonnet 5 daily coding |
| `agy` (Antigravity) | Google | Gemini-family access for individual Google accounts (free/Pro/Ultra); multi-vendor catalog (Gemini 3.5 Flash / 3.1 Pro, Claude 4.6, GPT-OSS 120B) on a weekly quota |

> **Gemini consumer transition:** Gemini CLI stopped serving free, Google AI Pro, and Google AI Ultra accounts on June 18, 2026. Google directs those users to Antigravity CLI. Gemini CLI remains supported for Gemini Code Assist Standard/Enterprise and paid Gemini or Enterprise Agent Platform API keys.

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

# Antigravity (for individual Google accounts; installs binary `agy`)
curl -fsSL https://antigravity.google/cli/install.sh | bash   # or: brew install --cask antigravity-cli
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
│       ├── test/
│       │   └── validate.sh      # Smoke tests for documented patterns
│       └── references/
│           ├── claude-cli.md    # Claude CLI details
│           ├── gemini-cli.md    # Gemini CLI details
│           ├── codex-cli.md     # Codex CLI details
│           └── orchestration-patterns.md  # Advanced patterns
├── CLAUDE.md                    # Project instructions for Claude Code
├── CONTRIBUTING.md              # Contribution guidelines
└── README.md
```

## License

BSD
