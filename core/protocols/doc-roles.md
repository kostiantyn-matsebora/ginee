---
audience: all-cardinals
load: on-demand
triggers: [doc-roles, doc-ownership, authorship]
cap-bytes: 6144
reads-before-applying: []
---

# Doc roles — all-roles authorship + ai-engineer shape

Loaded when a new role-owned doc lands · a doc grows past size threshold / exhibits duplication · cross-reference repair needed across multiple docs · structure dispute surfaces between authoring role and `ai-engineer`. Default tasks do not load.

Generalised from earlier SA ↔ ai-engineer two-role co-ownership: every role authors content in its domain; `ai-engineer` owns shape + load topology across the whole set.

## Authorship — per role, per doc class

| Doc class | Author |
|---|---|
| Architecture doc · ADRs · diagrams · requirements register (`local/requirements.md`) · ASR utility tree (`local/asr-utility-tree.md`) | `solution-architect` |
| CRs · project-instruction file (`CLAUDE.md` / `AGENTS.md` / equivalent) · work-breakdown doc | `team-lead` |
| CI/CD guide · infrastructure runbooks · deployment guides | `devops-engineer` |
| Backend READMEs · API docs · service docs | `backend-engineer` |
| Frontend READMEs · component docs · style guides | `frontend-engineer` |
| Test plans · scenario docs · QA reports | `qa-engineer` |
| Mockup | mockup-owning role (default `frontend-engineer`) |
| Role definitions (`core/roles/*.md`) · process spec (`core/process.md`) · skills (`core/skills/`) | framework upstream (adopter authors `local/roles/` only) |

## Ownership split — semantics vs shape

- **Author owns semantics** — rules · invariants · requirements · routing entries · gates. Adding / removing / rewording is author's call.
- **`ai-engineer` owns shape + load topology** — structure (tables vs prose) · file splits · cross-reference integrity · byte / line discipline. Never changes semantics.
- Neither overrides the other's invariants. Runs under `core/protocols/iteration-protocol.md`.

## Routing

| Scenario | Routing |
|---|---|
| New rule / invariant / routing entry / governance decision | **Owning role** per § Authorship. `ai-engineer` may run structural pass after. |
| Doc grows past size threshold OR has duplication | `ai-engineer` compacts / splits. Author post-reviews — no rule lost. |
| Cross-refs break from split / move | `ai-engineer` updates refs. Author verifies semantic continuity. |
| Scope unclear (which role owns?) | `team-lead` resolves via `local/bindings.md § Source-of-truth ownership`. |
| Spans semantics + shape | Pair-dispatch — author edits content; `ai-engineer` edits shape. Author first. |
| Author wants prose; `ai-engineer` wants table | Author wins on semantics; `ai-engineer` may propose alt structure preserving clarity. |
| Architectural-coherence concern on non-SA doc | `solution-architect` reviews per `core/roles/solution-architect.md § Review`. APPROVE / REJECT / REQUEST-CHANGES; never edits. |

## SA architectural-coherence review

Non-SA-owned doc edits touching architectural concerns route through SA — but **only at Phase 7 (conditional governance) or out-of-process Review**, never as a Phase 4 / 5 / 6 dip. Folds into `core/roles/solution-architect.md § Governance` (Phase 7) or `§ Review` (out-of-process).

- **Trigger.** Engineer / team-lead / mockup-owner doc edit touches architectural concern (component name · contract · stack reference · NFR-bearing claim · invariant) AND lands in a PR that also triggers Phase 7 SA dispatch (task introduced architectural changes OR `post-implementation-governance: yes`). Standalone non-architectural-change doc edits do NOT pull SA in.
- **Outcome.** APPROVE (architecturally coherent) / RETURN-TO-author (specific findings). No edits to author's doc.
- **Out of scope.** Pure-engineering wording not touching architectural concerns (code example values · README phrasing nuance) — author judgment, no SA review.
- **Mid-Phase 4/5/6 architectural-coherence concerns** — engineer flags in `## Open issues` + routes through team-lead's `§ Engineer-surfaced architectural-delta gate` per `core/roles/team-lead.md`; never direct SA dispatch mid-phase.

## Lossless rule

Before completing any optimization pass, `ai-engineer` spot-checks every rule · invariant · routing entry · gate in the diff. Each MUST appear (verbatim or semantically identical) in the new structure. Any miss → revert + re-plan. Applies across the whole doc set.

## Dispatch trigger

Not part of standard Phase 1–8. Invoked between phases on: user-explicit AI-asset / doc optimization · authoring-role flag (*"this doc is getting unwieldy"*) · periodic maintenance (release · post-large-feature cleanup) · Phase 8 post-acceptance doc-optimization hook.
