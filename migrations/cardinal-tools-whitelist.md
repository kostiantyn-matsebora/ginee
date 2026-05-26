# Migration — Cardinal subagent `tools:` whitelist

**Target release:** next minor after 2026-05-26.
**Affected adopters:** Claude Code adapter (primary) · Copilot CLI adapter (shared pointer files).
**Closes:** [#137](https://github.com/kostiantyn-matsebora/ginee/issues/137).
**Parent:** [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135) — 12-tactic compliance playbook (tactic 1 / Tier 1, Class A force).

## What changed

Each of the 7 cardinal pointer subagent files at `adapters/_shared/agents/<role>.md` (copied to `.claude/agents/<role>.md` at install) now declares a tightly-scoped `tools:` whitelist in its YAML frontmatter. Tool requests outside the whitelist are blocked **at the tool-call layer by Claude Code itself** — Class A (action-time gate) per `migrations/change-governance-opt-out.md`'s force-taxonomy reference.

| Cardinal | `tools:` | Class A enforcement |
|---|---|---|
| `solution-architect` | `[Read, Grep, Glob, WebFetch, Bash]` | No `Edit`, no `Write` — SA cannot edit code from a dispatch |
| `team-lead` | `[Read, Grep, Glob, Bash, SendMessage, Edit, Write]` | `Agent` omitted (top-level-only on Claude) |
| `ai-engineer` | `[Read, Edit, Write, Grep, Glob]` | No `Bash` — between-phase doc optimization only |
| `qa-engineer` | `[Read, Edit, Write, Bash, Grep, Glob]` | All present; path scope deferred to T2 |
| `frontend-engineer` | `[Read, Edit, Write, Grep, Glob, Bash]` | All present; Bash pattern scope deferred to T3 |
| `backend-engineer` | `[Read, Edit, Write, Grep, Glob, Bash]` | All present; Bash pattern scope deferred to T3 |
| `devops-engineer` | `[Read, Edit, Write, Grep, Glob, Bash]` | All present; path scope deferred to T2 |

The whitelist is **binary at the tool level**: a tool is either present or absent. Path-scoped restrictions (`Edit(tests/**)`, `Bash(npm:*)`, `Edit(IaC + CI only)`) cannot be expressed in Claude Code's per-subagent `tools:` field — those are enforced by the T2 (#138) `Edit` / `Write` PreToolUse hook and the T3 (#139) `Bash` PreToolUse hook. T1 lands the binary gate first because it has no install-time dependency; T2 + T3 layer on top.

## Why

Per parent issue #135 § Force taxonomy, ginee historically depended on Class H (always-loaded text — LLM voluntary compliance). The compliance budget is finite; under task pressure the LLM drifts toward shortest-path completion and bends rules that have no external enforcement. Tactic 1 converts a pile of historical voluntary-compliance rules into Class A hard gates:

- **`solution-architect` never edits code** (governance role) — was a charter rule; is now impossible.
- **`ai-engineer` never invokes runners** (between-phase only) — was a charter rule; is now impossible.
- The remaining 5 cardinals retain the tools their craft requires; T2 + T3 hooks add the path / pattern dimension.

Force gained is asymmetric — strongest on SA + ai-engineer (full Class A), advisory on the other 5 (Class A on tool presence; T2/T3 fill the gap). The two strongest gates target the two roles whose drift causes the most cross-cardinal damage (SA editing code breaks doc-roles ownership; ai-engineer running commands breaks the between-phase boundary).

## Tool-list rationale (per cardinal)

- **`solution-architect`** — `Read` / `Grep` / `Glob` / `WebFetch` cover all governance + review reads. `Bash` retained for read-only git inspection (`git diff`, `git log`); T3 enforces the command pattern. `Edit` / `Write` omitted — the Class A win.
- **`team-lead`** — `Read` / `Grep` / `Glob` / `Bash` cover orchestration reads + git ops. `SendMessage` lets team-lead resume warm cardinals (per `migrations/warm-reuse-claude-plumbing.md`). `Edit` / `Write` retained for `local/bindings.md` + `local/framework.config.yaml` discovery authorship; T2 enforces the path scope. `Agent` deliberately omitted — Claude Code's `Agent` tool is top-level-only and subagents do not inherit it (per `adapters/claude/install.md § Subagent dispatch limitation`); listing it would be misleading.
- **`ai-engineer`** — `Read` / `Edit` / `Write` / `Grep` / `Glob` cover all doc-shape work. `Bash` omitted — ai-engineer optimizes between phases and never invokes runners; the Class A win.
- **`qa-engineer`** — full read / write / `Bash` set for test authoring + runner invocation. Path scope (`tests/**`) and command scope (test runners only) deferred to T2 + T3.
- **`frontend-engineer`** / **`backend-engineer`** / **`devops-engineer`** — symmetric read / write / `Bash` sets; per-domain path + command scope deferred to T2 + T3.

## Opt-out

Adopters who cannot accept the whitelist (e.g., heavily customised cardinals, transitional installs, edge-case enforcement conflicts):

```yaml
# local/framework.config.yaml
compliance:
  disabled:
    - subagent-tools-whitelist
```

With `subagent-tools-whitelist` disabled, the adopter re-edits their `.claude/agents/<role>.md` files to remove the `tools:` line — restoring unscoped tool access. The framework's `/ginee-update` skill honours the opt-out and skips rewriting the `tools:` field on the next sync. Opt-out is **per tactic** — T2 / T3 / T4 each carry their own tactic-id; opting out of T1 does not affect them.

## Verification

| Step | Expected |
|---|---|
| Dispatch a Phase 2 review to `solution-architect` and ask it to edit `core/process.md` | Claude Code refuses the tool call with `tool not available in this subagent` — verifying Class A enforcement |
| Dispatch to `ai-engineer` and request a `Bash` invocation (e.g., `pwd`) | Same refusal — verifying ai-engineer Class A |
| Dispatch to `qa-engineer` with a test-authoring scope | All tool calls succeed — verifying the 5 non-Class-A cardinals are unbroken |
| Set `compliance.disabled: [subagent-tools-whitelist]` and remove the `tools:` line | All tool calls succeed for every cardinal — verifying opt-out path |

## Decisions affected

- **#135 parent playbook** — first tactic to ship; establishes the per-tactic opt-out shape (`compliance.disabled: [<tactic-id>]`) reused by T2 / T3 / T4 and all later tactics.
- **`adapters/claude/install.md § Subagent dispatch limitation`** — the `Agent`-top-level-only rule informs team-lead's `tools:` omission; previously implicit, now binding on the whitelist shape.
- **`migrations/warm-reuse-claude-plumbing.md`** — `SendMessage` retained on team-lead's whitelist; warm-reuse plumbing unaffected.
- **`core/roles/solution-architect.md` § Review** — "no code edits" rule promoted from charter (Class H) to action-time gate (Class A); charter text is preserved (lossless rule).
- **`core/roles/ai-engineer.md`** — "between-phase only; no Bash" promoted from charter to Class A.

## Forward-only

Purely additive — adds one `tools:` line to each pointer file + one comment block. Adopters on `/ginee-update` get the whitelist on next sync; adopters who skip the update see no behavioural change. No `local/` schema break: `compliance:` is a new key with implicit-default-enabled semantics.

## Out of scope

- **Path-scoped restrictions** (`Edit(tests/**)`, `Bash(npm:*)`, etc.) — deferred to T2 / T3 PreToolUse hooks. Tactic 1 is the binary gate; tactics 2 / 3 are the per-pattern gates.
- **Cross-adapter parity** — Cursor / Codex / generic adapters have different subagent surfaces (or none); their compliance playbooks ship separately if/when their tooling matures.
- **Custom cardinals** — adopters with `local/roles/<role>.md` extensions retain unscoped tool access on the pointer they author. T1 governs the 7 framework cardinals only.
- **Runtime enforcement of the comment-documented intent** (e.g., the team-lead pointer says "Edit intended for `local/bindings.md` only" — that scope is documented but not yet enforced). T2's PreToolUse hook closes this gap.
