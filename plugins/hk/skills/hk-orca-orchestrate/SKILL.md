---
name: hk-orca-orchestrate
description: "Use when coordinating parallel Orca sub-worktree workers for one feature/page cycle from provisioning through scouting, briefing, supervised dispatch, cross-model review, fix loop, and integration landing."
version: 0.1.0
author: hk
license: MIT
metadata:
  hermes:
    tags: [hk, orca, orchestration, worktrees, claude-code, codex, supervised-workers]
    related_skills: [claude-code-development-workflow, claude-tmux-worker, codex]
---

# HK Orca Orchestrate

이 Hermes skill은 Claude Code `/hk:orca:orchestrate` command와 같은 절차를 Hermes에서 쓰기 위한 mirror다.

한 작업(페이지/기능)을 **여러 Orca 서브워크트리 워커에 병렬 분담**시키고, 리드(이 세션)가 **supervised로** 수집·브리프·디스패치·교차리뷰·수정·통합을 조율한다. **얇은 레시피** — 명령·플래그·완료추적 메커닉은 아래 필수 로드가 정본이고, 이 파일은 **우리 워크플로 + 주의사항**만 담는다.

## Hermes 사용 방식

- 이 skill을 로드하면 Hermes는 Claude Code command 파일을 따로 읽지 않아도 같은 절차를 따른다.
- **공식 출처**: `stablyai/orca` (`https://github.com/stablyai/orca`). 공식 설치는 README의 `brew install --cask stablyai/orca/orca`; npm/PyPI/brew의 동명 `orca` 후보는 다른 도구일 수 있으니 설치 전에 공식 repo/README와 `orca --help`를 대조한다.
- 실제 명령 실행은 설치된 `orca` CLI를 기준으로 한다. 시작 전 `command -v orca`, `orca status --json`, `orca worktree ps --json`, 필요한 하위 명령 help를 확인한다. 런타임이 꺼져 있으면 공식 가이드대로 `orca open --json` 후 `orca status --json`을 재확인한다.
- 공식 `orca-cli`/`orchestration` 스킬 원본은 `stablyai/orca/skills/orca-cli/SKILL.md`, `stablyai/orca/skills/orchestration/SKILL.md`다. 로컬에 별도 설치되어 있으면 먼저 로드하고, 없으면 공식 원본 또는 현재 `orca agent-context --json`/`orca --help`를 파싱한다. 기억으로 플래그를 만들지 않는다.
- Hermes의 `delegate_task`나 일반 subagent는 Orca supervised provenance를 만들지 않으므로 이 workflow의 대체재로 쓰지 않는다.

## 먼저 로드 (필수 · 스킵 금지)

디스패치 전에 **둘 다** 연다. 여기 든 걸 안 읽고 기억/습관으로 실행하지 마라 — 그게 매 사고의 원인이었다. 메커닉 정본은 이 스킬들이다(프로젝트가 별도 orca 문서를 두더라도 스킬이 우선).

- **`orca-cli` 스킬** — worktree / terminal / read / send / 보드 전달 계층.
- **`orchestration` 스킬** — supervised 추적(`task-create` → `dispatch --inject` → `worker_done`/알림 드레인) + 「도구 경계」(비-Orca subagent 도구로 대체 금지).

**방식 = supervised 고정.** 워커 디스패치·완료추적은 항상 supervised다. ❌ full handoff · 자체 파일/문자열 폴링 · Workflow/subagent 도구로 워커 완료를 대체하지 마라 — Orca task/dispatch/`worker_done` provenance를 안 만든다. Workflow는 **P1 스카우트·P6 준비도 분석(read-only)만**. 교차리뷰는 워크트리 내 **교차모델(Codex) 실터미널**.

## 워크플로 (우리 방식)

**P0 프로비저닝** — `worktree ps` 감지, 없으면 `worktree create --parent-worktree active`. 역할은 `--name …-ui/…-data`로 드러내기.

