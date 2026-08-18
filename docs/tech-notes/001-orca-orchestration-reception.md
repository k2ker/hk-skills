# 001 — Orca 1.4.180 orchestration 수신 경로·다이얼로그 감지 실측 (2026-08-12~18)

orca-workers 스킬의 전제였던 "자동 알림 고장(#11787)"을 재검증하고 스킬 문서를 갱신한 작업 기록.
**실측 정본은 스킬 references에 있다** — 이 노트는 요약과 포인터만.

## 결론 3줄

1. **#11787의 실질 문제는 v1.4.177에서 해소** — 이슈/원 PR은 여전히 Open이지만, #12584+#12988(#12953 Phase 1)이 `run:<id>` 메일 도착 시 코디네이터 pane에 "check 하라" **포인터**를 주입해 깨운다(본문 주입 아님). A/B 실측: waiter 방식 1초 캡처, 포인터 방식 idle 후 도착. 주 경로는 계속 백그라운드 `check --wait`, 포인터는 보험. → `plugins/orca/skills/orca-workers/references/push-on-idle-bug-11787.md` 재실측 섹션
2. **승인 다이얼로그 감금은 별개 문제** — 메일이 아니라 `check --wait`로 못 잡음. `terminal wait --for tui-idle` 프로브의 `blockedReason`(`codex-interactive-prompt`)으로 기계 감지. 이 머신 기본 구성(Claude 넓은 allowlist·Codex YOLO)에선 다이얼로그 자체가 안 뜸. → `references/approval-dialog-detection.md`
3. **1.4.180 신규 표면**(스킬 채택은 미결 — DECISIONS 참고): `worker-start`(preferred 워커 기동), `worker-release/retain/abandon/show/read`, `worker_done`에 `--outcome` 필수(+task 자동 completed), `--model/--effort` 런치 옵션, `--on <env>` 연합 원격 워커, `dispatch:<id>` 주소, `task-list --brief`.

## 반영 커밋

- `d01a2e8` — 수신 문서 갱신(0.4.4): 포인터 깨우기 복구 반영, ack 전 이중 노크 정상 명시
- `e8d77e2` — 승인 다이얼로그 감금 감지·대응(0.4.5)

## 함정 (재발 방지)

- 터미널 env `ORCA_APP_VERSION`은 런타임 실버전이 아님 — `orca status --json`의 `runtime.appVersion`이 정답
- 로컬 orca 스킬 파일은 의도적 discovery stub — 정본은 `orca skills get <name>` (stub을 grep해서 stale 판정 금지)
- waiter가 배치를 받고 ack하기 전 틈에 포인터가 한 번 더 올 수 있음 — 무해, 즉시 ack로 잠재움
