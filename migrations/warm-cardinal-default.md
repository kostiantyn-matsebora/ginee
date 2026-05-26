# Migration — Main-thread tool restriction + warm-cardinal-default + per-issue registry expiry

**Target release:** next minor after 2026-05-26.
**Affected adopters:** Claude Code adapter only.
**Closes:** [#147](https://github.com/kostiantyn-matsebora/ginee/issues/147).
**Parent:** [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135) — tactic 11 / Tier 3, Class A + F integrated.
**Prior:** [`migrations/warm-specialist-reuse.md`](warm-specialist-reuse.md) (D36) · [`migrations/warm-reuse-claude-plumbing.md`](warm-reuse-claude-plumbing.md) (D43) · [`migrations/cardinal-tools-whitelist.md`](cardinal-tools-whitelist.md) (T1) · [`migrations/pretooluse-edit-hook.md`](pretooluse-edit-hook.md) (T2).

## What changed

Three coupled changes make off-context-with-warm-continuity the **default** execution path on the Claude adapter:

1. **Main-thread permission lockdown** — `.claude/settings.json § permissions.deny` blocks framework-side edits from the main thread. Real work routes through cardinals via `Agent` / `SendMessage`.
2. **Warm-cardinal-default** — combined with T1 (`tools:` whitelist) + T2 / T3 / T8 (PreToolUse hooks) → every cardinal action passes through hook gauntlet + drift-detection + tool-scope restriction. No new mechanism; this migration codifies the path as default-on.
3. **Per-issue warm registry with dispatch-count expiry** — extends D43 plumbing with a `local/framework.config.yaml § warm-reuse.dispatch-cap` soft cap (default 15). When a warm agent's dispatch count exceeds the cap, team-lead force-fresh + emits a **summary handoff** so the new agent inherits prior decisions instead of starting blind.

## Main-thread permission lockdown

Add to the adopter `.claude/settings.json`:

```json
{
  "permissions": {
    "deny": [
      "Edit(.agents/ginee/core/**)",
      "Edit(.agents/ginee/adapters/**)",
      "Edit(.agents/ginee/extras/**)",
      "Write(.agents/ginee/core/**)",
      "Write(.agents/ginee/adapters/**)",
      "Write(.agents/ginee/extras/**)",
      "MultiEdit(.agents/ginee/core/**)",
      "MultiEdit(.agents/ginee/adapters/**)",
      "MultiEdit(.agents/ginee/extras/**)",
      "Bash(rm -rf:*)",
      "Bash(git push --force:*)",
      "Bash(git push -f:*)",
      "Bash(git reset --hard:*)"
    ]
  }
}
```

Allowed main-thread surface (no allow-list needed — anything not in `deny` is permitted by Claude Code default): `Read` · `Grep` · `Glob` · `Bash(<read-only>)` · `Agent` (dispatch cardinals) · `SendMessage` (continue warm cardinals) · `Edit` / `Write` on **adopter** code (everything outside `.agents/ginee/`).

The deny rules are **framework-scoped only** — adopter project code (their own `core/`, `src/`, etc.) is untouched. The intent is that ginee-framework changes route through cardinals (so T2 / T6 hooks fire); adopter-code changes route through cardinals when they have governance weight (Phase 4 backend / frontend dispatch) and through the main thread for trivial tweaks (typo fixes in adopter docs).

Auto-wired via the existing `core/scripts/sync-claude-settings.{ps1,sh}` — extended in this migration to seed `permissions.deny` if absent; adopters who already set a `deny` list see their entries preserved + the ginee entries appended.

**Opt-out:** `local/framework.config.yaml § compliance.disabled: [main-thread-permissions]`. The installer skips the `permissions` sync entirely when this tactic-id is listed.

## Warm-cardinal-default

This migration ships **no new code** for the warm-default behaviour. It codifies the path that T1 + T2 + T3 + T8 + D43 already make available as the *recommended adopter default*. Adopters who:

- Set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (D43 prerequisite),
- Run `/ginee-update` (lands T1 `tools:` whitelist on cardinals + T2 / T3 / T8 hooks),
- Apply this migration (lands the main-thread permission lockdown),

land in the off-context-with-warm-continuity flow per the parent playbook §  *"Strongest pattern available without programmatic supervisor"*. No further opt-in required.

## Per-issue warm registry — dispatch-count expiry

Extends `migrations/warm-specialist-reuse.md § Forced-fresh triggers` with one row:

| Trigger | Why |
|---|---|
| Dispatch count for the warm agent exceeds the soft cap (`local/framework.config.yaml § warm-reuse.dispatch-cap`; default 15) | Drift accumulates over many dispatches in one task. Forcing fresh + summary-handoff drops drift while preserving prior decisions. |

Resolution chain (stop at first match):

1. Explicit `fresh:` prefix on the dispatch (per D36 / `core/process/dispatch.md § Per-task prefix grammar`).
2. Hard-fresh trigger (worktree mismatch · `local/*` drift · prior `Status: Blocked` resolved externally · resume failure).
3. Dispatch count > `warm-reuse.dispatch-cap` (this migration; soft cap; emits summary-handoff).
4. Warm-resume per D43 plumbing.

## Summary-handoff payload format

When the dispatch-cap trigger fires, team-lead emits the *normal* dispatch payload per `core/protocols/dispatch-prompt-schema.md` PLUS a `## Carry-forward summary` section at the top. The new section is dispatch-prompt-schema-compliant — same self-lint rules, ≤ 200 words, anchored cites.

```
## Carry-forward summary

Prior warm cardinal handed back after <N> dispatches in this task; force-fresh per
warm-reuse.dispatch-cap (>= 15). Key decisions to inherit:

- <decision-1> — <cite: ADR-NNNN-slug / FR-NN-slug / mockup §X>
- <decision-2> — <cite>
- <decision-3> — <cite>

Open work items:

- <item-1> — <status · file · expected next step>
- <item-2> — <status>

Re-read before proceeding: <local/index/<entry>.yaml + 1–2 raw paths max>.
```

Empty case: `(no prior decisions — first dispatch of this role)`.

Self-lint per `core/protocols/dispatch-prompt-schema.md § Self-lint` applies; `## Carry-forward summary` counts as a content section for the marker check. Body ≤ 200 words / ≤ 10 bullets total across all sub-sections. Cites mandatory — preserves the lossless rule across cardinal generations.

**Forbidden in carry-forward summary** — verbatim copies of the prior cardinal's `## Files touched` / `## Verification log` tables (those live in git history; the new cardinal re-derives). Restate **decisions**, not file lists.

## Architecture

| Surface | Owns |
|---|---|
| `.claude/settings.json § permissions` | Main-thread lockdown rules (synced by `core/scripts/sync-claude-settings.{ps1,sh}`) |
| `local/framework.config.yaml § warm-reuse.dispatch-cap` | Soft cap value (default 15); adopter override |
| Skill-runner (Claude main thread) | Warm registry holder per D43; tracks `(role, agent-id, dispatch-count)`; surfaces the count to team-lead on every cycle |
| Team-lead (re-invoked) | Reads dispatch count from registry input; applies the resolution chain; emits `## Carry-forward summary` when force-fresh fires |
| `local/framework.config.yaml § compliance.disabled: [main-thread-permissions]` | Per-tactic opt-out for the permission lockdown |

The dispatch-count tracking is plumbing-only — skill-runner reads it from the registry and passes it as a numeric input to team-lead. Team-lead writes the warm-vs-fresh decision (including the cap-triggered force-fresh) into the next plan line; skill-runner executes verbatim. Decision authority unchanged from D28 / D43.

## Verification

| Step | Expected |
|---|---|
| Manual diff — `core/templates/framework.config.yaml` | New `warm-reuse:` block with `dispatch-cap: 15` example (commented) |
| Manual diff — `migrations/warm-specialist-reuse.md § Forced-fresh triggers` | New row citing this migration |
| Pester — `tests/warm-cardinal-default.Tests.ps1` | Schema-marker checks against this migration spec + framework.config.yaml + warm-specialist-reuse.md |
| bats — `tests/warm-cardinal-default.bats` | Equivalent shape |
| Context-economy gate — `pwsh scripts/context-economy-check.ps1 -BaseRef origin/main` | `pass` (this migration spec is the only > 50-line surface; `Optimized-By` trailer required on the bundled commit) |

## Decisions affected

- **Parent playbook #135** — eleventh tactic shipped; Tier 3 progress.
- **D36 / `migrations/warm-specialist-reuse.md` § Forced-fresh triggers** — extended with the dispatch-count trigger.
- **D43 / `migrations/warm-reuse-claude-plumbing.md`** — registry payload now carries a numeric dispatch-count; skill-runner reads + passes through.
- **`core/protocols/dispatch-prompt-schema.md`** — `## Carry-forward summary` section is a recognised optional input alongside the existing `## Carry-forward` rule-anchor line (different scope — rule-anchor is single-line; summary is multi-line on cap trigger).
- **`core/protocols/github-integration.md § Sub-issue dispatch`** — unchanged. The 4-tier resolution chain (notrack: → `ginee:track:off` → config → default) honours sub-issue-mode regardless of warm-vs-fresh — team-lead emits a fresh sub-issue per cardinal dispatch in either case.

## Forward-only

Purely additive — adopters who do not enable the env var (D43 prerequisite) see no behavioural change. Adopters who do warm-reuse get the dispatch-cap protection automatically. Adopters who customised their `.claude/settings.json § permissions.deny` keep their entries; ginee entries append idempotently.

## Out of scope

- **Cross-task warm reuse** — task boundary still wipes the registry per D36.
- **Cross-session warm reuse** — session restart still wipes registry per D43.
- **Hard cap (kill the agent)** — only soft cap (force-fresh + summary handoff). A hard cap would mean dropping decisions; this contradicts the summary-handoff design.
- **Adaptive cap based on cardinal kind** — single value across all cardinals. Per-role caps deferred until production usage shows asymmetric drift.
- **Statusline integration of dispatch count** — T4 statusline already exposes `dispatches: N/M`; that surface is sufficient.
