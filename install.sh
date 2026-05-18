#!/usr/bin/env bash
# ginee installer (POSIX shell)
#
# Run anonymously — no GitHub auth needed; the framework is public OSS.
#
# Usage (one-liner — recommended):
#   curl -fsSL https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh | bash -s -- --adapter claude
#
# Usage (download once, then run with named flags):
#   curl -fsSLO https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh
#   chmod +x install.sh
#   ./install.sh [--target <path>] [--adapter <claude|copilot-cli|agents-md|generic>] [--ref <ref>] [--update-only]
#
# Parameters:
#   --target       Project root to install into. Default = $PWD.
#   --adapter      claude | copilot-cli | agents-md | generic. Prompts if omitted.
#   --ref          Release tag (vX.Y.Z), "latest" (default), or any git branch/SHA. Tagged refs and
#                  "latest" download the released tarball over HTTPS (no git needed). Branch/SHA refs
#                  fall back to git clone.
#   --repo         Override fetch URL — only needed for forks or testing a local checkout. Forks
#                  always use the git-clone path regardless of --ref.
#                  Default = https://github.com/kostiantyn-matsebora/ginee.
#   --update-only  Refresh core/+adapters/+extras/ in place; preserve local/.
#
# What gets created inside --target:
#   ./.agents/ginee/              — the framework (core/, adapters/, extras/, local/)
#   ./.claude/agents/             — Claude adapter (when --adapter claude)
#   ./.claude/skills/             — Claude adapter skills
#   ./.github/agents/             — Copilot CLI adapter (when --adapter copilot-cli)
#   ./.agents/skills/             — Copilot CLI adapter skills (cross-tool AgentSkills path)
#   ./AGENTS.md                   — AGENTS.md adapter (when --adapter agents-md)
#   ./CLAUDE.md                   — pointer block appended (idempotent via sentinel)

set -euo pipefail

# --- Diagnostics: step banners + on-error dump ----------------------------

LAST_STEP=""
# Step messages go to stderr so they don't pollute $(...) capture of function return values
step() { echo ">> $1" >&2; LAST_STEP="$1"; }
on_error() {
  local code=$?
  echo "" >&2
  echo "ginee install FAILED at step: ${LAST_STEP:-<before first step>} (exit $code)" >&2
  echo "  Ref     : ${REF:-<unset>}" >&2
  echo "  Target  : ${TARGET:-<unset>}" >&2
  echo "  RepoUrl : ${REPO_URL:-<unset>}" >&2
  echo "  Adapter : ${ADAPTER:-<unset>}" >&2
  echo "  Shell   : ${BASH_VERSION:-<not bash>}" >&2
  exit "$code"
}
trap on_error ERR

# --- Defaults + arg parsing -----------------------------------------------

DEFAULT_REPO_URL="https://github.com/kostiantyn-matsebora/ginee"

TARGET="$(pwd)"
ADAPTER=""
REF="latest"
REPO_URL="$DEFAULT_REPO_URL"
UPDATE_ONLY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --adapter) ADAPTER="$2"; shift 2 ;;
    --ref) REF="$2"; shift 2 ;;
    --repo) REPO_URL="$2"; shift 2 ;;
    --update-only) UPDATE_ONLY=1; shift ;;
    -h|--help)
      grep -E '^# ' "$0" | sed 's/^# //'
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# Defensive: empty REF (e.g., --ref "") falls back to latest
[ -n "$REF" ] || REF="latest"

FRAMEWORK_DIR="$TARGET/.agents/ginee"

echo "ginee installer"
echo "  Install into (--target) : $TARGET   (defaults to \$PWD)"
echo "  Fetch from   (--repo)   : $REPO_URL"
echo "  Framework dir           : $FRAMEWORK_DIR"
echo "  Adapter                 : ${ADAPTER:-detect interactively}"
echo "  Ref                     : $REF"
echo ""
echo "This installer must be run from the root of the project / git repo you want to set up."
echo "It writes the framework into ./.agents/ginee/ and adapter files into your project tree."
echo ""

