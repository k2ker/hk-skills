---
description: Orca 서브워크트리 병렬 워커로 한 작업을 프로비저닝→수집→브리프→디스패치→교차리뷰→수정루프→통합랜딩까지 오케스트레이션하는 얇은 레시피. 명령 메커닉은 orca-cli·orchestration 스킬에 위임.
argument-hint: "[이번 사이클 타깃, 예: '홈 화면']"
---

# /hk:orca:orchestrate

한 작업(페이지/기능)을 **여러 Orca 서브워크트리 워커에 병렬 분담**시키고, 컨텍스트·브리프·계약·공유상태·교차리뷰·통합을 리드(이 세션)가 조율한다. **얇은 레시피**다 — 명령·플래그 정본은 아래 두 스킬이 갖고, 이 파일은 **순서 · 결정 · 프로젝트-무관 함정**만 담는다. 워커는 각 워크트리의 Claude(구현)·Codex(리뷰) 세션.

## 먼저 로드 (메커닉은 여기 위임)

- **`orca-cli`** — worktree / terminal / wait / read / send + 보드(`worktree set --workspace-status`). **전달 계층 정본.**
- **Orca `orchestration`** — 감독형 추적: `task-create` → `dispatch --inject` → `check --wait` → `worker_done`. 완료를 **이벤트로** 받고 싶을 때.
- **Workflow 툴** — Phase 1 병렬 스카우트 + Phase 6 통합 준비도 분석(read-only fan-out).
- **워커용(브리프에 "구현 전 로드"로 명세):** 프로젝트 스택 스킬(프레임워크/모노레포 워크플로 · DS/Storybook · ORM/스키마 · 테스트/품질게이트) + 프로젝트 `CLAUDE.md` · 메모리 · 결정로그. ← **프로젝트마다 치환.**

## 디스패치 2모드

| 모드 | 언제 | 완료 판정 |
|---|---|---|
| **full handoff** (`terminal send`) | 최초 오픈엔드 작업, fire-and-forget | 수동(read tail · 보드) |
| **supervised** (`orchestration`) | 완료를 **자동 트래킹** 원할 때(수정 재투입 · 배선 등) | **`worker_done` 이벤트** |

`orca-cli`는 full handoff엔 orchestration을 권하지 않지만, "다 했어?"를 폴링 않고 이벤트로 받으려면 supervised가 맞다. 명령은 `orchestration` 스킬 참조. ⚠️ 플래그 주의: dispatch=`--task`, task-update=`--id`(반대). 하트비트=alive(**답장 불필요**), 완료=`worker_done`.

**⚠️ 모드 선택 강제:** 리드가 "완료되면 자동 진행"(이벤트 기반 완료)을 약속했으면 = **supervised 필수**, `orchestration` 스킬 반드시 로드. full handoff + 자체 파일/문자열 sentinel 폴링으로 대체 금지 — 협조적 sentinel은 워커가 안 남기면 조용히 정지한다(아래 liveness 함정).

## 레시피

**P0 프로비저닝** — `worktree ps`로 감지, 없으면 리드가 `worktree create --parent-worktree active`(하위로 묶임; `--no-parent`는 독립). 역할은 `--name …-ui`/`…-data`로 드러내기.

**P1 컨텍스트 수집** — Workflow로 **병렬 read-only 스카우트**(현재 표면 / 레퍼런스 UX / DS·컴포넌트 인벤토리 / 도메인·DB 델타). ⚠️ 스카우트는 서로 blind → 추정이 엇갈릴 수 있으니 **리드가 실파일로 재대조·판정**.

