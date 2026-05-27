#!/usr/bin/env pwsh
<#
.SYNOPSIS  ginee compliance — PreToolUse hook on Edit / Write / MultiEdit
           against SA-owned artefact paths (#182 content axis).
.DESCRIPTION  Hard gate. Blocks (exit 2 + stderr) when:
              - tool_name in (Edit, Write, MultiEdit)
              - target file resolves to an SA-owned path per
                `local/framework.config.yaml` (architecture-doc · adr-directory ·
                diagrams-directory) OR canonical paths (local/requirements.md ·
                local/asr-utility-tree.md)
              - post-edit content carries verifiable implementation-rendering
                patterns:
                  - `<file>:<line>` citations into the working tree
                  - commit SHAs in evidence context (`as of <sha>` / `prior to <sha>`
                    / `since <sha>` / `at commit <sha>`)
              Per `core/roles/solution-architect.md § Forbidden actions §
              Content depth-bound rules` + `core/templates/phase-report.md §
              SA-artefact content self-lint`.
              Adopter-identifier detection deliberately omitted — pattern-matching
              adopter function / member names is brittle outside controlled
              vocabularies; soft-force via self-lint is the floor for that
              category, per playbook [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135).
.PARAMETER TestInput  Test-only: pass JSON instead of reading stdin.
.PARAMETER RepoRoot   Test-only: override repo root detection.
.PARAMETER ConfigFile Test-only: override path to local/framework.config.yaml.
#>
[CmdletBinding()]
param(
  [string]$TestInput,
  [string]$RepoRoot,
  [string]$ConfigFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:SKIP_GINEE_COMPLIANCE -eq '1') { exit 0 }

function Read-Payload {
  param([string]$TestInput)
  if ($TestInput) { return $TestInput }
  try { return [Console]::In.ReadToEnd() } catch { return '' }
}

function Get-RepoRoot {
  param([string]$Override)
  if ($Override) { return $Override }
  $root = & git rev-parse --show-toplevel 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $root) { return $null }
  return $root.Trim()
}

function Test-OptOut {
  param([string]$Root, [string]$TacticId)
  $config = Join-Path $Root 'local/framework.config.yaml'
  if (-not (Test-Path -LiteralPath $config)) { return $false }
  $body = Get-Content -Raw -LiteralPath $config
  if (-not $body) { return $false }
  if ($body -notmatch '(?m)^compliance:\s*$') { return $false }
  $pattern = "(?m)^\s+-\s+$([regex]::Escape($TacticId))\s*$"
  return ($body -match $pattern)
}

function Get-SAOwnedPathTable {
  param([string]$Root, [string]$ConfigOverride)
  $paths = @{}
  # Always-included canonical paths (created by the classical-architect migration).
  $paths['local/requirements.md'] = $true
  $paths['local/asr-utility-tree.md'] = $true
  # Read configured paths if present.
  $cfgPath = $ConfigOverride
  if (-not $cfgPath) {
    $cfgPath = Join-Path $Root 'local/framework.config.yaml'
  }
  if (-not (Test-Path -LiteralPath $cfgPath)) { return $paths }
  $body = Get-Content -Raw -LiteralPath $cfgPath
  if (-not $body) { return $paths }
  foreach ($key in @('architecture-doc','adr-directory','diagrams-directory')) {
    $rx = "(?m)^\s*$([regex]::Escape($key))\s*:\s*(.+?)\s*$"
    if ($body -match $rx) {
      $v = $matches[1].Trim().Trim('"').Trim("'")
      if ($v -and $v -ne 'null' -and $v -ne '~') {
        $paths[($v -replace '\\','/')] = $true
      }
    }
  }
  return $paths
}

function Test-SAOwnedPath {
  param([string]$RelPath, [hashtable]$OwnedPaths)
  if (-not $RelPath) { return $false }
  $n = ($RelPath -replace '\\','/')
  foreach ($k in $OwnedPaths.Keys) {
    $kn = ($k -replace '\\','/').TrimEnd('/')
    if ($n -ieq $kn) { return $true }
    if ($n -like "$kn/*") { return $true }
  }
  # Heuristic fallback when local/framework.config.yaml is absent —
  # canonical adopter paths produced by the discovery flow.
  if ($n -match '(?i)(^|/)adr/' -and $n -match '\.md$') { return $true }
  if ($n -match '(?i)(^|/)architecture\.md$') { return $true }
  return $false
}

function Get-FileLineCitationList {
  param([string]$Content)
  if (-not $Content) { return @() }
  # `<file>.<ext>:<line>` — common source extensions; word-bounded.
  $rx = '(?im)\b([\w./-]+\.(?:ts|tsx|js|jsx|py|cs|go|java|rb|rs|cpp|c|h|hpp|swift|kt|m|mm|scala|php|sh|ps1|psm1|sql|html|css|scss|sass|less|vue|svelte|tf|hcl|yaml|yml|toml|ini|env|conf|md|mdx)):(\d+)\b'
  $hits = @()
  foreach ($m in [regex]::Matches($Content, $rx)) {
    $hits += "$($m.Groups[1].Value):$($m.Groups[3].Value)"
  }
  return $hits
}

function Get-CommitShaEvidence {
  param([string]$Content)
  if (-not $Content) { return @() }
  # `as of <sha>` / `prior to <sha>` / `since <sha>` / `at commit <sha>` / `commit <sha>` / `revision <sha>` / `rev <sha>`
  # SHA is 7+ hex chars. Case-insensitive lead phrase; hex case-sensitive lowercase preferred but allow both.
  $rx = '(?im)\b(?:as\s+of|prior\s+to|since|at\s+commit|at\s+sha|commit|revision|rev)\s+([0-9a-f]{7,40})\b'
  $hits = @()
  foreach ($m in [regex]::Matches($Content, $rx)) {
    $hits += $m.Groups[1].Value
  }
  return $hits
}

