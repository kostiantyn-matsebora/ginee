# Migration — heavy-role bypass (team-lead + solution-architect across phases 4–7)

**Target release:** next minor after 2026-05-26.
**Affected adopters:** every adopter on every adapter — codifies an existing principle; no breaking change. Adopter `local/*` unchanged.

## What changed

Codifies the generalized form of [#152](https://github.com/kostiantyn-matsebora/ginee/issues/152)'s sub-issue fast-path — **persistence-artefact-based bypass + explicit re-entry triggers** — into a shared protocol covering both heavy roles (`team-lead` · `solution-architect`) across phases 4 / 5 / 6 / 7. Each `Phase 4–7` dispatch of either heavy role is now treated as **invocation-gated, not phase-gated**: default behaviour is *skip*; presence requires an affirmative trigger.

The codification is enforcement + observability — half the rules already existed in fragmented form (SA "governance dip" qualifiers in `phase-4`/`phase-5`/`phase-6`.md; "Review on architectural fix" in `phase-6`.md; sub-issue pickup fast-path in `core/skills/ginee-pick-up/SKILL.md`). The leak was orchestrators dispatching heavy roles defensively despite the trigger not firing.

## Shared machinery — `core/protocols/heavy-role-bypass.md`

Single source of truth. Two parts:

### Persistence-artefact table

| Heavy role | Persistence artefact | Bypass valid when |
|---|---|---|
| `team-lead` | `ginee:role:*` label + dispatch-contract body in sub-issue | Single role label + dispatch contract + AC unambiguous |
| `solution-architect` | Blueprint + ADRs + AC at Phase 2 | AC unambiguous · no SA-owned-file edit · no NFR-oracle red |

### Universal re-entry trigger table

| Trigger | Re-loads |
|---|---|
| Role label missing or conflicting | `team-lead` |
| Returned `## Open issues` non-empty | `team-lead` |
| Returned `## Hand-off` set | `team-lead` |
| Returned `Status: In-progress` | `team-lead` |
| Cross-domain bug surfaced | `team-lead` |
| Multi-cardinal PR (≥ 2 owned-path sets) | `team-lead` |
| PR touches `local/bindings.md` SA-owned path | `solution-architect` |
| NFR-oracle red | `solution-architect` |
| Fix proposal crosses blueprint-diff threshold | `solution-architect` |
| Engineer proposes architectural change mid-phase | `solution-architect` |

## Tracks

### Team-lead (TL1–TL4)

| # | Fast-path | Phase | First instance |
|---|---|---|---|
| TL1 | Sub-issue pickup | 4 (entry) | [#152](https://github.com/kostiantyn-matsebora/ginee/issues/152) — `migrations/sub-issue-fast-path.md` |
| TL2 | Single-cardinal verification | 5 | this protocol |
| TL3 | Intra-domain bug-fix | 6 | this protocol |
| TL4 | Phase 7 lead-elision (single-cardinal PR) | 7 | this protocol |

### Solution-architect (SA1–SA3)

| # | Fast-path | Phase | Rule source pre-codification |
|---|---|---|---|
| SA1 | Phase 4 SA-default-skip | 4 | `phase-4-implementation.md § governance dip` (already conditional; codified) |
| SA2 | Phase 5 SA-default-skip on green NFR | 5 | `phase-5-testing.md § governance dip` (already conditional; codified) |
| SA3 | Phase 6 SA-default-skip on local fix | 6 | `phase-6-bug-fixing.md § review on architectural fix` (already conditional; codified) |

## Out of scope (heavy role stays mandatory)

| Phase | `team-lead` | `solution-architect` |
|---|---|---|
| 1 — Analysis | always | always (design dip) |
| 2 — Design | always | always (architecture / ADRs) |
| 3 — Design review | always (synchronous user gate) | n/a |
| 8 — User approval | always (delivery finalize) | n/a |

Bypasses in these phases would corrupt the artefact chain downstream.

## Action required — none (adopter-side)

**Purely additive codification.** No `local/` schema change · no new commands · no adapter re-install. The next Phase 4–7 dispatch under any cardinal kernel runs against the shared protocol's gate automatically; orchestrators with internalized rules already behave this way and need not change anything.

## Files changed (framework upstream)

| Path | Change |
|---|---|
| `core/protocols/heavy-role-bypass.md` | **NEW** — load-on-demand shared protocol (persistence-artefact table · universal re-entry triggers · per-phase tracks · transcript-grep recipes) |
| `core/process/phase-4-implementation.md` | Roster qualified — `team-lead` / `solution-architect` rows cite the bypass protocol |
| `core/process/phase-5-testing.md` | Same — roster qualified for TL2 + SA2 |
| `core/process/phase-6-bug-fixing.md` | Same — roster qualified for TL3 + SA3 |
| `core/process/phase-7-sa-review.md` | Same — `team-lead` qualified for TL4 lead-elision |
| `core/roles/team-lead.md` | New `## Heavy-role bypass — when you are invoked at all` block citing the protocol |
| `core/roles/solution-architect.md` | New `**Heavy-role bypass.**` paragraph under `## Governance — continuous, scoped` |
| `docs/CONCEPTS.md` | One-line user-docs co-update under Phased task lifecycle |
| `migrations/heavy-role-bypass.md` | This file (**NEW**) |
| `core/protocols/doc-authoring-examples.md` | New worked example — one TL fast-path + one SA fast-path |

## Transcript-grep recipes — spotting defensive dispatch in past tasks

| Grep | Purpose |
|---|---|
| `@team-lead` invocation in a Phase 4–6 window | Match each against the universal re-entry trigger table. Unmatched → defensive dispatch. |
| `@solution-architect` dispatches outside Phase 1 / 2 / 7 | Match each against the SA-track triggers. Unmatched → defensive. |
| `## Open issues\n(none)` immediately followed by `@team-lead` re-dispatch | Orchestrator dispatched team-lead after a clean return → defensive. |
| `Status: Done` + empty `## Hand-off` + `@team-lead` immediate re-entry | Same — no trigger fired. |

Advisories surface one-line; never auto-rewrite the transcript. The aim is to retrain orchestrators, not to gate post-hoc.

## Backward compatibility

- **Adopter `local/*`** — no schema change.
- **In-flight tasks** — no behaviour change; protocol re-states existing rules in unified form.
- **Closed-task transcripts** — not retroactively re-classified.
- **Adapter renderings** — none required; spec lives in `core/`.
- **Heavy role kernels** — `team-lead.md` + `solution-architect.md` get a citation-only block each; no rule restated outside the shared protocol.

## Rollback

To revert:

1. Remove `core/protocols/heavy-role-bypass.md`.
2. Revert phase-roster qualifiers in `core/process/phase-4-implementation.md` · `phase-5-testing.md` · `phase-6-bug-fixing.md` · `phase-7-sa-review.md` to their unconditional form.
3. Remove the `## Heavy-role bypass` block from `core/roles/team-lead.md`.
4. Remove the `**Heavy-role bypass.**` paragraph from `core/roles/solution-architect.md § Governance — continuous, scoped`.
5. Remove the user-docs line from `docs/CONCEPTS.md`.
6. Remove the worked example from `core/protocols/doc-authoring-examples.md`.
7. Delete this migration file.

Framework still functions; defensive dispatches return + the "habitual heavy-role ceremony" failure mode returns. TL1 (sub-issue fast-path per [#152](https://github.com/kostiantyn-matsebora/ginee/issues/152)) remains intact independently.

## Out of scope

- Compliance / force-class machinery — separate cohort ([#135](https://github.com/kostiantyn-matsebora/ginee/issues/135)).
- Other cardinals (engineers / QA / ai-engineer) — their footprints don't justify the bypass spec overhead.
- MCP-server-based context-routing — deferred to v2.0 per `CLAUDE.md § Out of scope`.
- Renaming or restructuring heavy roles — bypass only; role definitions unchanged.

## Issue reference

Closes [#162](https://github.com/kostiantyn-matsebora/ginee/issues/162) — *"[Framework Feature] Heavy roles as on-demand — codify team-lead + SA bypass across phases 4–7."*

Builds on [#152](https://github.com/kostiantyn-matsebora/ginee/issues/152) — *"Sub-issue fast-path — dispatch labeled role without re-routing through team-lead."*
