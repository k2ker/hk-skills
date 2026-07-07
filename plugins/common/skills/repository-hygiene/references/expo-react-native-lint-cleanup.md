# Expo / React Native warning cleanup after repository hygiene

Use this when a repo hygiene pass removes stale docs/agent files and then needs code-quality cleanup in an Expo Router / React Native TypeScript app.

## Safe-first warning order

1. Run lint in JSON form and group by rule before editing.
2. Auto-apply behavior-preserving warnings first:
   - `@typescript-eslint/no-unused-vars`: remove unused imports, unused destructured values, unused local variables.
   - `import/no-duplicates`: merge imports from the same module.
   - `import/no-named-as-default`: if a module exports both `export const logger` and `export default logger`, prefer the named import consistently.
   - `@typescript-eslint/no-empty-object-type`: replace an empty extending interface with a type alias to the supertype when no extra fields exist.
3. Re-run `npm run lint` and `npm run typecheck` after safe edits.
4. Treat `react-hooks/exhaustive-deps` as a second phase; blindly adding dependencies can duplicate API mutations or navigation.

## React hook dependency cleanup

- If a missing dependency is a helper returned by a local hook, stabilize the helper inside that hook with `useCallback`, then include it in the consumer dependency array.
- If a callback is referenced by an effect, define the callback before the effect to avoid temporal-dead-zone issues.
- For effects that intentionally make a one-shot API request or route transition, use a `useRef` execution guard and include the full dependency list. This documents the one-shot intent while preventing duplicate calls.

Example:

```tsx
const hasRequestedRef = useRef(false);

useEffect(() => {
  if (hasRequestedRef.current) return;
  hasRequestedRef.current = true;

  submitMutation.mutate(formData, callbacks);
}, [submitMutation, formData, callbacks]);
```

## Dev-only route cleanup

For app files named like `*test*`, `*Test*`, or explicit dev routes such as `bottom-sheet-test.tsx`:

1. Search for references with `git grep` before deleting.
2. Remove user-visible dev entry points first, even if they are guarded by `__DEV__`, when the task is production/repo hygiene.
3. Delete wrapper route files and demo components after references are gone.
4. Re-run grep for the route/component names to prove no references remain.

## Verification commands

```bash
npm run lint
npm run typecheck
git diff --check
git grep -n -E 'bottom-sheet-test|diary-modal-test|DiaryCompleteModalTest|\[DEV\]' -- ':!package-lock.json' || true
```

A clean endpoint is lint with zero errors/warnings, typecheck pass, diff check pass, and no dev-route grep hits.
