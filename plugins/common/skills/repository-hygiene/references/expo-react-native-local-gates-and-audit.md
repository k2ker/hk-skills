# Expo / React Native local quality gates and safe audit fixes

Use this reference when cleaning or hardening an Expo React Native repo after repository hygiene work.

## Lightweight Husky + lint-staged pattern

For Expo/RN apps, keep `pre-commit` practical. Native builds and device checks are too slow for every commit; use them as explicit QA tasks instead.

Recommended `package.json` additions:

```json
{
  "scripts": {
    "prepare": "husky",
    "precommit": "lint-staged && npm run typecheck",
    "format": "prettier --write .",
    "format:check": "prettier --check ."
  },
  "lint-staged": {
    "*.{ts,tsx,js,jsx}": [
      "eslint --fix --max-warnings=0",
      "prettier --write"
    ],
    "*.{json,md,yml,yaml}": [
      "prettier --write"
    ]
  }
}
```

Recommended files:

```text
.husky/pre-commit
.prettierrc
```

Example `.husky/pre-commit` for Husky v9:

```sh
npm run precommit
```

Example `.prettierrc` when using `prettier-plugin-tailwindcss`:

```json
{
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

## Verification recipe

After installing/configuring Husky:

```bash
npm run prepare
git add package.json package-lock.json .husky/pre-commit .prettierrc
npm run precommit
git diff --check
npm run lint
npm run typecheck
```

If you run `npm run precommit` manually before `git commit`, remember the commit itself will invoke the same hook again. This is expected; it proves the hook is wired.

## Safe `npm audit fix` pattern

For Expo projects, prefer:

```bash
npm audit fix
npm audit --json > /tmp/audit.json || true
```

Then inspect `metadata.vulnerabilities` from the JSON rather than relying only on the exit code. `npm audit fix` can apply useful safe lockfile updates and still exit non-zero when remaining advisories require `--force`.

Important interpretation:

- If `package.json` is unchanged and only `package-lock.json` changed, this is usually a transitive lockfile refresh.
- If high/critical vulnerabilities drop to zero but moderate advisories remain, do not run `npm audit fix --force` automatically.
- In Expo/RN repos, `--force` may jump Expo SDK, `expo-dev-client`, or `react-native` to breaking versions. Treat that as a separate migration task with native QA.

Minimum verification after safe audit fixes:

```bash
npm run lint
npm run typecheck
git add package-lock.json
npm run precommit
git diff --check
```
