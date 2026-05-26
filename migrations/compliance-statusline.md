# Migration — Compliance statusline

**Target release:** next minor after 2026-05-26.
**Affected adopters:** Claude Code adapter only.
**Closes:** [#140](https://github.com/kostiantyn-matsebora/ginee/issues/140).
**Parent:** [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135) — tactic 4 / Tier 1, **Class G force** (visible state; awareness only — no enforcement).

## What changed

Two new cross-platform scripts:

- `adapters/claude/statusline.ps1` — PowerShell (primary).
- `adapters/claude/statusline.sh` — bash port.

Wired into `.claude/settings.json § statusLine`, Claude Code invokes the chosen script on every prompt + tool call. Each invocation emits a single line (≤ 100 chars) to stdout, which Claude renders as the persistent status row above the input.

**Format** (per playbook §):

```
[ginee] #<N> · phase: <P> · warm: <roles> · dispatches: <n/cap>
        · trailer: <ok|needed> · self-lint: <pass|miss|n/a> · cap: <N>%
```

This first cut surfaces the locally-derivable subset; fields requiring in-process warm-registry state print `?` placeholders until the skill-runner-side plumbing lands.

## Locally-derivable fields (shipped now)

| Field | Source |
|---|---|
| `#<N>` (issue number) | Branch name — explicit `#<N>` token first, then `/t<N>` ginee convention |
| Branch name (fallback) | `git rev-parse --abbrev-ref HEAD` when no issue number is parseable |
| `trailer: <ok\|needed>` | `git log --format='%B' origin/main..HEAD` scanned for `Optimized-By: ai-engineer` |
| `cap: <N>%` | Walks hot-spec files in `git diff --name-only origin/main..HEAD`; for each with frontmatter `cap-bytes`, computes `(cap - size) / cap * 100`; emits the minimum (tightest file) |

## Placeholder fields (require D43 plumbing)

| Field | Why placeholder |
|---|---|
| `phase: ?` | Lifecycle phase lives in `team-lead`'s working memory; not externalised to a file the statusline can read. |
| `warm: ?` | Warm cardinal registry lives in the skill-runner main thread per `migrations/warm-reuse-claude-plumbing.md`; same problem. |
| `dispatches: <n/cap>` | Same — counters maintained in skill-runner context. |
| `self-lint: <pass\|miss\|n/a>` | Latest cardinal-return self-lint marker is in skill-runner context too. |

A follow-up tactic ships the skill-runner-side write-out (`.claude/.ginee/compliance-state.json` or similar) — once that file exists, the statusline picks it up automatically and replaces the `?` placeholders. Visible-state-only / Class G means partial coverage is acceptable: the present subset (issue · trailer · cap) is the highest-signal trio in the playbook author's experience.

## Why

Per parent #135 § Force taxonomy, Class G (visible state) is the cheapest force-class — pure awareness, no enforcement. The author repeatedly missed `Optimized-By` trailers and cap-bytes thresholds during the playbook's audit window; surfacing them in the persistent status row catches drift before the gate fires at commit / CI time. The signal compounds with the action-time gates (T2 / T3) — those block; this one warns ahead of time, so the LLM proactively dispatches `ai-engineer` instead of hitting the gate.

## Architecture + safety

- Statusline runs frequently (every prompt + tool call) — must be fast. The script's hot path runs 1 `git rev-parse` + 1 `git log` + 1 `git diff --name-only` + N small file reads (only hot-spec files in the diff). Typical wall-clock < 100 ms.
- **MUST NOT crash the host.** Every script path is wrapped in try/catch (pwsh) / `trap ERR` (bash). On any uncaught error the script emits a bare `[ginee]` (or nothing) and exits 0. Claude Code displays the fallback; no host disruption.
- Opt-out is per-tactic via `local/framework.config.yaml § compliance.disabled: [compliance-statusline]`. Opting out prints nothing.

## Opt-out

```yaml
# local/framework.config.yaml
compliance:
  disabled:
    - compliance-statusline   # statusline emits no output; T1 / T2 / T3 unaffected
```

## Verification

| Step | Expected |
|---|---|
| `Invoke-Pester -Path tests/statusline.Tests.ps1` | 8 / 8 pass — parse-clean · always-exit-0 · [ginee] prefix · ≤ 100 chars · trailer field · phase placeholder · opt-out · no-repo fallback |
| bats — `tests/statusline.bats` | 8 cases mirror the surface against the `.sh` port |
| PSScriptAnalyzer + shellcheck | clean |
| Manual smoke (with this branch checked out) — `echo '{"session_id":"x"}' \| pwsh -F adapters/claude/statusline.ps1` | `[ginee] #140 · phase: ? · warm: ? · trailer: <ok\|needed> · cap: <N>%` |

## Decisions affected

- **#135 parent playbook** — fourth tactic shipped; first Class G surface (visible-state, no enforcement).
- **`migrations/warm-reuse-claude-plumbing.md` (D43)** — gains a forward dependency: the warm-registry plumbing needs to write a state file the statusline can read in order to fill `phase: ?` / `warm: ?` / `dispatches: ?` / `self-lint: ?` placeholders. Tracked as a follow-up; current placeholders document the contract.

## Forward-only

Purely additive — 2 scripts under `adapters/claude/`, 2 test files, `.claude/settings.json.example` gains a `statusLine` block, `install.md` gains a section. Adopters with customised `.claude/settings.json` add the `statusLine` block manually (auto-merge in installer is the same shared follow-up as T2 / T3).

## Out of scope

- **In-process warm-registry write-out.** Skill-runner-side plumbing to persist phase / warm / dispatches / self-lint to a file the statusline can read is its own tactic; current placeholders are a holding pattern.
- **Per-field opt-out.** All-or-nothing via the single tactic-id `compliance-statusline`. Splitting is deferred.
- **Cross-adapter parity.** Cursor / Codex / generic adapters expose no equivalent statusline surface today.
- **PR-time CI gate parity.** The `trailer: needed` indicator mirrors the CI gate's PASS/FAIL boundary but does not invoke the same logic — it uses a coarse `Optimized-By` presence check, not the per-file threshold computation. CI remains authoritative.
