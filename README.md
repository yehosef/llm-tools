# LLM CLI Tools

A Claude Code skill/plugin that enables using other LLM CLI tools (Gemini, Codex, Claude) for validation, second opinions, and cross-checking work.

## What This Does

This skill teaches Claude Code how to invoke other LLM command-line tools. When you say things like:

- "Validate this plan with Gemini"
- "Get Codex's opinion on this code"
- "Cross-check this with a fresh Claude context"

Claude will know how to call the appropriate CLI tool and synthesize the response.

## Supported Tools

| Tool | Provider | Best For |
|------|----------|----------|
| `gemini` | Google | Large context (1M tokens), research tasks |
| `codex` | OpenAI | Code review, finding bugs, different perspective |
| `claude` | Anthropic | Fresh context, different model tier |

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

Once installed, just ask Claude to use other tools:

```
"Validate this implementation plan with Gemini"

"Have Codex review this code for bugs"

"Get a second opinion on this approach from Opus"
```

Claude will automatically:
1. Read your content
2. Invoke the appropriate CLI tool
3. Synthesize the response

## How It Works

This is a **skill** (not a command wrapper). It provides Claude with knowledge about:

- How to call each CLI tool non-interactively
- When to use each tool (strengths/weaknesses)
- How to format prompts for best results
- How to handle errors

Claude then uses this knowledge + Bash to invoke the tools as needed.

## File Structure

```
llm-tools/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── skills/
│   └── llm-cli-tools/
│       ├── SKILL.md             # Main skill knowledge
│       └── references/
│           ├── claude-cli.md    # Claude CLI details
│           ├── gemini-cli.md    # Gemini CLI details
│           └── codex-cli.md     # Codex CLI details
└── README.md
```

## License

BSD-3-Clause
