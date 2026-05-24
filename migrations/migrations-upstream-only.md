# Migration — migrations are upstream-only, never shipped

**Affected adopters:** every adopter on every adapter. Purely additive; no breaking change to installer flags or skill triggers.

## What changed

Migration files no longer ship inside `.agents/ginee/`. Pre-cutover the installer copied a full migration tree (`.agents/ginee/core/MIGRATIONS/`, 36 files / ~228 KB) into every adopter install — then `/ginee-update` Step 7 read those local files to compose the post-update report. Adopters never edited them; LLMs never loaded them at task time. They were update-time-only artefacts paying a runtime distribution cost.

The cutover does two things in one pass:

| Change | Effect |
|---|---|
| **Move out of `core/`** | Migrations relocated to `migrations/` at the repo root upstream. They are no longer "framework spec" by location either. |
| **Drop the `D<N>-` filename prefix** | Migration filenames go slug-only (`installer-fetch-on-update.md`, `model-tier.md`, …). The owner's decision-log numbers stay in `PLAN.md`; migrations are per-change adopter switching instructions, not decision records. |
| **Stop shipping** | `install.{ps1,sh}` prune the directory on every install — fresh installs get no `migrations/`; pre-cutover installs get `core/MIGRATIONS/` cleaned up on first re-run. |
| **Fetch on demand** | `/ginee-update` Step 7 enumerates the `(old, new]` window via GitHub Contents API + raw-URL fetch + per-item approval gate. |

## Action required

**One-time action: none for new installs.** Fresh `install.{ps1,sh}` runs land with no `<fw>/migrations/` directory.

**One-time action: nothing for pre-cutover adopters on their next update.** The first time an existing adopter runs `/ginee-update` against a post-cutover target version, the prune step inside the installer removes `<fw>/core/MIGRATIONS/` (legacy home) AND `<fw>/migrations/` (new home, in case the tarball ever carried it). No manual action needed.

**Going forward, when you run `/ginee-update`:**

- The skill fetches migrations landed in the `(old, new]` window from `https://raw.githubusercontent.com/<upstream>/<new>/migrations/<slug>.md`.
- Each migration surfaces with title · 5-line summary · its `## Action required` section · a `yes / skip / all-yes / all-skip` prompt.
- Apply only what you want; skipped migrations are recorded in the post-update report with `user-skipped at <ISO>`.
- Network failure during fetch surfaces inline (`migration fetch failed: <code>; check <upstream-URL>/migrations manually for v<old>→v<new>`) — never silent retry; never blocks the update (framework files already landed in installer Step 6).

**If you still need to browse migrations as files:** `https://github.com/<upstream>/tree/main/migrations/`. Replace `<upstream>` with your `local/framework.config.yaml § github.framework-repo` value (default `kostiantyn-matsebora/ginee`).

**No `local/*` edits required.** No `framework.config.yaml` schema change. No new flags.

## Behavioural change to expect

- `.agents/ginee/migrations/` and `.agents/ginee/core/MIGRATIONS/` no longer exist on post-cutover installs (whether fresh or after first update from pre-cutover).
- `/ginee-update` post-update report lists migrations with a per-item gate — applying anything mechanical from a migration body requires explicit `yes`.
- Framework files no longer cite migration files. The framework rule body is the source of truth; migrations are per-version switching instructions only.
- LLM context economy on adopter task runs: unchanged in practice — no role / skill / template loaded migrations at task time pre-cutover either; they were update-time-only. The ~228 KB distribution-weight reduction is the real win.
- Forks: adopters who set `github.framework-repo: <fork-owner>/ginee` have the skill fetch migrations from that fork's raw URLs.

## Safeguards

- **Never auto-apply.** Step 7 per-item gate is hard — `yes` only; `skip` / `all-skip` always honored.
- **Never edit `local/*`** — mirrors the installer's `local/` preservation guarantee.
- **Never silent retry on migration-fetch failure** — error surfaces inline + flagged in the post-update report.
- **Never block the update on migration-fetch failure** — framework files already landed in installer Step 6.

## Rollback

This cutover spans the installer + the skill. To revert:

1. Replace `core/skills/ginee-update/SKILL.md` Step 7 with the pre-cutover version (recover from git history).
2. Remove `migrations` + `core/MIGRATIONS` from the prune list in `install.ps1` and `install.sh`.
3. Optionally `git mv migrations/ core/MIGRATIONS/` to restore the original location.

After rollback, the next `install.{ps1,sh}` run will re-ship the migration tree on adopter installs, and `/ginee-update` Step 7 reverts to reading local files.

## Issue reference

Closes [#115](https://github.com/kostiantyn-matsebora/ginee/issues/115) — "[Framework Feature] Fetch migrations from upstream on update — drop shipped `core/MIGRATIONS/`".
