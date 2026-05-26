# Migration — SessionStart resume hook

**Target release:** next minor after 2026-05-26.
**Affected adopters:** Claude Code adapter only.
**Closes:** [#148](https://github.com/kostiantyn-matsebora/ginee/issues/148).
**Parent:** [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135) — tactic 12 / Tier 3, Class D (session-boundary anchor).

## What changed

A new cross-platform SessionStart hook lives at:

- `adapters/claude/hooks/session-start.ps1` — PowerShell (primary).
- `adapters/claude/hooks/session-start.sh` — bash port (jq + git dependent).

When `.claude/settings.json` wires this hook into `hooks.SessionStart`, Claude Code invokes it at the start of each conversation. The hook scans local + remote state and emits stdout JSON whose `hookSpecificOutput.additionalContext` carries a `[ginee:resume]` block describing what's in flight, so the LLM picks up where it left off.

## Scans

| Source | Inject |
|---|---|
| Current branch matching `^issue/(\d+)` (any branch name starting `issue/<N>-…`) | `branch: <name> — <N> ahead of origin/main` plus ` · uncommitted changes` when working tree is dirty |
| Open `ginee:in-progress` issues (via `gh issue list --label ginee:in-progress`) | `open ginee:in-progress issues:` header then `  - #<N> [· phase <P>] — <title>` per issue (phase from `ginee:phase-N` label if present) |

`gh`-backed scan fails open — missing `gh` / network error / non-zero exit → quiet skip, never an LLM-visible error.

Empty injection (no qualifying branch AND no qualifying issues) → exit 0 with empty stdout. No noise.

## Why

Parent #135 § Force taxonomy — Class D at the session boundary defeats the "start fresh and re-decide everything" failure mode that hits after session restarts mid-task. The two scan targets cover the most common loss surfaces — branch state (local) + parent issue (remote). Both are durable across session boundaries; the LLM's task list + warm registry are not (see "Out of scope").

The `[ginee:resume]` label distinguishes injection from user-supplied prompt content — adopters can grep transcripts unambiguously.

## Architecture

| Surface | Owns |
|---|---|
| Hook script (`session-start.{ps1,sh}`) | Drain payload · resolve repo root · check opt-out · scan branch · scan gh (offline-safe) · emit `hookSpecificOutput.additionalContext` |
| `.claude/settings.json § hooks.SessionStart` | Wires the hook command. Synced by `core/scripts/sync-claude-settings.{ps1,sh}` |
| `local/framework.config.yaml § compliance.disabled: [session-start-hook]` | Per-tactic opt-out |

The hook is **pure-on-read** — no writes, no daemon, no state file. Network call (gh) is the only off-disk dependency, gated by `Get-Command gh` / `command -v gh` presence + a short-circuit on non-zero exit. `--limit 20` caps gh payload size for the typical adopter; SessionStart latency stays well under the 2-second ceiling acceptance criterion.

## Verification

| Step | Expected |
|---|---|
| Pester — `tests/session-start.Tests.ps1` | 10 / 10 pass — parse-clean · quiet-on-empty (×2) · branch scan (×3) · envelope · opt-out (×2) · fail-open |
| bats — `tests/session-start.bats` | 9 / 9 pass — bash-clean · quiet (×2) · branch (×3) · envelope · opt-out (×2) |
| PSScriptAnalyzer — `Invoke-ScriptAnalyzer adapters/claude/hooks/session-start.ps1` | clean |
| shellcheck — `shellcheck adapters/claude/hooks/session-start.sh` | clean |
| Manual smoke — `cd <issue-branch> && echo '{"hook_event_name":"SessionStart"}' \| pwsh -F adapters/claude/hooks/session-start.ps1` | stdout JSON contains `[ginee:resume]` + `branch: …` |

## Decisions affected

- **Parent playbook #135** — twelfth tactic shipped; Tier 3 final.
- **`core/protocols/automatic-mode.md`** — unchanged. SessionStart inject is non-prescriptive (informational only); does not force a specific resume flow.
- **`core/protocols/github-integration.md`** — unchanged. The scan label conventions (`ginee:in-progress` · `ginee:phase-<N>`) are read-only; no new label semantics introduced.

## Forward-only

Purely additive — adds 2 files under `adapters/claude/hooks/` + 2 tests under `tests/` + one `SessionStart` entry in `.claude/settings.json.example`. Adopter `.claude/settings.json` auto-merge via `core/scripts/sync-claude-settings.{ps1,sh}`; re-runs idempotent.

## Out of scope

- **In-progress TaskList scan.** Claude Code's task list is in-memory per session; no on-disk artifact to scan. If task list ever gains persistence, the hook gains a `Get-TaskListScan` companion in a follow-up.
- **Last cardinal return + warm registry scan.** Cross-session warm reuse is explicitly out of scope per `migrations/warm-reuse-claude-plumbing.md § Out of scope` (registry is in-process; session restart resets). When a durable cross-session registry lands, the hook gains a third scan target.
- **Cross-repo aggregation.** Single-repo only — same scope rule as the rest of the framework.
- **Custom scan extensions via `local/framework.config.yaml`.** Considered; deferred until production usage shows extension demand.
