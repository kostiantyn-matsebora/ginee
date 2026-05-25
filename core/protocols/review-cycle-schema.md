# Review-cycle schema

**Load-on-demand.** Loaded when `team-lead` runs `ginee-address-review` / `@team-lead address-review #<N>` — per-thread reply authoring · sticky cycle-summary post · reconciliation commit.

Procedure + plan-table contract + idempotency + lossless coverage rule live in `core/protocols/github-integration.md § Review-comment ingestion`. Sticky-summary literal template lives in `core/templates/pr-comment-cadence.md`. This file binds the **rules + self-lint** across both surfaces.

## Schema

Two surfaces per cycle:

| Surface | Authored by | Cardinality | Cite |
|---|---|---|---|
| **Per-thread reply** | dispatched specialist (reply-track) — text + marker; team-lead posts via API | 1 per addressed thread per cycle | `core/protocols/github-integration.md § Review-comment ingestion § Comment cadence` |
| **Sticky cycle summary** | `team-lead` at cycle end | 1 per cycle (hard cap; immutable cycle log) | `core/templates/pr-comment-cadence.md` |

| Element | Required on | Source |
|---|---|---|
| Per-thread marker `<!-- ginee:review-reply r=<thread-id> -->` | every per-thread reply | `core/protocols/github-integration.md § HTML markers` |
| Sticky cycle marker `<!-- ginee:review-cycle n=<N> -->` | every sticky | `core/protocols/github-integration.md § HTML markers` |
| Cycle headline `**Review cycle <N>:** <M> remarks addressed (<K> code, <M-K> reply). HEAD: <sha>.` | sticky | `core/templates/pr-comment-cadence.md § Format` |
| Thread table — 4 columns (`Thread · File:line · Role · Action`) | sticky | `core/templates/pr-comment-cadence.md § Format` |
| Reply body — specialist-authored rationale / decline-with-cite / deferred-to-#N | per-thread reply | `core/protocols/github-integration.md § Review-comment ingestion` |
| Self-lint marker `<!-- self-lint: pass -->` | every surface | Last line per `core/protocols/doc-authoring-protocol.md § Enforcement for ginee-authored GitHub artefacts` |

`thread-id` = last 6 chars of GitHub thread-id. `<N>` = count of prior `ginee:review-cycle` markers + 1.

## Section templates

### Per-thread reply

```
<specialist-authored reply text — rationale OR decline-with-cite OR deferred-to-#N>

<!-- ginee:review-reply r=<thread-id> -->
<!-- self-lint: pass -->
```

### Sticky cycle summary

Literal template per `core/templates/pr-comment-cadence.md § Format`; fields per `core/templates/pr-comment-cadence.md § Fields`. `<sha>` renders `(no code changes)` when the cycle was reply-only.

## Forbidden patterns

1. **Editing a prior cycle's sticky.** Cycles are immutable; new cycle = new sticky. Per `core/templates/pr-comment-cadence.md § Forbidden`.
2. **Posting a mid-cycle progress comment.** The cycle summary IS the progress signal.
3. **Inlining thread `body` text** in the sticky. Link via thread-id only.
4. **Team-lead paraphrasing a specialist reply.** Specialist owns the wording; team-lead never rewrites.
5. **Bypassing the user-confirmation gate** for "trivial" remarks. Per `core/protocols/github-integration.md § User-confirmation gate` — forced-interactive even under `auto:`.
6. **Silent drops.** Every plan-table thread ends the cycle as **fix** OR **reply** per the lossless coverage rule.
7. **PII in sticky cells** — reviewer handles · raw comment text. Cells are summary digests only.

## Worked example

Per-thread reply (decline track):

```
The async overload was considered in ADR-0006-sync-orm-boundary; the synchronous
boundary is intentional. Closing on existing decision.

<!-- ginee:review-reply r=def123 -->
<!-- self-lint: pass -->
```

Sticky cycle summary:

```
<!-- ginee:review-cycle n=1 -->
**Review cycle 1:** 3 remarks addressed (2 code, 1 reply). HEAD: abc1234.

| Thread | File:line | Role | Action |
|---|---|---|---|
| T#abc | backend/api/users.cs:42 | backend-engineer | fix → abc1234 |
| T#def | docs/architecture.md:88 | solution-architect | reply (decline — cites ADR-0006) |
| T#ghi | frontend/src/login.tsx:17 | frontend-engineer | fix → abc1234 |

<!-- self-lint: pass -->
```

## Self-lint checks

Run against every per-thread reply + sticky summary **before** posting:

1. Per-thread reply ends with the `ginee:review-reply r=<thread-id>` marker; `<thread-id>` matches the plan-table `T#<short-id>` column.
2. Sticky starts with the `ginee:review-cycle n=<N>` marker; `<N>` = count of prior cycle markers + 1.
3. Cycle headline numerics add up — `<M> = <K> + <M-K>`; HEAD `<sha>` matches the cycle commit (or `(no code changes)` on reply-only).
4. Thread table has exactly 4 columns; one row per addressed thread; `Action` collapses `proposed action` + landed-commit ref.
5. Lossless coverage — count of plan-table threads = count of `ginee:review-reply` markers + fix-touched-thread mappings. Gap → re-dispatch.
6. Doc-authoring 5 mandatory checks per `core/process.md § Documentation style § Mandatory checks`.

Append, as the **last line** of each posted surface, the literal attestation marker `<!-- self-lint: pass -->`.

<!-- self-lint: pass -->
