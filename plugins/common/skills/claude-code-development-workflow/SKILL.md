---
name: claude-code-development-workflow
description: "Coordinate Claude Code workers through tmux as the default development path for Hermes-style repo work, with project-local Claude files and skills as first-class repo artifacts."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
metadata:
  hermes:
    tags: [claude-code, tmux, worker-orchestration, project-local-context, monorepo]
    related_skills: [claude-tmux-worker, claude-worker-workflow]
---

# Claude Code Development Workflow

Use this skill when a project should be developed by a Claude Code worker session rather than by Hermes directly editing code.

## Core policy

- Prefer **Claude Code in an interactive tmux session** for implementation work.
- Treat Hermes as **PM / coordinator / verifier**, not the default code author.
- Use direct Hermes edits only for trivial, obviously safe exceptions or when the user explicitly asks for them.
- Keep one clear worker session per task; do not mix unrelated work into the same Claude pane.

## What to look for in the repo

Before starting work, check whether the repo already defines its own AI collaboration contract:

- `CLAUDE.md`
- `docs/AI_COLLABORATION.md`
- `.claude/settings.json`
- `.claude/rules/`
- `.claude/skills/`
- `.claude/commands/`
- `.mcp.json`

If the repo has `.claude/skills/`, inspect the backing skill files or symlink targets before assuming the directory is empty. A shallow listing is not enough.

## Standard workflow

1. Start the Claude worker in the repo workdir.
2. Load the repo's local Claude contract files first.
3. Send a self-contained task prompt with explicit scope and verification criteria.
4. Capture the pane periodically and watch for trust / MCP / permission prompts.
5. Verify changed files and run project checks yourself.
6. Report only what is backed by git diff, file reads, or command output.

## Recommended repo-local files

If the project is new, create these early:

- `CLAUDE.md`
- `.claude/skills/`
- `.claude/rules/`
- `.claude/commands/`
- `.mcp.json`
- `docs/AI_COLLABORATION.md`

See `references/project-local-claude-environment.md` for a compact checklist and suggested contents.

## Pitfalls

- Do not assume `claude -p` is the right mode just because it is simpler; many real development loops need a live worker.
- Do not treat the worker's summary as proof. Verify with git diff, file reads, and test output.
- Do not bury project rules only in a personal profile; durable workflow belongs in the repo.
- Do not overbuild shell wrappers when tmux or tmux-bridge can manage the pane lifecycle.

## Support files

- `references/project-local-claude-environment.md` — compact checklist for repo-local Claude setup and skill seeding.
