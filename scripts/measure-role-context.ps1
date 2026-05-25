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
    - core/protocols/*.md, core/protocols/automatic-mode.md, etc. (load-on-demand specs)
    - local/* (per-project state — not framework cost)
    - Citations from role-kernel body (counted only if always-loaded).

  Token estimate = bytes / 4 (tiktoken approximation for English markdown).
  Useful for ranking + regression detection; not a substitute for real
  tokenisation when absolute counts matter.

.PARAMETER Json
  Emit JSON to stdout instead of a human-readable table.

.PARAMETER RepoRoot
  Explicit repo root. Default: git rev-parse --show-toplevel from cwd.

.PARAMETER UpdateDoc
  Regenerate the auto-generated measurement section in
  docs/reference/CONTEXT_COSTS.md (between BEGIN/END sentinel markers).

.PARAMETER CheckDoc
  Verify docs/reference/CONTEXT_COSTS.md is up to date with current
  measurements. Exits 1 with a diff hint if stale; 0 otherwise.

.OUTPUTS
  Exit code:
    0 — table output, JSON output, or -UpdateDoc succeeded
    0 — -CheckDoc: doc is current
    1 — -CheckDoc: doc is stale (run with -UpdateDoc to refresh)
#>
[CmdletBinding(DefaultParameterSetName = 'Report')]
param(
  [Parameter(ParameterSetName = 'Report')]
  [switch]$Json,

  [Parameter(ParameterSetName = 'UpdateDoc')]
  [switch]$UpdateDoc,

  [Parameter(ParameterSetName = 'CheckDoc')]
  [switch]$CheckDoc,

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

function Get-FileMetric {
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
  $m = Get-FileMetric -Path $processMd
  $null = $files.Add([PSCustomObject]@{ Path = 'core/process.md'; Bytes = $m.Bytes; Lines = $m.Lines; Reason = 'always-loaded common' })

  # Role kernel.
  $m = Get-FileMetric -Path $kernelPath
  $null = $files.Add([PSCustomObject]@{ Path = "core/roles/$RoleName.md"; Bytes = $m.Bytes; Lines = $m.Lines; Reason = 'role kernel' })

  # Phase-participation files.
  $phases = Get-PhaseParticipation -KernelPath $kernelPath
  foreach ($n in $phases) {
    $glob = Join-Path $RepoRoot "core/process/phase-$n-*.md"
    $phaseFiles = @(Get-ChildItem -Path $glob -ErrorAction SilentlyContinue)
    foreach ($pf in $phaseFiles) {
      $rel = ($pf.FullName.Substring($RepoRoot.Length).TrimStart('\', '/')) -replace '\\', '/'
      $pm = Get-FileMetric -Path $pf.FullName
      $null = $files.Add([PSCustomObject]@{ Path = $rel; Bytes = $pm.Bytes; Lines = $pm.Lines; Reason = "phase-$n" })
    }
  }

  # Orchestration (team-lead only).
  if ($RoleName -eq 'team-lead') {
    $dispatchMd = Join-Path $RepoRoot 'core/process/dispatch.md'
    if (Test-Path -LiteralPath $dispatchMd) {
      $m = Get-FileMetric -Path $dispatchMd
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

# ----- Doc generation -----------------------------------------------------

$Script:DocBeginMarker = '<!-- BEGIN: auto-generated by scripts/measure-role-context.ps1 - do not edit by hand -->'
$Script:DocEndMarker = '<!-- END: auto-generated by scripts/measure-role-context.ps1 -->'

function Read-TemplateFile {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { throw "Template not found: $Path" }
  # Strip the leading <!-- ... --> comment block (template documentation) so it
  # doesn't bleed into rendered output. The comment occupies the file's first
  # block only.
  $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  $stripped = [regex]::Replace($raw, '(?s)\A<!--.*?-->\s*\n', '')
  # Normalize CRLF -> LF; trim trailing newline added by editors so the row
  # template can be joined cleanly.
  return ($stripped -replace "`r`n", "`n").TrimEnd("`n")
}

function Format-PhaseExpr {
  param([object]$Role)
  $phaseArr = @($Role.Phases)
  if ($phaseArr.Count -eq 0) { return '`[]`' }
  if ($Role.Role -eq 'team-lead') { return '`[1..8]` + `dispatch.md`' }
  return '`[' + ($phaseArr -join ', ') + ']`'
}

function Get-RoleCeiling {
  param([string]$TemplatesDir)
  $path = Join-Path $TemplatesDir 'role-context-ceilings.json'
  if (-not (Test-Path -LiteralPath $path)) { throw "Ceilings file not found: $path" }
  $json = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
  return $json.ceilings
}

function Format-DocFragment {
  param(
    [object[]]$Results,
    [string]$Version,
    [string]$TemplatesDir
  )
  $snapshotTmpl = Read-TemplateFile -Path (Join-Path $TemplatesDir 'context-costs-snapshot.md.tmpl')
  $rowTmpl = Read-TemplateFile -Path (Join-Path $TemplatesDir 'context-costs-row.md.tmpl')
  $ceilRowTmpl = Read-TemplateFile -Path (Join-Path $TemplatesDir 'context-costs-ceilings-row.md.tmpl')
  $ceilings = Get-RoleCeiling -TemplatesDir $TemplatesDir

  $sorted = $Results | Sort-Object -Property TotalBytes

  # Measurement rows.
  $rows = [System.Collections.ArrayList]::new()
  foreach ($r in $sorted) {
    $row = $rowTmpl
    $row = $row.Replace('{{ROLE}}', $r.Role)
    $row = $row.Replace('{{PHASES}}', (Format-PhaseExpr -Role $r))
    $row = $row.Replace('{{FILES}}', $r.TotalFiles.ToString())
    $row = $row.Replace('{{BYTES}}', ('{0:N0}' -f $r.TotalBytes))
    $row = $row.Replace('{{TOKENS}}', ('{0:N0}' -f $r.TotalTokensApprox))
    $null = $rows.Add($row)
  }

  # Ceiling rows.
  $ceilRows = [System.Collections.ArrayList]::new()
  foreach ($r in $sorted) {
    $cap = $ceilings.($r.Role)
    if ($null -eq $cap) { throw "No ceiling declared for role '$($r.Role)' in role-context-ceilings.json" }
    $headroomPct = [math]::Round((($cap - $r.TotalBytes) / [double]$cap) * 100)
    $row = $ceilRowTmpl
    $row = $row.Replace('{{ROLE}}', $r.Role)
    $row = $row.Replace('{{CEILING}}', ('{0:N0}' -f $cap))
    $row = $row.Replace('{{CURRENT}}', ('{0:N0}' -f $r.TotalBytes))
    $row = $row.Replace('{{HEADROOM_PCT}}', $headroomPct.ToString())
    $null = $ceilRows.Add($row)
  }

  $body = $snapshotTmpl
  $body = $body.Replace('{{VERSION}}', $Version)
  $body = $body.Replace('{{ROWS}}', ($rows -join "`n"))
  $body = $body.Replace('{{CEILING_ROWS}}', ($ceilRows -join "`n"))

  # Wrap in sentinel markers. Use LF (matches repo convention; avoids CRLF on Windows
  # breaking -CheckDoc cross-platform).
  return ($Script:DocBeginMarker + "`n`n" + $body.TrimEnd("`n") + "`n`n" + $Script:DocEndMarker)
}

function Get-DocWithFragment {
  param([string]$DocPath, [string]$Fragment)
  if (-not (Test-Path -LiteralPath $DocPath)) { throw "Doc not found: $DocPath" }
  $orig = Get-Content -LiteralPath $DocPath -Raw -Encoding UTF8
  $pattern = [regex]::Escape($Script:DocBeginMarker) + '.*?' + [regex]::Escape($Script:DocEndMarker)
  $regex = [regex]::new($pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if (-not $regex.IsMatch($orig)) {
    throw "Sentinel markers not found in $DocPath. Expected '$($Script:DocBeginMarker)' ... '$($Script:DocEndMarker)'."
  }
  # Use callback-form Replace to avoid regex-substitution-token interpretation of
  # '$' / backreferences in $Fragment (markdown can contain '$'). The $m callback
  # parameter is required by the Regex.Replace API but intentionally unused.
  $captured = $Fragment
  $new = $regex.Replace($orig, { param($m) $null = $m; $captured })
  return @{ Original = $orig; Updated = $new; Changed = ($orig -ne $new) }
}

function Get-DocCurrentFragment {
  param([string]$DocPath)
  if (-not (Test-Path -LiteralPath $DocPath)) { throw "Doc not found: $DocPath" }
  $content = Get-Content -LiteralPath $DocPath -Raw -Encoding UTF8
  # Normalize CRLF -> LF so the comparison is line-ending-agnostic.
  $content = $content -replace "`r`n", "`n"
  $pattern = [regex]::Escape($Script:DocBeginMarker) + '.*?' + [regex]::Escape($Script:DocEndMarker)
  $regex = [regex]::new($pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
  $m = $regex.Match($content)
  if (-not $m.Success) {
    throw "Sentinel markers not found in $DocPath."
  }
  return $m.Value
}

# ----- Main ---------------------------------------------------------------

$root = Resolve-RepoRoot -Hint $RepoRoot
$rolesDir = Join-Path $root 'core/roles'
$versionPath = Join-Path $root 'core/VERSION'
$docPath = Join-Path $root 'docs/reference/CONTEXT_COSTS.md'
$templatesDir = Join-Path $root 'scripts/templates'

$version = if (Test-Path -LiteralPath $versionPath) {
  (Get-Content -LiteralPath $versionPath -Raw -Encoding UTF8).Trim()
}
else { 'unknown' }

$roles = @(Get-ChildItem -Path $rolesDir -Filter '*.md' |
  Where-Object { $_.Name -notlike '*.details.md' } |
  ForEach-Object { $_.BaseName } |
  Sort-Object)

$results = @($roles | ForEach-Object { Measure-Role -RepoRoot $root -RoleName $_ })

if ($UpdateDoc) {
  $fragment = Format-DocFragment -Results $results -Version $version -TemplatesDir $templatesDir
  $result = Get-DocWithFragment -DocPath $docPath -Fragment $fragment
  if ($result.Changed) {
    Set-Content -LiteralPath $docPath -Value $result.Updated -Encoding UTF8 -NoNewline
    Write-Output "Updated: $docPath"
  }
  else {
    Write-Output "No change: $docPath already current"
  }
  return
}

if ($CheckDoc) {
  $fragment = Format-DocFragment -Results $results -Version $version -TemplatesDir $templatesDir
  $current = Get-DocCurrentFragment -DocPath $docPath
  if ($current.Trim() -eq $fragment.Trim()) {
    Write-Output "OK: $docPath is current"
    exit 0
  }
  else {
    Write-Output "STALE: $docPath does not match current measurements."
    Write-Output "Run: pwsh -File scripts/measure-role-context.ps1 -UpdateDoc"
    Write-Output ''
    Write-Output '--- expected (current measurement) ---'
    Write-Output $fragment
    Write-Output '--- found in doc ---'
    Write-Output $current
    exit 1
  }
}

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
