# Migration — Estimation gate fires on every dispatch

**Target release:** next minor.
**Affected adopters:** every adopter project. Soft cutover — legacy dispatches authored before adopter re-fetches `core/` are tolerated; new dispatches follow the new shape.
**Issue:** [#168](https://github.com/kostiantyn-matsebora/ginee/issues/168).

## Why

The estimation-first dispatch rule was documented across team-lead + every cardinal kernel + 5 extras roles, but did not fire in practice. Root cause: the rule was **trigger-circular** (loaded only when scope > 15 min, but no step ever decided that) AND had **no schema home** in dispatch-prompt or phase-report. Concretely:

1. Team-lead skipped the classifier; iteration-protocol failed to load.
2. Cardinals jumped to implementation; no `## Estimate` block in the return — no such schema slot existed.
3. Sub-issue body's `**Estimate:**` field stayed at template default or was omitted.
4. Heavy-role-bypass paths (TL1–TL4) and `lite:` prefix elided the surface entirely with no estimation handover.

Result: scope ballooned silently; stop-and-report boundaries collapsed; the iteration-protocol's stoppable-intermediate-states invariant did not engage because the protocol itself failed to load.

## What changed — six surfaces

### 1. Team-lead pre-dispatch scope-size classifier

`core/roles/team-lead.md` adds a pre-dispatch step. Before every cardinal dispatch, team-lead MUST emit one of `≤15m` · `15-60m` · `>60m` + one-line signal. The class drives three downstream surfaces:

| Surface | Effect |
|---|---|
| `## Scope size` on dispatch-prompt | Required section per `core/protocols/dispatch-prompt-schema.md`. |
| `**Estimate:**` field on sub-issue body | Filled at create per `core/templates/sub-issue-dispatch.md`. |
| Iteration-protocol load + cardinal `## Estimate` return | Required iff class ∈ `{15-60m, >60m}` per `core/protocols/iteration-protocol.md` + `core/templates/phase-report.md`. |

`≤15m` MUST be recorded explicitly; silent elision is not permitted.

### 2. Dispatch-prompt schema — `## Scope size`

`core/protocols/dispatch-prompt-schema.md` adds `## Scope size` as a required section. For `15-60m` / `>60m` dispatches, `## Required output` gains a one-line addendum: `iteration-protocol loaded; ## Estimate required.` Self-lint pre-send gate grows from 5 → 6 checks; check 6 enforces class membership + addendum presence.

### 3. Phase-report schema — `## Estimate`

`core/templates/phase-report.md` adds `## Estimate` as a required section iff dispatch carried `## Scope size` ∈ `{15-60m, >60m}`. Placement: before `## Files touched`. Shape: table — sub-task · estimate (min). Self-lint checks grow from 7 → 8; check 8 enforces presence-when-required + sum vs class upper bound.

### 4. Sub-issue dispatch — Scope size + Estimate at create

`core/templates/sub-issue-dispatch.md` body's dispatch contract gains a `**Scope size:**` line (`<class> — <signal>`) and the existing `**Estimate:**` line is rebound: class `≤15m` records `≤15m` verbatim, classes `15-60m` / `>60m` carry the cardinal-decomposed `<H>h <M>m`. Self-lint adds check 9 — fails on template-literal-left-in-place (angle-bracket placeholders surviving create).

### 5. Heavy-role-bypass + `lite:` prefix

`core/protocols/heavy-role-bypass.md` adds a new `§ Scope-size classification — required even on bypass` section. TL1 / TL2 / TL3 / TL4 each emit the one-line classification before bypass approval (TL1 — skill-runner mechanical write at sub-issue create; TL2 — cardinal at verification entry; TL3 — engineer at fix entry; TL4 — SA at review entry). `core/process/dispatch.md`'s `lite:` / `direct:` prefix row gains: auto-classifies as `≤15m`; iteration-protocol skipped + cardinal `## Estimate` not required; class still written to dispatch payload + sub-issue.

### 6. Iteration-protocol — explicit load trigger

`core/protocols/iteration-protocol.md` replaces the circular "estimated total scope > 15 min" trigger with explicit "team-lead's classifier returned `15-60m` or `>60m`". Sizing table expanded from binary (≤15 / >15) to three-tier mirroring the classifier classes. `core/protocols/role-kernel-shared.md § B` rephrased to depend on dispatch payload's `## Scope size`.

## Adopter action

No runtime change required — purely additive on the dispatch surface. Adopters re-fetch `core/` per the standard update flow; the next team-lead dispatch runs the classifier automatically.

If you maintain custom roles under `local/roles/` that override the `## Estimation-first dispatch` section: drop the override (the new wording in `role-kernel-shared.md § B` already cites the classifier). Custom-role kernels carrying a verbatim copy of the old `Phase 4/5/6/7 work above the 15-min threshold` phrasing SHOULD be updated to cite the classifier.

If you have an in-house `/ginee-dispatch`-equivalent slash command that builds dispatch payloads, regenerate from `core/protocols/dispatch-prompt-schema.md § Templates` to pick up the new `## Scope size` section.

### Notes

- **No `local/framework.config.yaml` changes.** No new opt-out keys — the classifier is unconditional on team-lead, matching the existing pattern for source-of-truth resolution.
- **Existing open sub-issues are not retroactively rewritten** (forward-only convention upheld). The new lint fires on next-create only.
- **Hard-force deferred.** No hook lands in this release — the classifier is soft-force (in-kernel text + schema additions + carry-forward via existing T5 / T8 vectors). A PreToolUse hook scanning dispatch payloads for missing `## Scope size` MAY follow if drift surfaces in practice.

## Related

- Closes [#168](https://github.com/kostiantyn-matsebora/ginee/issues/168).
- Sibling pattern: [#50](https://github.com/kostiantyn-matsebora/ginee/issues/50) (orchestrator silent-elision when work feels "fast").
- Builds on [#177](https://github.com/kostiantyn-matsebora/ginee/issues/177) (engineer self-verify before QA hand-off) — both close gaps where a documented rule did not fire in practice.
