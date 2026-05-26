BeforeAll {
  $script:hookScript = (Resolve-Path "$PSScriptRoot/../adapters/claude/hooks/stop.ps1").Path
  $script:repoRoot   = (Resolve-Path "$PSScriptRoot/..").Path

  function Invoke-Hook {
    param([string]$Json, [string]$Root = $null)
    if (-not $Root) { $Root = $script:repoRoot }
    $inFile  = New-TemporaryFile
    $outFile = New-TemporaryFile
    $errFile = New-TemporaryFile
    try {
      [System.IO.File]::WriteAllText($inFile.FullName, $Json)
      $p = Start-Process -FilePath 'pwsh' `
        -ArgumentList @('-NoProfile','-File',$script:hookScript,'-RepoRoot',$Root) `
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

  # Build a Stop payload — Claude Code passes transcript via path; tests
  # may use `transcript` inline (the ps1 supports both).
  function Get-Payload {
    param(
      [string]$Transcript = '',
      [bool]$Active = $false
    )
    $obj = @{ hook_event_name = 'Stop' }
    if ($Transcript) { $obj['transcript'] = $Transcript }
    if ($Active)     { $obj['stop_hook_active'] = $true }
    $obj | ConvertTo-Json -Compress
  }
}

Describe 'stop.ps1' {

  It 'parses cleanly' {
    { [scriptblock]::Create((Get-Content -Raw $script:hookScript)) } | Should -Not -Throw
  }

  Context 'pass-through' {
    It 'exits 0 on empty payload' {
      $r = Invoke-Hook -Json ''
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 on malformed JSON' {
      $r = Invoke-Hook -Json 'not-json{'
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 on a transcript with no specialist return' {
      $r = Invoke-Hook -Json (Get-Payload -Transcript 'just a casual exchange about the weather')
      $r.ExitCode | Should -Be 0
    }
  }

  Context 'anti-loop guard' {
    It 'exits 0 immediately when stop_hook_active=true (never blocks a re-entry)' {
      $body = @"
## Files touched
core/process.md

## Decisions made
none
"@  # NO self-lint marker — would normally block
      $r = Invoke-Hook -Json (Get-Payload -Transcript $body -Active $true)
      $r.ExitCode | Should -Be 0
    }
  }

  Context 'Block 1 — self-lint marker missing' {
    It 'blocks when a return-shaped tail is missing the marker' {
      $body = @"
Some narrative…

## Files touched
core/process.md (+12 lines)

## Decisions made
extended the lifecycle reading-order table.

## Verification log
ran Pester locally.

## Open issues
(none)

## Next dispatch needed
(none)

## Source reads (this dispatch)
core/process.md

(no self-lint marker — must block)
"@
      $r = Invoke-Hook -Json (Get-Payload -Transcript $body)
      $r.ExitCode | Should -Be 2
      $r.StdErr | Should -Match 'self-lint marker'
    }

    It 'passes when the marker is present' {
      $body = @"
## Files touched
core/process.md

## Decisions made
none

<!-- self-lint: pass -->
"@
      $r = Invoke-Hook -Json (Get-Payload -Transcript $body)
      $r.ExitCode | Should -Be 0
    }
  }

  Context 'Block 3 — gh pr create without acceptance' {
    It 'blocks when transcript has gh pr create + no acceptance signal' {
      $body = @"
gh pr create --title "feat: x" --body "..."
PR opened successfully.
"@
      $r = Invoke-Hook -Json (Get-Payload -Transcript $body)
      $r.ExitCode | Should -Be 2
      $r.StdErr | Should -Match 'PR opened without CI-watch sign-off'
    }

    It 'passes when an acceptance signal follows' {
      $body = @"
gh pr create --title "feat: x" --body "..."
PR opened successfully.
…later: User: looks good, merged.
"@
      $r = Invoke-Hook -Json (Get-Payload -Transcript $body)
      $r.ExitCode | Should -Be 0
    }
  }

  Context 'opt-out via SKIP_GINEE_COMPLIANCE' {
    It 'exits 0 with SKIP_GINEE_COMPLIANCE=1 even on otherwise-blocking transcript' {
      $body = @"
## Files touched
core/process.md
(no marker)
"@
      $prev = $env:SKIP_GINEE_COMPLIANCE
      try {
        $env:SKIP_GINEE_COMPLIANCE = '1'
        $r = Invoke-Hook -Json (Get-Payload -Transcript $body)
        $r.ExitCode | Should -Be 0
      } finally {
        if ($null -eq $prev) { Remove-Item Env:\SKIP_GINEE_COMPLIANCE -ErrorAction SilentlyContinue }
        else { $env:SKIP_GINEE_COMPLIANCE = $prev }
      }
    }
  }

  Context 'opt-out via framework.config.yaml' {
    It 'exits 0 when stop-hook listed under compliance.disabled' {
      $tmp = New-Item -ItemType Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) "ginee-stop-$([guid]::NewGuid().Guid)")
      try {
        $local = Join-Path $tmp.FullName 'local'
        New-Item -ItemType Directory -Path $local | Out-Null
        Set-Content -LiteralPath (Join-Path $local 'framework.config.yaml') -Value @"
compliance:
  disabled:
    - stop-hook
"@ -NoNewline
        Push-Location $tmp.FullName
        & git init --quiet 2>&1 | Out-Null
        & git config user.email "t@t" 2>&1 | Out-Null
        & git config user.name "t" 2>&1 | Out-Null
        & git commit --allow-empty --quiet -m "x" 2>&1 | Out-Null
        Pop-Location

        $body = @"
## Files touched
x.md (no marker)
"@
        $r = Invoke-Hook -Json (Get-Payload -Transcript $body) -Root $tmp.FullName
        $r.ExitCode | Should -Be 0
      } finally {
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $tmp.FullName
      }
    }
  }
}
