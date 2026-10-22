---
name: orca-workers
description: "Use whenever work is split across parallel Orca worker agents in sub-worktrees and this session supervises them: provisioning worktrees, writing briefs, dispatching, cross-model review (Claude ↔ Codex), fix loop, and landing. Trigger on: Orca orchestration, worker, sub-worktree, worker_done, 병렬 워커, 교차 리뷰, 디스패치 — even if the user does not say 'orchestration'. Orca's own orchestration/orca-cli skills own the commands; this skill adds hk's house rules on top."
version: 0.5.0
author: hk
license: MIT
---

# Orca 워커 병렬 작업 — hk 규칙

명령·대기 루프·워커 정리는 **Orca 정본**이 맡는다. 시작 전에 `orca skills get orchestration`과 `orca skills get orca-cli`를 읽고 그대로 따른다(기억으로 명령을 추측하지 않는다 — 버전마다 바뀐다). 이 파일은 정본이 모르는 우리 규칙과, 정본대로 했는데 다르게 동작한 실측만 담는다.

## 투입 전 준비

- 정본대로 `run-create`로 Run을 먼저 묶는다.
- **워커당 워크트리 1개, 두 단계로.** `orca worktree create`로 먼저 만들고, deps 설치 + 베이스라인 검증(typecheck/test)을 리드가 끝낸 뒤 `worker-start --worktree <selector> --agent …`로 투입한다. 정본 기본값은 `worker-start --worktree new-child`로 한 번에 만드는 것이지만, 우리는 워커가 첫 명령을 치기 전에 베이스라인과 아래 마커가 있어야 해서 일부러 나눈다. 한 워크트리에 워커 둘은 git 인덱스·dev 서버를 공유해 반쯤 쓰인 파일로 얽힌다.
- **기록 게이트 면제 마커**: `touch "$(git -C <워커 워크트리> rev-parse --absolute-git-dir)/hk-worker"`. 워커는 기록(docs/log·MEMORY)을 쓰지 않고, 기록은 리드가 랜딩 때 한 번 한다. 반드시 `--absolute-git-dir` — 상대 경로는 리드 cwd 기준으로 풀려 엉뚱한 repo에 마커가 생긴 사고가 있다. 워크트리를 지우면 마커도 같이 사라진다.
- 파일을 전혀 안 만드는 읽기 전용 워커(정찰·검증·리뷰)는 `--worktree current`로 리드 워크트리에 띄워도 된다. 브리프에 "산출은 worker_done 본문뿐, 임시 파일도 금지"를 적는다.

## 브리프는 파일로

터미널에 장문을 붙여넣으면 이스케이프·잘림이 난다. 워커별 브리프 파일을 워크트리 **밖**(세션 scratch 등)에 쓰고 spec에는 그 경로를 준다. 브리프에 꼭 넣는 것: 역할("너는 X만"), 스코프 IN/OUT, 프로젝트 규약, 검증 명령, **커밋 금지**, 공유 계약(DTO)은 양쪽에 같은 shape, 보고 문구는 "`worker_done`을 `--outcome`과 함께 전송, 실패 시 1회 재시도, 그래도 안 되면 최종 텍스트로 완료 보고"(“정확히 한 번만”이라고만 쓰면 전송 실패 때 그냥 포기한다).

## 교차 리뷰

- **저자 ≠ 리뷰어.** 기본은 Claude 구현 → Codex 리뷰. 모델 역할을 바꾸는 건 사용자 결정이다.
- **Codex 가용성은 실제 호출로 확인한다.** `command -v codex`나 `codex login status`는 토큰이 죽어도 통과한다(실측: status는 "Logged in"인데 exec는 `401 invalid_refresh_token`). 프리플라이트: `codex exec --skip-git-repo-check -s read-only 'reply with exactly: ok'`가 exit 0이면 가용. 401이면 사용자에게 `codex login`을 요청하고, 안 되면 새 Claude 세션이 리뷰한다 — 같은 워크트리에 `worker-start --agent claude`로 띄우면 provenance가 남는다.
- 리뷰는 **저자 워크트리 in-place**에서(미커밋 diff는 다른 워크트리에서 안 보인다). Codex는 이렇게 띄운다:
  `orca terminal create --worktree <저자 wt> --title codex-review --command "codex exec --skip-git-repo-check -s read-only -C <wt> --add-dir <브리프 dir> -o <리뷰 파일> '<브리프 경로> 읽고 수행'; exit"` → `terminal wait --for exit`. 끝의 `; exit`가 없으면 codex가 끝나도 셸 프롬프트가 남아 exit 대기가 타임아웃된다(실측 240초 낭비). 산출은 파일: `file:line` findings + `verdict CLEAN|NEEDS_FIX`.
- 리드는 findings를 실측으로 대조해 오탐을 거르고, 확정분은 **같은 워커에 재투입**한다(리뷰 중엔 `worker-retain`으로 잡아 둔다). 리드가 직접 고치지 않는다(정본의 review ownership 규칙과 같다).

## 랜딩과 정리

- **커밋·푸시·배포·운영 인프라는 승인 게이트.** 브랜치별 커밋(`-F <msgfile>`) → base에 `merge --no-ff` → 전체 검증 → 실동작 확인 → push. 코드 GREEN ≠ 눌러봄 — 어디까지 확인했는지 그대로 보고한다.
- 정리까지가 사이클이다. 워커 터미널은 정본대로 `worker-release`, 워크트리는 `worktree rm`, 브리프·리뷰 파일은 삭제. 끝내기 전 `worker-list`·`worktree ps`로 잔여물 0을 확인하고, 남긴 게 있으면 무엇을 왜 남겼는지 쓴다. 중단된 사이클도 같다.
- **`worker-release`가 `retained / user_takeover`를 돌려주고 터미널을 안 닫을 수 있다**(1.4.230 실측, 재시도해도 같음, 원인 미확인). 정본은 `terminal close` 대체를 금지하므로 그대로 두고, `worktree rm --force`가 그 워크트리의 터미널까지 함께 정리하는 것으로 마무리한다. 리드 워크트리에 띄운 읽기 전용 워커는 이 경로가 없으니 release 결과를 그대로 보고한다.

## 실측 메모

- `check --wait --json`은 15초 넘게 기다리면 `{"_keepalive":true,…}` 줄이 앞에 섞인다. 마지막 JSON 객체만 파싱한다.
- `worker-start`가 "could not make it discoverable" 경고를 내도 워커는 정상 동작한다(background surface).
- 터미널은 handle로만 식별 — title은 Orca가 바꾼다(실측: 사용자가 준 제목이 `worker-<taskId>`로 바뀜). `send` 전 `read`. `worktree rm`은 브랜치도 지운다.
- 워커 침묵이 길면 승인 다이얼로그 감금일 수 있다. 다이얼로그는 메일이 아니라 `check --wait`에 안 잡힌다 → `references/approval-dialog-detection.md`. 이 머신 기본 구성(Claude bypass permissions, Codex 샌드박스 read-only)에선 재현되지 않는다.
- 미검증(2026-08 기록): Codex **구현** 워커는 `network_access=true`가 필요했다(샌드박스가 orchestration RPC를 막아 `worker_done` 불가). 1.4.230에서 재확인 전.

검증 이력: 2026-10-22 Orca 1.4.230에서 구현 워커 1 + 리뷰(Codex 401 → Claude 대체) 사이클을 맥락 없는 새 세션이 이 파일만 보고 end-to-end 완주(9분). Codex 프리플라이트·`; exit` 종료 감지는 리드가 별도 실측.
