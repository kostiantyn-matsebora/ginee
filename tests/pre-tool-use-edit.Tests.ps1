BeforeAll {
  $script:hookScript = (Resolve-Path "$PSScriptRoot/../adapters/claude/hooks/pre-tool-use-edit.ps1").Path
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

  function Get-EditPayload {
    param([string]$FilePath, [string]$OldString, [string]$NewString)
    @{
      tool_name  = 'Edit'
      tool_input = @{
        file_path  = $FilePath
        old_string = $OldString
        new_string = $NewString
      }
    } | ConvertTo-Json -Depth 4 -Compress
  }

  function Get-WritePayload {
    param([string]$FilePath, [string]$Content)
    @{
      tool_name  = 'Write'
      tool_input = @{ file_path = $FilePath; content = $Content }
    } | ConvertTo-Json -Depth 4 -Compress
  }
}

Describe 'pre-tool-use-edit.ps1' {

  It 'parses cleanly' {
    { [scriptblock]::Create((Get-Content -Raw $script:hookScript)) } | Should -Not -Throw
  }

  Context 'pass-through (no violation)' {
    It 'exits 0 on a tool name outside Edit/Write/MultiEdit' {
      $json = '{"tool_name":"Read","tool_input":{"file_path":"x.md"}}'
      $r = Invoke-Hook -Json $json
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 on an empty payload' {
      $r = Invoke-Hook -Json ''
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 when malformed JSON is provided (fail-open)' {
      $r = Invoke-Hook -Json 'not-json{'
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 on a benign edit outside core/' {
      $body = "Hello world.`n"
      $json = Get-WritePayload -FilePath 'README.txt' -Content $body
      $r = Invoke-Hook -Json $json
      $r.ExitCode | Should -Be 0
    }
  }

  Context 'Violation 1 — hot-spec frontmatter required (D47)' {
    It 'blocks a Write to core/process.md without frontmatter' {
      $json = Get-WritePayload -FilePath 'core/process.md' -Content "body without frontmatter`n"
      $r = Invoke-Hook -Json $json
      $r.ExitCode | Should -Be 2
      $r.StdErr  | Should -Match 'hot-spec frontmatter required'
    }

    It 'allows a Write to core/process.md with frontmatter' {
      $body = @"
---
audience: all-cardinals
load: always
triggers: []
cap-bytes: 12000
reads-before-applying: []
---

Body here.
"@
      $json = Get-WritePayload -FilePath 'core/process.md' -Content $body
      $r = Invoke-Hook -Json $json
      $r.ExitCode | Should -Be 0
    }
  }

  Context 'Violation 3 — D<N> token introduction blocked (D42)' {
    It 'blocks a Write under core/protocols/ that adds a D-token' {
      $body = @"
---
audience: all-cardinals
load: on-demand
triggers: [foo]
cap-bytes: 2000
reads-before-applying: []
---

This change cites D42 — should be blocked.
"@
      $json = Get-WritePayload -FilePath 'core/protocols/new-spec.md' -Content $body
      $r = Invoke-Hook -Json $json
      $r.ExitCode | Should -Be 2
      $r.StdErr  | Should -Match 'D<N> token introduction blocked'
    }
  }

  Context 'Violation 4 — RFC 2119 keyword convention (D48)' {
    It 'blocks a Write that adds "always" as a rule modifier' {
      $body = "Lines must always include a trailing period.`n"
      $json = Get-WritePayload -FilePath 'core/protocols/style.md' -Content @"
---
audience: all-cardinals
load: on-demand
triggers: [style]
cap-bytes: 2000
reads-before-applying: []
---

$body
"@
      $r = Invoke-Hook -Json $json
      $r.ExitCode | Should -Be 2
      $r.StdErr  | Should -Match 'RFC 2119 keyword convention'
    }
  }

  Context 'opt-out via local/framework.config.yaml' {
    BeforeEach {
      $script:fakeRoot = (New-Item -ItemType Directory -Force `
        -Path (Join-Path ([System.IO.Path]::GetTempPath()) "ginee-pretool-test-$([guid]::NewGuid().Guid)")).FullName
      New-Item -ItemType Directory -Force -Path "$script:fakeRoot/local" | Out-Null
      New-Item -ItemType Directory -Force -Path "$script:fakeRoot/core/protocols" | Out-Null
      Push-Location $script:fakeRoot
      & git init --quiet 2>&1 | Out-Null
    }

    AfterEach {
      Pop-Location
      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $script:fakeRoot
    }

    It 'exits 0 when the tactic is listed under compliance.disabled' {
      $cfg = @"
compliance:
  disabled:
    - pretooluse-edit-hook
"@
      Set-Content -LiteralPath "$script:fakeRoot/local/framework.config.yaml" -Value $cfg -NoNewline
      $json = Get-WritePayload -FilePath 'core/process.md' -Content 'body without frontmatter'
      $r = Invoke-Hook -Json $json -Root $script:fakeRoot
      $r.ExitCode | Should -Be 0
    }

    It 'still blocks when compliance.disabled does not include this tactic' {
      $cfg = @"
compliance:
  disabled:
    - some-other-tactic
"@
      Set-Content -LiteralPath "$script:fakeRoot/local/framework.config.yaml" -Value $cfg -NoNewline
      $json = Get-WritePayload -FilePath 'core/process.md' -Content 'body without frontmatter'
      $r = Invoke-Hook -Json $json -Root $script:fakeRoot
      $r.ExitCode | Should -Be 2
    }
  }

  Context 'SKIP_GINEE_COMPLIANCE bypass' {
    It 'exits 0 when SKIP_GINEE_COMPLIANCE=1' {
      $json = Get-WritePayload -FilePath 'core/process.md' -Content 'no frontmatter'
      $env:SKIP_GINEE_COMPLIANCE = '1'
      try {
        $exitCode = $null
        & pwsh -NoProfile -File $script:hookScript -TestInput $json -RepoRoot $script:repoRoot *>$null
        $exitCode = $LASTEXITCODE
        $exitCode | Should -Be 0
      } finally {
        Remove-Item Env:\SKIP_GINEE_COMPLIANCE -ErrorAction SilentlyContinue
      }
    }
  }
}
