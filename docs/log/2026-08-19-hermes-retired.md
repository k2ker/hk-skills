---
date: 2026-08-19
type: decision
refs: [구 docs/DECISIONS.md]
---

# Hermes 소비 경로 폐기 (사용자 선언)

사용자가 Hermes를 더 안 쓰기로 함 → `skills.external_dirs`용 로컬 실파일 요구가 사라짐. **후속 미결**: ① vendor 아키텍처 재평가 — git-subdir+SHA 핀 전환(공식 방식·repo 경량화) vs 복사 방식 유지(업스트림 소멸 보험 — `vercel-cli-with-tokens` 실사례 · 커뮤니티 diff 검증). 권고는 유지+SHA 기록 보강, 선택 대기. ② CLAUDE.md·README의 Hermes 소비 경로 문단 정리 — vendor 결정과 함께 반영.
