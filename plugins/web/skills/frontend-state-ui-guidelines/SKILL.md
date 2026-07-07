---
name: frontend-state-ui-guidelines
description: Use when implementing forms, server-state fetching, HTTP clients, or UI motion — picks the right tool per concern. Defers per-tool detail to the dedicated skills. (web-ai-docent에서 일반화·이식; 앱/패키지 경로 제거)
---

# Frontend State and UI Guidelines

The default stack policy for React frontends: which tool owns which concern, plus the one hard data boundary. This skill is the umbrella — for per-tool detail, open the dedicated skills instead of re-deriving it here.

## Concern → tool

| Concern | Use | Detail skill |
|---|---|---|
| Server state (fetch / cache / sync) | TanStack Query | `tanstack-query`, `web-tanstack-query-patterns` |
| Substantial forms | TanStack Form | `tanstack-form` |
| HTTP calls | app-local axios instance | `web-tanstack-query-patterns` |
| Product motion | Framer Motion | `framer-motion-animator` |

## Rules

- **Server state = TanStack Query.** Query keys centralized / factory-style — never hand-write ad-hoc key arrays inside components. Invalidate narrowly after mutations, not the whole cache.
- **Forms = TanStack Form.** Keep validation near the domain / API contract. Don't mix in a second form library without a reason.
- **HTTP = one app-local axios instance.** Keep response DTOs typed. Reach for `fetch` only when the platform requires it (streaming, special upload constraints).
- **Motion = Framer Motion.** Respect reduced-motion. Avoid decorative animation that hurts clarity or mobile performance.

## Data boundary

Browser UI calls your API, never the database directly. That boundary — server-only DB access, no client secrets, DTO responses — is owned by the `api-only-boundary` skill; follow it whenever a component fetches or mutates.

## Design boundary

Shared, product-agnostic primitives live in the shared UI package. Product-specific screen composition stays in the app that owns the screen.
