#!/usr/bin/env bash
# ginee installer (POSIX shell)
#
# Parameter cheat-sheet (do not confuse the two paths):
#   --target  = WHERE TO INSTALL INTO (the adopter project root — e.g. your dashboard repo).
#               Defaults to $PWD.
#   --repo    = WHERE TO FETCH THE FRAMEWORK FROM (the ginee git repo).
#               Defaults to the public GitHub URL. Pass a local checkout path
#               (e.g. /path/to/ginee) while the repo is private.
#
# The installer creates inside --target:
#   ./.agents/ginee/   — the framework (core/, adapters/, extras/, local/)
#   ./.claude/agents/             — Claude adapter (when --adapter claude)
#   ./.claude/skills/             — Claude adapter skills
#   ./.github/agents/             — Copilot CLI adapter (when --adapter copilot-cli)
#   ./.agents/skills/             — Copilot CLI adapter skills (cross-tool AgentSkills path)
#   ./AGENTS.md                   — AGENTS.md adapter (when --adapter agents-md)
#
# Field-trial example (private repo, local framework checkout, explicit --target so $PWD is irrelevant):
#   /path/to/ginee/install.sh \
#     --target  /path/to/your-project \
#     --repo    /path/to/ginee \
#     --adapter claude
#
# Usage (download once, run from project root):
#   curl -fsSLO https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh
#   chmod +x install.sh
#   ./install.sh [--target <path>] [--adapter <claude|copilot-cli|agents-md|generic>] [--ref <branch-or-tag>] [--repo <url-or-local-path>] [--update-only]
#
# Usage (remote one-liner — works once the framework repo is public):
#   curl -fsSL https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh | bash -s -- --adapter claude

set -euo pipefail

TARGET="$(pwd)"
ADAPTER=""
REF="main"
REPO_URL="https://github.com/kostiantyn-matsebora/ginee"
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
  echo "Migrating .agents/engineering-team/ -> .agents/ginee/ (post-2026-05-18 rebrand)"
  mv "$LEGACY_DIR" "$FRAMEWORK_DIR"
  echo "  Legacy install preserved in place; local/ contents carried over intact."
fi

# --- 1. Fetch framework ----------------------------------------------------

if [ -d "$FRAMEWORK_DIR" ]; then
  if [ "$UPDATE_ONLY" -eq 1 ]; then
    echo "Updating existing framework (preserving local/)..."
    LOCAL_BACKUP="$(mktemp -d)/local"
    if [ -d "$FRAMEWORK_DIR/local" ]; then
      cp -r "$FRAMEWORK_DIR/local" "$LOCAL_BACKUP"
    fi
    rm -rf "$FRAMEWORK_DIR/core" "$FRAMEWORK_DIR/adapters" "$FRAMEWORK_DIR/extras"
    # Fetch fresh upstream content into a temp clone, then copy the three upstream-owned dirs into place
    TMP_CLONE="$(mktemp -d)"
    git clone --depth 1 --branch "$REF" "$REPO_URL" "$TMP_CLONE"
    for d in core adapters extras; do
      if [ -d "$TMP_CLONE/$d" ]; then
        cp -r "$TMP_CLONE/$d" "$FRAMEWORK_DIR/$d"
      fi
    done
    rm -rf "$TMP_CLONE"
  else
    echo "Framework already installed at $FRAMEWORK_DIR. Use --update-only to refresh core/+adapters/+extras/ (local/ preserved)." >&2
    exit 1
  fi
else
  echo "Cloning framework..."
  mkdir -p "$(dirname "$FRAMEWORK_DIR")"
  git clone --depth 1 --branch "$REF" "$REPO_URL" "$FRAMEWORK_DIR"
  rm -rf "$FRAMEWORK_DIR/.git"
fi

# --- 2. Restore local/ on update -------------------------------------------

if [ "$UPDATE_ONLY" -eq 1 ] && [ -d "${LOCAL_BACKUP:-}" ]; then
  echo "Restoring preserved local/..."
  cp -r "$LOCAL_BACKUP" "$FRAMEWORK_DIR/local"
  rm -rf "$(dirname "$LOCAL_BACKUP")"
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
# Adopters need: core/ (incl. MIGRATIONS), adapters/_shared + chosen adapter,
# extras/, local/ skeleton. Everything else is framework-dev only.
for p in .github .claude .gitignore .dockerignore install.ps1 install.sh PLAN.md CLAUDE.md README.md; do
  rm -rf "$FRAMEWORK_DIR/$p"
done
# Drop unchosen adapter subdirs (keep _shared + the selected one)
for d in "$FRAMEWORK_DIR"/adapters/*/; do
  name="$(basename "$d")"
  if [ "$name" != "_shared" ] && [ "$name" != "$ADAPTER" ]; then
    rm -rf "$d"
  fi
done
echo "Pruned framework-dev files (release CI, other adapters, design docs)"

echo ""
echo "Adapter '$ADAPTER' will be installed per:"
echo "  $INSTALL_NOTE"
echo ""

case "$ADAPTER" in
  claude)
    mkdir -p "$TARGET/.claude/agents"
    cp "$FRAMEWORK_DIR"/adapters/_shared/agents/*.md "$TARGET/.claude/agents/"
    echo "Copied 7 cardinal subagents to .claude/agents/"
    mkdir -p "$TARGET/.claude/skills"
    rm -rf "$TARGET"/.claude/skills/ginee-*
    cp -r "$FRAMEWORK_DIR"/core/skills/ginee-* "$TARGET/.claude/skills/"
    echo "Copied 10 ginee-* skills to .claude/skills/"

    # Append CLAUDE-pointer.md to project's CLAUDE.md (idempotent via sentinel header)
    CLAUDE_MD="$TARGET/CLAUDE.md"
    POINTER_SRC="$FRAMEWORK_DIR/adapters/claude/CLAUDE-pointer.md"
    SENTINEL='## Engineering team framework'
    if [ -f "$CLAUDE_MD" ]; then
      if grep -qF "$SENTINEL" "$CLAUDE_MD"; then
        echo "CLAUDE.md already contains the ginee pointer — skipped append"
      else
        printf '\n' >> "$CLAUDE_MD"
        cat "$POINTER_SRC" >> "$CLAUDE_MD"
        echo "Appended ginee pointer block to CLAUDE.md"
      fi
    else
      cp "$POINTER_SRC" "$CLAUDE_MD"
      echo "Created CLAUDE.md from pointer template"
    fi
    ;;
  copilot-cli)
    mkdir -p "$TARGET/.github/agents"
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

echo ""
echo "Install complete."
echo "Next steps:"
echo "  1. Open your client in this project."
echo "  2. Type:  Run initial discovery"
echo "     (auto-activates the ginee-discovery skill in Claude Code / Copilot CLI."
echo "      Tier-3 fallback: 'act as project-manager and run initial discovery'.)"
echo "  3. Review the recommended specialists; user-approve any extras to enable."
echo ""
echo "Documentation:"
echo "  README:      $FRAMEWORK_DIR/README.md"
echo "  Process:     $FRAMEWORK_DIR/core/process.md"
echo "  Adapter:     $INSTALL_NOTE"
