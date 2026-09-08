---
date: 2026-08-18
type: decision
refs: [구 docs/DECISIONS.md]
---

# 벤더 전수 대조에서 나온 결정 2건

## canary 갱신 기준 보완

7/28 판례("차이가 버전 문자열뿐이면 canary로 안 내려간다")를 보완: **canary라도 실질 내용 변경이 있으면 갱신한다.** 적용례: turborepo 2.10.6 → 2.10.11-canary.4.

## vercel-cli-with-tokens 업스트림 소멸 대응

`vercel-labs/agent-skills`에서 제거됨 → 로컬본 유지 + VENDORED-SKILLS.md에 "갱신 좌표 상실" 표기. 제거/대체는 필요해질 때 재결정.
