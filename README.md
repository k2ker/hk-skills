# hk-skills

개인 Claude Code 스킬 마켓플레이스. 여러 프로젝트/PC에서 공유·중앙관리하는 스킬 번들.

## 번들

| 번들(플러그인) | 스킬 수 | 설명 |
|---|---|---|
| `common` | 22 | Stack-agnostic dev workflow: git & GitHub, debugging, quality gates, TDD, planning, code review, repo hygiene, secrets, TypeScript, tests, and Claude worker orchestration. |
| `web` | 18 | Web frontend (React/Next/Vite): design, Tailwind, UI/UX, Framer Motion, React best-practices/composition, shadcn, Storybook, Playwright, TanStack (Query/Form/Table), Turborepo, Vercel deploy. |
| `rn` | 0 | React Native / Expo mobile. (Placeholder — 아직 스킬 없음. RN 프로젝트 시작 시 skills/에 추가.) |
| `supabase` | 2 | Supabase + Postgres: client/SSR, auth/RLS, migrations, query & schema best-practices. |
| `design` | 2 | Throwaway HTML mockups / design exploration before building: claude-design, sketch. |

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

## 향후 분할

지금은 `web` 하나에 웹 스택 전부. RN/Vite 등 스택이 실제로 갈릴 때 `web`을 쪼개면 된다(스킬은 한 번만 존재하는 원칙 유지).
