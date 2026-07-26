# Session Handoff

> 다음 세션 시작 시 `/hk:pre-clear:resume` 호출.
> 저장: 2026-07-26T14:51:27Z · HEAD: c33271e (origin/main과 동기, 미푸시 0) · 브랜치: main

## 세션 목표

hk-skills 마켓플레이스 개편 실행 — web→dev rename, orca-workers 스킬 리팩토링·라이브 검증, **벤더(외부) 스킬 브릿지 구축**(이번 세션 최대 작업), planning-quick 커맨드 이관·리팩토링·배포.

## 완료한 작업 (전부 push 완료 — origin/main = c33271e)

- **web→dev 번들 rename** — `plugins/dev/` (git rename, history 보존). 소비 측은 다음 marketplace update 때 `web@hk-skills`→`dev@hk-skills` 참조 변경 필요.
- **orca-workers 리팩토링** (v0.2.2, orca plugin 0.3.0): ① "번들에 들어있다" 거짓 주장 제거 → Orca가 사용자 레벨에 설치(`~/.claude/skills`→`~/.agents/skills` 심링크)하는 스킬이니 **경로 말고 이름으로 로드** 힌트화. ② stale 라인번호 인용 제거. ③ **모델 역할 A/B/C 모드** — A: Claude 구현→Codex 리뷰(기본) / B: 역방향 / C: Claude 전용(교차세션). Codex 가용성 먼저(`command -v codex`, 없으면 C 강제), **누가 짤지는 사용자 결정**(미지정=A).
- **orca 훅 하드닝** — `check --wait` 차단을 앵커링 정규식으로(오탐·우회 제거, 10케이스 실측). `plugins/orca/hooks/hooks.json`.
- **orca 라이브 검증 2회** — same-worktree 워커 + **서브워크트리 워커**(자체 브랜치·격리 실증). dispatch→worker_done 자동알림→리드 재검증 골격 실동작 확인. P4~P6은 미검증.
- **벤더 브릿지** — `/vendor:add|update|remove` 커맨드(`.claude/commands/vendor/`, repo-local·단순 3단계: skills add→`plugins/vendor/skills/`로 이동→sync). **`plugins/vendor` 번들에 외부 스킬 25개** 설치(tanstack 4·supabase 2·vercel 5·playwright 2·vitest·storybook·turborepo·typescript·tailwind·framer-motion·frontend-design·shadcn·ui-ux-pro-max·prisma-orm-v7-skills·find-skills·skill-creator). **소비 검증 실측 통과** — `claude plugin install`+`details`로 25개 로드 확인(always-on ~3k tok).
- **repo 관리 도구** — `find-skills`·`skill-creator`를 `.claude/skills/`에(이 repo에서 내가 씀) + vendor에도(배포용).
- **planning-quick** — user 전역 `~/.claude/commands/hk/planning-quick.md`를 hk 번들로 이관 후 전역본 삭제(단일 소스). 179→81줄 리팩토링: 스킬 참조 전부 제거(hk UserPromptSubmit 훅이 이미 강제 — 중복), **결정 규칙 재설계**(사실=기재 / 사소한 미정=잠정 default+seal 일괄검토 / **중대한 미정=권고 있어도 반드시 AskUserQuestion**, 애매하면 중대 취급), phase 역할·진입·게이트 표, design↔build 경계(design=계약까지). 용어 "스테이크"→"중대/사소".
- **hk 번들 v0.12.0** — 설명에 planning-quick·훅 3종 반영(stale 정리).
- **문서 최신화** — CLAUDE.md(vendor 브릿지 섹션), README(vendor 옵트인·조합 예), VENDORED-SKILLS.md(현재 상태 노트).
- **도슨트 궁합 분석** — gamescom 스택(Next16·React19·Tailwind4·TanStack·Prisma7.8·Supabase·vitest·playwright·storybook·turbo) 실측 → vendor가 거의 전부 커버, Prisma 구멍은 `prisma-orm-v7-skills` 추가로 메움.

## 진행 중 작업

마켓플레이스 개편 일단락. 모든 커밋 push 완료, working tree clean.

## 다음에 할 일

1. **planning-quick 실전 검증** — 도슨트 등 실제 프로젝트에서 sub-plan 한 사이클(spec→…→summary) 돌려보고 어색한 부분 수정. (리팩토링 버전은 실전 미검증)
2. **user scope 설치 정리 결정** — 사용자가 `/plugin` UI로 dev·hk·orca·vendor 4개를 **user 전역**에 설치함(`~/.claude/settings.json`). 이 repo 개발 시 github 캐시가 로컬 편집을 가리는 shadowing 문제 제기했으나 **미결정** — (a) 전역 제거+소비 프로젝트 committed settings.json로 / (b) 전역 유지.
3. (선택) vendor 애매 3개 정리 판단 — `shadcn`(도슨트는 자체 DS, CLI 안 맞음)·`deploy-to-vercel`·`vercel-cli`(Vercel 배포 안 하면 불필요).
4. (소비 측, 내 소관 아님) 도슨트 committed settings.json에 `dev`·`vendor@hk-skills` 켜기 + 구 `web@` 참조 정리.
5. (트리거 오면) `design` 번들 신설.

