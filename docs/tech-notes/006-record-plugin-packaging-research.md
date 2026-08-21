# 006 — 기록 컨벤션 v2 플러그인화 리서치 (2026-08-21)

3렌즈 병렬 리서치(생태계 패키징 사례 / Claude Code 네이티브 기능 정본 / 훅 구현 기술). 사실만 — 설계 결정은 DECISIONS.

## 생태계 패키징 사례 (repo 실물 확인)

- **claude-md-management**(공식): 스킬 1 + 커맨드 1, 훅 0. "회고→초안→diff 제시→승인 후 적용" 5단계가 전부 프롬프트 지시. 품질 루브릭은 references/로 분리.
- **superpowers**: 스킬 14 + SessionStart 훅 1(메타 스킬 전문을 additionalContext로 주입), 커맨드 0. 강제는 전부 프롬프트 규범 — 게이트 훅 없음. 서브에이전트 면제는 주입 텍스트 안의 조건 분기(`<SUBAGENT-STOP>`).
- **ECC**: 초대형 다훅 관찰 모델(모든 툴콜 관찰→instinct 추출) — async:true로 완화하지만 무겁다.
- **karanb192**: 훅 1개=플러그인 1개 원자화. session-logger는 **Stop이 아니라 SessionEnd** 사용(Stop은 매 턴 발화라서), PostToolUse는 async:true 지연 0.
- **dev-journal**: v2와 가장 유사한 조각 저널(일별 순번 — 우리는 순번 無가 차이). `/journal init`이 디렉터리+가이드+CLAUDE.md 한 줄 스캐폴딩, "디렉터리 존재=opt-in 감지".

## 네이티브 기능·스펙 (공식 문서, v2.1.217+ 기준)

- **Stop 훅 입력**: `stop_hook_active`(이번 턴 이미 차단됨 표시 — **true면 즉시 exit 0 필수**, 아니면 8연속 차단 캐스케이드), `last_assistant_message`, `stop_reason`. **파일 변경 목록은 없음** → `git status --porcelain`이 공식적 우회.
- **훅 타입**: command(로컬, 무료, 기본 600s) / prompt(발동마다 Haiku 1콜, 30s) / agent(실험). prompt형 출력은 `{ok, reason}`, command형 차단은 stdout JSON `{"decision":"block","reason":…}`.
- **⚠️ 플러그인 배포 훅에서 exit 2 오동작 보고**(anthropics/claude-code#10412) — 마켓플레이스 훅의 차단은 exit 2가 아니라 stdout JSON으로.
- transcript_path 파싱은 비동기 기록이라 현재 턴 누락 가능 — `last_assistant_message` 사용, 파싱 실패는 무조건 통과(fail-open; claude-mem #1460 피드백 루프 실사고).
- 플러그인 훅은 프로젝트별 opt-out 불가 — 스크립트 내 파일 감지 필터가 정답(현행 hk SessionStart 방식).
- 네이티브 auto-memory(머신 로컬, `~/.claude/projects/…/memory/MEMORY.md`, 200줄/25KB 제한)는 repo 루트 MEMORY.md와 **별개 파일** — 이름만 같음. 우리는 git 쪽만 쓴다(사용자 결정 기존과 일치).
- 템플릿 배포 관례: 플러그인에 커밋 + `${CLAUDE_PLUGIN_ROOT}` 참조(캐시 경로가 버전마다 바뀌므로 하드코딩 금지), 영속 상태는 `${CLAUDE_PLUGIN_DATA}`.

## 훅 구현 기술 (실전 패턴)

- **하이브리드 게이트가 정석**: command 프리필터(stop_hook_active → 컨벤션 파일 부재 → 워커 마커 → git 변경 0 → 기록 파일 mtime 갱신됨 순으로 조기 exit 0) 후 잔여 턴만 LLM 판정 — 미사용 프로젝트·무변경 턴의 API 콜이 0이 된다. 현행 hk Stop은 이 판단 전부를 매 턴 Haiku에 맡기는 중.
- 같은 이벤트의 훅 여러 개는 단락 체이닝 없이 둘 다 돈다 — 프리필터+판정은 한 스크립트가 조건부 `claude -p`를 부르는 구조로.
- 타임아웃된 훅은 차단 못 하고 통과 — 게이트 스크립트는 빠르고 fail-open으로, timeout 명시(10~30s).
- **워커 감지**: ORCA_* env는 리드도 갖고 있어 판별 불가. 결정적 방법 = 리드가 프로비저닝 때 워커 워크트리에 **마커 파일**(예: `.hk/worker`) 생성 → 훅이 `[ -f ]` 1ms 판별. 프롬프트 조건("브리프가 금지함")은 백업으로.
