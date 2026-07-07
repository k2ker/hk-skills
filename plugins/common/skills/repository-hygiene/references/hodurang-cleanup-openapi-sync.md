# Hodurang cleanup + OpenAPI sync pattern

Session pattern captured from a Hodurang React Native cleanup.

## Situation

The repo had accumulated Task Master, Serena, Claude skill, MCP, GitHub instruction, temp plan, incident, backend-guide, and API-change markdown artifacts. The user wanted a clean current-state project, using git history to decide what was already reflected or obsolete, and wanted the API docs synchronized to the current backend.

## Useful evidence steps

- `git log --since='18 months ago' --name-status --pretty=format:'%h %ad %s' --date=short -- '*.md' '.claude/**' '.taskmaster/**' '.serena/**' '.mcp.json' '.github/instructions/**'`
- `git grep -n -E -i '(\.claude|task[- ]?master|taskmaster|serena|\.taskmaster|\.mcp|mcpServers|SKILL\.md|references/)' -- ':!package-lock.json' || true`
- `git ls-files '*.md' 'docs/api/openapi-snapshot.json' | sort`

## Classification that worked

Removed:

- `.claude/commands/tm/**`
- `.claude/skills/**` shells
- `.taskmaster/**`
- `.serena/**`
- `.mcp.json`
- `.github/instructions/**`
- `.env_.example` when it only contained AI provider/task tool examples
- `docs/plans/**`, `docs/temp/**`
- one-off backend request/incident docs after no live references remained
- old API delta/changelog markdown after current docs reflected the content

Moved/preserved:

- API skill reference docs became normal `docs/api/*.md` docs.
- `swagger.md` became `docs/api/openapi-snapshot.json` because the content was OpenAPI JSON, not Markdown.

## OpenAPI sync verification

Live fetch showed `paths 70 -> 80`, `schemas 74 -> 91`, with 10 added paths and 0 removed paths. The key added paths were quiz-sharing and mypage endpoints.

The reliable completeness check was to parse `docs/api/openapi-snapshot.json` and compare against endpoint headings in `docs/api/*.md`:

```python
import json, re
from pathlib import Path
root = Path('.')
data = json.loads((root/'docs/api/openapi-snapshot.json').read_text())
live = set(data['paths'])
doc = set()
for p in root.glob('docs/api/*.md'):
    if p.name == 'schemas.md':
        continue
    doc |= set(re.findall(r'`(?:GET|POST|PUT|PATCH|DELETE) ([^`]+)`', p.read_text()))
print('live_paths', len(live))
print('doc_paths', len(doc))
print('missing', len(live-doc))
print('extra', len(doc-live))
```

Expected successful result:

```text
live_paths 80
doc_paths 80
missing 0
extra 0
```

## Verification notes

- `git diff --check` caught whitespace issues and passed.
- `npm run lint` initially failed on an unrelated JSX `react/no-unescaped-entities` error. A small text escape (`"` -> `&quot;`) made lint pass without functional change.
- `npm run typecheck` passed.
- `npm install` was needed only because `node_modules` was absent. Do not record absence as a durable repo problem.

## Reporting nuance

When stale-reference grep reports `anthropic.claude-...`, that is an AWS Bedrock model ID and should not be counted as a stale Claude/agent artifact.