# --- 0. Migrate legacy install path (pre-rebrand: .agents/engineering-team/) ---

LEGACY_DIR="$TARGET/.agents/engineering-team"
if [ -d "$LEGACY_DIR" ] && [ ! -d "$FRAMEWORK_DIR" ]; then
  step "Migrating .agents/engineering-team/ -> .agents/ginee/ (post-2026-05-18 rebrand)"
  mv "$LEGACY_DIR" "$FRAMEWORK_DIR"
  echo "  Legacy install preserved in place; local/ contents carried over intact."
fi

# --- Fetch helpers --------------------------------------------------------
# Two paths:
#   1. Tarball — for vX.Y.Z tags + "latest" against canonical upstream. No git dependency.
#   2. Git clone — for branches, SHAs, and forks (--repo override).

is_tag_ref() {
  echo "$1" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+([-+.][A-Za-z0-9.-]+)?$'
}

resolve_latest_tag() {
  step "Resolving 'latest' tag via $REPO_URL/releases/latest"
  local effective
  effective="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "$REPO_URL/releases/latest")"
  # Effective URL: https://github.com/<owner>/<repo>/releases/tag/vX.Y.Z
  local tag="${effective##*/}"
  if ! is_tag_ref "$tag"; then
    echo "ERROR: could not parse 'latest' redirect (got '$tag' from '$effective')" >&2
    exit 1
  fi
  echo "$tag"
}

fetch_tarball_to() {
  local tag="$1"
  local dest="$2"
  local tarball="ginee-${tag}.tar.gz"
  local tarball_url="$REPO_URL/releases/download/${tag}/${tarball}"
  local checksums_url="$REPO_URL/releases/download/${tag}/SHA256SUMS.txt"
  local tmp
  tmp="$(mktemp -d)"

  step "Downloading $tarball"
  curl -fsSL -o "$tmp/$tarball" "$tarball_url"

  step "Downloading SHA256SUMS.txt"
  curl -fsSL -o "$tmp/SHA256SUMS.txt" "$checksums_url"

  step "Verifying SHA256 of $tarball"
  (cd "$tmp" && sha256sum --ignore-missing -c SHA256SUMS.txt) >/dev/null

  step "Extracting $tarball"
  tar -xzf "$tmp/$tarball" -C "$tmp"

  step "Installing framework -> $dest"
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  mv "$tmp/ginee-${tag}" "$dest"
  rm -rf "$tmp"
}

fetch_git_clone_to() {
  local ref="$1"
  local dest="$2"
  if ! echo "$ref" | grep -qE '^[A-Za-z0-9._/-]+$'; then
    echo "ERROR: invalid --ref '$ref' (alphanum, dot, slash, dash, underscore only)" >&2
    exit 1
  fi
  step "Cloning $REPO_URL @ $ref -> $dest (git fallback)"
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  git clone --depth 1 --branch "$ref" "$REPO_URL" "$dest"
  rm -rf "$dest/.git"
}

fetch_to_dir() {
  local ref="$1"
  local dest="$2"
  # Tarball path only against canonical upstream — forks may not publish releases under same naming
  if [ "$REPO_URL" = "$DEFAULT_REPO_URL" ]; then
    if [ "$ref" = "latest" ]; then
      ref="$(resolve_latest_tag)"
    fi
    if is_tag_ref "$ref"; then
      fetch_tarball_to "$ref" "$dest"
      return
    fi
  fi
  # Fall back to git clone for branches, SHAs, and forks
  fetch_git_clone_to "$ref" "$dest"
}

# --- 1. Fetch framework ----------------------------------------------------

