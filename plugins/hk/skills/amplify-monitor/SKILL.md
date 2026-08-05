---
name: amplify-monitor
description: "AWS Amplify 앱의 배포(빌드) 상태를 폴링해 완료까지 모니터링하고 결과를 요약 보고한다. /amplify-monitor 로 직접 실행하거나, 배포 파이프라인(GitHub Actions + Amplify auto-build) 검증의 Amplify 단계로 사용. 트리거: Amplify 배포 확인, 빌드 상태 체크, 배포 모니터링, amplify list-jobs, 프론트 배포가 끝났는지 확인."
user-invocable: true
version: 1.0.0
author: hk
---

# Amplify Monitor

AWS Amplify 앱의 최신 빌드 상태를 폴링해 최종 상태(성공/실패/취소)까지 추적하고 요약 보고한다. push 시 auto-build되는 Amplify 특성상, 배포 직후 "빌드가 실제로 끝났는지"를 확인하는 용도다.

## 사전 조건

- AWS CLI 설치 + 인증(`aws sts get-caller-identity`로 확인). 미설치·미인증이면 그 사실만 출력하고 중단.
- 대상 앱에 `amplify:ListJobs` 권한.

## 입력 (택 1)

```
/amplify-monitor --app-id d1234abcde[,d5678fghij] --branch prod/myapp
/amplify-monitor --env-prefix AMPLIFY_MYAPP --branch prod/myapp
```

- `--app-id` — App ID 직접 지정(쉼표로 다수). 라벨은 `App 1`, `App 2`… 자동 부여.
- `--env-prefix` — `{PREFIX}_{라벨}_ID` 패턴의 환경변수를 전부 탐색해 앱 목록을 만든다(예: `AMPLIFY_MYAPP_DOCS_ID=d1234abcde` → 라벨 `Docs`). 매칭이 없으면 "환경변수 {PREFIX}_*_ID 없음"을 출력하고 중단 — 배포 파이프라인의 하위 단계로 쓰일 땐 중단 대신 이 단계만 스킵.
- `--branch`(필수) · `--region`(기본 `ap-northeast-2`) · `--timeout`(기본 300초) · `--interval`(기본 10초).
- 인자 없이 실행하면 위 사용법을 안내한다.

## 실행 흐름

1. **인증 확인** — `aws sts get-caller-identity`.
2. **앱 목록 결정** — 입력 방식대로. env-prefix면 `env | grep "^{PREFIX}_" | grep "_ID="`.
3. **폴링** — 앱별 최신 잡 1건씩:

```bash
aws amplify list-jobs --app-id {앱ID} --branch-name "{브랜치}" --max-results 1 \
  --region {리전} \
  --query 'jobSummaries[0].{status:status,jobId:jobId,startTime:startTime,endTime:endTime,jobType:jobType}' \
  --output json
```

상태 판정: `SUCCEED`·`FAILED`·`CANCELLED`는 **최종**(해당 앱 폴링 종료), `RUNNING`·`PENDING`·`PROVISIONING`·`CANCELLING`은 대기 후 재확인. 모든 앱이 최종 상태거나 타임아웃이면 종료.

매 회차 진행 상황을 한 줄로: `[3/30] Docs: SUCCEED | Console: RUNNING`

4. **결과 요약** — 완료 후 박스 출력:

```
┌───────────────────────────────────────────────┐
│  Amplify Monitor                              │
│  Branch: prod/myapp                           │
├───────────────────────────────────────────────┤
│  Docs (d1234abcde)                            │
│  ├─ Status     ✅ SUCCEED                     │
│  ├─ Job ID     abcdef123                      │
│  ├─ Duration   2m 34s                         │
│  └─ Type       RELEASE                        │
├───────────────────────────────────────────────┤
│  Result: ✅ ALL PASS   (또는 ❌ N PASS / M FAIL) │
│  Elapsed: 2m 40s (8 polls)                    │
└───────────────────────────────────────────────┘
```

아이콘: ✅ SUCCEED · ❌ FAILED · ⏹️ CANCELLED · ⏱️ 타임아웃(최종 미도달). 하나라도 실패·취소·타임아웃이면 Result는 ❌.

## 세션을 묶지 마라

폴링 루프(기본 최대 5분)를 포그라운드로 돌리면 그동안 세션이 아무것도 못 한다. 하니스가 백그라운드 Bash를 지원하면 **폴링 스크립트를 백그라운드로 돌리고 완료 알림에 반응**하라 — 그동안 다른 검증(S3·CDN 등)을 병행할 수 있다. 배포 파이프라인 안에서 쓰일 때 특히 중요하다(GitHub Actions watch와 Amplify 폴링은 병렬이 정석 — Amplify는 push 시 auto-build라 Actions와 동시에 이미 돌고 있다).

## 함정 (실전 검증분)

- **Amplify 브랜치명엔 슬래시가 그대로 들어간다** — `prod/myapp`이지 `prod-myapp`이 아니다. `--branch-name`은 반드시 따옴표로 감싼다.
- **폴링이 잡은 잡이 "이번 배포"인지 확인** — `--max-results 1`은 최신 잡 1건이다. 방금 push했는데 `startTime`이 과거면 auto-build가 아직 잡을 안 만든 것 → 몇 회차 더 기다린다.
- **에러 후 재시도로 성공했어도 결과 요약에 ⚠️로 남긴다** — 최종 요약에서 생략하지 않는다(정직 고지).
- 여러 앱 중 하나가 먼저 FAILED로 확정돼도 **나머지 앱 폴링은 계속**한다 — 전체 그림이 요약에 필요하다.
