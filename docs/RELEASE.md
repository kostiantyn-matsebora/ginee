# Release checklist

Run before bumping `core/VERSION`.

1. `pwsh -File scripts/measure-role-context.ps1 -UpdateDoc` — refresh `docs/reference/CONTEXT_COSTS.md` snapshot. Pester gates this.
2. `pwsh -File scripts/measure-role-context.ps1` — compare vs. prior tag. Material shift (≥ 10% per role, OR headroom < 20%) → one-line release-notes entry.
3. Tighten `scripts/templates/role-context-ceilings.json` if measurements stabilised; loosening any ceiling → `ai-engineer` review required.
4. `Invoke-Pester -Path tests/measure-role-context.Tests.ps1` — all 17 tests MUST pass.
5. Commit regenerated `CONTEXT_COSTS.md` + ceiling adjustments in the release-prep PR; do NOT tag until the snapshot is current.

## Tagging

`git push --tags` only — `release.yml` fires on tag push and creates the GitHub release. Do NOT manually `gh release create` (races the workflow).
