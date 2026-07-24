---
description: 외부 스킬을 plugins/vendor/에 넣는다 — skills add로 받아 폴더를 옮기고 sync. 인자로 소스 (예 shadcn-ui/ui shadcn).
---

# /vendor:add — 외부 스킬 넣기

`skills add`로 받은 폴더를 `plugins/vendor/skills/`로 옮기면 끝. 그러면 hk-skills(플러그인)가 그 스킬을 나눠준다.

**인자:** `<owner>/<repo>` + 스킬 이름.

1. **받기** — `DISABLE_TELEMETRY=1 npx skills add <owner>/<repo> --skill <이름> --copy -a claude-code -y` → `.claude/skills/<이름>/`에 생김.
2. **옮기기** — 그 폴더를 `plugins/vendor/skills/<이름>/`로 이동. (vendor 번들이 처음이면 `plugins/vendor/.claude-plugin/plugin.json`도 만든다: `{"name":"vendor","version":"0.1.0","description":"외부 벤더 스킬","author":{"name":"hk"}}`)
3. **sync + 커밋** — `node scripts/sync-marketplace.mjs --fix` 통과하면 커밋.

참고:
- frontmatter `name`은 폴더명과 같아야 한다(다르면 sync가 막음).
- `orca-cli`·`supabase`·`skill-creator`처럼 **다른 플러그인이 이미 주는 스킬은 넣지 마라**(중복).
