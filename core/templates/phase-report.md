# Phase Report — Schema

Binding schema for every cardinal-dispatch return. Same machinery as `core/protocols/doc-authoring-protocol.md`, scoped to subagent-return surface. Self-lint at report-as-done; orchestrator surfaces violations as one-line advisory + consumes anyway.

## Section cardinality

| Section | Cardinality | Default shape | Cap |
|---|---|---|---|
| `## Estimate` | required **when dispatch carried `## Scope size` ∈ `{15-60m, >60m}`** (else omit) | Table — sub-task · estimate (min); placed **before** `## Files touched` | 1 row per sub-task |
| `## Files touched` | required (else `(none)`) | Table — path · Δ lines · purpose | 1 row per file |
| `## Decisions made` | required (else `(none)`) | Bullets — `<short imperative> — cite` | ≤ 80 chars / bullet |
| `## Verification log` | required | Table — command / check · outcome | 1 row per check |
| `## Defects` | required **on Phase 5 / Phase 6 QA returns when failures surface** (else omit) | Table — desc · suite · test file · test name · observed vs expected · `testable` · rationale | 1 row per defect |
| `## Open issues` | required (else `(none)`) | Bullets — `<issue> — <owner / blocker>` | ≤ 80 chars / bullet |
| `## Next dispatch needed` | required (else `(none)`) | One-liner — `<role> · <surface> · <reason>` | 1 line |
| `## Source reads (this dispatch)` | required (else `(none)`) | Table — Path · Justification · Index entry consulted | 1 row per source read |
| `## Hand-off` | required **on failed dispatch / cross-domain root cause outside domain** per `core/protocols/cross-agent-handoff.md` | Embed `core/templates/hand-off-note.md` shape | per template |
| `## Stop-state` | required **when `Status: In-progress`** | Three-bucket bullets — Done / In-progress / Not-started | per `core/protocols/iteration-protocol.md § Stoppable intermediate states` |
| `## Time spent` | required **when sub-issue mode active** | One-liner — `<H>h <M>m perceived effort; <N> progress comments on sub-issue #<M>.` | 1 line |
| `## Notes` | optional — narrative escape hatch | Free-form prose | ≤ 200 words |

**Status header** (single line at top): `Status: Done | In-progress | Blocked | Hand-off`. Iteration-protocol intermediate: same schema · sections marked `(in-progress)` where partial · `## Stop-state` required.

## Forbidden patterns (self-lint catches)

1. **Narrative preamble** ("I started by reading…") → `## Files touched` table directly.
2. **Restated dispatch context** → cite the dispatch prompt; don't restate.
3. **Code snippets in schema body** → diff stats + path cite. Carve-out: ≤ 5-line literal in `## Notes` when orchestrator needs verbatim.
4. **Verbose rationale outside `## Notes`** → one-line decision + cite in `## Decisions made`; deeper in capped `## Notes`.
5. **Parenthetical comma-soup** → inventories in tables, not parentheses.

## Mandatory checks before report-as-done

Same 6 as `core/process.md § Documentation style § Mandatory checks` PLUS:

7. **No narrative preamble** — first non-Status line is a `##` section header.
8. **`## Estimate` present iff dispatch carried `## Scope size` ∈ `{15-60m, >60m}`** — placed before `## Files touched`; one row per sub-task with per-task minutes; sum ≤ class upper bound (`60m` for `15-60m` class is a soft cap — overrun → scope-overrun trigger per `core/protocols/iteration-protocol.md § Scope-overrun trigger`).

Run all 8 against draft before returning. Violations → restructure; un-restructurable content lifted to `## Notes` (still ≤ 200 words).

## SA-artefact content self-lint

**Binding for `solution-architect` returns when `## Files touched` includes any architecture-family artefact** — architecture doc · ADR · requirements register · ASR utility tree · diagrams (per `core/roles/solution-architect.md § What you own`). Adds one row per touched artefact to `## Verification log` — `SA-artefact content self-lint: PASS / <N findings>`.

Per `core/roles/solution-architect.md § Forbidden actions § Content depth-bound rules`. Authored content MUST NOT contain:

