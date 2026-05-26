#!/usr/bin/env pwsh
<#
.SYNOPSIS
  ginee installer hook — idempotently merge T2 / T3 PreToolUse hooks and T4
  statusLine into the adopter's .claude/settings.json.

.DESCRIPTION
  Invoked from install.ps1 (claude adapter branch) after pointer subagents +
  skills are copied. Wires the compliance playbook (#135) entries that live
  on the adopter side:

    - statusLine    (T4 / #140) — `adapters/claude/statusline.ps1`
    - PreToolUse    (T2 / #138) — `Edit|Write|MultiEdit` matcher
    - PreToolUse    (T3 / #139) — `Bash` matcher

  Adopter customisations are preserved:
    - `statusLine.command` already set to a non-ginee value → left alone.
    - PreToolUse entries identified by command-string substring matching the
      ginee hook path; existing matches are not duplicated.
    - All other settings.json keys (env, theme, permissions, etc.) untouched.

  Re-running on an already-wired settings.json is a no-op.

.PARAMETER Target
  Adopter project root (the directory containing .claude/).

.PARAMETER FrameworkRel
  Relative path from project root to the ginee framework root.
  Default: `.agents/ginee`.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Target,
  [string]$FrameworkRel = '.agents/ginee'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$claudeDir   = Join-Path $Target '.claude'
$settingsPath = Join-Path $claudeDir 'settings.json'

# Compose canonical ginee commands (with target paths relative to project root,
# matching the form adopters' Claude Code sessions will execute).
$editHookCmd   = "pwsh -NoProfile -File $FrameworkRel/adapters/claude/hooks/pre-tool-use-edit.ps1"
$bashHookCmd   = "pwsh -NoProfile -File $FrameworkRel/adapters/claude/hooks/pre-tool-use-bash.ps1"
$statuslineCmd = "pwsh -NoProfile -File $FrameworkRel/adapters/claude/statusline.ps1"

# Marker substrings used for idempotence — anything matching is considered
# "ginee-owned" and is replaced in place rather than duplicated.
$editHookMarker   = "adapters/claude/hooks/pre-tool-use-edit"
$bashHookMarker   = "adapters/claude/hooks/pre-tool-use-bash"
$statuslineMarker = "adapters/claude/statusline"

New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null

# --- Load existing settings (or seed `{}`) ---
if (Test-Path -LiteralPath $settingsPath) {
  $raw = Get-Content -Raw -LiteralPath $settingsPath
  if (-not $raw -or -not $raw.Trim()) { $raw = '{}' }
  try {
    $settings = $raw | ConvertFrom-Json -AsHashtable -ErrorAction Stop
  } catch {
    Write-Warning "settings.json: failed to parse — leaving file untouched. Manual merge required per adapters/claude/install.md § Compliance hooks."
    return
  }
} else {
  $settings = @{}
}

# --- statusLine (T4) ---
$statusLineChanged = $false
if (-not $settings.ContainsKey('statusLine')) {
  $settings['statusLine'] = @{
    type    = 'command'
    command = $statuslineCmd
  }
  $statusLineChanged = $true
} else {
  $existingCmd = ''
  if ($settings['statusLine'] -is [hashtable] -and $settings['statusLine'].ContainsKey('command')) {
    $existingCmd = [string]$settings['statusLine']['command']
  }
  if ($existingCmd -match [regex]::Escape($statuslineMarker)) {
    # Ginee-owned — refresh command (path may change across releases).
    if ($existingCmd -ne $statuslineCmd) {
      $settings['statusLine']['command'] = $statuslineCmd
      $statusLineChanged = $true
    }
  }
  # else: adopter-customised statusLine — leave alone.
}

# --- hooks scaffolding ---
if (-not $settings.ContainsKey('hooks')) { $settings['hooks'] = @{} }
if (-not $settings['hooks'].ContainsKey('PreToolUse')) { $settings['hooks']['PreToolUse'] = @() }

# --- PreToolUse entries (T2 + T3) ---
function Test-PreToolUseEntryPresent {
  param([array]$Entries, [string]$Marker)
  foreach ($entry in $Entries) {
    if ($entry -isnot [hashtable]) { continue }
    if (-not $entry.ContainsKey('hooks')) { continue }
    foreach ($hook in $entry['hooks']) {
      if ($hook -is [hashtable] -and $hook.ContainsKey('command')) {
        if ([string]$hook['command'] -match [regex]::Escape($Marker)) { return $true }
      }
    }
  }
  return $false
}

$preToolUseEntries = @($settings['hooks']['PreToolUse'])
$preToolUseChanged = $false

if (-not (Test-PreToolUseEntryPresent -Entries $preToolUseEntries -Marker $editHookMarker)) {
  $preToolUseEntries += @{
    matcher = 'Edit|Write|MultiEdit'
    hooks   = @(@{
      type    = 'command'
      command = $editHookCmd
      timeout = 10
    })
  }
  $preToolUseChanged = $true
}

if (-not (Test-PreToolUseEntryPresent -Entries $preToolUseEntries -Marker $bashHookMarker)) {
  $preToolUseEntries += @{
    matcher = 'Bash'
    hooks   = @(@{
      type    = 'command'
      command = $bashHookCmd
      timeout = 10
    })
  }
  $preToolUseChanged = $true
}

$settings['hooks']['PreToolUse'] = $preToolUseEntries

# --- Persist if changed ---
if ($statusLineChanged -or $preToolUseChanged) {
  # PowerShell ConvertTo-Json default depth (2) is too shallow for nested hook
  # structures — set 10 to be safe.
  $json = ($settings | ConvertTo-Json -Depth 10)
  Set-Content -LiteralPath $settingsPath -Value $json -NoNewline -Encoding utf8
  Write-Host "Synced .claude/settings.json (statusLine: $statusLineChanged, PreToolUse: $preToolUseChanged)" -ForegroundColor Green
} else {
  Write-Host ".claude/settings.json already current — no change" -ForegroundColor DarkGray
}
