# Third-party notices — `orca` bundle

This bundle vendors two skills verbatim so the `orca` plugin is **standalone**
(no dependency on the user's locally-installed Orca skills):

| Skill (this bundle)              | Upstream path                    |
| -------------------------------- | -------------------------------- |
| `skills/orca-cli/SKILL.md`       | `skills/orca-cli/SKILL.md`       |
| `skills/orchestration/SKILL.md`  | `skills/orchestration/SKILL.md`  |

- **Source:** https://github.com/stablyai/orca
- **Pinned commit:** `26934b11bfb5bb02cd9f504a33498a67aa14fdeb` (branch `main`, vendored 2026-07-12)
- **Upstream install (for re-vendoring / updates):**
  `npx skills add https://github.com/stablyai/orca --skill orca-cli`
  `npx skills add https://github.com/stablyai/orca --skill orchestration`

The two upstream `SKILL.md` files are kept **verbatim** (do not hand-edit — re-vendor
from upstream to update). The `skills/orca-workers/SKILL.md` skill in this bundle is
original hk work, not part of the upstream project.

## License (upstream)

The vendored skills are distributed under the MIT License:

```
MIT License

Copyright (c) 2026 Lovecast Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
