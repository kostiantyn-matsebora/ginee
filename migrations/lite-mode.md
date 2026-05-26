# Migration — lite mode (`lite:` / `direct:` per-task prefix)

**Target release:** next minor after 2026-05-26.
**Affected adopters:** every adopter on every adapter — opt-in via prefix or config; no breaking change.

## What changed

Phase 1–8 is calibrated for non-trivial work. A typo fix · single-label tweak · single-doc-bullet change does not need requirements elicitation + architecture proposal + work-breakdown + multi-cardinal dispatch — the overhead dominates the actual change. Lite mode (per-task prefix `lite:` · alias `direct:`) skips Phase 1–3 and dispatches one named cardinal in Phase 4. Phases 5–8 run normally; CR / ADR / Phase 7 / Phase 8 gates stay in effect.

## Phase elision

| Phase | Default lifecycle | Lite |
|---|---|---|
| 1 Analysis | runs | skipped |
| 2 Design | runs | skipped |
| 3 Design review | runs (user gate) | skipped — direct dispatch from pickup |
| 4 Implementation | runs (cardinal selection by team-lead) | runs (single cardinal, pre-selected) |
| 5 Testing | runs | runs |
| 6 Bug fixing | runs if applicable | runs if applicable |
| 7 SA review | runs | runs |
| 8 User approval | runs | runs |

## Resolution

Stop at first match:

1. Per-task prefix `lite:` or `direct:` on the dispatch line.
2. Issue-sourced — labels `complexity:low` AND exactly one `ginee:role:<cardinal>` AND `local/framework.config.yaml § lifecycle.lite-mode.label-trigger: true`.
3. `local/framework.config.yaml § lifecycle.lite-mode.default: true` (adopter-wide; off by default).
4. Framework default — interactive Phase 1–8.

## Combinability

`lite:` composes freely with every other prefix:

| Composition | Effect |
|---|---|
| `auto: lite: fix typo in CONCEPTS.md § Triage scoring` | auto-mode + lite (Phase 4 → 5 → 7 → delivery handoff) |
| `lite: branch: bump dotnet runtime label` | lite + Mode 1 (branch + PR) |
| `lite: model:fast tweak a YAML comment` | lite + fast-tier model |
| `lite: nocr: change one bullet in CHEATSHEET.md` | lite + skip CR (where CR would otherwise prompt) |

## Forbidden — lite does NOT elide governance

| Gate | Lite-mode behaviour |
|---|---|
| CR-gate (`core/roles/team-lead.md § CR-gate`) | runs — fires if Phase-4 change trips architectural-delta heuristic |
| ADR-gate (`core/roles/solution-architect.md § ADR-gate`) | runs — architectural delta → ADR authorship |
| Phase 7 SA review | runs |
| Phase 8 user approval (interactive) | runs |
| Phase 8 delivery handoff (when composed with `auto:`) | runs |

Lite is an orchestration cost reduction, not a governance bypass.

## When to use

Adopter-visible scope signals:

| Scope | Lite candidate? |
|---|---|
| Typo fix in a single file | yes |
| Single-label tweak (`ginee:ready` → `ginee:in-progress` · `value:high` → `value:medium`) | yes |
| Single-doc-bullet change (one bullet added / removed / rephrased) | yes |
| Touches 2+ files | no — use default lifecycle |
| Introduces a new concept / contract / mockup section | no |
| Spans 2+ cardinals | no |

## Worked examples

**Example 1 — typo.** `lite: fix "lifeycle" → "lifecycle" in CHEATSHEET.md § Phases`. Resolves via tier 1. Skill-runner records `lifecycle: lite`; team-lead dispatches `frontend-engineer` (or whichever cardinal owns docs per `local/bindings.md`) directly into Phase 4. Phase 7 SA review runs; Phase 8 user approval surfaces a one-line diff.

