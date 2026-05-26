# Migration — Stop hook (refuse turn-end on incomplete work)

**Target release:** next minor after 2026-05-26.
**Affected adopters:** Claude Code adapter only.
**Closes:** [#143](https://github.com/kostiantyn-matsebora/ginee/issues/143).
**Parent:** [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135) — tactic 7 / Tier 2, Class C force.

## What changed

A new cross-platform Stop hook lives at:

- `adapters/claude/hooks/stop.ps1` — PowerShell (primary).
- `adapters/claude/hooks/stop.sh` — bash port (jq-dependent).

When `.claude/settings.json` wires this hook into `hooks.Stop`, Claude Code invokes it when the LLM is about to end its turn. The hook reads the conversation transcript (via `transcript` inline or `transcript_path`) and exits 2 + stderr remediation when *any* of three block conditions fire. Exit 2 forces the LLM to continue rather than end.

| # | Block condition | Stderr remediation |
|---|---|---|
| 1 | Last specialist return (detected by `## Files touched` / `## Decisions made` / etc. headers) missing the literal `<!-- self-lint: pass -->` tail | Acknowledge as advisory in main thread; re-running passes the gate (never re-dispatch for format alone — `core/process.md § Reporting`) |
| 2 | `gh pr create` issued earlier without a subsequent acceptance signal AND `ci-watch-policy: poll` (default) | Enter CI-watch per `core/protocols/ci-watch.md`, OR switch posture via `local/framework.config.yaml § ci-watch-policy: async \| hybrid \| disabled` |
| 3 | Branch matches `^<N>-…`, issue #N is OPEN + carries `ginee:in-progress`, transcript shows no Phase-8 close | Post `gh issue close <N> -c "<phase-8 summary>"`, OR hand back with stop-state note |

**Anti-loop guard:** Respect the `stop_hook_active` payload flag. When set, exit 0 unconditionally — the hook MUST NOT trap the LLM in an unproductive loop (parent #135 anti-pattern). Block condition 3 is also offline-safe — `gh` missing or unauth'd → skip (no block).

## Why

Parent issue #135 § Force taxonomy — Class C (turn-time gate) is the last line of defence: it fires *after* the LLM has decided to stop. Adopters were observing the "ghost on mid-task work" pattern — LLM completes some edits, fails to close the loop (no PR opened, no issue closed, no self-lint marker on the final return), then ends the turn cleanly. The user has to detect and resume.

T7 transforms each of those silent stops into a forced continuation with clear remediation guidance. The forced-interactive triggers in `automatic-mode.md` already cover *during-task* halts; T7 fills the gap at *turn-end*.

The anti-loop guard is non-negotiable. A hook that ignores `stop_hook_active` would trap the LLM in repeated stops; this is explicitly forbidden by parent #135's anti-pattern rule.

## Architecture

| Surface | Owns |
|---|---|
| Hook script (`stop.{ps1,sh}`) | Read payload + transcript · respect `stop_hook_active` · run 3 block checks · exit 2 + stderr on first hit. Reads git branch + (optional) `gh issue view` for block 3 |
| `.claude/settings.json § hooks.Stop` | Wires the hook command. Synced by `core/scripts/sync-claude-settings.{ps1,sh}` |
| `local/framework.config.yaml § compliance.disabled: [stop-hook]` | Per-tactic opt-out |
| `local/framework.config.yaml § ci-watch-policy` | Modulates block 2 — `poll` (default) blocks; `async` / `hybrid` / `disabled` allow |

The hook is **best-effort** — missing transcript / missing gh / network failure → fall open. The cost of a false-block is a confused adopter and a forced retry; the cost of fail-open is the same condition the playbook already accepts pre-T7.

## Verification

| Step | Expected |
|---|---|
| Pester — `tests/stop.Tests.ps1` | 11 / 11 pass — parse-clean · 3 pass-through · 1 anti-loop guard · 2 self-lint block · 2 PR-create block · 2 opt-out |
| bats — `tests/stop.bats` | 10 / 10 pass — equivalent surface against the `.sh` port |
| Manual smoke — `echo '{"hook_event_name":"Stop","transcript":"## Files touched\nx.md\n(no marker)"}' \| pwsh -F adapters/claude/hooks/stop.ps1` | exit 2 + `[ginee:stop-gate] cardinal return missing self-lint marker` on stderr |

## Decisions affected

- **#135 parent playbook** — seventh tactic shipped. Establishes the turn-time gate pattern (Class C).
- **`core/templates/phase-report.md` § Mandatory marker** — the self-lint marker now has a turn-time enforcement layer, not only the LLM's own self-review.
- **`core/protocols/ci-watch.md`** — `poll` posture (default) is now action-enforced at turn-end; adopters who prefer fire-and-forget switch posture explicitly.

## Forward-only

Purely additive — 2 hook scripts + 2 test files + 1 `Stop` entry in `.claude/settings.json.example`. `core/scripts/sync-claude-settings.{ps1,sh}` extended to scaffold the `Stop` event key. Adopter `.claude/settings.json` auto-merge via `/ginee-update`; re-runs idempotent.

## Out of scope

- **Pending-TODO check on local TODO files.** Detection is brittle (multi-file scanning, line-state inference) and overlaps with the user's own task-list visibility. Deferred.
- **Block on PRs without `Closes #N` linkage** — already enforced by the PR-template lint (`core/templates/pr-description.md`).
- **Cross-adapter parity.** Cursor / Copilot / Codex / generic have no Stop event today.
