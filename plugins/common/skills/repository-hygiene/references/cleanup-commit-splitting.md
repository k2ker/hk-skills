# Cleanup commit splitting pattern

Use this after a broad repository cleanup has already produced a large mixed worktree. The goal is to turn a scary diff into reviewable commits without changing file contents.

## Pattern

1. Reset only the index, not the worktree:

```bash
git reset
```

This unstages everything while preserving all cleanup edits and deletions.

2. Stage the pure legacy/artifact removal first. Keep API-doc moves and code changes out of this commit:

```bash
git add -- .claude .taskmaster .serena .mcp.json .github/instructions \
  .env_.example docs/plans docs/temp docs/backend-requests \
  docs/backend-push-notification-guide.md NEW_APIS_*.md CLAUDE.md .gitignore
```

Adjust paths to the actual repo. Exclude migrated API docs such as `.claude/skills/<api-skill>` when they are being moved into `docs/api` in a separate commit.

3. Stage API documentation sync separately:

```bash
git add -A -- docs/api swagger.md README.md src/api/hodu/README.md
```

If API source files contain both reference-path comment updates and lint fixes, stage only the doc-reference hunks for this commit and leave lint-only hunks unstaged.

4. Stage dev-only route/test harness removal separately:

```bash
git add -A -- 'src/app/**/*test*' 'src/components/**/*Test*' src/features/mypage/MyPageScreen.tsx
```

Before committing, grep for route/component names to prove no live references remain.

5. Stage lint/code cleanup last:

```bash
git add -A -- src
```

6. Verify each staged commit candidate:

```bash
git diff --cached --stat
git diff --cached --check
```

After all commits, run the full project checks again:

```bash
npm run lint
npm run typecheck
git diff --check
git status -sb
```

## Suggested commit sequence

```text
chore: remove legacy agent and planning artifacts
docs: sync API docs with current OpenAPI snapshot
chore: remove dev-only test routes
fix: resolve lint warnings
```

## Pitfalls

- Do not commit a giant cleanup diff as one blob. Large cleanup work usually needs at least artifact removal, docs/API sync, dev-route removal, and code cleanup separated.
- Do not let `git rm` staging from earlier steps decide the commit boundaries. If the index is mixed, reset the index and re-stage deliberately.
- Do not mix pure API doc moves with lint-only import cleanup in API source files. Use partial staging for comment/reference hunks when needed.
- If Git warns that author identity was inferred from host/user, report it; offer to set repo-local `user.name`/`user.email` or amend authors only if the user wants it.
