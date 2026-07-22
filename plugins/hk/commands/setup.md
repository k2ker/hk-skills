---
description: hk-skills 소비 프로젝트 부트스트랩 — 번들된 견본을 읽어 현재 프로젝트 .claude/settings.json에 마켓플레이스 등록·플러그인 활성화·안전 권한 기본값을 병합(비파괴)
---

# /hk:setup

이 저장소(`hk-skills`)를 소비하는 **다른 프로젝트**에서 실행한다. 플러그인 자체는 담을 수 없는 "설정 조각"(마켓플레이스 등록 + `enabledPlugins` + 안전한 권한 기본값)을, 플러그인에 **번들된 견본** `templates/settings.example.json`에서 꺼내 현재 프로젝트의 `.claude/settings.json`에 **병합**한다.

- 견본 위치: 이 플러그인 폴더 안 `templates/settings.example.json` (설치 시 캐시로 함께 복사됨)
- 목적: `.claude/settings.json`을 프로젝트 git에 커밋 → 다른 PC/팀원이 repo 열면 동일 Claude 환경 공유
- 성격: **1회성 스냅샷 복사**. 견본이 나중에 바뀌어도 이미 깐 프로젝트는 자동 갱신되지 않는다(다시 실행해야 반영). 진짜 자동/강제 배포가 필요하면 managed settings(조직/MDM) 계층을 써야 한다.

## 실행 절차

### 1) 번들된 견본 위치 탐색 (env var 우선, 없으면 캐시 검색)

슬래시 커맨드 마크다운에는 `${CLAUDE_PLUGIN_ROOT}` 치환이 보장되지 않으므로 런타임에 견고하게 찾는다:

```bash
TPL="${CLAUDE_PLUGIN_ROOT:-__unset__}/templates/settings.example.json"
if [ ! -f "$TPL" ]; then
  # 플러그인 캐시/클론에서 hk 플러그인의 견본을 검색 (가장 최근 버전)
  TPL="$(find "$HOME/.claude/plugins" -type f -path '*/hk/templates/settings.example.json' 2>/dev/null | sort | tail -1)"
fi
if [ -z "$TPL" ] || [ ! -f "$TPL" ]; then
  echo "TEMPLATE_NOT_FOUND"
else
  echo "TEMPLATE=$TPL"
  cat "$TPL"
fi
```

- `TEMPLATE_NOT_FOUND` → hk 플러그인이 설치돼 있지 않거나 캐시가 비었을 수 있음. 사용자에게 알리고 종료:
  > 번들 견본을 찾지 못했습니다. `/plugin install hk@hk-skills`로 hk 플러그인이 설치돼 있는지 확인 후 다시 실행해주세요.
- 견본 JSON을 읽었으면 다음 단계.

### 2) 현재 프로젝트의 기존 settings.json 확인

```bash
test -f .claude/settings.json && cat .claude/settings.json || echo "NO_EXISTING_SETTINGS"
```

- **없음** → 4)에서 `.claude/`를 만들고 견본을 그대로 기록(신규 생성).
- **있음** → 3)에서 **병합**(기존 키 보존).

### 3) 병합 계획 수립 (비파괴 deep-merge)

기존 값을 **절대 덮어쓰지 않고** 누락된 것만 채운다:

| 키 | 병합 규칙 |
| --- | --- |
| `extraKnownMarketplaces` | `hk-skills` 항목이 없으면 추가. 다른 마켓플레이스는 그대로 둔다 |
| `enabledPlugins` | 견본의 플러그인 ID 중 **기존에 없는 것만** 추가. 이미 있는 키(사용자가 켜/끈 것)는 손대지 않는다 |
| `permissions.deny` | 배열 합집합 — 견본 항목 중 없는 것만 append |
| 그 외 사용자 키 | 전부 보존 |

### 4) 사용자에게 병합 계획 보고 후 확인

`.claude/settings.json`은 프로젝트 설정이므로 **쓰기 전에 반드시 확인**한다. 다음을 보고:

- 신규 생성인지 / 기존 병합인지
- 추가될 항목 목록 (마켓플레이스 1건, enabledPlugins 중 새로 추가되는 ID, deny 새 항목)
- 이미 존재해서 건너뛴 항목
- `enabledPlugins`의 web/supabase/orca는 견본에서 `false`이니 필요하면 사용자가 `true`로 바꾸도록 안내

확인을 받은 뒤에만 파일을 기록한다. (`--yes`/명시 동의가 이미 있으면 확인 생략)

### 5) 기록

```bash
mkdir -p .claude
```

병합 결과를 `.claude/settings.json`에 **유효한 JSON**으로 기록한다(들여쓰기 2칸). 기록 후 `node -e "JSON.parse(require('fs').readFileSync('.claude/settings.json','utf8'))"` 등으로 파싱 검증.

### 6) 마무리 안내

```
.claude/settings.json 준비 완료. 이 파일을 프로젝트 git에 커밋하면 다른 PC·팀원이 repo를 열 때
같은 마켓플레이스·플러그인 설정을 공유합니다(팀원은 신뢰 프롬프트 1회 승인).

- 활성화할 번들을 늘리려면 enabledPlugins에서 web/supabase/orca 등을 true로 바꾸세요.
- 견본이 갱신되면 /hk:setup을 다시 실행해 반영하세요(1회성 스냅샷이라 자동 갱신 안 됨).
```

## 원칙

- **비파괴 병합** — 기존 사용자 설정/권한/플러그인 선택은 절대 덮어쓰지 않는다. 누락분만 채운다.
- **쓰기 전 확인** — settings.json은 프로젝트 동작을 바꾼다. 무확인 기록 금지(사전 동의 있을 때만 생략).
- **민감정보 금지** — 견본·병합 결과에 토큰/키/비밀번호를 넣지 않는다. 견본은 마켓플레이스·플러그인·권한 뼈대만.
- **JSON 유효성 검증** — 기록 후 반드시 파싱 확인. 깨진 settings.json은 Claude Code 로딩을 막는다.
- **스냅샷임을 명시** — 자동 동기화가 아님을 사용자에게 분명히 한다.

## 안티패턴

| ❌ | 이유 |
| --- | --- |
| 기존 `.claude/settings.json`을 통째로 덮어쓰기 | 사용자 권한·env·다른 마켓플레이스 유실 |
| 확인 없이 바로 기록 | 프로젝트 설정 변경은 확인 대상 |
| 견본 경로를 `${CLAUDE_PLUGIN_ROOT}` 하드코딩 가정 | 커맨드 마크다운엔 치환 보장 없음 — 런타임 탐색 필요 |
| web/supabase/orca를 임의로 true | 소비 프로젝트가 안 쓰는 번들까지 로딩돼 토큰 낭비. 사용자 선택에 맡긴다 |
| "자동으로 최신 유지된다"고 안내 | 1회성 스냅샷임. 오해 소지 |
