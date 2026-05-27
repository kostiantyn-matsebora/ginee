#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.5.0' }

BeforeAll {
  $script:hookScript = (Resolve-Path "$PSScriptRoot/../adapters/claude/hooks/pre-tool-use-sa-artefact.ps1").Path
  $script:repoRoot   = (Resolve-Path "$PSScriptRoot/..").Path

  # A tempdir we can populate with a fake config + SA-owned target file per test.
  $script:tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) "sa-artefact-tests-$([guid]::NewGuid().ToString('N'))"
  New-Item -ItemType Directory -Force -Path $script:tmpRoot | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $script:tmpRoot 'local') | Out-Null
  New-Item -ItemType Directory -Force -Path (Join-Path $script:tmpRoot 'docs/adr') | Out-Null
  # Initialise as a git repo so `git rev-parse --show-toplevel` works inside the hook fallback.
  Push-Location $script:tmpRoot
  try { & git init --quiet 2>$null | Out-Null } finally { Pop-Location }

  # Default config — adopts our docs/adr/ as the ADR directory.
  $cfgBody = "adr-directory: docs/adr/`narchitecture-doc: docs/architecture.md`n"
  Set-Content -LiteralPath (Join-Path $script:tmpRoot 'local/framework.config.yaml') -Value $cfgBody

  function Invoke-Hook {
    param([string]$Json, [string]$Root = $null)
    if (-not $Root)  { $Root  = $script:tmpRoot }
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

  function Get-WritePayload {
    param([string]$Path, [string]$Content)
    @{
      hook_event_name = 'PreToolUse'
      tool_name       = 'Write'
      tool_input      = @{ file_path = $Path; content = $Content }
    } | ConvertTo-Json -Compress -Depth 4
  }
}

AfterAll {
  if ($script:tmpRoot -and (Test-Path -LiteralPath $script:tmpRoot)) {
    Remove-Item -Recurse -Force -LiteralPath $script:tmpRoot -ErrorAction SilentlyContinue
  }
}

Describe 'pre-tool-use-sa-artefact.ps1 — #182 SA content axis' {

  It 'parses cleanly' {
    { [scriptblock]::Create((Get-Content -Raw $script:hookScript)) } | Should -Not -Throw
  }

  Context 'pass-through — non-SA paths' {
    It 'exits 0 on Bash payload (wrong tool)' {
      $r = Invoke-Hook -Json '{"tool_name":"Bash","tool_input":{"command":"ls"}}'
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 on edit to src/handler.ts (non-SA path)' {
      $payload = Get-WritePayload 'src/handler.ts' 'see other.ts:42 for context'
      $r = Invoke-Hook -Json $payload
      $r.ExitCode | Should -Be 0
    }

    It 'exits 0 on edit to README.md outside SA-owned paths' {
      $payload = Get-WritePayload 'README.md' 'See handler.ts:142 here.'
      $r = Invoke-Hook -Json $payload
      $r.ExitCode | Should -Be 0
    }
  }

  Context 'SA-owned canonical paths — clean content allowed' {
    It 'allows clean content on local/requirements.md' {
      $payload = Get-WritePayload 'local/requirements.md' "# Requirements`n## FR-001`nThe system shall paginate.`n"
      $r = Invoke-Hook -Json $payload
      $r.ExitCode | Should -Be 0
    }

    It 'allows clean content on local/asr-utility-tree.md' {
      $payload = Get-WritePayload 'local/asr-utility-tree.md' "# ASRs`nLatency NFR derived from FR-002.`n"
      $r = Invoke-Hook -Json $payload
      $r.ExitCode | Should -Be 0
    }

    It 'allows content with an interface-declaration code block' {
      # Use a single-quoted here-string to avoid PowerShell backtick-escape
      # interpretation that would otherwise inject BEL chars into the fixture.
      $clean = @'
# ADR

## Decision
Use cursor pagination.

```typescript
interface Page<T> { items: T[]; next?: string }
```
'@
      $payload = Get-WritePayload 'docs/adr/ADR-0001-pagination.md' $clean
      $r = Invoke-Hook -Json $payload
      $r.ExitCode | Should -Be 0
    }
  }

  Context 'hard gate — file-line citation blocked on SA paths' {
    It 'blocks file-line citation in local/requirements.md' {
      $payload = Get-WritePayload 'local/requirements.md' "## FR-001`nSee src/handler.ts:142.`n"
      $r = Invoke-Hook -Json $payload
      $r.ExitCode | Should -Be 2
      $r.StdErr | Should -Match 'file.*line'
      $r.StdErr | Should -Match '#182'
    }

    It 'blocks file-line citation in local/asr-utility-tree.md' {
      $payload = Get-WritePayload 'local/asr-utility-tree.md' "## ASR-001`nDerived from app/pagination.cs:47.`n"
      $r = Invoke-Hook -Json $payload
      $r.ExitCode | Should -Be 2
    }

    It 'blocks file-line citation in docs/adr/ADR-0001.md (config-derived path)' {
      $payload = Get-WritePayload 'docs/adr/ADR-0001-paging.md' "## Decision`nReplace approach.ts:88 with cursor pagination.`n"
      $r = Invoke-Hook -Json $payload
      $r.ExitCode | Should -Be 2
    }
  }

  Context 'hard gate — commit SHA in evidence context blocked' {
    It 'blocks as-of <sha> in SA path' {
      $payload = Get-WritePayload 'local/requirements.md' "## FR-001`nAs of 1aaa215abc, pagination wraps.`n"
      $r = Invoke-Hook -Json $payload
      $r.ExitCode | Should -Be 2
      $r.StdErr | Should -Match 'SHA'
    }

    It 'blocks prior-to <sha> in SA path' {
      $payload = Get-WritePayload 'local/asr-utility-tree.md' "## ASR-001`nPrior to deadbeef revision, latency was 5s.`n"
      $r = Invoke-Hook -Json $payload
      $r.ExitCode | Should -Be 2
    }

    It 'blocks commit <sha> in SA path' {
      $payload = Get-WritePayload 'docs/adr/ADR-0002-latency.md' "## Context`nIntroduced in commit 1234567.`n"
      $r = Invoke-Hook -Json $payload
      $r.ExitCode | Should -Be 2
    }
  }

  Context 'opt-out' {
    It 'honours SKIP_GINEE_COMPLIANCE=1' {
      $orig = $env:SKIP_GINEE_COMPLIANCE
      try {
        $env:SKIP_GINEE_COMPLIANCE = '1'
        $payload = Get-WritePayload 'local/requirements.md' "See src/x.ts:42."
        $r = Invoke-Hook -Json $payload
        $r.ExitCode | Should -Be 0
      } finally {
        $env:SKIP_GINEE_COMPLIANCE = $orig
      }
    }
  }
}
