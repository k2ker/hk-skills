# 승인 다이얼로그 감금 감지 (실측 2026-08-12, Orca 1.4.180)

워커 TUI의 승인 다이얼로그(Codex approval, Claude 권한 프롬프트)에 워커가 붙잡히면 **리드의 `check --wait`로는 영원히 모른다** — 다이얼로그는 오케스트레이션 메일이 아니고, 워커 프로세스가 입력 대기로 멈춰 있어 아무것도 못 보낸다. 증상은 "긴 침묵"뿐이라 타임아웃 체크포인트와 구분이 필요하다.

## 감지 (기계적 — 화면 파싱 불필요)

```bash
orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 3000 --json
```

| 상태 | 응답 |
|---|---|
| 정상 idle (승인 대기 없음) | `satisfied: true`, `blockedReason` 없음 |
| **다이얼로그 감금** | `satisfied: false` + **`blockedReason: "codex-interactive-prompt"`** |

Codex `-a untrusted`에서 curl 승인 다이얼로그를 실제로 띄워 확인했다. P3의 idle 확정 조건("satisfied:true + blockedReason 없음")과 같은 필드라, 디스패치 전·체크포인트 어디서든 같은 프로브를 쓰면 된다.

## 대응

1. `terminal read`로 다이얼로그 내용(무슨 명령의 승인 요청인지)을 확인한다.
2. 필요한 것만 `terminal send`(예: `1` + Enter)로 승인한다 — **일괄 trust 금지**(기존 함정 규칙: 타 에이전트 훅까지 켜져 로그 오염).
3. 승인 불가한 요청이면 esc로 거절시키고 브리프를 보정해 재지시한다.

## 예방

**워커 기동 시 승인 정책을 미리 결정하라.** 다이얼로그가 뜨는지 자체가 워커 쪽 설정에 달려 있다:

- 이 머신 기본 구성에선 재현조차 안 됐다 — Claude는 allowlist가 넓어 Write·`rm`까지 자동 승인, Codex는 **YOLO 모드**(승인 전면 생략).
- `codex -a untrusted`처럼 승인 정책이 켜진 워커만 감금이 발생한다. 단 `echo` 같은 안전 명령은 untrusted에서도 자동 통과라, 정책이 켜져 있어도 늘 뜨는 건 아니다(재현 시 네트워크·파일 변경 명령을 쓸 것).
- 승인 정책이 켜진 워커를 의도적으로 쓸 거면, `check --wait` 타임아웃 체크포인트에 이 프로브를 포함하라.
