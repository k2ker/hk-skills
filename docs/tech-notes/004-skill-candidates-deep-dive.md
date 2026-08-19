# 004 — 스킬 후보 심층 분석: SKILL.md 원문 기준 (2026-08-19)

[[002]] 서베이에서 추린 스킬 후보 11종의 **원문 지시문**을 분석. 각 스킬이 실제로 에이전트에게 뭘 시키는지, 산출물·컨텍스트 비용·우리 워크플로와의 궁합. 상세 원장은 워크플로 결과에, 여기는 결론만.

## 핵심 발견 (도입 판단에 직결)

- **grill-me는 껍데기** — 실체는 `grilling` 스킬로 리다이렉트하는 2단 구성. 세트로 가져와야 동작. 결정 트리를 "라운드" 단위 질문으로 풀어가는 방식이며, 결과를 어디에도 기록하라는 지시가 없어 우리 DECISIONS.md 연결은 별도 규칙 필요.
- **verification-before-completion이 궁합 1위** — 3.6KB 단일 파일, "fresh 증거 없이 완료 선언 금지" + **"위임 에이전트의 성공 보고를 믿지 말고 git diff로 독립 검증"** — orca-workers의 코디네이터 검수 원칙과 문자 그대로 일치. systematic-debugging이 이 스킬을 이름으로 참조하므로 둘은 세트.
- **systematic-debugging** — "원인 조사 전 수정 금지" 철칙 + 4단계 강제 + **수정 3회 실패 시 사람 에스컬레이션**. 산출물 없음, 순수 행동 프로토콜. 충돌 없음.
- **tdd** — 독창점은 "seam(테스트할 공개 경계) 사전 합의" 강제. 단 Matt Pocock 생태계 결합(CONTEXT.md·docs/adr·codebase-design/code-review 스킬 참조)이라 우리 컨벤션(tech-notes·DECISIONS.md)과 파일명이 달라 포크/별칭 조정 필요.
- **security-review(Sentry)** — 읽기 전용(Edit/Write 없음), "익스플로잇 경로 확인 후에만 보고"로 오탐 억제, 보조 문서 206KB지만 코드 타입별 선택 로드. **⚠️ Claude Code 내장 /security-review와 이름 정면 충돌** — 도입 시 트리거 모호성 처리 필요. 문서가 지시하는 go/rust/k8s 가이드 일부는 repo에 실존하지 않음(JS/TS엔 무영향).
- **accessibility/performance(Osmani)** — 규칙+수치 예산이 구체적이고 자족적. 단 기존 vendor 스킬과 트리거 겹침(playwright-best-practices의 axe, vercel-react-best-practices의 성능) — 역할 구분 필요. performance는 Next.js가 이미 자동화한 것(코드 스플리팅·폰트·이미지)을 수동 구현하지 않게 주의.
- **보조 4종**: improve-codebase-architecture(의존 스킬 최다 — codebase-design·grilling·domain-modeling 세트 필요, HTML 리포트 CDN 의존), wayfinder(이슈 트래커 결합 계획 전용 — orca-workers의 상류로는 가능하나 무겁고 12KB), documentation-and-adrs(docs/decisions/ 디렉터리 방식이 우리 DECISIONS.md 단일 파일과 충돌 위험), git-workflow-and-versioning("증분마다 커밋" 지시가 Claude Code 기본 규칙·워커 커밋 금지 브리프와 충돌 위험).

## 도입 난이도 분류

| 바로 가능 (충돌 없음) | 조정 후 가능 | 신중 |
|---|---|---|
| verification-before-completion, systematic-debugging | grill-me+grilling(기록 연결), tdd(컨벤션 별칭), security-review(내장과 이름 충돌 해소) | accessibility·performance(트리거 겹침), documentation-and-adrs, git-workflow, improve-codebase-architecture·wayfinder(의존 세트) |

도입 선정은 사용자 결정 대기.
