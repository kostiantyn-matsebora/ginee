#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.5.0' }

BeforeAll {
  $script:hookScript = (Resolve-Path "$PSScriptRoot/../adapters/claude/hooks/pre-tool-use-task.ps1").Path
  $script:repoRoot   = (Resolve-Path "$PSScriptRoot/..").Path

  function Invoke-Hook {
    param([string]$Json, [string]$Root = $null)
    if (-not $Root)  { $Root  = $script:repoRoot }
    $inFile  = New-TemporaryFile
    $errFile = New-TemporaryFile
    try {
      [System.IO.File]::WriteAllText($inFile.FullName, $Json)
      $p = Start-Process -FilePath 'pwsh' `
        -ArgumentList @('-NoProfile','-File',$script:hookScript,'-RepoRoot',$Root) `
        -NoNewWindow -PassThru -Wait `
        -RedirectStandardInput $inFile.FullName `
        -RedirectStandardError $errFile.FullName
      $err = Get-Content -Raw -LiteralPath $errFile.FullName -ErrorAction SilentlyContinue
      return [pscustomobject]@{ ExitCode = $p.ExitCode; StdErr = ($err ?? '') }
    } finally {
      Remove-Item -ErrorAction SilentlyContinue -LiteralPath $inFile.FullName
      Remove-Item -ErrorAction SilentlyContinue -LiteralPath $errFile.FullName
    }
  }

  function Get-TaskPayload {
    param([string]$Subagent, [string]$Prompt)
    @{
      hook_event_name = 'PreToolUse'
      tool_name       = 'Task'
      tool_input      = @{ subagent_type = $Subagent; prompt = $Prompt }
    } | ConvertTo-Json -Compress -Depth 4
  }
}

Describe 'pre-tool-use-task.ps1 — #182 SA boundary timing axis' {

  It 'parses cleanly' {
    { [scriptblock]::Create((Get-Content -Raw $script:hookScript)) } | Should -Not -Throw
  }

  Context 'pass-through' {
    It 'exits 0 on non-Task tool' {
      $r = Invoke-Hook -Json '{"tool_name":"Bash","tool_input":{"command":"ls"}}'
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 on empty payload' {
      $r = Invoke-Hook -Json ''
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 when Task targets a non-SA cardinal in Phase 4' {
      $r = Invoke-Hook -Json (Get-TaskPayload 'backend-engineer' 'Implement Phase 4 backend changes')
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 when Task targets SA in Phase 1' {
      $r = Invoke-Hook -Json (Get-TaskPayload 'solution-architect' 'Run Phase 1 design dip and elicit FRs/NFRs')
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 when Task targets SA in Phase 2' {
      $r = Invoke-Hook -Json (Get-TaskPayload 'solution-architect' 'Author Phase 2 architecture doc + ADRs')
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 when Task targets SA in Phase 7' {
      $r = Invoke-Hook -Json (Get-TaskPayload 'solution-architect' 'Phase 7 governance review of the PR')
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 when Task targets SA with no phase indicator' {
      $r = Invoke-Hook -Json (Get-TaskPayload 'solution-architect' 'Review the ASR utility tree')
      $r.ExitCode | Should -Be 0
    }
  }

  Context 'hard gate — SA dispatch in Phase 4 / 5 / 6 blocked' {
    It 'blocks SA dispatch mentioning Phase 4' {
      $r = Invoke-Hook -Json (Get-TaskPayload 'solution-architect' 'Review the architecture changes in Phase 4 implementation')
      $r.ExitCode | Should -Be 2
      $r.StdErr | Should -Match '#182'
      $r.StdErr | Should -Match 'categorical refusal'
    }

    It 'blocks SA dispatch mentioning Phase 5' {
      $r = Invoke-Hook -Json (Get-TaskPayload 'solution-architect' 'Address NFR-oracle red mid-Phase 5')
      $r.ExitCode | Should -Be 2
    }

    It 'blocks SA dispatch mentioning Phase 6' {
      $r = Invoke-Hook -Json (Get-TaskPayload 'solution-architect' 'Review the architectural fix proposal during Phase 6')
      $r.ExitCode | Should -Be 2
    }

    It 'blocks SA dispatch mentioning phase-4-implementation' {
      $r = Invoke-Hook -Json (Get-TaskPayload 'solution-architect' 'Read phase-4-implementation.md and dispatch')
      $r.ExitCode | Should -Be 2
    }

    It 'blocks case-insensitive PHASE 5' {
      $r = Invoke-Hook -Json (Get-TaskPayload 'solution-architect' 'PHASE 5 NFR check')
      $r.ExitCode | Should -Be 2
    }

    It 'blocks alternate target field — agent_name' {
      $payload = @{
        hook_event_name = 'PreToolUse'
        tool_name       = 'Task'
        tool_input      = @{ agent_name = 'solution-architect'; prompt = 'Phase 4 dip' }
      } | ConvertTo-Json -Compress -Depth 4
      $r = Invoke-Hook -Json $payload
      $r.ExitCode | Should -Be 2
    }
  }

  Context 'opt-out' {
    It 'honours SKIP_GINEE_COMPLIANCE=1' {
      $orig = $env:SKIP_GINEE_COMPLIANCE
      try {
        $env:SKIP_GINEE_COMPLIANCE = '1'
        $r = Invoke-Hook -Json (Get-TaskPayload 'solution-architect' 'Phase 4 dip')
        $r.ExitCode | Should -Be 0
      } finally {
        $env:SKIP_GINEE_COMPLIANCE = $orig
      }
    }
  }
}
