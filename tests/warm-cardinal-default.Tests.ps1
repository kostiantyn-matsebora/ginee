BeforeAll {
  $script:repoRoot = (Resolve-Path "$PSScriptRoot/..").Path
  $script:migration = (Resolve-Path "$PSScriptRoot/../migrations/warm-cardinal-default.md").Path
  $script:warmSpecReuse = (Resolve-Path "$PSScriptRoot/../migrations/warm-specialist-reuse.md").Path
  $script:cfgTemplate = (Resolve-Path "$PSScriptRoot/../core/templates/framework.config.yaml").Path
}

Describe 'T11 / #147 — warm-cardinal-default migration coverage' {

  Context 'migration spec' {
    BeforeAll { $script:body = Get-Content -Raw -LiteralPath $script:migration }

    It 'cites parent #135 and predecessors D36 + D43 + T1 + T2' {
      $script:body | Should -Match '#135'
      $script:body | Should -Match 'warm-specialist-reuse\.md'
      $script:body | Should -Match 'warm-reuse-claude-plumbing\.md'
      $script:body | Should -Match 'cardinal-tools-whitelist\.md'
      $script:body | Should -Match 'pretooluse-edit-hook\.md'
    }

    It 'documents the main-thread permission lockdown with framework-scoped deny rules' {
      $script:body | Should -Match 'Edit\(\.agents/ginee/core/\*\*\)'
      $script:body | Should -Match 'Write\(\.agents/ginee/adapters/\*\*\)'
      $script:body | Should -Match 'MultiEdit\(\.agents/ginee/extras/\*\*\)'
      $script:body | Should -Match 'Bash\(rm -rf:\*\)'
      $script:body | Should -Match 'Bash\(git push --force:\*\)'
      $script:body | Should -Match 'Bash\(git reset --hard:\*\)'
    }

    It 'documents the per-tactic opt-out tactic-id main-thread-permissions' {
      $script:body | Should -Match 'compliance\.disabled:\s*\[main-thread-permissions\]'
    }

    It 'enumerates the dispatch-count soft cap with default 15' {
      $script:body | Should -Match 'warm-reuse\.dispatch-cap'
      $script:body | Should -Match 'default 15'
    }

    It 'documents the summary-handoff payload format' {
      $script:body | Should -Match '##\s+Carry-forward summary'
      $script:body | Should -Match 'Key decisions to inherit'
      $script:body | Should -Match 'Open work items'
      $script:body | Should -Match 'Re-read before proceeding'
    }

    It 'lists the resolution chain with 4 priority tiers ending at warm-resume' {
      $script:body | Should -Match '(?m)^1\.\s.*fresh:.*prefix'
      $script:body | Should -Match '(?m)^2\.\s.*Hard-fresh trigger'
      $script:body | Should -Match '(?m)^3\.\s.*Dispatch count > .*dispatch-cap'
      $script:body | Should -Match '(?m)^4\.\s.*Warm-resume per D43 plumbing'
    }
  }

  Context 'warm-specialist-reuse spec extension' {
    It 'gains the dispatch-cap forced-fresh trigger cross-referencing this migration' {
      $body = Get-Content -Raw -LiteralPath $script:warmSpecReuse
      $body | Should -Match 'dispatch-cap'
      $body | Should -Match 'warm-cardinal-default\.md'
    }
  }

  Context 'framework.config.yaml template' {
    It 'documents warm-reuse.dispatch-cap with default 15 (commented)' {
      $body = Get-Content -Raw -LiteralPath $script:cfgTemplate
      $body | Should -Match '(?ms)warm-reuse:.*dispatch-cap:\s*15'
    }

    It 'lists T11 tactic-id main-thread-permissions in the compliance.disabled comment' {
      $body = Get-Content -Raw -LiteralPath $script:cfgTemplate
      $body | Should -Match 'main-thread-permissions'
    }
  }
}
