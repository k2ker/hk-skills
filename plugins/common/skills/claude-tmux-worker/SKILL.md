---
name: claude-tmux-worker
description: Use when coordinating Claude Code (or another CLI coding agent) as a real interactive worker in a tmux / tmux-bridge-mcp session while you stay coordinator, verifier, and reporter. Covers launching the worker, project-local MCP setup, cross-profile Hermes sharing, monitoring long-running sessions without mistaking long thinking for a block, handling permission/approval prompts safely, and verifying the worker's output. Prefer this over headless `claude -p`/print mode whenever the task is multi-turn, needs slash commands (`/init`, `/review`), or when `claude -p` fails with auth/subscription/environment errors.
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
metadata:
  hermes:
    tags: [claude-code, tmux, tmux-bridge, mcp, worker-orchestration, monitoring, approval-prompts, verification, cross-profile]
    related_skills: [claude-code, claude-worker-workflow]
---

# Claude tmux Worker

Run Claude Code as a real interactive worker while the coordinator (Hermes, or you) stays the PM, verifier, and reporter. This consolidates worker launch, monitoring, permission handling, and verification into one workflow.

```text
coordinator + verifier  ↔  interactive worker pane(s)
              \            /   (Claude Code / other CLI agent)
               tmux-bridge-mcp
                    ↓
              tmux session
```

**Operating model:** the coordinator decides and verifies; the worker edits/runs/explores. Do not trust the worker's status text alone. Keep one task per worker session. Keep custom shell scripts small — use scripts only to create/attach layout; use `tmux-bridge-mcp` (or tmux itself) for reading, messaging, and key delivery.

## When to use

- You want to coordinate Claude Code, Codex, Gemini, or another CLI coding agent as a worker.
- The worker must stay open for follow-up prompts, slash commands (`/init`, `/review`, `/effort`), or permission prompts.
- `claude -p`/print mode fails with auth/subscription/environment errors, or you want a real interactive session.
- The work is multi-turn, long-running, or must be portable to another Hermes profile or machine.
- The user mentions tmux, tmux-bridge, MCP, multiple profiles, Claude worker panes, or avoiding wrapper complexity.

Don't use this for a one-shot file edit the coordinator can safely make and verify directly.

## Setup: verify facts, don't assume

Run live checks instead of assuming environment state:

```bash
claude --version
claude auth status --text
claude --help | grep -A2 -- '--effort'
tmux -V
npx --yes tmux-bridge-mcp --version
```

Effort values are usually `low, medium, high, xhigh, max` — verify from live CLI output. Map nonstandard labels ("ultracode/ultrathink") to the highest available effort only after checking, and mention the mapping. See `references/effort-level-behavior.md`.

**MCP scope model** — do not say "MCP is installed globally" unless verified. Separate three layers:

| Layer | Meaning | Verification |
|---|---|---|
| npm global install | package installed globally | `npm list -g --depth=0 tmux-bridge-mcp` |
| `npx` execution | fetched/cached on demand | `npx --yes tmux-bridge-mcp --version` |
| client MCP config | Claude/Hermes profile can launch it | `claude mcp list`, `hermes mcp list/test` |

Preferred setup for a project pilot:

```bash
cd /path/to/repo
claude mcp add -s local tmux-bridge -- npx -y tmux-bridge-mcp
claude mcp list
```

For shared project config, add `.mcp.json` from `templates/mcp.json` and let Claude Code request project approval interactively. For Hermes profiles, add per profile and `hermes mcp test` each one — existing gateway sessions won't see new MCP tools until restart.

## Standard interactive flow

1. **Start a real TUI session** (tmux, not a foreground non-PTY terminal):
   ```bash
   tmux new-session -d -s <session> -x 160 -y 48 -c /path/to/repo 'claude --effort max'
   ```
   Done when `tmux capture-pane` shows the Claude prompt or a trust/MCP dialog.
2. **Handle startup prompts promptly.** Workspace trust + MCP approval are expected; approve in-scope and continue — don't leave the session waiting silently.
3. **Send the task / slash command.** For `/init`, type exactly `/init` + Enter. For implementation work, use `templates/worker-prompt.md`.
4. **Verify readiness before real work.** Treat `auth`/`status` as informational, not proof. Follow with a tiny real invocation (e.g. `/status` or the actual slash command) and capture the result. If `claude -p` returns `401 Invalid authentication credentials` while interactive login is valid, stop looping on print mode and use interactive tmux.
5. **Monitor in a tight loop.** Capture every 30–60s during active work, and immediately after any approval:
   ```bash
   tmux capture-pane -t <session> -p -S -120
   ```
6. **Approve per the user's scope** (see next section), with a brief approval note.
7. **Verify changes yourself** — `git status`, `git diff --stat`, inspect changed files, run project checks. Don't trust the worker's summary.
8. **Leave commits/pushes explicit** — don't commit/push unless the user explicitly requested it.

**tmux-bridge tool discipline** — read before you act:

```text
tmux_list → tmux_read(target) → tmux_message|tmux_type(target) → tmux_read(target) → tmux_keys(target, Enter) → tmux_read(target)
```

Use `tmux_name` early to label panes (`claude-implementer`, `claude-reviewer`, `shell-tests`) and avoid brittle pane IDs.

## Monitoring: long thinking is not a block

