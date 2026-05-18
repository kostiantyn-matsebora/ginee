BeforeAll {
  $script:installScript = (Resolve-Path "$PSScriptRoot/../install.ps1").Path
}

Describe 'install.ps1' {
  It 'parses cleanly' {
    { [scriptblock]::Create((Get-Content -Raw $script:installScript)) } | Should -Not -Throw
  }

  It 'rejects an invalid -Adapter and exits non-zero' {
    $tmpTarget = Join-Path ([System.IO.Path]::GetTempPath()) "ginee-it-test-$([guid]::NewGuid().Guid)"
    New-Item -ItemType Directory -Force -Path $tmpTarget | Out-Null
    try {
      $output = & pwsh -NoProfile -File $script:installScript `
        -Target $tmpTarget `
        -Adapter 'bogus-not-a-real-adapter' 2>&1
      $exit = $LASTEXITCODE
      $exit | Should -Not -Be 0
      ($output -join "`n") | Should -Match 'Invalid -Adapter'
    } finally {
      Remove-Item -Recurse -Force $tmpTarget -ErrorAction SilentlyContinue
    }
  }
}
