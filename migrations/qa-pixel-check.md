# Migration — QA pixel-check (optional Phase 5 visual oracle)

**Target release:** next minor after 2026-05-26.
**Affected adopters:** every adopter on every adapter — opt-in; defaults to `enabled: false`. No breaking change to adopters who don't enable it.

## What changed

Extends `qa-engineer` Phase 5 with an **optional pixel-check stage** that diffs the **rendered app** against the **mockup** at a **shared seed-state**. Mockup graduates from design reference to runtime oracle — closes the loop that behaviour tests + manual smoke leave open (CSS regressions · layout shifts · missing icons · wrong copy · broken responsive breakpoints).

Pairs with `core/protocols/blueprint-diff-protocol.md`:

| Protocol | Diffs | Catches |
|---|---|---|
| `blueprint-diff-protocol.md` | mockup ↔ mockup `blueprint-ref` | mockup self-drift |
| `pixel-check-protocol.md` (new) | app ↔ mockup at shared seed-state | app-vs-mockup drift |

## State-alignment direction (adopter choice)

Both renders MUST show the same application state. State origin is the seed script. Two configurations — adopter picks once per project:

| Direction | What changes | Pick when |
|---|---|---|
| `mockup-follows-seed` | Mockup is authored / re-snapshotted to match seed-script output | Seed is the stable artefact; mockup churn is cheaper |
| `seed-follows-mockup` | Seed script is authored to produce the state the mockup depicts | Mockup is the stable artefact (design-led); seed churn is cheaper |

Framework MUST NOT prescribe — adopter declares via `qa.pixel-check.alignment`.

## Gate — pixel-check fires when ALL hold

| Condition | Source |
|---|---|
| `qa.pixel-check.enabled: true` | `local/framework.config.yaml` |
| Change diff touches visual surface | `visual-source-of-truth.path` OR any `local/bindings.md § front-end-owned` path |
| `seed-script.path` + `mockup-snapshot.path` + `app-render.command` configured | `local/bindings.md` |

Any condition unmet → pixel-check skipped silently; QA falls through to manual smoke.

## Run — 4 steps

1. Execute `seed-script.path` → app at canonical state.
2. Execute `app-render.command` per viewport → `actual/<viewport>.png`.
3. Read `mockup-snapshot.path/<viewport>.png` → `expected/<viewport>.png`.
4. Adopter pixel-diff tool → `diff/<viewport>.png` + delta count.

## Drift routing

QA classifies the diff source BEFORE routing. Misrouted failures waste a full cardinal dispatch.

| Diff source | Route to | Phase |
|---|---|---|
| App rendered wrong (mockup correct) | Owning front-end engineer | Phase 6 |
| Mockup outdated (app correct) | Mockup-owning role | Phase 2 (mockup update) |
| Seed produces wrong state | Seed-script owner | Phase 6 / new Phase 2 work item |
| Tolerance too tight (false positive) | `team-lead` | Out-of-phase config call |

Cross-domain bug (e.g. frontend blames backend seed) → `team-lead` re-enters per `core/protocols/cross-domain-bugs.md`.

## Oracle discipline

Tolerance + masks ARE part of the oracle and audited like any test code:

- **Mask justification.** Every entry carries selector + `# why: <reason>` comment.
- **Tolerance bumps.** MUST cite the specific diff that would have been caught at the prior threshold — prevents creep masking real regressions.
- **Pixel-check is NOT a gate.** Failures route to Phase 6 / Phase 2, never BLOCK.

## Tolerance-bootstrap recipe

First-run on a new project / viewport:

1. Configure `max-diff-pixels: 0` + empty masks.
2. Inspect each region with `> 0` pixel delta.
3. Classify each: real diff (route) · stable noise (mask) · animated (mask with justification).
4. Land the mask set + agreed `max-diff-pixels` / `max-diff-ratio` in config.

## Action required — none (adopter-side, default)

**Purely additive, default off.** No `local/` schema change required for adopters who don't opt in.

