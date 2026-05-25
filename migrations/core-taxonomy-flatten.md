# Migration — core/ taxonomy flatten

**Target release:** next minor.
**Affected adopters:** all adopters with `.agents/ginee/` installed; auto-applies on next `/ginee-update`.
**Closes:** (no issue — direct framework-hygiene task).

## What changed

12 root-level files under `core/` moved into `core/protocols/`. The existing taxonomy (`core/process/` · `core/protocols/` · `core/templates/` · `core/roles/` · `core/skills/` · `core/scripts/`) now covers every framework spec. Only `core/process.md` + `core/VERSION` remain at the `core/` root.

| Before | After |
|---|---|
| `core/automatic-mode.md` | `core/protocols/automatic-mode.md` |
| `core/changelog-protocol.md` | `core/protocols/changelog-protocol.md` |
| `core/ci-watch.md` | `core/protocols/ci-watch.md` |
| `core/cross-agent-handoff.md` | `core/protocols/cross-agent-handoff.md` |
| `core/cross-domain-bugs.md` | `core/protocols/cross-domain-bugs.md` |
| `core/delivery-modes.md` | `core/protocols/delivery-modes.md` |
| `core/doc-authoring-examples.md` | `core/protocols/doc-authoring-examples.md` |
| `core/doc-roles.md` | `core/protocols/doc-roles.md` |
| `core/github-integration.md` | `core/protocols/github-integration.md` |
| `core/index-syntax.md` | `core/protocols/index-syntax.md` |
| `core/post-task-check-in.md` | `core/protocols/post-task-check-in.md` |
| `core/triage-scoring.md` | `core/protocols/triage-scoring.md` |

## Why

Pre-cutover the `core/` root mixed three concerns — the lifecycle spec (`process.md`), invariants like `VERSION`, and 12 ad-hoc protocol files that pre-dated the `protocols/` subdirectory. New protocol files have been landing in `protocols/` for several releases (`blueprint-diff-protocol.md` · `doc-authoring-protocol.md` · `doc-size-caps.md` · `index-protocol.md` · `iteration-protocol.md` · `options-protocol.md`); the legacy root files were the only stragglers. Flattening eliminates a "two-place" puzzle for both maintainers and adopters when locating a spec.

- **Taxonomy clarity.** A spec is in `core/protocols/`. A phase or dispatch file is in `core/process/`. A role kernel is in `core/roles/`. A template is in `core/templates/`. No ad-hoc root files.
- **Adopter look-up cost.** `local/bindings.md` and adopter-authored role files cross-reference framework specs by path. One consistent prefix (`core/protocols/<spec>.md`) is faster to scan than the prior root-vs-subdir split.
- **No semantic change.** Every rule survives byte-for-byte; only paths changed.

## Adopter migration

**Nothing to do for the typical install.** `/ginee-update` replaces `<fw>/core/` wholesale (preserving `local/`), so the file relocations land automatically.

**If your `local/` files cite old paths** — `local/bindings.md` · `local/roles/*.md` · `local/<your-doc>.md` — run a one-shot find-and-replace under your repo root:

```bash
files=(automatic-mode changelog-protocol ci-watch cross-agent-handoff cross-domain-bugs \
       delivery-modes doc-authoring-examples doc-roles github-integration index-syntax \
       post-task-check-in triage-scoring)
for f in "${files[@]}"; do
  grep -rlZ "core/${f}\.md" local/ 2>/dev/null \
    | xargs -0 -r sed -i "s|core/${f}\.md|core/protocols/${f}.md|g"
done
```

PowerShell equivalent:

```powershell
$files = @('automatic-mode','changelog-protocol','ci-watch','cross-agent-handoff','cross-domain-bugs',
           'delivery-modes','doc-authoring-examples','doc-roles','github-integration','index-syntax',
           'post-task-check-in','triage-scoring')
Get-ChildItem -Path local -Recurse -Include *.md | ForEach-Object {
  $content = Get-Content $_.FullName -Raw
  foreach ($f in $files) { $content = $content -replace "core/$f\.md", "core/protocols/$f.md" }
  Set-Content $_.FullName $content -NoNewline
}
```

Skip if `local/` doesn't reference framework spec paths.

## Files touched (this migration)

| Surface | Change |
|---|---|
| `core/<12 files>.md` | Moved to `core/protocols/<file>.md` (git mv — history preserved) |
| `core/**` cross-references | Updated to new paths |
| `adapters/**` cross-references | Updated to new paths |
| `extras/**` cross-references | Updated to new paths |
| `docs/**` cross-references | Updated to new paths (CONCEPTS · CHEATSHEET · GETTING_STARTED · ARCHITECTURE · index) |
| `migrations/<prior>.md` cross-references | Updated to new paths (so existing migrations remain navigable post-cutover) |
| `.github/release-notes/v*.md` | **Not touched** — point-in-time records; paths reflect the state at release |
| `CLAUDE.md` | Repo-structure tree extended with `process/` + `protocols/` + `skills/` + `scripts/` rows; decision-table heading and row gained |
| `PLAN.md` | New decision entry logged |
| `scripts/context-economy-check.ps1` | Watched-path patterns already cover both `^core/[^/]+\.md$` + `^core/protocols/[^/]+\.md$` (other tier) — no script change needed |
| `tests/*.Tests.ps1` | No path assertions reference the moved files |

## Action required

None — `/ginee-update` lands the new paths mechanically. Run the `local/` sed snippet above only if your `local/` files cite framework spec paths.