| Forbidden category | Pattern signal |
|---|---|
| Adopter function / method / member identifier | `<Name>()` · `_<name>` · `.<name>(` patterns that resolve to a working-tree symbol (not a contract surface). |
| Line-numbered citation into the working tree | `<file>:<line>` · `at line <N>` · `lines <N>–<M>`. |
| Commit SHA as evidence | 7+ hex chars in evidence context — `as of <sha>` · `prior to <sha>`. |
| Handler-body / wiring code snippet | Multi-line fenced code exhibiting function body, event handler, template binding, or call sequence (vs interface declaration / wire-shape type / event-payload type — those are allowed). |
| "How to implement" / "how to wire it" prescription | Imperative second-person steps prescribing implementation order ("declare a `<x>` signal, then call `<y>()`…"). |
| Repeated adopter file path as architectural basis | Same working-tree path cited > 2× as the basis for an architectural claim (vs single mention for context). |

**Self-lint procedure.**

1. Grep the authored content for each pattern.
2. Hit → restructure: replace with architectural-mechanism phrasing (cite the mechanism + rationale rooted in NFR / constraint, not the code site) OR move the content to an engineer-owned per-tier doc via `## Next dispatch needed`.
3. After restructure, re-run; record `PASS` in `## Verification log`.
4. If a finding genuinely cannot be lifted (rare), record `<N> findings — <reason>` and surface in `## Notes` (≤ 200 words). Team-lead consumes + surfaces to user at gate.

**Worked architectural-mechanism vs implementation-rendering examples:** `core/roles/solution-architect.details.md § Architectural mechanism vs implementation rendering — worked pair`.

**Adapter binding.** Class H (always-loaded text in `core/roles/solution-architect.md`) + Class A-indirect via `/ginee-self-lint` slash command extension (Claude adapter). Hard-force regex lint deferred — pattern-matching adopter identifiers is brittle outside controlled vocabularies. Per playbook [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135).

## Marker

Append literal `<!-- self-lint: pass -->` as the LAST line (fixed form · case-sensitive · after every section + `(none)` + `## Notes`). Write after running checks, never blindly. Honest-fail: un-restructurable content in `## Notes` still writes marker (cap is the legal escape hatch). Not a pass/fail gate; not a re-dispatch trigger.

Without marker the 8 checks are aspirational + the orchestrator has no structural signal. Same attestation mechanism as doc-authoring `## Verification log` lines, scoped to the return envelope.

## Orchestrator behaviour on non-compliant returns

- Surface one-line advisory before consuming (`"Return missed self-lint: <violation>; consuming anyway."`).
- **Never re-dispatch purely for format** (two narrow carve-outs below).
- Never auto-rewrite content (same forbidden as reporter-content rule in `github-integration.md § Forbidden actions`).
- **Skill-runner forbidden** from cleanup before passing to team-lead.
- **Violation count surfaces in the user-response.** Per turn, team-lead's `## Notes` to user includes one line: `Schema-bound returns: <N>/<M> compliant.` Source: `core/templates/user-response.md § Synthesis from phase-report returns`. No prose; no per-cardinal breakdown.

### Non-compliance threshold — auto-fires carry-forward

| Threshold | Action |
|---|---|
| Marker present, ≤ 1 missing required section, no forbidden-pattern hit | Advisory; consume. No carry-forward. |
| Marker absent OR ≥ 2 missing required sections OR ≥ 1 forbidden-pattern hit | Advisory; consume; **carry-forward rephrasing fires automatically** on next dispatch to same cardinal (see § Carry-forward rephrasing). |
| Same cardinal returns non-compliant 2 turns in a row in the same task | Format-only re-dispatch ONCE per task per cardinal (second carve-out below). |

Threshold is mechanical, not judgmental — count missing sections; check forbidden-pattern hits; decide.

### Format-only re-dispatch — two carve-outs

**Carve-out 1 — missing audit trail.** Re-dispatch fires when raw source paths appear in `## Files touched` (paths outside `local/index/`) AND `## Source reads (this dispatch)` is missing or `(none)`. Rationale: missing audit trail is substantive omission (missing decision data), not format.

