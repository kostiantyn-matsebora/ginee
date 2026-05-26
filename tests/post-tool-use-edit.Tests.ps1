BeforeAll {
  $script:hookScript = (Resolve-Path "$PSScriptRoot/../adapters/claude/hooks/post-tool-use-edit.ps1").Path
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

  function Get-Payload {
    param([string]$Tool='Edit', [string]$Path)
    @{
      hook_event_name = 'PostToolUse'
      tool_name       = $Tool
      tool_input      = @{ file_path = $Path }
      tool_response   = @{ success = $true }
    } | ConvertTo-Json -Compress -Depth 4
  }
}

Describe 'post-tool-use-edit.ps1' {

  It 'parses cleanly' {
    { [scriptblock]::Create((Get-Content -Raw $script:hookScript)) } | Should -Not -Throw
  }

  Context 'pass-through (no injection)' {
    It 'exits 0 with empty stdout on a non-Edit tool' {
      $r = Invoke-Hook -Json '{"tool_name":"Bash","tool_input":{"command":"ls"}}'
      $r.ExitCode | Should -Be 0
      $r.StdOut.Trim() | Should -Be ''
    }

    It 'exits 0 on empty payload' {
      $r = Invoke-Hook -Json ''
      $r.ExitCode | Should -Be 0
      $r.StdOut.Trim() | Should -Be ''
    }

    It 'exits 0 on malformed JSON' {
      $r = Invoke-Hook -Json 'not-json{'
      $r.ExitCode | Should -Be 0
      $r.StdOut.Trim() | Should -Be ''
    }

    It 'exits 0 with empty stdout on edits outside core/ (tests/)' {
      $r = Invoke-Hook -Json (Get-Payload -Path 'tests/foo.Tests.ps1')
      $r.ExitCode | Should -Be 0
      $r.StdOut.Trim() | Should -Be ''
    }

    It 'exits 0 with empty stdout on edits outside core/ (adapters/)' {
      $r = Invoke-Hook -Json (Get-Payload -Path 'adapters/claude/install.md')
      $r.ExitCode | Should -Be 0
      $r.StdOut.Trim() | Should -Be ''
    }

    It 'exits 0 with empty stdout on edits outside core/ (local/)' {
      $r = Invoke-Hook -Json (Get-Payload -Path 'local/bindings.md')
      $r.ExitCode | Should -Be 0
      $r.StdOut.Trim() | Should -Be ''
    }
  }

  Context 'self-check injection on core/**' {
    It 'injects on an Edit to core/process.md' {
      $r = Invoke-Hook -Json (Get-Payload -Path 'core/process.md')
      $r.ExitCode | Should -Be 0
      $r.StdOut | Should -Match '\[ginee:self-check\]'
      $r.StdOut | Should -Match 'core/process\.md'
    }

    It 'emits valid hookSpecificOutput envelope' {
      $r = Invoke-Hook -Json (Get-Payload -Path 'core/protocols/foo.md')
      $r.ExitCode | Should -Be 0
      $obj = $r.StdOut | ConvertFrom-Json
      $obj.hookSpecificOutput.hookEventName | Should -Be 'PostToolUse'
      $obj.hookSpecificOutput.additionalContext | Should -Match 'self-check'
    }

    It 'reminder body is <= 6 lines for a non-always-loaded path' {
      $r = Invoke-Hook -Json (Get-Payload -Path 'core/protocols/foo.md')
      $obj = $r.StdOut | ConvertFrom-Json
      $lines = $obj.hookSpecificOutput.additionalContext -split "`n"
      $lines.Count | Should -BeLessOrEqual 6
    }

    It 'adds always-loaded reminder for core/process.md' {
      $r = Invoke-Hook -Json (Get-Payload -Path 'core/process.md')
      $obj = $r.StdOut | ConvertFrom-Json
      $obj.hookSpecificOutput.additionalContext | Should -Match 'always-loaded surface'
    }

    It 'adds always-loaded reminder for a role kernel (core/roles/team-lead.md)' {
      $r = Invoke-Hook -Json (Get-Payload -Path 'core/roles/team-lead.md')
      $obj = $r.StdOut | ConvertFrom-Json
      $obj.hookSpecificOutput.additionalContext | Should -Match 'always-loaded surface'
    }

    It 'does NOT add always-loaded reminder for a *.details.md sibling' {
      $r = Invoke-Hook -Json (Get-Payload -Path 'core/roles/team-lead.details.md')
      $obj = $r.StdOut | ConvertFrom-Json
      $obj.hookSpecificOutput.additionalContext | Should -Not -Match 'always-loaded surface'
    }
  }

  Context 'opt-out' {
    It 'exits 0 with empty stdout when SKIP_GINEE_COMPLIANCE=1' {
      $prev = $env:SKIP_GINEE_COMPLIANCE
      try {
        $env:SKIP_GINEE_COMPLIANCE = '1'
        $r = Invoke-Hook -Json (Get-Payload -Path 'core/process.md')
        $r.ExitCode | Should -Be 0
        $r.StdOut.Trim() | Should -Be ''
      } finally {
        if ($null -eq $prev) { Remove-Item Env:\SKIP_GINEE_COMPLIANCE -ErrorAction SilentlyContinue }
        else { $env:SKIP_GINEE_COMPLIANCE = $prev }
      }
    }
  }
}
