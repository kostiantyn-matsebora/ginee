---
audience: all-cardinals
load: with-role-kernel
triggers: []
cap-bytes: 6144
reads-before-applying: []
---

# Role-kernel shared blocks

**Read once per role kernel.** Each role kernel CITES this file by section + supplies role-specific specifics (per-role `Source of truth` table rows · adoption axes · forbidden-action specifics · proposing-change rationale). Blocks below bind for every cardinal whose kernel carries the citation.

## §A. Source of truth — index-first read order

Index-first per `core/protocols/index-protocol.md` (`local/index/`); two-tier loading per `§ Role consumption pattern`.

- Each role kernel's `## Source of truth` table declares per-file load triggers (`always` vs scope-trigger phrase).
- Report loaded set in first response per `§ Role consumption pattern § Reporting`.
- Full source-doc read ONLY when the index entry's anchor points at a fragment needing verbatim consumption OR the role authors new content in the source. Every raw source read records a one-line justification under `## Source reads (this dispatch)` per `core/templates/phase-report.md`.
- Every cardinal also reads `local/bindings.md` · `local/project-profile.md` · `local/framework.config.yaml` per task; `local/roles/<role>.md` when present.

## §B. Estimation-first dispatch

Activated when the dispatch payload's `## Scope size` is `15-60m` or `>60m` per `core/roles/team-lead.md § Scope-size classifier`. Cardinal:

1. Returns `## Estimate` (task decomposition + per-task minutes) per `core/templates/phase-report.md § ## Estimate`, BEFORE editing, placed before `## Files touched`.
2. Orchestrator synthesizes proposals; surfaces total + per-task to user when scope warrants.
3. Specialist implements after approval — 3–5 min iterations per `core/protocols/iteration-protocol.md`, each ending in a stoppable intermediate state.

`≤15m` dispatches skip `## Estimate` — class is recorded on the dispatch payload, never silently elided. Doc edits include lossless evidence in the propose step.

## §C. Adoption research before authoring

For any sub-task with a live adopt-vs-build axis (per `core/protocols/options-protocol.md`):

- **Floor.** ≥ 1 `adopt` candidate (name · version · source · license · fit rationale) OR explicit `(none viable — <reason>)`.
- **Tagging.** Every candidate tagged `adopt` / `build` / `hybrid`; no silent mixing.
- **Self-lint.** 5 checks before surfacing per options-protocol.
- **Inapplicable scope** (rename · local bug fix · internal refactor · single-file doc tweak) → cite `"axis n/a — <reason>"` and skip.
- **Role-typical axes** declared by each role kernel.

## §D. Reporting — schema-bound returns

Schema-bound per `core/templates/phase-report.md`; self-lint against the 7 mandatory checks before report-as-done; end with `<!-- self-lint: pass -->` marker; taxonomy citations slug-glued. Role-specific attestation rows (coverage · script-quality · health-check · test-run · manual-smoke · lossless self-check · Phase-1 design-mode) land in `## Verification log` / `## Decisions made` per the role kernel's addendum.

## §E. Proposing architectural changes

When a fix / feature implies an architectural delta (new contract · topology change · stack change · NFR-affecting decision) during Phase 4 / 5 / 6:

1. Draft proposal in the final report leading with impact (wire / schema / NFR / cost — role-specific) under `## Open issues`.
2. Set `## Next dispatch needed: team-lead · architectural-delta gate · <one-line reason>`. MUST NOT request direct SA dispatch — SA is categorically refused at Phase 4 / 5 / 6 per `core/roles/solution-architect.md`.
3. Stop at stoppable intermediate state per `core/protocols/iteration-protocol.md` OR continue non-architectural work in the same dispatch (engineer judgment).
4. Team-lead surfaces user gate per `core/roles/team-lead.md § Engineer-surfaced architectural-delta gate` — outcomes are *defer to next design cycle* OR *stop + re-enter Phase 1–2*.
5. Option B → SA dispatched at Phase 1–2 only; new ADR / architecture-doc edit lands; Phase 3 re-passes; original task resumes Phase 4.

**Local fixes** (no architectural delta) route directly engineer → engineer; no team-lead gate, no SA dispatch.

## §F. Forbidden actions — lead-in

Full role-boundary list: `local/bindings.md § Project role boundaries`. Each role kernel carries only role-specific forbidden-action specifics + cross-references to the canonical list.

## §G. Doc authorship — ai-engineer pairing

`ai-engineer` runs shape + load-topology passes per `core/protocols/doc-roles.md`. SA reviews for architectural coherence on PRs that touch SA-owned files (architecture-doc invariants · contracts · NFR-bearing claims).
