---
audience: all-cardinals
load: on-demand
triggers: [engineer-self-verify, phase-4, before-handoff]
cap-bytes: 6144
reads-before-applying: []
---

# Engineer self-verify — change-scoped fix-loop before QA hand-off

- **Binding.** Strict constraint, not advisory. Phase 4 hand-off non-compliant with this protocol violates `core/process/phase-4-implementation.md § Acceptance`. Bypass only via explicit user direction recorded in the phase report — never silent.
- **Load triggers.** `frontend-engineer` · `backend-engineer` · `devops-engineer` MUST load at Phase 4 report-as-done. `qa-engineer` MUST load at Phase 5 entry (binds `§ Independent re-execution`).
- **Goal.** Engineer MUST run every available change-scoped suite in a fix → re-test loop until green BEFORE Phase 4 hand-off. QA's Phase 5 pass is backstop (independent re-execution + AC compliance), never first-pass discovery.

## Available-suite matrix

Engineer MUST run every row whose runner is configured per `local/bindings.md` AND whose surface is exercised by the change.

| Role | Suites |
|---|---|
| `frontend-engineer` | Component unit · E2E flows hitting changed surface · pixel-check when `qa.pixel-check.enabled: true` AND visual surface touched. |
| `backend-engineer` | Unit per `§ Coverage obligation` · API / functional against the real local stack (never mocked, per `core/roles/qa-engineer.md § Required test layers`) · integration covering touched endpoints / migrations. |
| `devops-engineer` | Script lint + Pester / bats per `§ Script-quality obligation` · local-orchestration post-step health per `§ Post-step health verification` · deploy smoke against reachable environments. |

## Loop mechanics

Numbered procedure — every step implicitly MUST.

1. **Inventory.** List the change-scoped suites the engineer's role owns per matrix; cross out skip-rule cases with cited reason.
2. **Run.** Execute each in turn. Red suite triggers stoppable intermediate state per `core/protocols/iteration-protocol.md § Stoppable intermediate states`.
3. **Triage red suites.** For each failing assertion, classify per `core/process.md § Test oracles can be wrong`:

   | Failure type | Engineer action |
   |---|---|
   | **Real defect** — code does not match its still-valid contract | Fix code in same task; re-run; loop until green. |
   | **Stale oracle** — engineer's intentional contract change made the assertion obsolete | MUST NOT modify code to satisfy the assertion · MUST NOT edit the test (per `core/roles/{frontend,backend,devops}-engineer.md § Forbidden`) · MUST flag in `## Verification log` as `<suite> stale — <contract change> requires QA oracle update` · QA owns the update + re-execution. |

4. **Re-test.** After every code fix, re-run the suite + any sibling suite the fix could regress. Loop until green OR every red suite carries a `stale —` flag with QA hand-off cited in `## Next dispatch needed`.
5. **Hand-off.** Report per `§ Hand-off contract`. Phase 4 hand-off without a green / `n/a` / `stale` cite per available-matrix suite violates `core/process/phase-4-implementation.md § Acceptance`.

**Loop termination.** Loop terminates only when one holds — all change-scoped suites green; every remaining red suite is `stale —` with QA hand-off cited under `## Next dispatch needed`. Same-task fix; MUST NOT defer to follow-up ticket per `iteration-protocol.md`.

## Skip rules

Engineer MAY skip a suite only when one holds AND MUST cite the reason:

| Reason | Verification-log cite |
|---|---|
| Runner not configured in `local/bindings.md` / `local/index/commands.yaml` | `<suite> n/a — runner not configured (discovery gap surfaced)` |
| Suite not exercised by the change (no touched endpoint / state / mockup section) | `<suite> n/a — change does not touch <surface>` |
| Environment out of engineer reach (cloud-staging / production smoke) | `<suite> n/a — out of engineer reach; QA / release-pipeline owns` |

Silent skip violates this protocol. Every available-matrix suite MUST carry exactly one cite — green run · `n/a — <reason>` · `stale — <reason>`.

## Hand-off contract

Engineer's `## Verification log` (per `core/templates/phase-report.md`) MUST carry exactly one row per available-matrix suite:

| Row form | When |
|---|---|
| `<suite>: <command> — PASS (<N> tests)` | Suite ran green. |
| `<suite>: n/a — <skip reason>` | Suite skipped per `§ Skip rules`. |
| `<suite>: stale — <contract change>; QA oracle update needed` | Red suite triaged as stale oracle. Engineer MUST surface `qa-engineer · <suite>` under `## Next dispatch needed`. |

QA MUST NOT trust a green engineer log on its own — see `§ QA does NOT skip`.

## Change-scoped only

- This protocol MUST NOT mandate full regression.
- Engineer runs only — new + modified scenarios · touched-contract pre-existing scenarios · per-project unit specs in modified files (mirrors `core/process/phase-5-testing.md § Scope`).
- Full regression remains opt-in per `core/roles/team-lead.md § Testing scope`.

## QA does NOT skip

- QA's Phase 5 entry MUST independently re-execute every change-scoped suite the engineer reported green.
- QA MUST verify AC compliance against the issue / TODO / freeform task spec.
- Engineer's green log is paper trail, never a waiver.
- Stale-oracle flags MUST trigger oracle update before re-execution (Phase 5 scenario work, never Phase 6 bug). Spec: `core/roles/qa-engineer.md § Independent re-execution`.

## Phase 4 acceptance binding

- `core/process/phase-4-implementation.md § Acceptance` raises the bar to this protocol; the prior unit-only floor is replaced.
- Engineer self-verify completion is the gate for Phase 4 → Phase 5 transition.
- Non-compliance at hand-off blocks Phase 4 acceptance; team-lead MUST return the dispatch for self-verify completion.
