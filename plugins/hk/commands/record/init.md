---
description: 기록 컨벤션 v2 구조를 이 프로젝트에 깐다 (멱등 — 있는 파일은 건드리지 않음)
---

기록 컨벤션 v2 스캐폴딩을 수행하라. 먼저 hk `record` 스킬을 로드해 규칙을 확인한다. 템플릿 원본은 플러그인에 동봉되어 있다: `${CLAUDE_PLUGIN_ROOT}/templates/` — **반드시 이 환경변수로 참조**(플러그인 캐시 경로는 버전마다 바뀌므로 절대경로 하드코딩 금지).

절차:

0. **preflight — 어떤 쓰기보다 먼저.** 판정 순서 엄수: ① `docs/log/`가 있으면 **이미 v2** — 빠진 파일만 아래 절차로 보충(MEMORY.md가 함께 있어도 v2다) ② docs/log가 없는데 v1 흔적(`MEMORY.md` 또는 `docs/tech-notes/`)이 있으면 **아무것도 만들지 말고 종료** — `/hk:record:migrate` 안내(반쪽 이관 방지) ③ 둘 다 아니면 신규 — 아래 절차 전부 수행. (migrate가 뼈대를 만들 때는 이 preflight를 건너뛰고 1~4단계만 재사용한다 — "scaffold 절차")
1. `docs/log/` 생성 + `templates/log-readme.md` → `docs/log/README.md` 복사
2. `templates/memory-skeleton.md` → `MEMORY.md` 복사
3. `docs/DECISIONS.md` 없으면 헤더만 생성: `# Decisions` + "새 결정이 생기면 위에 추가 (최신이 위). 항목 3줄 상한 — 증거·경위는 docs/log/ 조각 링크로."
4. `CLAUDE.md`에 `templates/claude-md-snippet.md` 내용을 append (같은 제목의 섹션이 이미 있으면 스킵). CLAUDE.md 자체가 없으면 이 내용만으로 새로 만들지 사용자에게 확인
5. 결과 보고: 만든 것 / 건너뛴 것 / preflight에서 감지된 기존 기록물(NOTES/TODO류 제각각 문서 포함 — 있으면 migrate 안내)

커밋은 하지 않는다 (사용자 승인 게이트).
