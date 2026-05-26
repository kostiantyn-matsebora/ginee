# Migration — Slash command suite for gate-prone operations

**Target release:** next minor after 2026-05-26.
**Affected adopters:** Claude Code adapter only.
**Closes:** [#146](https://github.com/kostiantyn-matsebora/ginee/issues/146).
**Parent:** [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135) — tactic 10 / Tier 3, Class A (indirect; replaces LLM free-form composition with deterministic templates).

## What changed

Six slash commands ship under `adapters/claude/commands/ginee-*.md`. The adapter installer (`core/scripts/sync-claude-commands.{ps1,sh}` — see "Installer" below) syncs them to the adopter's `.claude/commands/`. Invocation lands the schema skeleton + filling instructions directly in the LLM's prompt — schema-bound by construction.

| Command | Output |
|---|---|
| `/ginee-dispatch <role> <task>` | `core/protocols/dispatch-prompt-schema.md` payload skeleton with positional args resolved (`$1` = role, `$ARGUMENTS` = task) |
| `/ginee-phase-report` | `core/templates/phase-report.md` schema skeleton (Status header + every required section + `(none)` fallbacks + final `<!-- self-lint: pass -->`) |
| `/ginee-self-lint` | The 7 mandatory checks; advisory only — never re-dispatch for format |
| `/ginee-commit` | Commit-message skeleton with `Closes #N` **inside** the body + `Optimized-By: ai-engineer` + `Co-Authored-By` trailers on contiguous lines |
| `/ginee-pr` | PR body per `core/templates/pr-description.md` + `gh pr create --body "$(cat <<'EOF' … EOF)"` HEREDOC pattern |
| `/ginee-issue-pickup #N` | Mechanical pick-up procedure — comments fetch (binding) + sub-issues fetch (binding) + scoring/sticky + lite-mode detection + sub-issue fast-path + label swap + team-lead hand-off |

## Why

Parent #135 § Force taxonomy — Class A (indirect). LLM free-form composition of these six artefacts is the highest-drift surface in ginee:

- Dispatch payloads drop required sections under task pressure.
- Phase reports drift toward narrative preamble + restated dispatch context.
- Commit messages place `Closes #N` outside the body (breaks git auto-close).
- PR bodies miss required cites.
- Issue pickup skips comments OR sub-issues fetch.

The slash command body becomes a one-shot prompt injection — the LLM sees the schema skeleton + filling instructions at exactly the moment of composition. Deterministic by construction, no every-turn token cost.

## Architecture

| Surface | Owns |
|---|---|
| `adapters/claude/commands/ginee-*.md` | Frontmatter (`description:` · `argument-hint:`) + body skeleton. Static markdown; no script execution |
| `core/scripts/sync-claude-commands.{ps1,sh}` | Sync to adopter `.claude/commands/ginee-*.md` (overwrite — framework-owned) |
| `adapters/claude/install.md § Steps` | Adds Step 2b — copy `adapters/claude/commands/ginee-*.md` → `.claude/commands/` (POSIX symlink preferred; `/ginee-update` handles re-sync) |
| `local/framework.config.yaml § compliance.disabled: [slash-commands]` | Per-tactic opt-out — adopters opt out by deleting the synced files; the disabled list keeps `/ginee-update` from re-syncing |

Slash commands are markdown only — no script, no test runner. The deterministic-template force comes from constraining the prompt shape, not from runtime enforcement.

## Verification

| Step | Expected |
|---|---|
| Pester — `tests/ginee-commands.Tests.ps1` | 13 / 13 pass — directory shape · frontmatter · schema-marker coverage per command |
| bats — `tests/ginee-commands.bats` | 7 / 7 pass — equivalent surface |
| Manual smoke — type `/ginee-dispatch backend-engineer "wire X"` in Claude Code | Skeleton lands in prompt; role + task interpolated |
| Manual smoke — type `/ginee-commit "fix Y"` in Claude Code | Commit-message skeleton with `Closes #N` before trailer block |

## Decisions affected

- **Parent playbook #135** — tenth tactic shipped; Tier 3 progress.
- **`core/protocols/dispatch-prompt-schema.md`** — unchanged; the slash command emits the skeleton verbatim and cites the spec for the 5 self-lint checks.
- **`core/templates/phase-report.md`** — unchanged; the slash command emits the schema skeleton + 7-check reminder.
- **`core/templates/pr-description.md`** — unchanged; the slash command emits the body skeleton + the HEREDOC submission pattern.
- **`core/skills/ginee-pick-up/SKILL.md`** — unchanged; `/ginee-issue-pickup` is a mechanical wrapper, not a replacement.
- **Git trailer block format** — `/ginee-commit` enforces the contiguous-trailer rule (no blank line between `Closes` / `Optimized-By` / `Co-Authored-By`) per the framework's commit conventions.

## Forward-only

Purely additive — adds 6 files under `adapters/claude/commands/` + 2 tests + 1 sync script pair (PS1 + bash) + 1 install.md step. Adopter `.claude/commands/ginee-*.md` auto-sync via `/ginee-update`. Adopters who do nothing on upgrade keep their existing slash commands; pre-existing non-ginee commands untouched.

## Out of scope

- **Adopter customisation of the slash command body.** Slash commands ship from `adapters/claude/commands/` and overwrite on `/ginee-update`. Adopters who want a custom variant create their own under a non-`ginee-` prefix.
- **Cross-adapter parity.** Cursor / Copilot / Codex / generic adapters have no equivalent surface. Cross-adapter playbooks ship as their tooling matures.
- **Per-command opt-out.** The single tactic-id `slash-commands` covers all six; per-command granularity deferred until production usage shows asymmetric value.
- **Programmatic invocation from skill-runner.** Slash commands are user-typed only; skill-runner continues to invoke the underlying schemas directly via dispatch payloads.
