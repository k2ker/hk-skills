# Claude effort-level behavior notes

## Observed behavior in this session

- `claude --help` listed effort flags as: `low`, `medium`, `high`, `xhigh`, `max`.
- The interactive `/effort` picker also displayed `ultracode`.
- On the current Claude Code build used here, selecting `/effort ultracode` did **not** change the session away from `max`.
- The UI response was effectively: `Kept effort level as max`.

## Practical rule

When a user asks for `ultracode`, confirm the resulting session state from the CLI/UI status line instead of assuming the label changed the runtime effort. If the session stays at `max`, report that plainly.

## Why this matters

The effort menu label can imply a higher setting than the session actually applies. For coordination work, treat the confirmed session state as source of truth, not the menu wording alone.