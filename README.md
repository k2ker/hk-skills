# hk-skills

개인 Claude Code 스킬 마켓플레이스. 여러 프로젝트/PC에서 공유·중앙관리하는 스킬 번들.

## 번들

<!-- BUNDLES:START (auto: scripts/sync-marketplace.mjs) -->
| 번들(플러그인) | 스킬 수 | 설명 |
|---|---|---|
| `web` | 6 | Web frontend (React/Next) 팀 컨벤션 스킬: 컴포넌트·Context·Next.js App Router·Tailwind·TanStack Query 패턴 + client/server API-only 경계(브라우저 DB 직접접근·secret 노출 차단). |
| `rn` | 0 | React Native / Expo mobile. (Placeholder — 아직 스킬 없음. RN 프로젝트 시작 시 skills/에 추가.) |
| `hk` | 0 | hk personal cross-project custom commands. /hk:pre-clear:save & /hk:pre-clear:resume — hand off session context around /clear (writes/reads .hk/pre-clear/handoff.md). |
| `orca` | 1 | Standalone Orca orchestration bundle. Skill `orca-workers` — coordinate parallel sub-worktree workers for one feature/page cycle (provision → brief → supervised dispatch → cross-model Codex review → fix loop → integration landing). Command mechanics delegate to Orca's own orca-cli/orchestration skills. |
<!-- BUNDLES:END -->

번들 표 · `marketplace.json` 설명은 **커밋 훅이 자동 동기화**한다(수동 편집 금지). 원본은 파일시스템 + 각 `plugin.json`. 스킬 상세는 각 `plugins/<번들>/skills/<스킬>/SKILL.md`.

프로젝트 계약 스킬(특정 repo 구조에 종속)은 여기 없고 각 프로젝트 `.claude/skills/`에 둔다.

## 프로젝트에서 쓰는 법

프로젝트의 **커밋되는** `.claude/settings.json`에 필요한 번들만 켠다:

```json
{
  "extraKnownMarketplaces": {
    "hk-skills": {
      "source": {
        "source": "github",
        "repo": "k2ker/hk-skills"
      }
    }
  },
  "enabledPlugins": {
    "web@hk-skills": true,
    "hk@hk-skills": true
  }
}
```

- clone + repo 신뢰 시 자동 설치 프롬프트. Hermes 불필요.
- `settings.local.json`(gitignore) 말고 `settings.json`(커밋)에 둬야 다른 PC에도 전파.

## Hermes에서 쓰는 법

Hermes는 마켓플레이스로 install하지 않고, 쓰려는 프로필의 `skills.external_dirs`에 이 repo의 `plugins/` 경로를 추가해 `SKILL.md`들을 직접 읽는다(경로·프로필은 각 머신/환경에 맞게).

운영 원칙:

- 여기 들어간 skill은 `npx skills update` 대상이 아니다 — 수정은 이 repo에서 git으로 관리(`git pull` → edit → validate → `git commit` → `git push`).
- 기존 Hermes 세션은 `/reload-skills`(또는 `/new`)로 최신 skill index를 다시 읽는다.

## 스택별 조합 예

- 웹(React/Next): `web`
- 웹 + 개인 커맨드/훅: `web hk`
- React Native: `rn` (placeholder — 아직 스킬 없음)
- 멀티에이전트 오케스트레이션: `orca`

## 업데이트

스킬 고치고 push → 각 프로젝트에서 `/plugin marketplace update hk-skills`(또는 자동갱신).
버전은 `plugins/<b>/.claude-plugin/plugin.json`의 `version`. 생략 시 매 commit이 새 버전.

## 커밋 훅 (파생 파일 자동 동기화)

스킬을 추가/삭제/이동하면 `README.md` 번들 표·`marketplace.json` 설명이 어긋난다. 이를 커밋 시 자동으로 맞추는 pre-commit 훅이 있다.

```bash
git config core.hooksPath .githooks   # 클론마다 1회
```

- 커밋할 때마다 `scripts/sync-marketplace.mjs --fix`가 돌아 파생 파일을 SSOT(파일시스템 + 각 `plugin.json`)에서 재생성하고 `git add`한다.
- 구조 위반(스킬 `name`↔디렉터리 불일치, 스킬명 전역 중복, `plugin.json` 누락 등)이 있으면 커밋이 **중단**된다.
- 이전 커밋 대비 추가/수정/삭제된 스킬을 요약 출력한다.
- 수동 점검: `node scripts/sync-marketplace.mjs`(비변경 검사, 드리프트면 exit 1) / `--fix`(갱신).
- 훅 우회는 `git commit --no-verify`지만 파생 파일이 어긋나므로 지양.

## 향후 분할

지금은 `web` 하나에 웹 스택 전부. RN/Vite 등 스택이 실제로 갈릴 때 `web`을 쪼개면 된다(스킬은 한 번만 존재하는 원칙 유지).
