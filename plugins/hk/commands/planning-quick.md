---
description: 페이지/기능 단위 sub-plan을 4-phase(spec → design → build → summary)로 진입·진행. 매 phase에 프로젝트 SSOT를 강제 재로드해 컨벤션·컨텍스트를 복구한다.
argument-hint: "[NN-name] [spec|design|build|summary]"
---

# /hk:planning-quick

페이지/기능 하나(sub-plan)를 **4-phase SSOT** — `spec → design → build → summary` — 로 진행한다. 매 phase 진입 전 프로젝트 SSOT를 강제로 다시 읽어, 세션이 넘어가며 잃는 컨벤션·결정을 1턴에 복구한다.

## 전제 (프로젝트마다 다름 — 없으면 처음 발동 시 1회 확인)

1. **plan 루트** — sub-plan 폴더들의 부모 (예: `.plan/`, `.planning/`).
2. **대시보드** — 루트 안 `README.md` 등, 진행 상태표(⬜/◆/✅) 보유.
3. **정책 파일** — `CLAUDE.md`/`AGENTS.md` 등. 컴포넌트·구조 컨벤션의 SSOT.

## 인자 — `$ARGUMENTS`

| 인자 | 동작 |
|---|---|
| (없음) / `list` | 대시보드 + 다음 진입 후보 제안. 작업 시작 안 함. |
| `<NN-name>` | 그 sub-plan의 다음 ⬜ phase 자동 진입. |
| `<NN-name> <phase>` | 명시 phase 진입. 이미 sealed면 사용자 확인 후 갱신. |

## 매 phase 공통 — SSOT 재로드

phase 진입 직후 아래 중 **의무 행을 직접 읽고 인용**한다. design의 `.md` 코드 스니펫도 build에 그대로 반영되므로 "종이 결정이라 안 읽어도 됨"은 **틀림**.

| SSOT | 위치 (프로젝트별) | 의무 phase |
|---|---|---|
| 대시보드 | `<plan-root>/README.md` | 모든 |
| 정책 파일 | `CLAUDE.md`(+ apps `AGENTS.md`) | 모든 |
| 명세 원본 / 평가 보고서 | 정책·사용자 명시 위치 | spec |
| 공유 결정 파일 | `<plan-root>/shared/*` (mock-shape·라우팅·토큰) | spec·design |
| 디자인 mockup (있으면) | 정책·사용자 명시 위치 | **design** |
| 공식 docs (breaking change) | context7 / `node_modules/<pkg>` 번들 docs / `/llms.txt` | **design·build** |
| 기존 인프라 코드 | 관련 `src/lib`·프록시·클라이언트 등 실제 commit 코드 | design·build |

## 각 phase

- **spec** — 원본을 line/§ 그대로 인용. **사실 vs 결정 분리**: 원본 명시=사실 기재 / 원본 미정+권고=기본 채택(default) / 진짜 미정=`AskUserQuestion`(옵션 묶어 1회). 인접 의존(모달·별 페이지)은 인터페이스만, 본체는 별 sub-plan. 산출: Scope·출처·UI·상호작용·상태·URL↔화면·명시/기본채택/미정·수용기준. → `status: sealed`.
- **design** — spec sealed 후. 위 의무 SSOT(mockup·docs·인프라) 대조 후 산출: 컴포넌트 트리 / Props·시그니처 / Mock shape / 서버상태·라우팅 상태전이 / 디자인 토큰 / Edge case + 결정 로그 / Acceptance. **정책 파일의 컴포넌트·구조 컨벤션 100% 반영.** → `sealed` + frontmatter `source_mockup`·`audit_baseline`.
- **build** — design sealed 후. 코드 편집 직전 docs 재확인 + Edit 대상 Read. 단위 분리(컴포넌트→화면→page entry), 큰 단위마다 typecheck. **회귀 검증 typecheck/test/build + 시각 확인(dev 서버 + 브라우저)**. pre-commit hook 통과 필수(`--no-verify` 금지). `03-build.md`=작업 로그.
- **summary** — build 후 회고: spec/design 대비 어긋난 점 / 후속 follow-up / **공유 SSOT·정책·mockup 정정 사항**. 다음 sub-plan에 영향 있으면 그 spec 직접 편집.

## 마무리 (매 phase)

- 대시보드 row 갱신(draft=◆ / sealed·done=✅) + frontmatter `status` 동기.
- sealed 시 결정 로그에 `YYYY-MM-DD: <한 줄>` append.
- build 완료 시 커밋 분리 + 커밋 제안(사용자 결재). 4-phase ✅ 시 다음 sub-plan 후보 제시.

## 즉시 중단 (안티패턴)

| ❌ | 이유 |
|---|---|
| 원본 SSOT 안 읽고 spec | 환각. |
| 명시 사항을 `AskUserQuestion`으로 물음 | 사용자 시간 낭비. |
| spec 미sealed인데 design | 결정 안 된 것 위에 쌓임. |
| docs·mockup 미참조하고 design/build | breaking change·토큰 불일치 → 재작성. |
| build `--no-verify` | pre-commit 우회. |
| 대시보드 갱신 누락 | 다음 세션이 상태 못 봄. |
| 부속 전부 한 sub-plan에 욱여넣음 | 1페이지=1 sub-plan 위반 → 분리. |
| 정책 파일 무시 | 본 커맨드는 절차만 강제, 구체 규약은 정책이 SSOT. |
