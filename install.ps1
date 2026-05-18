# ginee installer (PowerShell)
#
# Run anonymously — no GitHub auth needed; the framework is public OSS.
#
# Usage (one-liner — recommended; env vars carry arguments since `iex` can't accept params):
#   $env:GINEE_ADAPTER='claude'; iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.ps1 | iex
#   $env:GINEE_ADAPTER='claude'; $env:GINEE_REF='v0.1.0'; iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.ps1 | iex
#
# Usage (download once, then run with named parameters):
#   iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.ps1 -OutFile install.ps1
#   .\install.ps1 [-Target <path>] [-Adapter <claude|copilot-cli|agents-md|generic>] [-Ref <ref>] [-UpdateOnly]
#
# Parameters:
#   -Target    Project root to install into. Default = current working directory.
#   -Adapter   claude | copilot-cli | agents-md | generic. Prompts if omitted.
#   -Ref       Release tag (vX.Y.Z), "latest" (default), or any git branch/SHA. Tagged refs and
#              "latest" download the released zip over HTTPS (no git needed). Branch/SHA refs
#              fall back to git clone.
#   -RepoUrl   Override fetch URL — only needed for forks or testing a local checkout. Forks
#              always use the git-clone path regardless of -Ref.
#              Default = https://github.com/kostiantyn-matsebora/ginee.
#   -UpdateOnly  Refresh core/+adapters/+extras/ in place; preserve local/.
#
# What gets created inside -Target:
#   .\.agents\ginee\              — the framework (core, adapters, extras, local)
#   .\.claude\agents\             — Claude adapter (when -Adapter claude)
#   .\.claude\skills\             — Claude adapter skills
#   .\.github\agents\             — Copilot CLI adapter (when -Adapter copilot-cli)
#   .\.agents\skills\             — Copilot CLI adapter skills (cross-tool AgentSkills path)
#   .\AGENTS.md                   — AGENTS.md adapter (when -Adapter agents-md)
#   .\CLAUDE.md                   — pointer block appended (idempotent via sentinel)

[CmdletBinding()]
param(
  # WHERE TO INSTALL INTO — adopter project root. Default = cwd.
  [string] $Target = (Get-Location).Path,
  # Note: validated manually below (not via [ValidateSet]) so that `iwr | iex`
  # doesn't fail with "The attribute cannot be added because variable Adapter
  # with value would no longer be valid" when an empty $Adapter pre-exists in
  # the caller's scope.
  [string] $Adapter,
  [string] $Ref = 'latest',
  # WHERE TO FETCH THE FRAMEWORK FROM. Override for forks / local-checkout testing.
  [string] $RepoUrl = 'https://github.com/kostiantyn-matsebora/ginee',
  [switch] $UpdateOnly
)

# Fallback to env vars when invoked via `iwr | iex` (which cannot pass parameters)
if (-not $Adapter -and $env:GINEE_ADAPTER) { $Adapter = $env:GINEE_ADAPTER }
if ($env:GINEE_REF)    { $Ref = $env:GINEE_REF }
if ($env:GINEE_TARGET) { $Target = $env:GINEE_TARGET }
if ($env:GINEE_REPO)   { $RepoUrl = $env:GINEE_REPO }
if ($env:GINEE_UPDATE_ONLY -eq '1' -or $env:GINEE_UPDATE_ONLY -eq 'true') { $UpdateOnly = $true }

# --- Defeat iex caller-scope leak ------------------------------------------
# When this script is piped through Invoke-Expression, param() runs in the caller's
# scope. If $Ref / $Target / $RepoUrl already exist in that scope (very common —
# $Ref is a stock identifier), the param defaults DON'T fire — PowerShell coerces
# the pre-existing value via [string], turning $null into ''. Then `git clone
# --branch ''` triggers Windows ERROR_INVALID_NAME ("The filename, directory name,
# or volume label syntax is incorrect.") with no PS wrapping — hard to diagnose.
# Re-apply defaults if scope-leaked vars came in empty/whitespace.
if ([string]::IsNullOrWhiteSpace($Ref))     { $Ref = 'latest' }
if ([string]::IsNullOrWhiteSpace($RepoUrl)) { $RepoUrl = 'https://github.com/kostiantyn-matsebora/ginee' }
if ([string]::IsNullOrWhiteSpace($Target))  {
  $fsLoc = Get-Location -PSProvider FileSystem -ErrorAction SilentlyContinue
  $Target = if ($fsLoc) { $fsLoc.Path } else { [Environment]::CurrentDirectory }
}
# Strip PS-provider prefix (e.g., Microsoft.PowerShell.Core\FileSystem::C:\…)
# so git.exe + file ops get a plain Win32 path.
try { $Target = (Resolve-Path -LiteralPath $Target -ErrorAction Stop).ProviderPath } catch {
  # If $Target doesn't exist yet (rare; e.g., --target points at a not-yet-created dir),
  # fall back to making it absolute against cwd via Path API.
  $Target = [System.IO.Path]::GetFullPath($Target)
}

