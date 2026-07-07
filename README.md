# hk-skills

개인 Claude Code 스킬 마켓플레이스. 여러 프로젝트/PC에서 공유·중앙관리하는 스킬 번들.

## 번들

<!-- BUNDLES:START (auto: scripts/sync-marketplace.mjs) -->
| 번들(플러그인) | 스킬 수 | 설명 |
|---|---|---|
| `common` | 23 | Stack-agnostic dev workflow: git & GitHub, debugging, quality gates, TDD, planning, code review, repo hygiene, secrets, TypeScript, tests, and Claude worker orchestration. |
| `web` | 26 | Web frontend (React/Next/Vite): design, Tailwind, UI/UX, Framer Motion, React best-practices/composition, shadcn, Storybook, Playwright, TanStack (Query/Form/Table), Turborepo, Vercel deploy, API-only client/server boundary, frontend state policy. |
| `rn` | 0 | React Native / Expo mobile. (Placeholder — 아직 스킬 없음. RN 프로젝트 시작 시 skills/에 추가.) |
| `supabase` | 2 | Supabase + Postgres: client/SSR, auth/RLS, migrations, query & schema best-practices. |
| `design` | 2 | Throwaway HTML mockups / design exploration before building: claude-design, sketch. |
| `visuals` | 3 | Standalone visual assets from a prompt: architecture/infra diagrams (SVG/HTML), Excalidraw flowcharts & sequence diagrams, and infographics (layouts × styles). |
<!-- BUNDLES:END -->

번들 표 · `marketplace.json` 설명 · `SKILLS.md` 인벤토리는 **커밋 훅이 자동 동기화**한다(수동 편집 금지). 원본은 파일시스템 + 각 `plugin.json`. 전체 스킬 목록은 [SKILLS.md](SKILLS.md).

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
    "common@hk-skills": true,
    "web@hk-skills": true,
    "supabase@hk-skills": true
  }
}
```

- clone + repo 신뢰 시 자동 설치 프롬프트. Hermes 불필요.
- `settings.local.json`(gitignore) 말고 `settings.json`(커밋)에 둬야 다른 PC에도 전파.

## 스택별 조합 예

- 웹(Next/Vite)+Supabase: `common web supabase`
- 순수 웹: `common web`
- React Native: `common rn`
- 백엔드/DB만: `common supabase`

## 업데이트

스킬 고치고 push → 각 프로젝트에서 `/plugin marketplace update hk-skills`(또는 자동갱신).
버전은 `plugins/<b>/.claude-plugin/plugin.json`의 `version`. 생략 시 매 commit이 새 버전.

## 커밋 훅 (파생 파일 자동 동기화)

스킬을 추가/삭제/이동하면 `README.md` 번들 표·`marketplace.json` 설명·`SKILLS.md` 인벤토리가 어긋난다. 이를 커밋 시 자동으로 맞추는 pre-commit 훅이 있다.

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
