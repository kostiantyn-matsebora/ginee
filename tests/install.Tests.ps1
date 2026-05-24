BeforeAll {
  $script:installScript = (Resolve-Path "$PSScriptRoot/../install.ps1").Path

  # Load only the model-tier helper functions from install.ps1 — avoids running
  # the installer's top-level code (which fetches the framework from GitHub).
  # The functions are defined between the `# --- Model-tier overrides (D31)`
  # banner and the `# --- 3. Adapter prompt + install` banner.
  $installerText = Get-Content -Raw $script:installScript
  $mtBlock = [regex]::Match(
    $installerText,
    '(?ms)# --- Model-tier overrides \(D31\).*?# --- 3\. Adapter prompt'
  )
  if (-not $mtBlock.Success) {
    throw 'Could not locate the D31 model-tier helper block in install.ps1'
  }
  # Write the extracted block to a temp file and dot-source it into the test
  # scope — avoids PSScriptAnalyzer's PSAvoidUsingInvokeExpression warning while
  # still defining the helper functions for the test cases below.
  $script:mtHelperPath = Join-Path ([System.IO.Path]::GetTempPath()) "ginee-mt-helpers-$([guid]::NewGuid().Guid).ps1"
  Set-Content -LiteralPath $script:mtHelperPath -Value $mtBlock.Value -NoNewline
  . $script:mtHelperPath
}

AfterAll {
  if ($script:mtHelperPath -and (Test-Path $script:mtHelperPath)) {
    Remove-Item -LiteralPath $script:mtHelperPath -Force -ErrorAction SilentlyContinue
  }
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

  # Migrations are upstream-only; installer must prune both the new home
  # (<fw>/migrations/) and the legacy home (<fw>/core/MIGRATIONS/) on every
  # install. Each lookup grabs the prune-array block delimited by the section
  # banners so an unrelated `)` inside a comment (e.g. `(would shadow ...)`)
  # doesn't truncate the non-greedy regex.
  Context 'Migrations prune' {
    BeforeAll {
      $script:installerText = Get-Content -Raw $script:installScript
      # Match from "$pruneRoots = @(" through the matching close-paren on its
      # own line (PowerShell convention for multi-line arrays).
      $script:pruneRootsBlock = [regex]::Match(
        $script:installerText,
        '(?ms)\$pruneRoots\s*=\s*@\(.*?^\)'
      ).Value
    }

    It 'extracts the $pruneRoots array' {
      $script:pruneRootsBlock | Should -Not -BeNullOrEmpty
    }

    It 'lists migrations in the $pruneRoots array (new home)' {
      $script:pruneRootsBlock | Should -Match "'migrations'"
    }

    It 'lists core/MIGRATIONS in the $pruneRoots array (legacy home backcompat)' {
      $script:pruneRootsBlock | Should -Match "'core/MIGRATIONS'"
    }

    It 'documents the prune in the banner comment' {
      $script:installerText | Should -Match 'upstream-only'
      $script:installerText | Should -Match '/ginee-update'
    }
  }
}

