# Scaffold checklist convergence

When a repo is still in scaffold-only mode, treat the checklist and decision docs as the source of truth for the current phase.

Observed rules from the `hodurang-web` M0 session:

- If the user adds or changes stack requirements mid-session, update the repo's decision doc and checklist first, then re-run verification.
- Keep the verification proof simple and direct: `git status`, tree/listing, and targeted greps against the actual repo state.
- For absence checks, avoid writing the exact searched literal into the docs as an explanatory example unless you intend that grep to match.
- When copying approved project-local skills, verify source and target counts separately and record the ledger in a repo-local README.
- Do not trust the worker summary alone if the repo docs still describe an earlier phase; resolve the docs first, then consider the worker complete.