$validAdapters = @('claude','copilot-cli','agents-md','generic')
if ($Adapter -and $Adapter -notin $validAdapters) {
  Write-Error "Invalid -Adapter '$Adapter'. Must be one of: $($validAdapters -join ', ')."
  exit 1
}

$DefaultRepoUrl = 'https://github.com/kostiantyn-matsebora/ginee'

# --- Diagnostics: step banners + on-error dump -----------------------------

$script:lastStep = ''
function Step([string]$msg) {
  Write-Host ">> $msg" -ForegroundColor DarkCyan
  $script:lastStep = $msg
}
trap {
  Write-Host ''
  Write-Host "ginee install FAILED at step: $(if ($script:lastStep) { $script:lastStep } else { '<before first step>' })" -ForegroundColor Red
  Write-Host "  Ref      : $Ref"
  Write-Host "  Target   : $Target"
  Write-Host "  RepoUrl  : $RepoUrl"
  Write-Host "  Adapter  : $Adapter"
  Write-Host "  PS       : $($PSVersionTable.PSVersion)"
  Write-Host "  Cwd      : $($PWD.Path) (provider: $($PWD.Provider.Name))"
  Write-Host "  Error    : $($_.Exception.Message)"
  break
}

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
  Step "Migrating .agents\engineering-team\ -> .agents\ginee\ (post-2026-05-18 rebrand)"
  Rename-Item $legacyDir $frameworkDir
  Write-Host "  Legacy install preserved in place; local/ contents carried over intact." -ForegroundColor DarkGray
}

# --- Fetch helpers ---------------------------------------------------------
# Two paths:
#   1. Zip — for vX.Y.Z tags + "latest" against canonical upstream. No git dependency.
#   2. Git clone — for branches, SHAs, and forks (-RepoUrl override).

function Test-TagRef([string]$r) {
  return $r -match '^v\d+\.\d+\.\d+([-+.][A-Za-z0-9.-]+)?$'
}

function Resolve-LatestTag {
  Step "Resolving 'latest' tag via $RepoUrl/releases/latest"
  # /releases/latest HTTP 302s to /releases/tag/vX.Y.Z. Use UseBasicParsing so this
  # works on PS 5.1 without IE.
  $resp = Invoke-WebRequest -UseBasicParsing -Uri "$RepoUrl/releases/latest" -MaximumRedirection 10
  $finalUri = $resp.BaseResponse.ResponseUri
  if (-not $finalUri) {
    $finalUri = $resp.BaseResponse.RequestMessage.RequestUri
  }
  $tag = ([string]$finalUri).TrimEnd('/').Split('/')[-1]
  if (-not (Test-TagRef $tag)) {
    throw "Could not parse 'latest' redirect (got '$tag' from '$finalUri')"
  }
  return $tag
}

function Save-FrameworkZip([string]$tag, [string]$dest) {
  $zip = "ginee-$tag.zip"
  $zipUrl = "$RepoUrl/releases/download/$tag/$zip"
  $checksumsUrl = "$RepoUrl/releases/download/$tag/SHA256SUMS.txt"
  $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "ginee-$([guid]::NewGuid().Guid)"
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null

  Step "Downloading $zip"
  Invoke-WebRequest -UseBasicParsing -Uri $zipUrl -OutFile (Join-Path $tmp $zip)

  Step "Downloading SHA256SUMS.txt"
  Invoke-WebRequest -UseBasicParsing -Uri $checksumsUrl -OutFile (Join-Path $tmp 'SHA256SUMS.txt')

  Step "Verifying SHA256 of $zip"
  $expected = (Get-Content (Join-Path $tmp 'SHA256SUMS.txt') | Where-Object { $_ -match "\s$([regex]::Escape($zip))\s*$" } | Select-Object -First 1)
  if (-not $expected) {
    throw "SHA256SUMS.txt does not contain an entry for $zip"
  }
  $expectedHash = ($expected -split '\s+')[0].ToUpper()
  $actualHash = (Get-FileHash -Algorithm SHA256 -Path (Join-Path $tmp $zip)).Hash.ToUpper()
  if ($expectedHash -ne $actualHash) {
    throw "SHA256 mismatch for $zip (expected $expectedHash, got $actualHash)"
  }

  Step "Extracting $zip"
  Expand-Archive -Path (Join-Path $tmp $zip) -DestinationPath $tmp -Force

  Step "Installing framework -> $dest"
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
  if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
  Move-Item -Path (Join-Path $tmp "ginee-$tag") -Destination $dest
  Remove-Item -Recurse -Force $tmp
}

