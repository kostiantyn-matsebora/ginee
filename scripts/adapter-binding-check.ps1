#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Pre-push gate — every new framework rule classifies its Claude-adapter
  enforcement (per CLAUDE.md § Framework authoring — context economy §
  Adapter binding).

.DESCRIPTION
  Scans the commit range being pushed for newly-added MUST / MUST NOT
  (RFC 2119) lines in `core/**/*.md`, excluding template + script paths.
  If any are found, checks whether the same commit range contains an
  adapter-binding signal — either:
    - Diff touches  adapters/claude/hooks/**
                   adapters/claude/commands/**
                   adapters/_shared/agents/*.md
                   .claude/settings.json.example
                   adapters/claude/hooks/keyword-triggers.yaml
                   adapters/claude/hooks/carry-forward-rules.yaml
    - Commit messages OR added doc content reference one of the
      adapter-binding force-classes / mechanisms (Class A-H · PreToolUse ·
      PostToolUse · pre-tool-use-* · slash command · subagent tools
      whitelist · keyword-triggers · carry-forward-rules · always-loaded ·
      hard-force · playbook #135).

  Returns:
    exit 0 — no new rule lines OR adapter-binding signal present.
    exit 1 — gate triggered (caller decides what to do — pre-push hook
              prompts user, CI hard-fails, etc.).

  Bypass: SKIP_ADAPTER_BINDING=1 env var.

.PARAMETER BaseRef
  Git ref to diff against. Defaults to 'origin/main'.

.PARAMETER Json
  Emit JSON diagnostic on stdout instead of human-readable text.
#>
[CmdletBinding()]
param(
  [string]$BaseRef = 'origin/main',
  [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($env:SKIP_ADAPTER_BINDING -eq '1') {
  if (-not $Json) { Write-Host 'adapter-binding-check: bypassed via SKIP_ADAPTER_BINDING=1' -ForegroundColor DarkGray }
  exit 0
}

# Resolve base ref — fall back if origin/main isn't fetched (e.g. fresh fork).
$base = $BaseRef
& git rev-parse --verify --quiet $base *> $null
if ($LASTEXITCODE -ne 0) {
  foreach ($cand in @('main','master','HEAD~1')) {
    & git rev-parse --verify --quiet $cand *> $null
    if ($LASTEXITCODE -eq 0) { $base = $cand; break }
  }
}

# Files in range — only added or modified .md under core/, excluding template +
# script subtrees.
$pathFilter = @(
  'core/*.md',
  'core/**/*.md',
  ':(exclude)core/templates/issues/**',
  ':(exclude)core/scripts/**',
  ':(exclude)core/skills/**'
)
$rangeFiles = @(& git diff --name-only --diff-filter=AM "$base...HEAD" -- @pathFilter 2>$null)
if (-not $rangeFiles -or $rangeFiles.Count -eq 0) {
  if ($Json) { '{"new_rules": 0, "signal_found": false, "skipped": "no-core-md-changes"}' } else {
    Write-Host 'adapter-binding-check: no core/**/*.md additions in range — pass.' -ForegroundColor DarkGray
  }
  exit 0
}

# Collect added lines per file. `git diff -U0` keeps no context — only +/- and
# hunk headers. We filter to lines starting with '+' (added) and skip the
# `+++ b/...` filename headers.
function Get-AddedRuleHit {
  param([string]$BaseRef, [string[]]$Files)
  $hits = @()
  foreach ($f in $Files) {
    $rx = '(?m)^\+(?!\+).*\b(MUST(?:\s+NOT)?|SHOULD(?:\s+NOT)?)\b'
    $diff = & git diff -U0 "$BaseRef...HEAD" -- $f 2>$null | Out-String
    foreach ($m in [regex]::Matches($diff, $rx)) {
      $line = $m.Value.TrimEnd().Substring(1).Trim()
      # Skip code-fence content, table-cell-only modifier mentions inside an
      # otherwise-unchanged surrounding context. Heuristic: line must contain
      # a verb-like word after the keyword to be a real rule.
      if ($line.Length -lt 12) { continue }
      $hits += [pscustomobject]@{ File = $f; Line = $line }
    }
  }
  return $hits
}

$ruleHits = @(Get-AddedRuleHit -BaseRef $base -Files $rangeFiles)

if ($ruleHits.Count -eq 0) {
  if ($Json) { '{"new_rules": 0, "signal_found": false}' } else {
    Write-Host 'adapter-binding-check: no new RFC 2119 rule lines in core/** range — pass.' -ForegroundColor DarkGray
  }
  exit 0
}

