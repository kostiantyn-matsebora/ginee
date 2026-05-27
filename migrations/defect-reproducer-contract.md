# Migration — QA defect-reproducer test: Phase 5 → Phase 6 contract

**Target release:** next minor.
**Affected adopters:** every adopter project. Soft cutover — legacy Phase 6 dispatches without reproducer tests are tolerated until adopters re-fetch the updated `core/`; new dispatches follow the new shape.
**Issue:** [#184](https://github.com/kostiantyn-matsebora/ginee/issues/184).

## Why

Phase 6 today carries no contractual reproducer artefact across the QA → engineer boundary. The engineer reads the defect description, re-derives the failure locally (often without the exact fixture / data / sequence QA observed), proposes a fix, and signals back. QA re-runs the suite in the next cycle and may or may not see it green; mismatches start another iteration. Four costs accrue:

1. **Round-trip waste** — typical Phase 6 takes 1–3 iterations before a defect closes; first iteration is often consumed by reproducer drift, not by the fix itself.
2. **"Works on my machine" stalls** — engineer cannot reproduce the failure QA reported because the trigger conditions (seed state · fixture variant · timing · environment) are described informally in prose.
3. **Fix-verification is informal** — engineer reasons that the fix should work; QA confirms in the next cycle. No deterministic local gate the engineer can run before signalling back.
4. **Defect-class regression risk** — a defect fixed in Phase 6 may reappear later because no committed test gates against re-introduction.

Handing the engineer a failing test that reproduces the defect collapses all four costs at once: engineer runs the test locally, observes the failure, fixes, observes green, signals back with a self-verified artefact. The test also doubles as a permanent regression gate.

## What changed — five surfaces

### 1. Phase 5 acceptance

`core/process/phase-5-testing.md` adds a new `Defect-reproducer` bullet and extends `Acceptance`:

| Surface | Before | After |
|---|---|---|
| Bullet list | (no defect-reproducer rule) | New bullet — every defect routed to Phase 6 MUST carry a committed failing test in the appropriate suite OR `testable: false` + rationale. |
| Acceptance — Failures line | `Failures → Phase 6.` | `Failures → Phase 6 with reproducer-test cite per § Defect-reproducer.` |
| Testable-false threshold | (no rule) | Team-lead advisory when `testable: false` ratio > `qa.defect-reproducer.testable-false-threshold` (default 20%); informational only. |

### 2. Phase 6 dispatch contract + acceptance

`core/process/phase-6-bug-fixing.md` adds `Reproducer-test dispatch contract` rule and extends `Acceptance`:

| Element | Content |
|---|---|
| Dispatch carries | defect description · test file path · runner command (sourced from `local/framework.config.yaml § test-runners`) · expected end-state (test passes) |
| Engineer-fix loop | run test → confirm fails → fix → re-run → confirm passes → signal back |
| Untestable defects | Skip the contract; description-only dispatch falls through |
| Acceptance row | New — `Reproducer test passes locally (when carried per § Reproducer-test dispatch contract); QA's Phase 6 re-verification sweep still runs.` |

### 3. QA role kernel

New `§ Defect-reproducer authoring discipline` — see `core/roles/qa-engineer.md`.

### 4. QA role companion + phase-report template

| File | Addition |
|---|---|
| `core/roles/qa-engineer.details.md` | New `§ Test-layer selection per defect class` table — API → functional · UI → e2e · visual → pixel-check · component-internal → unit · script behaviour → script-suite · post-deploy → smoke. Reproducer-fail-first discipline + fixture-sourcing rule. |
| `core/templates/phase-report.md` | New `## Defects` section required on Phase 5 / Phase 6 QA returns when failures surface; columns: defect · suite · test file · test name · observed vs expected · `testable` · rationale. Rules: `testable: true` → file+name MUST point to a committed failing test; `testable: false` → rationale MUST be set; one row per defect. |

### 5. Sub-issue dispatch template

`core/templates/sub-issue-dispatch.md` gains:

- New `## Reproducer test` section (Phase 6 dispatch body) — Defect · Test file · Test name · Runner command · Expected end-state.
- `§ Required elements per surface` row extended — `## Reproducer test` added on Phase 6 dispatches unless defect is `testable: false`.
- `§ Self-lint` check 8 — when `Phase: 6`, body carries `## Reproducer test` with all five fields populated OR the defect carries `testable: false` cite.

## Test-layer selection per defect class

Layer table lives in `core/roles/qa-engineer.details.md § Test-layer selection per defect class` — see there.

## Untestable-defect escape hatch

Same shape as `core/roles/qa-engineer.md § Defect-reproducer authoring discipline` final bullet — defect types (pure visual judgement · human-in-the-loop · timing-sensitive) · `testable: false` + rationale · description-only Phase 6 fallback · 20% threshold advisory.

## Config — `local/framework.config.yaml`

Optional. Default applies when omitted.

```yaml
qa:
  defect-reproducer:
    testable-false-threshold: 0.20      # ratio of testable:false defects per Phase 5 return
```

Override to `0.0` to surface advisory on any untestable defect, or higher to relax the signal. Threshold is informational; team-lead does not block Phase 6 on it.

## Adapter force-class wiring

Mostly soft-force; verifiable signals (Phase-6 dispatch body shape · QA report `## Defects` table) backstopped by Class H text + slash-command templates. Per playbook [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135):

| Axis | Class | Surface |
|---|---|---|
| Class H text on role kernels + process specs | H | `core/process/phase-5-testing.md § Defect-reproducer` · `core/process/phase-6-bug-fixing.md § Reproducer-test dispatch contract` · `core/roles/qa-engineer.md § Defect-reproducer authoring discipline` |
| Phase-report `## Defects` schema | H + A-indirect | `core/templates/phase-report.md § Defects` enforced by `/ginee-phase-report` slash command's deterministic template |
| Phase 6 dispatch body `## Reproducer test` | H + A-indirect | `core/templates/sub-issue-dispatch.md § Reproducer test` enforced by sub-issue self-lint check 8 |
| `testable: false` threshold advisory | H (team-lead consumption rule) | Surfaces in user-response `## Notes` — soft signal, does not block Phase 6 |

Hard-force regex hook deferred — pattern-matching test file paths + defect prose is brittle outside controlled vocabularies. Sibling adapters (Cursor · Copilot · Codex · generic) inherit the soft-force surface; per-adapter playbooks TBD when the tooling matures.

## Action required

| Step | Action |
|---|---|
| Re-fetch | Pull latest `core/` via `/ginee-update` (or `ginee-update` workflow on non-AgentSkills adapters). |
| Config (optional) | Set `qa.defect-reproducer.testable-false-threshold` in `local/framework.config.yaml` to override default 20%. |
| QA team brief | QA cardinals pick up `§ Defect-reproducer authoring discipline` on next dispatch via the role kernel. |
| Existing Phase 6 dispatches | Tolerated as legacy; no rewrite needed. New dispatches authored post-update follow the new shape. |

## Out of scope

- Required unit-test minimum from QA — test layer is selected per defect class.
- Replacement of QA's broader Phase 6 re-verification sweep — reproducer tightens the engineer-fix loop only.
- New test-runner mechanism — engineers use existing project runners per `local/framework.config.yaml § test-runners`.
- Cross-suite test discovery — reproducer tests live in whichever suite is appropriate; no new index or registry.

<!-- self-lint: pass -->
