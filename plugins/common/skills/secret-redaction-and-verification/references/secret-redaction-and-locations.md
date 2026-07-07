# Secret redaction and location reporting

Session-derived note: when the user asks for PATs, API keys, bot tokens, or other secrets, answer with safe alternatives only.

## Safe reply pattern

- Refuse the raw value briefly.
- Offer one of: existence check, auth check, scope check, or file path.
- If the user asks “where is it?”, return path(s) only.
- If the user asks “does it work?”, verify with a non-secret call.

## Example safe locations observed in this workspace

- Slack bot token: `~/.hermes/slack-apps/agoldenwalnut-hermes-ops-agent/agoldenwalnut-bot-token.secret`
- GitHub CLI auth: `~/.config/gh/hosts.yml`
- npm token store: `~/.npmrc`
- Docker registry auth: `~/.docker/config.json`
- Hodurang local env: `~/Agoldenwalnut/repos/hodurang/.env.local`

These are path-only notes. Never print the secret values themselves.
