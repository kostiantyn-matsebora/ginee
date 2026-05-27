---
audience: all-cardinals
load: on-demand
triggers: [phase-4, implementation]
cap-bytes: 4096
reads-before-applying: []
---

# Phase 4 — Implementation

**Load triggers** — cardinals with `phase-participation:` including `4`. Heavy-role-bypass per `core/protocols/heavy-role-bypass.md` — TL on entry (sub-issue pickup) OR re-entry trigger; SA on SA1 governance dip.

- **Goal.** Working code mirroring approved Phase 2 contracts.
- **Rules.**
  - Each engineering role implements its part in its owned paths (`local/bindings.md`).
  - Parallel where independent.
  - Phase 5 overlaps once Phase 3 passes.
  - Iteration protocol when scope > 15 min — `core/protocols/iteration-protocol.md`.
- **Blueprint-diff entry precondition.** Every dispatch touching the configured `visual-source-of-truth.path` runs `core/protocols/blueprint-diff-protocol.md` as first step — diff vs `blueprint-ref` · classify Expected / Unexpected / Pre-existing · surface to team-lead before any edit. Unexpected delta → forced-interactive gate (auto-mode does NOT elide). Inapplicable when dispatch carries no edit on the configured path — cite `"visual-SoT untouched — protocol n/a"` and skip.
- **`solution-architect` governance dip.** Triggered only when the in-flight PR touches an SA-owned file per `local/bindings.md § Source-of-truth ownership` (NOT every Phase 4 PR). Spot-checks engineer deltas against architecture invariants + ASRs. Drift → PR comment + dispatch back to owning engineer. Per `core/roles/solution-architect.md § Governance`.
- **`solution-architect` review on in-flight proposals.** If an engineer proposes an architectural change mid-Phase 4 (new contract / topology / stack / NFR-affecting decision), SA reviews per `§ Review` — APPROVE / REJECT / REQUEST-CHANGES. SA never edits the engineer's code.
- **Acceptance.**
  - Compiles / builds clean.
  - No new lint or type errors.
  - **Engineer self-verify per `core/protocols/engineer-self-verify.md`** — strict gate, not advisory. Every change-scoped suite available to the role MUST run green OR MUST carry an `n/a — <reason>` / `stale — <reason>` cite in `## Verification log`. Replaces the prior unit-only floor. Non-compliance blocks Phase 4 acceptance; team-lead MUST return the dispatch for completion. QA backstops in Phase 5 per `phase-5-testing.md § Goal`.