**Example 2 — label tweak.** Issue #200 labelled `complexity:low` + `ginee:role:devops-engineer`; `lifecycle.lite-mode.label-trigger: true` in `local/framework.config.yaml`. Resolves via tier 2. Skill-runner records `lifecycle: lite` + `cardinal: devops-engineer`; team-lead dispatches devops-engineer in Phase 4.

**Example 3 — single-doc-bullet.** `lite: add one bullet to GETTING_STARTED.md § Files installed under .agents/ginee/`. Resolves via tier 1. Same shape as typo case.

**Counter-example — NOT lite.** `lite: add streaming response to /api/deployments`. Touches multiple files + introduces a new wire-contract → lite-mode forbiddens fire. Team-lead surfaces *"`lite:` rejected — change scope exceeds lite triggers; revert to default lifecycle"* + offers `noinit: <task>` continuation under the default flow.

## Action required — none (adopter-side)

**Purely additive.** No `local/` schema change required · no new commands · no adapter re-install. The next dispatch prefixed `lite:` / `direct:` resolves under the new prefix. Adopters wanting `complexity:low` + single-role-label to auto-promote set `lifecycle.lite-mode.label-trigger: true` in `local/framework.config.yaml`. Adopters wanting lite by default set `lifecycle.lite-mode.default: true` (rare — typically a docs-only project).

## Files changed (framework upstream)

| Path | Change |
|---|---|
| `core/process/dispatch.md` | New `### Per-task prefix grammar — lifecycle mode` section; combinability line on the change-governance prefix entry mentions `lite:` / `direct:` |
| `core/skills/ginee-pick-up/SKILL.md` | New `### Step 2.4 — lite-mode detection (all sources)` section; Step 3 hand-off payload extended with `lifecycle: lite` flag |
| `core/templates/framework.config.yaml` | New `# --- Lifecycle mode (lite / default) ---` block with `lifecycle.lite-mode.default` + `label-trigger` keys |
| `docs/CONCEPTS.md` | One-line user-docs co-update under Phased task lifecycle |
| `migrations/lite-mode.md` | This file (**NEW**) |

## Backward compatibility

- **Adopter `local/*`** — no schema change required; `lifecycle.lite-mode` is opt-in.
- **In-flight tasks** — default lifecycle unchanged.
- **Existing prefixes** — `auto:` · `branch:` / `wt:` / `commit:` · `model:` · `notrack:` · `cr:` / `nocr:` / `adr:` / `noadr:` · `fresh:` all preserved; `lite:` composes freely.
- **Closed-task lifecycle records** — NOT retroactively rewritten.
- **Adapter renderings** — none required; spec lives in `core/`.

## Rollback

To revert:

1. Remove the `### Per-task prefix grammar — lifecycle mode` section from `core/process/dispatch.md`; drop `lite:` / `direct:` from the change-governance combinability line.
2. Remove `### Step 2.4 — lite-mode detection (all sources)` from `core/skills/ginee-pick-up/SKILL.md`; drop the `lifecycle: lite` mention from Step 3 inbound payload.
3. Remove the `# --- Lifecycle mode (lite / default) ---` block from `core/templates/framework.config.yaml`.
4. Remove the CONCEPTS.md user-docs line.
5. Delete this migration file.

Framework still functions; every task runs the full Phase 1–8 lifecycle and the "trivial scope dominated by orchestration overhead" failure mode returns.

## Out of scope

- Heavy-role-bypass codification across phases 4–7 — generalized in [#162](https://github.com/kostiantyn-matsebora/ginee/issues/162). Lite mode here is a per-task elision; #162 is a per-phase elision under persistence-artefact checks.
- Auto-promoting TODO-sourced or freeform tasks to lite based on description heuristics — explicit invocation only.
- Compliance / force-class machinery — separate cohort (#135).

## Issue reference

Closes [#153](https://github.com/kostiantyn-matsebora/ginee/issues/153) — *"[Framework Feature] Lite mode — skip Phase 1–3 for trivial scope (lite: / direct: prefix)."*
