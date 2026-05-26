BeforeAll {
  $script:hookScript = (Resolve-Path "$PSScriptRoot/../adapters/claude/hooks/pre-tool-use-bash.ps1").Path
  $script:repoRoot   = (Resolve-Path "$PSScriptRoot/..").Path

  function Invoke-Hook {
    param([string]$Json, [string]$Root = $null)
    if (-not $Root) { $Root = $script:repoRoot }
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

  function Get-BashPayload {
    param([string]$Command)
    @{
      tool_name  = 'Bash'
      tool_input = @{ command = $Command }
    } | ConvertTo-Json -Depth 4 -Compress
  }
}

Describe 'pre-tool-use-bash.ps1' {

  It 'parses cleanly' {
    { [scriptblock]::Create((Get-Content -Raw $script:hookScript)) } | Should -Not -Throw
  }

  Context 'pass-through (no violation)' {
    It 'exits 0 on a non-Bash tool' {
      $r = Invoke-Hook -Json '{"tool_name":"Read","tool_input":{"file_path":"x"}}'
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 on empty payload' {
      $r = Invoke-Hook -Json ''
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 on a benign Bash command' {
      $r = Invoke-Hook -Json (Get-BashPayload -Command 'ls -la')
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 on a normal git commit' {
      $r = Invoke-Hook -Json (Get-BashPayload -Command 'git commit -m "feat: add foo"')
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 on git push to a feature branch' {
      $r = Invoke-Hook -Json (Get-BashPayload -Command 'git push --force-with-lease origin feat/my-branch')
      $r.ExitCode | Should -Be 0
    }
  }

  Context 'Violation 1 — git commit --no-verify' {
    It 'blocks git commit --no-verify' {
      $r = Invoke-Hook -Json (Get-BashPayload -Command 'git commit -m "msg" --no-verify')
      $r.ExitCode | Should -Be 2
      $r.StdErr  | Should -Match 'git commit --no-verify blocked'
    }

    It 'blocks git commit -n short flag' {
      $r = Invoke-Hook -Json (Get-BashPayload -Command 'git commit -n -m "msg"')
      $r.ExitCode | Should -Be 2
    }
  }

  Context 'Violation 2 — git push --force on main' {
    It 'blocks git push --force origin main' {
      $r = Invoke-Hook -Json (Get-BashPayload -Command 'git push --force origin main')
      $r.ExitCode | Should -Be 2
      $r.StdErr  | Should -Match 'force on main'
    }

    It 'blocks git push -f master' {
      $r = Invoke-Hook -Json (Get-BashPayload -Command 'git push -f origin master')
      $r.ExitCode | Should -Be 2
    }

    It 'allows git push --force-with-lease on a feature branch' {
      $r = Invoke-Hook -Json (Get-BashPayload -Command 'git push --force-with-lease origin feat/wip')
      $r.ExitCode | Should -Be 0
    }
  }

  Context 'Violation 3 — git reset --hard' {
    It 'blocks git reset --hard' {
      $r = Invoke-Hook -Json (Get-BashPayload -Command 'git reset --hard HEAD~1')
      $r.ExitCode | Should -Be 2
      $r.StdErr  | Should -Match 'git reset --hard blocked'
    }

    It 'allows git reset --soft' {
      $r = Invoke-Hook -Json (Get-BashPayload -Command 'git reset --soft HEAD~1')
      $r.ExitCode | Should -Be 0
    }
  }

  Context 'Violation 4 — gh pr create without --body' {
    It 'blocks gh pr create with no --body / --draft' {
      $r = Invoke-Hook -Json (Get-BashPayload -Command 'gh pr create --title "x"')
      $r.ExitCode | Should -Be 2
      $r.StdErr  | Should -Match 'missing PR body'
    }

    It 'allows gh pr create --body "..."' {
      $r = Invoke-Hook -Json (Get-BashPayload -Command 'gh pr create --title "x" --body "body"')
      $r.ExitCode | Should -Be 0
    }

    It 'allows gh pr create --draft' {
      $r = Invoke-Hook -Json (Get-BashPayload -Command 'gh pr create --draft --title "x"')
      $r.ExitCode | Should -Be 0
    }
  }

  Context 'opt-out via local/framework.config.yaml' {
    BeforeEach {
      $script:fakeRoot = (New-Item -ItemType Directory -Force `
        -Path (Join-Path ([System.IO.Path]::GetTempPath()) "ginee-pretool-bash-test-$([guid]::NewGuid().Guid)")).FullName
      New-Item -ItemType Directory -Force -Path "$script:fakeRoot/local" | Out-Null
      Push-Location $script:fakeRoot
      & git init --quiet 2>&1 | Out-Null
    }

    AfterEach {
      Pop-Location
      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $script:fakeRoot
    }

    It 'exits 0 when the tactic is listed under compliance.disabled' {
      $cfg = "compliance:`n  disabled:`n    - pretooluse-bash-hook`n"
      [System.IO.File]::WriteAllText("$script:fakeRoot/local/framework.config.yaml", $cfg)
      $r = Invoke-Hook -Json (Get-BashPayload -Command 'git reset --hard HEAD~1') -Root $script:fakeRoot
      $r.ExitCode | Should -Be 0
    }
  }

  Context 'SKIP_GINEE_COMPLIANCE bypass' {
    It 'exits 0 when SKIP_GINEE_COMPLIANCE=1' {
      $env:SKIP_GINEE_COMPLIANCE = '1'
      try {
        & pwsh -NoProfile -File $script:hookScript -RepoRoot $script:repoRoot *>$null
        $LASTEXITCODE | Should -Be 0
      } finally {
        Remove-Item Env:\SKIP_GINEE_COMPLIANCE -ErrorAction SilentlyContinue
      }
    }
  }
}
