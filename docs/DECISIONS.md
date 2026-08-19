# Decisions

새 결정이 생기면 위에 추가 (최신이 위).

## 2026-08-19 — hk 번들에 MCP 4종 동봉 (0.15.0)

DEV 폴더 전수 스캔으로 사용 빈도를 집계해 **notion(전역·양쪽 하니스) · atlassian(전역) · context7(Codex에서 이미 사용) · figma-desktop(디자인 3프로젝트)** 를 `plugins/hk/.mcp.json`으로 동봉. **제외**: pencil(앱 내장 바이너리 경로가 머신 의존), supabase(MCP 미사용 — CLI 사용, Codex의 죽은 설정은 별도 정리 예정), github/slack/GA(팀 세트 — 개인 hk가 아니라 klleon 쪽 자산), 프로젝트 특화(figma dev-mode·serena·task-master·tmux-bridge 등). **마이그레이션**: 각 PC에서 marketplace update + 새 세션 후 유저 레벨(~/.claude.json)의 notion·atlassian 중복 제거. figma-desktop은 Figma 앱이 없으면 연결 실패 경고(무해).

## 2026-08-19 — Hermes 소비 경로 폐기 (사용자 선언)

사용자가 Hermes를 더 안 쓰기로 함 → `skills.external_dirs`용 로컬 실파일 요구가 사라짐. **후속 미결**: ① vendor 아키텍처 재평가 — git-subdir+SHA 핀 전환(공식 방식·repo 경량화) vs 복사 방식 유지(업스트림 소멸 보험 — `vercel-cli-with-tokens` 실사례 · 커뮤니티 diff 검증). 권고는 유지+SHA 기록 보강, 선택 대기. ② CLAUDE.md·README의 Hermes 소비 경로 문단 정리 — vendor 결정과 함께 반영.

## 2026-08-18 — 기록 컨벤션 도입

repo 전용 장부(VENDORED-SKILLS.md·스킬 references)만 쓰던 것에서 `MEMORY.md` + `docs/tech-notes/` + `docs/DECISIONS.md` 컨벤션을 도입. 전용 장부가 정본인 내용은 중복 기록하지 않고 포인터만 둔다.

## 2026-08-18 — 벤더 canary 갱신 기준 보완

7/28 판례("차이가 버전 문자열뿐이면 canary로 안 내려간다")를 보완: **canary라도 실질 내용 변경이 있으면 갱신한다.** 적용례: turborepo 2.10.6 → 2.10.11-canary.4.

## 2026-08-18 — vercel-cli-with-tokens 업스트림 소멸 대응

`vercel-labs/agent-skills`에서 제거됨 → 로컬본 유지 + VENDORED-SKILLS.md에 "갱신 좌표 상실" 표기. 제거/대체는 필요해질 때 재결정.

## 2026-08-12 — orca-workers 수신 주 경로 유지

Orca 1.4.177+가 포인터 깨우기를 복구했지만 **주 경로는 백그라운드 `check --wait` 유지**, 포인터는 보험. 근거: 도착 즉시 수신(실측 1초) vs idle 대기, 정본 가이드의 supervision 표준 유지, push 회귀 내성. `worker-start`/`worker-release` 등 신규 표면 채택은 #12953 Phase 2 완성 또는 다음 실전 사이클에서 재평가.