if [ -d "$FRAMEWORK_DIR" ]; then
  if [ "$UPDATE_ONLY" -eq 1 ]; then
    step "Updating existing framework (preserving local/)"
    LOCAL_BACKUP="$(mktemp -d)/local"
    if [ -d "$FRAMEWORK_DIR/local" ]; then
      cp -r "$FRAMEWORK_DIR/local" "$LOCAL_BACKUP"
    fi
    rm -rf "$FRAMEWORK_DIR/core" "$FRAMEWORK_DIR/adapters" "$FRAMEWORK_DIR/extras"
    # Fetch fresh upstream content into a staging dir, then copy the three upstream-owned dirs
    STAGING="$(mktemp -d)/ginee-staging"
    fetch_to_dir "$REF" "$STAGING"
    for d in core adapters extras; do
      if [ -d "$STAGING/$d" ]; then
        cp -r "$STAGING/$d" "$FRAMEWORK_DIR/$d"
      fi
    done
    rm -rf "$(dirname "$STAGING")"
  else
    echo "Framework already installed at $FRAMEWORK_DIR. Use --update-only to refresh core/+adapters/+extras/ (local/ preserved)." >&2
    exit 1
  fi
else
  fetch_to_dir "$REF" "$FRAMEWORK_DIR"
fi

# --- 2. Restore local/ on update -------------------------------------------
# local/ was preserved in place (step 1 only removes core/+adapters/+extras/), so
# in the happy path the backup is redundant — just discard it. The defensive
# branch handles a corrupted state where local/ disappeared mid-update.
# DON'T cp -r the backup into an existing local/ — coreutils nests it as
# local/local/ instead of merging. See #25.

if [ "$UPDATE_ONLY" -eq 1 ] && [ -d "${LOCAL_BACKUP:-}" ]; then
  if [ -d "$FRAMEWORK_DIR/local" ]; then
    step "local/ preserved in place; discarding backup"
    rm -rf "$(dirname "$LOCAL_BACKUP")"
  else
    step "Restoring local/ from backup (local/ was nuked during update)"
    mv "$LOCAL_BACKUP" "$FRAMEWORK_DIR/local"
    rm -rf "$(dirname "$LOCAL_BACKUP")"
  fi
fi

# --- 3. Adapter prompt + install -------------------------------------------

if [ -z "$ADAPTER" ]; then
  if [ ! -t 0 ] && [ ! -r /dev/tty ]; then
    echo "Error: --adapter not specified and no interactive terminal available." >&2
    echo "When piping from curl, pass it explicitly, e.g.:" >&2
    echo "  curl -fsSL <url>/install.sh | bash -s -- --adapter claude" >&2
    exit 1
  fi
  echo ""
  echo "Pick the adapter that matches your LLM client:"
  echo "  [1] claude       — Claude Code (tier-1)"
  echo "  [2] copilot-cli  — GitHub Copilot CLI (tier-1)"
  echo "  [3] agents-md    — Codex / Cursor / Windsurf / Amp / Devin / Factory / Jules / Copilot IDE (tier-2)"
  echo "  [4] generic      — INSTRUCTIONS.md fallback (tier-3)"
  if [ -t 0 ]; then
    read -rp "Pick 1-4: " sel
  else
    read -rp "Pick 1-4: " sel < /dev/tty
  fi
  case "$sel" in
    1) ADAPTER="claude" ;;
    2) ADAPTER="copilot-cli" ;;
    3) ADAPTER="agents-md" ;;
    4) ADAPTER="generic" ;;
    *) echo "Invalid selection: $sel" >&2; exit 1 ;;
  esac
fi

ADAPTER_DIR="$FRAMEWORK_DIR/adapters/$ADAPTER"
INSTALL_NOTE="$ADAPTER_DIR/install.md"

