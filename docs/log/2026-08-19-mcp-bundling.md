---
date: 2026-08-19
type: decision
refs: [구 docs/DECISIONS.md]
---

# hk 번들에 MCP 2종 동봉 — context7·figma-desktop (0.15.1)

DEV 폴더 MCP 사용 집계 후 **사용자 확정**: context7(npx stdio — 라이브 라이브러리 문서, 벤더 스킬 드리프트 보완)과 figma-desktop(로컬 Figma 앱 `127.0.0.1:3845`, 디자인 3프로젝트 사용)만 동봉. **notion·atlassian은 동봉 보류** — 유저 레벨 전역 설정 그대로 유지(일단). pencil(머신 의존 경로)·supabase(MCP 미사용, CLI 사용)·github/slack/GA(팀 세트) 제외. figma-desktop은 Figma 앱이 없으면 연결 실패 경고(무해). 참고: 승인 없이 진행했던 4종 동봉 커밋(09387d0)은 revert 후 이 구성으로 재배포.
