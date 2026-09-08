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
- [004 — 스킬 후보 심층 분석](docs/tech-notes/004-skill-candidates-deep-dive.md) — 도입 판단에 필요한 원문 근거
- [005 — 기록 컨벤션 감사](docs/tech-notes/005-record-convention-audit.md) — 겹침 5건 진단
- [006 — v2 플러그인화 리서치](docs/tech-notes/006-record-plugin-packaging-research.md) — 패키징 사례·훅 스펙·하이브리드 게이트
- [007 — v2 Phase A 구현](docs/tech-notes/007-record-v2-phase-a-impl.md) — 산출물 5종·설계 결정·리뷰 결산·수용 한계
- [008 — git 동기화 가드](docs/tech-notes/008-git-sync-guard.md) — 목적지 해석·bash 함정 4종·리뷰 수렴 교훈
- [009 — 기록 컨벤션 구조 개선](docs/tech-notes/009-record-convention-restructure.md) — setup 통합·라벨 폐지·MEMORY 5섹션·재실행 안전성·적용 현황 스캔

## 미결 (다음 세션이 이어받을 것)

- **git-sync-guard 간결화 완료(98줄·11케이스, tech-note 008) — 커밋 승인 대기.** 남은 결정 2건: ① 테스트 파일 위치 — `plugins/hk/hooks/tests/`(배포에 포함) vs `scripts/tests/`(배포 제외, 권고) ② 교차 리뷰 수렴 규칙(상한 2라운드·HIGH 의무/MED 재량) 채택 여부
- **record 컨벤션 구조 개선 완료 — 커밋 승인 대기**(hk 0.18.0): init+migrate→`/hk:record:setup` 통합(보충/적용 2모드, **재실행 안전 — `docs/log` 있으면 조각 재처리 금지·잔여는 보고만**), v1/v2 라벨 폐지(`docs/log` 유무로만 판정), MEMORY를 내장 메모리 명세대로(미결·사용자/작업 방식·제약·참조), DECISIONS 필수→선택
- **세션 메모리(PC 종속) 이관 미이행**: "쉬운 한국어"·"질문≠승인" 등 user·feedback 항목이 아직 `~/.claude/.../memory/`에 있음 → repo MEMORY.md 또는 hk 훅으로 옮기고 폐기할 것

- vendor 아키텍처: git-subdir+SHA 전환 vs 복사 유지+SHA 기록 — 사용자 선택 대기 (DECISIONS 2026-08-19 참고)
- **기존 규칙 고도화 (외부 스킬 도입은 보류 — 2026-08-19 결정)**: 흡수 후보 매핑은 DECISIONS 참고 (verification→orca-workers, grilling→planning-quick, 실수 원장→Stop 훅, instructions-audit→/vendor:add). 착수 범위는 사용자와 정할 것
- 기록 컨벤션 v2: **Phase A 배포·E2E 완료**(7300ab6, hk 0.16.0·orca 0.4.6 캐시 반영, 실측은 007 후속절 1) → **다음: Phase B — hk-skills 자체 이관(태스크 9, init/migrate 실전 테스트 겸함) 착수 승인 대기** → gamescom 랜딩(행사 후, record-pilot 워크트리 보존 중). 주의: 이 세션은 구훅(0.14.0)으로 시작됨 — 새 훅은 새 세션부터
