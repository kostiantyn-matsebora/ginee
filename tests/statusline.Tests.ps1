BeforeAll {
  $script:statuslineScript = (Resolve-Path "$PSScriptRoot/../adapters/claude/statusline.ps1").Path
  $script:repoRoot         = (Resolve-Path "$PSScriptRoot/..").Path

  function Invoke-Statusline {
    param([string]$Json = '{"session_id":"test"}', [string]$Root = $null)
    if (-not $Root) { $Root = $script:repoRoot }
    $inFile  = New-TemporaryFile
    $outFile = New-TemporaryFile
    try {
      [System.IO.File]::WriteAllText($inFile.FullName, $Json)
      $p = Start-Process -FilePath 'pwsh' `
        -ArgumentList @('-NoProfile','-File',$script:statuslineScript,'-RepoRoot',$Root) `
        -NoNewWindow -PassThru -Wait `
        -RedirectStandardInput $inFile.FullName `
        -RedirectStandardOutput $outFile.FullName
      $out = Get-Content -Raw -LiteralPath $outFile.FullName -ErrorAction SilentlyContinue
      return [pscustomobject]@{ ExitCode = $p.ExitCode; StdOut = ($out ?? '') }
    } finally {
      Remove-Item -ErrorAction SilentlyContinue -LiteralPath $inFile.FullName
      Remove-Item -ErrorAction SilentlyContinue -LiteralPath $outFile.FullName
    }
  }
}

Describe 'statusline.ps1' {

  It 'parses cleanly' {
    { [scriptblock]::Create((Get-Content -Raw $script:statuslineScript)) } | Should -Not -Throw
  }

  It 'always exits 0 (must not crash the host)' {
    $r = Invoke-Statusline
    $r.ExitCode | Should -Be 0
  }

  It 'output starts with [ginee] prefix' {
    $r = Invoke-Statusline
    $r.StdOut | Should -Match '^\[ginee\]'
  }

  It 'output fits within 100 chars' {
    $r = Invoke-Statusline
    $r.StdOut.Length | Should -BeLessOrEqual 100
  }

  It 'emits a `trailer:` field (ok or needed)' {
    $r = Invoke-Statusline
    $r.StdOut | Should -Match 'trailer:\s+(ok|needed)'
  }

  It 'emits a `phase:` placeholder until D43 plumbing lands' {
    $r = Invoke-Statusline
    $r.StdOut | Should -Match 'phase:\s+\?'
  }

  Context 'opt-out via local/framework.config.yaml' {
    BeforeEach {
      $script:fakeRoot = (New-Item -ItemType Directory -Force `
        -Path (Join-Path ([System.IO.Path]::GetTempPath()) "ginee-statusline-test-$([guid]::NewGuid().Guid)")).FullName
      New-Item -ItemType Directory -Force -Path "$script:fakeRoot/local" | Out-Null
      Push-Location $script:fakeRoot
      & git init --quiet 2>&1 | Out-Null
    }

    AfterEach {
      Pop-Location
      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $script:fakeRoot
    }

    It 'emits no output when the tactic is opt-out' {
      $cfg = "compliance:`n  disabled:`n    - compliance-statusline`n"
      [System.IO.File]::WriteAllText("$script:fakeRoot/local/framework.config.yaml", $cfg)
      $r = Invoke-Statusline -Root $script:fakeRoot
      $r.ExitCode | Should -Be 0
      $r.StdOut   | Should -BeNullOrEmpty
    }
  }

  Context 'no repo' {
    It 'gracefully prints `[ginee] (no repo)` outside a git tree' {
      $tmp = (New-Item -ItemType Directory -Force `
        -Path (Join-Path ([System.IO.Path]::GetTempPath()) "ginee-statusline-norepo-$([guid]::NewGuid().Guid)")).FullName
      try {
        $r = Invoke-Statusline -Root $tmp
        $r.ExitCode | Should -Be 0
        $r.StdOut   | Should -Match '\[ginee\].*no repo'
      } finally {
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $tmp
      }
    }
  }
}
