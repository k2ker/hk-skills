---
name: api-only-boundary
description: Use when adding client/server communication, API routes, server actions, or data fetching. Enforces that browser code never touches the DB directly and that secrets never reach the client. (web-ai-docent에서 일반화·이식; 특정 앱/패키지 경로 제거)
---

# API-only Client/Server Boundary

Browser UI must never talk to the database (or Supabase) directly. Every data access goes through server-only code reached via an API route or a server action.

## Rule

The browser holds no database credentials and issues no DB/storage calls. It calls your own API surface; the server owns every database interaction.

## Flow

```text
Browser/client UI
  -> API route or server action (server-only)
  -> input validation (domain / schema layer)
  -> permission / scope check when the action is protected
  -> server-only DB / ORM / Supabase access
  -> DTO response (screen-shaped, not a raw row dump)
  -> Browser/client UI
```

The same flow applies to every app in the repo — public client, internal admin/CMS, etc. Only the permission strictness differs (a public client is read-mostly and unauthenticated; an admin surface gates on role/scope).

## Do not

- Do not put service role / secret keys in browser code.
- Do not expose secrets through `NEXT_PUBLIC_` (or any client-inlined env). Client-side env vars ship to the browser in the bundle.
- Do not shape UI around raw DB rows — map to a DTO first.
- Do not call the DB / storage directly from a public client, unless a specific public-read use case is explicitly approved and scoped.

## DTO rule

A DTO is the request/response shape of your API. Keep it safe and screen-oriented, not a 1:1 dump of DB tables. It is the seam that lets the DB schema and the UI evolve independently, and the place to drop fields the client should never see.
