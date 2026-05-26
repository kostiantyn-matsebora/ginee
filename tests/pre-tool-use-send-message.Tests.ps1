BeforeAll {
  $script:hookScript = (Resolve-Path "$PSScriptRoot/../adapters/claude/hooks/pre-tool-use-send-message.ps1").Path
  $script:repoRoot   = (Resolve-Path "$PSScriptRoot/..").Path
  $script:rules      = (Resolve-Path "$PSScriptRoot/../adapters/claude/hooks/carry-forward-rules.yaml").Path

  function Invoke-Hook {
    param([string]$Json, [string]$Root = $null, [string]$Rules = $null)
    if (-not $Root)  { $Root  = $script:repoRoot }
    if (-not $Rules) { $Rules = $script:rules }
    $inFile  = New-TemporaryFile
    $errFile = New-TemporaryFile
    try {
      [System.IO.File]::WriteAllText($inFile.FullName, $Json)
      $p = Start-Process -FilePath 'pwsh' `
        -ArgumentList @('-NoProfile','-File',$script:hookScript,'-RepoRoot',$Root,'-RulesFile',$Rules) `
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

  function Get-Payload {
    param([string]$Target, [string]$Message)
    @{
      hook_event_name = 'PreToolUse'
      tool_name       = 'SendMessage'
      tool_input      = @{ to = $Target; message = $Message }
    } | ConvertTo-Json -Compress -Depth 4
  }
}

Describe 'pre-tool-use-send-message.ps1' {

  It 'parses cleanly' {
    { [scriptblock]::Create((Get-Content -Raw $script:hookScript)) } | Should -Not -Throw
  }

  Context 'pass-through' {
    It 'exits 0 on a non-SendMessage tool' {
      $r = Invoke-Hook -Json '{"tool_name":"Bash","tool_input":{"command":"ls"}}'
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 on Agent tool (first-dispatch — explicitly out of scope)' {
      $payload = '{"tool_name":"Agent","tool_input":{"subagent_type":"solution-architect","prompt":"do a thing"}}'
      $r = Invoke-Hook -Json $payload
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 on empty payload' {
      $r = Invoke-Hook -Json ''
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 on missing target field' {
      $payload = '{"tool_name":"SendMessage","tool_input":{"message":"hello"}}'
      $r = Invoke-Hook -Json $payload
      $r.ExitCode | Should -Be 0
    }
  }

  Context 'anchor present' {
    It 'exits 0 when the message leads with [carry-forward]' {
      $msg = "[carry-forward] Remember: lossless rule binds.`nNow apply that to the next batch."
      $r = Invoke-Hook -Json (Get-Payload -Target 'ai-engineer' -Message $msg)
      $r.ExitCode | Should -Be 0
    }

    It 'tolerates leading blank lines before the anchor' {
      $msg = "`n  `n[carry-forward] Remember: foo.`nbody"
      $r = Invoke-Hook -Json (Get-Payload -Target 'ai-engineer' -Message $msg)
      $r.ExitCode | Should -Be 0
    }
  }

  Context 'anchor missing — blocks' {
    It 'blocks SendMessage to ai-engineer without anchor' {
      $r = Invoke-Hook -Json (Get-Payload -Target 'ai-engineer' -Message 'continue the optimization pass on core/process.md')
      $r.ExitCode | Should -Be 2
      $r.StdErr | Should -Match 'carry-forward'
      $r.StdErr | Should -Match 'lossless rule binds'
    }

    It 'blocks SendMessage to solution-architect with the SA-specific rule' {
      $r = Invoke-Hook -Json (Get-Payload -Target 'solution-architect' -Message 'review the next ADR draft please')
      $r.ExitCode | Should -Be 2
      $r.StdErr | Should -Match 'APPROVE / REJECT / REQUEST-CHANGES only'
    }

    It 'blocks SendMessage to team-lead with the team-lead rule' {
      $r = Invoke-Hook -Json (Get-Payload -Target 'team-lead' -Message 'pick up the next cardinal return')
      $r.ExitCode | Should -Be 2
      $r.StdErr | Should -Match 'skill-runner boundary'
    }

    It 'falls back to a generic rule on an unknown target' {
      $r = Invoke-Hook -Json (Get-Payload -Target 'unknown-cardinal' -Message 'continue')
      $r.ExitCode | Should -Be 2
      $r.StdErr | Should -Match "stay within your role"
    }
  }

  Context 'opt-out' {
    It 'exits 0 when SKIP_GINEE_COMPLIANCE=1' {
      $prev = $env:SKIP_GINEE_COMPLIANCE
      try {
        $env:SKIP_GINEE_COMPLIANCE = '1'
        $r = Invoke-Hook -Json (Get-Payload -Target 'ai-engineer' -Message 'no anchor')
        $r.ExitCode | Should -Be 0
      } finally {
        if ($null -eq $prev) { Remove-Item Env:\SKIP_GINEE_COMPLIANCE -ErrorAction SilentlyContinue }
        else { $env:SKIP_GINEE_COMPLIANCE = $prev }
      }
    }

    It 'exits 0 when tactic listed under compliance.disabled' {
      $tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "ginee-smsg-$(Get-Random)")
      try {
        $local = Join-Path $tmp.FullName 'local'
        New-Item -ItemType Directory -Path $local | Out-Null
        Set-Content -LiteralPath (Join-Path $local 'framework.config.yaml') -Value @"
compliance:
  disabled:
    - pretooluse-send-message-hook
"@ -NoNewline
        Push-Location $tmp.FullName
        & git init --quiet 2>&1 | Out-Null
        & git config user.email "t@t" 2>&1 | Out-Null
        & git config user.name "t" 2>&1 | Out-Null
        & git commit --allow-empty --quiet -m "x" 2>&1 | Out-Null
        Pop-Location

        $r = Invoke-Hook -Json (Get-Payload -Target 'ai-engineer' -Message 'no anchor') -Root $tmp.FullName
        $r.ExitCode | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $tmp.FullName
      }
    }
  }
}
