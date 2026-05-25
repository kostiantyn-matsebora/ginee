#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Context-economy gate for the ginee framework repo.

.DESCRIPTION
  Enforces CLAUDE.md § Framework authoring — context economy on changes to
  this repo's framework source (core/, adapters/, extras/, CLAUDE.md, PLAN.md).
  Diffs the working tree (or staged set, or a base-ref range) against a base;
  for each watched file, computes net-added lines + bytes; flags any file that
  exceeds the threshold unless the branch carries an "Optimized-By: ai-engineer"
  trailer on at least one commit.

  Also runs a structural lint on always-loaded files — flags prose paragraphs
  containing > 2 sentence terminators (the D18–D20 regression signature).

  Three modes:
    -BaseRef <ref>    Diff HEAD (or staged) against <ref> — CI mode (base = PR target)
    -StagedOnly       Diff staged changes against HEAD — git pre-commit hook mode
    -ClaudeHook       Diff working tree against HEAD — Claude Code PostToolUse hook mode

.OUTPUTS
  Exit codes:
    0 — gate pass (under threshold, or threshold passed with marker present)
    1 — gate fail (threshold exceeded without marker, no waiver)
    2 — structural lint fail (prose-paragraph regression in always-loaded file)
  In -Json mode, emits a JSON summary to stdout for CI / hook consumption.

.NOTES
  Cross-platform (pwsh 7+). No external dependencies beyond git on PATH.
  Tests: tests/context-economy-check.Tests.ps1