**Carve-out 2 — consecutive non-compliance, same cardinal, same task.** When a cardinal returns non-compliant 2 consecutive turns within the same task (per the threshold table above), team-lead MAY format-only re-dispatch ONCE. Bounded: one retry per task per cardinal; further non-compliance after the retry → carry-forward only · surface in `## Notes` for user awareness. Prevents indefinite consume-anyway loops on a drifting cardinal without re-instating habitual format-only re-dispatch.

Never re-dispatch for pure format issues outside these two carve-outs (preamble · marker absence · table shape on first occurrence).

### Worked advisories

| Violation | Advisory text |
|---|---|
| Missing marker | `"Return missed self-lint: marker absent; consuming anyway."` |
| Narrative preamble | `"Return missed self-lint: narrative preamble; consuming anyway."` |
| Inventory as prose / comma-soup | `"Return missed self-lint: inventory not in table form; consuming anyway."` |
| Code snippet outside `## Notes` | `"Return missed self-lint: code outside Notes carve-out; consuming anyway."` |
| Bullet > 25 words without sub-bullets | `"Return missed self-lint: bullet over-length; consuming anyway."` |
| Source touched without `## Source reads` | `"Re-dispatching: source files touched without justification; cite consulted index entries."` |
| Multiple violations | Cite the first; one line; never enumerate. |

### Carry-forward rephrasing for next dispatch

**Auto-fires** on threshold hit (per § Non-compliance threshold). Team-lead appends a single-line reminder at end of next dispatch prompt to the same cardinal — cite specific violation; never reopen prior return; never re-dispatch for format (subject to the two carve-outs above):

```
<original dispatch text>

Return format: schema-bound per core/templates/phase-report.md;
last cycle's return missed self-lint (<violation>) — apply the 8 checks + marker this cycle.
```

**Scope.** Carry-forward applies to the *next dispatch to the same cardinal within the same task*. Cross-cardinal violations don't propagate; cross-task carry-forward is out of scope (treat each task fresh). Tracking: orchestrator counts forward-applied violations per turn; surface in `## Notes` of the user-response per `core/templates/user-response.md § Synthesis`.

## Section templates

### Status

```
Status: Done
```

### `## Estimate` *(when dispatch carried `## Scope size` ∈ `{15-60m, >60m}`)*

Returned **before any edit** + before `## Files touched`. Specialist's pre-implementation decomposition; orchestrator synthesizes to user when scope warrants per `core/protocols/iteration-protocol.md § Estimation-first dispatch`.

| Sub-task | Estimate |
|---|---|
| `<one-line — change / where / why>` | `<N>m` |

**Rules:**

1. Sum of per-task minutes is the proposed total; budget against the dispatch's class upper bound (`60m` soft cap for `15-60m`; no hard cap for `>60m` — overrun → scope-overrun trigger).
2. `15-60m` typical: 3–7 sub-tasks. `>60m` typical: 5–12 sub-tasks scoping the first iteration batch (per iteration-protocol; further batches re-propose).
3. Omit the section entirely when dispatch was `≤15m` — class is recorded on the dispatch payload, not the return.

### `## Files touched`

| Path (absolute or repo-relative) | Δ lines (`+N / -M`) | Purpose |
|---|---|---|
| `<path>` | `+12 / -3` | `<one-line why>` |

Empty case: `(none)`.

### `## Decisions made`

- `<short imperative>` — `<cite: FR-NN-slug / NFR-NN-slug / ADR-NNNN-slug / mockup §X>`

Taxonomy IDs slug-glued — `ADR-0001-topology-derivation-five-pass`, not bare `ADR-0001`. Resolution lookup + lint rule: `core/protocols/doc-authoring-protocol.md § Taxonomy identifier pairing`.

Empty case: `(none)`.

### `## Verification log`

| Command / check | Outcome |
|---|---|
| `<command>` | `<exit code / pass-fail / count>` |

Doc-authoring attestation lines live here as table rows, not free-form bullets.

