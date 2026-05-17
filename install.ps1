# engineering-team installer (PowerShell)
#
# Run this from the ROOT of the project / git repo you want to install the framework into.
# The installer treats the current working directory as the project root and creates:
#   .\.agents\engineering-team\   — the framework (core, adapters, extras, local)
#   .\.claude\agents\             — Claude adapter (when -Adapter claude)
#   .\.github\agents\             — Copilot CLI adapter (when -Adapter copilot-cli)
#   .\AGENTS.md                   — AGENTS.md adapter (when -Adapter agents-md)
# Use -Target to install into a different directory.
#
# Usage (local — recommended while the framework repo is private):
#   iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/engineering-team/main/install.ps1 -OutFile install.ps1
#   .\install.ps1 [-Target <path>] [-Adapter <claude|copilot-cli|agents-md|generic>] [-Ref <branch-or-tag>] [-UpdateOnly]
#
# Usage (remote one-liner — works once the framework repo is public; env vars carry arguments since `iex` can't accept params):
#   $env:ET_ADAPTER='claude'; iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/engineering-team/main/install.ps1 | iex
#   $env:ET_ADAPTER='claude'; $env:ET_REF='v0.1.0'; iwr -useb <url>/install.ps1 | iex

[CmdletBinding()]
param(
  [string] $Target = (Get-Location).Path,
  [ValidateSet('claude','copilot-cli','agents-md','generic')]
  [string] $Adapter,
  [string] $Ref = 'main',
  [string] $RepoUrl = 'https://github.com/kostiantyn-matsebora/engineering-team',
  [switch] $UpdateOnly
)

# Fallback to env vars when invoked via `iwr | iex` (which cannot pass parameters)
if (-not $Adapter -and $env:ET_ADAPTER) { $Adapter = $env:ET_ADAPTER }
if ($env:ET_REF)    { $Ref = $env:ET_REF }
if ($env:ET_TARGET) { $Target = $env:ET_TARGET }
if ($env:ET_REPO)   { $RepoUrl = $env:ET_REPO }
if ($env:ET_UPDATE_ONLY -eq '1' -or $env:ET_UPDATE_ONLY -eq 'true') { $UpdateOnly = $true }

$ErrorActionPreference = 'Stop'
$frameworkDir = Join-Path $Target '.agents\engineering-team'

Write-Host "engineering-team installer" -ForegroundColor Cyan
Write-Host "  Project root     : $Target   (cwd — pass -Target to install elsewhere)"
Write-Host "  Framework dir    : $frameworkDir"
Write-Host "  Adapter          : $(if ($Adapter) { $Adapter } else { 'detect interactively' })"
Write-Host "  Ref              : $Ref"
Write-Host ""
Write-Host "This installer must be run from the root of the project / git repo you want to set up." -ForegroundColor Yellow
Write-Host "It writes the framework into .\.agents\engineering-team\ and adapter files into your project tree."
Write-Host ""

# --- 1. Fetch framework ----------------------------------------------------

if (Test-Path $frameworkDir) {
  if ($UpdateOnly) {
    Write-Host "Updating existing framework at $frameworkDir (preserving local/)..." -ForegroundColor Yellow
    # Preserve local/
    $localBackup = Join-Path ([System.IO.Path]::GetTempPath()) "et-local-$([guid]::NewGuid().Guid)"
    if (Test-Path (Join-Path $frameworkDir 'local')) {
      Copy-Item -Recurse (Join-Path $frameworkDir 'local') $localBackup
    }
    Remove-Item -Recurse -Force (Join-Path $frameworkDir 'core'),
                                (Join-Path $frameworkDir 'adapters'),
                                (Join-Path $frameworkDir 'extras') -ErrorAction SilentlyContinue
  } else {
    Write-Error "Framework already installed at $frameworkDir. Use -UpdateOnly to refresh core/+adapters/+extras/ (local/ is preserved)."
  }
} else {
  Write-Host "Cloning framework..." -ForegroundColor Cyan
  New-Item -ItemType Directory -Force (Split-Path -Parent $frameworkDir) | Out-Null
  git clone --depth 1 --branch $Ref $RepoUrl $frameworkDir
  Remove-Item -Recurse -Force (Join-Path $frameworkDir '.git') -ErrorAction SilentlyContinue
}

