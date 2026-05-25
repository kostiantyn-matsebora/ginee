# Migration — Claude adapter warm-reuse plumbing carve-out

**Target release:** next minor after 2026-05-25.
**Affected adopters:** Claude Code adapter only — no behavioural change on other adapters.
**Closes:** [#117](https://github.com/kostiantyn-matsebora/ginee/issues/117).
**Prior:** [`migrations/warm-specialist-reuse.md`](warm-specialist-reuse.md) (D36) · [`migrations/claude-adapter-subagent-dispatch.md`](claude-adapter-subagent-dispatch.md) (D32).

## What changed

D36-warm-specialist-reuse placed the warm registry "in team-lead's own context". On the Claude Code adapter that assignment is **architecturally unrealisable** — team-lead is itself a subagent spawned via the `Agent` tool; its conversation does not survive across dispatches, and subagents do not inherit the `Agent` / `SendMessage` tools they would need to fan out further (D32-claude-adapter-subagent-dispatch). Net effect on every default Claude install: the 15–50 k token / task savings D36 was designed for were silently never realised.

A second, dependent gap — `SendMessage` on Claude Code is gated behind `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (off by default). Even adopters who read D36 and tried to make warm reuse work had no signal that the resume tool was genuinely absent from their session.

This migration:

- **Documents the env-var prerequisite** in `adapters/claude/install.md § Warm specialist reuse` with the `.claude/settings.json` snippet + restart note + claude-code issue references.
- **Refines registry ownership on Claude** — the skill-runner (Claude main thread, durable across the task) holds the warm registry; team-lead reads it back as dispatch input and writes warm-vs-fresh decisions into its plan; the skill-runner executes those decisions verbatim. Decision authority unchanged — only mechanical plumbing moves.
- **Adds a narrow D28-skill-runner-boundary carve-out** on `core/process/dispatch.md` so the warm-reuse plumbing op (registry · team-lead bootstrap · agent-id round-trip) is explicit, not implied by silence.
- **Adds the team-lead warm self-reuse step** — without it team-lead's in-context warm-vs-fresh ledger evaporates between cycles. Skill-runner spawns team-lead with `run_in_background: true` on first dispatch + `SendMessage` to team-lead for every later cycle in the task.
- **Documents known caveats** — raw-`agent-id` resume only (claude-code#42999); first-resume cache miss (claude-code#44724).

## Why

Warm reuse is unconditionally desirable on the cost axis (15–50 k tokens / task saved per `migrations/warm-specialist-reuse.md § Why`). On adapters where the resume tool lives on the same surface as decision authority (single-LLM impersonations · CLI hosts that expose the resume call to the orchestrator) the D36 contract works as written. On Claude the tool-to-authority split (D32) means there is no surface that has *both* the resume tool *and* durable cross-dispatch state — except by routing the plumbing through the skill-runner.

The carve-out preserves *"team-lead in charge all the time"* (D28-skill-runner-boundary). What changes is the bin we put the words *registry · bootstrap · agent-id round-trip* in — they were silently expected to live on team-lead (impossible on Claude) and now live explicitly on the skill-runner (mechanical, not decisional).

## Architecture

| Surface | Owns on Claude |
|---|---|
| skill-runner (main thread; durable across one task) | Warm registry holder · team-lead bootstrap (first dispatch spawns team-lead with `run_in_background: true`; agent-id recorded; every later team-lead dispatch in the task is a `SendMessage`) · specialist agent-id round-trip (capture on first `Agent` call · pass the registry as input to team-lead's next dispatch · execute team-lead's `SendMessage` instructions verbatim) |
| team-lead (subagent; re-invoked each cycle via `SendMessage`) | All warm-vs-fresh decisions · plan-line shape — every dispatch line carries explicit `mode: warm-resume \| fresh-spawn` · on `mode: warm-resume` the line carries `agent-id: <id>` from the registry the skill-runner passed in · forced-fresh triggers applied per `migrations/warm-specialist-reuse.md § Forced-fresh triggers` |

Decision authority is unchanged from D28 / D36 — team-lead still decides every warm-vs-fresh on every dispatch. What the carve-out adds is the explicit mechanical-plumbing op (registry · bootstrap · round-trip) that lets team-lead's decision actually execute on an adapter where its own surface has no `SendMessage` tool.

## Loop

1. **First skill-runner batch** — parse · label / sticky ops · branch ops · `Agent` `run_in_background: true` to spawn team-lead · record team-lead's agent-id · pass parsed task + registry as input.
2. **team-lead authors plan** — for every dispatch line: `role: <cardinal>` · `mode: fresh-spawn` (first dispatch in task; or any forced-fresh trigger fires) OR `mode: warm-resume` + `agent-id: <id>` (from the registry the skill-runner passed in) · standard dispatch contract.
3. **User approves the plan** (Phase 3; or elided per `core/protocols/automatic-mode.md` in `auto:` mode).
4. **skill-runner executes verbatim** — for each plan line: `mode: fresh-spawn` → `Agent` with `run_in_background: true` + capture new agent-id into registry · `mode: warm-resume` → `SendMessage` to the named agent-id with the payload + drift advisory.
5. **skill-runner collects returns + `SendMessage`s team-lead** with returns + updated registry; team-lead synthesises + plans next cycle.
6. **Repeat** 2–5 until phase complete.
7. **Phase 8 acceptance / abandonment** — skill-runner sends `## Phase 8 close — release` to every recorded agent-id (including team-lead's); registry cleared.

The loop is the D32-claude-adapter-subagent-dispatch cycle extended with `mode:` / `agent-id:` plan-line fields + the registry round-trip. Skill-runner's surface is unchanged in kind — still mechanical execution of an approved contract — only the contract now carries warm-vs-fresh routing the skill-runner is mechanically required to honour.

## D28-skill-runner-boundary carve-out (narrow)

| Op | Surface |
|---|---|
| Warm registry holding · team-lead bootstrap (background-spawn + agent-id capture) · agent-id round-trip · verbatim execution of team-lead's `mode: warm-resume \| fresh-spawn` plan lines | skill-runner (allowed — **mechanical plumbing only**) |
| Warm-vs-fresh decision · `mode:` field on plan lines · forced-fresh-trigger evaluation · registry interpretation beyond pass-through | **team-lead** (forbidden in skill-runner) |

The carve-out is **mechanical** — skill-runner never reads a plan line's `mode:` field and second-guesses it; never picks a registered agent-id when team-lead omitted the field; never spawns or releases an agent outside an approved plan-line. The registry is a data carrier; team-lead is the authority over its content.

## Env-var prerequisite

`SendMessage` on Claude Code is gated behind `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` at the time of this writing (references: `anthropics/claude-code#36196` · `#42737` · `#35240`). Without the flag the tool is genuinely absent from the session and every `SendMessage` call resolves to a fresh-spawn fallback — defeating the entire D36 contract on Claude.

`adapters/claude/install.md § Warm specialist reuse` carries the `.claude/settings.json` snippet + restart note as a **Prerequisite** subsection so adopters set the flag at install time. Adopters who cannot enable the flag (organisational policy, etc.) set `local/framework.config.yaml § warm-reuse.enabled: false` and accept the fresh-spawn cost; team-lead falls through to the D36 capability-less-adapter behaviour transparently.

## Known caveats (documented in `adapters/claude/install.md § Warm specialist reuse § Known caveats`)

| Caveat | Reference |
|---|---|
| Friendly-name `SendMessage` resume fails — raw `agent-id` only | `anthropics/claude-code#42999` |
| First resume incurs a cache miss (the resumed agent reads its history afresh) | `anthropics/claude-code#44724` |

Both are upstream issues outside ginee's control. The registry stores raw agent-ids exclusively to sidestep the first; the first-resume cache miss is acceptable cost (a single full-context read amortised across the warm-reuse savings for the rest of the task).

## Decisions affected

- **D28-skill-runner-boundary** — extended with a narrow carve-out for warm-reuse plumbing on adapters where team-lead lacks the resume tool. Skill-runner surface gains *mechanical plumbing only*; decision authority unchanged.
- **D32-claude-adapter-subagent-dispatch** — extended: the verbatim-execution cycle now carries `mode:` / `agent-id:` plan-line fields routed through the skill-runner registry.
- **D36-warm-specialist-reuse** — Claude adapter implications corrected: registry ownership is *adapter-specific* — team-lead-side on adapters where team-lead has the resume tool; skill-runner-side on Claude. Contract semantics unchanged; surface assignment refined.
- **D35-process-md-load-topology** — unchanged. The carve-out lives in `core/process/dispatch.md` (team-lead + skill-runner main thread); other cardinals never load it.

## Opt-out

Adopters who cannot or do not want to enable the env var:

```yaml
# local/framework.config.yaml
warm-reuse:
  enabled: false  # default: true on Claude when SendMessage is available
```

With `enabled: false`, team-lead skips the warm-resume code path entirely + every dispatch fresh-spawns. The fresh-spawn behaviour is identical to capability-less adapters (D36 fallback); no behavioural change vs pre-D36.

## Forward-only

Purely additive. No `local/` schema change beyond the existing `warm-reuse.enabled` override (D36). No installer change. No script change. Adopters on Claude who enable the env var get the warm-reuse savings on next dispatch; adopters who skip the env var see no behavioural change vs pre-D43 (warm reuse silently fell back to fresh-spawn before; now it does so explicitly with a discovery hint).

## Out of scope

- **Auto-detection of `SendMessage` availability** at dispatch time. The framework documents the env-var prerequisite; the adopter sets it once. If the flag was left off, team-lead surfaces the warm-resume plan line and the skill-runner's `SendMessage` call fails — at which point team-lead applies the existing "adapter cannot deliver SendMessage" forced-fresh trigger transparently. This degrades to fresh-spawn safely without an upfront probe.
- **Cross-adapter warm-reuse plumbing.** Other adapters (Cursor · Copilot CLI · Codex · generic) inherit the original D36 contract — team-lead-side registry. They are unaffected by D43.
- **Cross-session warm reuse** — registry is in-process; session restart resets it. Sub-issue dispatch (`migrations/sub-issue-dispatch.md`) bridges the cross-session gap via persistent GH state, not the warm registry.
- **Capability ranking** — if multiple resume mechanisms become available on Claude in future, D43 stays adapter-specific to *Claude with SendMessage*; new mechanisms get their own migration.
