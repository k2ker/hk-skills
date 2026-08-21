#!/bin/bash
# 기록 게이트 (record 컨벤션 v2) — Stop 훅용 하이브리드.
# 설계: 프리필터(무비용)로 뻔한 통과를 조기 처리하고, 잔여 턴만 LLM 판정.
# 원칙: fail-open — 판단 불가·오류·타임아웃은 전부 통과(exit 0).
#       차단은 exit 2가 아니라 stdout JSON (플러그인 훅 exit 2 오동작 회피 — anthropics/claude-code#10412).
# 알려진 한계(수용): 직전 일단락의 기록 파일이 미커밋으로 남아 있는 동안은 ⑤가 통과시킨다 —
#       게이트는 넛지이지 벽이 아니며, 기록은 보통 일단락 커밋에 포함되므로 창이 짧다.
# 테스트 오버라이드: RECORD_GATE_JUDGE=block|pass 로 LLM 단계를 대체.

# ⓪ 재귀 차단 — 이 게이트가 띄운 중첩 claude가 자기 Stop 훅으로 이 스크립트를 또 돌리는 경우
[ -n "${RECORD_GATE_INNER:-}" ] && exit 0
# ⓪' 런타임 의존성 — python3(JSON 파싱)·git 없으면 명시적 fail-open
command -v python3 >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null || printf '{}')

json_field() {
  printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    v = d.get(sys.argv[1], "")
    sys.stdout.write(v if isinstance(v, str) else json.dumps(v))
except Exception:
    pass
' "$1" 2>/dev/null
}

# ① 이번 턴에 이미 한 번 차단됐음 → 즉시 통과 (차단 캐스케이드 방지)
case "$(json_field stop_hook_active)" in
  true|True) exit 0 ;;
esac

# 프로젝트 루트 해석 — cwd는 루트가 아닐 수 있다(하위 디렉터리에서 세션 시작).
# 우선순위: CLAUDE_PROJECT_DIR → git toplevel(cwd 기준) → cwd
CWD=$(json_field cwd)
ROOT="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$ROOT" ] && [ -n "$CWD" ]; then
  ROOT=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null)
fi
[ -z "$ROOT" ] && ROOT="$CWD"
if [ -n "$ROOT" ] && [ -d "$ROOT" ]; then cd "$ROOT" 2>/dev/null || exit 0; else exit 0; fi

# ② 컨벤션 미사용 프로젝트 → 통과 (이 프로젝트의 게이트 비용은 영원히 0)
CONV=""
[ -d docs/log ] && CONV=v2
if [ -z "$CONV" ]; then
  { [ -f MEMORY.md ] || [ -f docs/DECISIONS.md ] || [ -d docs/tech-notes ]; } && CONV=v1
fi
[ -z "$CONV" ] && exit 0

# ③ 위임 워커 면제 — git 메타데이터 마커 단일화(커밋 자체가 불가능한 위치, 워크트리별 격리).
#    작업 트리 파일 마커는 커밋 오염 경로가 있어 지원하지 않는다(2차 리뷰 #2).
GITDIR=$(git rev-parse --absolute-git-dir 2>/dev/null)
[ -n "$GITDIR" ] && [ -f "$GITDIR/hk-worker" ] && exit 0

# ④ 이번 세션에 실질 변경 없음 → 통과 (비-git 폴더·git 오류도 통과)
CHANGES=$(git status --porcelain 2>/dev/null) || exit 0
[ -z "$CHANGES" ] && exit 0

# ⑤ 기록 파일을 이미 만졌음(기록 진행/완료) → 통과. 경로 오탐 방지: 정확한 pathspec으로 별도 조회
RECTOUCHED=$(git status --porcelain -- MEMORY.md docs/log docs/DECISIONS.md docs/tech-notes docs/memory 2>/dev/null)
[ -n "$RECTOUCHED" ] && exit 0

# ⑥ 잔여 턴만 LLM 판정 — "일단락됐는데 미기록인가?"
LAST=$(json_field last_assistant_message | head -c 3500)
VERDICT=""
case "${RECORD_GATE_JUDGE:-}" in
  block) VERDICT=YES ;;
  pass)  VERDICT=NO ;;
  *)
    [ -z "$LAST" ] && exit 0
    # 중첩 판정 세션 격리: 자기 재귀는 env 가드, MCP는 strict 빈 설정, 주요 도구는 명시 차단.
    # 지시문은 위치 인자가 아니라 stdin에 합친다 — --disallowedTools가 가변 인자라 뒤따르는
    # 위치 인자를 도구 패턴으로 삼키는 실측 사고가 있다.
    # 잔여 한계(수용): 타 플러그인 훅·세션 저장까지 완전 격리하지는 않는다 — 게이트는 넛지이며
    # 판정 실패·환경 이상은 전부 fail-open. 판정 경로 생존 여부는 배포 후 E2E로 확인한다.
    VERDICT=$(printf '%s\n\n---\n%s' \
      "다음 '---' 아래는 코딩 에이전트 턴의 마지막 메시지다. 이 턴으로 실질 작업 단위(구현·수정·조사 결론·결정)가 '일단락'됐는데 기록이 없는 상태인지 판단하라. NO인 경우: 작업이 아직 진행 중(mid-work), 단순 대화·질문 답변·계획 논의, 또는 다른 에이전트/코디네이터에게 보고(worker_done·리뷰 결과 전달 등)하는 위임 워커의 마무리. 일단락+미기록이 확실할 때만 YES. 반드시 YES 또는 NO 한 단어만 출력하라." \
      "$LAST" \
      | RECORD_GATE_INNER=1 claude -p --model claude-haiku-4-5-20251001 --max-turns 1 \
        --strict-mcp-config --disallowedTools "Bash,Edit,Write,NotebookEdit,WebFetch,WebSearch,Task,Agent" \
        2>/dev/null | tr -d '[:space:]' | head -c 3)
    ;;
esac

if [ "$VERDICT" = "YES" ]; then
  if [ "$CONV" = "v2" ]; then
    printf '%s' '{"decision":"block","reason":"[기록 게이트] 일단락된 작업이 미기록으로 보인다. docs/log/YYYY-MM-DD-주제.md 조각 1개를 작성하라(박제 — 번복이면 새 조각+refs). 미결이 바뀌었으면 MEMORY.md 갱신(항목 3줄 이내), 결정이 났으면 docs/DECISIONS.md(3줄 상한). 아직 진행 중이었다면 그대로 계속하고 일단락 시점에 기록하라. 규칙 정본: record 스킬. 쓸 사실·결정·교훈이 없으면 그 사실만 한 줄로 밝히고 종료해도 된다."}'
  else
    printf '%s' '{"decision":"block","reason":"[기록 게이트] 일단락된 작업이 미기록으로 보인다. 이 프로젝트의 기존 기록 컨벤션(v1)대로 기록하라 — docs/tech-notes append + MEMORY.md 갱신(+ 새 결정이면 docs/DECISIONS.md). v2 조각 구조를 새로 만들지 마라(전환은 사용자가 /hk:record:migrate로 결정). 아직 진행 중이었다면 그대로 계속하라. 쓸 내용이 없으면 그 사실만 밝히고 종료해도 된다."}'
  fi
fi
exit 0
