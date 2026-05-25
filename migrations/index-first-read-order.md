# Migration — index-first read order

**Target release:** next minor.
**Affected adopters:** every adopter — applies on next cardinal dispatch under the updated framework.
**Closes:** [#125](https://github.com/kostiantyn-matsebora/ginee/issues/125).

## What changed

Pre-change the index-first rule lived inside `core/protocols/index-protocol.md § Role consumption pattern → Trigger evaluation → step 3` — buried, not load-bearing. Cardinals silently fell through to full raw source reads when the dispatch prompt was silent (e.g. SA auto-complexity-estimate per `core/protocols/triage-scoring.md § Auto-estimation on pickup` defaulted to "skim affected paths"). Net — token cost of dispatches inflated beyond what the index was designed to eliminate.

Three coupled changes promote the rule from buried to bedrock:

1. **`core/protocols/index-protocol.md § Read order`** — new top-level H2, first body section above `§ Why`. Three terse rules — index-first bedrock · raw-source-read trigger conditions · justification-required reporting. Existing `§ Why` + `§ Role consumption pattern` content unchanged; new section is the bedrock the per-tier mechanics implement.
2. **Dispatch-contract wiring.**
   - `core/protocols/triage-scoring.md § Auto-estimation on pickup` — explicit clause: *"solution-architect gathers signals from `issue body + index entries` only; raw source reads require a one-line justification in the return per `core/templates/phase-report.md § Source reads (this dispatch)`."*
   - `core/process/dispatch.md § Dispatch & parallelism rules` — bans free-text *"skim affected paths"* / *"read relevant files"* / *"explore the codebase"* variants in dispatch authoring; points at `index-protocol.md § Read order` as the contract default.
3. **`core/templates/phase-report.md`** — new mandatory-with-empty-case section `## Source reads (this dispatch)`. Table — `Path` · `Justification` · `Index entry consulted`. Empty case `(none)`. Plus a narrow re-dispatch carve-out: when raw source paths appear in `## Files touched` AND `## Source reads` is missing or `(none)`, orchestrator re-dispatches for the justification cycle — first format-only re-dispatch in the schema, scoped to this content-substantive omission.

## Why

Issue #125 (filed by the framework owner mid-task) captures the live failure mode:

| Trace | Detail |
|---|---|
| Trigger | `@team-lead pick up #<N>` against an issue with no `complexity:*` label. |
| Drift | team-lead's dispatch prompt to SA said *"skim affected paths to ground the estimate"* — no `consult index first` clause. |
| Symptom | SA loaded full TypeScript / source files under `mockup/src/app/`, `frontend/matrix/`, `docs/adr/`, etc. — burning tokens before the estimate returned. |
| Root cause 1 | Consume-side rule of `core/protocols/index-protocol.md § Why` (the index *replaces* full reads with summaries) was buried at step 3 of a sub-section. Drifts past on read. |
| Root cause 2 | `core/protocols/triage-scoring.md § Auto-estimation on pickup` listed signals to gather but was silent on *how* to gather them — gather method inherited whatever team-lead's free-text dispatch prompt said. |
| Root cause 3 | Cardinal returns reported `Loaded baselines` (per spec) but not `Source reads + justification` — silent source-read drift invisible to team-lead's gate. |

The index protocol exists to cut adopter token cost. Without a bedrock placement + dispatch-contract wiring + return-shape audit trail, the savings were lossy by default.

## Adopter migration

**Nothing to do.** Applies automatically on next cardinal dispatch under the updated framework.

**What you'll see in cardinal returns from now on:**

- Every return carries a `## Source reads (this dispatch)` block. Empty case `(none)` when the cardinal worked from index entries only — the cheap path.
- Returns with raw source-path entries in `## Files touched` BUT empty `## Source reads` trigger a one-cycle re-dispatch from team-lead to fill in the justification table — first format-only re-dispatch in the schema; scoped narrowly to this audit-trail omission.
- Dispatch prompts authored by team-lead instruct specialists to consult the index first; the old *"skim affected paths"* style is forbidden in dispatch authoring.

**No `local/` schema change.** Purely additive — adopters with no `local/index/` populated yet see the empty-case `(none)` rendering consistently; the rule degrades gracefully.

## Files touched (this migration)

| Path | Change |
|---|---|
| `core/protocols/index-protocol.md` | +7 / -0 — new `## Read order` H2 above `## Why` |
| `core/protocols/triage-scoring.md` | +2 / -1 — new step in `§ Auto-estimation on pickup` (index-first clause) |
| `core/process/dispatch.md` | +1 / -0 — new row banning free-text source-read instructions |
| `core/templates/phase-report.md` | +14 / -1 — `## Source reads` section + `### Format-only re-dispatch — single carve-out` H3 |
| `docs/CONCEPTS.md` | +N / -M — sync `§ Subagent-return schema` table + index-first paragraph |
| `docs/CHEATSHEET.md` | +N / -M — sync `§ Subagent-return schema` block + index-first paragraph |

## Action required

None — framework-side only; defaults preserve every prior cardinal-return rule.