**To opt in:**

1. Set `qa.pixel-check.enabled: true` in `local/framework.config.yaml`.
2. Pick alignment direction (`alignment: mockup-follows-seed` or `seed-follows-mockup`).
3. Configure tolerance + viewports under `qa.pixel-check.tolerance` / `.viewports`.
4. Populate the Visual oracle fields table in `local/bindings.md` — `seed-script.path` · `mockup-snapshot.path` · `app-render.command`.
5. Run tolerance-bootstrap recipe above to establish baseline masks.
6. Next `qa-engineer` dispatch on a Phase 5 task touching the visual surface runs pixel-check automatically.

## Files changed (framework upstream)

| Path | Change |
|---|---|
| `core/protocols/pixel-check-protocol.md` | **NEW** — load-on-demand spec (principle · gate · alignment · run · tolerance · drift routing · oracle discipline · tolerance-bootstrap · forbidden patterns) |
| `core/process/phase-5-testing.md` | New `qa-engineer` pixel-check bullet — optional step between change-scoped e2e and manual smoke |
| `core/roles/qa-engineer.md` | New `Pixel-check (optional)` row in the Required test layers table |
| `core/templates/framework.config.yaml` | New `# --- QA pixel-check (optional Phase 5 visual oracle) ---` block with `qa.pixel-check.*` config schema |
| `core/templates/bindings.md` | New `## Visual oracle fields (optional — pixel-check)` table with `seed-script.path` · `mockup-snapshot.path` · `app-render.command` |
| `docs/CONCEPTS.md` | One-line user-docs co-update — pixel-check as Phase 5 visual oracle |
| `migrations/qa-pixel-check.md` | This file (**NEW**) |
| `core/protocols/doc-authoring-examples.md` | New worked example — true-positive (app regression caught) + false-positive (mask added) |

## Backward compatibility

- **Adopter `local/*`** — no schema change required for default-off adopters.
- **In-flight Phase 5 runs** — pixel-check fires only on next dispatch with `enabled: true`; no retroactive effect.
- **`framework.config.yaml`** — new keys all optional + commented out by default.
- **Adapter renderings** — none required; spec lives in `core/`.

## Rollback

To revert framework upstream:

1. Delete `core/protocols/pixel-check-protocol.md`.
2. Remove the pixel-check bullet from `core/process/phase-5-testing.md`.
3. Remove the `Pixel-check (optional)` row from `core/roles/qa-engineer.md`'s Required test layers table.
4. Remove the `# --- QA pixel-check ---` block from `core/templates/framework.config.yaml`.
5. Remove the `## Visual oracle fields` block from `core/templates/bindings.md`.
6. Remove the user-docs line from `docs/CONCEPTS.md`.
7. Remove the worked example from `core/protocols/doc-authoring-examples.md`.
8. Delete this migration file.

Adopters who opted in must remove their `qa.pixel-check.*` config + Visual oracle fields entries from `local/`. Framework still functions; visual regressions return to being caught (or missed) only by manual smoke.

## Out of scope

- **Pixel-diff tool selection.** Adopter brings their own (`pixelmatch` · `playwright --update-snapshots` · `reg-cli` · `Percy` · `Chromatic`). Framework specifies the contract, not the tool.
- **Mockup authoring tool.** Figma / Sketch / Penpot / hand-rolled HTML — adopter's call.
- **Multi-state pixel-check in one pass.** Each pass = one seed-state. Multi-state runs are iterative.
- **Cross-browser visual diffing.** Single canonical browser per viewport; multi-browser is opt-in adopter extension.
- **Animation-frame diffing.** Pixel-check is static-state only. Motion correctness stays in behaviour tests.
- **Automatic mockup re-snapshotting.** Mockup updates remain a Phase 2 artefact change with human review.

## Issue reference

Closes [#163](https://github.com/kostiantyn-matsebora/ginee/issues/163) — *"[Framework Feature] QA pixel-check — visual diff between mockup and running app at a shared seed-state."*