function Save-FrameworkClone([string]$ref, [string]$dest) {
  if ($ref -notmatch '^[A-Za-z0-9._/-]+$') {
    throw "Invalid -Ref '$ref' (alphanum, dot, slash, dash, underscore only)"
  }
  Step "Cloning $RepoUrl @ $ref -> $dest (git fallback)"
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
  if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
  $gitArgs = @('clone','--depth','1','--branch',$ref,$RepoUrl,$dest)
  & git @gitArgs
  if ($LASTEXITCODE -ne 0) { throw "git clone failed (exit $LASTEXITCODE)" }
  Remove-Item -Recurse -Force (Join-Path $dest '.git') -ErrorAction SilentlyContinue
}

function Save-Framework([string]$ref, [string]$dest) {
  # Zip path only against canonical upstream — forks may not publish releases under same naming
  if ($RepoUrl -eq $DefaultRepoUrl) {
    if ($ref -eq 'latest') { $ref = Resolve-LatestTag }
    if (Test-TagRef $ref) {
      Save-FrameworkZip $ref $dest
      return
    }
  }
  Save-FrameworkClone $ref $dest
}

# --- 1. Fetch framework ----------------------------------------------------

if (Test-Path $frameworkDir) {
  if ($UpdateOnly) {
    Step "Updating existing framework at $frameworkDir (preserving local/)"
    # Preserve local/
    $localBackup = Join-Path ([System.IO.Path]::GetTempPath()) "et-local-$([guid]::NewGuid().Guid)"
    if (Test-Path (Join-Path $frameworkDir 'local')) {
      Copy-Item -Recurse (Join-Path $frameworkDir 'local') $localBackup
    }
    Remove-Item -Recurse -Force (Join-Path $frameworkDir 'core'),
                                (Join-Path $frameworkDir 'adapters'),
                                (Join-Path $frameworkDir 'extras') -ErrorAction SilentlyContinue
    # Fetch fresh upstream content into a staging dir, then copy the three upstream-owned dirs
    $staging = Join-Path ([System.IO.Path]::GetTempPath()) "ginee-staging-$([guid]::NewGuid().Guid)"
    Save-Framework $Ref $staging
    foreach ($d in 'core','adapters','extras') {
      $src = Join-Path $staging $d
      if (Test-Path $src) { Copy-Item -Recurse $src (Join-Path $frameworkDir $d) }
    }
    Remove-Item -Recurse -Force $staging
  } else {
    Write-Error "Framework already installed at $frameworkDir. Use -UpdateOnly to refresh core/+adapters/+extras/ (local/ is preserved)."
  }
} else {
  Save-Framework $Ref $frameworkDir
}

# --- 2. Restore local/ on update -------------------------------------------
# local/ was preserved in place (step 1 only removes core/+adapters/+extras/), so
# in the happy path the backup is redundant — just discard it. The defensive
# branch handles a corrupted state where local/ disappeared mid-update.
# DON'T Copy-Item the backup into an existing local/ — PowerShell nests it as
# local/et-local-<guid>/ instead of merging. See #25.

