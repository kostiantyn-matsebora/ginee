#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.5.0' }

BeforeAll {
  $script:scriptPath = (Resolve-Path "$PSScriptRoot/../scripts/context-economy-check.ps1").Path
  # Dot-source the script so Pester can instrument code coverage. The dispatcher
  # block at the bottom of the script detects dot-sourcing via $MyInvocation
  # and skips auto-execution, leaving all functions defined for direct call.
  . $script:scriptPath

  function New-SandboxRepo {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test-only helper.')]
    [CmdletBinding()]
    param()
    $root = Join-Path ([System.IO.Path]::GetTempPath()) "ginee-ce-$([guid]::NewGuid().Guid)"
    New-Item -ItemType Directory -Force -Path $root | Out-Null
    Push-Location $root
    try {
      & git init -q --initial-branch=main *> $null
      & git config user.email 'test@example.com' *> $null
      & git config user.name 'Test' *> $null
      & git config commit.gpgsign false *> $null
      & git config core.hooksPath /dev/null *> $null
      New-Item -ItemType Directory -Force -Path (Join-Path $root 'core/roles') | Out-Null
      New-Item -ItemType Directory -Force -Path (Join-Path $root 'core/templates') | Out-Null
      New-Item -ItemType Directory -Force -Path (Join-Path $root 'adapters') | Out-Null
      Set-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value 'baseline'
      Set-Content -LiteralPath (Join-Path $root 'core/process.md') -Value 'baseline'
      Set-Content -LiteralPath (Join-Path $root 'core/roles/team-lead.md') -Value 'baseline'
      & git add . *> $null
      & git commit -q -m 'baseline' *> $null
    } finally {
      Pop-Location
    }
    return $root
  }

  # In-process invoker. Captures all output streams (pipeline + Information
  # stream where Write-Host messages land in PS 5+). Returns @{ Code; Output; Json }.
  function Invoke-CheckInProc {
    param([string]$Root, [hashtable]$Params)
    $allParams = $Params.Clone()
    $allParams['RepoRoot'] = $Root
    $jsonMode = [bool]($Params.ContainsKey('Json') -and $Params['Json'])
    # *>&1 merges Information, Verbose, Warning, Error, etc. into the pipeline.
    $captured = @(Invoke-ContextEconomyCheckMain @allParams *>&1)
    $code = 0
    $jsonLine = $null
    $hostLines = New-Object System.Collections.ArrayList
    foreach ($item in $captured) {
      if ($item -is [System.Management.Automation.InformationRecord]) {
        [void]$hostLines.Add($item.MessageData.ToString())
      } elseif ($item -is [int]) {
        $code = [int]$item
      } elseif ($item -is [string]) {
        $trimmed = $item.TrimStart()
        if ($trimmed.StartsWith('{') -and $null -eq $jsonLine) {
          $jsonLine = $item
        } else {
          [void]$hostLines.Add($item)
        }
      }
    }
    return [PSCustomObject]@{
      Code   = $code
      Output = ($hostLines -join "`n")
      Json   = if ($jsonMode -and $jsonLine) { $jsonLine | ConvertFrom-Json } else { $null }
    }
  }
}

