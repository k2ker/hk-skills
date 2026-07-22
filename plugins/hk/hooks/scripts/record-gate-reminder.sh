#!/usr/bin/env bash
# hk plugin — Stop hook: "완료 전 필수 기록" 게이트 리마인더.
#
# 플러그인 훅은 활성화되면 모든 프로젝트·모든 턴 종료마다 전역 발동하므로,
# 이 스크립트가 스스로 게이트를 걸어 "기록이 빠진 경우"에만 알린다:
#   - docs/tech-notes/ 컨벤션을 쓰는 git 프로젝트에서만 (그 외엔 조용)
#   - apps/ packages/ supabase/ src/ 에 미커밋 소스 변경이 있는데
#   - docs/tech-notes/ · MEMORY.md 변경이 하나도 없을 때
# 이때 딱 한 번 stop 을 차단(exit 2)하며 stderr 로 리마인더를 전달한다.
# 다음 stop 은 stop_hook_active=true 가드로 통과 → 트랩되지 않는다.
set -uo pipefail

input="$(cat)"

jqr() { # $1 = jq path; jq 없으면 빈 문자열
  command -v jq >/dev/null 2>&1 && printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null
}

# 0) jq 없으면 오작동 방지 위해 조용히 통과
command -v jq >/dev/null 2>&1 || exit 0

# 1) 재진입 가드: 직전에 한 번 차단했다면 통과시킨다(트랩 방지)
[ "$(jqr '.stop_hook_active')" = "true" ] && exit 0

cwd="$(jqr '.cwd')"
[ -n "$cwd" ] || exit 0

# 2) 컨벤션 마커 — tech-note 를 안 쓰는 프로젝트에선 조용
[ -d "$cwd/docs/tech-notes" ] || exit 0

# 3) git 워크트리인지
git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# 4) 미커밋 소스 변경이 있나 (apps/ packages/ supabase/ src/)
[ -n "$(git -C "$cwd" status --porcelain -- apps packages supabase src 2>/dev/null)" ] || exit 0

# 5) 이미 기록했나 (tech-notes 또는 MEMORY.md 변경) → 기록된 걸로 보고 통과
[ -n "$(git -C "$cwd" status --porcelain -- docs/tech-notes MEMORY.md 2>/dev/null)" ] && exit 0

# 6) 한 번만 차단하며 리마인더 전달
echo "완료 전 필수 기록 게이트: apps/·packages/·supabase/ 소스는 변경됐는데 docs/tech-notes/·MEMORY.md 갱신이 없습니다. 기능/조사 단위가 끝났다면 CLAUDE.md '완료 전 필수 기록'대로 tech-note append + MEMORY.md 갱신 후 마무리하세요. 이미 기록했거나 아직 작업 중이면 그대로 다시 종료하면 통과됩니다." >&2
exit 2
