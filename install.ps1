# ginee installer (PowerShell)
#
# Parameter cheat-sheet (do not confuse the two paths):
#   -Target   = WHERE TO INSTALL INTO (the adopter project root — e.g. your dashboard repo).
#               Defaults to current working directory.
#   -RepoUrl  = WHERE TO FETCH THE FRAMEWORK FROM (the ginee git repo).
#               Defaults to the public GitHub URL. Pass a local checkout path
#               (e.g. C:\path\to\ginee) while the repo is private.
#
# The installer creates inside -Target:
#   .\.agents\ginee\   — the framework (core, adapters, extras, local)
#   .\.claude\agents\             — Claude adapter (when -Adapter claude)
#   .\.claude\skills\             — Claude adapter skills
#   .\.github\agents\             — Copilot CLI adapter (when -Adapter copilot-cli)
#   .\.agents\skills\             — Copilot CLI adapter skills (cross-tool AgentSkills path)
#   .\AGENTS.md                   — AGENTS.md adapter (when -Adapter agents-md)
#
# Field-trial example (private repo, local framework checkout, explicit -Target so cwd is irrelevant):
#   C:\path\to\ginee\install.ps1 `
#     -Target  C:\path\to\your-project `
#     -RepoUrl C:\path\to\ginee `
#     -Adapter claude
#
# Usage (download once, run from project root, no -Target):
#   iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.ps1 -OutFile install.ps1
#   .\install.ps1 [-Target <path>] [-Adapter <claude|copilot-cli|agents-md|generic>] [-Ref <branch-or-tag>] [-RepoUrl <url-or-local-path>] [-UpdateOnly]
#
# Usage (remote one-liner — works once the framework repo is public; env vars carry arguments since `iex` can't accept params):
#   $env:GINEE_ADAPTER='claude'; iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.ps1 | iex
#   $env:GINEE_ADAPTER='claude'; $env:GINEE_REF='v0.1.0'; iwr -useb <url>/install.ps1 | iex

[CmdletBinding()]
param(
  # WHERE TO INSTALL INTO — adopter project root. Default = cwd.
  [string] $Target = (Get-Location).Path,
  [ValidateSet('claude','copilot-cli','agents-md','generic')]
  [string] $Adapter,
  [string] $Ref = 'main',
  # WHERE TO FETCH THE FRAMEWORK FROM — git URL or local checkout path.
  [string] $RepoUrl = 'https://github.com/kostiantyn-matsebora/ginee',
  [switch] $UpdateOnly
)

# Fallback to env vars when invoked via `iwr | iex` (which cannot pass parameters)
if (-not $Adapter -and $env:GINEE_ADAPTER) { $Adapter = $env:GINEE_ADAPTER }
if ($env:GINEE_REF)    { $Ref = $env:GINEE_REF }
if ($env:GINEE_TARGET) { $Target = $env:GINEE_TARGET }
if ($env:GINEE_REPO)   { $RepoUrl = $env:GINEE_REPO }
if ($env:GINEE_UPDATE_ONLY -eq '1' -or $env:GINEE_UPDATE_ONLY -eq 'true') { $UpdateOnly = $true }

$ErrorActionPreference = 'Stop'
$frameworkDir = Join-Path $Target '.agents\ginee'

Write-Host "ginee installer" -ForegroundColor Cyan
Write-Host "  Install into (-Target)  : $Target   (defaults to cwd)"
Write-Host "  Fetch from   (-RepoUrl) : $RepoUrl"
Write-Host "  Framework dir           : $frameworkDir"
Write-Host "  Adapter                 : $(if ($Adapter) { $Adapter } else { 'detect interactively' })"
Write-Host "  Ref                     : $Ref"
Write-Host ""
Write-Host "This installer must be run from the root of the project / git repo you want to set up." -ForegroundColor Yellow
Write-Host "It writes the framework into .\.agents\ginee\ and adapter files into your project tree."
Write-Host ""

# --- 0. Migrate legacy install path (pre-rebrand: .agents/engineering-team/) ---

$legacyDir = Join-Path $Target '.agents\engineering-team'
if ((Test-Path $legacyDir) -and -not (Test-Path $frameworkDir)) {
  Write-Host "Migrating .agents\engineering-team\ -> .agents\ginee\ (post-2026-05-18 rebrand)" -ForegroundColor Cyan
  Rename-Item $legacyDir $frameworkDir
  Write-Host "  Legacy install preserved in place; local/ contents carried over intact." -ForegroundColor DarkGray
}

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
    # Fetch fresh upstream content into a temp clone, then copy the three upstream-owned dirs into place
    $tmpClone = Join-Path ([System.IO.Path]::GetTempPath()) "et-clone-$([guid]::NewGuid().Guid)"
    git clone --depth 1 --branch $Ref $RepoUrl $tmpClone
    foreach ($d in 'core','adapters','extras') {
      $src = Join-Path $tmpClone $d
      if (Test-Path $src) { Copy-Item -Recurse $src (Join-Path $frameworkDir $d) }
    }
    Remove-Item -Recurse -Force $tmpClone
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

