---
name: orca-workers
description: "Use when coordinating parallel Orca sub-worktree workers for one feature/page cycle: provision worktrees, brief, supervised dispatch (task-create + dispatch --inject), cross-model review (Claude↔Codex either direction, or Claude-only cross-session), fix loop, and integration landing (commit → verify → Playwright → push → cleanup). Command mechanics delegate to the orca-cli & orchestration skills. Triggers: Orca orchestration, parallel worktree workers, supervised dispatch, worker_done, cross-model review."
version: 0.2.2
author: hk
license: MIT
platforms: [macos, linux]
metadata:
  hermes:
    tags: [orca, orchestration, worktrees, supervised-workers, codex, cross-model-review, claude-code]
    related_skills: [orca-cli, orchestration]
---

# Orca 서브워크트리 병렬 오케스트레이션

한 작업을 **여러 Orca 서브워크트리 워커에 병렬 분담**하고, 리드(이 세션)가 **supervised로** 브리프·디스패치·교차리뷰·수정·통합을 조율할 때 쓴다. 명령·플래그 정본은 **Orca가 제공하는** 아래 두 스킬이고, 이 파일은 **우리 워크플로 + 실전 함정**만 담는다.

## 먼저 로드 (필수 · 스킵 금지)

디스패치 전에 **둘 다** 이름으로 로드한다. 기억/습관으로 실행하지 마라 — 그게 매 사고의 원인이었다. 이 둘은 **이 번들이 vendor하는 게 아니라 Orca가 제공하는 스킬**이다 — Orca 앱이 사용자 레벨에 깔아두므로, Orca 환경 세션이면 스킬 인벤토리에 **이미 떠 있다**. **경로를 하드코딩하지 말고 인벤토리에서 이름으로 로드**하라(설치 위치는 머신·버전마다 다름). 인벤토리에 이 둘이 없으면 Orca-프로비저닝 환경이 아니라는 신호 → 이 레시피를 진행하지 마라.

- **`orca-cli`**(Orca 제공) — worktree / terminal / read / send.
- **`orchestration`**(Orca 제공) — `task-create` → `dispatch --inject` → `worker_done`.

> ⚠️ **오버라이드 (이 레시피가 orchestration 스킬을 이깁니다).** `orchestration` 스킬은 `check --wait`(롤링 대기)를 여러 곳에서 권장한다(supervision 지침·예시 명령 등). **이 환경에선 전부 무시한다** — `worker_done`·백그라운드 완료가 **자동 알림**으로 오므로 대기 명령 자체가 불필요·유해. **`orca orchestration check --wait`를 어떤 timeout으로도 실행하지 마라.** 그 스킬의 명령 문법(task-create/dispatch/reply)만 빌리고, `--wait`는 버린다.

## 핵심 원칙

- **supervised 고정 (full handoff 아님).** 워커는 항상 `task-create` + `dispatch --inject`로 띄운다(provenance) — **완료·검증 authority는 리드가 소유**(ownership 이전 아님). Workflow(이 하니스의 병렬 subagent 오케스트레이션 도구)/subagent로 워커 완료를 대체하지 마라. Workflow는 큰 표면의 P1 스카우트·P6 준비도 분석(read-only)에만.
- **분해·토폴로지는 리드의 선택 — N-way 병렬이 기본 아님.** 팬아웃 전 **의존 방향**을 보고 *최고 결과*가 나오는 구조를 고른다(병렬 최대화가 목표 아님): ① 파일 disjoint + 계약 독립 → **병렬**. ② **강한 단방향 의존**(db 도메인·repo·계약 → 기능 → ui) → **웨이브**: wave1 db/계약 확정(별 워크트리) → wave2 기능·ui·통합 병렬(각자 워크트리). 웨이브 안 나누면 다운스트림이 계약을 *가정*만 하다 합류 때 **DTO 드리프트**를 리드가 수습. ③ 소규모(스칼라 CRUD 몇 화면) → **순차 1명**이 더 빠르고 안전. **병렬 이득 > 정합 리스크일 때만 팬아웃.**
- **모델 역할 배정 = 사용자 지정 (없으면 기본 A) · 교차는 불변.** 누가 구현하고 누가 리뷰할지는 **사용자가 정한다** — 안 정했으면 **기본 A**. **불변식: 저자 ≠ 리뷰어** — 모델이 다르거나(교차모델), 최소한 별 세션·별 컨텍스트(교차세션)여야 교차가 의미. 세 모드:
  - **A. Claude 구현 → Codex 리뷰** (기본): Claude Opus 워커 → Codex 리뷰어.
  - **B. Codex 구현 → Claude 리뷰** (역방향): Codex 워커는 반드시 `network_access=true`로 기동(P3·함정) → 신규 Claude 세션이 리뷰.
  - **C. Claude 전용** (Codex 미사용/불가): 구현·리뷰 모두 Claude지만 **반드시 별 세션·별 컨텍스트**(교차모델은 포기, 교차세션=독립 관점은 유지). 교차모델보다 약하니 가능하면 A/B 우선.
  에포트는 어느 모드든 고정: 워커·리드 = **max**, Codex = **`model_reasoning_effort=xhigh`**.
  **모드 선택 = 가용성 먼저, 그다음 사용자 지정.** 팬아웃 전 Codex 설치·가용 여부를 확인한다(`command -v codex`, 또는 orca가 `--agent codex`를 받는지). **Codex 없으면 무조건 C**(Claude 전용·교차세션 — 사용자가 B를 원해도 Codex가 없으면 C). Codex 있으면 **사용자가 정한 대로**: "Codex가 짜"→B, "Claude가 짜"→A. **사용자가 안 정했으면 기본 A**(Claude 구현→Codex 리뷰). **리드가 임의로 구현 모델을 B로 바꾸지 마라** — 누가 짤지는 사용자 결정.
