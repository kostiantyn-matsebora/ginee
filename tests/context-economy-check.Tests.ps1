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
