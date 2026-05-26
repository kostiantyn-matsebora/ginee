# Migration — sub-issue fast-path (ginee-pick-up)

**Target release:** next minor after 2026-05-26.
**Affected adopters:** every adopter on every adapter — purely additive; no breaking change.

## What changed

`ginee-pick-up` now detects sub-issue parentage and dispatches the labelled cardinal directly. Before this change, every `pick up #<N>` re-routed through `@team-lead` — even when the sub-issue already carried a `ginee:role:<cardinal>` label and a populated dispatch body (`core/templates/sub-issue-dispatch.md` shape). The team-lead re-route paid one full ~15–40k token dispatch to re-derive a routing decision the parent already encoded.

The fast-path applies **only** to sub-issues; parent issues still hand off to `@team-lead`. Re-entry through `@team-lead` is mandatory on five trigger conditions (role-label gap · `## Open issues` non-empty · `## Hand-off` set · `Status: In-progress` · cross-domain bug).

## Resolution

Skill-runner pre-dispatch decision per `core/skills/ginee-pick-up/SKILL.md § Step 2.5`:

| Source shape | Fast-path applies | Hand-off target |
|---|---|---|
| Parent issue | no | `@team-lead` |
| Sub-issue · single `ginee:role:*` label · dispatch-contract body | yes | `@<cardinal>` |
| Sub-issue · zero or >1 role labels | no | `@team-lead` (routing absent / ambiguous) |
| Sub-issue · role label present · body missing dispatch contract | no | `@team-lead` (artefact incomplete) |

Detection — `gh api repos/{owner}/{repo}/issues/{N}` exposes the `parent_issue` reference (or equivalent `sub_issue_of`); skill-runner confirms membership via `gh api repos/{owner}/{repo}/issues/{parent}/sub_issues`.

## Re-entry triggers

`@team-lead` is re-loaded mid-dispatch on any of:

| Trigger | Source | Why |
|---|---|---|
| Role label missing or conflicting | pre-dispatch check | Routing decision absent — re-derive |
| Cardinal return — `## Open issues` non-empty | phase-report consume | Cross-cardinal synthesis needed |
| Cardinal return — `## Hand-off` set | phase-report consume | Routing change — re-plan |
| Cardinal return — `Status: In-progress` | phase-report consume | Stop-state — re-decide |
| Cross-domain bug surfaced | `core/protocols/cross-domain-bugs.md` | Integration cycle required |

Skill-runner never synthesizes the cardinal return — on any trigger the return is forwarded to `@team-lead` as inbound payload, unchanged. Same forbiddens as `core/process/dispatch.md § Skill-runner — surface boundary` apply across the dispatched cardinal lifetime.

## Enforcement

LLM self-decision against the four-condition gate **before** the Step 3 hand-off. No external linter — the skill text + `github-integration.md § Sub-issue dispatch` contract are the spec.

| Stage | Mechanism |
|---|---|
| Detect | `gh api .../issues/{N}` — read `parent_issue` field |
| Decide | Step 2.5 four-condition gate |
| Hand off | Step 3 table — `@<cardinal>` or `@team-lead` |
| Re-enter | Cardinal return consumed against trigger table; `@team-lead` dispatched on hit |

## Action required — none (adopter-side)

**Purely additive.** No `local/` schema change · no new commands · no adapter re-install. The next `pick up #<N>` invocation against a sub-issue with a populated routing artefact takes the fast-path automatically. Parent-issue pickups behave exactly as before.

## Files changed (framework upstream)

| Path | Change |
|---|---|
| `core/skills/ginee-pick-up/SKILL.md` | New `### Step 2.5 — sub-issue fast-path` section + Step 3 hand-off table |
| `core/protocols/doc-authoring-examples.md` | New paired example — sub-issue dispatch fast-path vs re-route |
| `migrations/sub-issue-fast-path.md` | This file (**NEW**) |

## Backward compatibility

- **Adopter `local/*`** — no schema change.
- **In-flight sub-issues** — fast-path applies on next pickup; no retroactive change.
- **Parent-issue pickups** — unchanged.
- **TODO + freeform sources** — unchanged (no parent / routing artefact concept applies).
- **`framework.config.yaml`** — no new keys.
- **Adapter renderings** — none required; spec lives in `core/`.

## Rollback

To revert:

1. Remove `### Step 2.5 — sub-issue fast-path` from `core/skills/ginee-pick-up/SKILL.md`.
2. Restore the original Step 3 prose (`After the mechanical ops ... skill-runner dispatches @team-lead ...`).
3. Remove the worked example from `core/protocols/doc-authoring-examples.md`.
4. Delete this migration file.

Skill-runner reverts to unconditional `@team-lead` hand-off; every sub-issue pickup re-derives routing and pays the full team-lead dispatch cost.

## Out of scope

Cross-cardinal synthesis fast-paths (`@team-lead` skips on single-cardinal verification or intra-domain bug-fix) — separate feature, generalizes this pattern across phases 4–7. The fast-path here is the orchestration-efficiency carve-out for sub-issue pickup only.

## Issue reference

Closes [#152](https://github.com/kostiantyn-matsebora/ginee/issues/152) — *"[Framework Feature] Sub-issue fast-path — dispatch labeled role without re-routing through team-lead."*
