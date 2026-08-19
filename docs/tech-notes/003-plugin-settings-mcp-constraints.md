# 003 — Claude Code 플러그인의 settings/MCP 배포 제약 (2026-08-19)

"플러그인에 settings.json을 동봉해 권한까지 배포할 수 있나?"를 공식 문서(plugins-reference·plugins·settings)로 확인한 결과. hk 번들 MCP 동봉 설계의 근거.

## 확인된 사실

- **플러그인 settings.json은 껍데기만 지원** — 플러그인 루트의 `settings.json`은 공식 지원이지만 현재 반영 필드는 `agent`·`subagentStatusLine` 2개뿐. `permissions`(allowlist)·`env`·`statusLine`·`model`·`outputStyle`은 **미지원 — 실어도 무시됨**. "enable = 권한 설정 완성"은 현 구조상 불가.
- **MCP 배포는 `.mcp.json`이 정식 유일 경로** — `plugin.json`의 `mcpServers` 필드는 인라인 정의 불가, `"./.mcp.json"` 파일 경로 지정만. enable 시 자동 기동, disable 시 제거, 민감값은 `userConfig`(키체인) + `${user_config.KEY}` 치환.
- **settings류(권한 allowlist 등)의 PC 간 전파 공식 답** = 각 프로젝트의 커밋된 `.claude/settings.json` (이 repo의 그 파일이 정확히 이 역할). SessionStart 훅이 settings.json을 고쳐 쓰는 커뮤니티 우회는 실패 시 미적용·동시 세션 경쟁·파일 오염 리스크 — statusline처럼 다른 수가 없는 경우 외 비권장.
- 컴포넌트 전체 목록: skills · commands(레거시) · agents · hooks · mcpServers(경로) · lspServers · experimental.monitors/themes. settings류 없음.

## 함의

- MCP 동봉 아이디어([[002]] ③)는 `.mcp.json` 경로로 진행하면 됨 — 제약 아님.
- 권한 allowlist 배포 욕구는 플러그인이 아니라 **소비 프로젝트의 settings.json 템플릿**(스캐폴딩 커맨드/doctor에서 안내)으로 풀 것.