function Write-Block {
  param([string]$Rule, [string]$Detail, [string]$Remediation)
  [Console]::Error.WriteLine("[ginee:gate] $Rule — $Detail")
  [Console]::Error.WriteLine("  Remediation: $Remediation")
  [Console]::Error.WriteLine("  Bypass (emergency): SKIP_GINEE_COMPLIANCE=1")
  [Console]::Error.WriteLine("  Opt out repo-wide: local/framework.config.yaml § compliance.disabled: [pretooluse-sa-artefact-hook]")
  exit 2
}

# --- Main ---
try {

$raw = Read-Payload -TestInput $TestInput
if (-not $raw) { exit 0 }

try {
  $payload = $raw | ConvertFrom-Json -ErrorAction Stop
} catch {
  exit 0
}

$toolName = [string]$payload.tool_name
if ($toolName -notin @('Edit','Write','MultiEdit')) { exit 0 }

$root = Get-RepoRoot -Override $RepoRoot
if (-not $root) { exit 0 }
if (Test-OptOut -Root $root -TacticId 'pretooluse-sa-artefact-hook') { exit 0 }

$ti = $payload.tool_input
if (-not $ti) { exit 0 }
$filePath = $ti.file_path
if (-not $filePath) { exit 0 }

# Resolve absolute → repo-relative
$relPath = $filePath
if ([System.IO.Path]::IsPathRooted($filePath)) {
  try {
    $resolved = (Resolve-Path -LiteralPath $filePath -ErrorAction Stop).Path
    $rootResolved = (Resolve-Path -LiteralPath $root -ErrorAction Stop).Path
    if ($resolved.StartsWith($rootResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
      $relPath = $resolved.Substring($rootResolved.Length).TrimStart('\','/')
    }
  } catch {
    $null = $_
  }
}
$relPath = $relPath -replace '\\','/'

$ownedPaths = Get-SAOwnedPathTable -Root $root -ConfigOverride $ConfigFile
if (-not (Test-SAOwnedPath -RelPath $relPath -OwnedPaths $ownedPaths)) { exit 0 }

# Compose proposed post-edit content
$oldContent = ''
$newContent = ''
if ($toolName -eq 'Write') {
  $newContent = if ($ti.PSObject.Properties.Name -contains 'content') { [string]$ti.content } else { '' }
  if (Test-Path -LiteralPath $filePath) {
    $oldContent = Get-Content -Raw -LiteralPath $filePath
  }
} elseif ($toolName -eq 'Edit') {
  $oldStr = [string]$ti.old_string
  $newStr = [string]$ti.new_string
  if (Test-Path -LiteralPath $filePath) {
    $oldContent = Get-Content -Raw -LiteralPath $filePath
    $newContent = $oldContent.Replace($oldStr, $newStr)
  } else {
    $newContent = $newStr
  }
} elseif ($toolName -eq 'MultiEdit') {
  if (Test-Path -LiteralPath $filePath) {
    $oldContent = Get-Content -Raw -LiteralPath $filePath
    $newContent = $oldContent
  }
  foreach ($e in $ti.edits) {
    $newContent = $newContent.Replace([string]$e.old_string, [string]$e.new_string)
  }
}

# Compute the added body (newContent minus oldContent lines) to scope the lint
# to the diff — existing legacy violations don't block new edits.
$addedBody = ''
if ($oldContent -and $newContent) {
  $oldLines = @($oldContent -split "`r?`n")
  $newLines = @($newContent -split "`r?`n")
  $addedBody = (@($newLines | Where-Object { $_ -and ($_ -notin $oldLines) })) -join "`n"
} elseif ($newContent) {
  $addedBody = $newContent
}

# --- Violation 1: file:line citation into the working tree ---
$citations = @(Get-FileLineCitationList -Content $addedBody)
if ($citations.Count -gt 0) {
  $sample = ($citations | Select-Object -First 3) -join ', '
  Write-Block `
    -Rule 'SA-artefact implementation rendering — <file>:<line> citation (#182)' `
    -Detail "$relPath would introduce $($citations.Count) line-numbered citation(s) into the working tree (sample: $sample). SA-owned artefacts MUST NOT cite line numbers." `
    -Remediation 'Replace with architectural-mechanism phrasing (cite the mechanism + rationale rooted in NFR / constraint, not the code site) OR move the content to an engineer-owned per-tier doc via `## Next dispatch needed`. Full check schema: `core/templates/phase-report.md § SA-artefact content self-lint`.'
}

# --- Violation 2: commit SHA in evidence context ---
$shas = @(Get-CommitShaEvidence -Content $addedBody)
if ($shas.Count -gt 0) {
  $sample = ($shas | Select-Object -First 3) -join ', '
  Write-Block `
    -Rule 'SA-artefact implementation rendering — commit SHA as evidence (#182)' `
    -Detail "$relPath would cite $($shas.Count) commit SHA(s) as evidence (sample: $sample). SA-owned artefacts MUST NOT cite commit SHAs." `
    -Remediation 'Commit SHAs belong in PR descriptions (`core/templates/pr-description.md`), not SA artefacts. Replace with mechanism + rationale, or move to engineer-owned doc.'
}

exit 0

} catch {
  $null = $_
  exit 0
}
