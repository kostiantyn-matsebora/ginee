---
audience: team-lead-only
load: on-demand
triggers: [dispatch prompt, dispatch contract, specialist dispatch, dispatch payload]
cap-bytes: 6144
reads-before-applying: [core/process/dispatch.md, core/templates/phase-report.md]
---

# Dispatch-prompt schema

**Load-on-demand.** Loaded when `team-lead` drafts a specialist dispatch payload — Phase 1–8 cardinal · sub-issue · review-cycle · skill-runner first-batch dispatch (per `core/process/dispatch.md § Skill-runner — surface boundary`).

Sister schema to `core/templates/phase-report.md` — that file binds the *return* surface; this one binds the *dispatch* surface. Same machinery — cardinality · templates · forbidden · self-lint marker.

## Schema

| Section | Cardinality | Default shape |
|---|---|---|
| `## Reading list` | **required** (else `(none)`) | Bullets — `<path> — <what the specialist needs from it>` |
| `## Task` | **required** | One paragraph — verb-first; ≤ 4 sentences |
| `## Read discipline` | **required** | One paragraph citing `core/protocols/index-protocol.md § Read order` |
| `## Deliverable` | **required** | Bullets — `<deliverable-id> — <one-line description>`; ≤ 80 chars |
| `## Required output` | **required** | One line citing `core/templates/phase-report.md` + per-task addenda |
| `## Forbidden` | optional | Per-task forbidden ops; cite the source rule |
| `## Capability-tool hints` | optional | Per-tool one-liner per `core/process/dispatch.md § Host capability-tool affinity injection` |
| `## Carry-forward` | optional | Single-line reminder per `core/templates/phase-report.md § Carry-forward rephrasing` |

## Section templates

### `## Reading list`

```
- core/protocols/<spec>.md — <what the specialist needs from it>
- local/index/<entry>.yaml — <which entries cover the task surface>
```

Empty case: `(none)`.

### `## Read discipline`

```
Index-first per core/protocols/index-protocol.md § Read order. Raw source reads
require one-line justification per core/templates/phase-report.md § Source reads
(this dispatch).
```

### `## Required output`

```
Phase-report schema per core/templates/phase-report.md. <per-task addenda — e.g.
"sub-issue mode: include ## Time spent">. End with <!-- self-lint: pass --> marker.
```

### `## Carry-forward` *(optional)*

```
Return format: schema-bound per core/templates/phase-report.md;
last cycle's return missed self-lint (<violation>) — apply the 6 checks + marker this cycle.
```

## Forbidden patterns

1. **Narrative preamble.** *"Please go and look at X, then think about Y…"* → `## Task` paragraph directly.
2. **Restated framework rules.** Cite by location; never paste the rule body.
3. **Free-text `## Read discipline` variants** — "skim affected paths", "read relevant files", "explore the codebase". Per `core/process/dispatch.md § Index-first read discipline in dispatch payload`.
4. **Mixed surfaces in `## Deliverable`** when work crosses role boundaries. Decompose into parallel dispatches per `core/process/dispatch.md § Dispatch & parallelism rules`.
5. **Skill-runner carrying tracking-mode posture · warm-vs-fresh decisions · routing reconciliation.** Per `core/process/dispatch.md § Skill-runner — surface boundary`.

## Worked example

```
## Reading list
- core/protocols/triage-scoring.md — H/M/L scale + WSJF formula
- local/index/repo-map.idx — files touching pickup flow

## Task
Auto-estimate complexity for issue #131 per the auto-estimation hook on pickup;
return H/M/L with one-line signal digest.

## Read discipline
Index-first per core/protocols/index-protocol.md § Read order. Raw source reads
require one-line justification per core/templates/phase-report.md § Source reads
(this dispatch).

## Deliverable
- complexity-estimate — H/M/L + one-line signal digest for the sticky reasoning column

## Required output
Phase-report schema per core/templates/phase-report.md. End with <!-- self-lint: pass -->.

## Forbidden
- Auto-set value — cite core/protocols/triage-scoring.md § Forbidden
```

## Self-lint checks

Run all 5 against the drafted dispatch **before** sending:

1. No paragraph contains > 2 rules (sentence terminators).
2. Inventories are tables / bullets, not prose.
3. Reading-list entries cite a path; never restate the rule.
4. `## Read discipline` cites `core/protocols/index-protocol.md § Read order` verbatim.
5. No narrative preamble — first non-header line is a `##` section header.

Append, as the **last line**, the literal attestation marker `<!-- self-lint: pass -->`.

<!-- self-lint: pass -->