# Adapter-binding signal — diff touches one of the binding-bearing surfaces.
$bindingPaths = @(
  'adapters/claude/hooks/',
  'adapters/claude/commands/',
  'adapters/_shared/agents/',
  '.claude/settings.json.example',
  'adapters/claude/hooks/keyword-triggers.yaml',
  'adapters/claude/hooks/carry-forward-rules.yaml',
  'core/scripts/sync-claude-settings.'
)
$rangeAllFiles = @(& git diff --name-only "$base...HEAD" 2>$null)
$pathSignal = $false
foreach ($p in $bindingPaths) {
  if ($rangeAllFiles | Where-Object { $_ -like "$p*" -or $_ -eq $p }) { $pathSignal = $true; break }
}

# Textual signal — commit messages OR added doc content reference one of the
# force-class / mechanism keywords.
$signalKeywords = @(
  '\bClass\s+[A-H]\b',                       # force-class taxonomy
  'PreToolUse\s+hook', 'PostToolUse\s+hook',
  'pre-tool-use-', 'post-tool-use-',
  '\bslash\s+command\b', '/ginee-',
  'subagent\s+tools\s+whitelist', '\btools\s+whitelist\b',
  'keyword-triggers', 'carry-forward-rules',
  '\balways-loaded\b', '\bhard-force\b', '\bsoft-force\b',
  'playbook\s*#135',
  'T1[0-9]|T2[0-9]|T1[45]'                  # tactic IDs (T9..T15+)
)
$rangeMessages = (& git log --format='%B' "$base..HEAD" 2>$null) -join "`n"
$rangeAddedDocBody = ''
foreach ($f in $rangeFiles) {
  $d = & git diff "$base...HEAD" -- $f 2>$null
  $rangeAddedDocBody += "`n" + (($d -split "`n" | Where-Object { $_ -match '^\+' -and $_ -notmatch '^\+\+\+' }) -join "`n")
}
$haystack = $rangeMessages + "`n" + $rangeAddedDocBody
$textSignal = $false
foreach ($k in $signalKeywords) {
  if ($haystack -match $k) { $textSignal = $true; break }
}

$signalFound = ($pathSignal -or $textSignal)

if ($Json) {
  $obj = @{
    new_rules     = $ruleHits.Count
    signal_found  = $signalFound
    path_signal   = $pathSignal
    text_signal   = $textSignal
    rule_samples  = @($ruleHits | Select-Object -First 5)
    base_ref      = $base
  }
  ($obj | ConvertTo-Json -Compress -Depth 5)
  if (-not $signalFound) { exit 1 } else { exit 0 }
}

if ($signalFound) {
  Write-Host "adapter-binding-check: $($ruleHits.Count) new rule line(s) in core/** — adapter-binding signal FOUND (path=$pathSignal, text=$textSignal). PASS." -ForegroundColor Green
  exit 0
}

Write-Host ''
Write-Host '[ginee:gate] Adapter-binding classification missing' -ForegroundColor Red
Write-Host "  Detected $($ruleHits.Count) new RFC 2119 rule line(s) in core/** with NO adapter-binding signal"
Write-Host "  in commit-range diff or messages ($base..HEAD)."
Write-Host ''
Write-Host '  Per CLAUDE.md § Framework authoring — context economy § Adapter binding:'
Write-Host '  every new rule in core/** classifies its Claude-adapter enforcement —'
Write-Host '  hook · slash command · subagent `tools:` whitelist · always-loaded text.'
Write-Host ''
Write-Host '  Sample new rule lines (first 5):' -ForegroundColor Yellow
foreach ($h in ($ruleHits | Select-Object -First 5)) {
  $excerpt = if ($h.Line.Length -gt 110) { $h.Line.Substring(0, 107) + '...' } else { $h.Line }
  Write-Host "    $($h.File): $excerpt" -ForegroundColor DarkYellow
}
Write-Host ''
Write-Host '  Resolutions:' -ForegroundColor Cyan
Write-Host '    (a) Add adapter-binding diff — author the corresponding hook /' -ForegroundColor Cyan
Write-Host '        slash command / subagent-tools entry, OR' -ForegroundColor Cyan
Write-Host '    (b) Cite the force-class in the commit message (Class A-H) +' -ForegroundColor Cyan
Write-Host '        the binding mechanism (PreToolUse hook · slash command · ...).' -ForegroundColor Cyan
Write-Host '    (c) Bypass for the genuinely-adopter-doc-only / structural case:' -ForegroundColor Cyan
Write-Host '        SKIP_ADAPTER_BINDING=1 git push ...' -ForegroundColor Cyan
exit 1
