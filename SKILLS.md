# hk-skills — 스킬 인벤토리

> 자동 생성: `scripts/sync-marketplace.mjs`. 직접 수정하지 말 것. 총 16개 스킬 / 6개 번들.

## common (8)

- `claude-code-development-workflow` — Coordinate Claude Code workers through tmux as the default development path for Hermes-style repo work, with project-local Claude files and skills as first-c…
- `claude-tmux-worker` — Use when coordinating Claude Code (or another CLI coding agent) as a real interactive worker in a tmux / tmux-bridge-mcp session while you stay coordinator,…
- `claude-worker-workflow` — Use when Claude Code works as the implementation worker for this repo.
- `git-commit-rewrite-safety` — Safely correct git author identity and rewrite published commits with explicit verification and lease-protected pushes.
- `node-quality-gates` — Design and implement local and remote quality gates for Node, React, Next.js, Expo, and React Native projects: Husky, lint-staged, typecheck, tests, pre-push…
- `repository-hygiene` — Clean up repository clutter, stale docs, agent/tool artifacts, and synchronize API snapshots/documentation with the current source of truth. Use when the use…
- `secret-redaction-and-verification` — Handle PATs, API keys, bot tokens, and other secrets safely: refuse raw values, report only paths or existence, verify access with non-secret calls, and guid…
- `skill-library-curation` — Curate class-level skills, consolidate narrow one-off entries, and maintain references/templates/scripts for reusable skill knowledge.

## web (7)

- `api-only-boundary` — Use when adding client/server communication, API routes, server actions, or data fetching. Enforces that browser code never touches the DB directly and that…
- `frontend-state-ui-guidelines` — Use when implementing forms, server-state fetching, HTTP clients, or UI motion — picks the right tool per concern. Defers per-tool detail to the dedicated sk…
- `web-component-patterns` — UI 컴포넌트 레퍼런스 및 Feature 컴포넌트 템플릿. 기존 컴포넌트 재사용, Skeleton/Modal 패턴. 새 컴포넌트 작성 시 참조.
- `web-context-patterns` — React Context + use-context-selector 팀 컨벤션. Provider/hooks 분리, selector 최적화, useMemo 필터 체인. Context/Provider 설계 시 참조.
- `web-nextjs-patterns` — Next.js App Router 컨벤션. SSR/Hydration, Suspense 분리, Server Component, Client 컴포넌트, 환경변수 설정. Next.js 작업 시 참조. (web-almigo에서 이식, 프로젝트 특화 부분 제거됨)
- `web-tailwind-patterns` — Tailwind CSS 팀 컨벤션. cn() 유틸리티, 조건부 클래스. v3/v4 버전별 패턴은 references 참조.
- `web-tanstack-query-patterns` — TanStack Query + Axios 팀 컨벤션. Query Key 팩토리, queryOptions, Mutation, 캐시 갱신, Infinite Query, SSR Prefetch, Axios Instance 패턴. API/Query 작성 시 참조.

## rn (0)

_아직 스킬 없음(placeholder)._


## supabase (0)

_아직 스킬 없음(placeholder)._


## hk (0)

_아직 스킬 없음(placeholder)._


## orca (1)

- `orca-workers` — Use when coordinating parallel Orca sub-worktree workers for one feature/page cycle: provision worktrees, brief, supervised dispatch (task-create + dispatch…
