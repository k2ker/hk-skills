---
name: orca-workers
description: "Use when coordinating parallel Orca sub-worktree workers for one feature/page cycle: provision worktrees, brief, supervised dispatch (task-create + dispatch --inject), background check --wait reception of worker_done (auto-injection is broken — orca#11787), cross-model review (Claude↔Codex either direction, or Claude-only cross-session), fix loop, and integration landing. Command mechanics delegate to the orca-cli & orchestration skills. Triggers: Orca orchestration, parallel worktree workers, supervised dispatch, worker_done, cross-model review."
version: 0.4.0
author: hk
license: MIT
platforms: [macos, linux]
metadata:
  hermes:
    tags: [orca, orchestration, worktrees, supervised-workers, codex, cross-model-review, claude-code]
    related_skills: [orca-cli, orchestration]
---

# Orca 서브워크트리 병렬 오케스트레이션

한 작업을 여러 Orca 서브워크트리 워커에 병렬 분담하고, 리드(이 세션)가 supervised로 브리프·디스패치·교차리뷰·수정·통합을 조율한다. 이 파일은 워크플로와 검증된 함정만 담는다 — 명령·플래그 정본은 Orca가 제공한다(아래).

## 먼저 로드 (스킵 금지)

디스패치 전에 `orca-cli`·`orchestration` 스킬을 인벤토리에서 이름으로 로드한다(경로 하드코딩 금지 — 설치 위치는 머신마다 다름). 인벤토리에 없으면 Orca 환경이 아니라는 신호 → 진행하지 마라. 둘 다 discovery stub이므로 로드 후 `orca skills get <name>`으로 실행 바이너리와 버전이 일치하는 정본을 읽는다 — 기억이나 캐시로 명령을 추측하는 게 사고의 반복 원인이었다.

## 수신 = 백그라운드 `check --wait` (자동 주입 없음)

