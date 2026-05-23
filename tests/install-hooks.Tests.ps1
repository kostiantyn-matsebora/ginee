BeforeAll {
  $script:installHooksScript = (Resolve-Path "$PSScriptRoot/../scripts/install-hooks.ps1").Path
  $script:repoRoot = (Resolve-Path "$PSScriptRoot/..").Path
}

Describe 'install-hooks.ps1' {
  It 'parses cleanly' {
    { [scriptblock]::Create((Get-Content -Raw $script:installHooksScript)) } | Should -Not -Throw
  }

  Context 'against a synthetic git repo' {
    BeforeEach {
      $script:tmp = (New-Item -ItemType Directory -Force `
        -Path (Join-Path ([System.IO.Path]::GetTempPath()) "ginee-install-hooks-test-$([guid]::NewGuid().Guid)")).FullName
      Push-Location $script:tmp
      & git init --quiet 2>&1 | Out-Null
      # Stage the source hook files we expect the installer to copy
      $null = New-Item -ItemType Directory -Force -Path "$script:tmp/hooks"
      Set-Content -LiteralPath "$script:tmp/hooks/pre-commit" -Value "#!/usr/bin/env bash`necho 'pre-commit hook'`n" -NoNewline
      Set-Content -LiteralPath "$script:tmp/hooks/pre-push"   -Value "#!/usr/bin/env bash`necho 'pre-push hook'`n"   -NoNewline
      # Provide the .example claude settings the installer also copies
      $null = New-Item -ItemType Directory -Force -Path "$script:tmp/.claude"
      Set-Content -LiteralPath "$script:tmp/.claude/settings.json.example" -Value '{ "hooks": {} }' -NoNewline
    }

    AfterEach {
      Pop-Location
      Remove-Item -Recurse -Force $script:tmp -ErrorAction SilentlyContinue
    }

    It 'fails when run outside a git tree' {
      $outside = (New-Item -ItemType Directory -Force `
        -Path (Join-Path ([System.IO.Path]::GetTempPath()) "ginee-no-git-$([guid]::NewGuid().Guid)")).FullName
      try {
        Push-Location $outside
        # Script uses Write-Error with $ErrorActionPreference = 'Stop' → throws
        { & $script:installHooksScript *>$null } | Should -Throw
      }
      finally {
        Pop-Location
        Remove-Item -Recurse -Force $outside -ErrorAction SilentlyContinue
      }
    }

    It 'installs both pre-commit and pre-push into .git/hooks/' {
      & $script:installHooksScript *>&1 | Out-Null
      Test-Path "$script:tmp/.git/hooks/pre-commit" | Should -BeTrue
      Test-Path "$script:tmp/.git/hooks/pre-push"   | Should -BeTrue
      (Get-Content -Raw "$script:tmp/.git/hooks/pre-commit") | Should -Match 'pre-commit hook'
      (Get-Content -Raw "$script:tmp/.git/hooks/pre-push")   | Should -Match 'pre-push hook'
    }

    It 'installs .claude/settings.json from .example when absent' {
      Remove-Item -ErrorAction SilentlyContinue "$script:tmp/.claude/settings.json"
      & $script:installHooksScript *>&1 | Out-Null
      Test-Path "$script:tmp/.claude/settings.json" | Should -BeTrue
      (Get-Content -Raw "$script:tmp/.claude/settings.json").Trim() | Should -BeExactly '{ "hooks": {} }'
    }

    It 'idempotent — re-run with identical hooks reports "already up to date"' {
      & $script:installHooksScript *>&1 | Out-Null
      $output = & $script:installHooksScript *>&1
      ($output -join "`n") | Should -Match 'already up to date'
    }

    It 'leaves an existing differing hook untouched without -Force' {
      $null = New-Item -ItemType Directory -Force -Path "$script:tmp/.git/hooks"
      Set-Content -LiteralPath "$script:tmp/.git/hooks/pre-commit" -Value '#!/usr/bin/env bash`n# user customisation`n' -NoNewline
      $before = Get-Content -Raw "$script:tmp/.git/hooks/pre-commit"
      $output = & $script:installHooksScript *>&1
      $after = Get-Content -Raw "$script:tmp/.git/hooks/pre-commit"
      $after | Should -BeExactly $before
      ($output -join "`n") | Should -Match 'exists and differs'
    }

    It '-Force overwrites an existing differing hook' {
      $null = New-Item -ItemType Directory -Force -Path "$script:tmp/.git/hooks"
      Set-Content -LiteralPath "$script:tmp/.git/hooks/pre-commit" -Value '# user version' -NoNewline
      & $script:installHooksScript -Force *>&1 | Out-Null
      (Get-Content -Raw "$script:tmp/.git/hooks/pre-commit") | Should -Match 'pre-commit hook'
    }

    It 'leaves an existing .claude/settings.json untouched without -Force' {
      Set-Content -LiteralPath "$script:tmp/.claude/settings.json" -Value '{ "user": "value" }' -NoNewline
      & $script:installHooksScript *>&1 | Out-Null
      (Get-Content -Raw "$script:tmp/.claude/settings.json").Trim() | Should -BeExactly '{ "user": "value" }'
    }

    It 'honours core.hooksPath when set' {
      $customHooks = "$script:tmp/custom-hooks"
      $null = New-Item -ItemType Directory -Force -Path $customHooks
      & git config core.hooksPath $customHooks 2>&1 | Out-Null
      & $script:installHooksScript *>&1 | Out-Null
      Test-Path "$customHooks/pre-commit" | Should -BeTrue
      Test-Path "$customHooks/pre-push"   | Should -BeTrue
      Test-Path "$script:tmp/.git/hooks/pre-commit" | Should -BeFalse
    }

    It 'fails when source hooks/ directory is missing' {
      Remove-Item -Recurse -Force "$script:tmp/hooks"
      { & $script:installHooksScript *>$null } | Should -Throw
    }
  }
}
