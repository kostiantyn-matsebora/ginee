# Migration — Change-governance gating + opt-out

**Target release:** next minor after 2026-05-25.
**Affected adopters:** every adopter on every adapter — default-preserving. Adopters who do nothing on upgrade see no behavioural change; existing CR / ADR authorship continues unchanged.
**Closes:** [#121](https://github.com/kostiantyn-matsebora/ginee/issues/121).
**Spec:** `core/roles/team-lead.md § CR-gate` · `core/roles/solution-architect.md § Architecture-doc freeze + change governance § ADR-gate` · `core/process.md § Change governance — pre-authorship gating`.

## What changed

Pre-cutover, CR / ADR authorship was unconditional once team-lead / SA judged the trigger condition met. Adopters who file requirement-scope changes via GitHub issues (where the issue body IS the requirement record) had no way to suppress redundant CR drafting; adopters making code changes with no architectural delta had no way to suppress redundant ADR drafting. Result — drift toward governance theatre on adopter projects that don't need a separate CR / ADR record per task.

This migration adds a pre-authorship intercept gate on both surfaces:

- **CR-gate** — `team-lead` runs before drafting any CR.
- **ADR-gate** — `solution-architect` runs before drafting any ADR.

Both gates resolve against `local/framework.config.yaml § change-governance` + the per-task prefix grammar (`core/process/dispatch.md § Task model § Per-task prefix grammar — change governance`).

## Why

- **Issue-as-CR.** Adopters whose source-of-truth for requirement scope is GitHub issues already record the change in the issue body. A CR drafted alongside is redundant — same content twice.
- **Code-touch-no-architectural-delta.** A backend fix that doesn't touch component boundaries / wire contracts / NFRs / invariants / stack does not need an ADR; the existing architecture doc still describes the system. An ADR drafted "because we changed code" is governance noise.
- **Adopter heterogeneity.** Some projects need every change recorded (regulated environments). Some never need separate records (small teams, issue-first workflows). The framework supports both by making the gate adopter-controlled.

## Five-key gate (`local/framework.config.yaml`)

```yaml
change-governance:
  cr:
    enabled: true                       # set false → skip CR authorship; skip-reason: config-disabled
    skip-when-issue-source: true        # issue-sourced task → skip CR; skip-reason: issue-source-skip
  adr:
    enabled: true                       # set false → skip ADR authorship; skip-reason: config-disabled
    require-architectural-delta: true   # no architectural-delta heuristic match → skip ADR; skip-reason: no-architectural-delta
  prompt-before-create: non-trivial     # always | never | non-trivial
```

**Defaults preserve pre-cutover behaviour** on most surfaces — `cr.enabled: true` · `adr.enabled: true`. The one exception is `cr.skip-when-issue-source: true`, which is the documented owner default per issue #121 (issues already record requirement scope; redundant CR drafting suppressed). Adopters who want pre-cutover behaviour set `skip-when-issue-source: false`.

## Per-task prefix grammar

Resolved BEFORE config (precedence: prefix > config > default):

| Prefix | Effect |
|---|---|
| `cr:` | Force CR authorship (overrides config). |
| `nocr:` | Skip CR authorship (overrides config). Logged `skip-reason: prefix-override`. |
| `adr:` | Force ADR authorship (overrides config). |
| `noadr:` | Skip ADR authorship (overrides config). Logged `skip-reason: prefix-override`. |

**Combinability.** Combine freely with `auto:` · `branch:` / `wt:` / `commit:` · `model:<tier>` · `notrack:` · `fresh:`. Within change-governance prefixes: explicit-force (`cr:` / `adr:`) > explicit-skip (`nocr:` / `noadr:`).

## Non-trivial heuristic (defines `prompt-before-create: non-trivial`)

Fires when EITHER:

- Proposal touches ≥ 2 architectural-delta triggers (component boundaries · wire contracts · NFR-bearing claims · architecture invariants · stack / topology / infrastructure — full list in `core/roles/solution-architect.md § ADR-gate`), OR
- `local/requirements.md` register-diff is non-empty (any FR / NFR / Constraint added · modified · retired in the current task).

## Skip-reason logging

Logged under `## Decisions made` in the phase-report when the gate skips authorship. Fixed enum (no free-form):

| Surface | Enum |
|---|---|
| CR | `config-disabled | issue-source-skip | prefix-override | user-declined` |
| ADR | `config-disabled | no-architectural-delta | prefix-override | user-declined` |

`user-declined` fires when `prompt-before-create: always` / `non-trivial` triggered the forced-interactive prompt and the user said no.

## Worked examples

### Example 1 — Issue-sourced task → CR skipped automatically

Adopter picks up issue #42 (*"Bump retry policy to exponential backoff"*) — a requirement scope change. Pre-cutover team-lead drafted a CR; post-cutover the gate fires:

- Source = issue → issue-sourced flag set on task.
- `change-governance.cr.skip-when-issue-source: true` (default).
- Gate branch 3 matches → skip CR.
- Phase-report `## Decisions made` records `CR skipped — skip-reason: issue-source-skip`.

The issue body remains the requirement record; the PR `Closes #42` preserves traceability.

### Example 2 — Code-touch with no architectural-delta → ADR skipped automatically

Adopter dispatches *"refactor the auth middleware's logging format"* — same component boundary, same wire contract, same NFRs, same stack. Pre-cutover SA might draft an ADR explaining the refactor; post-cutover the gate fires:

- `change-governance.adr.require-architectural-delta: true` (default).
- No delta trigger matches (logging format change touches none of: component boundaries · wire contracts · NFRs · invariants · stack).
- Gate branch 3 matches → skip ADR.
- Phase-report `## Decisions made` records `ADR skipped — skip-reason: no-architectural-delta`.

### Example 3 — Per-task `cr:` forces creation when `enabled: false`

Adopter has CR authorship disabled repo-wide (`change-governance.cr.enabled: false` — they record scope outside ginee). A user dispatches *"cr: deprecate the legacy /v1 endpoints"* expecting a one-off CR for audit purposes:

- Task prefix `cr:` resolved first (precedence: prefix > config).
- Gate branch 4 matches (prefix `cr:`) → draft CR silently.
- Phase-report records the new CR path under `## Files touched`.

The repo-wide opt-out is preserved; the one-off override lands the artefact for this task only.

## Files touched (this migration)

| File | Change |
|---|---|
| `core/templates/framework.config.yaml` | New `change-governance:` block (5 keys; defaults documented). |
| `core/roles/team-lead.md` | New `§ CR-gate` subsection under `§ What you author` — 6-branch decision table + non-trivial heuristic pointer + skip-reason pointer. |
| `core/roles/team-lead.details.md` | New `§ CR authoring` — skip-reason enum + phase-report logging shape. |
| `core/roles/solution-architect.md` | New `§ ADR-gate` subsection under `§ Architecture-doc freeze + change governance` — 6-branch decision table + delta-trigger list + SA-judgment-retained cases. |
| `core/roles/solution-architect.details.md` | New `§ ADR-gate` — non-trivial heuristic + skip-reason enum + logging shape. |
| `core/process.md` | New top-level `§ Change governance — pre-authorship gating` — gate-table pointer + scope. |
| `core/process/dispatch.md` | New `### Per-task prefix grammar — change governance` under `§ Task model` — prefix table + combinability rules. |
| `core/automatic-mode.md` | New row under `§ Forced-interactive triggers` — gate prompt branch fires forced-interactive even under `auto:`. |
| `migrations/change-governance-opt-out.md` | NEW — this file. |
| `docs/CONCEPTS.md` | New adopter-facing `§ Change governance gating + opt-out` section. |
| `docs/CHEATSHEET.md` | New `§ Change governance` mini-section — YAML block + prefix grammar + quick table. |
| `PLAN.md` | New D45 entry. |
| `CLAUDE.md` | New D45 row in the locked decisions table; heading updated D1–D45. |

## Action required

**Nothing required if pre-cutover behaviour suits your project** — except one named default change:

- **`cr.skip-when-issue-source: true`** is the new default per issue #121. Adopters who want CRs drafted on issue-sourced tasks (pre-cutover behaviour) set `cr.skip-when-issue-source: false`.

All other defaults preserve pre-cutover behaviour:

- `cr.enabled: true` · `adr.enabled: true` — CR / ADR authorship continues.
- `adr.require-architectural-delta: true` — pre-cutover SA already gated ADR authorship on architectural delta; the gate makes this explicit.
- `prompt-before-create: non-trivial` — pre-cutover surface-decision was implicit; the gate codifies it.

**To opt out of redundant CR / ADR authorship beyond defaults**, set:

```yaml
change-governance:
  cr:
    enabled: false       # never draft CRs (e.g. all scope changes recorded in issues)
  adr:
    enabled: false       # never draft ADRs (e.g. small project with no architectural-decision log)
```

**To force prompt on every authorship**, set:

```yaml
change-governance:
  prompt-before-create: always
```

## Out of scope (v1)

- **Retroactive sweep.** Forward-only. Existing CRs / ADRs are not deleted on opt-out; new authorship is gated only on go-forward dispatches.
- **Per-issue / per-PR override beyond the prefix.** The `cr:` / `nocr:` / `adr:` / `noadr:` prefixes cover per-task overrides. Per-repository labels for "force CR on this issue" are out of scope.
- **CR / ADR template selection at gate time.** The gate decides authorship yes-or-no; template content is unchanged (`team-lead.details.md § CR template` · `solution-architect.details.md § ADR template`).
- **Multi-CR / multi-ADR per task.** Same as pre-cutover — one CR per requirement-change event, one ADR per architectural decision. The gate adjudicates the first authorship event; downstream events flow through the same gate independently.
- **Automatic skip-reason inference for borderline cases.** If the heuristic doesn't fire but the change feels material, the team-lead / SA judgment cases (kernel § SA-judgment-retained cases) override; the gate yields to specialist judgment.

## Backwards compatibility

Purely additive on the adopter-action surface. `local/framework.config.yaml` schema gains the `change-governance:` block — all keys optional; all default to pre-cutover behaviour (modulo the one named default change above). Installer flags unchanged. Skill triggers unchanged. No `core/` rule walked back. Forward-only.
