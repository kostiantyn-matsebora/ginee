# Migration — UserPromptSubmit hook (task-keyword anchor)

**Target release:** next minor after 2026-05-26.
**Affected adopters:** Claude Code adapter only.
**Closes:** [#141](https://github.com/kostiantyn-matsebora/ginee/issues/141).
**Parent:** [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135) — tactic 5 / Tier 2, Class D force.

## What changed

A new cross-platform UserPromptSubmit hook lives at:

- `adapters/claude/hooks/user-prompt-submit.ps1` — PowerShell (primary).
- `adapters/claude/hooks/user-prompt-submit.sh` — bash port (jq-dependent fallback).

Pattern → injection mappings live in `adapters/claude/hooks/keyword-triggers.yaml` (data-config separation).

When `.claude/settings.json` wires this hook into `hooks.UserPromptSubmit`, Claude Code invokes it before each user prompt is delivered to the LLM. The hook reads the prompt, scans for ginee task patterns, and emits stdout JSON whose `hookSpecificOutput.additionalContext` is a sequence of `[ginee:context:<label>]` blocks. Each matched pattern contributes ≤ 28 body lines.

| Trigger pattern | Injection label | Spec excerpt |
|---|---|---|
| `pick up #N` / `pickup #N` / `work on issue #N` / `start on #N` | `ginee-pick-up` | `core/skills/ginee-pick-up/SKILL.md § Procedure` + dispatch-prompt-schema reminder |
| `auto:` (prefix) / `address team-lead with auto` | `automatic-mode` | `core/protocols/automatic-mode.md § Forced-interactive triggers` |
| `branch:` / `wt:` / `commit:` (prefix) | `delivery-modes` | `core/protocols/delivery-modes.md` |
| `/ginee-update` | `ginee-update` | `core/skills/ginee-update/SKILL.md` |
| `triage` | `triage-scoring` | `core/protocols/triage-scoring.md` (ATAM H/M/L) |
| `address review` / `review #N` | `ginee-address-review` | `core/skills/ginee-address-review/SKILL.md` |
| `@<role>` / `dispatch` | `dispatch-prompt-schema` | dispatch-prompt schema + return-schema (self-lint marker) |

## Why

Parent issue #135 § Force taxonomy — Class D (prompt-time anchor) injects the relevant rules at the head of the LLM's context window before deliberation begins. The dominant compliance failure mode for `pick up #N` was burying the GitHub-integration protocol behind unrelated charter loads; for `auto:` it was forced-interactive triggers being forgotten mid-task. T5 puts the operative spec excerpt in front of the LLM at the moment it sees the keyword, eliminating that burial.

Class D is *injection*, not *gate*. The hook never blocks — only prepends. Adopters who type ginee keywords casually (in narrative prose, not as a task command) accept a small additionalContext payload; the cost is bounded by the ≤ 28-line per-trigger ceiling.

## Architecture

| Surface | Owns |
|---|---|
| Hook script (`user-prompt-submit.{ps1,sh}`) | Read payload · resolve repo root · check opt-out · parse triggers YAML · match prompt against patterns (case-insensitive) · emit stdout JSON with `hookSpecificOutput.additionalContext` |
| `adapters/claude/hooks/keyword-triggers.yaml` | Pattern → label → context-body table. Simple block format (`pattern:` / `label:` / `context: \|` heredoc) — hand-parsed; no external YAML dep |
| `.claude/settings.json § hooks.UserPromptSubmit` | Wires the hook command. Synced by `core/scripts/sync-claude-settings.{ps1,sh}` |
| `local/framework.config.yaml § compliance.disabled: [user-prompt-submit-hook]` | Per-tactic opt-out |

The hook is **pure** over the payload + on-disk triggers file — no side effects, no network, no daemon. Bad regex in the YAML is silently skipped (never breaks the prompt).

## Verification

| Step | Expected |
|---|---|
| Pester — `tests/user-prompt-submit.Tests.ps1` | 13 / 13 pass — parse-clean · 4 pass-through · 3 pick-up · 1 auto-mode · 1 compound · 1 dispatch · 2 opt-out |
| bats — `tests/user-prompt-submit.bats` | 11 / 11 pass — equivalent surface against the `.sh` port |
| PSScriptAnalyzer — `Invoke-ScriptAnalyzer adapters/claude/hooks/user-prompt-submit.ps1` | clean |
| shellcheck — `shellcheck adapters/claude/hooks/user-prompt-submit.sh` | clean |
| Manual smoke — `echo '{"hook_event_name":"UserPromptSubmit","prompt":"pick up #141"}' \| pwsh -F adapters/claude/hooks/user-prompt-submit.ps1` | stdout JSON contains `[ginee:context:ginee-pick-up]` |

## Decisions affected

- **#135 parent playbook** — fifth tactic shipped. Establishes the prompt-time injection pattern (Class D); T8 reuses the per-SendMessage variant.
- **`core/skills/ginee-pick-up/SKILL.md`** — full procedure stays canonical; UserPromptSubmit injection is a *recency-floor* reminder, not a replacement for the SKILL.md read.
- **`core/protocols/automatic-mode.md` § Forced-interactive triggers** — surfaced to context every `auto:` invocation.

## Forward-only

Purely additive — adds 3 files under `adapters/claude/hooks/` (`user-prompt-submit.{ps1,sh}` + `keyword-triggers.yaml`), 2 tests under `tests/`, one `UserPromptSubmit` entry in `.claude/settings.json.example`. Adopter `.claude/settings.json` auto-merge via `core/scripts/sync-claude-settings.{ps1,sh}`; re-runs idempotent.

## Out of scope

- **Per-trigger opt-out.** All triggers share the single tactic-id `user-prompt-submit-hook`. Splitting (e.g., disable `auto:` injection only) is deferred until production usage shows asymmetric value.
- **Cross-adapter parity.** Cursor / Copilot / Codex / generic have no UserPromptSubmit equivalent today. Cross-adapter playbooks ship as their tooling matures.
- **Bash hook without `jq`.** Fails open silently when `jq` is absent.