# --- Prune framework-dev cruft from the adopter's framework dir ------------
# Needed for backward compat with releases packaged before release.yml was updated
# to pre-prune. On future releases the tarball ships clean and these rms become no-ops.
# Adopters need: core/ (incl. MIGRATIONS), adapters/_shared + chosen adapter,
# extras/, local/ skeleton, LICENSE. Everything else is framework-dev only:
#  - docs/        Jekyll site source (lives at kostiantyn-matsebora.github.io/ginee)
#  - .github/     CI workflows + issue templates for the framework's own repo
#  - .claude/    framework's dogfooded local config
#  - PLAN.md / CLAUDE.md / README.md / SECURITY.md   framework-dev orientation
#  - install.sh / install.ps1   already-executed installer scripts
step "Pruning framework-dev cruft"
for p in .github .claude .gitignore .dockerignore install.ps1 install.sh PLAN.md CLAUDE.md README.md SECURITY.md docs; do
  rm -rf "$FRAMEWORK_DIR/$p"
done
# Drop unchosen adapter subdirs (keep _shared + the selected one)
for d in "$FRAMEWORK_DIR"/adapters/*/; do
  name="$(basename "$d")"
  if [ "$name" != "_shared" ] && [ "$name" != "$ADAPTER" ]; then
    rm -rf "$d"
  fi
done

echo ""
echo "Adapter '$ADAPTER' will be installed per:"
echo "  $INSTALL_NOTE"
echo ""

case "$ADAPTER" in
  claude)
    step "Installing claude adapter to .claude/"
    mkdir -p "$TARGET/.claude/agents"
    # Drop legacy project-manager.md pointer from pre-rename installs (renamed to team-lead.md on 2026-05-18)
    rm -f "$TARGET/.claude/agents/project-manager.md"
    cp "$FRAMEWORK_DIR"/adapters/_shared/agents/*.md "$TARGET/.claude/agents/"
    echo "Copied 7 cardinal subagents to .claude/agents/"
    mkdir -p "$TARGET/.claude/skills"
    rm -rf "$TARGET"/.claude/skills/ginee-*
    cp -r "$FRAMEWORK_DIR"/core/skills/ginee-* "$TARGET/.claude/skills/"
    echo "Copied 10 ginee-* skills to .claude/skills/"

    # Sync CLAUDE-pointer.md block into project's CLAUDE.md.
    #  - Existing block (sentinel present): refresh body in place — pointer blocks
    #    evolve across releases (D11 rename being the most extreme case).
    #  - No block yet: append.
    #  - No CLAUDE.md: create.
    CLAUDE_MD="$TARGET/CLAUDE.md"
    POINTER_SRC="$FRAMEWORK_DIR/adapters/claude/CLAUDE-pointer.md"
    SENTINEL='## Engineering team framework'
    # Extract just the pointer block (sentinel line through next --- on its own line)
    TMPL_BLOCK_FILE="$(mktemp)"
    sed -n "/^${SENTINEL}\$/,/^---\$/p" "$POINTER_SRC" > "$TMPL_BLOCK_FILE"
    if [ ! -s "$TMPL_BLOCK_FILE" ]; then
      cp "$POINTER_SRC" "$TMPL_BLOCK_FILE"  # Fallback for malformed templates
    fi
    if [ -f "$CLAUDE_MD" ]; then
      if grep -qxF "$SENTINEL" "$CLAUDE_MD"; then
        # Refresh: replace existing block (sentinel line through next ---) with template block
        awk -v block_file="$TMPL_BLOCK_FILE" -v sentinel="$SENTINEL" '
          BEGIN {
            while ((getline line < block_file) > 0) {
              block = block (NR_block++ ? "\n" : "") line
            }
            close(block_file)
          }
          $0 == sentinel { in_block=1; print block; next }
          in_block && /^---[[:space:]]*$/ { in_block=0; next }
          !in_block { print }
        ' "$CLAUDE_MD" > "$CLAUDE_MD.new"
        if cmp -s "$CLAUDE_MD" "$CLAUDE_MD.new"; then
          rm "$CLAUDE_MD.new"
          echo "CLAUDE.md pointer block already current — no change"
        else
          mv "$CLAUDE_MD.new" "$CLAUDE_MD"
          echo "Refreshed ginee pointer block in CLAUDE.md"
        fi
      else
        printf '\n' >> "$CLAUDE_MD"
        cat "$TMPL_BLOCK_FILE" >> "$CLAUDE_MD"
        echo "Appended ginee pointer block to CLAUDE.md"
      fi
    else
      cp "$TMPL_BLOCK_FILE" "$CLAUDE_MD"
      echo "Created CLAUDE.md from pointer template"
    fi
    rm -f "$TMPL_BLOCK_FILE"
    ;;
  copilot-cli)
    step "Installing copilot-cli adapter to .github/agents/ + .agents/skills/"
    mkdir -p "$TARGET/.github/agents"
    # Drop legacy project-manager.agent.md pointer from pre-rename installs (renamed to team-lead on 2026-05-18)
    rm -f "$TARGET/.github/agents/project-manager.agent.md"
    for f in "$FRAMEWORK_DIR"/adapters/_shared/agents/*.md; do
      name="$(basename "$f" .md)"
      cp "$f" "$TARGET/.github/agents/${name}.agent.md"
    done
    echo "Copied 7 cardinal subagents to .github/agents/*.agent.md"
    mkdir -p "$TARGET/.agents/skills"
    rm -rf "$TARGET"/.agents/skills/ginee-*
    cp -r "$FRAMEWORK_DIR"/core/skills/ginee-* "$TARGET/.agents/skills/"
    echo "Copied 10 ginee-* skills to .agents/skills/ (cross-tool path per AgentSkills convention)"
    ;;
  agents-md)
    step "Installing AGENTS.md to project root"
    cp "$FRAMEWORK_DIR/adapters/agents-md/AGENTS.md" "$TARGET/AGENTS.md"
    echo "Copied AGENTS.md to project root"
    echo "NEXT (Gemini users): cp AGENTS.md GEMINI.md"
    ;;
  generic)
    echo "Generic adapter is manual — point your LLM client at:"
    echo "  $FRAMEWORK_DIR/adapters/generic/INSTRUCTIONS.md"
    echo "See $INSTALL_NOTE for client-specific options."
    ;;
esac

# --- 4. Final guidance -----------------------------------------------------

# Detect lingering pre-D11 references in local/ (independent of step-0 dir rename —
# the dir may have been renamed in a previous run while local/ text stayed stale).
STALE_LOCAL_HITS=0
if [ -d "$FRAMEWORK_DIR/local" ] && grep -rqF 'engineering-team' "$FRAMEWORK_DIR/local" 2>/dev/null; then
  STALE_LOCAL_HITS=1
fi

echo ""
echo "Install complete."

if [ "$STALE_LOCAL_HITS" -eq 1 ]; then
  MIGRATE_SCRIPT="$FRAMEWORK_DIR/core/scripts/migrate-engineering-team-to-ginee.sh"
  echo ""
  echo "ACTION REQUIRED — legacy 'engineering-team' references detected under local/"
  echo "  Run the rename migration script to rewrite them:"
  echo ""
  echo "    $MIGRATE_SCRIPT --dry-run   # preview"
  echo "    $MIGRATE_SCRIPT             # apply"
  echo ""
  echo "  Details: $FRAMEWORK_DIR/core/MIGRATIONS/engineering-team-renamed-ginee.md"
  echo ""
fi

echo "Next steps:"
echo "  1. Open your client in this project."
echo "  2. Type:  Run initial discovery"
echo "     (auto-activates the ginee-discovery skill in Claude Code / Copilot CLI."
echo "      Tier-3 fallback: 'act as team-lead and run initial discovery'.)"
echo "  3. Review the recommended specialists; user-approve any extras to enable."
echo ""
echo "Documentation:"
echo "  Online:      https://kostiantyn-matsebora.github.io/ginee"
echo "  Process:     $FRAMEWORK_DIR/core/process.md"
echo "  Adapter:     $INSTALL_NOTE"