# --- Prune framework-dev cruft from the adopter's framework dir -------------
# Adopters need: core/ (incl. MIGRATIONS), adapters/_shared + chosen adapter,
# extras/, local/ skeleton. Everything else is framework-dev only.
$pruneRoots = @(
  '.github',         # release CI for the framework's own repo
  '.claude',         # framework's own working state
  '.gitignore',
  '.dockerignore',
  'install.ps1',     # installer; not invoked from inside .agents/
  'install.sh',
  'PLAN.md',         # framework design doc
  'CLAUDE.md',       # framework's own project instructions (would shadow adopter's notion)
  'README.md'        # install/marketing; references framework's GitHub
)
foreach ($p in $pruneRoots) {
  $path = Join-Path $frameworkDir $p
  if (Test-Path $path) { Remove-Item -Recurse -Force $path }
}
# Drop unchosen adapter subdirs (keep _shared + the selected one)
$adaptersRoot = Join-Path $frameworkDir 'adapters'
$keepAdapters = @('_shared', $Adapter)
Get-ChildItem -Directory $adaptersRoot | Where-Object { $keepAdapters -notcontains $_.Name } |
  ForEach-Object { Remove-Item -Recurse -Force $_.FullName }
Write-Host "Pruned framework-dev files (release CI, other adapters, design docs)" -ForegroundColor DarkGray

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
    $skillsDir = Join-Path $Target '.claude\skills'
    New-Item -ItemType Directory -Force $skillsDir | Out-Null
    Get-ChildItem $skillsDir -Filter 'ginee-*' -Directory -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
    Copy-Item -Recurse (Join-Path $frameworkDir 'core\skills\ginee-*') $skillsDir
    Write-Host "Copied 10 ginee-* skills to .claude/skills/" -ForegroundColor Green

    # Append CLAUDE-pointer.md to project's CLAUDE.md (idempotent via sentinel header)
    $claudeMd = Join-Path $Target 'CLAUDE.md'
    $pointerSrc = Join-Path $frameworkDir 'adapters\claude\CLAUDE-pointer.md'
    $sentinel = '## Engineering team framework'
    if (Test-Path $claudeMd) {
      $existing = Get-Content $claudeMd -Raw
      if ($existing -like "*$sentinel*") {
        Write-Host "CLAUDE.md already contains the ginee pointer — skipped append" -ForegroundColor Yellow
      } else {
        Add-Content -Path $claudeMd -Value ""
        Add-Content -Path $claudeMd -Value (Get-Content $pointerSrc -Raw)
        Write-Host "Appended ginee pointer block to CLAUDE.md" -ForegroundColor Green
      }
    } else {
      Copy-Item $pointerSrc $claudeMd
      Write-Host "Created CLAUDE.md from pointer template" -ForegroundColor Green
    }
  }
  'copilot-cli' {
    $agentsDir = Join-Path $Target '.github\agents'
    New-Item -ItemType Directory -Force $agentsDir | Out-Null
    Get-ChildItem (Join-Path $frameworkDir 'adapters\_shared\agents\*.md') | ForEach-Object {
      Copy-Item $_.FullName (Join-Path $agentsDir "$($_.BaseName).agent.md")
    }
    Write-Host "Copied 7 cardinal subagents to .github/agents/*.agent.md" -ForegroundColor Green
    $skillsDir = Join-Path $Target '.agents\skills'
    New-Item -ItemType Directory -Force $skillsDir | Out-Null
    Get-ChildItem $skillsDir -Filter 'ginee-*' -Directory -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
    Copy-Item -Recurse (Join-Path $frameworkDir 'core\skills\ginee-*') $skillsDir
    Write-Host "Copied 10 ginee-* skills to .agents/skills/ (cross-tool path per AgentSkills convention)" -ForegroundColor Green
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
Write-Host "  2. Type:  Run initial discovery"
Write-Host "     (auto-activates the ginee-discovery skill in Claude Code / Copilot CLI."
Write-Host "      Tier-3 fallback: 'act as project-manager and run initial discovery'.)"
Write-Host "  3. Review the recommended specialists; user-approve any extras to enable."
Write-Host ""
Write-Host "Documentation:" -ForegroundColor Cyan
Write-Host "  README:      $(Join-Path $frameworkDir 'README.md')"
Write-Host "  Process:     $(Join-Path $frameworkDir 'core\process.md')"
Write-Host "  Adapter:     $installNote"