## 결정된 사항

- **벤더 = plugins/vendor에 실제 복사본** — 브릿지가 나눠주려면 파일이 `plugins/`에 있어야 함(Claude Code·Hermes 둘 다 plugins/만 읽음). 참조/포인터 방식 기각.
- **벤더 관리 = 단순 3단계 커맨드** — skills add→이동→sync. 무거운 스크립트·매니페스트·SHA 파이프라인은 **과설계로 기각**(사용자 명시). 커뮤니티 소스만 넣기 전 눈으로 확인.
- **orca 3종(orca-cli·orchestration·computer-use)은 vendor에 안 넣음** — orca-workers가 참조로 처리.
- **유용한 스킬은 내 환경 설치 여부와 무관하게 vendor에 넣음** — "이미 있음"은 제외 사유 아님(브릿지니까). supabase·skill-creator도 넣은 이유.
- **planning-quick 스킬 참조 제거** — hk UserPromptSubmit 훅이 매 프롬프트 스킬 로드를 이미 강제 + 같은 번들이라 항상 동반 → 중복.
- **결정 규칙: 중대한 미정은 AI가 대신 결정 금지** — 권고 있어도 AskUserQuestion. 애매하면 중대 취급.
- **이 repo는 self-install 안 함** — 원본이므로. (단 사용자가 user 전역 설치를 해버림 → 다음할일 2)
- **하드코딩 참조(스킬명·라인번호·경로) 금지** — rename/업데이트로 썩음. 이름/역할 힌트로.

## 작업 메모리 (워크플로우·역할·임시 컨텍스트)

- **나 = hk-skills 마켓플레이스 담당** — 회사 프로젝트(docent 등) 직접 수정 금지(읽기는 OK, 이번에 궁합 분석은 read-only로 함).
- **SSOT→파생**: `scripts/sync-marketplace.mjs`가 marketplace.json plugins[]·README 번들 표 재생성. 파생 직접 편집 금지. pre-commit 자동.
- **벤더 넣기 실무**: `DISABLE_TELEMETRY=1 npx skills add <owner>/<repo> --skill <이름> --copy -a claude-code -y` (스크래치 폴더에서) → `.claude/skills/<이름>` 생성됨 → `plugins/vendor/skills/`로 복사 → sync. **스킬 이름 정확히 하나씩**이 안전(콤마 다중·틀린 이름이 이전 실패 원인, 모노레포 탓 아님). 이름 못 찾으면 원본 clone해서 SKILL.md 위치 찾고 폴더명=frontmatter name으로 복사.
- **`claude plugin` CLI(v2.1.218) 유용**: `marketplace add/update/list/remove`, `install <p>@<m> --scope user|project|local`, `uninstall --scope`, `details <p>@<m>`(스킬 인벤토리+토큰), `validate .`. 마켓 캐시 = `~/.claude/plugins/marketplaces/hk-skills/`.
- **배포 사이클**: 편집→sync→커밋→push→`claude plugin marketplace update hk-skills`(이 머신 캐시 갱신). 이번 세션 후반은 push 자유롭게 진행(사용자 "ok 배포" 흐름).
- **사용자 소통**: 쉬운 일상 한국어·한자어 자제·과설계 금지(영속 메모리에 저장됨). 커밋은 요청/흐름 확인 후.

## 미해결 질문

- **user scope 전역 설치 유지 여부** — 다음할일 2. shadowing 문제 제기했으나 사용자 응답 없이 다른 주제로 넘어감.

## 참조 파일 (다음 작업 1순위에 즉시 필요한 것만)

- `plugins/hk/commands/planning-quick.md` — 실전 검증 대상 (81줄 최종본)
- `plugins/hk/hooks/hooks.json` — planning-quick과 역할 분담하는 훅 3종
- `.claude/commands/vendor/add.md` — 벤더 추가 절차 (update·remove 동일 폴더)
- `VENDORED-SKILLS.md` — 벤더 출처 기록
- `CLAUDE.md` — repo 계약 (벤더 브릿지 섹션 추가됨)

## Suggested Skills / Commands

- `/hk:planning-quick` — 다음할일 1의 실전 검증 그 자체 (소비 프로젝트에서)
- `/vendor:add` — 스킬 추가 요청 오면
- `find-skills` — 새 스킬 탐색 (.claude/skills에 있음)

## 주의 사항

- **user 전역에 hk-skills 4개 켜져 있음** — 이 repo에서 스킬/커맨드 수정 시 **github 캐시 버전이 로컬 편집을 가릴 수 있음**. 수정→push→`claude plugin marketplace update hk-skills` 해야 이 머신에 반영. (다음할일 2로 정리 예정)
- **vendor는 `skills update` 미적용** — 갱신은 `/vendor:update`로 재수확.
- **stale 앵커** — HEAD(c33271e) 이후 커밋 많으면 이 handoff는 오래된 것.