**Blueprint-diff row.** Phase 4 dispatches touching the configured `visual-source-of-truth.path` add one row per protocol invocation:

```
Blueprint-diff (<type>) vs <blueprint-ref> on <path>: <N> expected / <M> unexpected / <K> pre-existing — surfaced + approved.
```

Inapplicable case — `Blueprint-diff: visual-SoT untouched — protocol n/a.` Full spec: `core/protocols/blueprint-diff-protocol.md`.

### `## Defects` *(when Phase 5 / Phase 6 QA return surfaces failures)*

One row per defect routed to Phase 6 per `core/process/phase-5-testing.md § Defect-reproducer` + `core/roles/qa-engineer.md § Defect-reproducer authoring discipline`.

| Defect | Suite | Test file | Test name | Observed vs expected | `testable` | Rationale |
|---|---|---|---|---|---|---|
| `<one-line>` | `<functional / e2e / unit / script / smoke / pixel-check>` | `<path>` | `<test name>` | `<observed → expected>` | `true | false` | `<one-line if false; — if true>` |

**Rules:**

1. `testable: true` → `Test file` + `Test name` MUST point to a committed failing test in the appropriate suite per `qa-engineer.details.md § Test-layer selection per defect class`. Reproducer-fail-first per same.
2. `testable: false` → `Rationale` MUST be set (one line); `Test file` + `Test name` columns render `—`.
3. One row per defect — no bundled rows.

Omit the section entirely when no failures surface.

### `## Open issues`

- `<issue>` — `<owner / blocker / TODO surfaced>`

Empty case: `(none)`.

### `## Next dispatch needed`

- `<role> · <surface> · <one-line reason>`

Empty case: `(none)`.

### `## Source reads (this dispatch)`

| Path | Justification | Index entry consulted |
|---|---|---|
| `<path>` | `<≤ 80 chars — why the index entry didn't suffice>` | `<index file cite>` OR `(no index entry — novel-class / out-of-index path)` |

Empty case: `(none)`. Required-with-empty-case — same shape as `## Hand-off` / `## Stop-state` (does not bump the 6-check count).

### `## Hand-off` *(when applicable)*

Per `core/templates/hand-off-note.md`. Required when the dispatch hit a forced-handoff (root cause outside the subagent's domain per `core/protocols/cross-agent-handoff.md`).

### `## Stop-state` *(when `Status: In-progress`)*

- **Done.** `<sub-tasks completed · files touched>`
- **In-progress.** `<sub-task interrupted · partial state · concrete resume instructions>`
- **Not-started.** `<sub-tasks remaining in approved batch · original estimates intact>`

### `## Time spent` *(when sub-issue mode is active)*

One line — cardinal-reported perceived effort (NOT wall-clock); progress-comment count for traceability:

```
1h 38m perceived effort; 4 progress comments on sub-issue #142.
```

Cardinal owns the number; team-lead never re-derives. Doubles as the rollup feeding the parent's `<!-- ginee:dispatch-map -->` sticky.

**In-flight cadence (every cardinal, sub-issue mode only).** While the dispatch runs, the cardinal posts progress comments on the sub-issue per `core/templates/sub-issue-dispatch.md § Comment cadence` — each carrying `time: <N>m` (since last comment) + `cumulative: <N>m` (since dispatch start). Doc-authoring self-lint applies. This is the SINGLE place where the cadence rule binds every cardinal; per-kernel addenda are intentionally avoided to keep the always-loaded surface free of duplication.

### `## Notes` *(optional, capped)*

Narrative rationale that genuinely won't fit on a `## Decisions made` bullet. ≤ 200 words. Code-snippet carve-out per forbidden-pattern #3.

## Worked size targets

| Dispatch class | Unbounded typical | Schema-bound target | Reduction |
|---|---:|---:|---:|
| Simple cardinal | 1,500–3,000 chars | 400–800 chars | ~70% |
| Complex Phase-4 | 5,000–15,000 chars | 1,500–3,000 chars | ~70% |
| Full Phase 1–8 | 30,000–80,000 chars | 8,000–20,000 chars | ~70% |

Material excess = self-lint failure; restructure before reporting.
