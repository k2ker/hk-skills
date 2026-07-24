---
description: 벤더 스킬을 지운다 — 폴더 삭제 후 sync. 인자로 스킬 이름.
---

# /vendor:remove — 벤더 스킬 삭제

1. `plugins/vendor/skills/<이름>/` 삭제.
2. `node scripts/sync-marketplace.mjs --fix` → 커밋.
3. 벤더 스킬이 하나도 안 남으면 `plugins/vendor` 번들도 지울지 판단.
