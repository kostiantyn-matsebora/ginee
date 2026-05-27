# Migration — `ginee-iterate` skill: route review-cycle replies to warm cardinal

**Target release:** next minor.
**Affected adopters:** every adopter — opt-in via warm-reuse-capable adapter; no breaking change on no-resume adapters.
**Closes:** [#154](https://github.com/kostiantyn-matsebora/ginee/issues/154).
**Parent:** [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135) — tactic 15 / Tier 2, Class B (skill-time enforcement).
**Prior:** [`migrations/warm-specialist-reuse.md`](warm-specialist-reuse.md) · [`migrations/warm-reuse-claude-plumbing.md`](warm-reuse-claude-plumbing.md) · [`migrations/warm-cardinal-default.md`](warm-cardinal-default.md).

## What changed

New skill `core/skills/ginee-iterate/SKILL.md` per AgentSkills standard. Every review-cycle user reply on a live cardinal task `SendMessage`s the warm agent verbatim; main thread = relay only. Closes a drift mode where skill-runner short-circuits the warm cardinal and edits directly because each individual fix looks small — over 10–20 cycles, main thread context grows to 1M+ tokens; warm cardinal stays unused; warm-reuse savings per `migrations/warm-specialist-reuse.md § Why` go unrealised.

Sibling tactic to `migrations/warm-cardinal-default.md` (T11) — that migration codifies warm-cardinal as the default execution path; this skill makes review-cycle iteration honour the path. Companion PreToolUse hook with registry-lookup precondition deferred to T11 sibling work per issue #147.

## Why

Pre-iterate cycle on a frontend mockup-review task:

| Cycle item | Pre-iterate | Post-iterate |
|---|---|---|
| User reply "fix the button" | Main thread `Edit` directly | `SendMessage` to warm `frontend-engineer` |
| Main-thread token growth per cycle | +5–10 k (re-reads file context) | +0 (relay only) |
| Warm cardinal context reuse | Discarded — fresh load every cycle | Preserved across cycle |
| 10-cycle aggregate | 50–100 k main-thread tokens · 0 warm reuse | <5 k main-thread · full warm reuse |

Review cycles are the surface where the small-task heuristic fails worst — each reply individually looks like a trivial edit, but the aggregate over a multi-reply cycle defeats the warm-reuse contract D36 / D43 / T11 stack.

## Architecture

| Surface | Owns |
|---|---|
| Skill-runner (Claude main thread; equivalent on each adapter) | Relay execution — registry read · `SendMessage` verbatim · return pass-through · hand-back trigger detection. Mechanical-plumbing carve-out per `core/process/dispatch.md § Skill-runner — surface boundary § Claude Code carve-out` extends to this skill's body |
| Team-lead | Governance — routing decision when multi-match / zero-match · stop-state re-decision on any return re-entry trigger · cross-cardinal synthesis · plan re-derivation. Reached via hand-back per `core/process/dispatch.md § Skill-runner — surface boundary § Hand-back rule` |
| Warm cardinal | Stays warm across the cycle; context-economy savings per `migrations/warm-specialist-reuse.md § Why` accrue across replies |

Decision authority unchanged — team-lead still owns routing; skill-runner adds a verbatim-relay path that honours the warm-vs-fresh decision team-lead wrote into the prior plan line.

## Loop

1. **Detect** — read warm registry (`adapters/claude/install.md § Warm specialist reuse § Architecture`); identify cardinal whose `phase-participation:` window covers in-flight phase AND owned file domain (`local/bindings.md § Source-of-truth ownership`) covers reply surface.
2. **Forward** — `SendMessage` user reply byte-verbatim to recorded `agent-id` (raw id only per `adapters/claude/install.md § Warm specialist reuse § Known caveats`); carry-forward anchor per `adapters/claude/hooks/carry-forward-rules.yaml`.
3. **Pass-through** — surface cardinal return unsynthesized; format-only advisory per `core/templates/phase-report.md § Orchestrator behaviour` on self-lint miss.
4. **Hand-back** — dispatch `@team-lead` when return carries `## Open issues` non-empty · `## Hand-off` set · `Status: In-progress` / `Status: Blocked` · cross-domain bug · reply surface outside warm cardinal's domain.

Loop repeats per reply until acceptance signal (cardinal `Status: Done` + user accept) → skill exits → team-lead resumes for Phase 8 close. Worked example: 5-reply frontend cycle — `core/skills/ginee-iterate/SKILL.md § Worked example`.

## Decisions affected

- **`core/process/dispatch.md § Skill-runner — surface boundary`** — extended: the relay path joins the existing mechanical-plumbing carve-out (warm-reuse plumbing per `migrations/warm-reuse-claude-plumbing.md`). Skill-runner gains verbatim `SendMessage` relay; decision authority unchanged.
- **`migrations/warm-specialist-reuse.md § Forced-fresh triggers`** — unchanged. Stale `agent-id` · `SendMessage` failure · cross-task boundary continue to force fresh per the existing trigger table; this skill consumes those triggers via hand-back, without extending the table.
- **`migrations/warm-reuse-claude-plumbing.md § Architecture`** — unchanged. Registry ownership stays adapter-specific (skill-runner-side on Claude; team-lead-side on resume-capable adapters); this skill reads the registry; team-lead writes it.
- **`migrations/warm-cardinal-default.md`** — sibling tactic; this skill makes review-cycle iteration honour the warm-default path that T11 codified. Companion PreToolUse hook with registry-lookup precondition deferred to T11 sibling work.
- **`core/templates/phase-report.md § Orchestrator behaviour`** — unchanged. Pass-through honours the existing advisory-not-restructure contract.
- **Adapter `install.md` files** — no per-adapter step added; existing `ginee-*` glob (`adapters/claude/install.md § Steps § 2` · `adapters/copilot-cli/install.md § Steps § 3` · `adapters/agents-md/install.md § Steps § 3` · `adapters/generic/install.md § Steps § 3`) covers the new skill on next `/ginee-update`.
- **Statusline writer for `warm: ?` field** (`adapters/claude/statusline.ps1` placeholder per `adapters/claude/install.md § Statusline`) — unaffected by this migration; writer is deferred T11 sibling work per the parent playbook.

## Adapter implications

| Adapter | Behaviour |
|---|---|
| `claude` (with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) | Full skill — `SendMessage` resume per `adapters/claude/install.md § Warm specialist reuse` |
| `claude` (env var off) | Degrades to fresh-spawn per `migrations/warm-specialist-reuse.md § Forced-fresh triggers § Adapter cannot deliver SendMessage`; skill hands back to team-lead transparently |
| `copilot-cli` | Cites adapter's resume mechanism by reference; degrades to fresh-spawn on no-resume host per the same trigger |
| `agents-md` (Cursor · Codex · Gemini · Goose) | Host-defined; same degrade path. Per-adapter compliance playbooks for each maturing client land separately per `CLAUDE.md § Framework authoring — context economy` (per-adapter classification subsection) |
| `generic` | No resume mechanism — degrades to fresh-spawn; same trigger |

Skill body cites the adapter's resume mechanism by reference (not by name); the framework MUST NOT pick a single non-Claude `SendMessage` equivalent.

## Forward-only

Purely additive. No `local/` schema change beyond the optional opt-out flag. No installer change. No script change. Adopters who do nothing on upgrade get the skill on next `/ginee-update`; review-cycle iteration on warm-reuse-capable adapters auto-honours the relay path.

## Opt-out

```yaml
# local/framework.config.yaml
compliance:
  disabled:
    - ginee-iterate-skill
```

With the flag set, the skill exits early on activation and the main thread retains pre-iterate behaviour (direct `Edit` permitted; warm cardinal cold-cycled). Bypass per call — `SKIP_GINEE_COMPLIANCE=1`.

## Out of scope

- **PreToolUse hook with registry-lookup precondition** — deferred T11 sibling work per parent issue #147. This skill enforces the relay path at skill-time (Class B); the hook would enforce at tool-call-time (Class A) for cases where the skill is bypassed.
- **Statusline writer for `warm: ?` / `iterating: @<role>`** — placeholder remains intentional per `adapters/claude/install.md § Statusline`; writer is deferred T11 sibling work.
- **Cross-task relay** — task close clears the registry per `migrations/warm-specialist-reuse.md § Reuse contract`; next task is a fresh pickup via `ginee-pick-up`.
- **Cross-session relay** — session restart wipes the registry per `migrations/warm-reuse-claude-plumbing.md § Out of scope`.
- **Auto-detection of acceptance signal beyond `Status: Done` + user-acceptance keyword** — the skill exits on explicit signal; ambiguous returns hand back to team-lead per the re-entry trigger table.
- **Adapter-portability shim for `SendMessage` equivalent on non-Claude adapters** — adopters on no-resume hosts get fresh-spawn fallback per the existing trigger; no shim required.
- **Routing on multi-match / zero-match** — hand-back to team-lead; the skill MUST NOT pick a default per `core/process/dispatch.md § Skill-runner — surface boundary`.
