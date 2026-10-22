---
date: 2026-10-22
type: decision
refs: [2026-08-12-orca-reception-primary-path, 2026-08-19-hermes-retired]
---

# orca 번들 폐기 → hk 번들에 `orca-workers` 축소 이관 (0.4.5 → 0.5.0)

## 왜

Orca 1.4.230 정본(`orca skills get orchestration`)이 8월(1.4.18x) 이후 크게 바뀌어 스킬과 두 곳이 정면 충돌했다. ① 스킬 "`task-create` → `dispatch --inject`가 supervised 경로" vs 정본 "`worker-start`가 정상 경로, `dispatch --inject`는 비감독·예외용". ② 스킬 "`terminal close`로 회수" vs 정본 "`worker-release`만, `terminal close` 대체 금지". 신규 verb 8개(`worker-start/show/read/stop/abandon/release/retain/list`)가 스킬의 수신·정리·복구 서술 대부분을 대체했다.

## 결정

- 명령·루프·정리는 전부 Orca 정본에 위임하고, 스킬엔 **Orca가 모르는 hk 규칙**만 남긴다(hk-worker 마커, 2단계 워크트리 준비, 브리프 파일, Codex 교차 리뷰, 승인 게이트, 잔여물 0). 263줄 → 46줄.
- `hk-worker` 마커가 hk `record` 게이트와 짝이라 hk 번들로 옮긴다. 번들 4 → 3. 소비 프로젝트의 `enabledPlugins`에서 `orca@hk-skills`는 제거해야 한다.
- `push-on-idle-bug-11787.md` 삭제: 결론("폴링이 정식")이 정본에 있고, 경위는 8월 조각에 있다. 이슈는 여전히 open, PR #11857은 머지 없이 closed.

## 실측 (맥락 없는 새 세션이 새 SKILL.md만 보고 1사이클 완주, 9분)

- 통과: 2단계 준비, 마커 경로, 브리프 파일, `worker-start --worktree <selector>` 재사용, `check --wait` 수신(12초·29초), in-place 리뷰, `worktree rm`이 브랜치·마커·터미널까지 정리.
- 어긋남 → 스킬 반영: `command -v codex`로는 가용성 판단 불가(토큰 401인데 `login status`는 Logged in) → exec 프리플라이트. `codex exec`를 `terminal create --command`로 띄우면 셸이 남아 `wait --for exit` 타임아웃 → `; exit`. `worker-release`가 `retained/user_takeover`로 터미널을 안 닫음(원인 미확인) → `worktree rm --force`로 마무리. `check --wait --json`에 `_keepalive` 줄 섞임.
- 미검증 유지: Codex 구현 워커 `network_access=true`.

## 같은 날 벤더

25개 전수 재수확 diff 없이 덮어쓰기(사용자 지시). turborepo는 업스트림이 번들 문서 안내 26줄로 축소. 상세는 `VENDORED-SKILLS.md`.
