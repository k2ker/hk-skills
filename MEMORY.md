# hk-skills 프로젝트 메모리

> 세션 간 공유하는 작업 기록의 입구. 구조·규칙은 `CLAUDE.md`, 결정 기록은 `docs/DECISIONS.md`, 조사·실측 기록은 `docs/tech-notes/`.

## 현재 상태 (2026-08-18)

- 번들 버전: `orca` 0.4.5 · `vendor` 0.2.1 · `hk` 0.15.1(MCP 2종: context7·figma-desktop) · `dev` 0.2.0
- 반영 경로: 커밋→푸시 후 각 PC에서 `/plugin marketplace update hk-skills` → **새 세션** (플러그인은 GitHub 캐시본으로 실행되므로 repo 수정만으로는 반영 0)
- 벤더 스킬 26개 최신 전수 대조: 2026-08-18 (7개 갱신, `vercel-cli-with-tokens` 업스트림 소멸)

## 전용 장부 (여기 중복 기록 금지 — 포인터만)

- 벤더 스킬 출처·대조 이력 → `VENDORED-SKILLS.md`
- orca-workers 실측 정본(스킬과 함께 배포됨) → `plugins/orca/skills/orca-workers/references/`

## Tech-notes

- [001 — Orca 1.4.180 orchestration 수신 경로·다이얼로그 감지 실측](docs/tech-notes/001-orca-orchestration-reception.md)
- [002 — Claude Code 생태계 서베이: 훅·스킬·커맨드·플러그인 후보 48건 압축](docs/tech-notes/002-claude-code-ecosystem-survey.md)
- [003 — 플러그인 settings/MCP 배포 제약: settings는 agent 필드만, MCP는 .mcp.json 필수](docs/tech-notes/003-plugin-settings-mcp-constraints.md)
- [004 — 스킬 후보 심층 분석: grill-me는 grilling과 세트, verification이 궁합 1위, Sentry security-review는 내장과 이름 충돌](docs/tech-notes/004-skill-candidates-deep-dive.md)

## 미결 (다음 세션이 이어받을 것)

- vendor 아키텍처: git-subdir+SHA 전환 vs 복사 유지+SHA 기록 — 사용자 선택 대기 (DECISIONS 2026-08-19 참고)
- 생태계 서베이(002) 도입 선정: 스킬 /vendor:add·hk 훅 추가 — 사용자 선택 대기 (MCP 동봉은 2종으로 완료 — DECISIONS 참고)
