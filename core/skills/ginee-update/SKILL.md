---
name: ginee-update
description: Update the installed ginee framework in place to the latest published release (or a named ref). Drives `.agents/ginee/install.{ps1,sh} --update-only` — refreshes `core/` + `adapters/` + `extras/`; preserves `local/`. Use when the user asks to 'update ginee', 'upgrade the framework', 'pull the latest ginee', 'bump ginee to v<X>', or 'update to ref <branch|sha>'.
---

# Update the ginee framework (in place)

Drives the adopter project's bundled installer in `--update-only` mode. Refreshes the three upstream-owned trees (`core/` / `adapters/` / `extras/`); preserves `local/`. Surfaces version delta + CHANGELOG + any new migration notes — adopter decides what to act on.

## Activation

- User asks "update ginee" / "upgrade the framework" / "pull the latest ginee" / "bump ginee to `v<X>`" / "update to ref `<branch|sha>`".
- Adopter ran the session-start framework-name check and a new release exists upstream.

## Scope

| Form | Effect |
|---|---|
| `update` (no arg) | Update to the latest published release (resolved via `/releases/latest`). |
| `update <tag>` | Update to a named release tag (`v0.7.0`, `v0.6.1`, ...). Forbids downgrades unless `--allow-downgrade` is named explicitly. |
| `update <branch\|sha>` | Update to an unreleased ref. Falls back to `git clone --depth 1`; `git` must be on PATH. Surface a "non-release ref" notice. |

## Procedure

1. **Locate the framework.** Default `.agents/ginee/`. Confirm `install.ps1` + `install.sh` + `core/VERSION` exist there; fail fast with a one-line "framework not found at `<path>` — pass `--target` to override" if not.
2. **Read current version.** `Get-Content <fw>/core/VERSION` (PowerShell) or `cat <fw>/core/VERSION` (bash). Trim whitespace.
3. **Resolve target ref.**
   - No arg → query `https://api.github.com/repos/kostiantyn-matsebora/ginee/releases/latest` (`gh release view --json tagName --repo kostiantyn-matsebora/ginee` if `gh` is on PATH; otherwise `iwr -useb` / `curl -s` against the API URL).
   - Explicit `<tag>` → use verbatim.
   - Explicit `<branch|sha>` → use verbatim; note non-release fetch path.
4. **Compare versions.**
   - Target == current → report "already at `<v>`; no update needed" + exit.
   - Target < current (SemVer compare on release tags only) → refuse unless `--allow-downgrade` named; surface why.
   - Target > current OR non-release ref → proceed.
5. **Surface the update plan + wait for approval.** Single block:
   ```
   Framework: <path>
   Current:   v<current>
   Target:    v<target>   [or: ref <branch|sha>]
   Adapter:   <adapter>   (from existing install)
   Command:   <installer> --update-only --ref <target>
   Preserves: local/ (incl. local/roles/, local/index/, local/bindings.md, ...)
   Replaces:  core/, adapters/, extras/
   ```
   Wait for explicit `yes` / `proceed`. **Never auto-run.**
6. **Run the installer.** Pick by platform — `pwsh -File <fw>/install.ps1 -UpdateOnly -Ref <target>` on Windows; `<fw>/install.sh --update-only --ref <target>` elsewhere. Stream stdout / stderr to the user; capture exit code.
7. **Report.**
   - Re-read `core/VERSION`. Show `old → new`.
   - Diff `local/index/manifest.yaml` SHA-256s against the freshly fetched `core/` (a class's source file may have been re-glob-matched by a recipe rename) — surface drift; **never auto-reindex**, offer `ginee-reindex` per `core/index-protocol.md § Pre-dispatch staleness check`.
   - Read `<fw>/docs/CHANGELOG.md` and excerpt the section(s) covering versions in the range `(old, new]`.
   - List any **new** files under `<fw>/core/MIGRATIONS/` since the old version. For each, surface its `## Action required` section if present.
   - Recommend `@team-lead rediscover` if any migration's "Action required" mentions discovery / class membership / role catalog.

## Forbidden

- Never run `--update-only` without explicit user approval at step 5.
- Never edit `local/*` during update — the installer preserves it; the skill must too.
- Never auto-reindex on drift; surface `ginee-reindex` per the standard staleness flow.
- Never downgrade across SemVer release tags without explicit `--allow-downgrade`.
- Never mask installer failure — surface the exit code + the last 20 lines of installer stderr; do not retry silently.
- Never bypass an adopter's pinned `--ref` in `local/framework.config.yaml § framework.pinned-ref` (if present) without confirming the override with the user.
