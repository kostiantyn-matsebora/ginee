#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '5.5.0' }

BeforeAll {
  $script:scriptPath = (Resolve-Path "$PSScriptRoot/../scripts/adapter-binding-check.ps1").Path

  # Each test sets up its own tmp git repo with a controlled commit history.
  function New-FixtureRepo {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()] param()
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "ab-check-$([guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    Push-Location $tmp
    try {
      & git init --quiet
      & git config user.email t@t
      & git config user.name t
      # Baseline 'main' branch with empty core/.
      New-Item -ItemType Directory -Force -Path 'core/roles' | Out-Null
      Set-Content 'core/roles/baseline.md' "# Baseline`nNothing normative.`n"
      & git add -A
      & git commit --quiet -m 'baseline'
      & git branch -M main
      & git checkout -q -b feature
    } finally {
      Pop-Location
    }
    return $tmp
  }

  function Invoke-Check {
    param([string]$Repo, [string]$Base = 'main', [switch]$AsJson)
    Push-Location $Repo
    try {
      $outFile = New-TemporaryFile
      $errFile = New-TemporaryFile
      try {
        $argv = @('-NoProfile','-File',$script:scriptPath,'-BaseRef',$Base)
        if ($AsJson) { $argv += '-Json' }
        $p = Start-Process -FilePath 'pwsh' -ArgumentList $argv -NoNewWindow `
          -PassThru -Wait `
          -RedirectStandardOutput $outFile.FullName `
          -RedirectStandardError $errFile.FullName
        $out = Get-Content -Raw -LiteralPath $outFile.FullName -ErrorAction SilentlyContinue
        $err = Get-Content -Raw -LiteralPath $errFile.FullName -ErrorAction SilentlyContinue
        return [pscustomobject]@{ ExitCode = $p.ExitCode; StdOut = ($out ?? ''); StdErr = ($err ?? '') }
      } finally {
        Remove-Item -ErrorAction SilentlyContinue -LiteralPath $outFile.FullName
        Remove-Item -ErrorAction SilentlyContinue -LiteralPath $errFile.FullName
      }
    } finally {
      Pop-Location
    }
  }

  function Remove-FixtureRepo {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param([string]$Repo)
    if ($Repo -and (Test-Path -LiteralPath $Repo)) {
      Remove-Item -Recurse -Force -LiteralPath $Repo -ErrorAction SilentlyContinue
    }
  }
}

Describe 'adapter-binding-check.ps1 — pre-push gate' {

  It 'parses cleanly' {
    { [scriptblock]::Create((Get-Content -Raw $script:scriptPath)) } | Should -Not -Throw
  }

  Context 'pass-through cases (exit 0)' {

    It 'passes when no core/** files changed' {
      $repo = New-FixtureRepo
      try {
        Push-Location $repo
        Set-Content 'README.md' 'just a readme tweak'
        & git add -A; & git commit --quiet -m 'docs: readme'
        Pop-Location
        $r = Invoke-Check -Repo $repo
        $r.ExitCode | Should -Be 0
      } finally { Remove-FixtureRepo $repo }
    }

    It 'passes when core/** changed but no MUST/SHOULD added' {
      $repo = New-FixtureRepo
      try {
        Push-Location $repo
        Set-Content 'core/roles/new.md' "# New role`nThis is descriptive only.`n"
        & git add -A; & git commit --quiet -m 'add descriptive role'
        Pop-Location
        $r = Invoke-Check -Repo $repo
        $r.ExitCode | Should -Be 0
      } finally { Remove-FixtureRepo $repo }
    }

    It 'passes when MUST rule added AND adapter-binding diff present' {
      $repo = New-FixtureRepo
      try {
        Push-Location $repo
        Set-Content 'core/roles/new.md' "# Rule`nEvery dispatch MUST cite the source.`n"
        New-Item -ItemType Directory -Force -Path 'adapters/claude/hooks' | Out-Null
        Set-Content 'adapters/claude/hooks/pre-tool-use-new.ps1' "# hook stub`n"
        & git add -A; & git commit --quiet -m 'rule + hook (Class A)'
        Pop-Location
        $r = Invoke-Check -Repo $repo
        $r.ExitCode | Should -Be 0
        $r.StdOut | Should -Match 'PASS'
      } finally { Remove-FixtureRepo $repo }
    }

    It 'passes when MUST rule added AND commit message cites force-class' {
      $repo = New-FixtureRepo
      try {
        Push-Location $repo
        Set-Content 'core/roles/new.md' "# Rule`nEvery cardinal MUST end with self-lint marker.`n"
        & git add -A; & git commit --quiet -m "feat: add self-lint MUST rule (Class H always-loaded text)"
        Pop-Location
        $r = Invoke-Check -Repo $repo
        $r.ExitCode | Should -Be 0
      } finally { Remove-FixtureRepo $repo }
    }

    It 'passes when MUST added in core/templates/issues/ (excluded path)' {
      $repo = New-FixtureRepo
      try {
        Push-Location $repo
        New-Item -ItemType Directory -Force -Path 'core/templates/issues' | Out-Null
        Set-Content 'core/templates/issues/bug.md' "# Bug template`nReporter MUST provide repro steps.`n"
        & git add -A; & git commit --quiet -m 'add bug template'
        Pop-Location
        $r = Invoke-Check -Repo $repo
        $r.ExitCode | Should -Be 0
      } finally { Remove-FixtureRepo $repo }
    }

    It 'honours SKIP_ADAPTER_BINDING=1' {
      $repo = New-FixtureRepo
      try {
        Push-Location $repo
        Set-Content 'core/roles/new.md' "# Rule`nThe orchestrator MUST do X.`n"
        & git add -A; & git commit --quiet -m 'feat: unbound rule'
        Pop-Location
        $orig = $env:SKIP_ADAPTER_BINDING
        try {
          $env:SKIP_ADAPTER_BINDING = '1'
          $r = Invoke-Check -Repo $repo
          $r.ExitCode | Should -Be 0
        } finally {
          $env:SKIP_ADAPTER_BINDING = $orig
        }
      } finally { Remove-FixtureRepo $repo }
    }
  }

  Context 'gate-triggered cases (exit 1)' {

    It 'fails when MUST rule added in core/roles/ with NO adapter-binding signal' {
      $repo = New-FixtureRepo
      try {
        Push-Location $repo
        Set-Content 'core/roles/new.md' "# Rule`nEvery cardinal MUST cite the contract surface in dispatch.`n"
        & git add -A; & git commit --quiet -m 'add unbound rule'
        Pop-Location
        $r = Invoke-Check -Repo $repo
        $r.ExitCode | Should -Be 1
        $r.StdOut | Should -Match 'Adapter-binding classification missing'
      } finally { Remove-FixtureRepo $repo }
    }

    It 'fails when MUST NOT rule added with NO signal' {
      $repo = New-FixtureRepo
      try {
        Push-Location $repo
        New-Item -ItemType Directory -Force -Path 'core/protocols' | Out-Null
        Set-Content 'core/protocols/new.md' "# Spec`nOrchestrator MUST NOT auto-rewrite returns.`n"
        & git add -A; & git commit --quiet -m 'add forbidden action'
        Pop-Location
        $r = Invoke-Check -Repo $repo
        $r.ExitCode | Should -Be 1
      } finally { Remove-FixtureRepo $repo }
    }

    It 'fails when SHOULD rule added in core/process.md with NO signal' {
      $repo = New-FixtureRepo
      try {
        Push-Location $repo
        Set-Content 'core/process.md' "# Process`nReturn SHOULD cite the dispatch prompt.`n"
        & git add -A; & git commit --quiet -m 'add SHOULD guidance'
        Pop-Location
        $r = Invoke-Check -Repo $repo
        $r.ExitCode | Should -Be 1
      } finally { Remove-FixtureRepo $repo }
    }

    It 'JSON mode returns the same exit code + machine-readable diagnostic' {
      $repo = New-FixtureRepo
      try {
        Push-Location $repo
        Set-Content 'core/roles/new.md' "# Rule`nEvery cardinal MUST cite the contract surface.`n"
        & git add -A; & git commit --quiet -m 'unbound rule'
        Pop-Location
        $r = Invoke-Check -Repo $repo -AsJson
        $r.ExitCode | Should -Be 1
        $obj = $r.StdOut | ConvertFrom-Json
        $obj.new_rules | Should -BeGreaterThan 0
        $obj.signal_found | Should -BeFalse
      } finally { Remove-FixtureRepo $repo }
    }
  }
}
