# Migration — schema enforcement + human-audience binding

**Target release:** next minor after 0.24.0.
**Affected adopters:** every adopter on every adapter — opt-in; no breaking change.

## What changed

Two sibling ginee-internal authoring rules ship in one PR — both close *documented-but-unenforced* gaps on framework communication surfaces:

- **Schema enforcement tightened** on the three structured-communication surfaces — dispatch prompts (orchestrator → cardinal) · phase-report returns (cardinal → orchestrator) · user-facing responses (orchestrator → user). Pre-change: schemas existed but enforcement was advisory · non-compliant dispatch payloads were sent · non-compliant returns consumed with a single one-line advisory · user-facing surface had no schema at all.
- **Human-audience binding** lands on ginee-authored GitHub artefacts — filed issues · sub-issue dispatches · framework-authored comments · PR descriptions. Pre-change: titles + summaries shipped as LLM-only voice (`[6:frontend-engineer] Stage 1 forensic — confirm Bug C/D root cause on demo-gha data (#92 iteration 1)`) — opaque to a cold human reader. Post-change: title + first paragraph in user-facing outcome language while the framework prefix LLMs route by stays.

## Closes

- [#170](https://github.com/kostiantyn-matsebora/ginee/issues/170) — *"[Bug] Schema-bound communication never enforced — dispatch prompts, agent returns, and user-facing responses default to freeform prose"*
- [#175](https://github.com/kostiantyn-matsebora/ginee/issues/175) — *"[Framework Bug] Framework-authored issues, sub-issues, and reports are unreadable to humans — written for LLM consumption only"*

## Surface-by-surface delta

### Dispatch-prompt schema — pre-send gate

| Pre | Post |
|---|---|
| Self-lint listed 5 checks + marker; no consequence on miss. Drafts sent as paragraph-shaped narrative. | Self-lint promoted to **pre-send gate** — any check fail or marker absent → restructure inline; never send a non-compliant payload. Tracking signal: pre-send-restructure count surfaces in the user-response `## Notes`. |

Different mechanism from phase-report return enforcement: dispatch prompts are the orchestrator's own draft, so the fix is the author's pre-send restructure — no carry-forward (no prior author to carry forward to).

### Phase-report return — non-compliance threshold + automatic carry-forward

| Pre | Post |
|---|---|
| One-line advisory per violation; carry-forward documented but advisory; format-only re-dispatch allowed only on missing `## Source reads`. | Threshold-driven — marker absent OR ≥ 2 missing required sections OR ≥ 1 forbidden-pattern hit auto-fires carry-forward to same cardinal next dispatch. Format-only re-dispatch gains a second carve-out (consecutive same-cardinal non-compliance, bounded one-retry per task). Violation count surfaces in the orchestrator's user-response. |

Carry-forward scope clarified: next dispatch to same cardinal within same task; cross-cardinal violations don't propagate; cross-task starts fresh.

### User-response schema — NEW

New file `core/templates/user-response.md` carries the schema for every orchestrator → user surface — Phase-8 interactive · automatic-mode delivery handoff · mid-task reports · forced-interactive escalations. Five mandatory sections + 2 auto-mode addenda + 8 mandatory checks + marker. Same machinery as phase-report.md and dispatch-prompt-schema.md.

| Section | Cardinality | Cap |
|---|---|---|
| `## Result` | required | 1 line |
| `## What changed` | required (else `(none)`) | 1 row per surface |
| `## Verification` | required (else `(none)`) | 1 row per check |
| `## Next` | required | 1 line |
| `## Notes` | optional | ≤ 150 words |
| `## Delivery state` (auto-mode) | required | 1 table |
| `## Accept / Feedback / Reject` (auto-mode) | required | 3 lines |

Synthesis from cardinal phase-reports is part of the schema — team-lead never forwards cardinal returns verbatim.

### Skill-runner mechanical-message shape — 3-line kernel

| Pre | Post |
|---|---|
| Skill-runner mechanical messages drifted to prose status updates carrying default-selection language. | Fixed 3-line shape — `Did: <op>` · `Result: <outcome>` · `Next: <hand-back \| nil>` + marker. Prose status before / after forbidden. Orchestration messages keep the richer user-response schema. |

### Audience check — humans + LLMs

New section `core/protocols/doc-authoring-protocol.md § Audience check` carries the binding for issue bodies · sub-issue dispatches · framework-authored comments · PR `## What` lines:

1. **Title — user-facing language.** Outcome-shaped one-liner; framework prefix `[<phase>:<cardinal>]` preserved on sub-issues.
2. **First paragraph — 2-4 sentence human summary.** Restates the title for a cold reader; no jargon; no assumed context.
3. **Bug reports — numbered repro steps.** Mandatory; reader must repro without loading the framework.
4. **Framework-internal sections come AFTER the human summary.**
5. **Forbidden in title.** Internal bug IDs · forensic stage tags · iteration markers · file paths · module names · code-level technical terms · fix mechanics.

Title-shape examples ship inline. Five `ginee-file-*` skills + sub-issue-dispatch template bind the check into step-4 self-lint.

## Files changed (framework upstream)

| Path | Change |
|---|---|
| `core/templates/user-response.md` | **NEW** — schema for orchestrator → user surface |
| `core/protocols/dispatch-prompt-schema.md` | Pre-send gate section replaces advisory self-lint |
| `core/templates/phase-report.md` | Non-compliance threshold table + carry-forward auto-fire + second format-only re-dispatch carve-out + user-response binding |
| `core/process/dispatch.md` | New `### Skill-runner mechanical-message shape` 3-line kernel |
| `core/process/phase-8-user-approval.md` | `Action` line binds to user-response schema |
| `core/protocols/automatic-mode.md` | Delivery report shape binds to user-response schema (with auto-mode addenda) |
| `core/roles/team-lead.md` | `## Reporting` adds user-response binding for user-facing surfaces |
| `core/protocols/doc-authoring-protocol.md` | New `### Audience check — humans + LLMs` section + 5 binding checks + title-shape examples + scope-of-binding table |
| `core/templates/issues/bug-report.md` · `feature-request.md` · `framework-bug-report.md` · `framework-feature-request.md` | Audience binding in header + title placeholder · Summary placeholder asks for 2-4 sentence human restatement |
| `core/templates/sub-issue-dispatch.md` | Title audience binding + ❌/✅ example table · new `## Summary` in body template · audience check added to 7-item self-lint |
| `core/templates/pr-description.md` | `## What` lead-with-adopter-visible-change binding |
| `core/templates/hand-off-note.md` | One-line note — when surfaced to user, wrap per user-response template |
| `core/protocols/github-integration.md` | One-line cross-ref to audience check under `§ Sub-issue dispatch` |
| `core/skills/ginee-file-bug/SKILL.md` · `ginee-file-feature/SKILL.md` · `ginee-file-framework-bug/SKILL.md` · `ginee-file-framework-feature/SKILL.md` · `ginee-promote-discussion/SKILL.md` | Step-4 self-lint extended with audience check reference |
| `docs/CONCEPTS.md` | New `## Artefacts are written for humans + LLMs` section (adopter-facing principle) |
| `migrations/schema-enforcement-and-human-audience.md` | This file (NEW) |

## Action required — none (adopter-side)

**Purely additive.** No `local/` schema change. No new commands. No adapter re-install. Existing dispatches on closed tasks unaffected — forward-only. The next ginee-authored issue / sub-issue / dispatch / user-facing response runs the tightened gate automatically.

Adopters writing custom issue templates under `local/` SHOULD adopt the same audience binding — not required, but produces sub-issues humans can pick up cold.

## Backward compatibility

- **Adopter `local/*` files** — no schema change.
- **`framework.config.yaml`** — no new keys.
- **Existing open issues / sub-issues** — NOT retroactively rewritten (D14 reporter-content forbidden + forward-only convention).
- **Adapter renderings** — none required; the bindings live in `core/`.
- **CLAUDE adapter** — no hook changes; the audience check is LLM self-review against the schema, identical machinery to D22 / D26 / D29 / D40 / D49.

## Rollback

Not recommended. Both changes close documented-but-unenforced gaps that were the largest current source of (a) sent-as-prose dispatches + (b) human-unreadable GitHub artefacts.

To revert:

1. Restore `core/protocols/dispatch-prompt-schema.md § Self-lint — before sending` to advisory shape; drop pre-send gate.
2. Revert `core/templates/phase-report.md § Orchestrator behaviour on non-compliant returns` to advisory + single-carve-out form.
3. Delete `core/templates/user-response.md` + remove the bindings from `core/process/phase-8-user-approval.md` · `core/protocols/automatic-mode.md` · `core/roles/team-lead.md`.
4. Remove `### Skill-runner mechanical-message shape` from `core/process/dispatch.md`.
5. Remove `### Audience check` from `core/protocols/doc-authoring-protocol.md`.
6. Revert issue templates + sub-issue-dispatch + pr-description + the five `ginee-file-*` skills + the github-integration cross-ref.
7. Drop the `## Artefacts are written for humans + LLMs` section from `docs/CONCEPTS.md`.

The framework still functions; orchestration messages return to free-form prose; GitHub artefacts return to LLM-only voice.

## Issue references

- Closes [#170](https://github.com/kostiantyn-matsebora/ginee/issues/170)
- Closes [#175](https://github.com/kostiantyn-matsebora/ginee/issues/175)
- Sibling to [#168](https://github.com/kostiantyn-matsebora/ginee/issues/168) (estimation-gate rule documented but never fires)
- Extends [#69](https://github.com/kostiantyn-matsebora/ginee/issues/69) (schema-bound subagent return surface) to enforcement
