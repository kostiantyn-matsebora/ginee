# Migration — PreToolUse SendMessage carry-forward injection

**Target release:** next minor after 2026-05-26.
**Affected adopters:** Claude Code adapter only.
**Closes:** [#144](https://github.com/kostiantyn-matsebora/ginee/issues/144).
**Parent:** [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135) — tactic 8 / Tier 2, Class D force.

## What changed

A new cross-platform PreToolUse hook lives at:

- `adapters/claude/hooks/pre-tool-use-send-message.ps1` — PowerShell (primary).
- `adapters/claude/hooks/pre-tool-use-send-message.sh` — bash port (jq-dependent).

Per-cardinal rule mappings live in `adapters/claude/hooks/carry-forward-rules.yaml` (data-config separation).

When `.claude/settings.json` wires this hook into `hooks.PreToolUse` with matcher `SendMessage`, Claude Code invokes it before every `SendMessage` tool call (the warm-cardinal continuation path per `migrations/warm-reuse-claude-plumbing.md`). The hook reads target + message; if the message's first non-blank line does not begin with `[carry-forward]`, it exits 2 + stderr remediation citing the rule for the target cardinal.

| Target cardinal | Rule (carried-forward verbatim in stderr) |
|---|---|
| `solution-architect` | APPROVE / REJECT / REQUEST-CHANGES only — no code edits |
| `ai-engineer` | lossless rule binds — every existing rule survives byte-for-byte |
| `team-lead` | skill-runner boundary — do not synthesize specialist returns yourself |
| `backend-engineer` / `frontend-engineer` | stay in own tier — cross-domain bugs route via `@team-lead` |
| `qa-engineer` | tighten failing oracle; do not modify product code |
| `devops-engineer` | infra change first; service-owner confirms application reads the new value before merge |
| _unknown_ | generic fallback — stay within your role's surface; never edit outside owned paths |

**Out of scope (explicit):** `Agent` (first dispatch) is not in this hook's matcher set. The carry-forward anchor is a *continuation* contract; first dispatches carry the full role charter via the cardinal-tools-whitelist load (T1 / #137).

## Why

Parent issue #135 § Force taxonomy — Class D (prompt-time anchor) at the per-SendMessage granularity. Warm cardinals reused across 5–10 dispatches in one task drift away from their charter as the conversation grows; the recency-bias loss is the same failure mode as cardinal-charter burial, but at the warm-reuse layer rather than the always-loaded layer.

T8 forces the orchestrator (main-thread LLM) to author each continuation with a single-line rule reminder leading the message. The LLM authors the anchor; the hook gates submission; the warm cardinal receives the anchor as the first thing in its updated context — overriding accumulated drift.

The hook is *gate, not inject* — it blocks a malformed continuation rather than rewriting one. This preserves orchestrator authorship + makes the rule explicit in main-thread reasoning.

## Architecture

| Surface | Owns |
|---|---|
| Hook script (`pre-tool-use-send-message.{ps1,sh}`) | Read payload · match `tool_name == "SendMessage"` · extract `to` + `message` (with field-name fallbacks: `target` / `recipient` / `agent` / `agent_name` · `prompt` / `body` / `content`) · check leading-line anchor · look up rule · exit 2 + stderr on miss |
| `adapters/claude/hooks/carry-forward-rules.yaml` | Per-cardinal rule table. One rule per cardinal; lookup is case-insensitive exact-then-substring. Generic fallback rule when no match |
| `.claude/settings.json § hooks.PreToolUse § matcher SendMessage` | Wires the hook. Synced by `core/scripts/sync-claude-settings.{ps1,sh}` |
| `local/framework.config.yaml § compliance.disabled: [pretooluse-send-message-hook]` | Per-tactic opt-out |

The hook is **pure** over the payload + rules file. No state across invocations. Substring lookup handles the case where the target field carries an agent-id (`solution-architect-3a4f`) rather than the bare name.

## Verification

| Step | Expected |
|---|---|
| Pester — `tests/pre-tool-use-send-message.Tests.ps1` | 13 / 13 pass — parse-clean · 4 pass-through (Bash, Agent, empty, missing target) · 2 anchor-present · 4 anchor-missing per-cardinal · 2 opt-out |
| bats — `tests/pre-tool-use-send-message.bats` | 13 / 13 pass — equivalent surface against the `.sh` port |
| Manual smoke — `echo '{"tool_name":"SendMessage","tool_input":{"to":"ai-engineer","message":"continue"}}' \| pwsh -F adapters/claude/hooks/pre-tool-use-send-message.ps1` | exit 2 + `[ginee:gate] SendMessage continuation missing [carry-forward] anchor` + `Remember: lossless rule binds` on stderr |

## Decisions affected

- **#135 parent playbook** — eighth tactic shipped. Establishes the per-SendMessage anchor pattern (Class D).
- **`migrations/warm-reuse-claude-plumbing.md`** — warm continuations now require the `[carry-forward]` anchor. The drift-advisory mechanism in plan-line shape (`§ Drift advisory`) is the orchestrator-side input; T8 is the gate-side enforcement.
- **`core/process/dispatch.md` § Skill-runner — surface boundary** — anchor authorship is the orchestrator's (team-lead-re-invoked); skill-runner executes the resulting SendMessage verbatim.

## Forward-only

Purely additive — 2 hook scripts + 1 data file + 2 test files + 1 PreToolUse entry (`SendMessage` matcher) in `.claude/settings.json.example`. `core/scripts/sync-claude-settings.{ps1,sh}` adds the SendMessage matcher to its merge set.

## Out of scope

- **Adapter parity.** Warm reuse on Cursor / Copilot / Codex uses different continuation mechanics; the anchor rule is portable but the hook surface is not. Cross-adapter port deferred until warm reuse ships on those adapters.
- **Per-cardinal opt-out.** Single tactic-id `pretooluse-send-message-hook`. Disable per-cardinal by removing the cardinal's row from `carry-forward-rules.yaml` (the hook will fall back to the generic rule).
- **Multi-rule injection.** Each cardinal carries exactly one rule. If multi-rule per cardinal becomes load-bearing, switch to a richer schema (list of rules; picker chooses by phase or sub-task type).
