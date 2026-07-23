# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 이 repo의 정체

`hk-skills`는 애플리케이션이 아니라 **Claude Code 플러그인 마켓플레이스**다. 스킬(SKILL.md), 슬래시 커맨드, 훅을 번들(플러그인) 단위로 모아 여러 프로젝트/PC에서 공유·중앙관리한다. 런타임 코드도, 빌드도, 의존성도 없다 — 유일한 실행 코드는 파생 파일을 동기화하는 zero-dep node 스크립트 하나다.

번들: `dev`(React/Next 프론트엔드 팀 컨벤션 스킬), `hk`(개인 커맨드 + 훅), `orca`(멀티에이전트 오케스트레이션).

## 핵심 아키텍처 — SSOT → 파생 파일

이 repo를 다룰 때 반드시 이해해야 하는 단 하나의 개념. **원본(SSOT)을 고치면 파생 파일은 스크립트가 재생성한다. 파생 파일을 직접 수정하지 마라.**

**SSOT (직접 편집):**
- `plugins/<bundle>/skills/<skill>/SKILL.md` — 스킬의 존재·`name`·`description` (frontmatter)
- `plugins/<bundle>/.claude-plugin/plugin.json` — 번들의 `name`·`description`·`version`

**파생 (절대 손대지 말 것 — `sync-marketplace.mjs`가 재생성):**
- `.claude-plugin/marketplace.json` 의 `plugins[]` (상위 `name`/`owner`는 보존)
- `README.md` 의 번들 표 — `<!-- BUNDLES:START ... -->` / `<!-- BUNDLES:END -->` 마커 사이
즉 번들 설명을 바꾸려면 표가 아니라 `plugin.json`의 `description`을, 스킬 설명은 `SKILL.md`의 frontmatter를 고친다.

## 커밋 시 자동 동기화 + 구조 검증

`.githooks/pre-commit` → `node scripts/sync-marketplace.mjs --fix` 가 매 커밋마다 돌아 파생 파일을 재생성하고 `git add`한다. 클론마다 **1회** 활성화 필요:

```bash
git config core.hooksPath .githooks
```

수동 실행:
```bash
node scripts/sync-marketplace.mjs         # check 모드: 드리프트/위반이면 파일 변경 없이 exit 1
node scripts/sync-marketplace.mjs --fix   # 파생 파일 재작성 + git add
```

스크립트는 파생 동기화뿐 아니라 **구조 위반 시 커밋을 중단**시킨다. 다음 불변식을 깨면 스킬 추가/수정이 실패한다:

- `plugin.json`의 `name` == 번들 디렉터리명
- `SKILL.md` frontmatter의 `name` == 스킬 디렉터리명
- **스킬명은 마켓플레이스 전역에서 유일** (다른 번들과도 중복 불가)
- 각 번들에 `plugin.json` 존재
- `README.md`에 `BUNDLES` 마커 존재

경고(커밋은 통과하지만 고쳐야 함): `plugin.json`/`SKILL.md` `description` 누락.

이 검증 로직·frontmatter 파서·파생 렌더링은 전부 `scripts/sync-marketplace.mjs` 한 파일에 있다. 규칙을 바꾸려면 여기를 고친다.

## 디렉터리 해부

```
.claude-plugin/marketplace.json     # 마켓플레이스 루트 매니페스트 (파생 plugins[] 포함)
plugins/<bundle>/
  .claude-plugin/plugin.json        # 번들 매니페스트 (SSOT: description·version)
  skills/<skill>/SKILL.md           # 스킬 본체 (SSOT: frontmatter name/description)
  skills/<skill>/references/*.md    # 스킬 보조 문서 (선택)
  commands/**/*.md                  # 슬래시 커맨드 (hk 번들) — 스킬 아님
  hooks/hooks.json                  # 플러그인 제공 훅 (hk·orca 번들)
```

- **스킬로 카운트되는 조건**: 디렉터리 안에 `SKILL.md`가 있어야 한다. `.gitkeep`만 있는 placeholder 디렉터리는 스킬로 세지 않는다.
- **커맨드 vs 스킬**: `plugins/hk/commands/**/*.md`는 슬래시 커맨드로, frontmatter가 `description`만 갖는다 (스킬의 `name`/`user-invocable`/`allowed-tools` 없음). 파일 경로가 곧 커맨드명이 된다(`commands/pre-clear/save.md` → `/hk:pre-clear:save`).
- **스킬 frontmatter 필드**: `name`, `description`(스킬 매칭·인벤토리에 사용), 선택적으로 `user-invocable`, `allowed-tools`, `metadata`.
## 스킬 추가/이름변경/이동 워크플로우

1. `plugins/<bundle>/skills/<new-skill>/SKILL.md`를 만들고 frontmatter `name`을 **디렉터리명과 동일하게** 맞춘다. 스킬명이 전역에서 유일한지 확인.
2. 번들 설명을 바꿔야 하면 `plugin.json`의 `description`을 수정 (README 표가 아니라).
3. `node scripts/sync-marketplace.mjs --fix`로 파생 파일을 맞추거나, 그냥 커밋하면 훅이 처리한다.
4. 이름/디렉터리 불일치·중복이 있으면 스크립트가 실패시키므로 메시지를 보고 고친다.

프로젝트 구조에 종속된 "계약 스킬"은 이 repo가 아니라 각 프로젝트의 `.claude/skills/`에 둔다.

## 소비 방식 (두 경로)

- **Claude Code 네이티브 플러그인**: 프로젝트의 커밋되는 `.claude/settings.json`에 `extraKnownMarketplaces`로 `github: k2ker/hk-skills`를 등록하고 `enabledPlugins`로 원하는 번들만 켠다. (`settings.local.json` 말고 커밋되는 `settings.json`에 둬야 다른 PC로 전파.)
- **Hermes**: 마켓플레이스를 설치하지 않고 `plugins/` 밑 SKILL.md들을 `skills.external_dirs`로 직접 읽는다. 이 경로의 스킬은 `npx skills update` 대상이 아니며 수정은 이 repo에서 git으로 관리한다.

버전은 각 `plugin.json`의 `version`. 소비 측 갱신은 `/plugin marketplace update hk-skills`.
