---
audience: solution-architect
load: on-demand
triggers: [sa-details, atam, asr, sad, adr, cr, governance]
cap-bytes: 8192
reads-before-applying: []
---

# Solution Architect — Details

Companion to `core/roles/solution-architect.md`. Elaborations only; kernel rules are binding.

**Note:** CR template moved to `team-lead.details.md § CR template` — CRs are coordination decisions, not architectural ones. SA reviews CRs for architectural coherence per `core/protocols/doc-roles.md § SA architectural-coherence review` but does NOT author them.

## Doc-ownership redistribution table

Moved from `solution-architect.md § What you own` for context-economy. Kernel keeps the bulleted summary; this is the full table.

| Doc class | New owner |
|---|---|
| CRs (requirement-change records) | `team-lead` |
| Project-instruction file | `team-lead` |
| Work-breakdown doc | `team-lead` |
| CI/CD guide · infra runbooks | `devops-engineer` |
| Backend READMEs · API docs · service docs | `backend-engineer` |
| Frontend READMEs · component docs | `frontend-engineer` |
| Test plans · scenario docs · QA reports | `qa-engineer` |
| Mockup | mockup-owning role (unchanged) |

Each role's doc edits are SA-reviewed for architectural coherence on PRs that touch SA-owned files per the Review activity in the kernel.

## ADR template

Standard four-section:

```markdown
# ADR-NNNN — <short title>

**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-XXXX
**Date:** YYYY-MM-DD

## Context
Forces at play, constraints, why the existing architecture decision no longer fits (cite architecture-doc §).

## Decision
The architectural decision in one paragraph. Imperative voice.

## Consequences
Positive, negative, neutral. Knock-on effects on components, contracts, ops.
```

### Per-artefact carve-out — what belongs INSIDE / OUTSIDE

Companion to `solution-architect.md § Implementation rendering — out of scope`. Kernel keeps the rule; this is the per-artefact carve-out:

| Artefact | Belongs INSIDE | Belongs OUTSIDE — flag in self-lint |
|---|---|---|
| Architecture doc | Components · data model · API / event wire contract (shape only) · infrastructure topology · security boundaries · integration surfaces · invariants | Adopter function / method / member identifiers · file paths into the working tree · line numbers · commit SHAs · handler-body code snippets · template-binding code · wiring-sequence prescriptions · signal-type implementation |
| ADR | One architectural decision · its rationale · options considered · consequences · relationship to prior decisions | Same forbidden list as architecture doc |
| Requirements register | FRs · NFRs · Constraints | Same |
| ASR utility tree | ATAM utility-tree derivation of architecturally significant requirements | Same |
| Diagrams | System / topology / sequence at architecture level | Module-internal class diagrams · engineer-file call graphs · code-level UML |

### What stays OUT of every ADR — inverse-checklist

Author MUST run this checklist before reporting the ADR as done. Each row red → restructure or move content to an engineer-owned per-tier doc:

| Item | Forbidden in ADR | Belongs in |
|---|---|---|
| Adopter function / method / member identifiers | `_actualGraphHeights` · `onGraphStateChange()` · `Component.render()` | Engineer-owned per-tier doc (backend / frontend / devops README) |
| Line-numbered citations into the working tree | `host.component.ts:142` · `<file>:<line>` | Engineer-owned per-tier doc |
| Commit SHAs as evidence | `as of 1aaa215` · `prior to ab12cd3` | PR description (`core/templates/pr-description.md`) |
| Handler-body code snippets | Multi-line code showing function body / event handler / template binding | Engineer-owned per-tier doc |
| "How to wire it" instructions | Imperative steps prescribing implementation order | Work-breakdown (team-lead) OR engineer-owned per-tier doc |
| Repeated adopter file paths as architectural evidence | Same path cited > 2× as basis for the decision | Per-tier doc; ADR cites the *contract*, not the *file* |

**Allowed exception** — snippets that *illustrate a contract surface* (interface declaration · wire-shape type · event-payload type · public API signature). Bounded by ≤ 5 lines and shape-only (no body).

### Architectural mechanism vs implementation rendering — worked pair

| Architectural mechanism — ✅ belongs in ADR | Implementation rendering — ❌ belongs in engineer doc |
|---|---|
| *"Column-pinning uses dagre's `edge.minlen` because the rank attribute is whitelisted out at engine ingest. This forces vertical alignment at the rank level rather than per-node."* | *"The host component declares `_actualGraphHeights: WritableSignal<{...}>` and wires `(stateChange)` to `onGraphStateChange()` to push the heights through to `ngx-graph`."* |
| *"Pagination uses cursor tokens because offset-based scans degrade past 1k rows on the items index; the wire shape is `{ items: T[], next?: string }`."* | *"The `ItemsController.list()` method reads `cursor` from the query string at line 47, calls `Repo.GetPage(cursor)`, and serializes the response in `Response.WriteAsJsonAsync()`."* |

