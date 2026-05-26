#!/usr/bin/env pwsh
<#
.SYNOPSIS
  ginee compliance — Stop hook (playbook #135 T7 / #143).
.DESCRIPTION
  Reads Stop JSON from stdin; refuses turn-end (exit 2 + stderr) when work is
  genuinely incomplete. Block conditions (any of):

    1. transcript indicates pending TODO with `[ ]` state in a final summary
       AND no explicit user-acceptance signal earlier in the turn
    2. last cardinal-return excerpt is missing the `<!-- self-lint: pass -->`
       marker (advisory: never re-dispatch; consume + carry forward — but the
       Stop gate ensures the orchestrator at least sees the absence)
    3. a `gh pr create` was run earlier in the transcript without a subsequent
       acceptance / merge signal AND CI-watch is the configured policy
    4. an open `ginee:in-progress` GitHub issue exists on the current branch
       (detected from branch name `<n>-...` / commit messages) with no
       Phase-8 close comment posted

  Anti-loop guard: respect `stop_hook_active` payload flag. When set, exit 0
  unconditionally — the hook MUST NOT trap the LLM in an unproductive loop
  (parent #135 anti-pattern explicitly forbids this).

  Each block path emits a clear continuation message via stderr.

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

function Get-TranscriptText {
  param($Payload, [string]$Root)
  # Claude Code Stop payload includes `transcript_path`; on older versions it
  # may carry `transcript` inline. Read whichever is present; the hook never
  # raises on missing — it just degrades to fewer signals.
  $text = ''
  if ($Payload.PSObject.Properties.Name -contains 'transcript' -and $Payload.transcript) {
    $text = [string]$Payload.transcript
  } elseif ($Payload.PSObject.Properties.Name -contains 'transcript_path' -and $Payload.transcript_path) {
    $tp = [string]$Payload.transcript_path
    if (-not [System.IO.Path]::IsPathRooted($tp) -and $Root) {
      $tp = Join-Path $Root $tp
    }
    if (Test-Path -LiteralPath $tp) {
      try { $text = Get-Content -Raw -LiteralPath $tp } catch { $text = '' }
    }
  }
  return $text
}

function Write-Block {
  param([string]$Rule, [string]$Detail, [string]$Remediation)
  [Console]::Error.WriteLine("[ginee:stop-gate] $Rule — $Detail")
  [Console]::Error.WriteLine("  Remediation: $Remediation")
  [Console]::Error.WriteLine("  Bypass (emergency): SKIP_GINEE_COMPLIANCE=1")
  [Console]::Error.WriteLine("  Opt out repo-wide: local/framework.config.yaml § compliance.disabled: [stop-hook]")
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

# --- Anti-loop guard (parent #135 anti-pattern: never trap in unproductive loop) ---
if ($payload.PSObject.Properties.Name -contains 'stop_hook_active' -and $payload.stop_hook_active) {
  exit 0
}

$root = Get-RepoRoot -Override $RepoRoot
if (-not $root) { exit 0 }

if (Test-OptOut -Root $root -TacticId 'stop-hook') { exit 0 }

$transcript = Get-TranscriptText -Payload $payload -Root $root

# --- Block condition 1: cardinal return missing self-lint marker ---
# Look for the last block that looks like a dispatch return (any of the
# 6 mandatory `##` section headers from phase-report.md). If we find one,
# require the literal `<!-- self-lint: pass -->` marker after it.
if ($transcript) {
  $returnMarkers = '(?ms)## (Files touched|Decisions made|Verification log|Open issues|Next dispatch needed|Source reads)'
  $lastReturnIdx = -1
  foreach ($m in [regex]::Matches($transcript, $returnMarkers)) {
    if ($m.Index -gt $lastReturnIdx) { $lastReturnIdx = $m.Index }
  }
  if ($lastReturnIdx -ge 0) {
    $tail = $transcript.Substring($lastReturnIdx)
    if ($tail -notmatch '<!-- self-lint: pass -->') {
      Write-Block `
        -Rule 'cardinal return missing self-lint marker' `
        -Detail "The most recent specialist return omits the literal `<!-- self-lint: pass -->` tail required by core/templates/phase-report.md." `
        -Remediation 'Re-dispatch is FORBIDDEN for format alone — instead acknowledge as advisory in main thread, then continue. Re-running with this acknowledgement will pass the gate.'
    }
  }
}

# --- Block condition 3: gh pr create without acceptance signal ---
# A `gh pr create` invocation should be followed by a user acceptance signal
# (an Accept / merge / "looks good" reply). The hook is conservative: only
# blocks when create appears AND CI-watch posture in framework.config.yaml is
# `poll` (the default) AND no merge / accept signal follows.
if ($transcript -and ($transcript -match 'gh\s+pr\s+create\b')) {
  $createIdx = $transcript.LastIndexOf('gh pr create')
  if ($createIdx -ge 0) {
    $tail = $transcript.Substring($createIdx)
    $accepted = ($tail -match '(?i)(accept|merged|approve|looks\s+good|lgtm|ship\s+it)\b')
    $ciWatched = $false
    $config = Join-Path $root 'local/framework.config.yaml'
    if (Test-Path -LiteralPath $config) {
      $cfg = Get-Content -Raw -LiteralPath $config
      if ($cfg -match '(?m)^\s*ci-watch-policy:\s*poll\s*$' -or
          $cfg -notmatch '(?m)^\s*ci-watch-policy:\s*\S+\s*$') {
        $ciWatched = $true
      }
    } else {
      $ciWatched = $true  # default policy is poll
    }
    if ($ciWatched -and -not $accepted) {
      Write-Block `
        -Rule 'PR opened without CI-watch sign-off' `
        -Detail "A `gh pr create` was issued earlier this turn; default ci-watch policy is `poll` but no CI-green signal is recorded." `
        -Remediation 'Enter CI-watch per core/protocols/ci-watch.md OR explicitly hand back. To switch posture, set ci-watch-policy: async|hybrid|disabled in local/framework.config.yaml.'
    }
  }
}

# --- Block condition 4: open ginee:in-progress issue with no close comment ---
# Branch convention: `<N>-...` (e.g., `141-user-prompt-submit-hook`) → issue #N.
$branch = & git rev-parse --abbrev-ref HEAD 2>$null
if ($LASTEXITCODE -eq 0 -and $branch) {
  $branch = $branch.Trim()
  if ($branch -match '^(\d+)[-_/]') {
    $issueN = [int]$matches[1]
    # The check is best-effort + offline-safe: if `gh` is missing or unauth'd,
    # do not block. This keeps the hook usable without GitHub credentials.
    $ghPath = (Get-Command gh -ErrorAction SilentlyContinue).Source
    if ($ghPath) {
      try {
        $state = & gh issue view $issueN --json state,labels 2>$null
        if ($LASTEXITCODE -eq 0 -and $state) {
          $issue = $state | ConvertFrom-Json -ErrorAction Stop
          $isInProgress = $false
          if ($issue.labels) {
            foreach ($lbl in $issue.labels) {
              if ([string]$lbl.name -eq 'ginee:in-progress') { $isInProgress = $true; break }
            }
          }
          # If transcript shows a close comment / `Phase 8` summary, allow.
          $closed = ($transcript -match '(?im)^\s*##\s+Phase\s+8\b' -or
                     $transcript -match 'gh\s+issue\s+close\s+' + $issueN)
          if ($isInProgress -and -not $closed -and $issue.state -eq 'OPEN') {
            Write-Block `
              -Rule 'open ginee:in-progress issue without Phase-8 close' `
              -Detail "Issue #$issueN remains OPEN with the ginee:in-progress label and no Phase-8 close comment in this turn." `
              -Remediation 'Either post the Phase-8 close (`gh issue close <N> -c ...`) before ending the turn, OR explicitly hand back with a stop-state note.'
          }
        }
      } catch {
        $null = $_  # offline / unauth — fail open
      }
    }
  }
}

exit 0

} catch {
  $null = $_
  exit 0
}