Orca 1.4.162+는 `run:<id>` 앞 lifecycle 메일(`worker_done`·`question`·`escalation`)을 pane에 자동 주입하지 않는다([orca#11787](https://github.com/stablyai/orca/issues/11787) — 원인·실측·배제된 헛다리 목록은 `references/push-on-idle-bug-11787.md`). 그래서:

- dispatch 후 `orca orchestration check --wait --types worker_done,escalation,question --timeout-ms <n>`을 **백그라운드로** 건다. 완료 시 하니스가 리드를 자동 재호출하므로 리드는 그동안 다른 일을 계속한다.
- **2회차부터는 `check --ack <deliveryId> --wait …`** — ack 없이 반복하면 같은 배치가 무한 replay되어 새 완료가 영원히 안 보인다(증상이 "알림 고장"과 똑같아 오진 주의). 읽음 처리는 `--ack` 시점이며, 관찰만 할 땐 `--peek`(마킹 없음).
- foreground `--wait`·sleep·폴링 루프는 금지 — 리드가 묶여 감독이 멈춘다. `terminal wait`류 긴 대기도 같은 이유로 백그라운드로.
- 타임아웃·`{count:0}`은 실패가 아니라 체크포인트 — **즉시 다시 건다**(대기 공백에 도착한 메일이 이후 check에 안 잡히는 유실 사례 실측 — references 참고). 체크포인트마다 `task-list`도 본다: 메일을 못 받았는데 task가 `completed`면 배달 유실 — `inbox`로 존재 확인 후 워커에게 파일 보고를 받아 수확한다(긴 작업은 15~60분이 정상이니 조기 개입은 금물).

## 원칙

- **supervised 고정.** 워커는 `task-create` → `dispatch --inject`로 띄운다(provenance). 완료·검증 authority는 리드 소유 — worker_done "PASS"는 환경차로 가짜일 수 있으니 리드가 diff + 프로젝트 검증 명령으로 재대조한다.
- **토폴로지는 의존 방향으로 정한다 — N-way 병렬이 기본 아님.** 파일 disjoint + 계약 독립이면 병렬, 강한 단방향 의존이면 웨이브(계약 먼저 확정, 다음 웨이브에서 병렬 — 안 나누면 다운스트림이 계약을 가정만 하다 합류 때 드리프트 수습), 소규모면 순차 1명이 더 빠르고 안전하다.
- **모델 역할 = 사용자 결정 (기본 A) · 저자 ≠ 리뷰어 불변.** A: Claude 구현 → Codex 리뷰 / B: Codex 구현 → Claude 리뷰 / C: Claude 전용(구현·리뷰 별 세션 — 교차모델은 포기해도 독립 관점은 유지). Codex 가용성 먼저 확인(`command -v codex`), 없으면 무조건 C. 리드가 임의로 구현 모델을 바꾸지 않는다.
- **커밋·푸시·배포·운영 인프라 = 승인 게이트.**

## 워크플로

- **P0 프로비저닝** — 워커당 워크트리 1개. 한 워크트리에 워커 여럿은 절대 금지 — 작업트리·git 인덱스·dev 서버를 공유해 반쯤 쓰인 파일로 얽힌다. fresh 워크트리는 deps 없음 → 리드가 설치 + 베이스라인 검증 후 투입.
- **P1 파악** — 리드가 실파일로 계약·표면·스코프 확정(브리프 정확도가 결과를 좌우). 표면이 크면 read-only 스카우트 후 리드가 재대조.
- **P2 브리프** — 워커별 파일로 작성(터미널 장문 붙여넣기 금지 — 이스케이프·잘림). 필수: 역할("너는 X만") · 스코프 IN/**OUT** · 해당 프로젝트 규약 · 검증 명령 + 커밋 금지 · worker_done 보고 문구는 **이중 보고**로("전송, 실패 시 1회 재시도, 그래도 실패면 생략 — 성공 여부와 무관하게 최종 텍스트로 완료 보고"; "정확히 한 번만"으로 쓰면 전송 실패 시 그냥 포기한다). 파일 disjoint로 분할하고, 공유 계약(DTO)은 양쪽 브리프에 동일 shape 명시.
- **P3 디스패치** — `terminal wait --for tui-idle`로 idle 확정(satisfied:true + blockedReason 없음) → `task-create` → `dispatch --inject` → 백그라운드 `check --wait` 가동. 워커가 보고 없이 exit하면 리드가 산출물을 직접 수확·검증한다(코드는 됐는데 보고만 못 한 경우가 흔함).
- **P4 교차리뷰** — 저자 워크트리 in-place에서(미커밋 diff는 새 워크트리에선 안 보임) **위임 세션**이 리뷰한다 — 리드 셸에서 직접 실행 금지. Codex 리뷰어는 orca 터미널에서 `codex exec "<브리프 읽고 리뷰 파일 써라>"`(프롬프트를 arg로 — 첫 프롬프트 유실 회피, 종료가 완료 신호). 리뷰어는 읽기전용이라 워크트리-워커 1:1 원칙의 유일한 예외. 산출은 파일(`file:line` findings + `verdict CLEAN|NEEDS_FIX`)로 리드가 수확. Codex 불가 시 신규 Claude 세션으로 동일하게.
- **P5 수정 루프** — findings를 리드가 실측 대조(오탐 거름) → 확정분을 같은 워커에 재투입 → `CLEAN`까지. 리뷰어 제안 그대로인 trivial 수정은 리드 실측 확인으로 갈음하되 정직 고지.
- **P6 통합 랜딩(승인 게이트)** — 브랜치별 커밋(메시지는 `-F <msgfile>` — 멀티라인 안정) → base 워크트리에 `merge --no-ff`(disjoint면 충돌 0) → 전체검증(typecheck/lint/test/build) → 실동작 확인 → push → `worktree rm` 정리. 코드 GREEN ≠ 실제 눌러봄 — 어디까지 확인했는지 정직하게 보고한다.

## 함정 (전부 실사고·실측 기록 — 추정 없음)

2026-08 실측: 위 수신 섹션 전체 + `worker_done`은 `taskId`·`dispatchId` 둘 다 있어야 함(없으면 `Rejected`로 적재만 됨) + 코디네이터 터미널은 자기 Run에만 쓰기 가능(`consumer_fenced` — 남의 Run 작업은 그 세션에 위임).

과거 실사고에서 검증:

- **TUI 다이얼로그가 `send`·`dispatch --inject`의 프롬프트를 삼킨다** → 전송 전 tui-idle 확정, 유실 의심 시 `read`로 착수 확인 후 재전송.
- **dispatched task엔 `dispatch --inject` 재실행 불가** → 복구는 기존 taskId/dispatchId를 명시한 preamble을 `terminal send`로 수동 재주입(pane의 dispatch 컨텍스트는 유효해 worker_done 인정됨).
- **`terminal wait --for exit` 불신뢰**(handle stale 즉사·이미 exit인데 무기한 대기) → 완료 감지는 worker_done 경로로.
- **Codex 구현 워커는 `network_access=true` 필수** — 기본 샌드박스가 orchestration RPC를 막아 `worker_done`·`ask` 불가. 읽기전용 리뷰어는 불필요(파일 수확이 정석).
- **Codex의 MCP transport 에러는 무해 노이즈**, 훅 승인 다이얼로그는 필요한 것만 승인(일괄 trust는 타 에이전트 훅까지 켜 로그 오염).
- **터미널 식별은 handle로만** — title은 Orca가 자동 변경해 오탐. **`send` 전 `read`** — thinking 중 입력이 꼬인다. **`worktree rm`은 브랜치도 함께 제거.**

프로젝트 종속 사항(패키지매니저 함정, env 키·경로, 디자인 시스템 규약 등)은 이 스킬이 아니라 각 프로젝트의 CLAUDE.md·계약 스킬에 둔다.