A worker being silent or in long reasoning is **not** itself a problem. Keep monitoring until one of: a real permission prompt, a real block/error, a completed task, or explicit user steering.

- Long max-effort reasoning often runs many minutes before edits appear — preserve that thinking time. Do **not** take over, redirect to direct edits, interrupt, Ctrl-C, or shrink scope just because it is slow.
- Distinguish **reasoning** (pane shows activity, no explicit question) from **prompt wait** (explicit question + no progress). A worker sitting on a routine confirmation is *blocked*, not thinking.
- If the same prompt/idle state persists for ~2 minutes, re-capture and then surface it as a real block.
- Only report when state changes or the worker has been idle long enough to matter.

## Permission / approval handling

The repeated failure mode: the worker is waiting for a prompt, and the coordinator must decide to approve, escalate, or stop.

**Approve immediately (with a short note)** when the action is in the user's already-approved scope and has no external side effect: local installs, test/lint/build runs, file reads/scaffolding, capture/inspection commands. Report then approve — e.g. `tmux send-keys -t <session> 1 Enter` when option 1 is the safe choice — then re-capture within seconds.

**Stop and ask** before external side effects the user did not approve: git commit/push, deploy, Caddy/PM2 changes, production changes, public posting, account deletion, destructive data changes, secret exposure.

Response templates:

```text
승인요청: <prompt or command>
범위: <why this is in-scope>
조치: 승인하고 계속 진행합니다.
```
```text
승인요청: <prompt or command>
범위: <why this is out of scope>
조치: 여기서는 승인하지 않고 확인을 기다립니다.
```

A previous approval is **not** universal permission — a later command can ask for a fresh confirmation; keep surfacing each one. If the same prompt recurs after you approved it, the approval likely didn't reach the active pane, or the worker is behind a nested confirmation — re-capture and re-send to the correct pane.

## Progress reporting format

Report verified state changes, not speculation about "taking too long". Report: after startup/auth/MCP approval; when a long scan or subagents start; every few minutes while active; immediately when the worker waits for permission; immediately before/after approving; when files change or commands start; immediately on completion or failure.

```text
상태: 작업 중 / 대기 / 완료 / 차단
근거: <latest tmux capture summary>
진행: <what changed or what the worker is doing>
권한: <requested/approved/denied, if any>
다음: approve / wait / verify / ask user
```

Example:

```text
상태: 작업 중 / 권한 대기 없음
근거: Claude가 max effort로 6분째 설계 중입니다.
진행: 아직 파일 수정 전, Supabase 문서 확인 중입니다.
다음: long-thinking은 block이 아니므로 끊지 않고 계속 모니터링합니다.
```

## Verification checklist

- [ ] Active repo/branch confirmed with `git status -sb`.
- [ ] Claude version/auth/effort checked from live CLI output.
- [ ] tmux session exists and was captured after launch.
- [ ] MCP scope stated accurately (npm global vs npx vs profile config).
- [ ] Permission prompts handled per the user's approval scope; no secrets printed.
- [ ] Changed files inspected with `git diff --stat` and relevant reads/diffs.
- [ ] Lint/typecheck/build run or skipped with reason; for auth/session/token changes, run an authenticated smoke too.
- [ ] Commit/push/deploy/public posting only after explicit request.

## Portable project artifacts

Put reusable rules in the repo, not only one Hermes profile: `CLAUDE.md` (coding contract), `docs/AI_COLLABORATION.md` (roles + reporting), `.mcp.json` (shared MCP config, from `templates/mcp.json`), optional `.claude/commands/*.md`, optional `scripts/agent-layout.sh` (tiny tmux layout bootstrap only — don't reimplement bridge tools). Mirror durable parts into repo docs; profile-local runbooks aren't portable. Before implementation/review work, read the repo's `CLAUDE.md`, `docs/AI_COLLABORATION.md`, relevant `docs/api/*`, and any review artifacts (see `references/project-discovery-and-doc-review.md`).

## Common pitfalls

1. **Assuming `npx` means global install.** It doesn't — check the npm global list separately.
2. **Relying on `claude -p` for interactive work.** If headless 401s or the user wants real Claude Code, use tmux interactive mode.
3. **Letting the worker wait silently after the user authorized progress.** That's an operator failure. Capture often, approve in-scope prompts immediately with a short note, ask only for newly dangerous scope.
4. **Approving side effects because the session already did harmless work.** Safe and risky actions stay separate.
5. **Taking over because the worker is still thinking.** Long reasoning is not a block.
6. **Approving the wrong pane.** Always capture first, then respond.
7. **Trusting the worker's claims.** Verify with git diff, file reads, and command output before finalizing.
8. **Overbuilding wrappers.** Keep scripts for layout; let tmux-bridge handle read/message/key actions.
9. **Ignoring project-local skills.** A sparse `.claude/skills/` listing is not proof of absence — inspect backing files.
10. **Editing other Hermes profiles casually.** Only add profile MCP config when the user asked for multi-profile support; verify each separately.

## Support files

- `templates/mcp.json` — project MCP server definition for shared config.
- `templates/worker-prompt.md` — self-contained implementation-worker prompt.
- `templates/agent-layout.sh` — minimal tmux layout bootstrap.
- `references/effort-level-behavior.md` — observed effort menu/runtime mismatch note.
- `references/project-discovery-and-doc-review.md` — repo doc/review-artifact discovery before editing.
