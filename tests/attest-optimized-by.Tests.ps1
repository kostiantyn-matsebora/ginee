BeforeAll {
  $script:hookScript = (Resolve-Path "$PSScriptRoot/../adapters/claude/hooks/attest-optimized-by.ps1").Path

  function Invoke-Hook {
    param([string]$Json, [string]$Root = $null, [string]$Transcript = $null, [string]$Range = $null)
    $inFile  = New-TemporaryFile
    $outFile = New-TemporaryFile
    $errFile = New-TemporaryFile
    try {
      [System.IO.File]::WriteAllText($inFile.FullName, ($Json ?? ''))
      $argList = @('-NoProfile','-File',$script:hookScript)
      if ($Root)       { $argList += @('-RepoRoot', $Root) }
      if ($Transcript) { $argList += @('-TranscriptOverride', $Transcript) }
      if ($Range)      { $argList += @('-RangeOverride', $Range) }
      $p = Start-Process -FilePath 'pwsh' -ArgumentList $argList `
        -NoNewWindow -PassThru -Wait `
        -RedirectStandardInput  $inFile.FullName `
        -RedirectStandardOutput $outFile.FullName `
        -RedirectStandardError  $errFile.FullName
      $out = Get-Content -Raw -LiteralPath $outFile.FullName -ErrorAction SilentlyContinue
      return [pscustomobject]@{
        ExitCode = $p.ExitCode
        StdOut   = ($out ?? '')
      }
    } finally {
      Remove-Item -ErrorAction SilentlyContinue -LiteralPath $inFile.FullName
      Remove-Item -ErrorAction SilentlyContinue -LiteralPath $outFile.FullName
      Remove-Item -ErrorAction SilentlyContinue -LiteralPath $errFile.FullName
    }
  }

  # New-FakeRepo seeds a repo with a `base` ref + commits on top of it. Each commit
  # body in $CommitBodies lands as a separate commit; the range used in tests is
  # `base..HEAD`. Test fixture — ShouldProcess suppression is intentional.
  function New-FakeRepo {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param([string[]]$CommitBodies = @())
    $tmp = New-Item -ItemType Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) "ginee-attest-$([guid]::NewGuid().Guid)")
    Push-Location $tmp.FullName
    try {
      & git init --quiet 2>&1 | Out-Null
      & git config user.email "t@t" 2>&1 | Out-Null
      & git config user.name "t" 2>&1 | Out-Null
      & git commit --allow-empty --quiet -m "base" 2>&1 | Out-Null
      & git tag base 2>&1 | Out-Null
      $i = 0
      foreach ($body in $CommitBodies) {
        $i++
        & git commit --allow-empty --quiet -m $body 2>&1 | Out-Null
      }
    } finally { Pop-Location }
    return $tmp.FullName
  }

  function New-Transcript {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param([string]$Body)
    $f = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($f, $Body)
    return $f
  }

  function New-Payload {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param([string]$Tool = 'Bash', [string]$Command = 'git push', [string]$TranscriptPath = '')
    @{
      hook_event_name = 'PreToolUse'
      tool_name       = $Tool
      tool_input      = @{ command = $Command }
      transcript_path = $TranscriptPath
    } | ConvertTo-Json -Compress
  }
}

