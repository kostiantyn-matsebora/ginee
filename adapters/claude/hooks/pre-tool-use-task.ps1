#!/usr/bin/env pwsh
<#
.SYNOPSIS  ginee compliance — PreToolUse hook on Task (Agent dispatch) (#182).
.DESCRIPTION  Hard gate. Blocks (exit 2 + stderr) when:
              - tool_name = Task
              - tool_input.subagent_type = solution-architect (or any case variant)
              - tool_input.prompt carries a Phase 4 / 5 / 6 indicator
              Per `core/roles/solution-architect.md § Three activities — at a glance`
              + `core/roles/team-lead.md § SA dispatch — Phases 4 / 5 / 6 categorically excluded`.
              Engineer-surfaced architectural delta MUST route through team-lead's
              `§ Engineer-surfaced architectural-delta gate`, never direct SA dispatch.
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

function Test-SolutionArchitectTarget {
  param($ToolInput)
  if (-not $ToolInput) { return $false }
  foreach ($k in @('subagent_type','agent','agent_name','target','recipient')) {
    if ($ToolInput.PSObject.Properties.Name -contains $k -and $ToolInput.$k) {
      $v = [string]$ToolInput.$k
      if ($v -match '(?i)\bsolution-?architect\b') { return $true }
    }
  }
  return $false
}

function Test-Phase456Indicator {
  param([string]$Prompt)
  if (-not $Prompt) { return $false }
  # Match common forms — `Phase 4`, `Phase-4`, `phase 5`, `phase-6`, `Phases 4-6`,
  # `phase4`, `Phase 4 / 5 / 6`, `phase-4-implementation`, `phase-5-testing`,
  # `phase-6-bug-fixing`. Word-boundary anchored; case-insensitive.
  # Carve-out: a *retire / exclude / refuse* mention is NOT itself a dispatch
  # context — match only when phrase suggests SA is being invoked AT that phase.
  $rx = '(?i)\b(in\s+phase|at\s+phase|during\s+phase|mid-?phase|phase[\s-]*[456]\b)|(?i)\bphase-(4|5|6)-(implementation|testing|bug-?fixing)\b'
  return ($Prompt -match $rx)
}

function Write-Block {
  param([string]$Rule, [string]$Detail, [string]$Remediation)
  [Console]::Error.WriteLine("[ginee:gate] $Rule — $Detail")
  [Console]::Error.WriteLine("  Remediation: $Remediation")
  [Console]::Error.WriteLine("  Bypass (emergency): SKIP_GINEE_COMPLIANCE=1")
  [Console]::Error.WriteLine("  Opt out repo-wide: local/framework.config.yaml § compliance.disabled: [pretooluse-task-hook]")
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
if ($toolName -ne 'Task') { exit 0 }

$root = Get-RepoRoot -Override $RepoRoot
if (-not $root) { exit 0 }
if (Test-OptOut -Root $root -TacticId 'pretooluse-task-hook') { exit 0 }

$ti = $payload.tool_input
if (-not $ti) { exit 0 }

if (-not (Test-SolutionArchitectTarget -ToolInput $ti)) { exit 0 }

$prompt = ''
foreach ($k in @('prompt','description','message','task','body')) {
  if ($ti.PSObject.Properties.Name -contains $k -and $ti.$k) {
    $prompt += "`n" + [string]$ti.$k
  }
}

if (-not (Test-Phase456Indicator -Prompt $prompt)) { exit 0 }

Write-Block `
  -Rule 'SA dispatch in Phase 4 / 5 / 6 — categorical refusal (#182)' `
  -Detail "Task to solution-architect carries a Phase 4 / 5 / 6 indicator. SA `phase-participation: [1, 2, 7]`; categorical refusal during implementation phases." `
  -Remediation 'Engineer-surfaced architectural delta routes through team-lead per `core/roles/team-lead.md § Engineer-surfaced architectural-delta gate` — surface user-gate (defer / stop + re-enter Phase 1–2). SA is dispatched only in Phase 1, 2, or conditional Phase 7 (when (a) task introduced architectural changes OR (b) Phase-1 `post-implementation-governance: yes`).'

exit 0

} catch {
  $null = $_
  exit 0
}
