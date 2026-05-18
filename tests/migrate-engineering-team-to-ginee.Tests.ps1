BeforeAll {
  $script:migrateScript = (Resolve-Path "$PSScriptRoot/../core/scripts/migrate-engineering-team-to-ginee.ps1").Path
}

Describe 'migrate-engineering-team-to-ginee.ps1' {
  It 'parses cleanly' {
    { [scriptblock]::Create((Get-Content -Raw $script:migrateScript)) } | Should -Not -Throw
  }

  Context 'against a synthetic local/' {
    BeforeEach {
      $script:tmp = (New-Item -ItemType Directory -Force `
        -Path (Join-Path ([System.IO.Path]::GetTempPath()) "ginee-migrate-test-$([guid]::NewGuid().Guid)")).FullName
      $null = New-Item -ItemType Directory -Force -Path "$script:tmp/.agents/ginee/core/scripts"
      $null = New-Item -ItemType Directory -Force -Path "$script:tmp/.agents/ginee/local/index"
      Copy-Item $script:migrateScript "$script:tmp/.agents/ginee/core/scripts/"
      $script:scriptCopy = "$script:tmp/.agents/ginee/core/scripts/migrate-engineering-team-to-ginee.ps1"

      $cfg = @"
github:
  framework-repo: kostiantyn-matsebora/engineering-team
  ready-label: engineering-team:ready
  in-progress-label: engineering-team:in-progress
"@
      Set-Content -LiteralPath "$script:tmp/.agents/ginee/local/framework.config.yaml" -Value $cfg -NoNewline
    }

    AfterEach {
      Remove-Item -Recurse -Force $script:tmp -ErrorAction SilentlyContinue
    }

    It 'dry-run leaves files untouched' {
      $cfgPath = "$script:tmp/.agents/ginee/local/framework.config.yaml"
      $before = Get-Content $cfgPath -Raw
      & $script:scriptCopy -DryRun *>&1 | Out-Null
      $after = Get-Content $cfgPath -Raw
      $after | Should -BeExactly $before
    }

    It 'real run rewrites every engineering-team occurrence to ginee' {
      $cfgPath = "$script:tmp/.agents/ginee/local/framework.config.yaml"
      & $script:scriptCopy *>&1 | Out-Null
      $content = Get-Content $cfgPath -Raw
      $content | Should -Not -Match 'engineering-team'
      $content | Should -Match 'kostiantyn-matsebora/ginee'
      $content | Should -Match 'ginee:ready'
      $content | Should -Match 'ginee:in-progress'
    }

    It 'idempotent: re-run on already-rewritten tree is a no-op' {
      $cfgPath = "$script:tmp/.agents/ginee/local/framework.config.yaml"
      & $script:scriptCopy *>&1 | Out-Null
      $first = Get-Content $cfgPath -Raw
      & $script:scriptCopy *>&1 | Out-Null
      $second = Get-Content $cfgPath -Raw
      $second | Should -BeExactly $first
    }

    It 'reports zero hits when local/ is already clean' {
      $cfgPath = "$script:tmp/.agents/ginee/local/framework.config.yaml"
      & $script:scriptCopy *>&1 | Out-Null  # first pass rewrites
      $output = & $script:scriptCopy *>&1   # second pass should be clean
      ($output -join "`n") | Should -Match 'local/ is clean'
    }
  }
}
