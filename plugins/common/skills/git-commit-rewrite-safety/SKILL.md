---
name: git-commit-rewrite-safety
description: "Safely correct git author identity and rewrite published commits with explicit verification and lease-protected pushes."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [Git, identity, force-push, amend, rewrite, safety, repository]
    related_skills: [github-pr-workflow, github-repo-management, github-auth]
---

# Git Commit Rewrite Safety

Use this skill when a commit needs identity correction, when Git is falling back to a host-local author/committer, or when a pushed commit must be amended and re-pushed safely.

## Triggers

- Commit author/committer looks wrong or machine-local (`user@hostname.local`)
- User says "이전으로 돌려", "author 원복", "force push 해도 돼?", "이전 커밋 기준으로 맞춰"
- A pushed commit must be amended and the remote branch rewritten intentionally
- Repo-local git identity is missing and should be restored to the project-normal author

## Principles

1. **Check what Git will actually use before committing.**
2. **Prefer repo-local identity for project work.** It keeps the repo stable across machines and sessions.
3. **When restoring a commit, use the project-normal author rather than inventing a new one.** If the previous commit is the correct source of truth, reuse it.
4. **Use `--force-with-lease`, not blind `--force`, when rewriting a pushed branch.**
5. **Verify the final author, committer, and remote tip after the rewrite.**

## Workflow

### 1. Inspect current identity

```bash
git config --get user.name || true
git config --get user.email || true
git var GIT_AUTHOR_IDENT
git var GIT_COMMITTER_IDENT
```

If these resolve to a host-local fallback identity, stop and decide whether to set repo-local config before the next commit.

### 2. Restore the intended author identity

If the project convention is to match the previous commit's author, derive it from the prior commit:

```bash
PREV_NAME=$(git show -s --format='%an' HEAD~1)
PREV_EMAIL=$(git show -s --format='%ae' HEAD~1)
git config user.name "$PREV_NAME"
git config user.email "$PREV_EMAIL"
```

If the repo has an explicit canonical identity, use that instead of copying from history.

### 3. Amend the commit

```bash
git commit --amend --reset-author --no-edit
```

Use `--reset-author` when the goal is to record the corrected identity in the rewritten commit.

### 4. Rewrite the remote only when intended

If the bad commit was already pushed, update the branch with a lease-protected force push:

```bash
git push --force-with-lease origin <branch>
```

Do not rewrite shared history unless the user explicitly wants the remote updated.

### 5. Verify

```bash
git show -s --format='author=%an <%ae>%ncommitter=%cn <%ce>%ncommit=%H' HEAD
git status -sb
```

The author/committer should match the intended identity, and local/remote branch tips should match.

## Pitfalls

- Do not ask for a new author identity if the user has already indicated to restore the previous/project-normal one.
- Do not leave repo-local identity unset after a recovery; the next commit may fall back to the same wrong auto-identity.
- Do not use plain `git push --force` unless the user explicitly accepts the broader risk.
- Do not conflate auth/remote configuration with commit identity. Fix the commit identity separately from remote access.

## Reference notes

- `references/git-identity-recovery.md` — concrete recovery transcript and command sequence for restoring repo-local identity and rewriting a pushed commit.
