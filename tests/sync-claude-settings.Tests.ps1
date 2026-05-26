BeforeAll {
  $script:syncScript = (Resolve-Path "$PSScriptRoot/../core/scripts/sync-claude-settings.ps1").Path

  function Invoke-Sync {
    param([string]$Target, [string]$FrameworkRel = '.agents/ginee')
    & pwsh -NoProfile -File $script:syncScript -Target $Target -FrameworkRel $FrameworkRel *>$null
    return $LASTEXITCODE
  }

  function Read-SettingsJson {
    param([string]$Target)
    $p = Join-Path $Target '.claude/settings.json'
    if (-not (Test-Path -LiteralPath $p)) { return $null }
    return Get-Content -Raw -LiteralPath $p | ConvertFrom-Json -AsHashtable
  }

  function Get-FreshTarget {
    return (New-Item -ItemType Directory -Force `
      -Path (Join-Path ([System.IO.Path]::GetTempPath()) "ginee-sync-test-$([guid]::NewGuid().Guid)")).FullName
  }
}

Describe 'sync-claude-settings.ps1' {

  It 'parses cleanly' {
    { [scriptblock]::Create((Get-Content -Raw $script:syncScript)) } | Should -Not -Throw
  }

  Context 'fresh adopter (no .claude/settings.json)' {
    BeforeEach { $script:tgt = Get-FreshTarget }
    AfterEach { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $script:tgt }

    It 'creates settings.json with statusLine + Tier1/Tier2/Tier3 hook entries' {
      Invoke-Sync -Target $script:tgt | Should -Be 0
      $s = Read-SettingsJson $script:tgt
      $s | Should -Not -BeNullOrEmpty
      $s.statusLine.command | Should -Match 'adapters/claude/statusline\.ps1$'
      # T2 + T3 + T8 → 3 PreToolUse matcher entries.
      $s.hooks.PreToolUse.Count | Should -Be 3
      $matchers = @($s.hooks.PreToolUse | ForEach-Object { $_.matcher })
      $matchers | Should -Contain 'Edit|Write|MultiEdit'
      $matchers | Should -Contain 'Bash'
      $matchers | Should -Contain 'SendMessage'
      # PostToolUse — T6 only (context-economy-check is framework-self-dev,
      # not wired into adopter settings since scripts/ is pruned on install).
      $s.hooks.PostToolUse.Count | Should -Be 1
      $postCmds = @($s.hooks.PostToolUse[0].hooks | ForEach-Object { $_.command })
      ($postCmds -match 'post-tool-use-edit').Count       | Should -Be 1
      ($postCmds -match 'context-economy-check').Count | Should -Be 0
      # T5 + T7 + T12 land their own event keys.
      $s.hooks.UserPromptSubmit.Count | Should -Be 1
      $s.hooks.Stop.Count             | Should -Be 1
      $s.hooks.SessionStart.Count     | Should -Be 1
      $s.hooks.SessionStart[0].hooks[0].command | Should -Match 'adapters/claude/hooks/session-start\.ps1$'
    }

    It 'creates the T11 main-thread permission lockdown (permissions.deny)' {
      Invoke-Sync -Target $script:tgt | Should -Be 0
      $s = Read-SettingsJson $script:tgt
      $s.permissions.deny | Should -Not -BeNullOrEmpty
      $s.permissions.deny | Should -Contain 'Edit(.agents/ginee/core/**)'
      $s.permissions.deny | Should -Contain 'Write(.agents/ginee/core/**)'
      $s.permissions.deny | Should -Contain 'MultiEdit(.agents/ginee/core/**)'
      $s.permissions.deny | Should -Contain 'Bash(rm -rf:*)'
      $s.permissions.deny | Should -Contain 'Bash(git push --force:*)'
      $s.permissions.deny | Should -Contain 'Bash(git reset --hard:*)'
    }

    It 'honours compliance.disabled: [main-thread-permissions] opt-out (T11)' {
      $localDir = Join-Path $script:tgt 'local'
      New-Item -ItemType Directory -Force -Path $localDir | Out-Null
      Set-Content -LiteralPath (Join-Path $localDir 'framework.config.yaml') -Value @"
compliance:
  disabled:
    - main-thread-permissions
"@ -NoNewline
      Invoke-Sync -Target $script:tgt | Should -Be 0
      $s = Read-SettingsJson $script:tgt
      # Hooks still wired (T11 only skipped).
      $s.hooks.PreToolUse.Count | Should -Be 3
      # No permissions.deny additions.
      ($s.permissions -and $s.permissions.deny -and ($s.permissions.deny | Where-Object { $_ -like 'Edit(*core/**)' }).Count) `
        | Should -Not -BeTrue
    }

    It 'is idempotent on re-run' {
      Invoke-Sync -Target $script:tgt | Should -Be 0
      $before = (Get-Content -Raw -LiteralPath (Join-Path $script:tgt '.claude/settings.json'))
      Invoke-Sync -Target $script:tgt | Should -Be 0
      $after = (Get-Content -Raw -LiteralPath (Join-Path $script:tgt '.claude/settings.json'))
      $after | Should -BeExactly $before
    }
  }

  Context 'existing settings.json with adopter customisations' {
    BeforeEach { $script:tgt = Get-FreshTarget }
    AfterEach { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $script:tgt }

    It 'preserves unrelated top-level keys (env, theme)' {
      $existing = @{
        env   = @{ DEBUG = 'true' }
        theme = 'dark'
      } | ConvertTo-Json -Depth 5
      New-Item -ItemType Directory -Force -Path (Join-Path $script:tgt '.claude') | Out-Null
      Set-Content -LiteralPath (Join-Path $script:tgt '.claude/settings.json') -Value $existing -NoNewline -Encoding utf8

      Invoke-Sync -Target $script:tgt | Should -Be 0
      $s = Read-SettingsJson $script:tgt
      $s.env.DEBUG | Should -Be 'true'
      $s.theme     | Should -Be 'dark'
      $s.statusLine.command | Should -Match 'statusline\.ps1$'
    }

    It 'does NOT overwrite an adopter-customised statusLine command' {
      $custom = 'my-custom-status.sh'
      $existing = @{
        statusLine = @{ type = 'command'; command = $custom }
      } | ConvertTo-Json -Depth 5
      New-Item -ItemType Directory -Force -Path (Join-Path $script:tgt '.claude') | Out-Null
      Set-Content -LiteralPath (Join-Path $script:tgt '.claude/settings.json') -Value $existing -NoNewline -Encoding utf8

      Invoke-Sync -Target $script:tgt | Should -Be 0
      $s = Read-SettingsJson $script:tgt
      $s.statusLine.command | Should -Be $custom
      # But T2/T3/T8 PreToolUse hooks still added
      $s.hooks.PreToolUse.Count | Should -Be 3
    }

    It 'refreshes a ginee-owned statusLine command if the path changed' {
      $stale = 'pwsh -NoProfile -File OLD/PATH/adapters/claude/statusline.ps1'
      $existing = @{
        statusLine = @{ type = 'command'; command = $stale }
      } | ConvertTo-Json -Depth 5
      New-Item -ItemType Directory -Force -Path (Join-Path $script:tgt '.claude') | Out-Null
      Set-Content -LiteralPath (Join-Path $script:tgt '.claude/settings.json') -Value $existing -NoNewline -Encoding utf8

      Invoke-Sync -Target $script:tgt | Should -Be 0
      $s = Read-SettingsJson $script:tgt
      $s.statusLine.command | Should -Be 'pwsh -NoProfile -File .agents/ginee/adapters/claude/statusline.ps1'
    }

    It 'does NOT add a duplicate Edit/Write PreToolUse entry when one is already present' {
      $existing = @{
        hooks = @{
          PreToolUse = @(
            @{
              matcher = 'Edit'
              hooks   = @(@{
                type    = 'command'
                command = 'pwsh -NoProfile -File some/path/adapters/claude/hooks/pre-tool-use-edit.ps1'
                timeout = 5
              })
            }
          )
        }
      } | ConvertTo-Json -Depth 6
      New-Item -ItemType Directory -Force -Path (Join-Path $script:tgt '.claude') | Out-Null
      Set-Content -LiteralPath (Join-Path $script:tgt '.claude/settings.json') -Value $existing -NoNewline -Encoding utf8

      Invoke-Sync -Target $script:tgt | Should -Be 0
      $s = Read-SettingsJson $script:tgt
      # Original edit-hook entry preserved (matcher 'Edit', not Edit|Write|MultiEdit)
      $editEntries = @($s.hooks.PreToolUse | Where-Object {
        $_.hooks[0].command -match 'pre-tool-use-edit'
      })
      $editEntries.Count | Should -Be 1
      # Bash entry was added since absent before
      $bashEntries = @($s.hooks.PreToolUse | Where-Object {
        $_.hooks[0].command -match 'pre-tool-use-bash'
      })
      $bashEntries.Count | Should -Be 1
    }
  }

  Context 'malformed settings.json' {
    It 'leaves the file untouched and exits 0 (warn-only)' {
      $tgt = Get-FreshTarget
      try {
        New-Item -ItemType Directory -Force -Path (Join-Path $tgt '.claude') | Out-Null
        $junk = '{ this is not json'
        Set-Content -LiteralPath (Join-Path $tgt '.claude/settings.json') -Value $junk -NoNewline
        Invoke-Sync -Target $tgt | Should -Be 0
        (Get-Content -Raw -LiteralPath (Join-Path $tgt '.claude/settings.json')) | Should -Be $junk
      } finally {
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $tgt
      }
    }
  }

  Context 'custom -FrameworkRel' {
    It 'honours a non-default framework path in emitted commands' {
      $tgt = Get-FreshTarget
      try {
        Invoke-Sync -Target $tgt -FrameworkRel 'vendor/ginee' | Should -Be 0
        $s = Read-SettingsJson $tgt
        $s.statusLine.command | Should -Match '^pwsh -NoProfile -File vendor/ginee/adapters/claude/statusline\.ps1$'
        $s.hooks.PreToolUse[0].hooks[0].command | Should -Match 'vendor/ginee/adapters/claude/hooks/pre-tool-use-(edit|bash)\.ps1$'
      } finally {
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $tgt
      }
    }
  }
}
