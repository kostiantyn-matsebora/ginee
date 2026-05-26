# Migration — PreToolUse hook on Bash

**Target release:** next minor after 2026-05-26.
**Affected adopters:** Claude Code adapter only.
**Closes:** [#139](https://github.com/kostiantyn-matsebora/ginee/issues/139).
**Parent:** [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135) — tactic 3 / Tier 1, Class A force.
**Sibling:** [`migrations/pretooluse-edit-hook.md`](pretooluse-edit-hook.md) (T2 — extends T2's machinery to the Bash tool).

## What changed

New cross-platform PreToolUse hook:

- `adapters/claude/hooks/pre-tool-use-bash.ps1` — PowerShell (primary).
- `adapters/claude/hooks/pre-tool-use-bash.sh` — bash port (jq-dependent).

Wired into `.claude/settings.json § hooks.PreToolUse` against the `Bash` matcher. The hook reads Claude Code's payload from stdin, pattern-matches the `tool_input.command` string after whitespace normalisation, and exits 2 + stderr remediation on any of four shell-command violations:

| # | Violation | Block |
|---|---|---|
| 1 | `git commit --no-verify` (or `-n`) | Bypasses pre-commit hook gauntlet (context-economy gate + ginee compliance) |
| 2 | `git push --force` / `--force-with-lease` / `-f` targeting `main` / `master` | Force-rewriting trunk history is always blocked |
| 3 | `git reset --hard` | Always block (override via `SKIP_GINEE_COMPLIANCE=1` per invocation) |
| 4 | `gh pr create` without `--body` / `--body-file` / `--draft` | PR body is mandatory per `core/templates/pr-description.md` |

Allowlist patterns preserve common legitimate workflows: `git push --force-with-lease origin <feature-branch>` (non-trunk), `git reset --soft`, `gh pr create --draft` (work-in-progress).

## Why

Per parent issue #135, four shell-command anti-patterns disproportionately damage adopter projects under task pressure: bypassed pre-commit (silently ships malformed work), force-pushed trunk (destroys other contributors' commits), hard reset (loses uncommitted work), unbody'd PRs (drops audit trail). Each is documented in ginee charter today but enforced only by Class H (always-loaded text); under task pressure the LLM bends them. T3 promotes the four to **Class A** (action-time gate, blocks the Bash tool call).

The hook deliberately does NOT block the broader "destructive operation" set documented in `core/process.md § Executing actions with care` — those continue to rely on the LLM's voluntary "ask before risky action" judgement. T3 covers the four highest-frequency drift surfaces; the rest stay Class H by design (anti-pattern: hooks blocking forgivable infractions burn down adopter trust).

## Architecture

Same shape as T2 (`migrations/pretooluse-edit-hook.md`):

- Hook reads Claude Code JSON from stdin; pattern-matches against `tool_input.command`.
- Per-tactic opt-out via `local/framework.config.yaml § compliance.disabled: [pretooluse-bash-hook]`.
- Per-invocation bypass via `SKIP_GINEE_COMPLIANCE=1`.
- Stateless beyond a single `git rev-parse --show-toplevel` (repo root lookup).
- Fail-open wrap — any uncaught error in the hook exits 0 (never block on hook bugs).

## Detection details

**1. `git commit --no-verify` (or `-n`).** Regex `\bgit\s+commit\b.*?(--no-verify|-n\b)` after whitespace normalisation. The `-n` short flag is recognised at word boundaries (so e.g. `--inverse` doesn't trigger).

**2. `git push --force` on `main` / `master`.** Three signals required: `\bgit\s+push\b` + force flag (`--force` / `--force-with-lease` / `-f`) + branch token `\b(main|master)\b`. Non-trunk force-pushes are allowed unchanged (rebase workflow on feature branches preserved).

**3. `git reset --hard`.** Pattern `\bgit\s+reset\b` + `(?<![\w-])--hard(?![\w-])`. `--soft` / `--mixed` are allowed. SKIP_GINEE_COMPLIANCE bypass available because legitimate full-reset scenarios exist (recovery after botched rebase).

**4. `gh pr create` without body.** Trigger `\bgh\s+pr\s+create\b`; allowlist `(--body|--body-file|-B|--draft)`. `--draft` is honoured as legitimate WIP marker.

## Opt-out + bypass

```yaml
# local/framework.config.yaml — per-tactic opt-out
compliance:
  disabled:
    - pretooluse-bash-hook    # disable; T1 / T2 / T4 unaffected
```

```bash
# Per-invocation bypass — emergency only.
SKIP_GINEE_COMPLIANCE=1 git reset --hard <ref>
```

## Verification

| Step | Expected |
|---|---|
| Pester — `tests/pre-tool-use-bash.Tests.ps1` | 18 / 18 pass: parse-clean · 5 pass-through · 2 violation 1 · 2 + 1 allow violation 2 · 1 + 1 allow violation 3 · 1 + 2 allow violation 4 · 1 opt-out · 1 env-bypass |
| bats — `tests/pre-tool-use-bash.bats` | 17 cases mirror the surface against the `.sh` port |
| PSScriptAnalyzer | clean (per project settings) |
| shellcheck | clean |
| Manual smoke — `echo '{"tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}' \| pwsh -F adapters/claude/hooks/pre-tool-use-bash.ps1` | exit 2 + `[ginee:gate] git push --force on main / master blocked` on stderr |

## Decisions affected

- **#135 parent playbook** — third tactic shipped; first Bash-surface tactic.
- **`core/templates/pr-description.md`** — non-empty PR body promoted from convention to Class A.
- **`migrations/pretooluse-edit-hook.md` (T2)** — establishes hook shape; T3 mirrors infrastructure.

## Forward-only

Purely additive: two hook scripts, two test files, one `.claude/settings.json.example` entry, one `install.md` section. Adopters with customised `.claude/settings.json` add the snippet manually per `adapters/claude/install.md § Compliance hooks — Bash (T3)`.

## Out of scope

- **`git commit` threshold-aware trailer check.** Original issue spec called for blocking `git commit` when context-economy threshold tripped without `Optimized-By` trailer. Implementing that accurately requires invoking `scripts/context-economy-check.ps1` from within the hook — expensive (multi-second) and recursive (the hook runs on the same Bash call). The standalone `--no-verify` block + the existing pre-commit hook + the PR-time CI gate together cover the same drift surface; threshold-aware in-hook detection is a follow-up if needed.
- **Edit on `core/**` from main thread via `sed -i` / similar.** The Bash tool can edit files outside the `Edit` / `Write` tool path. Pattern-matching every shell command for destructive file edits is high-false-positive territory. The cardinal subagent `tools:` whitelist (T1) already prevents `sed -i` for SA + ai-engineer; further coverage layers on later.
- **Wider destructive operation set** (`rm -rf`, `kill -9`, `chmod -R`, ...). Stay Class H per `core/process.md § Executing actions with care`; explicit confirmation remains the LLM's responsibility. Hard-blocking these would over-fire and erode adopter trust.
- **Adopter `.claude/settings.json` auto-merge.** Same caveat as T2; tracked separately.
