#!/usr/bin/env bash
# engineering-team installer (POSIX shell)
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<owner>/engineering-team/main/install.sh | bash
#   OR locally:
#   ./install.sh [--target <path>] [--adapter <claude|copilot-cli|agents-md|generic>] [--ref <branch-or-tag>] [--update-only]

set -euo pipefail

TARGET="$(pwd)"
ADAPTER=""
REF="main"
REPO_URL="https://github.com/PLACEHOLDER-OWNER/engineering-team"
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

FRAMEWORK_DIR="$TARGET/engineering-team"

echo "engineering-team installer"
echo "  Target           : $TARGET"
echo "  Framework dir    : $FRAMEWORK_DIR"
echo "  Adapter          : ${ADAPTER:-detect interactively}"
echo "  Ref              : $REF"
echo ""

# --- 1. Fetch framework ----------------------------------------------------

if [ -d "$FRAMEWORK_DIR" ]; then
  if [ "$UPDATE_ONLY" -eq 1 ]; then
    echo "Updating existing framework (preserving local/)..."
    LOCAL_BACKUP="$(mktemp -d)/local"
    if [ -d "$FRAMEWORK_DIR/local" ]; then
      cp -r "$FRAMEWORK_DIR/local" "$LOCAL_BACKUP"
    fi
    rm -rf "$FRAMEWORK_DIR/core" "$FRAMEWORK_DIR/adapters" "$FRAMEWORK_DIR/extras"
  else
    echo "Framework already installed at $FRAMEWORK_DIR. Use --update-only to refresh core/+adapters/+extras/ (local/ preserved)." >&2
    exit 1
  fi
else
  echo "Cloning framework..."
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
  echo ""
  echo "Pick the adapter that matches your LLM client:"
  echo "  [1] claude       — Claude Code (tier-1)"
  echo "  [2] copilot-cli  — GitHub Copilot CLI (tier-1)"
  echo "  [3] agents-md    — Codex / Cursor / Windsurf / Amp / Devin / Factory / Jules / Copilot IDE (tier-2)"
  echo "  [4] generic      — INSTRUCTIONS.md fallback (tier-3)"
  read -rp "Pick 1-4: " sel
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

echo ""
echo "Adapter '$ADAPTER' will be installed per:"
echo "  $INSTALL_NOTE"
echo ""

case "$ADAPTER" in
  claude)
    mkdir -p "$TARGET/.claude/agents"
    cp "$FRAMEWORK_DIR"/adapters/_shared/agents/*.md "$TARGET/.claude/agents/"
    echo "Copied 7 cardinal subagents to .claude/agents/"
    echo "NEXT: append CLAUDE-pointer.md to your project's CLAUDE.md (see $INSTALL_NOTE)"
    ;;
  copilot-cli)
    mkdir -p "$TARGET/.github/agents"
    for f in "$FRAMEWORK_DIR"/adapters/_shared/agents/*.md; do
      name="$(basename "$f" .md)"
      cp "$f" "$TARGET/.github/agents/${name}.agent.md"
    done
    echo "Copied 7 cardinal subagents to .github/agents/*.agent.md"
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
echo "  2. Prompt: @project-manager run initial discovery"
echo "     (or 'act as project-manager and run initial discovery' for tier-2/3 clients)"
echo "  3. Review the recommended specialists; user-approve any extras to enable."
echo ""
echo "Documentation:"
echo "  README:      $FRAMEWORK_DIR/README.md"
echo "  Process:     $FRAMEWORK_DIR/core/process.md"
echo "  Adapter:     $INSTALL_NOTE"
