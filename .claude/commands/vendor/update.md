---
description: 벤더 스킬을 새로 받아 덮어쓴다 (plugins/는 skills update가 안 닿음). 인자로 스킬 이름.
---

# /vendor:update — 벤더 스킬 갱신

`plugins/`에 있는 건 `skills update`가 못 닿는다 → 다시 받아 덮어쓴다.

1. `/vendor:add`처럼 다시 받는다.
2. `plugins/vendor/skills/<이름>/`에 덮어쓴다.
3. `node scripts/sync-marketplace.mjs --fix` → 커밋.
