---
name: skill-library-curation
description: Curate class-level skills, consolidate narrow one-off entries, and maintain references/templates/scripts for reusable skill knowledge.
---

# Skill library curation

Use this skill when a session reveals reusable knowledge about how to structure, add, patch, or consolidate agent skills.

## Core objective

Keep the library *class-level* and durable:

- Prefer broad umbrella skills over one-session, one-feature skills.
- Put session-specific detail in `references/` instead of bloating `SKILL.md`.
- Add `templates/` for starter artifacts and `scripts/` for deterministic rerunnable checks.
- Patch an existing umbrella skill before creating a sibling if the learning belongs there.

## Decision rules

1. **Update an existing umbrella first.**
   - If the learning fits an already-loaded or clearly related skill, patch that skill.
   - Add a new subsection, trigger, pitfall, or verification step.

2. **Create a new umbrella only when needed.**
   - The skill name must describe a class of work, not a single task, bug, repo, or date.
   - Good: `skill-library-curation`, `slack-workspace-ops`, `project-planning`.
   - Bad: `hodurang-web-design-skill-addition`, `fix-2026-07-03-skill-sync`.

3. **Put detail in support files.**
   - `references/<topic>.md`: session notes, examples, quotes, quirks, condensed research.
   - `templates/<name>.<ext>`: reusable starter files.
   - `scripts/<name>.<ext>`: deterministic checks or generators the skill can invoke.

## What belongs in SKILL.md

Keep the main skill concise but rich:

- Triggers / when to use
- Durable rules and priorities
- Recommended workflow
- Common pitfalls
- Verification / success criteria
- A pointer to any support files

## What does *not* belong in SKILL.md

Avoid turning the skill into a logbook.

- Do not store one-off task narratives.
- Do not store file counts, commit SHAs, issue numbers, or stale execution outcomes.
- Do not encode environment-dependent failures as permanent rules.

## Practical workflow

1. Identify the reusable class of work.
2. Choose the broadest fitting umbrella.
3. Patch that umbrella with the lesson.
4. If the lesson is still too specific, move it to `references/`.
5. Verify the updated skill still reads like a reusable guide, not a session transcript.

## Pitfalls

- Creating too many narrow sibling skills for one project.
- Mixing durable policy with session-only evidence.
- Overwriting an umbrella when a small patch or reference note would do.
- Forgetting to add a support-file pointer after creating `references/` or `templates/`.

## Verification

Before considering the update done, check that:

- The skill title names a class of work.
- The instructions apply beyond a single session.
- Any session-specific detail lives in `references/`.
- The library would be easier to navigate, not harder.

## Support files

- `references/hodurang-web-skill-expansion.md` — example of expanding a project-local library from a narrow technical list to a class-level design + implementation set.
