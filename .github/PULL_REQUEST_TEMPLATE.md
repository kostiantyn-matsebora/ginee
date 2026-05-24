# Pull Request

## Summary

Describe what changed and why.

## Changes

- Describe the concrete changes in this PR.

## Acceptance criteria

<!-- For issue-sourced PRs, mirror the AC list from the issue and tick each. -->

- [ ] AC#1 — ...
- [ ] AC#2 — ...

## Verification

| Command | Outcome |
|---|---|
| `<test / lint / build>` | `<pass / fail / counts>` |

**Manual smoke** (if user-visible behaviour touched): `<result>` / `<not applicable — doc-only change>`.

## Checklist

- [ ] Scope is focused and intentionally limited
- [ ] Documentation was updated if behaviour changed
- [ ] Migration note added under `migrations/` for any change adopters must apply manually
- [ ] Role kernels + adapters stayed in sync if a generic-process rule changed
- [ ] Issue linkage uses `Fixes #N` / `Closes #N` so GitHub auto-closes on merge

## Out of scope (explicit alternatives considered)

<!-- For any design call where you took one path and rejected another, document the rejected alternative here so reviewers can redirect. -->

- `<alternative considered>` — `<why rejected>`

## Notes

Anything reviewers should pay special attention to.
