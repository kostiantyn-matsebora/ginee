BeforeAll {
  $script:commandsDir = (Resolve-Path "$PSScriptRoot/../adapters/claude/commands").Path
  $script:expected = @(
    'ginee-dispatch'
    'ginee-phase-report'
    'ginee-self-lint'
    'ginee-commit'
    'ginee-pr'
    'ginee-issue-pickup'
  )
}

Describe 'adapters/claude/commands/ — slash command suite (T10 / #146)' {

  It 'ships exactly the 6 commands documented in the playbook' {
    $files = @(Get-ChildItem -Path $script:commandsDir -Filter 'ginee-*.md' | ForEach-Object { $_.BaseName })
    Compare-Object -ReferenceObject $script:expected -DifferenceObject $files | Should -BeNullOrEmpty
  }

  Context 'frontmatter shape' {
    It '<_> has YAML frontmatter with description' -ForEach $expected {
      $path = Join-Path $script:commandsDir "$_.md"
      $body = Get-Content -Raw -LiteralPath $path
      $body | Should -Match '(?ms)^---\r?\n.*?\bdescription:\s*\S'
      $body | Should -Match '(?ms)^---\r?\n.*?\r?\n---\r?\n'
    }
  }

  Context 'schema markers per command' {

    It 'ginee-dispatch contains every required dispatch-prompt section' {
      $body = Get-Content -Raw -LiteralPath (Join-Path $script:commandsDir 'ginee-dispatch.md')
      $body | Should -Match '##\s+Reading list'
      $body | Should -Match '##\s+Task'
      $body | Should -Match '##\s+Read discipline'
      $body | Should -Match '##\s+Deliverable'
      $body | Should -Match '##\s+Required output'
      $body | Should -Match 'core/protocols/dispatch-prompt-schema\.md'
      $body | Should -Match '<!-- self-lint: pass -->'
    }

    It 'ginee-phase-report contains every required phase-report section' {
      $body = Get-Content -Raw -LiteralPath (Join-Path $script:commandsDir 'ginee-phase-report.md')
      $body | Should -Match 'Status:\s+Done\s*\|\s*In-progress'
      $body | Should -Match '##\s+Files touched'
      $body | Should -Match '##\s+Decisions made'
      $body | Should -Match '##\s+Verification log'
      $body | Should -Match '##\s+Open issues'
      $body | Should -Match '##\s+Next dispatch needed'
      $body | Should -Match '##\s+Source reads \(this dispatch\)'
      $body | Should -Match '<!-- self-lint: pass -->'
    }

    It 'ginee-self-lint enumerates the 7 mandatory checks + advisory rule' {
      $body = Get-Content -Raw -LiteralPath (Join-Path $script:commandsDir 'ginee-self-lint.md')
      $body | Should -Match '7\s+self-lint\s+checks'
      ([regex]::Matches($body, '(?m)^\s*\d+\.\s+\*\*')).Count | Should -BeGreaterOrEqual 7
      $body | Should -Match 'never re-dispatch for format'
    }

    It 'ginee-commit puts Closes #N INSIDE the body, not after the trailer block' {
      $body = Get-Content -Raw -LiteralPath (Join-Path $script:commandsDir 'ginee-commit.md')
      # The fenced skeleton block carries the canonical ordering — extract it then
      # assert Closes #<N> precedes the Optimized-By / Co-Authored-By trailers there.
      $skeleton = [regex]::Match($body, '(?ms)```\r?\n(.*?Closes\s+#<N>.*?)\r?\n```').Groups[1].Value
      $skeleton                    | Should -Not -BeNullOrEmpty
      $closesIdx       = $skeleton.IndexOf('Closes #<N>')
      $optimizedByIdx  = $skeleton.IndexOf('Optimized-By: ai-engineer')
      $coAuthoredByIdx = $skeleton.IndexOf('Co-Authored-By: Claude Opus')
      $closesIdx       | Should -BeGreaterThan -1
      $optimizedByIdx  | Should -BeGreaterThan $closesIdx
      $coAuthoredByIdx | Should -BeGreaterThan $closesIdx
      $body | Should -Match 'git interpret-trailers'
    }

    It 'ginee-pr cites the framework PR template + heredoc submission pattern' {
      $body = Get-Content -Raw -LiteralPath (Join-Path $script:commandsDir 'ginee-pr.md')
      $body | Should -Match 'core/templates/pr-description\.md'
      $body | Should -Match '##\s+What'
      $body | Should -Match '##\s+Why'
      $body | Should -Match '##\s+Cites'
      $body | Should -Match '##\s+Issue linkage'
      $body | Should -Match '##\s+Verification log'
      $body | Should -Match "gh pr create"
      $body | Should -Match 'HEREDOC'
    }

    It 'ginee-issue-pickup cites comments + sub-issues fetch + scoring + sticky' {
      $body = Get-Content -Raw -LiteralPath (Join-Path $script:commandsDir 'ginee-issue-pickup.md')
      $body | Should -Match 'core/skills/ginee-pick-up/SKILL\.md'
      $body | Should -Match 'gh issue view .* --comments'
      $body | Should -Match 'sub_issues'
      $body | Should -Match 'core/protocols/triage-scoring\.md'
      $body | Should -Match 'ginee:score v=1'
    }
  }
}