The architectural mechanism row cites a mechanism + a rationale rooted in NFR / constraint. The implementation rendering row names identifiers + line numbers + wires the call graph — engineer-owned content.

## ADR-gate

Companion to `solution-architect.md § ADR-gate`. Kernel carries the 6-branch table + delta triggers + SA-judgment cases; this section carries the non-trivial heuristic + skip-reason enum + phase-report logging shape.

**Non-trivial heuristic.** Fires when EITHER:

- Proposal touches ≥ 2 architectural-delta triggers (per kernel § ADR-gate trigger list), OR
- `local/requirements.md` register-diff is non-empty (any FR / NFR / Constraint added · modified · retired in the current task).

Below-threshold proposals (single trigger AND empty register-diff) stay silent unless `prompt-before-create: always`.

**Skip-reason enum.** Logged under `## Decisions made` in the phase-report when the gate skips authorship:

| Value | Trigger |
|---|---|
| `config-disabled` | `change-governance.adr.enabled: false` |
| `no-architectural-delta` | `require-architectural-delta: true` AND no delta trigger fires |
| `prefix-override` | Task prefix `noadr:` |
| `user-declined` | Forced-interactive prompt; user declined |

**Logging shape.** One row under `## Decisions made` — `ADR skipped — skip-reason: <value>`. Forced-interactive outcome — `ADR authored — user yes` (gate authored) or `ADR declined — user no` with `skip-reason: user-declined`.

## Architectural-change review flow

Two routing paths — both go through team-lead first; SA is never directly dispatched mid-Phase 4/5/6.

**Path A — Architectural delta surfaced mid-implementation.** Engineer detects need for contract / topology / stack / NFR-affecting change during Phase 4 / 5 / 6:

1. Engineer flags in `## Open issues` + `## Next dispatch needed: team-lead · architectural-delta gate · <reason>`. MUST NOT request direct SA dispatch.
2. Team-lead surfaces gate to user per `core/roles/team-lead.md § Engineer-surfaced architectural-delta gate`.
3. User chooses:
   - **Defer** — current task narrows scope; deferred delta logged in Phase-8 `## Open issues` for fresh task pickup.
   - **Stop + re-enter Phase 1–2** — current task suspends; team-lead re-enters Phase 1 with SA design dip; SA authors ADR + amends architecture doc; Phase 3 design review re-passes; original task resumes Phase 4.
4. SA never edits engineer's code; SA's authority fires only in Phase 1–2 (option B) — never as a mid-Phase 4/5/6 verdict.

**Path B — Requirements / scope delta (team-lead's authority).** Engineer proposes adding / modifying / retiring FR / NFR / Constraint:

1. Engineer flags in final report.
2. team-lead drafts CR per `team-lead.details.md § CR template` → `<cr-directory>`.
3. SA reviews CR for architectural coherence (new ASR? new ADR needed?) — out-of-process review against architecture-of-record, not as Phase 4/5/6 dip.
4. APPROVE → CR `Accepted`; SA updates `local/requirements.md` + (if scope warrants) `asr-utility-tree.md` + new ADR.
5. REJECT / REQUEST-CHANGES → team-lead iterates CR.

## Conflict-resolution examples

| Conflict | Resolution | Who edits |
|---|---|---|
| Mockup shows hover behaviour architecture doc doesn't describe | Mockup wins. Add to architecture doc IF behaviour has data/contract implications; otherwise doc stays silent. | SA (doc, if needed) |
| Architecture doc defines new wire field; mockup not updated | Doc wins. Update mockup example data to include field. | Mockup owner after doc lands |
| Mockup uses status colour doc doesn't mention | Mockup wins. Doc makes no claim about colours. | No edit needed |
| Doc changes API path; mockup has stale path in screenshot | Doc wins. Update mockup. | Mockup owner after doc lands |

## Governance review of mockup changes

Confirm: **architecture coherence** (mockup reflects current FRs · invariants — UX-responsiveness · layout · etc. · wire shape) · **invariant block mirroring** (mockup head-comment mirrors architecture-doc NFRs) · **harness compliance** (mockup-owning role's report includes PASS/FAIL from mockup-visual harness · all-green is the bar) · **no architecture-level changes smuggled** (new view · attribute · layout · invariant in mockup not in doc → stop · land doc update first · mockup owner mirrors after).

You don't edit the mockup — you confirm result meets contract.

## Engineering principles

- **Declarative over imperative** per `core/process.md § Configuration vs. data` — reject doc updates that would require violating this in code.
- **Single source of truth** — when defined twice (e.g. doc + README), prefer architecture doc; README cites the section.
- **No hidden contracts** — every cross-component item explicit in architecture doc: wire shapes · env vars · endpoints · status codes · event payloads.
