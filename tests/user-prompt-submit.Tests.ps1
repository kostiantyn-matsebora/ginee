BeforeAll {
  $script:hookScript = (Resolve-Path "$PSScriptRoot/../adapters/claude/hooks/user-prompt-submit.ps1").Path
  $script:repoRoot   = (Resolve-Path "$PSScriptRoot/..").Path
  $script:triggers   = (Resolve-Path "$PSScriptRoot/../adapters/claude/hooks/keyword-triggers.yaml").Path

  function Invoke-Hook {
    param([string]$Json, [string]$Root = $null, [string]$Triggers = $null)
    if (-not $Root)     { $Root = $script:repoRoot }
    if (-not $Triggers) { $Triggers = $script:triggers }
    $inFile  = New-TemporaryFile
    $outFile = New-TemporaryFile
    $errFile = New-TemporaryFile
    try {
      [System.IO.File]::WriteAllText($inFile.FullName, $Json)
      $p = Start-Process -FilePath 'pwsh' `
        -ArgumentList @('-NoProfile','-File',$script:hookScript,'-RepoRoot',$Root,'-TriggersFile',$Triggers) `
        -NoNewWindow -PassThru -Wait `
        -RedirectStandardInput $inFile.FullName `
        -RedirectStandardOutput $outFile.FullName `
        -RedirectStandardError $errFile.FullName
      $out = Get-Content -Raw -LiteralPath $outFile.FullName -ErrorAction SilentlyContinue
      $err = Get-Content -Raw -LiteralPath $errFile.FullName -ErrorAction SilentlyContinue
      return [pscustomobject]@{
        ExitCode = $p.ExitCode
        StdOut   = ($out ?? '')
        StdErr   = ($err ?? '')
      }
    } finally {
      Remove-Item -ErrorAction SilentlyContinue -LiteralPath $inFile.FullName
      Remove-Item -ErrorAction SilentlyContinue -LiteralPath $outFile.FullName
      Remove-Item -ErrorAction SilentlyContinue -LiteralPath $errFile.FullName
    }
  }

  function Get-Payload {
    param([string]$Prompt)
    @{ hook_event_name = 'UserPromptSubmit'; prompt = $Prompt } | ConvertTo-Json -Compress
  }
}

Describe 'user-prompt-submit.ps1' {

  It 'parses cleanly' {
    { [scriptblock]::Create((Get-Content -Raw $script:hookScript)) } | Should -Not -Throw
  }

  Context 'pass-through (no trigger)' {
    It 'exits 0 with empty stdout on a benign prompt' {
      $r = Invoke-Hook -Json (Get-Payload -Prompt 'just chatting about the weather')
      $r.ExitCode | Should -Be 0
      $r.StdOut.Trim() | Should -Be ''
    }

    It 'exits 0 on empty payload' {
      $r = Invoke-Hook -Json ''
      $r.ExitCode | Should -Be 0
      $r.StdOut.Trim() | Should -Be ''
    }

    It 'exits 0 on malformed JSON (fail-open)' {
      $r = Invoke-Hook -Json 'not-json{'
      $r.ExitCode | Should -Be 0
      $r.StdOut.Trim() | Should -Be ''
    }

    It 'exits 0 when prompt field is missing' {
      $r = Invoke-Hook -Json '{"hook_event_name":"UserPromptSubmit"}'
      $r.ExitCode | Should -Be 0
      $r.StdOut.Trim() | Should -Be ''
    }
  }

  Context 'pick-up trigger' {
    It 'injects ginee-pick-up context on "pick up #141"' {
      $r = Invoke-Hook -Json (Get-Payload -Prompt 'pick up #141 please')
      $r.ExitCode | Should -Be 0
      $r.StdOut | Should -Match '\[ginee:context:ginee-pick-up\]'
      $r.StdOut | Should -Match 'core/skills/ginee-pick-up/SKILL\.md'
    }

    It 'injects ginee-pick-up context on "work on issue #141"' {
      $r = Invoke-Hook -Json (Get-Payload -Prompt 'work on issue #141')
      $r.ExitCode | Should -Be 0
      $r.StdOut | Should -Match '\[ginee:context:ginee-pick-up\]'
    }

    It 'emits a valid JSON envelope with hookSpecificOutput' {
      $r = Invoke-Hook -Json (Get-Payload -Prompt 'pick up #141')
      $r.ExitCode | Should -Be 0
      $obj = $r.StdOut | ConvertFrom-Json
      $obj.hookSpecificOutput.hookEventName | Should -Be 'UserPromptSubmit'
      $obj.hookSpecificOutput.additionalContext | Should -Match 'ginee-pick-up'
    }
  }

  Context 'auto-mode trigger' {
    It 'injects automatic-mode context on "auto: pick up #141"' {
      $r = Invoke-Hook -Json (Get-Payload -Prompt 'auto: pick up #141')
      $r.ExitCode | Should -Be 0
      $r.StdOut | Should -Match '\[ginee:context:automatic-mode\]'
      $r.StdOut | Should -Match 'core/protocols/automatic-mode\.md'
    }
  }

  Context 'multiple-trigger composition' {
    It 'injects both ginee-pick-up and automatic-mode on a compound prompt' {
      $r = Invoke-Hook -Json (Get-Payload -Prompt 'auto: pick up #141 in branch:')
      $r.ExitCode | Should -Be 0
      $r.StdOut | Should -Match '\[ginee:context:ginee-pick-up\]'
      $r.StdOut | Should -Match '\[ginee:context:automatic-mode\]'
      $r.StdOut | Should -Match '\[ginee:context:delivery-modes\]'
    }
  }

  Context 'dispatch trigger' {
    It 'injects dispatch-prompt-schema on @solution-architect' {
      $r = Invoke-Hook -Json (Get-Payload -Prompt 'dispatch @solution-architect for an ADR')
      $r.ExitCode | Should -Be 0
      $r.StdOut | Should -Match '\[ginee:context:dispatch-prompt-schema\]'
      $r.StdOut | Should -Match 'self-lint: pass'
    }
  }

  Context 'opt-out via SKIP_GINEE_COMPLIANCE' {
    It 'exits 0 with empty stdout when SKIP_GINEE_COMPLIANCE=1' {
      $prev = $env:SKIP_GINEE_COMPLIANCE
      try {
        $env:SKIP_GINEE_COMPLIANCE = '1'
        $r = Invoke-Hook -Json (Get-Payload -Prompt 'pick up #141')
        $r.ExitCode | Should -Be 0
        $r.StdOut.Trim() | Should -Be ''
      } finally {
        if ($null -eq $prev) { Remove-Item Env:\SKIP_GINEE_COMPLIANCE -ErrorAction SilentlyContinue }
        else { $env:SKIP_GINEE_COMPLIANCE = $prev }
      }
    }
  }

  Context 'opt-out via framework.config.yaml' {
    It 'exits 0 with empty stdout when tactic listed under compliance.disabled' {
      $tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "ginee-upshook-$(Get-Random)")
      try {
        # Seed a fake repo root with framework.config.yaml opting this hook out.
        $local = Join-Path $tmp.FullName 'local'
        New-Item -ItemType Directory -Path $local | Out-Null
        Set-Content -LiteralPath (Join-Path $local 'framework.config.yaml') -Value @"
compliance:
  disabled:
    - user-prompt-submit-hook
"@ -NoNewline

        # Initialise git so Get-RepoRoot returns the temp dir.
        Push-Location $tmp.FullName
        & git init --quiet 2>&1 | Out-Null
        & git config user.email "t@t" 2>&1 | Out-Null
        & git config user.name "t" 2>&1 | Out-Null
        & git commit --allow-empty --quiet -m "x" 2>&1 | Out-Null
        Pop-Location

        $r = Invoke-Hook -Json (Get-Payload -Prompt 'pick up #141') -Root $tmp.FullName
        $r.ExitCode | Should -Be 0
        $r.StdOut.Trim() | Should -Be ''
      } finally {
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $tmp.FullName
      }
    }
  }
}
