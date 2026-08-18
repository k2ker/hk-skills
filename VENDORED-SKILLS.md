# Vendored Skills — 출처 기록 (provenance manifest)

이 파일은 `vendor` 번들이 재배포 중인 **외부 스킬의 원본 출처**를 기록한다.
`npx skills`로 받은 스킬은 `plugins/`로 옮기는 순간 `skills update`가 못 닿으므로, 되받을 좌표를 여기 남긴다.

## 현재 배치 — vendor 번들 26개 (2026-08-18 기준)

추가/갱신/삭제는 `/vendor:add|update|remove` (repo-local `.claude/commands/vendor/`).

| skill | 원본 repo | 성격 |
| --- | --- | --- |
| deploy-to-vercel | `vercel-labs/agent-skills` | 공식 |
| find-skills | `vercel-labs/skills` | 공식 |
| framer-motion-animator | `patricio0312rev/skills` | ⚠️ 커뮤니티 |
| frontend-design | `anthropics/skills` | 공식 |
| playwright-best-practices | `currents-dev/playwright-best-practices-skill` | ⚠️ 커뮤니티 |
| playwright-cli | `microsoft/playwright-cli` | 공식 |
| prisma-cli | `prisma/skills` | 공식 |
| prisma-client-api | `prisma/skills` | 공식 |
| shadcn | `shadcn-ui/ui` | 공식 |
| skill-creator | `anthropics/skills` | 공식 |
| storybook | `DaleStudy/skills` | ⚠️ 커뮤니티 |
| supabase | `supabase/agent-skills` | 공식 |
| supabase-postgres-best-practices | `supabase/agent-skills` | 공식 |
| tailwind-design-system | `wshobson/agents` | ⚠️ 커뮤니티 |
| tanstack-form | `tanstack-skills/tanstack-skills` | 공식 |
| tanstack-query | `tanstack-skills/tanstack-skills` | 공식 |
| tanstack-query-best-practices | `DeckardGer/tanstack-agent-skills` | ⚠️ 커뮤니티 |
| tanstack-table | `tanstack-skills/tanstack-skills` | 공식 |
| turborepo | `vercel/turborepo` | 공식 |
| typescript-advanced-types | `wshobson/agents` | ⚠️ 커뮤니티 |
| ui-ux-pro-max | `nextlevelbuilder/ui-ux-pro-max-skill` | ⚠️ 커뮤니티 |
| vercel-cli | `vercel/vercel` | 공식 |
| vercel-cli-with-tokens | `vercel-labs/agent-skills` | 공식 · ⚠️ **업스트림 제거됨**(2026-08-18 확인) — 갱신 좌표 상실, 로컬본만 유지 |
| vercel-composition-patterns | `vercel-labs/agent-skills` | 공식 |
| vercel-react-best-practices | `vercel-labs/agent-skills` | 공식 |
| vitest | `antfu/skills` | 공식 |

- ⚠️ **커뮤니티(비공식) 출처**는 안정성·유지가 공식보다 약하다. 갱신 시 내용 급변 가능 — diff를 눈으로 확인하고 반영한다.
- `orca-cli`·`orchestration`·`computer-use`는 `orca-workers`가 참조로 처리하므로 vendor에 넣지 않는다.
- **Prisma는 상시 사용 2개만 넣는다** — `prisma-client-api`(쿼리)·`prisma-cli`(init/generate/migrate/studio). `prisma-upgrade-v7`·`prisma-mongodb-upgrade`는 마이그레이션 시점에만, `prisma-postgres`·`prisma-compute` 계열은 Prisma 자사 호스팅 제품 전용이라 제외했다. 필요해지면 그때 `/vendor:add prisma/skills <이름>`.
- **스킬을 추가하면 이 표에 반드시 한 줄 넣는다.** 여기 없으면 나중에 갱신할 좌표가 사라진다 — `prisma-orm-v7-skills`가 실제로 그렇게 출처를 잃었다(2026-07-28 대조 때 발견, 결국 교체).

## 최신판 대조 이력

### 2026-08-18 — 26개 전수 대조 + 7개 일괄 갱신

병렬 수확(`npx skills add` → `diff -rq`, 원본 repo 17개)으로 전수 대조. **18개 동일**(LICENSE만 로컬 여분인 vitest·shadcn·playwright-cli 포함), **7개 갱신 적용**, **1개 업스트림 소멸**:

| 스킬 | 갱신 내용 |
| --- | --- |
| `supabase` | v0.1.7 — Debugging 섹션 신설, description에 디버깅 트리거 추가 |
| `supabase-postgres-best-practices` | description 개선(#194), 본문 변경 없음 |
| `vercel-cli` | 에이전트 안전 규칙 강화(자동 링크/인증 금지, `project inspect` 검증), `flags versions/diff` 신규 |
| `prisma-cli` | 7.6.0→7.9.1 — `agent-safety.md`·`complete.md` 신규 |
| `prisma-client-api` | 7.6.0→7.9.1 — constructor 옵션 등 레퍼런스 보강 |
| `turborepo` | 2.10.6→2.10.11-canary.4 — `--affected` 베이스 설명 정정, `TURBO_SCM_BASE`, `--parallel` deprecated, turbo-ignore 신규 옵션. **canary지만 실질 내용이 달라 갱신**(7/28의 "버전 문자열뿐이면 canary 안 받음" 판례와 상황 다름) |
| `ui-ux-pro-max` | 대규모 개편 — 데이터 CSV 개편, 'Query Contract' 섹션 신설. 커뮤니티 출처 규칙대로 위험 패턴 스캔(네트워크·eval류 없음, subprocess는 자체 테스트 전용) 후 반영 |

- `vercel-cli-with-tokens` — **업스트림(`vercel-labs/agent-skills`)에서 제거됨.** 로컬본 유지, 갱신 불가 상태로 표에 표기. 그 repo에 신규 스킬(vercel-react-native-skills, vercel-optimize, writing-guidelines) 등장 — 필요 시 `/vendor:add` 후보.
- LICENSE 로컬 유지물은 갱신 시 보존함(turborepo·vercel-cli).

### 2026-07-28 — 25개 전수 대조 (파일 단위 diff)

최신판을 전부 받아 `plugins/vendor/skills/`와 대조. **19개 완전 동일**(갱신 불필요). 나머지 발견:

| 스킬 | 상태 | 판단 |
| --- | --- | --- |
| `prisma-orm-v7-skills` | **출처 미기록** — 이 표에 항목이 없어 어느 repo에서 받았는지 확인 불가(`prisma/prisma`에는 스킬 없음). 내용은 Prisma v7 변경사항 121줄 단일 파일 | ✅ **`prisma-client-api` + `prisma-cli`로 교체**(둘 다 `prisma/skills` 공식). 상세는 아래 |
| `turborepo` | 최신판이 `2.10.7-canary.1` (우리는 stable `2.10.6`). 차이는 버전 문자열·`$schema` URL뿐, 내용 변경 없음 | **갱신 안 함** — canary로 내려가는 셈 |
| `deploy-to-vercel` | `Archive.zip`(11KB)이 우리 쪽에만 있음. 업스트림 최신판에 없는 수확 잔여물 | ✅ 삭제함 |
| `playwright-cli`·`shadcn`·`vercel-cli`·`vitest`·`turborepo` | LICENSE 파일이 우리 쪽에만 있음. 현재 `npx skills add`는 LICENSE를 안 딸려옴 | **우리 쪽이 나음 — 유지** |

**Prisma 교체 경위** — 출처를 잃은 `prisma-orm-v7-skills`를 대신할 스킬을 고르며 처음엔 주제가 같다는 이유로 `prisma-upgrade-v7`을 넣었으나, 이건 **v6→v7 마이그레이션 전용**이라 이미 v7을 쓰는 프로젝트에선 트리거되지 않는다. `find-skills` 절차로 `prisma/skills`(공식, 9개, 56~66K installs)를 다시 훑어 **상시 사용되는 `prisma-client-api`·`prisma-cli` 2개로 확정**했다. 나머지 7개를 뺀 이유는 위 "현재 배치" 참고.

대조 방법 (`--skill a,b` 콤마 나열은 현재 CLI에서 실패 — `-s` 를 스킬마다 따로):

```bash
npx -y skills@latest add <owner/repo> -s <skill> --copy -a claude-code -y   # 임시 dir에서
diff -rq plugins/vendor/skills/<skill> <임시>/.claude/skills/<skill>
```

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

## (히스토리) 2026-07-22 일괄 삭제 당시 26개 출처

> 아래는 **2026-07-22 리팩토링 때 repo에서 지운 26개의 스냅샷**이다. `bundle` 컬럼은 당시 이름(`common`/`dev`)이라 현재 배치와 다르다. 현재 목록은 위 "현재 배치" 표를 본다. 이 표는 그때 상태로 되돌릴 때만 참고한다.

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
| dev | deploy-to-vercel | `vercel-labs/agent-skills` | 공식 | — |
| dev | vercel-cli-with-tokens | `vercel-labs/agent-skills` | 공식 | — |
| dev | vercel-composition-patterns | `vercel-labs/agent-skills` | 공식 | metadata v1.0.0 |
| dev | vercel-react-best-practices | `vercel-labs/agent-skills` | 공식 | metadata v1.0.0 |
| dev | frontend-design | `anthropics/skills` | 공식 | — |
| dev | shadcn | `shadcn-ui/ui` | 공식 | — |
| dev | playwright-cli | `microsoft/playwright-cli` | 공식 | — |
| dev | turborepo | `vercel/turborepo` | 공식 | — |
| dev | vercel-cli | `vercel/vercel` | 공식 | — |
| dev | tanstack-form | `tanstack-skills/tanstack-skills` | 공식 | — |
| dev | tanstack-query | `tanstack-skills/tanstack-skills` | 공식 | — |
| dev | tanstack-table | `tanstack-skills/tanstack-skills` | 공식 | — |
| dev | tanstack-query-best-practices | `DeckardGer/tanstack-agent-skills` | ⚠️ 커뮤니티 | — |
| dev | tailwind-design-system | `wshobson/agents` | ⚠️ 커뮤니티 | — |
| dev | framer-motion-animator | `patricio0312rev/skills` | ⚠️ 커뮤니티 | — |
| dev | playwright-best-practices | `currents-dev/playwright-best-practices-skill` | ⚠️ 커뮤니티 | — |
| dev | storybook | `DaleStudy/skills` | ⚠️ 커뮤니티 | — |
| dev | ui-ux-pro-max | `nextlevelbuilder/ui-ux-pro-max-skill` | ⚠️ 커뮤니티 | — |

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
