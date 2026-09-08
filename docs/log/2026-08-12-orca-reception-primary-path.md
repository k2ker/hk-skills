---
date: 2026-08-12
type: decision
refs: [구 docs/DECISIONS.md, 2026-08-12-orca-orchestration-reception]
---

# orca-workers 수신 주 경로 유지 — check --wait

Orca 1.4.177+가 포인터 깨우기를 복구했지만 **주 경로는 백그라운드 `check --wait` 유지**, 포인터는 보험. 근거: 도착 즉시 수신(실측 1초) vs idle 대기, 정본 가이드의 supervision 표준 유지, push 회귀 내성. `worker-start`/`worker-release` 등 신규 표면 채택은 #12953 Phase 2 완성 또는 다음 실전 사이클에서 재평가.
