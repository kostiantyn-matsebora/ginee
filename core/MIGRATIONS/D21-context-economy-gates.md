# D21 — Context-economy enforcement gate

**Date.** 2026-05-19.
**Closes.** [#38](https://github.com/kostiantyn-matsebora/ginee/issues/38).

## What changed

The rule in `CLAUDE.md § Framework authoring — context economy` (any framework-file change > ~50 lines net-added → `ai-engineer` optimization pass before commit) is now **mechanically enforced** on this repo's PRs.

## Three layers

| Layer | Mechanism | Trigger | Behaviour |
|---|---|---|---|
| 1. Claude Code hook | `.claude/settings.json` PostToolUse | After every `Edit` / `Write` / `MultiEdit` | Runs `scripts/context-economy-check.ps1 -ClaudeHook -Json`; surfaces threshold breach in real time. |
| 2. Git pre-commit / pre-push | `hooks/pre-commit`, `hooks/pre-push` | On `git commit` / `git push` | Runs the same script in `-StagedOnly` or `-BaseRef origin/main` mode. Blocks if threshold exceeded without marker. |
| 3. CI workflow | `.github/workflows/context-economy.yml` | On PR + push to `main` | Diffs against base ref; fails if threshold breached without marker AND no waiver. |

## Watched paths (this repo only)

| Tier | Paths | Threshold |
|---|---|---|
| Always-loaded (strictest) | `CLAUDE.md`, `PLAN.md`, `core/process.md`, `core/roles/*.md` | 25 lines OR 1 KB net-added |
| Other watched | `core/*.md` specs, `core/roles/*.details.md`, `core/skills/**`, `core/templates/**`, `adapters/**`, `extras/roles/**` | 50 lines OR 2 KB net-added |

## Marker convention

Git trailer **`Optimized-By: ai-engineer`** on any commit in the PR range. Found via `git log --format='%(trailers:key=Optimized-By,valueonly,unfold)' <base>..HEAD`.

Why a trailer (not a marker file or commit-message regex):
- Machine-readable; native git support.
- Doesn't pollute the file tree.
- Survives squash-merge as long as it's preserved in the final commit message.

## Waiver

| Channel | Requirement |
|---|---|
| PR label | `context-economy:waived` |
| PR body | Line matching `**Context economy waiver:** <reason>` (text, ≥ 1 char after the colon) |

Both required. Label alone fails CI with an explicit error. Use sparingly — every waiver is visible in PR history.

## Structural lint

Always-loaded files also receive a **prose-paragraph lint**: any non-bullet, non-table, non-code-fence, non-heading paragraph containing > 2 sentence terminators (`.`, `!`, `?` followed by space) is flagged. Catches the D18–D20 regression signature (prose-in-table rows, multi-rule sentences in walls of text). Exit code 2 (separate from threshold exit code 1).

## Activation (per checkout)

```pwsh
# 1. Layer 1 — Claude Code hook (manual, since project hook activation is sensitive)
Copy-Item .claude/settings.json.example .claude/settings.json

# 2. Layer 2 — git hooks
pwsh -File scripts/install-hooks.ps1
# or
bash scripts/install-hooks.sh
```

Layer 3 (CI) is automatic — workflow runs on every PR.

## Bypass

Local (emergency only):

```
SKIP_CONTEXT_ECONOMY=1 git commit ...
SKIP_CONTEXT_ECONOMY=1 git push ...
```

CI: use the label + justification waiver above. Never `--no-verify` (per CLAUDE.md hard constraints).

## Out of scope

- **Adopter-project doc enforcement.** Adopter docs are a separate problem (see issue #39 — doc-authoring protocol). This gate runs on **this repo's PRs only**.
- **Hard byte ceilings per file.** Deferred — current sizes (CLAUDE.md 18.5 KB, team-lead.md 16.5 KB) sit above the originally-proposed caps. Re-evaluate after the cleanup from #36 lands and ~3 release cycles' worth of telemetry.
- **Lossless verification.** The gate trusts the trailer; mechanical lossless-checking is `ai-engineer`'s job, not a CI computation.
- **Adapter re-render cascade.** Edits to `core/` may need adapter updates; that's tracked separately, not blocked here.

## Rationale

Depending on a contributor remembering the rule failed three times in three releases (D18 / D19 / D20). Issue #36 fixes the symptom; this gate fixes the failure mode. Defense-in-depth — three independent mechanisms; bypassing one leaves two.
