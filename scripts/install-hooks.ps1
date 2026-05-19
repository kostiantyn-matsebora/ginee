#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Install ginee's git hooks (context-economy gate) into the current repo.

.DESCRIPTION
  Copies hooks/pre-commit + hooks/pre-push into .git/hooks/ (or whichever
  hooksPath git is configured with). Marks them executable. Idempotent —
  safe to re-run after upstream updates.

  Run from any path inside the repo. Run again after pulling new hook versions.

.PARAMETER Force
  Overwrite existing hooks of the same name without prompting.
#>
[CmdletBinding()]
param([switch]$Force)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (& git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0) {
  Write-Error 'Not inside a git working tree.'
}

$hooksPath = (& git config --get core.hooksPath 2>$null)
if (-not $hooksPath) { $hooksPath = '.git/hooks' }
$hooksDir = if ([System.IO.Path]::IsPathRooted($hooksPath)) {
  $hooksPath
} else {
  Join-Path $repoRoot $hooksPath
}
New-Item -ItemType Directory -Force -Path $hooksDir | Out-Null

$src = Join-Path $repoRoot 'hooks'
if (-not (Test-Path $src)) {
  Write-Error "Source hooks directory not found at $src"
}

foreach ($name in 'pre-commit', 'pre-push') {
  $from = Join-Path $src $name
  $to = Join-Path $hooksDir $name
  if (-not (Test-Path $from)) { continue }
  if ((Test-Path $to) -and -not $Force) {
    $existing = Get-Content -LiteralPath $to -Raw -ErrorAction SilentlyContinue
    $incoming = Get-Content -LiteralPath $from -Raw
    if ($existing -eq $incoming) {
      Write-Host "context-economy: $name already up to date." -ForegroundColor DarkGray
      continue
    }
    Write-Host "context-economy: $name exists and differs — re-run with -Force to overwrite." -ForegroundColor Yellow
    continue
  }
  Copy-Item -LiteralPath $from -Destination $to -Force
  if ($IsLinux -or $IsMacOS) {
    & chmod +x $to
  }
  Write-Host "context-economy: installed $name -> $to" -ForegroundColor Green
}

# Layer 1 — Claude Code project settings (copy template if absent).
$claudeSettingsDest = Join-Path $repoRoot '.claude/settings.json'
$claudeSettingsSrc = Join-Path $repoRoot '.claude/settings.json.example'
if ((Test-Path $claudeSettingsSrc) -and (-not (Test-Path $claudeSettingsDest) -or $Force)) {
  New-Item -ItemType Directory -Force -Path (Split-Path $claudeSettingsDest) | Out-Null
  Copy-Item -LiteralPath $claudeSettingsSrc -Destination $claudeSettingsDest -Force
  Write-Host "context-economy: installed .claude/settings.json (Layer 1 hook)" -ForegroundColor Green
} elseif (Test-Path $claudeSettingsDest) {
  Write-Host "context-economy: .claude/settings.json already exists — leaving untouched (re-run with -Force to overwrite)." -ForegroundColor DarkGray
}

Write-Host ''
Write-Host 'Done. Hooks active on next git commit / git push / Claude Code edit.' -ForegroundColor Green
Write-Host 'Bypass (use sparingly): SKIP_CONTEXT_ECONOMY=1 git commit ...' -ForegroundColor DarkGray
