---
name: node-quality-gates
description: "Design and implement local and remote quality gates for Node, React, Next.js, Expo, and React Native projects: Husky, lint-staged, typecheck, tests, pre-push, and CI boundaries."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux, windows]
metadata:
  hermes:
    tags: [node, husky, lint-staged, ci, pre-commit, quality-gates, expo, react-native]
    related_skills: [repository-hygiene, nextjs-prisma-github-actions-ci, playwright-cli]
---

# Node Quality Gates

Use this skill when adding, reviewing, or troubleshooting quality gates in a Node-based web or mobile repo: Husky hooks, lint-staged, Prettier, ESLint, typecheck, tests, pre-push hooks, or CI/MR checks.

## Core rule: Husky and CI are complementary

When hyeong asks whether Husky pre-commit is enough, answer with this distinction:

| Guard | Best for | Cannot guarantee |
|---|---|---|
| Husky pre-commit | fast local feedback, staged-file formatting/fixes, blocking obvious mistakes before commit | `--no-verify`, GitLab/GitHub web edits, bot commits, other machines without hooks installed, clean-environment reproducibility, merge-time enforcement |
| CI | remote reproducibility, MR/merge gate, team-wide enforcement, clean install | instant local feedback before a commit |

Default recommendation: **Husky + lint-staged first**, then add minimal CI when the repo needs remote enforcement.

## Discovery checklist

Before installing anything, inspect:

```bash
node -e "const p=require('./package.json'); console.log(JSON.stringify({scripts:p.scripts, devDependencies:p.devDependencies, lintStaged:p['lint-staged']}, null, 2))"
find . -maxdepth 2 -name '.husky' -o -name '.gitlab-ci.yml' -o -name '.github'
```

Check whether scripts already exist:

- `lint`
- `lint:fix`
- `typecheck`
- `test`
- `format` / `format:check`
- `prepare`

Do not silently install packages if hyeong asked to confirm package/architecture choices first; explain the small tradeoff and proceed after approval.

## Expo / React Native maintenance gates

For Expo React Native repos, distinguish **SDK-compatible patch alignment** from a full Expo SDK upgrade.

Recommended order when `expo-doctor` or `expo install --check` reports package mismatch:

1. Run `npx expo install --check` and `npx expo-doctor` to identify SDK-expected versions.
2. Align only the versions required for the installed SDK first, for example:

```bash
npx expo install expo@~<same-sdk-patch> react-native@<expected-rn> expo-router@~<expected-router>
```

3. Verify with `npx expo install --check`, `npm run lint`, `npm run typecheck`, Android dev-client run, and mobile smoke QA if available.
4. Treat Expo SDK major upgrades (for example SDK 53 -> 56) as a separate migration with native diff/build verification, not as a routine package update.

Do not use `npm update` or `npm audit fix --force` as the first answer to Expo/RN version drift; those can jump to incompatible Expo/RN majors.

## Recommended lightweight Husky setup

For Expo/React Native and frontend repos, keep pre-commit practical. Heavy checks make developers bypass hooks.

Install:

```bash
npm install -D husky lint-staged prettier
```

Initialize:

```bash
npx husky init
```

Recommended `package.json` additions:

```json
{
  "scripts": {
    "prepare": "husky",
    "lint": "expo lint",
    "typecheck": "tsc --noEmit",
    "precommit": "lint-staged && npm run typecheck"
  },
  "lint-staged": {
    "*.{ts,tsx,js,jsx}": "eslint --fix",
    "*.{json,md,yml,yaml}": "prettier --write"
  }
}
```

Recommended `.husky/pre-commit`:

```sh
npm run precommit
```

If `typecheck` is slow, move it to `pre-push` or CI and keep pre-commit to `lint-staged` only.

## Minimal CI after local hooks

Add CI when remote/MR protection matters. Minimal Node/Expo verification:

```yaml
stages:
  - verify

verify:
  image: node:20
  stage: verify
  script:
    - npm ci
    - npm run lint
    - npm run typecheck
```

CI is especially important when:

- the repo is shared by more than one person/agent
- pushes happen from automation
- merge requests are used
- the hook can be bypassed with `--no-verify`
- a clean install must be proven

## Verification after adding hooks

Run the actual commands, not just inspect files:

```bash
npx lint-staged --allow-empty
npm run typecheck
npm run lint
git diff --check
```

Then do a safe hook-level check by staging a harmless file or using the hook command directly:

```bash
npm run precommit
```

After `precommit`, re-check `git status` and `git diff --cached` because lint-staged / prettier may rewrite staged files before commit.

For feature work, keep local quality gates and product smoke separate: use lint/typecheck/precommit while editing, then run one integrated device or app smoke pass after the related bundle of changes is complete instead of smoke-testing each small edit in isolation.

Do not create fake commits just to test hooks unless hyeong asks.

## Pitfalls

- Do not put EAS local builds in pre-commit; they are too heavy.
- Do not make pre-commit run the entire world by default. Fast hooks get used; slow hooks get bypassed.
- Do not assume Husky exists because scripts exist; check `.husky/` and `prepare`.
- Do not claim CI exists just because old pipelines exist; verify current branch and CI config file.
- If adding Prettier to a repo with no existing format baseline, avoid reformatting the entire codebase unless hyeong explicitly wants a formatting-only commit.