#>
[CmdletBinding(DefaultParameterSetName = 'WorkingTree')]
param(
  [Parameter(ParameterSetName = 'Range')]
  [string]$BaseRef,

  [Parameter(ParameterSetName = 'Staged')]
  [switch]$StagedOnly,

  [Parameter(ParameterSetName = 'ClaudeHook')]
  [switch]$ClaudeHook,

  [switch]$Json,

  [switch]$SkipStructuralLint,

  [string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Parameter-set switches are consumed via $PSCmdlet.ParameterSetName, not by direct
# reference — silence the analyzer for the dispatch switches.
$null = $StagedOnly
$null = $ClaudeHook
$null = $Json
$null = $SkipStructuralLint

# ----- Thresholds ---------------------------------------------------------
$Script:Thresholds = @{
  AlwaysLoaded = @{ Lines = 25; Bytes = 1024 }
  Other        = @{ Lines = 50; Bytes = 2048 }
}

# Always-loaded patterns — strictest tier.
# core/roles/*.md = role kernels (loaded on every dispatch).
# core/roles/*.details.md = load-on-demand (NOT always-loaded).
$Script:AlwaysLoadedPatterns = @(
  '^CLAUDE\.md$'
  '^core/process\.md$'
  '^core/roles/[^/]+\.md$'
)

# Other watched paths — looser tier.
# Note: PLAN.md is the canonical design doc, read at session start but not
# auto-loaded by the harness on every dispatch — so it sits in "other", not
# "always-loaded" (#36's framing). Confirmed by the trim cleanup in 0.5.1.
# Note: core/process/*.md (per D35 phase + dispatch split) are load-on-demand
# by role per `phase-participation:`; tracked in "other" tier, not always-loaded.
$Script:OtherWatchedPatterns = @(
  '^PLAN\.md$'
  '^core/[^/]+\.md$'                # core/*.md specs (excluding process.md, caught above)
  '^core/process/[^/]+\.md$'        # D35 — phase + dispatch files (load-on-demand by role)
  '^core/protocols/[^/]+\.md$'      # load-on-demand protocol specs (relocated from core/)
  '^core/roles/[^/]+\.details\.md$' # load-on-demand role details
  '^local/roles/[^/]+\.md$'         # D37 — cardinal extensions (load if present)
  '^core/skills/'
  '^core/templates/'
  '^adapters/'
  '^extras/roles/'
)

$Script:MarkerTrailer = 'Optimized-By:'
$Script:MarkerValue = 'ai-engineer'

# Hot-spec frontmatter scope — files that MUST carry the YAML frontmatter
# defined in `core/protocols/hot-spec-format.md § Schema`. Excludes
# `core/templates/*.md` (templates), `core/skills/ginee-*/SKILL.md`
# (AgentSkills frontmatter governs), and `local/roles/*.md` (adopter-owned
# per the local-role-extensions carve-out).
$Script:HotSpecPatterns = @(
  '^core/process\.md$'
  '^core/process/[^/]+\.md$'
  '^core/protocols/[^/]+\.md$'
  '^core/roles/[^/]+\.md$'           # includes both kernels and *.details.md
)

# Required keys per `hot-spec-format.md § Schema`. `triggers` is conditional
# (required only when `load: on-demand`) so it is enforced in code, not in
# the always-required set.
$Script:HotSpecRequiredKeys = @('audience', 'load', 'cap-bytes', 'reads-before-applying')
$Script:HotSpecLoadValues   = @('always', 'on-demand')

# Doc-size caps — per-class total-file-size limits. Defaults match
# `core/protocols/doc-size-caps.md § Default caps`. Adopter override via
# `local/framework.config.yaml § doc-size-caps`.
$Script:DocSizeCapDefaults = @{
  adr = 4096
  cr  = 6144
  ui  = 4096
}
# Default directory hints when `local/framework.config.yaml` is absent or the
# class-directory key is not set. Adopters typically set these explicitly in
# `local/framework.config.yaml § adr-directory` / `cr-directory` / `ui-directory`.
$Script:DocClassDirDefaults = @{
  adr = 'docs/adr/'
  cr  = 'docs/cr/'
  ui  = 'docs/ui/'
}

# ----- Helpers ------------------------------------------------------------

function Resolve-RepoRoot {
  param([string]$Hint)
  if ($Hint) {
    if (-not (Test-Path -LiteralPath $Hint)) {
      throw "RepoRoot path does not exist: $Hint"
    }
    Push-Location -LiteralPath $Hint
    try {
      $top = & git rev-parse --show-toplevel 2>$null
      if ($LASTEXITCODE -ne 0) {
        throw "Not inside a git working tree at: $Hint"
      }
      return $top
    } finally { Pop-Location }
  }
  $top = & git rev-parse --show-toplevel 2>$null
  if ($LASTEXITCODE -ne 0) {
    throw "Not inside a git working tree (cwd: $(Get-Location))."
  }
  return $top
}

function Test-IsAlwaysLoaded {
  param([string]$Path)
  $norm = $Path -replace '\\', '/'
  # `.details.md` files belong to the "other" tier even though the role-kernel
  # regex `^core/roles/[^/]+\.md$` would otherwise greedily match them.
  if ($norm -match '\.details\.md$') { return $false }
  foreach ($p in $Script:AlwaysLoadedPatterns) {
    if ($norm -match $p) { return $true }
  }
  return $false
}

function Test-IsWatched {
  param([string]$Path)
  if (Test-IsAlwaysLoaded -Path $Path) { return $true }
  $norm = $Path -replace '\\', '/'
  foreach ($p in $Script:OtherWatchedPatterns) {
    if ($norm -match $p) { return $true }
  }
  return $false
}

function Get-Threshold {
  param([string]$Path)
  if (Test-IsAlwaysLoaded -Path $Path) { return $Script:Thresholds.AlwaysLoaded }
  return $Script:Thresholds.Other
}

function Get-DiffSpec {
  <#
    Returns @{ Args = @(<git diff args>); Range = '<range-or-staged>' } for the active mode.
  #>
  param([string]$Mode, [string]$Base)
  switch ($Mode) {
    'Range' {
      # Three-dot diff: changes on HEAD since merge-base with $Base.
      return @{ Args = @('diff', '--numstat', "$Base...HEAD"); Range = "$Base...HEAD" }
    }
    'Staged' {
      return @{ Args = @('diff', '--numstat', '--cached'); Range = 'staged' }
    }
    'ClaudeHook' {
      return @{ Args = @('diff', '--numstat', 'HEAD'); Range = 'HEAD..working-tree' }
    }
    default {
      return @{ Args = @('diff', '--numstat', 'HEAD'); Range = 'HEAD..working-tree' }
    }
  }
}

function Get-NumstatRow {
  <#
    Parse `git diff --numstat` output to per-file added/removed-line counts.
    Returns array of @{ Path; Added; Removed }.
  #>
  param([string[]]$Lines)
  $rows = @()
  foreach ($line in $Lines) {
    if (-not $line) { continue }
    # Binary files show '-\t-\t<path>'. Skip them — no line semantics.
    $parts = $line -split "`t", 3
    if ($parts.Count -lt 3) { continue }
    if ($parts[0] -eq '-' -or $parts[1] -eq '-') { continue }
    $added = 0; $removed = 0
    if (-not [int]::TryParse($parts[0], [ref]$added)) { continue }
    if (-not [int]::TryParse($parts[1], [ref]$removed)) { continue }
    $rows += [PSCustomObject]@{
      Path    = $parts[2] -replace '\\', '/'
      Added   = $added
      Removed = $removed
    }
  }
  # Emit individual rows; callers wrap with @() to defeat PowerShell array unwrapping.
  $rows | Write-Output
}

function Get-FileByteDelta {
  <#
    Compute net byte delta for a file between two trees.
    For working-tree mode, compares HEAD blob (or empty if new) to filesystem.
    For range mode, compares blob@base to blob@HEAD.
  #>
  param([string]$Path, [string]$Mode, [string]$Base, [string]$RepoRoot)

  $oldBytes = 0
  $newBytes = 0

  switch ($Mode) {
    'Range' {
      $oldContent = & git show "${Base}:$Path" 2>$null
      if ($LASTEXITCODE -eq 0) { $oldBytes = ([System.Text.Encoding]::UTF8.GetByteCount(($oldContent -join "`n"))) }
      $newContent = & git show "HEAD:$Path" 2>$null
      if ($LASTEXITCODE -eq 0) { $newBytes = ([System.Text.Encoding]::UTF8.GetByteCount(($newContent -join "`n"))) }
    }
    'Staged' {
      $oldContent = & git show "HEAD:$Path" 2>$null
      if ($LASTEXITCODE -eq 0) { $oldBytes = ([System.Text.Encoding]::UTF8.GetByteCount(($oldContent -join "`n"))) }
      # Staged content via :0:
      $newContent = & git show ":0:$Path" 2>$null
      if ($LASTEXITCODE -eq 0) { $newBytes = ([System.Text.Encoding]::UTF8.GetByteCount(($newContent -join "`n"))) }
    }
    default {
      # Working-tree / ClaudeHook
      $oldContent = & git show "HEAD:$Path" 2>$null
      if ($LASTEXITCODE -eq 0) { $oldBytes = ([System.Text.Encoding]::UTF8.GetByteCount(($oldContent -join "`n"))) }
      $fsPath = Join-Path $RepoRoot $Path
      if (Test-Path -LiteralPath $fsPath) { $newBytes = (Get-Item -LiteralPath $fsPath).Length }
    }
  }

  return ($newBytes - $oldBytes)
}

function Read-DocSizeCapConfig {
  <#
    Reads `local/framework.config.yaml` (relative to RepoRoot if present);
    returns @{ Dirs = @{ adr; cr; ui }; Caps = @{ adr; cr; ui }; Disabled = @{ adr; cr; ui } }.
    Missing keys → framework defaults. No framework.config.yaml → all defaults.
    YAML parsing is regex-based; full YAML parser not required for the limited surface.
  #>
  param([string]$RepoRoot)

  $result = @{
    Dirs     = @{ adr = $Script:DocClassDirDefaults.adr; cr = $Script:DocClassDirDefaults.cr; ui = $Script:DocClassDirDefaults.ui }
    Caps     = @{ adr = $Script:DocSizeCapDefaults.adr; cr = $Script:DocSizeCapDefaults.cr; ui = $Script:DocSizeCapDefaults.ui }
    Disabled = @{ adr = $false; cr = $false; ui = $false }
  }

  $cfgPath = Join-Path $RepoRoot 'local/framework.config.yaml'
  if (-not (Test-Path -LiteralPath $cfgPath)) { return $result }

  $section = ''
  $currentClass = ''
  foreach ($line in Get-Content -LiteralPath $cfgPath) {
    if ($line -match '^\s*#' -or $line -match '^\s*$') { continue }

    # Dedent transitions — leaving doc-size-caps block.
    if ($section -eq 'dsc.class' -and $line -notmatch '^    ') { $section = 'dsc'; $currentClass = '' }
    if ($section -eq 'dsc'       -and $line -notmatch '^  ')   { $section = '' }

    # Top-level directory keys.
    if ($line -match '^adr-directory:\s*(\S+)') { $result.Dirs.adr = (ConvertTo-NormalizedDirPath $Matches[1]); continue }
    if ($line -match '^cr-directory:\s*(\S+)')  { $result.Dirs.cr  = (ConvertTo-NormalizedDirPath $Matches[1]); continue }
    if ($line -match '^ui-directory:\s*(\S+)')  { $result.Dirs.ui  = (ConvertTo-NormalizedDirPath $Matches[1]); continue }

    # Section entries.
    if ($line -match '^doc-size-caps:\s*$') { $section = 'dsc'; $currentClass = ''; continue }
    if ($section -eq 'dsc' -and $line -match '^  ([\w-]+):\s*disabled\s*$') {
      $cls = $Matches[1].ToLower()
      if ($result.Disabled.ContainsKey($cls)) { $result.Disabled[$cls] = $true }
      continue
    }
    if ($section -eq 'dsc' -and $line -match '^  ([\w-]+):\s*$') {
      $cls = $Matches[1].ToLower()
      if ($result.Caps.ContainsKey($cls)) {
        $section = 'dsc.class'
        $currentClass = $cls
      }
      continue
    }
    if ($section -eq 'dsc.class' -and $currentClass -and $line -match '^    cap-bytes:\s*(\d+)') {
      $result.Caps[$currentClass] = [int]$Matches[1]
      continue
    }
  }

  return $result
}

function ConvertTo-NormalizedDirPath {
  param([string]$Path)
  $norm = $Path -replace '\\', '/'
  if ($norm -notmatch '/$') { $norm = "$norm/" }
  return $norm
}

function Get-DocClass {
  <#
    Returns 'adr' | 'cr' | 'ui' | $null based on a path matching one of the
    configured class directories. Match is "path starts with dir AND ends in .md".
  #>
  param([string]$Path, [hashtable]$Dirs)
  $norm = ($Path -replace '\\', '/')
  if ($norm -notmatch '\.md$') { return $null }
  foreach ($cls in @('adr', 'cr', 'ui')) {
    $dir = $Dirs[$cls]
    if (-not $dir) { continue }
    if ($norm.StartsWith($dir)) { return $cls }
  }
  return $null
}

function Get-DocSizeCapBreach {
  <#
    For each changed file matching a configured doc class, check the file's
    CURRENT total size against the class cap. Returns array of breach records.
    Breaches are independent of the delta-threshold gate (a tiny edit can still
    breach a cap if the file was already over).
  #>
  param([string[]]$Paths, [hashtable]$Config, [string]$Mode, [string]$RepoRoot)

  $breaches = @()
  foreach ($path in $Paths) {
    $cls = Get-DocClass -Path $path -Dirs $Config.Dirs
    if (-not $cls) { continue }
    if ($Config.Disabled[$cls]) { continue }

    $cap = $Config.Caps[$cls]
    $currentBytes = 0
    switch ($Mode) {
      'Range' {
        $content = & git show "HEAD:$path" 2>$null
        if ($LASTEXITCODE -eq 0) { $currentBytes = [System.Text.Encoding]::UTF8.GetByteCount(($content -join "`n")) }
      }
      'Staged' {
        $content = & git show ":0:$path" 2>$null
        if ($LASTEXITCODE -eq 0) { $currentBytes = [System.Text.Encoding]::UTF8.GetByteCount(($content -join "`n")) }
      }
      default {
        $fsPath = Join-Path $RepoRoot $path
        if (Test-Path -LiteralPath $fsPath) { $currentBytes = (Get-Item -LiteralPath $fsPath).Length }
      }
    }

    if ($currentBytes -gt $cap) {
      $breaches += [PSCustomObject]@{
        Path         = $path
        Class        = $cls
        CurrentBytes = $currentBytes
        CapBytes     = $cap
        OverBy       = $currentBytes - $cap
      }
    }
  }
  $breaches | Write-Output
}

function Test-IsHotSpec {
  param([string]$Path)
  $norm = $Path -replace '\\', '/'
  foreach ($p in $Script:HotSpecPatterns) {
    if ($norm -match $p) { return $true }
  }
  return $false
}

function Get-HotSpecFileContent {
  <#
    Returns the file's current content lines (per active mode) or $null if the
    file does not exist in that view (deleted / not present).
  #>
  param([string]$Path, [string]$Mode, [string]$RepoRoot)
  switch ($Mode) {
    'Range' {
      $content = & git show "HEAD:$Path" 2>$null
      if ($LASTEXITCODE -ne 0) { return $null }
      return @($content)
    }
    'Staged' {
      $content = & git show ":0:$Path" 2>$null
      if ($LASTEXITCODE -ne 0) { return $null }
      return @($content)
    }
    default {
      $fsPath = Join-Path $RepoRoot $Path
      if (-not (Test-Path -LiteralPath $fsPath)) { return $null }
      return @(Get-Content -LiteralPath $fsPath)
    }
  }
}

function Read-HotSpecFrontmatter {
  <#
    Parse a leading YAML frontmatter block (between two `---` markers at the
    file head) into a hashtable. Returns $null when no frontmatter block is
    present at file head.

    YAML parsing is narrowly scoped to the keys + value shapes used by the
    hot-spec schema:
      <key>: <scalar>       → string / int
      <key>: [a, b, c]      → flow-style list of strings
    Comments (#) and blank lines inside the block are ignored.
  #>
  param([string[]]$Lines)
  if (-not $Lines -or $Lines.Count -lt 2) { return $null }
  if ($Lines[0] -notmatch '^---\s*$') { return $null }

  $fm = [ordered]@{}
  $closed = $false
  for ($i = 1; $i -lt $Lines.Count; $i++) {
    $line = $Lines[$i]
    if ($line -match '^---\s*$') { $closed = $true; break }
    if ($line -match '^\s*$' -or $line -match '^\s*#') { continue }
    if ($line -match '^([A-Za-z][\w-]*)\s*:\s*(.*)$') {
      $key = $Matches[1]
      $raw = $Matches[2].Trim()
      # Strip inline comment (` # ...`) when present and not inside brackets.
      if ($raw -notmatch '^\[' -and $raw -match '^(.*?)\s+#') { $raw = $Matches[1].Trim() }
      if ($raw -match '^\[(.*)\]$') {
        $inner = $Matches[1].Trim()
        if (-not $inner) {
          $fm[$key] = @()
        } else {
          $items = $inner -split '\s*,\s*' | ForEach-Object { ($_ -replace '^["'']|["'']$', '').Trim() }
          $fm[$key] = @($items)
        }
      } elseif ($raw -match '^-?\d+$') {
        $fm[$key] = [int]$raw
      } else {
        $fm[$key] = ($raw -replace '^["'']|["'']$', '')
      }
    }
  }
  if (-not $closed) { return $null }
  return $fm
}

function Test-HotSpecFrontmatter {
  <#
    For each changed in-scope hot-spec path, parse + validate frontmatter
    against `core/protocols/hot-spec-format.md § Schema`. Returns an array of
    failure records — empty array means all in-scope files pass.

    Failure shape: @{ Path; Reason; Detail }
    Reasons: 'missing' · 'malformed' · 'missing-key' · 'invalid-load' ·
             'empty-triggers' · 'invalid-cap-bytes'
  #>
  param([string[]]$Paths, [string]$Mode, [string]$RepoRoot)

  $failures = @()
  foreach ($path in $Paths) {
    if (-not (Test-IsHotSpec -Path $path)) { continue }
    $lines = Get-HotSpecFileContent -Path $path -Mode $Mode -RepoRoot $RepoRoot
    if ($null -eq $lines) { continue }  # deleted in this view — nothing to validate

    $fm = Read-HotSpecFrontmatter -Lines $lines
    if ($null -eq $fm) {
      $failures += [PSCustomObject]@{
        Path   = $path
        Reason = 'missing'
        Detail = 'no YAML frontmatter block at file head'
      }
      continue
    }

    $missing = @()
    foreach ($req in $Script:HotSpecRequiredKeys) {
      if (-not $fm.Contains($req)) { $missing += $req }
    }
    if ($missing.Count -gt 0) {
      $failures += [PSCustomObject]@{
        Path   = $path
        Reason = 'missing-key'
        Detail = "missing required key(s): $($missing -join ', ')"
      }
      continue
    }

    if ($Script:HotSpecLoadValues -notcontains $fm['load']) {
      $failures += [PSCustomObject]@{
        Path   = $path
        Reason = 'invalid-load'
        Detail = "load='$($fm['load'])' — must be one of: $($Script:HotSpecLoadValues -join ', ')"
      }
      continue
    }

    if ($fm['load'] -eq 'on-demand') {
      if (-not $fm.Contains('triggers')) {
        $failures += [PSCustomObject]@{
          Path   = $path
          Reason = 'missing-key'
          Detail = "missing 'triggers' (required when load: on-demand)"
        }
        continue
      }
      $trig = $fm['triggers']
      if ($null -eq $trig -or ($trig -is [array] -and $trig.Count -eq 0)) {
        $failures += [PSCustomObject]@{
          Path   = $path
          Reason = 'empty-triggers'
          Detail = "'triggers' must be non-empty when load: on-demand"
        }
        continue
      }
    }

    if (-not ($fm['cap-bytes'] -is [int]) -or $fm['cap-bytes'] -le 0) {
      $failures += [PSCustomObject]@{
        Path   = $path
        Reason = 'invalid-cap-bytes'
        Detail = "cap-bytes='$($fm['cap-bytes'])' — must be a positive integer"
      }
      continue
    }
  }
  $failures | Write-Output
}

function Test-MarkerPresent {
  <#
    Detect an "Optimized-By: ai-engineer" trailer on any commit in the
    relevant range. For Range mode, scans base..HEAD. For Staged / WorkingTree
    modes, only HEAD itself can carry the trailer (since the optimization
    must precede the next commit) — so we scan HEAD.
  #>
  param([string]$Mode, [string]$Base)

  switch ($Mode) {
    'Range' {
      $log = & git log --format='%(trailers:key=Optimized-By,valueonly,unfold)' "$Base..HEAD" 2>$null
      if ($LASTEXITCODE -ne 0) { return $false }
      return ($log -match '(?i)\bai-engineer\b')
    }
    default {
      $log = & git log -1 --format='%(trailers:key=Optimized-By,valueonly,unfold)' HEAD 2>$null
      if ($LASTEXITCODE -ne 0) { return $false }
      return ($log -match '(?i)\bai-engineer\b')
    }
  }
}

function Invoke-StructuralLint {
  <#
    For each always-loaded watched file present in the diff, walk its current
    content and flag any prose paragraph (non-bullet, non-table, non-fenced,
    non-heading) containing > 2 sentence terminators followed by a space.
  #>
  param([string[]]$Paths, [string]$RepoRoot)

  $findings = @()
  foreach ($path in $Paths) {
    if (-not (Test-IsAlwaysLoaded -Path $path)) { continue }
    $fsPath = Join-Path $RepoRoot $path
    if (-not (Test-Path -LiteralPath $fsPath)) { continue }
    $lines = Get-Content -LiteralPath $fsPath
    $inFence = $false
    $inFrontmatter = $false
    $frontmatterOpened = $false  # only one frontmatter block is recognised, at file start
    $paragraphStart = -1
    $paragraphLines = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
      $line = $lines[$i]
      # YAML frontmatter — '---' on its own line at file start opens, next '---' closes.
      if ($line -match '^---\s*$') {
        if (-not $frontmatterOpened -and $i -eq 0) {
          $inFrontmatter = $true
          $frontmatterOpened = $true
          continue
        } elseif ($inFrontmatter) {
          $inFrontmatter = $false
          continue
        }
      }
      if ($inFrontmatter) { continue }
      if ($line -match '^\s*```') {
        $inFence = -not $inFence
        $paragraphLines = @()
        $paragraphStart = -1
        continue
      }
      if ($inFence) { continue }

      $isBlank = ($line -match '^\s*$')
      $isStructural = ($line -match '^\s*(#|-|\*|\+|\d+\.|\||>|\[)')

      if ($isBlank -or $isStructural) {
        if ($paragraphLines.Count -gt 0) {
          $text = $paragraphLines -join ' '
          # Count sentence terminators followed by space + capital/lower, or end-of-text
          $terminators = ([regex]::Matches($text, '[.!?](\s+|$)')).Count
          if ($terminators -gt 2) {
            $findings += [PSCustomObject]@{
              Path        = $path
              LineStart   = $paragraphStart + 1
              LineEnd     = $i  # last paragraph line was $i - 1, +1 for 1-indexed
              Terminators = $terminators
              Excerpt     = if ($text.Length -gt 120) { $text.Substring(0, 117) + '...' } else { $text }
            }
          }
          $paragraphLines = @()
          $paragraphStart = -1
        }
        continue
      }

      if ($paragraphStart -lt 0) { $paragraphStart = $i }
      $paragraphLines += $line
    }
    # Trailing paragraph at EOF
    if ($paragraphLines.Count -gt 0) {
      $text = $paragraphLines -join ' '
      $terminators = ([regex]::Matches($text, '[.!?](\s+|$)')).Count
      if ($terminators -gt 2) {
        $findings += [PSCustomObject]@{
          Path        = $path
          LineStart   = $paragraphStart + 1
          LineEnd     = $lines.Count
          Terminators = $terminators
          Excerpt     = if ($text.Length -gt 120) { $text.Substring(0, 117) + '...' } else { $text }
        }
      }
    }
  }
  $findings | Write-Output
}

# ----- Main ---------------------------------------------------------------

function Invoke-ContextEconomyCheckMain {
  [CmdletBinding(DefaultParameterSetName = 'WorkingTree')]
  [OutputType([int])]
  param(
    [Parameter(ParameterSetName = 'Range')]
    [string]$BaseRef,
    [Parameter(ParameterSetName = 'Staged')]
    [switch]$StagedOnly,
    [Parameter(ParameterSetName = 'ClaudeHook')]
    [switch]$ClaudeHook,
    [switch]$Json,
    [switch]$SkipStructuralLint,
    [string]$RepoRoot
  )

  $null = $StagedOnly
  $null = $ClaudeHook

  $mode = $PSCmdlet.ParameterSetName
  $repo = Resolve-RepoRoot -Hint $RepoRoot
  Push-Location $repo
  try {
  $spec = Get-DiffSpec -Mode $mode -Base $BaseRef
  $rawOutput = & git @($spec.Args) 2>$null
  if ($LASTEXITCODE -ne 0) {
    if ($Json) {
      [PSCustomObject]@{ status = 'error'; message = "git $($spec.Args -join ' ') failed" } | ConvertTo-Json -Compress
    } else {
      Write-Host "context-economy-check: git diff failed for range '$($spec.Range)'." -ForegroundColor Yellow
    }
    return 0  # Don't fail hooks on a missing range (e.g. shallow clone) — CI uses BaseRef explicitly.
  }

  $rows = @(Get-NumstatRow -Lines @($rawOutput))
  $offenders = @()
  foreach ($row in $rows) {
    if (-not (Test-IsWatched -Path $row.Path)) { continue }
    $threshold = Get-Threshold -Path $row.Path
    $byteDelta = Get-FileByteDelta -Path $row.Path -Mode $mode -Base $BaseRef -RepoRoot $repo
    $linesOver = $row.Added -gt $threshold.Lines
    $bytesOver = $byteDelta -gt $threshold.Bytes
    if ($linesOver -or $bytesOver) {
      $offenders += [PSCustomObject]@{
        Path            = $row.Path
        Tier            = if (Test-IsAlwaysLoaded -Path $row.Path) { 'always-loaded' } else { 'other' }
        AddedLines      = $row.Added
        RemovedLines    = $row.Removed
        NetBytes        = $byteDelta
        ThresholdLines  = $threshold.Lines
        ThresholdBytes  = $threshold.Bytes
        OverLines       = $linesOver
        OverBytes       = $bytesOver
      }
    }
  }

  $markerPresent = Test-MarkerPresent -Mode $mode -Base $BaseRef
  $watchedPaths = @($rows | Where-Object { Test-IsWatched -Path $_.Path } | ForEach-Object { $_.Path })

  $lintFindings = @()
  if (-not $SkipStructuralLint -and $watchedPaths.Count -gt 0) {
    $lintFindings = @(Invoke-StructuralLint -Paths $watchedPaths -RepoRoot $repo)
  }

  # Per-class doc-size caps — independent of the delta-threshold gate. Reads
  # adopter-side `local/framework.config.yaml` for directory keys + per-class
  # overrides; framework defaults fill gaps. Same Optimized-By trailer bypass.
  $sizeCapConfig = Read-DocSizeCapConfig -RepoRoot $repo
  $changedPaths = @($rows | ForEach-Object { $_.Path })
  $sizeCapBreaches = @(Get-DocSizeCapBreach -Paths $changedPaths -Config $sizeCapConfig -Mode $mode -RepoRoot $repo)

  # Hot-spec frontmatter validator — required YAML frontmatter on changed
  # files within `core/{process,protocols,roles}/**` per
  # `core/protocols/hot-spec-format.md § Schema`. Trailer bypass identical
  # to threshold + per-class-cap gates.
  $hotSpecFailures = @(Test-HotSpecFrontmatter -Paths $changedPaths -Mode $mode -RepoRoot $repo)

  $gateFail = (
    ($offenders.Count -gt 0) -or
    ($sizeCapBreaches.Count -gt 0) -or
    ($hotSpecFailures.Count -gt 0)
  ) -and (-not $markerPresent)
  $lintFail = $lintFindings.Count -gt 0

  $result = [PSCustomObject]@{
    mode             = $mode
    range            = $spec.Range
    offenders        = $offenders
    sizeCapBreaches  = $sizeCapBreaches
    hotSpecFailures  = $hotSpecFailures
    markerPresent    = $markerPresent
    lintFindings     = $lintFindings
    gateFail         = $gateFail
    lintFail         = $lintFail
  }

  if ($Json) {
    $result | ConvertTo-Json -Depth 6 -Compress
  } else {
    if ($offenders.Count -eq 0 -and $sizeCapBreaches.Count -eq 0 -and $hotSpecFailures.Count -eq 0 -and $lintFindings.Count -eq 0) {
      Write-Host "context-economy-check: pass ($($spec.Range))" -ForegroundColor Green
    } else {
      Write-Host "context-economy-check: $($spec.Range)" -ForegroundColor Cyan
      if ($offenders.Count -gt 0) {
        Write-Host ""
        Write-Host "Threshold exceeded ($($offenders.Count) file(s)):" -ForegroundColor Yellow
        foreach ($o in $offenders) {
          $reason = @()
          if ($o.OverLines) { $reason += "+$($o.AddedLines) lines > $($o.ThresholdLines)" }
          if ($o.OverBytes) { $reason += "+$($o.NetBytes) bytes > $($o.ThresholdBytes)" }
          Write-Host "  $($o.Path) [$($o.Tier)] — $($reason -join ', ')"
        }
      }
      if ($sizeCapBreaches.Count -gt 0) {
        Write-Host ""
        Write-Host "Per-class doc-size cap breach ($($sizeCapBreaches.Count) file(s)):" -ForegroundColor Yellow
        foreach ($b in $sizeCapBreaches) {
          Write-Host "  $($b.Path) [$($b.Class)] — $($b.CurrentBytes) bytes > cap $($b.CapBytes) (over by $($b.OverBy))"
        }
      }
      if ($hotSpecFailures.Count -gt 0) {
        Write-Host ""
        Write-Host "Hot-spec frontmatter ($($hotSpecFailures.Count) file(s)):" -ForegroundColor Yellow
        foreach ($f in $hotSpecFailures) {
          Write-Host "  $($f.Path) [$($f.Reason)] — $($f.Detail)"
        }
        Write-Host ""
        Write-Host "  Add YAML frontmatter per core/protocols/hot-spec-format.md § Schema:" -ForegroundColor Red
        Write-Host "  audience · load · triggers (when load: on-demand) · cap-bytes · reads-before-applying" -ForegroundColor Red
      }
      if ($offenders.Count -gt 0 -or $sizeCapBreaches.Count -gt 0 -or $hotSpecFailures.Count -gt 0) {
        if ($markerPresent) {
          Write-Host ""
          Write-Host "  Optimized-By: ai-engineer trailer FOUND — gate passes." -ForegroundColor Green
        } else {
          Write-Host ""
          Write-Host "  No 'Optimized-By: ai-engineer' trailer in range." -ForegroundColor Red
          Write-Host "  Dispatch ai-engineer for an optimization pass under the lossless rule," -ForegroundColor Red
          Write-Host "  then commit with trailer: 'Optimized-By: ai-engineer'." -ForegroundColor Red
        }
      }
      if ($lintFindings.Count -gt 0) {
        Write-Host ""
        Write-Host "Structural lint findings ($($lintFindings.Count)) — prose paragraph w/ > 2 sentences in always-loaded file:" -ForegroundColor Yellow
        foreach ($f in $lintFindings) {
          Write-Host "  $($f.Path):$($f.LineStart)-$($f.LineEnd) — $($f.Terminators) sentences"
          Write-Host "    $($f.Excerpt)" -ForegroundColor DarkGray
        }
        Write-Host ""
        Write-Host "  Restructure per CLAUDE.md § Framework authoring — context economy:" -ForegroundColor Red
        Write-Host "  prose paragraphs > 2 rules → bullet list / table / sub-bullets." -ForegroundColor Red
      }
    }
  }

  if ($lintFail) { return 2 }
  if ($gateFail) { return 1 }
  return 0
  } finally {
    Pop-Location
  }
}

# ----- Dispatcher ---------------------------------------------------------
# When dot-sourced (e.g. by Pester tests for in-process coverage),
# $MyInvocation.InvocationName is '.'. Skip auto-execution in that case;
# tests call Invoke-ContextEconomyCheckMain directly.

if ($MyInvocation.InvocationName -ne '.') {
  $exitCode = Invoke-ContextEconomyCheckMain @PSBoundParameters
  exit $exitCode
}