**P2 브리프** — 워커별 `.hk/handoff/<task>.md` **파일**(터미널 장문 send 금지 — 이스케이프·잘림). 필수 섹션: 역할분담(너는 X만) · 구현 전 로드 · 스코프 IN/**OUT** · 레퍼런스(UX만) · DS 규약(기존 프리미티브 조립·재구현 금지) · **DTO 계약(양쪽 브리프에 동일 shape)** · 앱 규약(노출문자열 언어·브라우저 DB직접 금지·접근성) · 검증 + **커밋 금지** · 완료보고 방식(모드별).

**P3 디스패치** — `read`로 idle 확인 후 위 2모드 중 선택.

**P4 조율** — 공유 상태를 리드가 순수 git으로 정렬. 미커밋 공유 변경(DS 등)은 base에서 커밋(**승인**) 후 각 워커 브랜치에 `git -C <wt> merge`(ff). DTO 드리프트는 임의변경 금지 → 보고 → 양쪽 브리프 동시 갱신.

**P4.5 교차리뷰(cross-model)** — 저자 ≠ 리뷰어 모델(Claude 저작 → Codex). 산출물이 **미커밋이면 같은 워크트리 in-place**에 리뷰어 스폰(새 워크트리는 미커밋이 안 보임). 리뷰 브리프 = 대상 `git diff` · 합격기준 handoff · **"정적 리뷰만(빌드/테스트/설치/네트워크/외부CLI 금지)"** · 산출 `.hk/review/<task>-<reviewer>.md`(심각도 blocker/major/minor/nit + `file:line` + 끝줄 `SUMMARY … verdict CLEAN|NEEDS_FIX`). **리드가 파일로 수확**(리뷰어는 `orca` 못 부름). Codex 셋업은 아래 함정.

**P5 수정 루프(CLEAN까지)** — findings를 리드가 실측 대조 → 확정분 `.hk/fix/<task>-fixes.md` → **supervised로 원 워커 재투입**(worker_done 추적) → 재리뷰(소규모·완전명세면 **기존 리뷰어 컨텍스트 재활용** = follow-up send). worker_done "PASS" 보고는 **리드가 diff·검증 재대조**(환경차로 가짜 PASS/FAIL 가능). 양쪽 `verdict CLEAN`까지 반복.

**P6 통합 랜딩(승인 게이트)** —
1. **준비도 분석(Workflow):** 계약 일치(UI mock ↔ DTO) · 머지 충돌 · 배선 범위 · 서버/클라 fetch 가능성.
2. **각 브랜치 커밋(승인):** `.hk/`·로컬 store 제외 **명시적 `git add`**. 문서 번호 충돌 시 리넘버.
3. **통합 워크트리:** `worktree create --base-branch <default-branch> --setup skip` → `git -C <wt> merge --no-ff <branch> -F <msgfile>`(경로 disjoint면 충돌 0) → 리드가 deps install + ORM codegen + 베이스라인 검증.
4. **배선:** supervised 워커 → Codex 리뷰 → **리드 최종 전체검증**.
5. **랜딩(승인):** `git merge --no-ff <intBranch>` → `<default-branch>` → `push` → `orca worktree rm --force`로 정리.
6. **정직한 검증 상태:** 코드·타입·테스트·빌드·정적리뷰까지 GREEN이어도 **실제 클릭 확인(로그인/DB)은 별도** — 어디까지 눌러봤는지 명시.

## 프로젝트-무관 함정 (스킬에 없는 것)

- **워커 완료 감지 = liveness 필수(협조적 sentinel 단독 금지):** full handoff의 파일/문자열 sentinel도, supervised의 `worker_done`도, 워커가 **보고 없이 종료**(claude/codex 프로세스 exit → 터미널이 셸 프롬프트 `❯`로 복귀)하면 똑같이 타임아웃까지 조용히 걸린다. 리드 대기 루프는 **(sentinel/worker_done) OR (터미널 exit 감지)** 를 종료조건으로 걸고, exit 감지 시 sentinel 유무와 무관하게 **즉시 리드가 산출물을 직접 수확 + 검증**(코드는 끝났는데 self-verify·보고만 못 남긴 경우가 흔함). exit 판정 = `orca terminal read`의 status/tail(셸 프롬프트). ❌ 다중 sentinel AND 조건 + 무한/장기 타임아웃 단독 폴링 = 1워커 미보고 시 전체 정지.
- **Codex 리뷰어:** 기본 on-request 승인 + 샌드박스 → pnpm/네트워크에서 멈추고 `orca`도 `runtime_unavailable`. **해법 = `codex --dangerously-bypass-approvals-and-sandbox -c model_reasoning_effort="xhigh"` + "정적 리뷰만" 브리프 + 결과는 파일.** 온보딩: 디렉터리 신뢰=Enter, 업데이트 알림 기본 "Update now"(설치!) → "2" Skip.
- **pnpm ignored-builds(esbuild 등)** 가 검증·`git commit`(husky pre-commit) 막음 → **ENV 형식 `PNPM_CONFIG_VERIFY_DEPS_BEFORE_RUN=false`** 를 export 후 실행·커밋(⚠️ 대문자 env만 유효 — 소문자 `npm_config_…`는 no-op). ⚠️ `pnpm --filter <pkg> <script> --config.verify-deps-before-run=false` 처럼 **CLI 플래그를 필터 실행 뒤에 붙이면 하위 스크립트 인자로 먹혀 무효** — 반드시 ENV 형식으로. 훅 통째 스킵(`--no-verify`)보다 정직.
- **fresh 워크트리**(`--setup skip`): deps 없음 → 리드가 `pnpm install` + ORM codegen(예: `pnpm --filter <db-pkg> <generate-script>`, 더미 `DATABASE_URL`로 오프라인) + 베이스라인 검증 후 워커 투입.
- **`git merge` 메시지 stdin(`-F -`) 불가** ("could not read file '-'") → `-F <file>` 또는 `-m`.
- **보드는 수동:** orchestration task 상태 ≠ 보드(`workspaceStatus`). dispatch/worker_done이 보드를 옮겨준다고 **의존하지 말 것** — 리드가 `worktree set --workspace-status`로 직접(in-progress / in-review / completed).
- **`orca worktree rm`:** 워크트리 + 연결 브랜치를 함께 제거(이후 `git branch -D`는 "not found").

## 가드레일 (프로젝트 `CLAUDE.md` 승인 게이트)

- commit / push / deploy · 운영 DB 변경 · infra 변경 = 승인 없이 금지.
- 잘못된 워크트리에서 공유 상태(DS·tokens·계약) 수정 금지 — 리드가 base에서 정렬 후 머지.
- 브리프에 비밀번호/토큰 평문 금지(env · 경로 참조).
- 커밋 시 `.hk/` 스크래치·로컬 store 섞지 말 것(명시적 add).

## 안티패턴

| ❌ | 이유 |
|---|---|
| 수집 없이 바로 디스패치 | 워커가 레거시/DB/DS 오판하며 헛돎 |
| 브리프를 터미널에 장문 붙여넣기 | 이스케이프·잘림 → 파일로 |
| 미커밋 공유 DS 방치하고 착수 | stale 위 작업 → 병합 충돌·재작업 |
| 양쪽 DTO shape 불일치 | 합류 시 배선 실패 |
| `send` 전 `read` 생략 | 워커 thinking 중이면 입력 꼬임 |
| 하트비트에 답장 | alive 신호. `worker_done`만 완료 |
| worker_done "PASS" 그대로 신뢰 | 환경차로 가짜 결과 → 리드 재대조 |
| 완료를 코드 유무로 판정 | 검증 상태(눌러봤는지)로 |
| 보드 자동이동 기대 | 수동 — 리드가 상태 올림 |