Describe 'context-economy-check.ps1' {

  It 'parses cleanly as a script block' {
    { [scriptblock]::Create((Get-Content -Raw $script:scriptPath)) } | Should -Not -Throw
  }

  It 'errors gracefully when run outside a git working tree' {
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "ginee-ce-nogit-$([guid]::NewGuid().Guid)"
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    try {
      { Invoke-ContextEconomyCheckMain -RepoRoot $tmp -ClaudeHook } | Should -Throw
    } finally {
      Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
  }

  Context 'WorkingTree / ClaudeHook mode' {
    It 'passes on a clean tree' {
      $root = New-SandboxRepo
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ ClaudeHook = $true; Json = $true }
        $r.Code | Should -Be 0
        $r.Json.offenders.Count | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'flags an over-threshold edit to an always-loaded file without marker' {
      $root = New-SandboxRepo
      try {
        $bloat = (1..60 | ForEach-Object { "- Bullet $_ of structured bloat" }) -join "`n"
        Set-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value "baseline`n$bloat"

        $r = Invoke-CheckInProc -Root $root -Params @{ ClaudeHook = $true; Json = $true }
        $r.Code | Should -Be 1
        $r.Json.offenders.Count | Should -BeGreaterOrEqual 1
        ($r.Json.offenders | Where-Object { $_.Path -eq 'CLAUDE.md' }).Tier | Should -Be 'always-loaded'
        $r.Json.gateFail | Should -BeTrue
        $r.Json.markerPresent | Should -BeFalse
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'ignores files outside the watched set' {
      $root = New-SandboxRepo
      try {
        $bloat = (1..100 | ForEach-Object { "- bullet $_" }) -join "`n"
        Set-Content -LiteralPath (Join-Path $root 'unrelated.txt') -Value $bloat
        Set-Content -LiteralPath (Join-Path $root 'README.md') -Value $bloat

        $r = Invoke-CheckInProc -Root $root -Params @{ ClaudeHook = $true; Json = $true }
        $r.Code | Should -Be 0
        $r.Json.offenders.Count | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'Test-IsAlwaysLoaded: role *.details.md is NOT always-loaded (regression: greedy regex match)' {
      Test-IsAlwaysLoaded -Path 'core/roles/team-lead.md' | Should -BeTrue
      Test-IsAlwaysLoaded -Path 'core/roles/team-lead.details.md' | Should -BeFalse
      Test-IsAlwaysLoaded -Path 'core/roles/ai-engineer.details.md' | Should -BeFalse
    }

    It 'Test-IsAlwaysLoaded: PLAN.md is NOT always-loaded but IS watched (other tier)' {
      Test-IsAlwaysLoaded -Path 'PLAN.md' | Should -BeFalse
      Test-IsWatched -Path 'PLAN.md' | Should -BeTrue
      $t = Get-Threshold -Path 'PLAN.md'
      $t.Lines | Should -Be 50
      $t.Bytes | Should -Be 2048
    }

    It 'tier-classifies role kernels as always-loaded, but role *.details.md as other' {
      $root = New-SandboxRepo
      try {
        $bloat = (1..30 | ForEach-Object { "- bullet $_" }) -join "`n"
        Set-Content -LiteralPath (Join-Path $root 'core/roles/team-lead.md') -Value "baseline`n$bloat"
        $detailsBloat = (1..40 | ForEach-Object { "- bullet $_" }) -join "`n"
        Set-Content -LiteralPath (Join-Path $root 'core/roles/team-lead.details.md') -Value "$detailsBloat"

        $r = Invoke-CheckInProc -Root $root -Params @{ ClaudeHook = $true; Json = $true }
        $r.Code | Should -Be 1
        $offenderPaths = @($r.Json.offenders | ForEach-Object { $_.Path })
        $offenderPaths | Should -Contain 'core/roles/team-lead.md'
        $offenderPaths | Should -Not -Contain 'core/roles/team-lead.details.md'
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }
  }

  Context 'Staged mode' {
    It 'flags staged threshold breach' {
      $root = New-SandboxRepo
      try {
        $bloat = (1..60 | ForEach-Object { "- staged bullet $_" }) -join "`n"
        Set-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value "baseline`n$bloat"
        Push-Location $root
        try { & git add CLAUDE.md *> $null } finally { Pop-Location }

        $r = Invoke-CheckInProc -Root $root -Params @{ StagedOnly = $true; Json = $true }
        $r.Code | Should -Be 1
        $r.Json.gateFail | Should -BeTrue
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'passes staged threshold breach when HEAD carries the Optimized-By trailer' {
      $root = New-SandboxRepo
      try {
        $bloat = (1..60 | ForEach-Object { "- optimized bullet $_" }) -join "`n"
        Set-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value "baseline`n$bloat"
        Push-Location $root
        try {
          & git add CLAUDE.md *> $null
          & git commit -q -m 'add bloat' *> $null
          & git commit --allow-empty -q -m "ai-engineer: shape pass

Optimized-By: ai-engineer" *> $null
          Add-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value "`nextra"
          & git add CLAUDE.md *> $null
        } finally { Pop-Location }

        $r = Invoke-CheckInProc -Root $root -Params @{ StagedOnly = $true; Json = $true }
        $r.Code | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }
  }

  Context 'Range mode (CI)' {
    It 'passes range threshold breach when an Optimized-By commit is present in range' {
      $root = New-SandboxRepo
      try {
        Push-Location $root
        try {
          & git checkout -q -b feature *> $null
          $bloat = (1..60 | ForEach-Object { "- range bullet $_" }) -join "`n"
          Set-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value "baseline`n$bloat"
          & git add CLAUDE.md *> $null
          & git commit -q -m 'bloat' *> $null
          & git commit --allow-empty -q -m "ai-engineer optimization pass

Optimized-By: ai-engineer" *> $null
        } finally { Pop-Location }

        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 0
        $r.Json.markerPresent | Should -BeTrue
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'fails range threshold breach when no Optimized-By commit in range' {
      $root = New-SandboxRepo
      try {
        Push-Location $root
        try {
          & git checkout -q -b feature *> $null
          $bloat = (1..60 | ForEach-Object { "- unguarded bullet $_" }) -join "`n"
          Set-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value "baseline`n$bloat"
          & git add CLAUDE.md *> $null
          & git commit -q -m 'unguarded bloat' *> $null
        } finally { Pop-Location }

        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 1
        $r.Json.gateFail | Should -BeTrue
        $r.Json.markerPresent | Should -BeFalse
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }
  }

  Context 'Structural lint' {
    It 'flags a prose paragraph with > 2 sentences in an always-loaded file' {
      $root = New-SandboxRepo
      try {
        $prose = @(
          '## Heading'
          ''
          'The system is a microservices architecture with container co-location. Four images: api, fetcher, frontend, gateway. The full topology lives under docs/.'
          ''
        ) -join "`n"
        Set-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value "baseline`n$prose"

        $r = Invoke-CheckInProc -Root $root -Params @{ ClaudeHook = $true; Json = $true }
        $r.Code | Should -Be 2
        $r.Json.lintFail | Should -BeTrue
        $r.Json.lintFindings.Count | Should -BeGreaterOrEqual 1
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'does not flag bullets or tables in always-loaded files' {
      $root = New-SandboxRepo
      try {
        $structured = @(
          '## Heading'
          ''
          '- Bullet one with three sentences. Still a bullet. Should pass.'
          '- Bullet two with three sentences. Still a bullet. Should pass.'
          ''
          '| col | val |'
          '|---|---|'
          '| a | one sentence. two sentence. three sentence. |'
          ''
        ) -join "`n"
        Set-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value "baseline`n$structured"

        $r = Invoke-CheckInProc -Root $root -Params @{ ClaudeHook = $true; Json = $true }
        $r.Json.lintFindings.Count | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'ignores YAML frontmatter (between leading --- delimiters)' {
      $root = New-SandboxRepo
      try {
        $withFrontmatter = @(
          '---'
          'name: team-lead'
          'description: Orchestrator. Routes work to specialists. Enforces lifecycle. Reads docs.'
          '---'
          ''
          '## Heading'
          ''
          '- bullet one'
          ''
        ) -join "`n"
        Set-Content -LiteralPath (Join-Path $root 'core/roles/team-lead.md') -Value $withFrontmatter

        $r = Invoke-CheckInProc -Root $root -Params @{ ClaudeHook = $true; Json = $true }
        $r.Json.lintFindings.Count | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'ignores prose inside code fences' {
      $root = New-SandboxRepo
      try {
        $fenced = @(
          '## Heading'
          ''
          '```'
          'Inside the fence we can write whatever prose we want. With many sentences. Still ignored. By the lint.'
          '```'
          ''
        ) -join "`n"
        Set-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value "baseline`n$fenced"

        $r = Invoke-CheckInProc -Root $root -Params @{ ClaudeHook = $true; Json = $true }
        $r.Json.lintFindings.Count | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It '-SkipStructuralLint suppresses lint findings' {
      $root = New-SandboxRepo
      try {
        $prose = @('## Heading'; ''; 'Sentence one. Sentence two. Sentence three.'; '') -join "`n"
        Set-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value "baseline`n$prose"

        $r = Invoke-CheckInProc -Root $root -Params @{ ClaudeHook = $true; SkipStructuralLint = $true; Json = $true }
        $r.Code | Should -Be 0
        $r.Json.lintFindings.Count | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }
  }

  Context 'Output modes' {
    It 'emits valid JSON when -Json is set' {
      $root = New-SandboxRepo
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ ClaudeHook = $true; Json = $true }
        $r.Code | Should -Be 0
        $r.Json | Should -Not -BeNullOrEmpty
        $r.Json.mode | Should -Be 'ClaudeHook'
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'emits human-readable output when -Json is unset' {
      $root = New-SandboxRepo
      try {
        $bloat = (1..60 | ForEach-Object { "- bullet $_" }) -join "`n"
        Set-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value "baseline`n$bloat"

        $r = Invoke-CheckInProc -Root $root -Params @{ ClaudeHook = $true }
        $r.Code | Should -Be 1
        $r.Output | Should -Match 'Threshold exceeded'
        $r.Output | Should -Match 'Optimized-By'
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }
  }

  Context 'Helper coverage — small targeted tests' {
    It 'Resolve-RepoRoot throws on a path that does not exist' {
      $missing = Join-Path ([System.IO.Path]::GetTempPath()) "ce-missing-$([guid]::NewGuid().Guid)"
      { Resolve-RepoRoot -Hint $missing } | Should -Throw '*does not exist*'
    }

    It 'Test-IsAlwaysLoaded returns false for non-always-loaded paths' {
      Test-IsAlwaysLoaded -Path 'core/skills/foo/SKILL.md' | Should -BeFalse
      Test-IsAlwaysLoaded -Path 'adapters/claude/foo.md' | Should -BeFalse
      Test-IsAlwaysLoaded -Path 'unrelated.txt' | Should -BeFalse
    }

    It 'Test-IsWatched matches non-always-loaded watched patterns' {
      Test-IsWatched -Path 'core/skills/foo/SKILL.md' | Should -BeTrue
      Test-IsWatched -Path 'adapters/claude/foo.md' | Should -BeTrue
      Test-IsWatched -Path 'extras/roles/ml-engineer.md' | Should -BeTrue
      Test-IsWatched -Path 'core/roles/team-lead.details.md' | Should -BeTrue
      Test-IsWatched -Path 'unrelated.txt' | Should -BeFalse
    }

    It 'Get-Threshold returns Other threshold for non-always-loaded paths' {
      $t = Get-Threshold -Path 'adapters/claude/foo.md'
      $t.Lines | Should -Be 50
      $t.Bytes | Should -Be 2048
    }

    It 'Get-DiffSpec returns working-tree default when mode is unrecognized' {
      $spec = Get-DiffSpec -Mode 'Unknown' -Base ''
      $spec.Range | Should -Be 'HEAD..working-tree'
    }

    It 'flags an "other"-tier watched file over its threshold (60-line bullets)' {
      $root = New-SandboxRepo
      try {
        $bloat = (1..60 | ForEach-Object { "- bullet $_" }) -join "`n"
        Set-Content -LiteralPath (Join-Path $root 'adapters/foo.md') -Value $bloat
        Push-Location $root
        try { & git add adapters/foo.md *> $null } finally { Pop-Location }
        $r = Invoke-CheckInProc -Root $root -Params @{ ClaudeHook = $true; Json = $true }
        $r.Code | Should -Be 1
        ($r.Json.offenders | Where-Object { $_.Path -eq 'adapters/foo.md' }).Tier | Should -Be 'other'
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }
  }

  Context 'Human-readable output coverage' {
    It 'shows "pass" line when no offenders + no lint findings' {
      $root = New-SandboxRepo
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ ClaudeHook = $true }
        $r.Code | Should -Be 0
        $r.Output | Should -Match 'context-economy-check: pass'
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'shows "trailer FOUND" line when marker present + threshold breached (range mode)' {
      $root = New-SandboxRepo
      try {
        Push-Location $root
        try {
          & git checkout -q -b feature *> $null
          $bloat = (1..60 | ForEach-Object { "- bullet $_" }) -join "`n"
          Set-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value "baseline`n$bloat"
          & git add CLAUDE.md *> $null
          & git commit -q -m 'bloat' *> $null
          & git commit --allow-empty -q -m "shape pass

Optimized-By: ai-engineer" *> $null
        } finally { Pop-Location }
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main' }
        $r.Code | Should -Be 0
        $r.Output | Should -Match 'trailer FOUND'
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'shows human-readable lint findings when -Json unset and lint fails' {
      $root = New-SandboxRepo
      try {
        $prose = @('Sentence one. Sentence two. Sentence three.') -join "`n"
        Set-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value "baseline`n$prose"
        $r = Invoke-CheckInProc -Root $root -Params @{ ClaudeHook = $true }
        $r.Code | Should -Be 2
        $r.Output | Should -Match 'Structural lint findings'
        $r.Output | Should -Match 'Restructure'
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }
  }

  Context 'Range mode — Get-FileByteDelta path' {
    It 'computes byte delta correctly for range mode (covers Get-FileByteDelta Range branch)' {
      $root = New-SandboxRepo
      try {
        Push-Location $root
        try {
          & git checkout -q -b feature *> $null
          $bloat = (1..60 | ForEach-Object { "- bullet $_" }) -join "`n"
          Set-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value "baseline`n$bloat"
          & git add CLAUDE.md *> $null
          & git commit -q -m 'bloat' *> $null
        } finally { Pop-Location }
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $offender = $r.Json.offenders | Where-Object { $_.Path -eq 'CLAUDE.md' }
        $offender | Should -Not -BeNullOrEmpty
        $offender.NetBytes | Should -BeGreaterThan 0
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }
  }

  Context 'Per-class doc-size caps' {
    BeforeAll {
      function New-SandboxRepoWithDoc {
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test-only helper.')]
        [CmdletBinding()]
        param([hashtable]$DocFiles, [string]$ConfigYaml)
        $root = Join-Path ([System.IO.Path]::GetTempPath()) "ginee-ce-caps-$([guid]::NewGuid().Guid)"
        New-Item -ItemType Directory -Force -Path $root | Out-Null
        Push-Location $root
        try {
          & git init -q --initial-branch=main *> $null
          & git config user.email 'test@example.com' *> $null
          & git config user.name 'Test' *> $null
          & git config commit.gpgsign false *> $null
          & git config core.hooksPath /dev/null *> $null
          New-Item -ItemType Directory -Force -Path (Join-Path $root 'core/roles') | Out-Null
          New-Item -ItemType Directory -Force -Path (Join-Path $root 'local') | Out-Null
          Set-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value 'baseline'
          Set-Content -LiteralPath (Join-Path $root 'core/process.md') -Value 'baseline'
          if ($ConfigYaml) {
            Set-Content -LiteralPath (Join-Path $root 'local/framework.config.yaml') -Value $ConfigYaml
          }
          & git add . *> $null
          & git commit -q -m 'baseline' *> $null
          & git checkout -q -b feature *> $null
          foreach ($entry in $DocFiles.GetEnumerator()) {
            $abs = Join-Path $root $entry.Key
            $dir = Split-Path $abs -Parent
            if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
            Set-Content -LiteralPath $abs -Value $entry.Value
          }
          if ($DocFiles.Count -gt 0) {
            & git add . *> $null
            & git commit -q -m 'doc edit' *> $null
          }
        } finally { Pop-Location }
        return $root
      }
    }

    It 'flags an oversized ADR against the framework default cap' {
      $oversized = 'x' * 5000
      $root = New-SandboxRepoWithDoc -DocFiles @{ 'docs/adr/ADR-0001.md' = $oversized }
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 1
        $r.Json.sizeCapBreaches.Count | Should -Be 1
        $b = $r.Json.sizeCapBreaches[0]
        $b.Path | Should -Be 'docs/adr/ADR-0001.md'
        $b.Class | Should -Be 'adr'
        $b.CapBytes | Should -Be 4096
        $b.CurrentBytes | Should -BeGreaterThan 4096
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'allows a CR up to the higher default (6144 bytes)' {
      $under = 'x' * 5000
      $root = New-SandboxRepoWithDoc -DocFiles @{ 'docs/cr/CR-0001.md' = $under }
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 0
        $r.Json.sizeCapBreaches.Count | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'flags an oversized UI doc against the framework default cap' {
      $oversized = 'x' * 5000
      $root = New-SandboxRepoWithDoc -DocFiles @{ 'docs/ui/screen-A.md' = $oversized }
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 1
        $r.Json.sizeCapBreaches.Count | Should -Be 1
        $r.Json.sizeCapBreaches[0].Class | Should -Be 'ui'
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'honours adopter cap-bytes override' {
      $cfg = @"
adr-directory: docs/adr/
doc-size-caps:
  adr:
    cap-bytes: 8192
"@
      $oversized = 'x' * 5000  # Over framework default (4096) but under override (8192)
      $root = New-SandboxRepoWithDoc -DocFiles @{ 'docs/adr/ADR-0001.md' = $oversized } -ConfigYaml $cfg
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 0
        $r.Json.sizeCapBreaches.Count | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'honours adopter `disabled` to opt out of a class' {
      $cfg = @"
adr-directory: docs/adr/
doc-size-caps:
  adr: disabled
"@
      $oversized = 'x' * 9000
      $root = New-SandboxRepoWithDoc -DocFiles @{ 'docs/adr/ADR-0001.md' = $oversized } -ConfigYaml $cfg
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 0
        $r.Json.sizeCapBreaches.Count | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'reads adopter-specified class directories (non-default path)' {
      $cfg = @"
adr-directory: architecture/decisions/
"@
      $oversized = 'x' * 5000
      $root = New-SandboxRepoWithDoc -DocFiles @{ 'architecture/decisions/ADR-001.md' = $oversized } -ConfigYaml $cfg
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 1
        $r.Json.sizeCapBreaches.Count | Should -Be 1
        $r.Json.sizeCapBreaches[0].Class | Should -Be 'adr'
        $r.Json.sizeCapBreaches[0].Path | Should -Be 'architecture/decisions/ADR-001.md'
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'passes a size-cap breach when Optimized-By trailer is present (range mode)' {
      $oversized = 'x' * 5000
      $root = New-SandboxRepoWithDoc -DocFiles @{}
      try {
        Push-Location $root
        try {
          $abs = Join-Path $root 'docs/adr/ADR-0001.md'
          New-Item -ItemType Directory -Force -Path (Split-Path $abs -Parent) | Out-Null
          Set-Content -LiteralPath $abs -Value $oversized
          & git add . *> $null
          $msg = "land oversized ADR`n`nOptimized-By: ai-engineer"
          & git commit -q -m $msg *> $null
        } finally { Pop-Location }
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Json.sizeCapBreaches.Count | Should -Be 1
        $r.Json.markerPresent | Should -Be $true
        $r.Code | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'does not flag .md files outside the configured class directories' {
      $oversized = 'x' * 9000
      $root = New-SandboxRepoWithDoc -DocFiles @{ 'docs/random-note.md' = $oversized }
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 0
        $r.Json.sizeCapBreaches.Count | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'Read-DocSizeCapConfig returns all defaults when local/framework.config.yaml is absent' {
      $root = New-SandboxRepo
      try {
        $cfg = Read-DocSizeCapConfig -RepoRoot $root
        $cfg.Caps.adr | Should -Be 4096
        $cfg.Caps.cr | Should -Be 6144
        $cfg.Caps.ui | Should -Be 4096
        $cfg.Dirs.adr | Should -Be 'docs/adr/'
        $cfg.Disabled.adr | Should -Be $false
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'Get-DocClass returns the matching class for a path' {
      $dirs = @{ adr = 'docs/adr/'; cr = 'docs/cr/'; ui = 'docs/ui/' }
      (Get-DocClass -Path 'docs/adr/ADR-001.md' -Dirs $dirs) | Should -Be 'adr'
      (Get-DocClass -Path 'docs/cr/CR-001.md' -Dirs $dirs) | Should -Be 'cr'
      (Get-DocClass -Path 'docs/ui/home.md' -Dirs $dirs) | Should -Be 'ui'
      (Get-DocClass -Path 'docs/random.md' -Dirs $dirs) | Should -BeNullOrEmpty
      (Get-DocClass -Path 'docs/adr/something.txt' -Dirs $dirs) | Should -BeNullOrEmpty
    }
  }

  Context 'Hot-spec frontmatter validator' {
    BeforeAll {
      function New-SandboxRepoWithHotSpec {
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test-only helper.')]
        [CmdletBinding()]
        param([hashtable]$Files, [switch]$WithTrailer)
        $root = Join-Path ([System.IO.Path]::GetTempPath()) "ginee-ce-hotspec-$([guid]::NewGuid().Guid)"
        New-Item -ItemType Directory -Force -Path $root | Out-Null
        Push-Location $root
        try {
          & git init -q --initial-branch=main *> $null
          & git config user.email 'test@example.com' *> $null
          & git config user.name 'Test' *> $null
          & git config commit.gpgsign false *> $null
          & git config core.hooksPath /dev/null *> $null
          # Baseline: minimal repo structure so trees diff cleanly.
          New-Item -ItemType Directory -Force -Path (Join-Path $root 'core/roles') | Out-Null
          New-Item -ItemType Directory -Force -Path (Join-Path $root 'core/protocols') | Out-Null
          New-Item -ItemType Directory -Force -Path (Join-Path $root 'core/process') | Out-Null
          New-Item -ItemType Directory -Force -Path (Join-Path $root 'core/templates') | Out-Null
          Set-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value 'baseline'
          & git add . *> $null
          & git commit -q -m 'baseline' *> $null
          & git checkout -q -b feature *> $null
          foreach ($entry in $Files.GetEnumerator()) {
            $abs = Join-Path $root $entry.Key
            $dir = Split-Path $abs -Parent
            if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
            Set-Content -LiteralPath $abs -Value $entry.Value
          }
          if ($Files.Count -gt 0) {
            & git add . *> $null
            if ($WithTrailer) {
              $msg = "land hot-spec edit`n`nOptimized-By: ai-engineer"
              & git commit -q -m $msg *> $null
            } else {
              & git commit -q -m 'hot-spec edit' *> $null
            }
          }
        } finally { Pop-Location }
        return $root
      }

      $script:validFrontmatter = @(
        '---'
        'audience: all-cardinals'
        'load: on-demand'
        'triggers: [hot-spec, frontmatter]'
        'cap-bytes: 4096'
        'reads-before-applying: [core/protocols/doc-size-caps.md]'
        '---'
        ''
        '# Body heading'
        ''
        '- one bullet'
      ) -join "`n"

      $script:malformedMissingLoad = @(
        '---'
        'audience: all-cardinals'
        'triggers: [hot-spec]'
        'cap-bytes: 4096'
        'reads-before-applying: []'
        '---'
        ''
        '# Body'
      ) -join "`n"

      $script:noFrontmatter = @(
        '# Body heading'
        ''
        '- bullet'
      ) -join "`n"

      $script:emptyTriggers = @(
        '---'
        'audience: all-cardinals'
        'load: on-demand'
        'triggers: []'
        'cap-bytes: 4096'
        'reads-before-applying: []'
        '---'
        ''
        '# Body'
      ) -join "`n"

      $script:invalidLoad = @(
        '---'
        'audience: all-cardinals'
        'load: lazy'
        'triggers: [x]'
        'cap-bytes: 4096'
        'reads-before-applying: []'
        '---'
        ''
        '# Body'
      ) -join "`n"

      $script:loadAlwaysNoTriggers = @(
        '---'
        'audience: all-cardinals'
        'load: always'
        'cap-bytes: 4096'
        'reads-before-applying: []'
        '---'
        ''
        '# Body'
      ) -join "`n"

      $script:invalidCapBytes = @(
        '---'
        'audience: all-cardinals'
        'load: always'
        'cap-bytes: 0'
        'reads-before-applying: []'
        '---'
        ''
        '# Body'
      ) -join "`n"
    }

    It 'Test-IsHotSpec recognises in-scope paths + rejects excluded ones' {
      Test-IsHotSpec -Path 'core/process.md' | Should -BeTrue
      Test-IsHotSpec -Path 'core/process/phase-4-implementation.md' | Should -BeTrue
      Test-IsHotSpec -Path 'core/protocols/hot-spec-format.md' | Should -BeTrue
      Test-IsHotSpec -Path 'core/roles/team-lead.md' | Should -BeTrue
      Test-IsHotSpec -Path 'core/roles/team-lead.details.md' | Should -BeTrue
      # Out-of-scope surfaces
      Test-IsHotSpec -Path 'core/templates/phase-report.md' | Should -BeFalse
      Test-IsHotSpec -Path 'core/skills/ginee-update/SKILL.md' | Should -BeFalse
      Test-IsHotSpec -Path 'local/roles/custom-role.md' | Should -BeFalse
      Test-IsHotSpec -Path 'CLAUDE.md' | Should -BeFalse
      Test-IsHotSpec -Path 'adapters/claude/install.md' | Should -BeFalse
    }

    It 'Read-HotSpecFrontmatter parses a well-formed block' {
      $lines = $script:validFrontmatter -split "`n"
      $fm = Read-HotSpecFrontmatter -Lines $lines
      $fm | Should -Not -BeNullOrEmpty
      $fm['audience'] | Should -Be 'all-cardinals'
      $fm['load'] | Should -Be 'on-demand'
      $fm['cap-bytes'] | Should -Be 4096
      ,$fm['triggers'] | Should -BeOfType [object[]]
      $fm['triggers'].Count | Should -Be 2
    }

    It 'Read-HotSpecFrontmatter returns null when no frontmatter is present' {
      $lines = $script:noFrontmatter -split "`n"
      Read-HotSpecFrontmatter -Lines $lines | Should -BeNullOrEmpty
    }

    It 'passes a file with valid frontmatter (no failures, gate clean)' {
      $root = New-SandboxRepoWithHotSpec -Files @{ 'core/protocols/hot-spec-format.md' = $script:validFrontmatter }
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 0
        $r.Json.hotSpecFailures.Count | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'fails when an in-scope file lacks frontmatter and no trailer is present' {
      $root = New-SandboxRepoWithHotSpec -Files @{ 'core/protocols/some-spec.md' = $script:noFrontmatter }
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 1
        $r.Json.gateFail | Should -BeTrue
        $r.Json.hotSpecFailures.Count | Should -Be 1
        $r.Json.hotSpecFailures[0].Path | Should -Be 'core/protocols/some-spec.md'
        $r.Json.hotSpecFailures[0].Reason | Should -Be 'missing'
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'passes a missing-frontmatter file when the Optimized-By trailer is present' {
      $root = New-SandboxRepoWithHotSpec -Files @{ 'core/protocols/some-spec.md' = $script:noFrontmatter } -WithTrailer
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 0
        $r.Json.markerPresent | Should -BeTrue
        # Failures are still reported (transparency), but the gate passes.
        $r.Json.hotSpecFailures.Count | Should -Be 1
        $r.Json.gateFail | Should -BeFalse
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'fails when frontmatter is malformed (missing required key: load)' {
      $root = New-SandboxRepoWithHotSpec -Files @{ 'core/protocols/some-spec.md' = $script:malformedMissingLoad }
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 1
        $r.Json.hotSpecFailures.Count | Should -Be 1
        $r.Json.hotSpecFailures[0].Reason | Should -Be 'missing-key'
        $r.Json.hotSpecFailures[0].Detail | Should -Match 'load'
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'fails when load: on-demand but triggers is an empty list' {
      $root = New-SandboxRepoWithHotSpec -Files @{ 'core/protocols/some-spec.md' = $script:emptyTriggers }
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 1
        $r.Json.hotSpecFailures[0].Reason | Should -Be 'empty-triggers'
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'fails when load value is outside the allowed enum' {
      $root = New-SandboxRepoWithHotSpec -Files @{ 'core/protocols/some-spec.md' = $script:invalidLoad }
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 1
        $r.Json.hotSpecFailures[0].Reason | Should -Be 'invalid-load'
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'allows load: always without triggers key' {
      $root = New-SandboxRepoWithHotSpec -Files @{ 'core/process.md' = $script:loadAlwaysNoTriggers }
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 0
        $r.Json.hotSpecFailures.Count | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'fails when cap-bytes is not a positive integer' {
      $root = New-SandboxRepoWithHotSpec -Files @{ 'core/process.md' = $script:invalidCapBytes }
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 1
        $r.Json.hotSpecFailures[0].Reason | Should -Be 'invalid-cap-bytes'
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'ignores out-of-scope files (templates, skills, local/roles)' {
      $root = New-SandboxRepoWithHotSpec -Files @{
        'core/templates/some-template.md' = $script:noFrontmatter
        'core/skills/ginee-update/SKILL.md' = $script:noFrontmatter
      }
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Json.hotSpecFailures.Count | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'emits human-readable hot-spec failure block when -Json is unset' {
      $root = New-SandboxRepoWithHotSpec -Files @{ 'core/protocols/some-spec.md' = $script:noFrontmatter }
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main' }
        $r.Code | Should -Be 1
        $r.Output | Should -Match 'Hot-spec frontmatter'
        $r.Output | Should -Match 'hot-spec-format.md'
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'flags an unclosed YAML frontmatter block as missing (no terminating ---)' {
      $unclosed = @(
        '---'
        'audience: all-cardinals'
        'load: always'
        'cap-bytes: 4096'
        'reads-before-applying: []'
        ''
        '# Body — no closing --- delimiter'
      ) -join "`n"
      $root = New-SandboxRepoWithHotSpec -Files @{ 'core/protocols/some-spec.md' = $unclosed }
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 1
        $r.Json.hotSpecFailures[0].Reason | Should -Be 'missing'
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'fails when load: on-demand AND triggers key is entirely absent' {
      $onDemandNoTriggers = @(
        '---'
        'audience: all-cardinals'
        'load: on-demand'
        'cap-bytes: 4096'
        'reads-before-applying: []'
        '---'
        ''
        '# Body'
      ) -join "`n"
      $root = New-SandboxRepoWithHotSpec -Files @{ 'core/protocols/some-spec.md' = $onDemandNoTriggers }
      try {
        $r = Invoke-CheckInProc -Root $root -Params @{ BaseRef = 'main'; Json = $true }
        $r.Code | Should -Be 1
        $r.Json.hotSpecFailures[0].Reason | Should -Be 'missing-key'
        $r.Json.hotSpecFailures[0].Detail | Should -Match 'triggers'
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'Read-HotSpecFrontmatter strips inline scalar comments' {
      $lines = @(
        '---'
        'audience: all-cardinals  # narrowest applicable cardinality'
        'load: always'
        'cap-bytes: 4096'
        'reads-before-applying: []'
        '---'
      )
      $fm = Read-HotSpecFrontmatter -Lines $lines
      $fm['audience'] | Should -Be 'all-cardinals'
    }

    It 'Get-HotSpecFileContent returns $null for a missing path (all three modes)' {
      $root = New-SandboxRepo
      try {
        Push-Location $root
        try {
          $missing = 'core/protocols/does-not-exist.md'
          (Get-HotSpecFileContent -Path $missing -Mode 'Range'      -RepoRoot $root) | Should -BeNullOrEmpty
          (Get-HotSpecFileContent -Path $missing -Mode 'Staged'     -RepoRoot $root) | Should -BeNullOrEmpty
          (Get-HotSpecFileContent -Path $missing -Mode 'ClaudeHook' -RepoRoot $root) | Should -BeNullOrEmpty
        } finally { Pop-Location }
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'Read-HotSpecFrontmatter returns $null for empty / one-line input' {
      Read-HotSpecFrontmatter -Lines @() | Should -BeNullOrEmpty
      Read-HotSpecFrontmatter -Lines @('---') | Should -BeNullOrEmpty
    }

    It 'Get-HotSpecFileContent returns content in Staged mode' {
      $root = New-SandboxRepoWithHotSpec -Files @{}
      try {
        Push-Location $root
        try {
          $abs = Join-Path $root 'core/protocols/staged-spec.md'
          New-Item -ItemType Directory -Force -Path (Split-Path $abs -Parent) | Out-Null
          Set-Content -LiteralPath $abs -Value $script:validFrontmatter
          & git add . *> $null
        } finally { Pop-Location }
        $r = Invoke-CheckInProc -Root $root -Params @{ StagedOnly = $true; Json = $true }
        $r.Code | Should -Be 0
        $r.Json.hotSpecFailures.Count | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'Get-HotSpecFileContent returns content in ClaudeHook (working-tree) mode' {
      # Stage a committed file first, then modify the working tree so
      # `git diff HEAD` reports the path. ClaudeHook diffs working-tree vs HEAD.
      $root = New-SandboxRepoWithHotSpec -Files @{ 'core/protocols/wt-spec.md' = $script:validFrontmatter }
      try {
        $abs = Join-Path $root 'core/protocols/wt-spec.md'
        Set-Content -LiteralPath $abs -Value $script:noFrontmatter
        $r = Invoke-CheckInProc -Root $root -Params @{ ClaudeHook = $true; Json = $true }
        $r.Code | Should -Be 1
        ($r.Json.hotSpecFailures | Where-Object { $_.Path -eq 'core/protocols/wt-spec.md' }).Reason | Should -Be 'missing'
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }
  }

  Context 'End-to-end via -File (cross-platform invocation contract)' {
    It 'returns exit code 0 on clean tree when invoked via pwsh -File' {
      $root = New-SandboxRepo
      try {
        $allArgs = @('-NoProfile', '-File', $script:scriptPath, '-RepoRoot', $root, '-ClaudeHook')
        $null = & pwsh @allArgs 2>&1
        $LASTEXITCODE | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }

    It 'returns exit code 1 on threshold breach when invoked via pwsh -File' {
      $root = New-SandboxRepo
      try {
        $bloat = (1..60 | ForEach-Object { "- bullet $_" }) -join "`n"
        Set-Content -LiteralPath (Join-Path $root 'CLAUDE.md') -Value "baseline`n$bloat"
        $allArgs = @('-NoProfile', '-File', $script:scriptPath, '-RepoRoot', $root, '-ClaudeHook')
        $null = & pwsh @allArgs 2>&1
        $LASTEXITCODE | Should -Be 1
      } finally {
        Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
      }
    }
  }
}
