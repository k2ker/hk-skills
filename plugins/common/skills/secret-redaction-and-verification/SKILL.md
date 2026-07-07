---
name: secret-redaction-and-verification
description: "Handle PATs, API keys, bot tokens, and other secrets safely: refuse raw values, report only paths or existence, verify access with non-secret calls, and guide safe rotation or storage."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [macos, linux]
metadata:
  hermes:
    tags: [security, secrets, tokens, pat, api-key, redaction, verification]
---

# Secret Redaction and Verification

Use this skill when the user asks for PATs, API keys, bot tokens, OAuth credentials, or the location/state of secrets. This applies across Slack, GitHub, Docker, npm, local `.env` files, and other credential stores.

## Core rule

Never output raw secret values in chat, logs, or generated files.

You may safely provide:

- the credential file path or store name
- whether a secret file exists
- whether a token is likely present in a file
- whether authentication succeeded, using a separate non-secret verification call
- scope/permission summary after verification
- rotation or re-issuance steps

## Response pattern

When asked for a secret value:

1. Refuse the raw value briefly.
2. Offer a safe alternative: existence check, auth check, scope check, or file path.
3. If the user asks “where is it?”, answer with path(s) only.
4. If the user asks “does it work?”, verify with a non-secret API call or CLI auth test.
5. If the user needs integration, use the secret locally without printing it.

Example:

```text
토큰 원문은 출력할 수 없습니다.
대신 경로/존재 여부/인증 상태는 확인해드릴 수 있습니다.
```

## Safe location reporting

When reporting locations, keep these boundaries:

- Print full paths, but not file contents.
- Separate each service by name so the user can see what belongs to what.
- Do not imply one token covers another service unless it has been verified.
- If several common stores exist, list them as candidates and state which were actually found.

Example safe output format:

```text
확인된 위치:
- Slack bot token: ~/.hermes/.../token.secret
- GitHub CLI auth: ~/.config/gh/hosts.yml
- npm token: ~/.npmrc
```

## Verification pattern

Use a non-secret probe before saying a token is usable:

- `auth.test`, `whoami`, or equivalent login check
- workspace/project/team ID comparison
- scope inspection where available
- read-only metadata fetch for the relevant service

If verification fails, report the failure mode without dumping the token.

## Pitfalls

- Do not confuse “I can see the token file” with “the token is valid.” Verify separately.
- Do not paste secrets into chat “for the admin” or “for quick debugging.”
- Do not group unrelated credential stores together; always identify the service.
- Do not create a permanent rule that a specific path or environment variable is the only valid place for a secret. Locations can change.
- If the user asks for a value and also asks where it is, answer the location only and keep the value withheld.

## References

- `references/secret-redaction-and-locations.md` — session-derived examples of safe replies, location reporting, and verification boundaries.