- **블로킹 대기 절대 금지 (알림 자동).** `worker_done`·백그라운드 태스크 완료는 **자동 알림**으로 온다 → dispatch·백그라운드 실행 후엔 **알림에 반응만** 해라. **`orca orchestration check --wait`는 실행하지 마라** — 어떤 `--wait`/sleep/파일 폴링 루프도 금지(orchestration 스킬이 권장해도 **오버라이드**; 위 ⚠️). 인박스 확인이 필요하면 `check`(non-`--wait`)로 드레인만.
- **리드 재검증.** `worker_done` "PASS"는 환경차로 가짜일 수 있다 → 리드가 diff + typecheck/lint/test/build를 재대조(백그라운드 태스크로 돌리고 완료 알림에 반응). Codex `verdict`·findings도 리드가 실파일로 실측 대조(오탐 거름).
- **커밋/푸시/배포·운영 DB·infra = 승인 없이 금지**(프로젝트 `CLAUDE.md` 가드레일).

## 워크플로

**P0 프로비저닝** — 결정한 토폴로지대로 **워커당 워크트리 1개** 만든다: `worktree ps` 감지, 없으면 `worktree create --parent-worktree active --name <역할> --setup skip`. 역할을 이름에 드러낸다(…-ui/…-data 또는 기능별). **한 워크트리에 워커 여럿 절대 금지** — 작업트리·git 인덱스·dev 서버를 공유해 파일이 반쯤 쓰인 채 얽힌다(`pnpm install` 몇 번 아끼려다 오염). **fresh 워크트리는 deps 없음** → 리드가 `pnpm install`(postinstall이 ORM codegen 자동) + 베이스라인(typecheck/test)까지 확인한 뒤 투입.

**P1 파악** — 리드가 실파일로 계약/표면/스코프를 확정(브리프 정확도). 표면이 크면 Workflow read-only 스카우트 후 리드가 재대조. (자주: 데이터/서버 계층이 이미 있어 스코프가 UI-only로 줄기도 함 — 실제로 열어 확인.)

