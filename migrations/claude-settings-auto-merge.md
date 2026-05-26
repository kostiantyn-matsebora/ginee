# Migration — `.claude/settings.json` auto-merge for compliance playbook tactics

**Target release:** next minor after 2026-05-26.
**Affected adopters:** Claude Code adapter only.
**Parent:** [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135) — closes the auto-merge follow-up cited in T2 / T3 / T4 migration specs.
**Prior:** [`migrations/pretooluse-edit-hook.md`](pretooluse-edit-hook.md) (T2) · [`migrations/pretooluse-bash-hook.md`](pretooluse-bash-hook.md) (T3) · [`migrations/compliance-statusline.md`](compliance-statusline.md) (T4).

## What changed

T2 / T3 / T4 each shipped hook + statusline scripts under `adapters/claude/`, but adopters had to paste the `.claude/settings.json` wiring snippet manually — the installer only copied `.claude/settings.json.example` when no file existed. Adopters with any prior customisation never got the auto-wire.

This migration closes that gap with two new scripts and an installer hook:

- `core/scripts/sync-claude-settings.ps1` (PowerShell, primary)
- `core/scripts/sync-claude-settings.sh` (bash port; requires `jq`)

`install.ps1` (claude branch) calls the `.ps1`; `install.sh` (claude branch) calls the `.sh`. Both run after the existing pointer-subagent + skill copy + CLAUDE-pointer.md sync steps.

## Behaviour

Each invocation:

1. Loads existing `.claude/settings.json` (or seeds `{}`).
2. **statusLine (T4)** — adds the ginee statusLine if absent; refreshes the path on a ginee-owned `statusLine.command` (substring `adapters/claude/statusline`) when the path drifts across releases; **leaves an adopter-customised command untouched**.
3. **PreToolUse Edit/Write/MultiEdit (T2)** — appends the matcher entry if no existing PreToolUse entry's command references `adapters/claude/hooks/pre-tool-use-edit`.
4. **PreToolUse Bash (T3)** — same shape; appends if no existing entry references `adapters/claude/hooks/pre-tool-use-bash`.
5. Writes the merged JSON back only when a change occurred (no spurious file modification on already-current installs).

All other top-level keys (`env`, `theme`, `permissions`, etc.) round-trip unchanged.

## Action required

**None for most adopters.** Run `/ginee-update` and the entries appear in `.claude/settings.json` automatically. Re-running is a no-op.

**Bash-only adopters without `jq`** — the bash sync script warns and skips:

```
sync-claude-settings: jq not on PATH — leaving .claude/settings.json untouched.
  Install jq, then run /ginee-update again, OR apply the snippet manually per
  adapters/claude/install.md § Compliance hooks.
```

Install jq (`apt-get install jq` / `brew install jq` / `dnf install jq`) and re-run `/ginee-update`, or paste the manual snippet from `adapters/claude/install.md`.

**Adopters with malformed `.claude/settings.json`** — the sync script warns and skips. Fix the JSON first, then re-run.

## Adopter customisations preserved

- A non-ginee `statusLine.command` is never replaced.
- Existing PreToolUse entries with matching commands are not duplicated. If you've manually wired an older path (e.g., `adapters/claude/hooks/pre-tool-use-edit.sh` instead of `.ps1`), it is left in place — only newly-introduced ginee paths are added.
- Adopter timeouts and matcher patterns (e.g., a narrower `Edit` matcher instead of `Edit|Write|MultiEdit`) are preserved when the command path already matches.

## Verification

| Step | Expected |
|---|---|
| Pester — `tests/sync-claude-settings.Tests.ps1` | 9 / 9 pass — parse-clean · fresh-install creates 3 entries · idempotent on re-run · preserves env/theme · keeps adopter-custom statusLine · refreshes ginee-owned statusLine on drift · no duplicate PreToolUse entry · malformed JSON warn-only · custom `-FrameworkRel` honoured |
| bats — `tests/sync-claude-settings.bats` | 10 cases mirror the surface against the `.sh` port |
| Manual smoke (Windows) — `pwsh -F core/scripts/sync-claude-settings.ps1 -Target <empty-tmp-dir>` | settings.json appears with `statusLine` + 2 PreToolUse entries; `.command` strings reference `.agents/ginee/adapters/claude/...` |

## Decisions affected

- **`migrations/pretooluse-edit-hook.md` (T2)** — out-of-scope item "auto-merge into adopter settings.json" struck through; now landed.
- **`migrations/pretooluse-bash-hook.md` (T3)** — same.
- **`migrations/compliance-statusline.md` (T4)** — same. Statusline wiring is now automatic.
- **`adapters/claude/install.md § Compliance hooks` / `§ Compliance statusline (T4)`** — flagged as auto-wired; manual snippet retained as fallback for adopters who skip the installer.

## Forward-only

Purely additive — 2 new scripts under `core/scripts/`, 2 new test files, +11 lines in each of `install.ps1` / `install.sh`. No `local/` schema change. Adopters re-running `/ginee-update` get the entries on next sync; adopters who skip the update see no behavioural change.

## Out of scope

- **Removal on opt-out.** Setting `local/framework.config.yaml § compliance.disabled: [pretooluse-edit-hook]` opts the hook OUT of action-time enforcement but does NOT remove the entry from `.claude/settings.json`. The hook itself reads the opt-out and exits 0; the settings.json entry stays. Adopters who want a clean settings.json can delete the matching block manually.
- **Cross-adapter parity.** Cursor / Codex / generic adapters have no equivalent `.claude/settings.json` surface today.
- **Pure-bash JSON fallback.** When `jq` is absent on Linux, the script warns and skips. Implementing a hand-rolled JSON merger in pure bash is intentionally out of scope — install `jq` or use the manual snippet.
