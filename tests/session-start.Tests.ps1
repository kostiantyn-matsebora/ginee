BeforeAll {
  $script:hookScript = (Resolve-Path "$PSScriptRoot/../adapters/claude/hooks/session-start.ps1").Path

  function Invoke-Hook {
    param([string]$Json, [string]$Root, [switch]$NoGh)
    if (-not $Root) { $Root = (Resolve-Path "$PSScriptRoot/..").Path }
    $inFile  = New-TemporaryFile
    $outFile = New-TemporaryFile
    $errFile = New-TemporaryFile
    try {
      [System.IO.File]::WriteAllText($inFile.FullName, ($Json ?? ''))
      $argList = @('-NoProfile','-File',$script:hookScript,'-RepoRoot',$Root)
      if ($NoGh) { $argList += '-NoGh' }
      $p = Start-Process -FilePath 'pwsh' `
        -ArgumentList $argList `
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

  function New-FakeRepo {
    param([string]$Branch = 'main')
    $tmp = New-Item -ItemType Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) "ginee-sshook-$([guid]::NewGuid().Guid)")
    Push-Location $tmp.FullName
    try {
      & git init --quiet 2>&1 | Out-Null
      & git config user.email "t@t" 2>&1 | Out-Null
      & git config user.name "t" 2>&1 | Out-Null
      & git checkout -b main --quiet 2>&1 | Out-Null
      & git commit --allow-empty --quiet -m "initial" 2>&1 | Out-Null
      # Fake origin/main so rev-list count is well-defined.
      & git update-ref refs/remotes/origin/main HEAD 2>&1 | Out-Null
      if ($Branch -ne 'main') {
        & git checkout -b $Branch --quiet 2>&1 | Out-Null
      }
    } finally { Pop-Location }
    return $tmp.FullName
  }

  function Disable-OptOut {
    param([string]$Root, [string]$TacticId)
    $local = Join-Path $Root 'local'
    New-Item -ItemType Directory -Path $local -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $local 'framework.config.yaml') -Value @"
compliance:
  disabled:
    - $TacticId
"@ -NoNewline
  }
}

Describe 'session-start.ps1' {

  It 'parses cleanly' {
    { [scriptblock]::Create((Get-Content -Raw $script:hookScript)) } | Should -Not -Throw
  }

  Context 'quiet on empty' {
    It 'exits 0 with empty stdout outside an issue/* branch and no in-progress issues' {
      $root = New-FakeRepo -Branch 'main'
      try {
        $r = Invoke-Hook -Json '{"hook_event_name":"SessionStart"}' -Root $root -NoGh
        $r.ExitCode | Should -Be 0
        $r.StdOut.Trim() | Should -Be ''
      } finally { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $root }
    }

    It 'exits 0 with empty stdout on empty payload (no inject)' {
      $root = New-FakeRepo -Branch 'main'
      try {
        $r = Invoke-Hook -Json '' -Root $root -NoGh
        $r.ExitCode | Should -Be 0
        $r.StdOut.Trim() | Should -Be ''
      } finally { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $root }
    }
  }

  Context 'branch scan' {
    It 'injects the branch line when on issue/<N>-... with origin/main set' {
      $root = New-FakeRepo -Branch 'issue/148-session-start'
      try {
        $r = Invoke-Hook -Json '{"hook_event_name":"SessionStart"}' -Root $root -NoGh
        $r.ExitCode | Should -Be 0
        $r.StdOut | Should -Match '\[ginee:resume\]'
        $r.StdOut | Should -Match 'branch:\s*issue/148-session-start'
      } finally { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $root }
    }

    It 'marks uncommitted changes' {
      $root = New-FakeRepo -Branch 'issue/148-session-start'
      try {
        Set-Content -LiteralPath (Join-Path $root 'dirty.txt') -Value 'x'
        $r = Invoke-Hook -Json '{"hook_event_name":"SessionStart"}' -Root $root -NoGh
        $r.ExitCode | Should -Be 0
        $r.StdOut | Should -Match 'uncommitted changes'
      } finally { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $root }
    }

    It 'skips branch line on non-issue branch names' {
      $root = New-FakeRepo -Branch 'feature/foo'
      try {
        $r = Invoke-Hook -Json '{"hook_event_name":"SessionStart"}' -Root $root -NoGh
        $r.ExitCode | Should -Be 0
        $r.StdOut.Trim() | Should -Be ''
      } finally { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $root }
    }
  }

  Context 'envelope shape' {
    It 'emits hookSpecificOutput.hookEventName = SessionStart' {
      $root = New-FakeRepo -Branch 'issue/148-session-start'
      try {
        $r = Invoke-Hook -Json '{"hook_event_name":"SessionStart"}' -Root $root -NoGh
        $r.ExitCode | Should -Be 0
        $obj = $r.StdOut | ConvertFrom-Json
        $obj.hookSpecificOutput.hookEventName | Should -Be 'SessionStart'
        $obj.hookSpecificOutput.additionalContext | Should -Match '\[ginee:resume\]'
      } finally { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $root }
    }
  }

  Context 'opt-out via SKIP_GINEE_COMPLIANCE' {
    It 'exits 0 with empty stdout when SKIP_GINEE_COMPLIANCE=1' {
      $root = New-FakeRepo -Branch 'issue/148-session-start'
      $prev = $env:SKIP_GINEE_COMPLIANCE
      try {
        $env:SKIP_GINEE_COMPLIANCE = '1'
        $r = Invoke-Hook -Json '{"hook_event_name":"SessionStart"}' -Root $root -NoGh
        $r.ExitCode | Should -Be 0
        $r.StdOut.Trim() | Should -Be ''
      } finally {
        if ($null -eq $prev) { Remove-Item Env:\SKIP_GINEE_COMPLIANCE -ErrorAction SilentlyContinue }
        else { $env:SKIP_GINEE_COMPLIANCE = $prev }
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $root
      }
    }
  }

  Context 'opt-out via framework.config.yaml' {
    It 'exits 0 with empty stdout when tactic listed under compliance.disabled' {
      $root = New-FakeRepo -Branch 'issue/148-session-start'
      try {
        Disable-OptOut -Root $root -TacticId 'session-start-hook'
        $r = Invoke-Hook -Json '{"hook_event_name":"SessionStart"}' -Root $root -NoGh
        $r.ExitCode | Should -Be 0
        $r.StdOut.Trim() | Should -Be ''
      } finally { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $root }
    }
  }

  Context 'fail-open on broken repo state' {
    It 'exits 0 with empty stdout when repo root resolution fails' {
      # Resolve to a path that is NOT a git repo — the hook should fail-open.
      $tmp = New-Item -ItemType Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) "ginee-sshook-bad-$([guid]::NewGuid().Guid)")
      try {
        $r = Invoke-Hook -Json '{"hook_event_name":"SessionStart"}' -Root $tmp.FullName -NoGh
        $r.ExitCode | Should -Be 0
        $r.StdOut.Trim() | Should -Be ''
      } finally { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $tmp.FullName }
    }
  }
}
