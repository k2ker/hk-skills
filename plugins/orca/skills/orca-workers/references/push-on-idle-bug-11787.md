# Orca #11787 — `worker_done` 자동 알림이 안 오는 문제 (1.4.162+)

> 조사·실측: 2026-08-01. 이슈가 닫히고 Orca를 업데이트하면 이 문서와 아래 예외 규칙을 **되돌려야 한다**.

## 한 줄 요약

`orca-workers`의 핵심 전제인 **"`worker_done`은 자동 알림으로 온다"가 Orca 1.4.162+에서 깨졌다.** 스킬 문제가 아니라 Orca 쪽 회귀이며, 그동안은 `check --wait` 폴링으로 받아야 한다.

## 증상

리드(코디네이터) 세션에 `--- Orchestration Messages (N) ---` 블록이 더 이상 주입되지 않는다. 워커는 정상적으로 일하고 `worker_done`도 정상 전송하지만 리드가 영원히 모른다. `orca orchestration inbox`로 보면 메시지는 멀쩡히 쌓여 있고 `delivered_at`만 계속 `null`이다.

## 원인

[stablyai/orca#11787](https://github.com/stablyai/orca/issues/11787) — *"orchestration: push-on-idle only covers terminal-handle mail"*

자동 주입 기능(push-on-idle, `deliverPendingMessages`)의 조회 쿼리가 **터미널 핸들 앞으로 온 메일만** 본다:

```sql
WHERE to_handle = ? AND read = 0 AND delivered_at IS NULL
```

그런데 `worker_done`·`question`·`escalation` 같은 lifecycle 메일은 Run 바인딩 계약으로 넘어오면서 **`run:<runId>` 앞으로** 간다. 그래서 이 필터에 **절대 매칭되지 않고**, 영원히 배달되지 않는다.

이슈 본문:

> Run-mailbox lifecycle mail — the messages a coordinator actually waits for — is never pushed, so coordinators must still run blocking `orca orchestration check --wait` loops.

[공식 문서](https://www.onorca.dev/docs/cli/orchestration)도 같은 입장이다:

> There is no automatic injection into the agent pane — coordinators must actively poll for messages using the check command.

- **영향 버전**: Orca 1.4.162+ (macOS)
- **상태**: 2026-08-02 기준 여전히 **Open**. 수정 PR [#11857](https://github.com/stablyai/orca/pull/11857) *"fix(orchestration): deliver Run mailbox messages to current coordinators"* 도 **Open(미머지)**
- **1.4.164~1.4.168에도 이 수정은 없다.** 2026-08-05에 1.4.168로 올린 뒤 **앱 재시작 이후 새로 띄운 Claude 세션에서** 재현 확인(구세션 탓이 아님). 버전만 보고 "고쳐졌겠지" 하지 말 것 — 릴리스가 하루 서너 번 나가지만 이 수정은 별개다
- **1.4.168 정본 가이드도 방향은 그대로다** — `orca skills get orchestration`에 여전히 *"use `check --wait --types worker_done,escalation,question` instead of sleep/poll loops … keep using rolling waits"*. 즉 폴링이 정식이라는 입장은 변함없다
- **머지 여부 확인 포인트**: PR #11857은 `getUndeliveredUnreadMessages` 쿼리에 runs 테이블 `LEFT JOIN` + OR 조건을 넣어, 터미널 핸들 직접 수신 **또는** run mailbox의 현재 코디네이터가 요청 핸들과 일치하면 배달되도록 고친다. 이게 들어간 버전부터 자동 주입이 복구된다
- **발생 시점**: 이 머신에서는 `ShipIt` 업데이터가 2026-08-01 13:42:02에 업데이트를 적용한 직후부터

## 실측 결과

| 경로 | 상태 |
|---|---|
| **push** (pane 자동 주입) | ❌ 죽음 |
| **pull** (`check` / `check --wait` / `inbox`) | ✅ 정상 |

완전한 조건(Run 바인딩 + 실제 `task-create` + 실제 `dispatch` + 워커 터미널에서 보낸 거부되지 않은 `worker_done`)을 갖춰도 주입은 오지 않았고, 같은 메시지가 `check --wait`에서는 한 배치로 전부 수신됐다.

**긴 작업 실측** — 45초짜리 작업을 워커에 디스패치하고 리드가 블로킹 대기한 결과, **지연 0초로 정확히 완료 시점에 깨어났다**:

```
워커   START 20:47:01  →  WORKDONE 20:47:46   (45초 작업)
리드   WAIT_START 20:47:23 →  WAIT_END 20:47:46   ← 동시 수신
       delivery_a60acea64416 · "LONGTASK 완료" · worker_done · count 1
```

즉 `check --wait`은 sleep이나 폴링 루프 없이 `worker_done` 도착 즉시 반환된다. 장시간 작업 supervision에 그대로 쓸 수 있다.

## 우회책

```bash
# 1회차 — 가장 오래된 미확인 배치를 받는다
orca orchestration check --wait --types worker_done,escalation,question --timeout-ms 600000

# 2회차부터 — 반드시 직전 배치를 ack하면서 다음을 기다린다 (ack + check + wait 한 번에)
orca orchestration check --ack <deliveryId> --wait --types worker_done,escalation,question --timeout-ms 600000
```

이슈가 제시한 공식 우회책이자, Orca가 번들한 최신 orchestration 가이드의 supervision 표준이다(`orca skills get orchestration` 참고). 타임아웃이나 `{count:0}`은 실패가 아니라 체크포인트이므로 롤링으로 계속 대기한다.

> 🔴 **`--ack`를 빠뜨리면 같은 배치가 무한 replay된다.** `check`는 **가장 오래된 미확인 Delivery 하나**만 돌려주고, `--ack <deliveryId>` 전까지 **그 배치를 계속 반복**한다. 실측: 4건짜리 배치를 ack 없이 `--wait`으로 다시 받으면 새로 도착한 `worker_done`이 있어도 **똑같은 4건만** 나온다(`deliveryId`가 동일). 직전 `deliveryId`로 ack하자 곧바로 다음 배치(`count: 1`, 새 `worker_done`)가 수신됐다. 즉 **대기 루프에서 ack를 빠뜨리면 워커 완료를 영원히 못 본다** — 자동 주입이 죽은 것과 증상이 똑같아 오진하기 쉽다.
>
> 참고로 메시지의 `read` 플래그가 0으로 남아 있는 것도 정상이다. 읽음 처리는 `check` 호출이 아니라 **`--ack` 시점**에 일어난다.

## ⚠️ 이 번들과의 충돌 (2026-08-05 해소됨)

> **해소:** orca 0.4.0에서 `check --wait` 차단 훅을 **삭제**하고, SKILL.md를 **백그라운드 `check --wait` + `--ack` 롤링 수신**으로 리팩토링했다. 아래는 그 이전 상태의 기록이다. #11787이 닫혀 자동 주입이 복구되더라도 백그라운드 wait 방식은 그대로 유효하다(이중화 — 한쪽이 죽어도 다른 쪽이 받는다).

이 버그가 열려 있는 동안, 이 번들의 다음 둘이 **정반대 전제**로 동작해 수신 경로를 **0개**로 만들었다:

- `SKILL.md` 핵심 원칙(구) — *"블로킹 대기 절대 금지 (알림 자동)"*
- `plugins/orca/hooks/hooks.json`(삭제됨) — `orca orchestration check ... --wait`를 **하드 deny**하는 PreToolUse 훅

실제로 이 훅은 진단 중 `check --wait` 실행을 차단했다. 자동 주입이 죽은 상태에서 유일한 대안까지 막히므로, 이슈가 닫힐 때까지는 훅을 완화하고 SKILL.md에 예외를 명시해야 한다.

### 2세션 실전 재현 (2026-08-05, Orca 1.4.168)

코디네이터 세션 + 워커 세션을 각각 Claude로 띄우고 `dispatch --inject` 정석 흐름을 그대로 돌린 결과:

| 단계 | 결과 |
|---|---|
| 워커: 작업 수행 + `worker_done` 전송 | ✅ 정상 (`"plugins 번들 4개: dev, hk, orca, vendor"`) |
| 자동 주입으로 코디네이터에 전달 | ❌ 안 옴 (#11787) |
| 코디네이터: `check --wait` 시도 | ❌ **훅이 deny** |
| **최종: 코디네이터의 완료 수신** | ❌ **실패** |

코디네이터 화면에 그대로 찍힌 차단 로그:

```
⏺ Bash(orca orchestration check --wait --types worker_done,escalation,question --timeout-ms 180000 --json)
  ⎿  Error: check --wait 블로킹 대기 금지 — worker_done·백그라운드 완료는 자동 알림으로 온다…
```

훅을 해제하고 같은 시나리오를 다시 돌리자 **코디네이터가 `check --wait`으로 `worker_done`을 정상 수신했다**(`"최근 커밋 5개 해시 나열 완료"` — 워커가 보낸 subject와 일치). 훅 유무만 바꾼 A/B 대조로, 차단이 원인임이 확정됐다.

> ⚠️ **훅을 고칠 때 반드시 알아야 할 것 — 실행되는 파일은 이 repo가 아니다.**
> 플러그인 훅은 `~/.claude/plugins/cache/hk-skills/orca/<version>/hooks/hooks.json`(GitHub에서 받아온 캐시본)에서 실행된다. 이 repo의 `plugins/orca/hooks/hooks.json`은 **배포 원본일 뿐**이라, 그것만 고치면 **아무 효과가 없다**(실제로 비워봐도 차단이 계속됐다). 정식 반영 경로는 **repo 수정 → 커밋 → 푸시 → `/plugin marketplace update hk-skills` → 새 세션**이다. 캐시본을 직접 고치는 건 진단용 임시 조치일 뿐이며 다음 marketplace update 때 덮어써진다.
> 또한 **훅 설정은 세션 시작 시 로드되어 캐시된다** — 파일을 바꿔도 이미 떠 있는 세션에는 반영되지 않으니, 검증하려면 반드시 세션을 새로 띄워야 한다.

**핵심: 워커는 멀쩡히 일을 끝내고 보고까지 했는데 리드가 그걸 받을 방법이 전부 막혀 있었다.** 진단 과정에서 성공했던 `--wait` 테스트들은 사람이 셸 스크립트로 훅을 우회했기 때문이고, **실제 에이전트는 그 우회를 안정적으로 해내지 못한다** — 이 코디네이터도 "훅에 차단됐다, 스크립트로 우회한다"까지 판단하고도 결국 수신에 실패했다. 훅을 고치지 않으면 이 스킬의 워크플로는 실전에서 성립하지 않는다.

## 헛다리 (전부 실측으로 배제 — 다시 의심하지 말 것)

- **코디네이터의 `check`/`--ack` 폴링이 알림을 먼저 소비해서** → `check`를 **한 번도 안 돌린** 상태에서도 재현된다.
- **로컬 `orca-cli`·`orchestration` 스킬이 낡아서** → 둘 다 의도적 **discovery stub**이다("kept out of this file on purpose so it can never drift from the binary"). 명령 정본은 `orca skills get <name>`이 실행 바이너리에서 서빙하므로, stub을 `grep`해 명령이 없다고 stale 판정하면 틀린다.
- **런타임과 CLI의 버전 불일치** → `orca status --json`의 `runtime.appVersion`이 진짜 값이고 번들과 일치한다. 터미널 env의 `ORCA_APP_VERSION`은 런타임의 실제 버전이 **아니므로** 근거로 쓰면 안 된다.
- **Run 바인딩·pane key·터미널 핸들 문제** → `run-show`의 `coordinator_handle`/`coordinator_pane_key`가 `terminal show`의 `handle`/`tabId`/`leafId`와 일치하고 `connected`·`writable`도 true.
- **훅이 앱에 도달 못 해서** → `~/.orca/agent-hooks/claude-hook.sh`를 그대로 재현해 POST하면 **HTTP 204**. 이 훅은 메일을 꺼내는 주체가 아니라 "이 pane이 턴 경계다"라는 신호일 뿐이고, 출력을 `>/dev/null`로 버리고 항상 `exit 0`이라 실패해도 조용히 묻힌다.
- **앱을 재시작하면 해결** → 재시작해도 동일.
- **세션이 낡아서** → 재시작 **이후** 새로 띄운 Claude 세션에서도 동일.

## 전체 워크플로 실전 테스트 (2026-08-05, 리팩토링된 스킬 기준)

병렬 2워커(각자 워크트리 + 브리프 파일 + `dispatch --inject`) + 무보고 exit + 불량 worker_done 시나리오를 실측한 결과:

| 시나리오 | 결과 |
|---|---|
| 워커 B: 정상 완료 → 백그라운드 `--wait` 수신 | ✅ 즉시 수신, `--ack` 롤링 정상 |
| 워커 A: 정상 완료 → **대기 공백에 도착** | ⚠️ **배달 유실** (아래) |
| 무보고 exit 워커 | task `ready` 잔존, 수신기 안 깨어남 → 리드 직접 수확으로 해결 (스킬 규정대로) |
| 불량 worker_done (바인딩·dispatch 없는 터미널) | `run_required` 에러로 **진입 자체 거부** |
| 불량 worker_done (컨텍스트 있고 id 불량) | `Rejected …` 접두어로 적재만, task 완료 마킹 안 됨 |

**추가 발견 ① — 대기 공백(no-waiter window) 배달 유실.** 직전 `--wait`이 타임아웃으로 죽고 다음 `--wait`을 걸기 전 공백에 도착한 `worker_done`이, 이후 어떤 `check`/`check --wait`에도 잡히지 않았다(메시지는 mailbox에 `read: 1`·미ack로 존재, task는 `completed`로 정산됨 — lifecycle 처리와 코디네이터 배달이 분리돼 있고 후자만 유실). 1회 관측이라 재현 조건은 미확정. **완화: ① 배치 처리 즉시 다음 `--wait`을 걸어 공백을 최소화(가능하면 디스패치 전에 미리 가동) ② 타임아웃 체크포인트에서 `task-list`를 확인 — 메일을 못 받았는데 task가 `completed`면 배달 유실로 간주하고 `inbox`로 존재 확인 후 워커에게 파일 보고를 요청해 수확.** 후속 라운드에서 수신기를 디스패치 **전에** 가동하자 유실 없이 즉시 수신됨(worker_done 전송 시각 = 수신 시각) — 공백 가설과 부합.

**추가 발견 ② — 동시 도착은 한 Delivery로 묶인다 (6병렬 스트레스 실측).** 워커 6개(워크트리 3 + 형제 세션 3)를 일괄 디스패치하자 7초 안에 도착한 5건이 **한 배치(count: 5)**로 병합돼 왔다. `--ack`는 배치 단위이므로 **배치 안의 모든 메시지를 처리한 뒤 ack해야 한다** — 첫 건만 처리하고 ack하면 나머지가 처리 누락된 채 소비된다. 수신기 사전 가동 + 즉시 재대기 롤링으로 6/6 유실 0, task 전부 `completed`, 워크트리 오염 0.

**추가 발견 ③ — 워커 세션도 사용자 레벨 플러그인 훅을 상속한다.** 워커로 띄운 Claude 세션에 이 마켓플레이스의 훅(예: hk 번들의 Stop 기록 강제 훅)이 그대로 걸린다. 워커의 턴 종료가 훅에 붙잡혀 완료 보고가 늦어지거나 브리프 밖 행동(기록 파일 생성 등)을 유발할 수 있다 — 브리프에 "추가 작업 금지"를 명시하고, 워커 완료가 유난히 늦으면 훅 개입을 의심하라.

## 진단할 때 주의

- **진단 중에는 `--peek`를 쓸 것.** `--peek`는 미읽음 메시지를 마킹 없이 보여줘서 배달 상태(`delivered_at`)를 관찰하기에 안전하다. 실제 소비·읽음 처리는 `--ack` 시점이다(일반 `check`는 배치를 반환만 하고 ack 전까지 replay한다).
- **코디네이터 터미널은 자기 Run에만 쓰기 가능**하다(`consumer_fenced`). 남의 Run에는 `task-create`를 할 수 없으니 그 세션에 위임해야 한다.
- `worker_done`은 `taskId`와 `dispatchId`가 **둘 다** 있어야 거부되지 않는다(없으면 `Rejected worker_done: …`으로 mailbox에 남는다).
