#!/usr/bin/env bash
set -euo pipefail

REPO="${1:?usage: $0 /path/to/repo [session-name]}"
SESSION="${2:-agent-dev-main}"
CLAUDE_BIN="${CLAUDE_BIN:-claude}"
EFFORT="${CLAUDE_EFFORT:-max}"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Session already exists: $SESSION"
  tmux list-panes -t "$SESSION" -F '#{pane_index}: #{pane_current_command} #{pane_current_path}'
  exit 0
fi

tmux new-session -d -s "$SESSION" -x 160 -y 48 -c "$REPO" "$CLAUDE_BIN --effort $EFFORT"
tmux split-window -h -t "$SESSION":0 -c "$REPO" "$CLAUDE_BIN --effort $EFFORT"
tmux split-window -v -t "$SESSION":0.1 -c "$REPO" "$SHELL"
tmux select-layout -t "$SESSION":0 tiled

echo "Started tmux session: $SESSION"
echo "Attach: tmux attach -t $SESSION"
echo "Capture: tmux capture-pane -t $SESSION -p -S -120"
