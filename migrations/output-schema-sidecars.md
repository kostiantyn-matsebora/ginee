# Migration — Output-schema sidecars

**Target release:** next minor after 2026-05-25.
**Affected adopters:** every adopter on every adapter — purely additive; forward-only; nothing to do.
**Closes:** [#131](https://github.com/kostiantyn-matsebora/ginee/issues/131).
**Specs (NEW):**

- [`core/protocols/dispatch-prompt-schema.md`](../core/protocols/dispatch-prompt-schema.md)
- [`core/protocols/score-comment-schema.md`](../core/protocols/score-comment-schema.md)
- [`core/protocols/audit-comment-schema.md`](../core/protocols/audit-comment-schema.md)
- [`core/protocols/sub-issue-dispatch-schema.md`](../core/protocols/sub-issue-dispatch-schema.md)
- [`core/protocols/review-cycle-schema.md`](../core/protocols/review-cycle-schema.md)

## What changed

Five new schema sidecars under `core/protocols/`, each following the `core/templates/phase-report.md` meta-template (`## Schema` · `## Section templates` · `## Forbidden patterns` · `## Worked example` · `## Self-lint checks` + mandatory `<!-- self-lint: pass -->` marker). They document shapes the framework *already produces* — no new behavioural rules, no new validators.

| Sidecar | Binds the shape of | Consolidates / replaces |
|---|---|---|
| `dispatch-prompt-schema.md` | Team-lead dispatch payload (Reading list · Task · Read discipline · Deliverable · Required output · Forbidden · capability-tool hints · carry-forward) | New canonical shape; existing dispatch rules in `core/process/dispatch.md` + role kernels cross-ref this |
| `score-comment-schema.md` | Sticky `ginee:score` comment | Cross-ref'd from `core/protocols/triage-scoring.md § Score comment + audit trail` (prose form preserved; sidecar carries the schema) |
| `audit-comment-schema.md` | `ginee:value-prompt` · `ginee:complexity-estimate` · `ginee:score-recompute` audit comments | Cross-ref'd from `core/protocols/triage-scoring.md § Immutable audit comments` (rules preserved) |
| `sub-issue-dispatch-schema.md` | Sub-issue body + progress comments + closing comment | Cross-ref'd from `core/protocols/github-integration.md § Sub-issue dispatch` + `core/templates/sub-issue-dispatch.md` |
| `review-cycle-schema.md` | Per-thread review-reply + sticky `ginee:review-cycle` comment | Cross-ref'd from `core/protocols/github-integration.md § Review-comment ingestion` + `core/templates/pr-comment-cadence.md` |

## Why

Pre-cutover the only structured-output surface with an explicit cardinality table + section templates + forbidden patterns + self-lint marker was `core/templates/phase-report.md`. Every other structured output the framework produces (dispatch prompts · sticky comments · audit comments · sub-issue bodies · review-cycle comments) was reconstructed by pattern-matching prior examples on every dispatch. Format drift compounded — same audit operation produced slightly different bodies depending on which spec the cardinal anchored on. Sidecars close that gap.

## Adopter migration

**Nothing required.** Purely additive — no `local/` schema change; no installer flag change; no skill trigger change; no script behaviour change. Existing comments / dispatches / sub-issues stay valid (forward-only; sidecars never retroactively rewrite history).

The next time `team-lead` drafts a dispatch / posts a sticky / opens a sub-issue / runs a review cycle, the cardinal consults the matching schema sidecar and self-lints against it before publishing.

## Lossless preservation

Every rule cross-ref'd from an existing spec survives byte-for-byte:

| Source spec | Touched section | Diff |
|---|---|---|
| `core/protocols/triage-scoring.md` | `§ Score comment + audit trail` | One sentence appended pointing at `score-comment-schema.md` + `audit-comment-schema.md` |
| `core/protocols/github-integration.md` | `§ Review-comment ingestion` | One sentence appended pointing at `review-cycle-schema.md` |
| `core/protocols/github-integration.md` | `§ Sub-issue dispatch` | Cross-ref to `sub-issue-dispatch-schema.md` appended to the existing sentence |
| `core/process/dispatch.md` | `§ Dispatch & parallelism rules` (lead-in) | One sentence pointing at `dispatch-prompt-schema.md` |
| `core/templates/sub-issue-dispatch.md` | header | Header note pointing at `sub-issue-dispatch-schema.md` |
| `core/templates/pr-comment-cadence.md` | header | Header note pointing at `review-cycle-schema.md` |

No rule deleted. No rule reworded.

## Files updated

| File | Change |
|---|---|
| `core/protocols/dispatch-prompt-schema.md` (NEW) | Full schema |
| `core/protocols/score-comment-schema.md` (NEW) | Full schema |
| `core/protocols/audit-comment-schema.md` (NEW) | Full schema |
| `core/protocols/sub-issue-dispatch-schema.md` (NEW) | Full schema |
| `core/protocols/review-cycle-schema.md` (NEW) | Full schema |
| `core/protocols/triage-scoring.md` | Cross-ref lines |
| `core/protocols/github-integration.md` | Cross-ref lines |
| `core/process/dispatch.md` | Cross-ref lead-in |
| `core/templates/sub-issue-dispatch.md` | Header cross-ref |
| `core/templates/pr-comment-cadence.md` | Header cross-ref |
| `docs/CONCEPTS.md` · `docs/CHEATSHEET.md` | One-line adopter-facing cross-refs |
| `CLAUDE.md` · `PLAN.md` | D49 row |
| `migrations/output-schema-sidecars.md` | This file |

## Backwards compatibility

Purely additive. `local/framework.config.yaml` schema unchanged. Installer flags unchanged. Skill triggers unchanged. No `core/` rule walked back. Forward-only — pre-existing comments / dispatches / sub-issue bodies / cycle stickies are not retroactively rewritten.

## Out of scope

- **External linter.** LLM self-review against the schema; same machinery as the phase-report 6 mandatory checks + sticky `<!-- self-lint: pass -->` marker.
- **Retroactive sweep.** Forward-only.
- **Adopter `local/` extension to add per-project schema sidecars.** Open question; revisit if motivating use case emerges.
