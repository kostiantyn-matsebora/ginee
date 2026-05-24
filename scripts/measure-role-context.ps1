#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Measure per-role framework context cost.

.DESCRIPTION
  For each cardinal role under core/roles/<role>.md, simulates a "first
  dispatch" load and reports the bytes + lines + approximate tokens the role
  would consume on activation, counting only framework files (core/).

  Load set per role:
    1. Always-loaded common: core/process.md
    2. The role kernel itself: core/roles/<role>.md
    3. Phase-participation files: core/process/phase-<N>-*.md for each N in
       the kernel's `phase-participation:` frontmatter list.
    4. Orchestration (team-lead only): core/process/dispatch.md.

  Excludes (load-on-demand or out-of-scope):
    - core/roles/<role>.details.md (load-on-demand sidecar)
    - core/protocols/*.md, core/automatic-mode.md, etc. (load-on-demand specs)
    - local/* (per-project state — not framework cost)
    - Citations from role-kernel body (counted only if always-loaded).

  Token estimate = bytes / 4 (tiktoken approximation for English markdown).
  Useful for ranking + regression detection; not a substitute for real
  tokenisation when absolute counts matter.

.PARAMETER Json
  Emit JSON to stdout instead of a human-readable table.

.PARAMETER RepoRoot
  Explicit repo root. Default: git rev-parse --show-toplevel from cwd.

.OUTPUTS
  Exit code 0 always (informational; gating happens in the Pester test).
#>
[CmdletBinding()]
param(
  [switch]$Json,
  [string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ----- Helpers ------------------------------------------------------------

function Resolve-RepoRoot {
  param([string]$Hint)
  if ($Hint) {
    if (-not (Test-Path -LiteralPath $Hint)) { throw "RepoRoot path does not exist: $Hint" }
    return (Resolve-Path -LiteralPath $Hint).Path
  }
  $top = & git rev-parse --show-toplevel 2>$null
  if ($LASTEXITCODE -ne 0) { throw "Not inside a git working tree (cwd: $(Get-Location))." }
  return $top
}

function Get-FrontmatterField {
  param([string]$Content, [string]$Field)
  if ($Content -match '(?ms)^---\s*\r?\n(.*?)\r?\n---') {
    $fm = $matches[1]
    if ($fm -match "(?m)^${Field}:\s*(.+?)\s*$") {
      return $matches[1].Trim()
    }
  }
  return $null
}

function Get-PhaseParticipation {
  param([string]$KernelPath)
  $content = Get-Content -LiteralPath $KernelPath -Raw -Encoding UTF8
  $val = Get-FrontmatterField -Content $content -Field 'phase-participation'
  if (-not $val) { return @() }
  # Strip trailing comment if any.
  $val = ($val -split '#', 2)[0].Trim()
  if ($val -match '^\[\s*\]\s*$') { return @() }
  if ($val -match '^\[\s*(.+?)\s*\]\s*$') {
    $inner = $matches[1]
    return @(($inner -split ',') | Where-Object { $_.Trim() } | ForEach-Object { [int]($_.Trim()) })
  }
  return @()
}

function Get-FileMetrics {
  param([string]$Path)
  $item = Get-Item -LiteralPath $Path
  $lines = (Get-Content -LiteralPath $Path -Encoding UTF8 | Measure-Object).Count
  return @{ Bytes = [int64]$item.Length; Lines = [int]$lines }
}

function Measure-Role {
  param([string]$RepoRoot, [string]$RoleName)

  $kernelPath = Join-Path $RepoRoot "core/roles/$RoleName.md"
  if (-not (Test-Path -LiteralPath $kernelPath)) { throw "Role kernel not found: $kernelPath" }

  $files = [System.Collections.ArrayList]::new()

  # Always-loaded common.
  $processMd = Join-Path $RepoRoot 'core/process.md'
  $m = Get-FileMetrics -Path $processMd
  $null = $files.Add([PSCustomObject]@{ Path = 'core/process.md'; Bytes = $m.Bytes; Lines = $m.Lines; Reason = 'always-loaded common' })

  # Role kernel.
  $m = Get-FileMetrics -Path $kernelPath
  $null = $files.Add([PSCustomObject]@{ Path = "core/roles/$RoleName.md"; Bytes = $m.Bytes; Lines = $m.Lines; Reason = 'role kernel' })

  # Phase-participation files.
  $phases = Get-PhaseParticipation -KernelPath $kernelPath
  foreach ($n in $phases) {
    $glob = Join-Path $RepoRoot "core/process/phase-$n-*.md"
    $phaseFiles = @(Get-ChildItem -Path $glob -ErrorAction SilentlyContinue)
    foreach ($pf in $phaseFiles) {
      $rel = ($pf.FullName.Substring($RepoRoot.Length).TrimStart('\', '/')) -replace '\\', '/'
      $pm = Get-FileMetrics -Path $pf.FullName
      $null = $files.Add([PSCustomObject]@{ Path = $rel; Bytes = $pm.Bytes; Lines = $pm.Lines; Reason = "phase-$n" })
    }
  }

  # Orchestration (team-lead only).
  if ($RoleName -eq 'team-lead') {
    $dispatchMd = Join-Path $RepoRoot 'core/process/dispatch.md'
    if (Test-Path -LiteralPath $dispatchMd) {
      $m = Get-FileMetrics -Path $dispatchMd
      $null = $files.Add([PSCustomObject]@{ Path = 'core/process/dispatch.md'; Bytes = $m.Bytes; Lines = $m.Lines; Reason = 'orchestration (team-lead only)' })
    }
  }

  $totalBytes = [int64](($files | Measure-Object -Property Bytes -Sum).Sum)
  $totalLines = [int](($files | Measure-Object -Property Lines -Sum).Sum)
  $totalTokens = [int][math]::Round($totalBytes / 4.0)

  # Typed arrays force JSON serialization to '[]' instead of 'null' for empty.
  $phasesTyped = [int[]]@($phases)
  $filesTyped = [object[]]@($files)

  return [PSCustomObject]@{
    Role              = $RoleName
    Phases            = $phasesTyped
    Files             = $filesTyped
    TotalFiles        = $files.Count
    TotalBytes        = $totalBytes
    TotalLines        = $totalLines
    TotalTokensApprox = $totalTokens
  }
}

# ----- Main ---------------------------------------------------------------

$root = Resolve-RepoRoot -Hint $RepoRoot
$rolesDir = Join-Path $root 'core/roles'

$roles = @(Get-ChildItem -Path $rolesDir -Filter '*.md' |
  Where-Object { $_.Name -notlike '*.details.md' } |
  ForEach-Object { $_.BaseName } |
  Sort-Object)

$results = @($roles | ForEach-Object { Measure-Role -RepoRoot $root -RoleName $_ })

if ($Json) {
  $results | ConvertTo-Json -Depth 6
  return
}

# Human-readable table.
$fmt = "{0,-22} {1,-22} {2,6} {3,10} {4,11}"
Write-Output ($fmt -f 'Role', 'Phases', 'Files', 'Bytes', '~Tokens')
Write-Output ('-' * 75)
$sorted = $results | Sort-Object -Property TotalBytes
foreach ($r in $sorted) {
  $phaseArr = @($r.Phases)
  $phaseStr = if ($phaseArr.Count -eq 0) { '[]' } else { '[' + ($phaseArr -join ',') + ']' }
  Write-Output ($fmt -f $r.Role, $phaseStr, $r.TotalFiles, ('{0:N0}' -f $r.TotalBytes), ('{0:N0}' -f $r.TotalTokensApprox))
}
Write-Output ''
Write-Output 'Token estimate: bytes / 4 (tiktoken English-markdown approximation).'
Write-Output 'Includes: role kernel + core/process.md + phase-participation files + (team-lead) dispatch.md.'
Write-Output 'Excludes: load-on-demand specs, role .details.md, local/*, citations.'
