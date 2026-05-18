# Pester tests

PowerShell quality bar per `CLAUDE.md § Hard constraints`: every `*.ps1` change passes [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) AND is covered by passing [Pester](https://pester.dev) tests under this directory.

## Convention

- One `<script-stem>.Tests.ps1` per script. Mirror the source layout:

  | Script | Test file |
  |---|---|
  | `install.ps1` | `tests/install.Tests.ps1` |
  | `core/scripts/migrate-engineering-team-to-ginee.ps1` | `tests/migrate-engineering-team-to-ginee.Tests.ps1` |

- Pester 5+. `BeforeAll` resolves the script under test via `$PSScriptRoot/..`.
- Tests that touch the filesystem create + tear down their own temp dir (`[System.IO.Path]::GetTempPath() / "ginee-..."`); never operate on the actual repo tree.

## Running locally

```powershell
Install-Module -Name Pester -MinimumVersion 5.5.0 -Force -SkipPublisherCheck -Scope CurrentUser
Invoke-Pester -Path ./tests -Output Detailed
```

CI: the `test-powershell` job in `.github/workflows/ci.yml` runs `Invoke-Pester` on every PR. Required-merge gate.
