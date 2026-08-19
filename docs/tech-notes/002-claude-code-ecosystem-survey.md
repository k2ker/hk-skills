# 002 — Claude Code 생태계 서베이: 훅·스킬·커맨드·플러그인 (2026-08-19)

6개 렌즈 병렬 서칭(skills.sh 리더보드+CLI · GitHub awesome/트렌딩 · Reddit · 훅 특화 · 플러그인 마켓플레이스 · 유틸성 셋업 도구), 후보 48건 → 교차 검증으로 압축. 설치수·스타·활동일은 2026-08-19 실측.

## 종합 결론

1. **최대 공백은 "방법론 스킬"** — 보유 26개가 전부 라이브러리 레퍼런스 계열. 계획 반문·체계적 디버깅·완료 전 검증 같은 프로세스 스킬이 비어 있고, 생태계 최상위 인기 스킬들이 정확히 이 영역.
2. **훅은 "병렬 워커 안전망" 방향이 우리 워크플로와 맞음** — 위험 명령 차단, 테스트 무력화 방지, 시크릿 보호, 자동 포맷. Orca 병렬 세션이 많을수록 배수 효과.
3. **플러그인 미사용 영역 = MCP 동봉·CI 검증·LSP** — enable 시 자동 적용되는 네이티브 능력의 절반만 쓰는 중.

## ① /vendor:add 후보 (스킬)

| 스킬 | 출처 | 근거 | 왜 |
|---|---|---|---|
| `grill-me` | mattpocock/skills | 리더보드 2위 895K installs + Reddit 열광(160↑ 스레드) | 구현 전 요구사항을 한 질문씩 캐물어 방향 착오 차단. planning-quick spec 단계 앞단 보강 |
| `systematic-debugging` | obra/superpowers | 229K installs, 2개 렌즈 교차 | 재현→격리→원인→검증 디버깅 절차. 워커 에스컬레이션 전 자가진단으로도 |
| `verification-before-completion` | obra/superpowers | superpowers 273K★ | "다 했다" 선언 전 실동작 검증 강제 — worker_done 허위 보고 감소 |
| `tdd` | mattpocock/skills | 709K installs | red-green-refactor 프로세스 (Vitest/Playwright 스킬은 도구 지식이라 비중복) |
| `accessibility` / `performance` | addyosmani/web-quality-skills | 45K/30K, Chrome 팀 | a11y·Web Vitals 공백 영역 (playwright a11y는 테스트 단계만 커버) |
| `security-review` | Sentry 공식 | 5개 보안 스킬 실측 비교 1위(timonweb), 926★지만 공식 | 데이터 플로우 추적 + confidence 판정, false positive 억제 |
| `documentation-and-adrs` | addyosmani/agent-skills | 24K | 우리 DECISIONS.md 컨벤션과 직결(ADR 포맷) |
| `git-workflow-and-versioning` | addyosmani/agent-skills | 21.5K, 카테고리 1위 | 멀티 워크트리 커밋 규율 일관성 |

- superpowers·GSD·ECC 같은 대형 프레임워크는 **통설치 비권장**(Reddit 합의: bloated, 체리픽이 정설) — planning-quick·orca-workers와 겹침. 개별 스킬만 위 표처럼 발췌.

## ② hk 번들 훅/커맨드 아이디어

| 아이디어 | 참고 구현 | 비고 |
|---|---|---|
| PostToolUse 자동 포맷(prettier/eslint) | 공식 문서 정석 패턴 | 가장 쉬움. Turborepo면 파일 경로 기준 해당 워크스페이스만 |
| 위험 명령 차단 + 시크릿 보호 | karanb192/claude-code-hooks(478★·활발), claude-guardrails(UserPromptSubmit 시크릿 스캐너) | 병렬 워커 안전망. .env에 Supabase/Vercel 토큰 있는 스택에 유효 |
| protect-tests (fake green 방지) | karanb192 | 워커가 테스트 삭제/skip으로 가짜 GREEN 만드는 것 차단 |
| instructions-audit | karanb192 | **vendor 재배포 마켓 운영자에게 특히 적합** — /vendor:add 수확물의 숨은 지시(유니코드·인젝션) 검사. /vendor:add 절차에 편입 후보 |
| TDD 게이트 | tdd-guard(2.3K★, Vitest 리포터) / probity(동저자, **Codex까지 지원**·병렬 세션 안전) | Codex 병용이라 probity가 구조상 맞음 |
| 실수 원장(MISTAKES.md) | Reddit 합의 패턴(43↑) | 제로 설치 — Stop 기록 훅에 항목 하나 추가로 편입 |
| 알림 | claude-notifications-go(790★) | 멀티 세션 입력 대기 알림 + 클릭-투-포커스 |
| `/hk:doctor` | 생태계에 doctor 전용 부재(틈새) | githooks 활성화·파생 드리프트·**캐시본 스테일** 검출 (자작) |
| 훅 설계 레퍼런스 | disler/claude-code-hooks-mastery(3.9K★) | 13개 이벤트 입출력 패턴 견본 (설치물 아님) |

## ③ 마켓플레이스/플러그인 개선

- **MCP 동봉**: 플러그인 `.mcp.json` → enable 시 자동 기동. `userConfig`(민감값 키체인)+`${CLAUDE_PLUGIN_ROOT}` 조합이 공식 패턴(Supabase 플러그인이 대표 사례). **동봉 1순위 후보 = Context7**(348K installs) — 벤더 스킬 스냅샷의 버전 드리프트를 라이브 문서 조회로 보완.
- **CI 이중화**: ivan-magda/claude-code-plugin-template(65★, 구조 참고용) — push/PR마다 sync 검증하는 GitHub Actions. **훅 안 켠 클론에서 커밋된 드리프트를 CI가 잡는 보완 레이어.**
- **typescript-lsp 플러그인**(공식): 실시간 타입 진단 — typescript-advanced-types(지식)와 비중복, 2026 리뷰들 1순위 추천.
- **codex-plugin-cc**(OpenAI 공식): 세션 안에서 Codex 크로스리뷰/위임 — 워크트리 분리 없는 저비용 보완재(Reddit 745↑ 스레드 최상위 추천).
- 공식 마켓 구조 벤치마킹: 플러그인 이름 불변+renames 맵, 내부/외부 디렉터리 분리, `${CLAUDE_PLUGIN_DATA}` 셋업 패턴. wshobson/agents의 "SSOT→멀티하니스 파생"은 Codex 확장 시 선행 사례.
- 참고: statusline은 플러그인 컴포넌트가 아님(settings.json 진입) — ccstatusline(12K★)·ccusage(18K★)가 정석. caveman(출력 토큰 절감, 실측 4-10%)은 마케팅 수치(75%)와 갭 인지하고 판단.

## 네이티브 플러그인 배포물 범위 (공식 plugins-reference)

skills · commands · agents · hooks(30여 이벤트) · **MCP servers** · LSP · output styles · workflows (+실험: themes/monitors/channels). enable 시 `userConfig` 프롬프트(키체인), lockfile 자동 `npm ci`, SessionStart+`${CLAUDE_PLUGIN_DATA}` 셋업 패턴, `bin/` PATH, 플러그인 간 semver 의존성.

## 관련 결정·후속

- 도입 우선순위·선정은 사용자 결정 대기 (이 노트는 후보 원장)
- 기존 아이디어 3종(MCP 동봉 / hk-doctor / vendor SHA 기록)은 본 서베이로 근거 보강됨 — DECISIONS 등재는 착수 결정 시
