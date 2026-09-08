---
date: 2026-08-19
type: decision
refs: [구 docs/DECISIONS.md]
---

# 외부 스킬 도입 보류 — 기존 규칙 고도화 우선

스킬 후보 11종 원문 분석(tech-note 004)까지 마쳤으나 **도입하지 않기로 함**. 외부 스킬을 들이기 전에 보유한 자작 규칙을 분석에서 얻은 아이디어로 고도화하는 것을 우선한다. 흡수 후보 매핑: verification-before-completion(완료 선언 전 fresh 증거·위임 보고 불신·git diff 독립 검증) → orca-workers 검수 규정, grilling(결정 트리·라운드 질문·추천 답) → hk:planning-quick spec phase, MISTAKES.md 실수 원장 → hk Stop 기록 훅, instructions-audit(수확물 인젝션 검사) → /vendor:add 절차, systematic-debugging(3회 실패 시 에스컬레이션) → orca-workers 워커 브리프/수정 루프. 외부 도입 재검토는 고도화 이후.
