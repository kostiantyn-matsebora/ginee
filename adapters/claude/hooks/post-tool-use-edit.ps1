#!/usr/bin/env pwsh
<#
.SYNOPSIS
  ginee compliance — PostToolUse self-check reminder (playbook #135 T6 / #142).
.DESCRIPTION
  Reads PostToolUse JSON from stdin; on Edit / Write / MultiEdit success
  targeting `core/**`, emits a ≤ 6-line `[ginee:self-check]` reminder via
  hookSpecificOutput.additionalContext.

  Coexists with `scripts/context-economy-check.ps1` (same matcher) — both
  attach to the same PostToolUse list; the structural gate fires first
  (structural-lint output), the self-check follows (LLM-facing reminder).

  Path-aware: only fires on edits whose resolved file path begins with `core/`.
  Skips `tests/**`, `local/**`, `adapters/**`, `extras/**`, `migrations/**`.

  Hook never blocks. Fail-open on every error path.

.PARAMETER TestInput  Test-only: pass JSON instead of reading stdin.
.PARAMETER RepoRoot   Test-only: override repo root detection.
#>
[CmdletBinding()]
param(
  [string]$TestInput,
  [string]$RepoRoot
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

function Get-RelPath {
  param([string]$FilePath, [string]$Root)
  if (-not $FilePath) { return '' }
  if ([System.IO.Path]::IsPathRooted($FilePath)) {
    try {
      $resolved = (Resolve-Path -LiteralPath $FilePath -ErrorAction Stop).Path
      $rootResolved = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).Path
      if ($resolved.StartsWith($rootResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
        return ($resolved.Substring($rootResolved.Length).TrimStart('\','/') -replace '\\','/')
      }
    } catch { $null = $_ }
  }
  return ($FilePath -replace '\\','/')
}

function Test-IsAlwaysLoaded {
  param([string]$RelPath)
  if ($RelPath -eq 'core/process.md') { return $true }
  if ($RelPath -match '^core/roles/[^/]+\.details\.md$') { return $false }
  if ($RelPath -match '^core/roles/[^/]+\.md$') { return $true }
  return $false
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

$toolName = $payload.tool_name
if ($toolName -notin @('Edit','Write','MultiEdit')) { exit 0 }

$root = Get-RepoRoot -Override $RepoRoot
if (-not $root) { exit 0 }

if (Test-OptOut -Root $root -TacticId 'posttooluse-edit-hook') { exit 0 }

$ti = $payload.tool_input
if (-not $ti) { exit 0 }
$rel = Get-RelPath -FilePath ([string]$ti.file_path) -Root $root
if (-not $rel) { exit 0 }

# Path gate — only fires on core/** edits.
if ($rel -notmatch '^core/') { exit 0 }

# Compose a ≤ 6-line self-check reminder. The set was chosen so the reminder
# stays useful even when the structural gate (context-economy-check.ps1) and
# the action-time gate (pre-tool-use-edit.ps1) have already passed.
$lines = @(
  "[ginee:self-check] You just edited $rel. Verify before continuing:",
  "- frontmatter present + valid (hot-spec contract: core/protocols/hot-spec-format.md)",
  "- size <= cap-bytes; if exceeded, dispatch ai-engineer + commit with Optimized-By: ai-engineer trailer",
  "- runtime surface stayed D-free (no bare D<N> tokens introduced — PLAN.md only)",
  "- lossless invariant: every prior rule survives byte-for-byte"
)
if (Test-IsAlwaysLoaded -RelPath $rel) {
  $lines += "- always-loaded surface: consider whether an ai-engineer optimization pass is needed before merge"
}

$body = $lines -join "`n"

$output = @{
  hookSpecificOutput = @{
    hookEventName     = 'PostToolUse'
    additionalContext = $body
  }
} | ConvertTo-Json -Depth 5 -Compress

[Console]::Out.WriteLine($output)
exit 0

} catch {
  $null = $_
  exit 0
}
