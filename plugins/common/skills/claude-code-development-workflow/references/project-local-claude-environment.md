# Project-local Claude environment checklist

Use this when a repo should be developed with Claude Code workers via tmux.

## Add early in a new repo

- `CLAUDE.md` — project contract for Claude Code
- `.claude/skills/` — repo-local skills used by Claude
- `.claude/rules/` — modular project rules
- `.claude/commands/` — repeatable slash-command workflows
- `.claude/settings.json` — shared Claude settings
- `.mcp.json` — shared project MCP config when needed
- `docs/AI_COLLABORATION.md` — human/AI workflow and verification rules

## Seed skills from external sources

When a new repo needs durable Claude guidance, copy or adapt the relevant class-level skills from source libraries into the repo-local `.claude/skills/` directory. Prefer skills that cover classes of work, not one-off tasks.

Good seed categories:

- Next.js / app-router workflow
- Prisma schema and migration workflow
- local Supabase / Postgres workflow
- API route and auth workflow
- review / security / planning workflow
- tmux bridge / worker orchestration workflow

## Practical rule

If the repo already has `.claude/skills/`, inspect the backing files or symlink targets before concluding there are no project skills. The directory can be a thin shell around real skill content.