Describe 'attest-optimized-by.ps1 — push-time attestation' {

  It 'parses cleanly' {
    { [scriptblock]::Create((Get-Content -Raw $script:hookScript)) } | Should -Not -Throw
  }

  Context 'pass-through (filter does not fire)' {

    It 'exits 0 on non-Bash tool' {
      $r = Invoke-Hook -Json (New-Payload -Tool 'Edit' -Command 'irrelevant')
      $r.ExitCode | Should -Be 0
      $r.StdOut.Trim() | Should -Be ''
    }

    It 'exits 0 on Bash command that is not git push' {
      $r = Invoke-Hook -Json (New-Payload -Command 'git status')
      $r.ExitCode | Should -Be 0
      $r.StdOut.Trim() | Should -Be ''
    }

    It 'exits 0 on git push when the range carries no Optimized-By trailer' {
      $root = New-FakeRepo -CommitBodies @("feat: plain change`n`nNo trailer here.")
      try {
        $r = Invoke-Hook -Json (New-Payload -Command 'git push') -Root $root -Range 'base..HEAD'
        $r.ExitCode | Should -Be 0
        $r.StdOut.Trim() | Should -Be ''
      } finally { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $root }
    }

    It 'exits 0 when Optimized-By trailer is in range AND ai-engineer dispatch in transcript' {
      $root = New-FakeRepo -CommitBodies @("feat: X`n`nOptimized-By: ai-engineer")
      $tx = New-Transcript -Body '{"type":"tool_use","name":"Agent","input":{"subagent_type":"ai-engineer","prompt":"opt pass"}}'
      try {
        $r = Invoke-Hook -Json (New-Payload -Command 'git push') -Root $root -Transcript $tx -Range 'base..HEAD'
        $r.ExitCode | Should -Be 0
        $r.StdOut.Trim() | Should -Be ''
      } finally {
        Remove-Item -ErrorAction SilentlyContinue $tx
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $root
      }
    }
  }

  Context 'permissionDecision: ask (unverified trailer)' {

    It 'emits ask when range carries trailer + transcript missing dispatch' {
      $root = New-FakeRepo -CommitBodies @(
        "feat: WIP",
        "fix: edge case",
        "chore: ai-engineer pass`n`nOptimized-By: ai-engineer"
      )
      $tx = New-Transcript -Body '{"type":"text","content":"nothing about ai-engineer here"}'
      try {
        $r = Invoke-Hook -Json (New-Payload -Command 'git push') -Root $root -Transcript $tx -Range 'base..HEAD'
        $r.ExitCode | Should -Be 0
        $obj = $r.StdOut | ConvertFrom-Json
        $obj.hookSpecificOutput.hookEventName            | Should -Be 'PreToolUse'
        $obj.hookSpecificOutput.permissionDecision       | Should -Be 'ask'
        $obj.hookSpecificOutput.permissionDecisionReason | Should -Match 'Optimized-By: ai-engineer trailer'
        $obj.hookSpecificOutput.permissionDecisionReason | Should -Match 'no Agent\(subagent_type=ai-engineer\) dispatch'
      } finally {
        Remove-Item -ErrorAction SilentlyContinue $tx
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $root
      }
    }

    It 'emits ask when trailer is in any commit in the range, not just the tip' {
      $root = New-FakeRepo -CommitBodies @(
        "feat: ai-engineer pass`n`nOptimized-By: ai-engineer",
        "fix: follow-up`n`nNo trailer."
      )
      $tx = New-Transcript -Body 'no dispatch'
      try {
        $r = Invoke-Hook -Json (New-Payload -Command 'git push') -Root $root -Transcript $tx -Range 'base..HEAD'
        $r.ExitCode | Should -Be 0
        $r.StdOut | Should -Match '"permissionDecision":"ask"'
      } finally {
        Remove-Item -ErrorAction SilentlyContinue $tx
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $root
      }
    }

    It 'emits ask for git push variants (--force-with-lease, -u origin branch)' {
      $root = New-FakeRepo -CommitBodies @("feat: X`n`nOptimized-By: ai-engineer")
      $tx = New-Transcript -Body 'no dispatch'
      try {
        foreach ($push in @('git push origin HEAD', 'git push -u origin feat/x', 'git push --force-with-lease')) {
          $r = Invoke-Hook -Json (New-Payload -Command $push) -Root $root -Transcript $tx -Range 'base..HEAD'
          $r.ExitCode | Should -Be 0
          $r.StdOut | Should -Match '"permissionDecision":"ask"'
        }
      } finally {
        Remove-Item -ErrorAction SilentlyContinue $tx
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $root
      }
    }
  }

  Context 'opt-out paths' {
    It 'SKIP_GINEE_COMPLIANCE=1 short-circuits to exit 0' {
      $root = New-FakeRepo -CommitBodies @("feat: X`n`nOptimized-By: ai-engineer")
      $tx = New-Transcript -Body 'no dispatch'
      $prev = $env:SKIP_GINEE_COMPLIANCE
      try {
        $env:SKIP_GINEE_COMPLIANCE = '1'
        $r = Invoke-Hook -Json (New-Payload -Command 'git push') -Root $root -Transcript $tx -Range 'base..HEAD'
        $r.ExitCode | Should -Be 0
        $r.StdOut.Trim() | Should -Be ''
      } finally {
        if ($null -eq $prev) { Remove-Item Env:\SKIP_GINEE_COMPLIANCE -ErrorAction SilentlyContinue }
        else { $env:SKIP_GINEE_COMPLIANCE = $prev }
        Remove-Item -ErrorAction SilentlyContinue $tx
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $root
      }
    }

    It 'framework.config.yaml § compliance.disabled: [optimized-by-attestation] short-circuits to exit 0' {
      $root = New-FakeRepo -CommitBodies @("feat: X`n`nOptimized-By: ai-engineer")
      $tx = New-Transcript -Body 'no dispatch'
      try {
        $local = Join-Path $root 'local'
        New-Item -ItemType Directory -Force -Path $local | Out-Null
        Set-Content -LiteralPath (Join-Path $local 'framework.config.yaml') -Value @"
compliance:
  disabled:
    - optimized-by-attestation
"@ -NoNewline
        $r = Invoke-Hook -Json (New-Payload -Command 'git push') -Root $root -Transcript $tx -Range 'base..HEAD'
        $r.ExitCode | Should -Be 0
        $r.StdOut.Trim() | Should -Be ''
      } finally {
        Remove-Item -ErrorAction SilentlyContinue $tx
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $root
      }
    }
  }

  Context 'fail-open on missing data' {
    It 'exits 0 on empty payload' {
      $r = Invoke-Hook -Json ''
      $r.ExitCode | Should -Be 0
      $r.StdOut.Trim() | Should -Be ''
    }

    It 'exits 0 on malformed JSON payload' {
      $r = Invoke-Hook -Json 'not-json{'
      $r.ExitCode | Should -Be 0
      $r.StdOut.Trim() | Should -Be ''
    }

    It 'exits 0 on empty range (no commits ahead of base)' {
      $root = New-FakeRepo -CommitBodies @()
      try {
        $r = Invoke-Hook -Json (New-Payload -Command 'git push') -Root $root -Range 'base..HEAD'
        $r.ExitCode | Should -Be 0
        $r.StdOut.Trim() | Should -Be ''
      } finally { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $root }
    }
  }
}