Describe 'Read-ModelTierConfig (D31)' {
  BeforeAll {
    $script:tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "ginee-mt-test-$([guid]::NewGuid().Guid)"
    New-Item -ItemType Directory -Force -Path $script:tmpDir | Out-Null
  }
  AfterAll {
    Remove-Item -Recurse -Force $script:tmpDir -ErrorAction SilentlyContinue
  }

  It 'returns $null when the config file does not exist' {
    $missing = Join-Path $script:tmpDir 'missing.yaml'
    Read-ModelTierConfig $missing | Should -BeNullOrEmpty
  }

  It 'returns $null when model-tier section is absent' {
    $cfg = Join-Path $script:tmpDir 'no-mt.yaml'
    Set-Content -LiteralPath $cfg -Value @"
architecture-doc: docs/architecture.md
delivery:
  default-mode: branch
"@
    Read-ModelTierConfig $cfg | Should -BeNullOrEmpty
  }

  It 'parses per-role overrides + claude adapter map' {
    $cfg = Join-Path $script:tmpDir 'full.yaml'
    Set-Content -LiteralPath $cfg -Value @"
# header comment
architecture-doc: docs/architecture.md

model-tier:
  per-role:
    team-lead: reasoning
    ai-engineer: reasoning
    qa-engineer: fast
  adapters:
    claude:
      reasoning: claude-opus-4-7
      standard: claude-sonnet-4-6
      fast: claude-haiku-4-5-20251001
    copilot-cli: {}

delivery:
  default-mode: branch
"@
    $parsed = Read-ModelTierConfig $cfg
    $parsed | Should -Not -BeNullOrEmpty
    $parsed.PerRole['team-lead']      | Should -Be 'reasoning'
    $parsed.PerRole['ai-engineer']    | Should -Be 'reasoning'
    $parsed.PerRole['qa-engineer']    | Should -Be 'fast'
    $parsed.PerRole.Keys.Count        | Should -Be 3
    $parsed.ClaudeMap['reasoning']    | Should -Be 'claude-opus-4-7'
    $parsed.ClaudeMap['standard']     | Should -Be 'claude-sonnet-4-6'
    $parsed.ClaudeMap['fast']         | Should -Be 'claude-haiku-4-5-20251001'
    $parsed.ClaudeMap.Keys.Count      | Should -Be 3
  }

  It 'ignores comments inside the model-tier block' {
    $cfg = Join-Path $script:tmpDir 'comments.yaml'
    Set-Content -LiteralPath $cfg -Value @"
model-tier:
  per-role:
    # this is a comment
    backend-engineer: standard
  adapters:
    claude:
      # commented map entry
      standard: claude-sonnet-4-6
"@
    $parsed = Read-ModelTierConfig $cfg
    $parsed.PerRole['backend-engineer'] | Should -Be 'standard'
    $parsed.ClaudeMap['standard']       | Should -Be 'claude-sonnet-4-6'
  }
}