**P1 수집** — Workflow 병렬 read-only 스카우트(현재 표면 / 레퍼런스 / DS 인벤토리 / 도메인·DB 델타). 스카우트는 서로 blind → **리드가 실파일로 재대조·판정**. parity면 레거시를 실제로 열어 대조.

**P2 브리프** — 워커별 `.hk/handoff/<task>.md` **파일**(터미널 장문 금지 — 이스케이프·잘림). 필수: 역할분담(너는 X만) · 구현 전 로드 · 스코프 IN/**OUT** · 레퍼런스(UX만) · DS 규약(프리미티브 조립·재구현 금지) · **DTO 계약(양쪽 동일 shape)** · 앱 규약(문자열 언어·브라우저 DB직접 금지·접근성) · 검증 + **커밋 금지** · `worker_done` 보고.

**P3 디스패치(supervised)** — `read`로 idle 확인 → `task-create` → 워커 터미널에 `dispatch --inject`를 **한 개씩** 투입 → 공식 방식대로 `check --wait --types worker_done,escalation,decision_gate --timeout-ms <n>` rolling window로 기다린다. timeout/`{count:0}`은 실패가 아니라 checkpoint다. 자체 sleep/파일 폴링 금지; 필요 시 `task-list`, `dispatch-show`, `terminal read/wait --for tui-idle`로 liveness만 점검한다.

**P4 조율** — 공유 상태는 리드가 순수 git으로 정렬. 미커밋 공유 변경(DS 등)은 base에서 커밋(**승인**) 후 각 워커 브랜치에 `git -C <wt> merge`(ff). DTO 드리프트는 임의변경 금지 → 보고 → 양쪽 브리프 동시 갱신.

**P4.5 교차리뷰(교차모델)** — 저자 ≠ 리뷰어 모델(Claude 저작 → Codex). 미커밋이면 **같은 워크트리 in-place** 스폰(새 워크트리는 미커밋 안 보임). 브리프 = 대상 `git diff` · 합격기준 · **"정적 리뷰만(빌드/테스트/설치/네트워크 금지)"** · 산출 `.hk/review/<task>-<reviewer>.md`(blocker/major/minor/nit + `file:line` + 끝줄 `SUMMARY … verdict CLEAN|NEEDS_FIX`). **리드가 파일로 수확**(리뷰어는 `orca` 못 부름).

**P5 수정 루프(CLEAN까지)** — findings를 **리드가 실측 대조** → 확정분 `.hk/fix/<task>-fixes.md` → **supervised 재투입** → 재리뷰(소규모면 기존 리뷰어 컨텍스트 재활용). `worker_done` "PASS"는 **리드가 diff·검증 재대조**(환경차로 가짜 가능). 양쪽 `verdict CLEAN`까지.

**P6 통합 랜딩(승인 게이트)** —
1. 준비도 분석(Workflow): 계약 일치(UI mock ↔ DTO) · 머지 충돌 · 배선 범위.
2. 각 브랜치 커밋(**승인**): `.hk/`·로컬 store 제외 명시적 `git add`. 문서 번호 충돌 시 리넘버.
3. 통합 워크트리: `worktree create --base-branch <default> --setup skip` → `git -C <wt> merge --no-ff <branch> -F <msgfile>`(경로 disjoint면 충돌 0) → deps install + ORM codegen + 베이스라인 검증.
4. 배선: supervised 워커 → Codex 리뷰 → **리드 최종 전체검증**.
5. 랜딩(**승인**): `git merge --no-ff <intBranch>` → `<default>` → `push` → `orca worktree rm --force` 정리.
6. **정직한 검증 상태**: 코드·타입·테스트·빌드 GREEN이어도 **실제 클릭(로그인/DB)은 별도** — 어디까지 눌렀는지 명시.

## 주의사항 (스킬·문서에 없는 것)

- **완료 감지 = `worker_done` + liveness**: 공식 기본은 rolling `check --wait --types worker_done,escalation,decision_gate`. timeout은 실패가 아니다. 워커가 보고 없이 종료(프로세스 exit → 셸 `❯`)하면 리드가 즉시 산출물 직접 수확·검증한다(코드는 됐는데 self-verify·보고만 못 한 경우 흔함).
- **Codex 리뷰어**: 샌드박스·승인이 pnpm/네트워크에서 멈춤 → `codex --dangerously-bypass-approvals-and-sandbox -c model_reasoning_effort="xhigh"` + "정적 리뷰만" 브리프 + 결과는 파일. 온보딩: 업데이트 프롬프트 = **"2" Skip**(기본 Enter는 설치).
- **pnpm ignored-builds(esbuild 등)**: 검증·`git commit`(pre-commit) 막힘 → **ENV `PNPM_CONFIG_VERIFY_DEPS_BEFORE_RUN=false` export**(대문자만 유효, 소문자 no-op). ⚠️ `pnpm --filter <pkg> <script> --config...` 처럼 필터 실행 뒤 CLI 플래그는 하위 스크립트로 먹혀 무효 → 반드시 ENV.
- **fresh 워크트리(`--setup skip`)**: deps 없음 → 리드가 `pnpm install` + ORM codegen(더미 `DATABASE_URL` 오프라인) + 베이스라인 검증 후 투입.
- **`git merge -F -`(stdin) 불가** → `-F <file>` 또는 `-m`.
- **보드 수동**: dispatch/worker_done ≠ 보드(`workspaceStatus`). 리드가 `worktree set --workspace-status`로 직접(in-progress/in-review/completed).
- **`orca worktree rm`**: 워크트리+브랜치 함께 제거(이후 `git branch -D`는 "not found").
- **가드레일(프로젝트 `CLAUDE.md`)**: commit/push/deploy·운영 DB·infra = 승인 없이 금지. 잘못된 워크트리에서 공유 상태(DS·tokens·계약) 수정 금지. 브리프에 비밀번호/토큰 평문 금지(env·경로 참조).

## 안티패턴

| ❌ | 이유 |
|---|---|
| 필수 로드 스킵하고 기억으로 실행 | 커맨드 무시 → 매번 재발 |
| supervised 대신 full handoff·자체 폴링·Workflow | provenance/`worker_done` 없음 → 조용히 정지 |
| 수집 없이 바로 디스패치 | 워커가 레거시/DB/DS 오판하며 헛돎 |
| 브리프 터미널 장문 붙여넣기 | 이스케이프·잘림 → 파일로 |
| 미커밋 공유 DS 방치하고 착수 | stale 위 작업 → 병합 충돌 |
| 양쪽 DTO shape 불일치 | 합류 시 배선 실패 |
| `send` 전 `read` 생략 | 워커 thinking 중 입력 꼬임 |
| `worker_done`/PASS 그대로 신뢰 | 환경차 가짜 → 리드 재대조 |
| 완료를 코드 유무로 판정 | 검증 상태(눌러봤는지)로 |

## Verification Checklist

- [ ] 공식 출처(`stablyai/orca` README + `skills/orca-cli`/`skills/orchestration`) 또는 현재 `orca agent-context --json`/`orca --help`를 확인했다.
- [ ] `command -v orca`, `orca status --json`, `orca worktree ps --json`로 설치·런타임·워크트리 상태를 확인했다.
- [ ] 워커 디스패치는 supervised 경로(`task-create` → `dispatch --inject` → `worker_done`/자동 알림)로 추적된다.
- [ ] 워커별 handoff는 `.hk/handoff/<task>.md` 파일로 작성했다.
- [ ] 교차리뷰 산출물은 `.hk/review/` 아래 파일로 수확했다.
- [ ] `worker_done` 또는 terminal exit 이후 리드가 diff·테스트·검증 상태를 직접 재대조했다.
- [ ] 통합/커밋/푸시/정리 같은 파괴적 단계는 hyeong 승인 후 진행했다.
