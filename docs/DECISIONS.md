# Decisions

새 결정이 생기면 위에 추가 (최신이 위).

## 2026-08-18 — 기록 컨벤션 도입

repo 전용 장부(VENDORED-SKILLS.md·스킬 references)만 쓰던 것에서 `MEMORY.md` + `docs/tech-notes/` + `docs/DECISIONS.md` 컨벤션을 도입. 전용 장부가 정본인 내용은 중복 기록하지 않고 포인터만 둔다.

## 2026-08-18 — 벤더 canary 갱신 기준 보완

7/28 판례("차이가 버전 문자열뿐이면 canary로 안 내려간다")를 보완: **canary라도 실질 내용 변경이 있으면 갱신한다.** 적용례: turborepo 2.10.6 → 2.10.11-canary.4.

## 2026-08-18 — vercel-cli-with-tokens 업스트림 소멸 대응

`vercel-labs/agent-skills`에서 제거됨 → 로컬본 유지 + VENDORED-SKILLS.md에 "갱신 좌표 상실" 표기. 제거/대체는 필요해질 때 재결정.

## 2026-08-12 — orca-workers 수신 주 경로 유지

Orca 1.4.177+가 포인터 깨우기를 복구했지만 **주 경로는 백그라운드 `check --wait` 유지**, 포인터는 보험. 근거: 도착 즉시 수신(실측 1초) vs idle 대기, 정본 가이드의 supervision 표준 유지, push 회귀 내성. `worker-start`/`worker-release` 등 신규 표면 채택은 #12953 Phase 2 완성 또는 다음 실전 사이클에서 재평가.