if ($UpdateOnly -and (Test-Path $localBackup)) {
  $localTarget = Join-Path $frameworkDir 'local'
  if (Test-Path $localTarget) {
    Step "local/ preserved in place; discarding backup"
    Remove-Item -Recurse -Force $localBackup
  } else {
    Step "Restoring local/ from backup (local/ was nuked during update)"
    Move-Item $localBackup $localTarget
  }
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
# Needed for backward compat with releases packaged before release.yml was updated
# to pre-prune. On future releases the zip ships clean and these rms become no-ops.
# Adopters need: core/ (incl. MIGRATIONS), adapters/_shared + chosen adapter,
# extras/, local/ skeleton, LICENSE. Everything else is framework-dev only.
Step "Pruning framework-dev cruft"
$pruneRoots = @(
  '.github',         # release CI + issue templates for the framework's own repo
  '.claude',         # framework's own working state
  '.gitignore',
  '.dockerignore',
  'install.ps1',     # installer; not invoked from inside .agents/
  'install.sh',
  'PLAN.md',         # framework design doc
  'CLAUDE.md',       # framework's own project instructions (would shadow adopter's notion)
  'README.md',       # install/marketing; references framework's GitHub
  'SECURITY.md',     # how to report security issues to the framework maintainers
  'docs'             # Jekyll site source (lives at kostiantyn-matsebora.github.io/ginee)
)
foreach ($p in $pruneRoots) {
  $path = Join-Path $frameworkDir $p
  if (Test-Path $path) { Remove-Item -Recurse -Force $path }
}
# Drop unchosen adapter subdirs (keep _shared + the selected one)
$adaptersRoot = Join-Path $frameworkDir 'adapters'
if (Test-Path $adaptersRoot) {
  Get-ChildItem $adaptersRoot -Directory | ForEach-Object {
    if ($_.Name -ne '_shared' -and $_.Name -ne $Adapter) {
      Remove-Item -Recurse -Force $_.FullName
    }
  }
}

Write-Host ""
Write-Host "Adapter '$Adapter' will be installed per:" -ForegroundColor Cyan
Write-Host "  $installNote"
Write-Host ""

switch ($Adapter) {
  'claude' {
    Step "Installing claude adapter to .claude\"
    $agentsDir = Join-Path $Target '.claude\agents'
    New-Item -ItemType Directory -Force $agentsDir | Out-Null
    # Drop legacy project-manager.md pointer from pre-rename installs (renamed to team-lead.md on 2026-05-18)
    Remove-Item (Join-Path $agentsDir 'project-manager.md') -Force -ErrorAction SilentlyContinue
    Copy-Item (Join-Path $frameworkDir 'adapters\_shared\agents\*.md') $agentsDir
    Write-Host "Copied 7 cardinal subagents to .claude/agents/" -ForegroundColor Green
    $skillsDir = Join-Path $Target '.claude\skills'
    New-Item -ItemType Directory -Force $skillsDir | Out-Null
    Get-ChildItem $skillsDir -Filter 'ginee-*' -Directory -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
    Copy-Item -Recurse (Join-Path $frameworkDir 'core\skills\ginee-*') $skillsDir
    Write-Host "Copied 10 ginee-* skills to .claude/skills/" -ForegroundColor Green

    # Sync CLAUDE-pointer.md block into project's CLAUDE.md.
    # - Existing block (sentinel present): refresh body in place — pointer blocks
    #   evolve across releases (D11 rename being the most extreme case).
    # - No block yet: append.
    # - No CLAUDE.md: create.
    $claudeMd = Join-Path $Target 'CLAUDE.md'
    $pointerSrc = Join-Path $frameworkDir 'adapters\claude\CLAUDE-pointer.md'
    $sentinel = '## Engineering team framework'
    $sentinelEscaped = [regex]::Escape($sentinel)
    $blockPattern = "(?ms)^$sentinelEscaped.*?^---\s*$"
    $tmplContent = Get-Content $pointerSrc -Raw
    $blockMatch = [regex]::Match($tmplContent, $blockPattern)
    $tmplBlock = if ($blockMatch.Success) { $blockMatch.Value } else { $tmplContent }
    if (Test-Path $claudeMd) {
      $existing = Get-Content $claudeMd -Raw
      if ([regex]::IsMatch($existing, $blockPattern)) {
        # Escape literal $ in the replacement so regex doesn't try to substitute $1/$& etc.
        $tmplBlockEscaped = $tmplBlock.Replace('$', '$$')
        $updated = [regex]::Replace($existing, $blockPattern, $tmplBlockEscaped, 1)
        if ($updated -ne $existing) {
          Set-Content -Path $claudeMd -Value $updated -NoNewline
          Write-Host "Refreshed ginee pointer block in CLAUDE.md" -ForegroundColor Green
        } else {
          Write-Host "CLAUDE.md pointer block already current — no change" -ForegroundColor Yellow
        }
      } else {
        Add-Content -Path $claudeMd -Value ""
        Add-Content -Path $claudeMd -Value $tmplBlock
        Write-Host "Appended ginee pointer block to CLAUDE.md" -ForegroundColor Green
      }
    } else {
      Set-Content -Path $claudeMd -Value $tmplBlock -NoNewline
      Write-Host "Created CLAUDE.md from pointer template" -ForegroundColor Green
    }
  }
  'copilot-cli' {
    Step "Installing copilot-cli adapter to .github\agents\ + .agents\skills\"
    $agentsDir = Join-Path $Target '.github\agents'
    New-Item -ItemType Directory -Force $agentsDir | Out-Null
    # Drop legacy project-manager.agent.md pointer from pre-rename installs (renamed to team-lead on 2026-05-18)
    Remove-Item (Join-Path $agentsDir 'project-manager.agent.md') -Force -ErrorAction SilentlyContinue
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
    Step "Installing AGENTS.md to project root"
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
Write-Host "      Tier-3 fallback: 'act as team-lead and run initial discovery'.)"
Write-Host "  3. Review the recommended specialists; user-approve any extras to enable."
Write-Host ""
Write-Host "Documentation:" -ForegroundColor Cyan
Write-Host "  Online:   https://kostiantyn-matsebora.github.io/ginee"
Write-Host "  Process:  $(Join-Path $frameworkDir 'core\process.md')"
Write-Host "  Adapter:  $installNote"