**P2 브리프** — 워커별 `.hk/handoff/<task>.md` **파일**(터미널 장문 붙여넣기 금지 — 이스케이프·잘림). 필수: 역할("너는 X만") · 구현 전 로드 목록 · 스코프 IN/**OUT** · DS 규약(프리미티브 조립·재구현 금지) · 앱 규약(문자열 언어·클라 DB직접 금지·a11y) · 검증 명령 + **커밋 금지** · **`worker_done` 보고 문구 = "worker_done 전송, 실패 시 1회 재시도, 그래도 실패면 생략 — 성공 여부와 무관하게 최종 텍스트로 완료 보고 출력 후 턴 종료"**(이중 보고; "정확히 한 번만 보내라"로 쓰면 전송 실패 시 재시도 없이 포기하는 사고). **파일 disjoint로 스코프를 갈라** 워커끼리 안 겹치게. 공유 계약(DTO)이 있으면 양쪽 브리프에 **동일 shape** 명시.

**P3 디스패치** — `read` + `terminal wait --for tui-idle`로 **idle 확정**(satisfied:true + blockedReason 없음) → `task-create` → `dispatch --inject` → **자동 알림에 반응**(블로킹 대기 없음). **codex 워커(구현·supervised, 모드 B)는 반드시 `-c sandbox_workspace_write.network_access=true`로 기동** — 없으면 기본 workspace-write 샌드박스가 orchestration RPC 채널을 막아(`orca status`만 되고 `orca orchestration *`는 `runtime_unavailable`) `worker_done`·`ask` 불가. **`dispatch --inject`도 첫 프롬프트를 삼킨다** — TUI에 다이얼로그(아래 함정)가 떠 있으면 inject가 유실되므로 위 tui-idle 확정 후 inject. 워커가 보고 없이 종료(터미널 exit)하면 리드가 즉시 산출물 직접 수확·검증(코드는 됐는데 self-verify/보고만 못 한 경우 흔함).

**P4 교차리뷰(교차모델·별세션)** — 저자 ≠ 리뷰어(**모델·세션 둘 다**). **리뷰어 모델 = 고른 모드**(A→Codex, B/C→신규 Claude 세션; B는 교차모델, C는 교차세션만). 아래 `codex exec` 정석은 **리뷰어=Codex**용 — **리뷰어=Claude면** 저자 워크트리에 **신규 claude 터미널 + 동일 브리프 파일**로 같은 산출(`.hk/review/<task>-*.md`)을 낸다. 리뷰는 **저자 워크트리의 위임 세션**이 한다 — **리드 셸에서 `codex exec` 직접 금지**(인라인의 실수), **interactive `codex`+`send`도 지양**(MCP 스타트업이 첫 프롬프트를 삼킴). 정석 = **orca 터미널에서 `codex exec`**(프롬프트를 arg로): `orca terminal create --worktree <저자 wt> --command 'codex exec … "브리프 .hk/review/<task>-brief.md 읽고 .hk/review/<task>-codex.md에 정적 리뷰만 써라"'` — arg 전달이라 첫-프롬프트-유실 회피 + 위임 세션 유지 + 끝나면 exit(완료 신호). 미커밋 diff를 봐야 하니 **저자 워크트리 in-place**(새 워크트리엔 미커밋 안 보임) — 리뷰어는 **읽기전용**(소스·빌드·테스트·설치·네트워크 금지)이라 'P0 워크트리당 워커 1개'의 **유일한 예외**(변경 안 하니 안 얽힘). 브리프 = 대상 `git diff` + 신규파일 목록 · 합격기준 · **"정적 리뷰만"** · 산출 `.hk/review/<task>-codex.md`(blocker/major/minor/nit + `file:line` + 끝줄 `SUMMARY … verdict CLEAN|NEEDS_FIX`). **리드가 파일로 수확**(리뷰어는 read-only라 `network_access` 플래그 없이 기동 → `orca` orchestration RPC 차단; 그래서 파일 수확이 정석). Codex 불가 시 **신규 Claude 세션**으로 동일하게.

**P5 수정 루프** — findings를 리드가 실측 대조 → 확정분 `.hk/fix/<task>-fixes.md` → **같은 워커 재engage(재투입)** → 리드 재검증. `verdict CLEAN`까지. 수정이 **리뷰어 제안 remedy 그대로인 trivial 건**은 리드 실측 확인으로 갈음(리뷰어 재핑 생략) — 단 **정직 고지**.

**P6 통합 랜딩(승인 게이트)** —
1. 각 브랜치 커밋(**승인**): `git add apps/…`로 의도 파일만(`.hk/`·`pnpm-workspace.yaml` 제외). 메시지는 **`-F <msgfile>` 파일로**(멀티라인·이스케이프 안정 — send 경로에선 stdin `-F -` 파이핑이 번거로움).
2. 통합 워크트리(`worktree create --base-branch <default> --setup skip`) → 각 브랜치 `merge --no-ff`(파일 disjoint면 충돌 0) → `pnpm install` + **전체검증**(typecheck/lint/test/build).
3. **Playwright 시각검증**: 통합 워크트리에 `.env` 복사 → dev 서버 → 로그인→해당 화면 실제 클릭.
4. 랜딩(**승인**): main 병합(disjoint면 ff) → `push` → `orca worktree rm --force`로 워크트리+워커/리뷰어 터미널 정리.
5. **정직한 검증 상태**: 코드/타입/테스트/빌드 GREEN ≠ 눌러봄. 어디까지 실제로 클릭했는지 명시(데이터 없는 빈 상태만 봤으면 그렇게).

## 실전 함정 (스킬·문서에 없는 것)

- **`export PNPM_CONFIG_VERIFY_DEPS_BEFORE_RUN=false`** — pnpm11이 `install`·`git commit`(pre-commit)·**`pnpm dev` 실행 전 verify-deps 게이트**에서 ignored-builds(esbuild/sharp/unrs)로 **exit 1**. 대문자 ENV만 유효(소문자 no-op), `pnpm --filter … --config` 플래그는 하위 스크립트로 먹혀 무효 → 반드시 ENV.
- **`pnpm install`이 `pnpm-workspace.yaml` 오염**(pnpm11 placeholder 주입) → 커밋 전 `git checkout -- pnpm-workspace.yaml`.
- **env 위치**: Next admin은 **`apps/admin/.env`**에서 읽는다(모노레포 루트 아님 — 루트에 두면 앱이 못 봄). 통합 워크트리 Playwright엔 `.env` 복사. 최소 키 `DATABASE_URL`·`RECALL_SESSION_SECRET`(없으면 login·/api/me **503**)·`NEXT_PUBLIC_API_BASE_URL`(없으면 클라가 운영 도메인 호출 → 로컬 `ERR_NAME_NOT_RESOLVED`).
- **Codex 리뷰어**: **orca 터미널에서 `codex exec`**(프롬프트를 arg로) — `--command 'codex exec --dangerously-bypass-approvals-and-sandbox --model gpt-5.5 -c model_reasoning_effort="xhigh" "<브리프 읽고 리뷰 파일 써라>"'`. **리드 셸에서 직접 `codex exec` 금지**(위임 아님). interactive `codex`+`send`로 가면 **MCP 스타트업이 첫 프롬프트를 삼킨다**(composer placeholder=미입력) → `read`로 착수 확인 후 **재전송**. **MCP transport 에러(github/supabase OAuth 실패)는 무해한 노이즈** — Codex 자체는 정상, 리뷰엔 MCP 불필요. 산출은 파일. **Codex 불가 시 신규 Claude 세션** 동일.
- **TUI 다이얼로그가 첫 프롬프트를 삼킴 (`send`·`dispatch --inject` 공통)** — 전송 전 `terminal wait --for tui-idle`로 **satisfied:true + blockedReason 없음** 확인. 신종 blockedReason 2건: ① **`codex-update-prompt`**(버전 업데이트 다이얼로그) → `"2"`(Skip) 전송으로 해소. ② **codex 0.145+ 훅 승인 다이얼로그**(바로 아래).
- **codex 0.145+ "N hooks need review" 다이얼로그가 기동을 막음** — Orca가 깔아둔 agent-hooks 중 신규 훅이 있으면 뜬다. `"t"`(trust all) 일괄 승인하면 **타 에이전트용 훅(claude-hook 등)까지 켜져** 도구 호출마다 `PostToolUse hook (failed) exit 127` 스팸(작업엔 무해, 로그 오염) → **필요한 훅만 승인**. (MCP transport 에러와 같은 무해 노이즈 부류.)
- **프롬프트 유실 후 재주입** — task가 `dispatched`면 `dispatch --inject` 재실행 불가(`already has an active dispatch`), `task-update --status ready`로도 안 풀림(pane에 active dispatch 잔존). 복구 = 기존 **taskId/dispatchId를 명시한 preamble**을 `terminal send`로 수동 재전송(pane의 dispatch 컨텍스트는 유효 → `worker_done` 인정), task 상태는 `task-update`로 `dispatched` 복귀.
- **`orca terminal wait --for exit` 불신뢰 (codex exec 터미널)** — ① `terminal_handle_stale`로 즉사 ② 이미 exit(셸 프롬프트 복귀)했는데 안 풀리고 무기한 대기. **exec 워커 완료 감지를 `wait --for exit`에 의존 마라** — `worker_done` 경로가 정답(위 `network_access` 플래그 전제).
- **터미널 title 매칭 금지** — Orca가 탭 제목을 세션 내용 기반으로 자동 변경(예: `codex-p5b` → `⠸ survey`). 식별은 **handle로만**; title 기반 grep/필터는 오탐("terminal gone" 오판 사고).
- **`send` 전 `read`** — 워커 thinking 중 입력이 꼬인다.
- **`orca worktree rm`은 브랜치도 함께 제거** — 이후 `git branch -D`는 "not found".
