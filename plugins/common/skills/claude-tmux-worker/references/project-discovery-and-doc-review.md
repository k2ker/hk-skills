# Project-local skill and doc discovery

Use this when a repo has its own Claude/AI workflow files, project-local skills, or review artifacts.

## Core principle

Do **not** assume Claude automatically reads every project-local rule or skill. Make discovery explicit, verify the files that hold the actual instructions, and tell the worker exactly what to load before asking for edits.

Repo rules win over generic Hermes/common skills for repo-specific behavior.

## What to inspect before editing code

1. `CLAUDE.md` at repo root.
2. `docs/AI_COLLABORATION.md` if present.
3. Relevant `docs/api/*` or other domain docs before changing implementation details.
4. Any `.plan/*` review artifacts that capture prior adversarial review or refactor findings.
5. `.claude/settings.local.json` and `.claude/settings.local` if present.
6. `.claude/skills/` and any backing symlink targets.
7. `.agents/skills/` and any backing skill files.
8. `skills-lock.json` if present.

## Identify actual content, not just directories

- A skills directory existing does not mean it contains a usable `SKILL.md`.
- Treat directory presence as a signal, then verify the files that hold the real instructions.
- If both `.claude/` and `.agents/` are present, inspect both before asking Claude to act.
- Do **not** assume a sparse `.claude/skills/` listing means no skills exist; check symlink targets.
- Do **not** trust a summary of docs or review artifacts without reading the actual repo files.

## Tell Claude what to load

Give the worker the exact local paths up front so it does not guess at project rules.

Good prompt pattern:

```text
Read CLAUDE.md, docs/AI_COLLABORATION.md, the relevant docs/api files, and any .plan review artifacts first.
Then inspect .claude/settings.local*, .claude/skills/, .agents/skills/, and skills-lock.json if present.
Resolve backing symlink targets before making changes.
Do not assume the directory contents are the full skill set.
Cite the local rule/skill you used if the edit is sensitive or stylistically constrained.
```

If the repo uses tmux bridge / MCP, prefer the interactive worker path over headless `claude -p` style automation.

## Keep the workflow grounded

- Prefer `git status`, `git diff`, and repo tests after changes.
- Use the repo's own quality gates first (`lint`, `typecheck`, local smoke scripts).
- For related edits in the same feature area, batch the edits first and run one integrated smoke pass at the end instead of per-change smoke loops.
- Require a short rationale that cites the specific local rule/skill used when the edit is sensitive or stylistically constrained.

## Verify before reporting success

- Confirm the changed files, intended diff, and any test/build/smoke signal.
- Check pushed commit / remote state if you claimed to push.
- Do not report success without checking the resulting workspace.

## Pitfalls

- Treating `.claude/skills/` as automatically populated just because the folder exists.
- Assuming a local skill was applied when the worker was never explicitly told to inspect it.
- Mixing up project-local skills with generic Hermes skills; repo rules win for repo-specific behavior.
- Forgetting to check both `.claude/skills/` and `.agents/skills/` when a repo uses both conventions.
- Skipping `.plan/*` review artifacts that may contain blocker/risk findings.
