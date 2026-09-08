#!/bin/bash
# git 동기화 가드 — 원격이 앞서 있는데 모르고 미는 사고를 막는다.
#
#   git push   → 원격에 새 커밋이 있으면 차단하고 목록을 보여준다
#   git commit → 알려만 주고 통과시킨다 (커밋은 세이브포인트라 막으면 오히려 위험)
#
# 이건 자물쇠가 아니라 안전벨트다. 판별은 단순하게 두고, 뭐가 하나라도 어긋나면
# 무조건 통과시킨다(fail-open) — 못 잡는 경우는 있어도 작업을 막는 경우는 없다.
#
# 테스트: <repo>/scripts/tests/git-sync-guard.test.sh (배포 제외 — repo 관리용)

INPUT=$(cat 2>/dev/null)

# ── 1. 이 명령이 git push 인가 git commit 인가? (아니면 여기서 끝)
#    git 뒤의 전역 옵션을 건너뛰고 첫 서브커맨드를 본다 — `git log --grep push` 같은 걸
#    push로 오해하지 않기 위함. 따옴표 안 경로처럼 특이한 형태는 그냥 놓친다(안전벨트).
PARSED=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    cmd = (json.load(sys.stdin).get("tool_input") or {}).get("command", "")
except Exception:
    sys.exit(0)

TAKES_VALUE = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path"}
words = cmd.replace("&&", " ; ").replace("||", " ; ").replace("|", " ; ").split()
mode, cdir = "", ""

for i, word in enumerate(words):
    if word != "git" or (i > 0 and words[i - 1] != ";"):
        continue
    j = i + 1
    here = ""
    while j < len(words) and words[j].startswith("-"):     # 전역 옵션 건너뛰기
        if words[j] in TAKES_VALUE:
            if words[j] == "-C" and j + 1 < len(words):
                here = words[j + 1].strip("\"'"'"'")
            j += 2
        else:
            j += 1
    sub = words[j] if j < len(words) else ""
    if sub == "push":
        mode, cdir = "push", here
        break                                              # push 가 있으면 그게 우선
    if sub == "commit" and not mode:
        mode, cdir = "commit", here

print(mode)
print(cdir)
' 2>/dev/null)

MODE=$(printf '%s\n' "$PARSED" | sed -n 1p)
CDIR=$(printf '%s\n' "$PARSED" | sed -n 2p)
[ "$MODE" = push ] || [ "$MODE" = commit ] || exit 0

# ── 2. 어느 저장소인지 확정 (못 찾으면 통과)
CWD=$(printf '%s' "$INPUT" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("cwd",""))' 2>/dev/null)
[ -n "$CWD" ] && [ -d "$CWD" ] || exit 0
cd "$CWD" 2>/dev/null || exit 0

GIT=(git)
[ -n "$CDIR" ] && GIT=(git -C "$CDIR")
"${GIT[@]}" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# ── 3. 비교 대상 = 실제 push 목적지(@{push}), 없으면 upstream. 둘 다 없으면 통과
TARGET=$("${GIT[@]}" rev-parse --abbrev-ref --symbolic-full-name '@{push}' 2>/dev/null)
[ -z "$TARGET" ] && TARGET=$("${GIT[@]}" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
[ -z "$TARGET" ] && exit 0

# ── 4. 원격 확인 (네트워크 문제·인증 프롬프트는 전부 통과 처리)
if [ "${GIT_SYNC_GUARD_NO_FETCH:-}" != "1" ]; then
  GIT_TERMINAL_PROMPT=0 "${GIT[@]}" fetch --quiet --no-tags "${TARGET%%/*}" "${TARGET#*/}" 2>/dev/null || exit 0
fi

BEHIND=$("${GIT[@]}" rev-list --count "HEAD..$TARGET" 2>/dev/null)
case "$BEHIND" in ''|*[!0-9]*) exit 0 ;; esac
[ "$BEHIND" -eq 0 ] && exit 0

# ── 5. 알린다: push 면 차단, commit 이면 안내만
NEW_COMMITS=$("${GIT[@]}" log --oneline -3 "HEAD..$TARGET" 2>/dev/null)

MODE="$MODE" TARGET="$TARGET" BEHIND="$BEHIND" NEW_COMMITS="$NEW_COMMITS" python3 -c '
import json, os
target, behind, new = os.environ["TARGET"], os.environ["BEHIND"], os.environ["NEW_COMMITS"].strip()

if os.environ["MODE"] == "push":
    out = {"permissionDecision": "deny", "permissionDecisionReason":
           f"[git 동기화 가드] {target} 에 로컬에 없는 커밋 {behind}개가 있다:\n{new}\n"
           "지금 push 하면 거부되거나 이력이 꼬인다. 새 커밋을 확인하고 rebase 또는 merge 로 "
           "합친 뒤 다시 push 하라. --force 로 우회하지 마라."}
else:
    out = {"additionalContext":
           f"[git 동기화 가드] 참고: {target} 이 {behind}커밋 앞서 있다:\n{new}\n"
           "커밋은 그대로 진행하고, push 전에 합쳐라."}

out["hookEventName"] = "PreToolUse"
print(json.dumps({"hookSpecificOutput": out}, ensure_ascii=False))
'
exit 0
