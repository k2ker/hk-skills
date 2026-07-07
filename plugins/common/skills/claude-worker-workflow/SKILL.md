---
name: claude-worker-workflow
description: Use when Claude Code works as the implementation worker for this repo.
---

# Claude Worker Workflow

## Role

Claude Code is the implementation worker. Klleon Hermes is PM/coordinator/verifier. hyeong is product/decision owner.

## Before work

1. Read `CLAUDE.md`.
2. Read `AGENTS.md`.
3. Read `docs/AI_COLLABORATION.md`.
4. Read `docs/DEVELOPMENT_RUNBOOK.md`.
5. Run:

```bash
git status -sb
```

6. State the files you expect to touch.

## During work

- Keep changes narrow.
- Do not mix unrelated tasks.
- Prefer editing the package/app that owns the behavior.
- If a decision changes DB/API/product boundaries, update docs before code spreads.

## Before reporting done

```bash
pnpm format
pnpm lint
pnpm typecheck
pnpm test
```

For app changes also run:

```bash
pnpm --filter admin build
pnpm --filter client build
```

## Never without hyeong approval

- `git commit`
- `git push`
- deploy
- production DB changes
- `supabase link`
- `supabase db push`
