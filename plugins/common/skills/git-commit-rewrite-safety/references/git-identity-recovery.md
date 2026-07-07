# Git identity recovery notes

This note captures the workflow demonstrated in the session where a pushed commit inherited a host-local identity because repo-local `user.name` / `user.email` were unset.

## Observed failure mode

- Git fell back to a host-local identity such as `hyeong <hyeong@hk-macmini.local>`.
- The user asked to restore the commit to the previous/project-normal author.
- The fix was to set repo-local identity from `HEAD~1`, amend the commit, and push with `--force-with-lease`.

## Recovery sequence

```bash
PREV_NAME=$(git show -s --format='%an' HEAD~1)
PREV_EMAIL=$(git show -s --format='%ae' HEAD~1)

git config user.name "$PREV_NAME"
git config user.email "$PREV_EMAIL"
git commit --amend --reset-author --no-edit
git push --force-with-lease origin <branch>
```

## Verification

```bash
git show -s --format='author=%an <%ae>%ncommitter=%cn <%ce>%ncommit=%H' HEAD
git status -sb
```

## Notes

- Use the previous commit's author only when that is the project-normal identity and the user explicitly wants the revert.
- Prefer repo-local config over global config for project work when identity needs to be stable within a single repository.
