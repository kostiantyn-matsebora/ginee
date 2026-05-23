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
}
