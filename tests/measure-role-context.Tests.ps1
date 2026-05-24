#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.5.0' }

BeforeAll {
  $script:scriptPath = (Resolve-Path "$PSScriptRoot/../scripts/measure-role-context.ps1").Path
  $script:repoRoot = (Resolve-Path "$PSScriptRoot/..").Path

  # Run once + cache for the whole file.
  $script:jsonRaw = & pwsh -NoProfile -File $script:scriptPath -Json -RepoRoot $script:repoRoot 2>&1
  $script:results = $script:jsonRaw | ConvertFrom-Json
  $script:byRole = @{}
  foreach ($r in $script:results) { $script:byRole[$r.Role] = $r }
}

Describe 'measure-role-context.ps1 — script integrity' {
  It 'exits cleanly in JSON mode' {
    $LASTEXITCODE | Should -Be 0
  }

  It 'emits valid JSON' {
    $script:results | Should -Not -BeNullOrEmpty
    $script:results.Count | Should -BeGreaterThan 0
  }

  It 'covers all seven cardinal roles' {
    $expected = @('ai-engineer', 'backend-engineer', 'devops-engineer', 'frontend-engineer', 'qa-engineer', 'solution-architect', 'team-lead')
    $actual = ($script:results | ForEach-Object { $_.Role }) | Sort-Object
    $actual | Should -Be $expected
  }

  It 'reports a positive TotalBytes for every role' {
    foreach ($r in $script:results) {
      $r.TotalBytes | Should -BeGreaterThan 0 -Because "role $($r.Role) must load at least the role kernel + core/process.md"
    }
  }

  It 'includes core/process.md in every role''s Files list' {
    foreach ($r in $script:results) {
      $paths = $r.Files | ForEach-Object { $_.Path }
      $paths | Should -Contain 'core/process.md' -Because "core/process.md is always-loaded for every role ($($r.Role))"
    }
  }

  It 'includes the role''s own kernel file in every Files list' {
    foreach ($r in $script:results) {
      $paths = $r.Files | ForEach-Object { $_.Path }
      $expected = "core/roles/$($r.Role).md"
      $paths | Should -Contain $expected
    }
  }
}

Describe 'measure-role-context.ps1 — D35 phase-participation contract' {
  It 'team-lead loads all 8 phase files + dispatch.md' {
    $tl = $script:byRole['team-lead']
    @($tl.Phases) | Sort-Object | Should -Be (1..8)
    $paths = $tl.Files | ForEach-Object { $_.Path }
    $paths | Should -Contain 'core/process/dispatch.md' -Because 'team-lead is the orchestrator (D35)'
    for ($n = 1; $n -le 8; $n++) {
      ($paths | Where-Object { $_ -match "^core/process/phase-$n-" }).Count | Should -Be 1 -Because "team-lead must load phase-$n"
    }
  }

  It 'solution-architect loads phases [1, 2, 4, 5, 6, 7]' {
    $sa = $script:byRole['solution-architect']
    @($sa.Phases) | Sort-Object | Should -Be @(1, 2, 4, 5, 6, 7)
  }

  It 'engineering cardinals (backend / frontend / devops) load phases [2, 4, 5, 6]' {
    foreach ($r in @('backend-engineer', 'frontend-engineer', 'devops-engineer')) {
      @($script:byRole[$r].Phases) | Sort-Object | Should -Be @(2, 4, 5, 6) -Because "$r participates in design + implementation + test + fix"
    }
  }

  It 'qa-engineer loads phases [5, 6]' {
    @($script:byRole['qa-engineer'].Phases) | Sort-Object | Should -Be @(5, 6)
  }

  It 'ai-engineer loads no phase files (between-phase optimizer)' {
    @($script:byRole['ai-engineer'].Phases).Count | Should -Be 0
    $paths = $script:byRole['ai-engineer'].Files | ForEach-Object { $_.Path }
    ($paths | Where-Object { $_ -match '^core/process/phase-' }).Count | Should -Be 0
  }

  It 'no non-orchestrator role loads core/process/dispatch.md' {
    foreach ($r in $script:results | Where-Object { $_.Role -ne 'team-lead' }) {
      $paths = $r.Files | ForEach-Object { $_.Path }
      $paths | Should -Not -Contain 'core/process/dispatch.md' -Because "$($r.Role) is not an orchestrator (D35)"
    }
  }
}

Describe 'measure-role-context.ps1 — load-cost invariants' {
  BeforeAll {
    # Per-role byte ceilings — catch egregious regressions. Tuned at ~1.5x
    # current measurement, leaving headroom for small additions. Tighten over time.
    $script:ceilings = @{
      'ai-engineer'        = 40000  # ~25.6 KB observed
      'qa-engineer'        = 55000  # ~35.3 KB observed
      'frontend-engineer'  = 55000  # ~35.5 KB observed
      'backend-engineer'   = 55000  # ~35.6 KB observed
      'devops-engineer'    = 65000  # ~41.2 KB observed
      'solution-architect' = 65000  # ~41.7 KB observed
      'team-lead'          = 90000  # ~57.5 KB observed
    }
  }

  It 'every role stays below its per-role byte ceiling' {
    foreach ($r in $script:results) {
      $cap = $script:ceilings[$r.Role]
      $cap | Should -Not -BeNullOrEmpty -Because "the test must declare a ceiling for every cardinal role"
      $r.TotalBytes | Should -BeLessOrEqual $cap -Because "$($r.Role) load cost exceeded its ceiling — investigate before raising"
    }
  }

  It 'ai-engineer has the smallest load (between-phase optimizer)' {
    $ai = $script:byRole['ai-engineer'].TotalBytes
    foreach ($r in $script:results | Where-Object { $_.Role -ne 'ai-engineer' }) {
      $r.TotalBytes | Should -BeGreaterThan $ai -Because "ai-engineer should be the cheapest role; $($r.Role) regressed"
    }
  }

  It 'team-lead has the largest load (loads all phases + dispatch)' {
    $tl = $script:byRole['team-lead'].TotalBytes
    foreach ($r in $script:results | Where-Object { $_.Role -ne 'team-lead' }) {
      $r.TotalBytes | Should -BeLessThan $tl -Because "team-lead should be the most expensive role; $($r.Role) is heavier — D35 contract broken"
    }
  }

  It 'qa-engineer loads less than backend / frontend / devops (fewer phases)' {
    $qa = $script:byRole['qa-engineer'].TotalBytes
    foreach ($r in @('backend-engineer', 'frontend-engineer', 'devops-engineer')) {
      $qa | Should -BeLessOrEqual $script:byRole[$r].TotalBytes -Because "qa loads [5,6] only; $r loads [2,4,5,6] which strictly includes qa's set"
    }
  }
}
