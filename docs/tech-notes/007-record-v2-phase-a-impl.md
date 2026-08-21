# 007 — record 컨벤션 v2 Phase A 구현 (2026-08-21)

Phase A 산출물 5종 구현 + Codex 2라운드 교차 리뷰 + 수정 완료. **미커밋 — 사용자 승인 대기.** 사실만 기록.

## 산출물

`record` 스킬(컨벤션 정본) · `/hk:record:init`(preflight → scaffold, 멱등) · `/hk:record:migrate`(시작 상태 A/B/C 감지 전면 이관) · `hooks/record-gate.sh`(Stop 하이브리드 게이트) · `templates/` 3종. hk 0.16.0 · orca 0.4.6(워커 마커 규약).

## 설계 결정 (구현에 박힌 것)

- 게이트 = 프리필터 6단(재귀 가드 → 의존성 검사 → stop_hook_active → 컨벤션 감지(루트 해석: CLAUDE_PROJECT_DIR→git toplevel→cwd) → git-dir 워커 마커 → 변경 0/기록 touched) 후 잔여만 중첩 Haiku 판정. 차단은 stdout JSON(플러그인 exit 2 버그 #10412 회피), **모든 오류·타임아웃 fail-open**.
- **워커 마커 = git 메타데이터 단일화**(`--absolute-git-dir`/hk-worker) — 커밋 불가능·워크트리별 격리 실증. 작업 트리 파일 마커(.hk/worker)는 커밋 오염 경로라 미지원.
- v1/v2 이중 지원 — v1 프로젝트엔 v1 방식 사유로 안내, v2 강요 안 함(전환은 사용자가 migrate로).
- 중첩 판정 격리: `RECORD_GATE_INNER` env 가드 + `--max-turns 1` + `--strict-mcp-config` + `--disallowedTools`. 지시문은 위치 인자가 아니라 **stdin에 합침** — `--disallowedTools`가 가변 인자라 뒤 위치 인자를 삼키는 실측 사고.

## 검증

단위 테스트(프리필터 6단·차단 JSON·fail-open·워크트리 마커 격리·v1 분기) 전부 GREEN, 프리필터 ~60ms. 라이브 중첩 판정 정상(일단락→차단, mid-work→통과). plugin validate·sync 통과.

## Codex 리뷰 결산

1차 NEEDS_FIX 11건 → 수정. 2차: 8건 RESOLVED + 잔여·신규 5건 수정(폴백 마커 제거, init preflight 순서, python3/git 의존 명시, untracked 원본 선보존, SSOT 문구). **수용 한계 2건**(코드 주석 명시): ① 중첩 판정 세션의 타 플러그인 훅까지 완전 격리 안 함 — 게이트는 넛지, 실패는 전부 통과 방향 ② 직전 기록 파일 미커밋 동안 게이트 휴면(freshness 창). 리뷰가 잡은 실전 사고 2건: 상대 git-dir 마커가 엉뚱한 repo에 박힘(재현·정리 완료) / --disallowedTools 프롬프트 삼킴.

## 다음

커밋·푸시 승인 → marketplace update → 새 세션 E2E 4시나리오(미사용 침묵/사용 게이트/init/마커 면제) → Phase B(hk-skills 이관).

## 후속절 1 — 배포·E2E 실측 (2026-08-21, 커밋 7300ab6 → 캐시 hk 0.16.0·orca 0.4.6)

- **캐시본 게이트 3종**: 미사용 침묵 · 차단 JSON · git-dir 마커 면제 — 전부 정상 (실행 비트 캐시 보존 확인)
- **SessionStart v2 주입**: 새 실세션이 주입 문구를 그대로 인용 ✅ / **미사용 프로젝트**: stop hooks 2개 실행에도 차단 0 + 주입 문구 부재 ✅
- **trivial 면제 실전**: hello 파일 수준 작업 → "게이트 개입 없음"(세션 파일 보고로 확인) — 판정 NO가 설계대로
- **게이트 실전 사이클**: 일단락형 메시지 턴에서 **차단 발동 확인**(중첩 Haiku 판정이 실제 Stop 훅 자식 환경에서 생존) + 세션이 "실작업 없는 지시 문구라 조각을 쓰면 허위 기록"이라며 **면제 경로로 정직 종료** — 훅 통과용 서사 거부가 게이트 문구 설계대로 작동
- **미실측 잔여**: init/migrate 커맨드의 실전 실행 — Phase B(hk-skills 자체 이관)가 곧 그 실전 테스트를 겸한다
- 부수 확인: 폴더 신뢰 다이얼로그가 `blockedReason: codex-trust-workspace`로 감지됨(승인 다이얼로그 감지 체계의 실전 첫 작동, tech-note 참조: orca-workers references)