Describe 'Set-ClaudeAgentModel (D31)' {
  BeforeAll {
    $script:tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "ginee-mt-rewrite-$([guid]::NewGuid().Guid)"
    New-Item -ItemType Directory -Force -Path $script:tmpDir | Out-Null

    function script:New-PointerFile([string]$dir, [string]$role, [string]$existingModel) {
      $file = Join-Path $dir "$role.md"
      $modelLine = if ($existingModel) { "model: $existingModel`n" } else { '' }
      $body = @"
---
name: $role
description: Test pointer for $role.
${modelLine}---

body
"@
      Set-Content -LiteralPath $file -Value $body -NoNewline
      return $file
    }
  }
  AfterAll {
    Remove-Item -Recurse -Force $script:tmpDir -ErrorAction SilentlyContinue
  }

  It 'is a no-op when the config is $null' {
    $agentsDir = Join-Path $script:tmpDir 'agents-null'
    New-Item -ItemType Directory -Force -Path $agentsDir | Out-Null
    $file = New-PointerFile $agentsDir 'team-lead' 'claude-opus-4-7'
    $before = Get-Content -LiteralPath $file -Raw
    { Set-ClaudeAgentModel $agentsDir $null } | Should -Not -Throw
    Get-Content -LiteralPath $file -Raw | Should -Be $before
  }

  It 'rewrites the model line when an override applies' {
    $agentsDir = Join-Path $script:tmpDir 'agents-override'
    New-Item -ItemType Directory -Force -Path $agentsDir | Out-Null
    $file = New-PointerFile $agentsDir 'ai-engineer' 'claude-sonnet-4-6'
    $cfg = @{
      PerRole   = @{ 'ai-engineer' = 'reasoning' }
      ClaudeMap = @{ 'reasoning' = 'claude-opus-4-7'; 'standard' = 'claude-sonnet-4-6' }
    }
    Set-ClaudeAgentModel $agentsDir $cfg
    $after = Get-Content -LiteralPath $file -Raw
    $after | Should -Match '(?m)^model:\s+claude-opus-4-7'
    $after | Should -Match 'D31 . reasoning tier'
    $after | Should -Not -Match 'model: claude-sonnet-4-6'
  }

  It 'leaves files without a matching override untouched' {
    $agentsDir = Join-Path $script:tmpDir 'agents-untouched'
    New-Item -ItemType Directory -Force -Path $agentsDir | Out-Null
    $file = New-PointerFile $agentsDir 'qa-engineer' 'claude-sonnet-4-6'
    $before = Get-Content -LiteralPath $file -Raw
    $cfg = @{
      PerRole   = @{ 'ai-engineer' = 'reasoning' }
      ClaudeMap = @{ 'reasoning' = 'claude-opus-4-7' }
    }
    Set-ClaudeAgentModel $agentsDir $cfg
    Get-Content -LiteralPath $file -Raw | Should -Be $before
  }

  It 'injects the model line when the pointer file lacks one' {
    $agentsDir = Join-Path $script:tmpDir 'agents-inject'
    New-Item -ItemType Directory -Force -Path $agentsDir | Out-Null
    $file = New-PointerFile $agentsDir 'devops-engineer' $null
    $cfg = @{
      PerRole   = @{ 'devops-engineer' = 'fast' }
      ClaudeMap = @{ 'fast' = 'claude-haiku-4-5-20251001' }
    }
    Set-ClaudeAgentModel $agentsDir $cfg
    $after = Get-Content -LiteralPath $file -Raw
    $after | Should -Match '(?m)^model:\s+claude-haiku-4-5-20251001'
    $after | Should -Match 'D31 . fast tier'
  }

  It 'skips files whose tier is set but adapter map lacks that tier' {
    $agentsDir = Join-Path $script:tmpDir 'agents-skip'
    New-Item -ItemType Directory -Force -Path $agentsDir | Out-Null
    $file = New-PointerFile $agentsDir 'backend-engineer' 'claude-sonnet-4-6'
    $before = Get-Content -LiteralPath $file -Raw
    $cfg = @{
      PerRole   = @{ 'backend-engineer' = 'fast' }
      ClaudeMap = @{ 'reasoning' = 'claude-opus-4-7' }   # no 'fast' entry
    }
    Set-ClaudeAgentModel $agentsDir $cfg
    Get-Content -LiteralPath $file -Raw | Should -Be $before
  }

  # --- #82 regression — comment must live on its own line, not inline ---------

  It 'emits comment-above shape — bare model line + comment on its own line (no inline `#`)' {
    $agentsDir = Join-Path $script:tmpDir 'agents-shape'
    New-Item -ItemType Directory -Force -Path $agentsDir | Out-Null
    $file = New-PointerFile $agentsDir 'ai-engineer' 'claude-sonnet-4-6'
    $cfg = @{
      PerRole   = @{ 'ai-engineer' = 'reasoning' }
      ClaudeMap = @{ 'reasoning' = 'claude-opus-4-7' }
    }
    Set-ClaudeAgentModel $agentsDir $cfg
    $after = Get-Content -LiteralPath $file -Raw
    # Bare model line — value followed immediately by EOL, no inline comment.
    $after | Should -Match '(?m)^model:\s+claude-opus-4-7\s*$'
    # Comment lives on its own line directly above the model line.
    $after | Should -Match '(?ms)^# D31 — reasoning tier.*\r?\nmodel:\s+claude-opus-4-7\s*$'
  }

  It 'does not accumulate comment lines when rewriting a pointer that already has the comment-above shape' {
    $agentsDir = Join-Path $script:tmpDir 'agents-noaccum'
    New-Item -ItemType Directory -Force -Path $agentsDir | Out-Null
    $file = Join-Path $agentsDir 'devops-engineer.md'
    # Pointer shipped by adapters/_shared/agents/* — comment above, bare model line.
    Set-Content -LiteralPath $file -NoNewline -Value @"
---
name: devops-engineer
description: test pointer
# D31 — standard tier; override via local/framework.config.yaml § model-tier.per-role.devops-engineer
model: claude-sonnet-4-6
---

body
"@
    $cfg = @{
      PerRole   = @{ 'devops-engineer' = 'fast' }
      ClaudeMap = @{ 'fast' = 'claude-haiku-4-5-20251001' }
    }
    Set-ClaudeAgentModel $agentsDir $cfg
    $after = Get-Content -LiteralPath $file -Raw
    # Exactly ONE `# D31 — ` comment in the file (no accumulation).
    ([regex]::Matches($after, '(?m)^# D31 — ')).Count | Should -Be 1
    # Comment reflects the new tier; old `standard tier` text is gone.
    $after | Should -Match '# D31 — fast tier'
    $after | Should -Not -Match 'standard tier'
    # Model line stayed bare.
    $after | Should -Match '(?m)^model:\s+claude-haiku-4-5-20251001\s*$'
  }
}
