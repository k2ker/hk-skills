# Repo ownership handoff / workspace migration

Use this reference when a project repo is being moved from a general/dev workspace into an organization/company workspace and must be handed off with enough operational context for another profile or team to own it.

## Goals

- Make the new workspace the source of truth for the repo and project index.
- Preserve uncommitted work safely during the move.
- Leave compatibility for old paths long enough to avoid breaking existing scripts, memories, and habits.
- Capture development, QA, CI, API, and operations context in concise handoff docs.

## Safe sequence

1. **Inventory before moving**
   - Confirm old repo path and git top-level.
   - Record branch, upstream, HEAD, remote, and dirty worktree count.
   - List untracked files and important local-only env files by key name only, never values.
   - Check whether the target workspace already has a `repos/` directory and whether the target repo path exists.

2. **Move with compatibility**
   - If the target path is empty/missing, move the directory with `mv`.
   - Create a symlink from the old path to the new path when existing automation or memories may still reference the old location.
   - Re-run `git rev-parse --show-toplevel` and `git status -sb` from the new path.

3. **Create handoff docs in the owning workspace**
   - Project index entry: exact repo path, remote, channel/context, and status.
   - Development handoff: stack, package scripts, build/test commands, local tool versions, QA flows, API docs, CI state, known pitfalls, secret policy.
   - Move/ownership note: old path, new path, symlink, dirty worktree status, follow-up cleanup.

4. **Update workspace rules, not runtime internals**
   - If the workspace previously said repos should not live inside it, patch that rule narrowly: repos may live under `repos/` only when the user explicitly assigns ownership to that workspace.
   - Do not edit another Hermes profile's runtime config/memory/skills unless explicitly asked.

5. **Verify after writing**
   - Check generated files exist.
   - Check old path symlink resolves to new path.
   - Run non-destructive repo checks from the new path: `git diff --check`, lint, typecheck where available.
   - Report remaining dirty worktree; do not commit or push unless requested.

## What to document for mobile/app repos

- Android Studio/SDK/JDK/adb/emulator state and exact env exports needed for shell builds.
- `package.json` scripts, especially destructive/clean scripts and QA scripts.
- Maestro or E2E flows, including which ones mutate server/user state and which guard env vars are required.
- Local env key names only; never values.
- API docs/OpenAPI snapshot counts and source URLs.
- Slack/issue tracker/QA list/meeting notes links.

## Pitfalls

- Do not treat a path move as a git change; moving the repo directory preserves uncommitted work, but you still must report the dirty status.
- Do not remove the old path immediately if tools or profiles may still reference it; symlink first, remove later after all references are updated.
- Do not copy secret-bearing `.env.local` values into handoff docs. Key presence is enough.
- Do not push after migration just to “save” the move. A filesystem move outside the repo is not a commit.
