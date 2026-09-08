# MEMORY

> **다음 세션이 알아야 할 것만.** 코드·git·`CLAUDE.md`가 이미 갖는 내용은 여기 쓰지 않는다.
> 지나간 일의 경위·교훈은 [`docs/log/`](docs/log/) 조각으로(연대기). 이 파일은 **지금 참인 것**만 두고, 닫히면 지운다.
> 옛 `docs/tech-notes/NNN` 참조는 같은 이름의 조각에 있다(`docs/log/YYYY-MM-DD-<슬러그>.md`). 원본은 git 이력에서 — `git show 9bc1f93:docs/tech-notes/...`

## 미결 / 진행 중

- **vendor 아키텍처 선택 대기** — git-subdir+SHA 핀 전환(공식 방식·repo 경량화) vs 복사 유지+SHA 기록 보강(업스트림 소멸 보험 — `vercel-cli-with-tokens` 실사례). 권고는 후자. Hermes 폐기로 "로컬 실파일 필요" 근거가 사라져 열린 선택지.
- **CLAUDE.md·README의 Hermes 소비 경로 문단 정리** — Hermes 폐기(2026-08-19 결정) 후속. vendor 결정과 함께 반영할 것.
- **기존 규칙 고도화 — 착수 범위 미정** — 외부 스킬 도입은 보류하고 아이디어만 흡수하기로 함(흡수 매핑은 `2026-08-19-external-skills-deferred` 조각). 어디부터 손댈지는 사용자와 정한다.
- **교차 리뷰 수렴 규칙 채택 여부** — 제안: 라운드 상한 2회, HIGH는 의무 수정, MED 이하는 리드 재량(SCOPED). 근거는 `2026-08-24-git-sync-guard` 조각의 리뷰 4라운드 경험.
- **gamescom 파일럿 랜딩** — `~/orca/workspaces/web-ai-docent-gamescom/record-pilot`(미커밋 이관본) + `test-sandbox`(조각 375) 워크트리 보존 중. 행사 후 랜딩·정리 판단.
- **세션 메모리(PC 종속) 폐기** — user·feedback 항목은 아래 「사용자·작업 방식」으로 옮겼다. `~/.claude/projects/.../memory/` 잔여 파일 삭제는 사용자 확인 후.

## 사용자 · 작업 방식

- **쉬운 일상 한국어로.** 과설계·용어 남발 금지. 표·비유를 선호하고 장황한 설명을 싫어한다. 사실은 확인 후 단정한다(추측을 단정처럼 말하지 않는다).
- **질문·정정은 승인이 아니다.** 커밋·푸시·배포 같은 확정 행동은 **명시적 승인** 후에만. 질문에는 답만 하고, 구성이 바뀌면 바뀐 안을 다시 보여주고 승인받는다. (2026-08-19 실사고: 질문을 승인으로 오해해 커밋·푸시 → revert)
- **교차 리뷰는 Codex로.** 브리프 파일 작성 → orca 터미널에서 `codex exec "<브리프 경로> 읽고 수행"` → 결과 파일(VERDICT) 수확 → **리드가 실측 대조해 오탐을 거른 뒤** 수정. 리뷰어의 완벽 기준 ≠ 머지 기준.
- **기억은 전부 repo에.** PC 종속 세션 메모리(`~/.claude/.../memory/`)는 쓰지 않는다 — 여러 PC를 오가므로 git에 있어야 한다.

## 제약 · 함정

- **플러그인은 캐시본으로 실행된다** — `plugins/` 수정만으로는 반영 0. 반영 경로: 커밋 → 푸시 → `claude plugin update <번들>@hk-skills`(또는 `/plugin marketplace update hk-skills`) → **새 세션**. 훅·커맨드가 안 바뀐 것 같으면 이걸 먼저 의심한다.
- **실행 중인 세션은 구버전 훅을 물고 있다** — 훅을 고쳤으면 검증은 반드시 새 세션에서.

## 참조

- 벤더 스킬 출처·대조 이력 → [`VENDORED-SKILLS.md`](VENDORED-SKILLS.md) (전용 장부 — 여기 중복 기록 금지)
- orca-workers 실측 정본(스킬과 함께 배포됨) → `plugins/orca/skills/orca-workers/references/`
- 기록 컨벤션 규칙 정본 → hk 플러그인 `record` 스킬 (로컬 요약: [`docs/log/README.md`](docs/log/README.md))

## 인덱스

- 히스토리 → [`docs/log/`](docs/log/) — 파일명 정렬이 곧 연대기. 결정만 보려면 `grep -l "type: decision" docs/log/*.md`
