# AGENTS.md

이 저장소의 에이전트 가이드 **정본(SSOT)은 [`CLAUDE.md`](./CLAUDE.md)** 다.

Codex · Cursor · 그 밖에 `AGENTS.md`를 읽는 모든 툴은 이 파일을 진입점으로 삼되, 실제 규칙·구조·워크플로우는 `CLAUDE.md`를 그대로 따른다. 내용을 여기에 복제하지 마라 — 문서 두 벌이 갈라진다(드리프트). 규칙을 바꿀 일이 있으면 `CLAUDE.md` 한 곳만 고친다.

## 왜 이 repo는 툴 이름을 갈아끼우면 안 되는가

`hk-skills`는 **Claude Code 플러그인 마켓플레이스** 규격 그 자체다. `.claude-plugin/marketplace.json`, `enabledPlugins`, `/plugin marketplace update` 같은 경로·명령은 Claude Code 전용 리터럴이며, 다른 툴 이름으로 치환하면 **거짓 경로**가 된다. `AGENTS.md`를 읽는 툴이라도 이 저장소를 다룰 때의 사실관계(경로·매니페스트·동기화 스크립트)는 Claude Code 기준 그대로 유효하다.

→ **[`CLAUDE.md`](./CLAUDE.md) 를 읽어라.**
