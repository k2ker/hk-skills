#!/bin/bash
# git-sync-guard.sh 회귀 테스트 — 로컬 bare 원격만 쓰므로 네트워크 불필요.
# 사용: bash scripts/tests/git-sync-guard.test.sh  (repo 관리용 — 플러그인으로 배포되지 않는다)
set -u
GATE="$(cd "$(dirname "$0")/../.." && pwd)/plugins/hk/hooks/git-sync-guard.sh"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0

# 훅 입력(JSON) 만들기
input() { python3 -c '
import json, sys
print(json.dumps({"tool_name": "Bash", "tool_input": {"command": sys.argv[1]}, "cwd": sys.argv[2]}))' "$1" "$2"; }

# 훅 출력 → DENY / WARN / SILENT
verdict() { python3 -c '
import json, sys
raw = sys.stdin.read().strip()
if not raw:
    print("SILENT")
else:
    out = json.loads(raw)["hookSpecificOutput"]
    print("DENY" if out.get("permissionDecision") == "deny" else "WARN")'; }

check() {  # check <이름> <기대> <명령> <cwd>
  # fetch 를 막지 않는다 — 원격이 로컬 bare 저장소라 네트워크를 타지 않고, 실제 경로 그대로 검증된다
  got=$(input "$3" "$4" | "$GATE" | verdict)
  if [ "$got" = "$2" ]; then
    PASS=$((PASS + 1)); echo "ok   $1"
  else
    FAIL=$((FAIL + 1)); echo "FAIL $1 — 기대 $2, 실제 $got"
  fi
}

# ── 픽스처: origin 에 커밋 3개. AHEAD=최신 상태, BEHIND=2개 뒤처진 상태
git init -q --bare "$T/origin.git"
git clone -q "$T/origin.git" "$T/ahead" 2>/dev/null
( cd "$T/ahead" && echo 1 > f && git add -A && git commit -qm c1 && git push -q origin HEAD )
git clone -q "$T/origin.git" "$T/behind" 2>/dev/null
( cd "$T/ahead" && echo 2 >> f && git commit -qam c2 && echo 3 >> f && git commit -qam c3 && git push -q )
mkdir "$T/notgit"
BR=$(cd "$T/ahead" && git branch --show-current)

echo "== 핵심 동작 =="
check "뒤처진 push 는 막는다"       DENY   "git push"                          "$T/behind"
check "최신 push 는 통과"           SILENT "git push"                          "$T/ahead"
check "뒤처진 commit 은 알리기만"   WARN   "git commit -m x"                   "$T/behind"
check "최신 commit 은 조용히"       SILENT "git commit -m x"                   "$T/ahead"
check "add && push 도 잡는다"       DENY   "git add -A && git push origin $BR" "$T/behind"

echo "== 오해하지 않기 =="
check "git log --grep push"         SILENT "git log --grep push"               "$T/behind"
check "커밋 메시지 속 push"         WARN   "git commit -m 'prepare push'"      "$T/behind"
check "git 아닌 명령"               SILENT "ls -la"                            "$T/behind"

echo "== 다른 저장소를 가리킬 때 =="
check "-C 로 지정한 저장소를 본다"  DENY   "git -C $T/behind push"             "$T/ahead"

echo "== 이상한 상황에서는 통과 =="
check "저장소가 아닌 폴더"          SILENT "git push"                          "$T/notgit"
got=$(printf 'not-json' | "$GATE" | verdict)
if [ "$got" = SILENT ]; then PASS=$((PASS + 1)); echo "ok   깨진 입력"
else FAIL=$((FAIL + 1)); echo "FAIL 깨진 입력 — 기대 SILENT, 실제 $got"; fi

echo; echo "결과: PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
