---
audience: all-cardinals
load: on-demand
triggers: [phase-7, sa-review, pr-review]
cap-bytes: 4096
reads-before-applying: []
---

# Phase 7 — SA governance review (conditional)

**Load triggers** — SA (conditional dispatch — see below) + TL (TL4 lead-elision per `core/protocols/heavy-role-bypass.md`: single-cardinal PR collapses to SA → user; TL re-entry on multi-cardinal PR · SA REJECT · cross-domain bug surfaced · Phase 8 finalize in auto mode).

- **Conditional — fires only when at least one trigger.** Default = skip; task closes at Phase 8 without SA dispatch.

  | Trigger | Source |
  |---|---|
  | Task introduced architectural changes — ADR landed in Phase 2 OR architecture-doc edit appears in PR diff OR new component / contract / NFR-bearing claim recorded | Phase-2 dispatch returns |
  | Phase-1 SA output `post-implementation-governance: yes` | Phase-1 dispatch return |

- **Goal.** `solution-architect` confirms post-implementation coherence with architecture invariants, requirements, mockup behavioural contracts — first and only SA post-implementation surface; continuous PR-time governance is RETIRED.
- **Checks.**
  - Architecture invariants honoured (cross-check against ASR utility tree).
  - Mockup behavioural contract honoured.
  - Phase 5 manual-smoke section was actually written (empty = REJECT, return to Phase 5).
  - ASR coverage — every ASR touched by the change is addressed by ≥ 1 ADR or architecture-doc section.
- **Constraint.** Sign-off only; no code edits. SA-authored ADRs / architecture-doc deltas in this phase MUST self-lint per `core/roles/solution-architect.md § Forbidden actions` — no implementation rendering (function / member names · line numbers · commit SHAs · handler-body snippets · wiring sequences).
- **Iteration.** Runs under `core/protocols/iteration-protocol.md` when follow-up architecture-doc edits exceed 15 min.
- **Acceptance.**
  - APPROVE (with or without pending additive architecture-doc edits), OR
  - RETURN-TO-engineer with specific findings (loops back to Phase 6).