# --- 2. Restore local/ on update -------------------------------------------

if ($UpdateOnly -and (Test-Path $localBackup)) {
  Write-Host "Restoring preserved local/..." -ForegroundColor Cyan
  Copy-Item -Recurse $localBackup (Join-Path $frameworkDir 'local')
  Remove-Item -Recurse -Force $localBackup
}

# --- 3. Adapter prompt + install --------------------------------------------

if (-not $Adapter) {
  Write-Host ""
  Write-Host "Pick the adapter that matches your LLM client:" -ForegroundColor Cyan
  Write-Host "  [1] claude       — Claude Code (tier-1)"
  Write-Host "  [2] copilot-cli  — GitHub Copilot CLI (tier-1)"
  Write-Host "  [3] agents-md    — Codex / Cursor / Windsurf / Amp / Devin / Factory / Jules / Copilot IDE (tier-2)"
  Write-Host "  [4] generic      — INSTRUCTIONS.md fallback (tier-3)"
  $sel = Read-Host "Pick 1-4"
  switch ($sel) {
    '1' { $Adapter = 'claude' }
    '2' { $Adapter = 'copilot-cli' }
    '3' { $Adapter = 'agents-md' }
    '4' { $Adapter = 'generic' }
    default { Write-Error "Invalid selection: $sel" }
  }
}

$adapterDir = Join-Path $frameworkDir "adapters\$Adapter"
$installNote = Join-Path $adapterDir 'install.md'

Write-Host ""
Write-Host "Adapter '$Adapter' will be installed per:" -ForegroundColor Cyan
Write-Host "  $installNote"
Write-Host ""

switch ($Adapter) {
  'claude' {
    $agentsDir = Join-Path $Target '.claude\agents'
    New-Item -ItemType Directory -Force $agentsDir | Out-Null
    Copy-Item (Join-Path $frameworkDir 'adapters\_shared\agents\*.md') $agentsDir
    Write-Host "Copied 7 cardinal subagents to .claude/agents/" -ForegroundColor Green
    Write-Host "NEXT: append CLAUDE-pointer.md to your project's CLAUDE.md (see $installNote)" -ForegroundColor Yellow
  }
  'copilot-cli' {
    $agentsDir = Join-Path $Target '.github\agents'
    New-Item -ItemType Directory -Force $agentsDir | Out-Null
    Get-ChildItem (Join-Path $frameworkDir 'adapters\_shared\agents\*.md') | ForEach-Object {
      Copy-Item $_.FullName (Join-Path $agentsDir "$($_.BaseName).agent.md")
    }
    Write-Host "Copied 7 cardinal subagents to .github/agents/*.agent.md" -ForegroundColor Green
  }
  'agents-md' {
    Copy-Item (Join-Path $frameworkDir 'adapters\agents-md\AGENTS.md') (Join-Path $Target 'AGENTS.md')
    Write-Host "Copied AGENTS.md to project root" -ForegroundColor Green
    Write-Host "NEXT (Gemini users): cp AGENTS.md GEMINI.md" -ForegroundColor Yellow
  }
  'generic' {
    Write-Host "Generic adapter is manual — point your LLM client at:" -ForegroundColor Yellow
    Write-Host "  $(Join-Path $frameworkDir 'adapters\generic\INSTRUCTIONS.md')"
    Write-Host "See $installNote for client-specific options."
  }
}

# --- 4. Final guidance ------------------------------------------------------

Write-Host ""
Write-Host "Install complete." -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open your client in this project."
Write-Host "  2. Prompt: @project-manager run initial discovery"
Write-Host "     (or 'act as project-manager and run initial discovery' for tier-2/3 clients)"
Write-Host "  3. Review the recommended specialists; user-approve any extras to enable."
Write-Host ""
Write-Host "Documentation:" -ForegroundColor Cyan
Write-Host "  README:      $(Join-Path $frameworkDir 'README.md')"
Write-Host "  Process:     $(Join-Path $frameworkDir 'core\process.md')"
Write-Host "  Adapter:     $installNote"
