# Session Handoff

> 다음 세션 시작 시 `/hk:pre-clear:resume` 호출.
> 저장: 2026-09-08T05:23:31Z · HEAD: 6b6a9cc · 브랜치: main

## 세션 목표

기록 컨벤션 v2 플러그인화의 마무리 — hk 0.18.0 배포(구조 개선 + git 동기화 가드)와, 이 repo 자체를 v2로 이관하는 도그푸딩(Phase B).

## 완료한 작업

- **hk 0.18.0 커밋·푸시·배포** (`9bc1f93`) — 이 PC 캐시도 0.18.0 갱신 완료
  - `/hk:record:init`·`migrate` → **`/hk:record:setup` 하나로 통합** (`plugins/hk/commands/record/setup.md`). 보충 모드(`docs/log` 있으면 비파괴·조각 재처리 금지·잔여는 보고만) / 적용 모드 2분기
  - **v1/v2 라벨 폐지** — 판정은 `docs/log` 유무 하나(`active`/`legacy`). 기존 기준은 "내 옛 형태와 닮았나"라서 `NOTES.md`만 있는 프로젝트를 신규로 오판했음
  - MEMORY 템플릿을 내장 메모리 명세대로 5섹션화, DECISIONS 필수→선택
  - **git 동기화 가드 신규** (`plugins/hk/hooks/git-sync-guard.sh`, 98줄) — push는 차단·commit은 알림만, 전부 fail-open. 테스트 11케이스는 `scripts/tests/git-sync-guard.test.sh`(배포 제외)
- **이 repo v2 이관 완료·푸시** (`6b6a9cc`) — `/hk:record:setup` 적용 모드 첫 실전 실행
  - `docs/tech-notes/001~009` → `docs/log/YYYY-MM-DD-<슬러그>.md` 9개 (git이 rename 94~95%로 인식 → `git log --follow` 추적 가능)
  - `docs/DECISIONS.md` 8건 → `type: decision` 조각 7개 (08-18 벤더 2건은 묶음). DECISIONS.md 폐지 — 이 repo는 D번호 미사용
  - `MEMORY.md` 재작성 5섹션(3.8KB) — PC 종속 세션 메모리에 있던 작업 방식·제약을 repo로 이관
  - `CLAUDE.md`에 기록 컨벤션 문단 추가
  - **검증 33/33**: git 원본과 조각 본문 바이트 대조 일치 · DECISIONS 8건 전수 · frontmatter 16개 유효

## 진행 중 작업

없음 — 두 커밋 모두 푸시 완료, 작업 트리 클린. 다음은 MEMORY.md 「미결」 항목에서 고르면 된다.

## 다음에 할 일

1. **PC 종속 세션 메모리 폐기 확인** — `~/.claude/projects/-Users-ravi-Desktop-DEV-My-hk-skills/memory/` 의 user·feedback 항목은 repo MEMORY.md로 옮겼다. 잔여 파일 삭제 여부 + 다른 프로젝트 전역 항목(포트폴리오 표기)을 어떻게 할지 사용자 확인 필요
2. **vendor 아키텍처 선택** — git-subdir+SHA 핀 전환 vs 복사 유지+SHA 기록 보강(권고). Hermes 폐기로 "로컬 실파일 필요" 근거가 사라져 열린 선택지
3. **CLAUDE.md·README의 Hermes 소비 경로 문단 정리** — 2번과 함께 반영. 추가로 CLAUDE.md의 "프로젝트 settings.json에 extraKnownMarketplaces 등록" 서술도 실제(user 스코프 CLI 설치)와 다르므로 같이 정정 대상
4. **교차 리뷰 수렴 규칙 채택 여부** — 제안: 라운드 상한 2회, HIGH 의무 수정, MED 이하 리드 재량(SCOPED)
5. **기존 규칙 고도화 착수 범위** — 외부 스킬은 도입 보류하고 아이디어만 흡수하기로 함(매핑은 `docs/log/2026-08-19-external-skills-deferred.md`)

