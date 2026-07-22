# Vendored Skills — 출처 기록 (provenance manifest)

이 파일은 `npx skills`(skills.sh)로 받아온 **스토어 스킬 26개의 원본 출처**를 기록한다.
2026-07-22 리팩토링을 위해 이 26개를 repo에서 일괄 삭제하기 전, 되받을 수 있도록 남긴 receipt다.

## 재설치(re-vendor) 절차

`npx skills add`는 `.claude/skills`(에이전트 디렉터리)에 설치하지, 이 repo의 `plugins/<bundle>/skills/`에 넣지 않는다.
따라서 스테이징 → 이동이 필요하다:

```bash
# 1) 임시 위치에 최신판 받기 (telemetry off, 심링크 대신 실제 복사)
DISABLE_TELEMETRY=1 npx skills add <owner/repo> --skill <name> --copy
#    → ./.claude/skills/<name>/ 생성됨
# 2) 마켓플레이스 레이아웃으로 이동
mv .claude/skills/<name> plugins/<bundle>/skills/<name>
# 3) 파생 동기화 + 유일성/구조 검증
node scripts/sync-marketplace.mjs --fix
```

- 위 커맨드는 **최신판(latest)**을 당겨온다. 삭제 직전 상태를 정확히 복원하려면 git을 쓴다:
  `git checkout <this-commit> -- plugins/<bundle>/skills/<name>`
- ⚠️ **커뮤니티(비공식) 출처**는 안정성/유지가 공식보다 약하다. 업데이트 시 내용 급변 가능.

## 26개 스토어 스킬 출처

| bundle | skill | 원본 repo | 성격 | pinned |
| --- | --- | --- | --- | --- |
| common | skill-creator | `anthropics/skills` | 공식 | — |
| common | typescript-advanced-types | `wshobson/agents` | ⚠️ 커뮤니티 | — |
| common | vitest | `antfu/skills` | 공식 | GENERATION SHA `4a7321e1` |
| orca | computer-use | `stablyai/orca` | 공식 | NOTICE `e3721e8` |
| orca | orca-cli | `stablyai/orca` | 공식 | NOTICE `e3721e8` |
| orca | orchestration | `stablyai/orca` | 공식 | NOTICE `e3721e8` |
| supabase | supabase | `supabase/agent-skills` | 공식 | — |
| supabase | supabase-postgres-best-practices | `supabase/agent-skills` | 공식 | — |
| web | deploy-to-vercel | `vercel-labs/agent-skills` | 공식 | — |
| web | vercel-cli-with-tokens | `vercel-labs/agent-skills` | 공식 | — |
| web | vercel-composition-patterns | `vercel-labs/agent-skills` | 공식 | metadata v1.0.0 |
| web | vercel-react-best-practices | `vercel-labs/agent-skills` | 공식 | metadata v1.0.0 |
| web | frontend-design | `anthropics/skills` | 공식 | — |
| web | shadcn | `shadcn-ui/ui` | 공식 | — |
| web | playwright-cli | `microsoft/playwright-cli` | 공식 | — |
| web | turborepo | `vercel/turborepo` | 공식 | — |
| web | vercel-cli | `vercel/vercel` | 공식 | — |
| web | tanstack-form | `tanstack-skills/tanstack-skills` | 공식 | — |
| web | tanstack-query | `tanstack-skills/tanstack-skills` | 공식 | — |
| web | tanstack-table | `tanstack-skills/tanstack-skills` | 공식 | — |
| web | tanstack-query-best-practices | `DeckardGer/tanstack-agent-skills` | ⚠️ 커뮤니티 | — |
| web | tailwind-design-system | `wshobson/agents` | ⚠️ 커뮤니티 | — |
| web | framer-motion-animator | `patricio0312rev/skills` | ⚠️ 커뮤니티 | — |
| web | playwright-best-practices | `currents-dev/playwright-best-practices-skill` | ⚠️ 커뮤니티 | — |
| web | storybook | `DaleStudy/skills` | ⚠️ 커뮤니티 | — |
| web | ui-ux-pro-max | `nextlevelbuilder/ui-ux-pro-max-skill` | ⚠️ 커뮤니티 | — |

## 일괄 재설치 커맨드 (원본 repo별 묶음)

```bash
export DISABLE_TELEMETRY=1
npx skills add anthropics/skills            --skill skill-creator,frontend-design --copy
npx skills add wshobson/agents              --skill typescript-advanced-types,tailwind-design-system --copy
npx skills add antfu/skills                 --skill vitest --copy
npx skills add stablyai/orca                --skill computer-use,orca-cli,orchestration --copy
npx skills add supabase/agent-skills        --skill supabase,supabase-postgres-best-practices --copy
npx skills add vercel-labs/agent-skills     --skill deploy-to-vercel,vercel-cli-with-tokens,vercel-composition-patterns,vercel-react-best-practices --copy
npx skills add shadcn-ui/ui                 --skill shadcn --copy
npx skills add microsoft/playwright-cli     --skill playwright-cli --copy
npx skills add vercel/turborepo             --skill turborepo --copy
npx skills add vercel/vercel                --skill vercel-cli --copy
npx skills add tanstack-skills/tanstack-skills --skill tanstack-form,tanstack-query,tanstack-table --copy
npx skills add DeckardGer/tanstack-agent-skills --skill tanstack-query-best-practices --copy
npx skills add patricio0312rev/skills       --skill framer-motion-animator --copy
npx skills add currents-dev/playwright-best-practices-skill --skill playwright-best-practices --copy
npx skills add DaleStudy/skills             --skill storybook --copy
npx skills add nextlevelbuilder/ui-ux-pro-max-skill --skill ui-ux-pro-max --copy
```

## 자작 스킬 — repo에 유지

`orca-workers`, `api-only-boundary`, `frontend-state-ui-guidelines`,
`web-component-patterns`, `web-context-patterns`, `web-nextjs-patterns`,
`web-tailwind-patterns`, `web-tanstack-query-patterns`

## common 번들 제거 (2026-07-22, 클린 목적)

common 번들 전체(8개 스킬 + plugin.json)를 일괄 제거했다 — 전부 Hermes 세션에서
vendor된 오염 산출물(author: Hermes Agent, 남의 워크스페이스 경로·`hyeong` 호명·
stale 참조·삼중 중복). 분석상 keep 0/8. store 스킬이 아니라 `npx skills add`로 되받을
수 없으며, **복구는 git 전용**:

```bash
git checkout <이 커밋^> -- plugins/common
```

향후 리워크 후보(진짜 재사용 가치 있던 것, 오염 제거 조건): `claude-tmux-worker`
(워커 오케스트레이션 몸통), `repository-hygiene`, `node-quality-gates`.
