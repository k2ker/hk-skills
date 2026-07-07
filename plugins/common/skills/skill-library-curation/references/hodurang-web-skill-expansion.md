# Hodurang web skill expansion — session note

Date: 2026-07-03

## What happened

A project-local library for `hodurang-web` started with a small set of implementation skills, then expanded to include design-oriented skills after the user explicitly asked for "design related all skills".

## Reusable lesson

When curating a project-local library:

- Prefer **class-level umbrellas** over a flat list of one-session entries.
- Group related items under durable domains:
  - implementation/form/query/testing/data
  - design systems / UI-UX / mockups / diagrams
- Keep session-specific detail in `references/`.
- Update the ledger/docs alongside the skill files so the library stays inspectable.

## Concrete pattern from this session

The library was expanded from a technical core to include design classes such as:

- UI/UX judgment
- design systems
- prototype/mockup generation
- diagramming / information design

The following were intentionally excluded or deferred because they were not part of the current product UI/design-system class of work:

- media-generation / audio-video tools
- experimental creative tooling
- unrelated deployment helpers
- `web-vxt` source import

## Why this matters

Future sessions should not repeat the same mistake of creating a long flat list of narrow skills. The better pattern is:

1. find the umbrella
2. extend it
3. stash the session-specific record here
4. keep the main skill readable as a reusable guide