## 결정된 사항

- **기록 컨벤션 v2 채택** — 조각 로그(`docs/log`) + MEMORY 5섹션. DECISIONS는 선택(D번호 쓰는 프로젝트만). 규칙 정본은 hk `record` 스킬. 재논의 금지
- **이관은 전면 이관 하나** — 경량/부분 이관 개념 폐기. 시작 상태는 `docs/log` 유무로만 판정
- **git 가드는 push만 차단, commit은 알림** — 뒤처진 커밋은 git에서 정상이고, 커밋을 막으면 더러운 작업 트리에서 통합을 강요해 세이브포인트가 없어짐
- **가드는 자물쇠가 아니라 안전벨트** — 우회 방지보다 가독성 우선(204줄 → 98줄로 되돌림)
- **테스트는 배포물이 아님** — `scripts/tests/`에 두고 플러그인에 포함하지 않음
- **커밋·푸시는 매번 명시 승인** — 질문·정정은 승인이 아님

## 작업 메모리 (워크플로우·역할·임시 컨텍스트)

- **이 세션은 hk 0.18.0 훅으로 돌고 있다** — 새 Stop 기록 게이트(`active`/`legacy` 분기)와 PreToolUse git 가드가 실제로 활성. 이 repo는 이제 `active`(docs/log 존재)라 게이트가 조각 작성을 요구한다
- **교차 리뷰 = Codex** — 브리프 파일 작성 → `orca terminal create --command "codex exec \"<브리프 경로> 읽고 수행\""` → 결과 파일(VERDICT) 수확 → 리드가 실측 대조. 이번 세션에서 리뷰어 터미널은 전부 정리했다
- **gamescom 워크트리 2개 보존 중** — `~/orca/workspaces/web-ai-docent-gamescom/record-pilot`(미커밋 이관본, 조각 39) · `test-sandbox`(조각 375). 행사 후 랜딩·정리 판단 대상이라 지우지 말 것
- 이미 v2로 넘어간 프로젝트(다른 세션에서 이관됨): sdk(조각 25)·weblanding(7)은 깔끔, **gamescom develop(조각 66)은 혼재** — tech-notes 314개·memory/·archive/ 잔존, MEMORY 36KB. setup 보충 모드로 감지·보고만 되고 자동 처리는 안 된다

## 미해결 질문

- 세션 메모리 잔여 파일 삭제 여부 — 사용자 결재 대기 (위 「다음에 할 일」 1번)
- vendor 아키텍처 선택 — 사용자 결재 대기
- 교차 리뷰 수렴 규칙 채택 여부 — 사용자 결재 대기

## 참조 파일 (다음 작업 1순위에 즉시 필요한 것만)

- `MEMORY.md` — 미결 6건이 현재 상태의 진입점
- `docs/log/README.md` — 조각 규칙 로컬 요약 (정본은 hk `record` 스킬)
- `~/.claude/projects/-Users-ravi-Desktop-DEV-My-hk-skills/memory/MEMORY.md` — 폐기 대상 세션 메모리 인덱스

## Suggested Skills / Commands

- `hk:record` 스킬 — 조각 작성·MEMORY 갱신 규칙 정본
- `/hk:record:setup` — 다른 프로젝트에 적용하거나 혼재 상태(gamescom) 점검할 때. 재실행 안전

## 주의 사항

- **플러그인은 캐시본으로 실행** — 다른 PC에서 이어가려면 `git pull` 후 `claude plugin update hk@hk-skills` → **새 세션**. 안 하면 구버전 커맨드(`/hk:record:init` 등)가 뜬다
- **`/hk:record:setup`은 이 repo에선 이제 보충 모드로 진입** — 이미 이관됐으므로 조각을 재처리하지 않는다(정상)
- 옛 tech-note 참조는 같은 이름의 조각에 있고, 원본은 `git show 9bc1f93:docs/tech-notes/...`
