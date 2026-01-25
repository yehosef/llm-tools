# Contributing to LLM Tools

Thanks for your interest in contributing!

## Reporting Issues

- Check existing issues first
- Include CLI version and error messages
- Describe what you expected vs what happened

## Pull Requests

1. Fork the repo
2. Create a feature branch
3. Make your changes
4. Test with Claude Code: symlink to `~/.claude/skills/` and verify skill loads
5. Submit PR with clear description

## Code Style

- Keep documentation concise
- Use consistent markdown formatting
- Update model information with dates (e.g., "Updated 2026-01")

## Adding New CLI Tools

To add support for a new LLM CLI:

1. Create `skills/llm-cli-tools/references/<tool>-cli.md`
2. Include: Installation, Authentication, Non-Interactive Usage, Models, Troubleshooting
3. Update `SKILL.md` Quick Reference table
4. Update `README.md` Supported Tools table

## Questions?

Open an issue on GitHub.
