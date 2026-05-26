#!/usr/bin/env bash
# ginee installer hook — idempotently merge T2 / T3 PreToolUse hooks and T4
# statusLine into the adopter's .claude/settings.json (bash port).
#
# Mirrors core/scripts/sync-claude-settings.ps1; see that script's header
# for the full contract.
#
# Usage:
#   sync-claude-settings.sh --target <project-root> [--framework-rel <path>]
#
# Requires: jq. Without jq we surface a warning and skip the merge so the
# installer can still complete — adopter applies the snippet manually per
# adapters/claude/install.md § Compliance hooks.

set -eu

TARGET=""
FRAMEWORK_REL=".agents/ginee"

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --framework-rel) FRAMEWORK_REL="$2"; shift 2 ;;
    *) echo "sync-claude-settings: unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "sync-claude-settings: --target is required" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "sync-claude-settings: jq not on PATH — leaving .claude/settings.json untouched." >&2
  echo "  Install jq, then run /ginee-update again, OR apply the snippet manually per" >&2
  echo "  adapters/claude/install.md § Compliance hooks." >&2
  exit 0
fi

CLAUDE_DIR="$TARGET/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

EDIT_HOOK_CMD="pwsh -NoProfile -File $FRAMEWORK_REL/adapters/claude/hooks/pre-tool-use-edit.ps1"
BASH_HOOK_CMD="pwsh -NoProfile -File $FRAMEWORK_REL/adapters/claude/hooks/pre-tool-use-bash.ps1"
STATUSLINE_CMD="pwsh -NoProfile -File $FRAMEWORK_REL/adapters/claude/statusline.ps1"

EDIT_HOOK_MARKER="adapters/claude/hooks/pre-tool-use-edit"
BASH_HOOK_MARKER="adapters/claude/hooks/pre-tool-use-bash"
STATUSLINE_MARKER="adapters/claude/statusline"

mkdir -p "$CLAUDE_DIR"

# Load existing settings (or seed `{}`).
if [ -f "$SETTINGS" ]; then
  if ! jq empty "$SETTINGS" 2>/dev/null; then
    echo "sync-claude-settings: settings.json: failed to parse — leaving file untouched." >&2
    echo "  Manual merge required per adapters/claude/install.md § Compliance hooks." >&2
    exit 0
  fi
  CURRENT="$(cat "$SETTINGS")"
else
  CURRENT='{}'
fi

ORIGINAL="$CURRENT"

# --- statusLine (T4) ---
HAS_STATUSLINE="$(printf '%s' "$CURRENT" | jq 'has("statusLine")')"
if [ "$HAS_STATUSLINE" = "false" ]; then
  CURRENT="$(printf '%s' "$CURRENT" | jq --arg cmd "$STATUSLINE_CMD" \
    '.statusLine = { type: "command", command: $cmd }')"
else
  EXISTING_STATUSLINE_CMD="$(printf '%s' "$CURRENT" | jq -r '.statusLine.command // ""')"
  case "$EXISTING_STATUSLINE_CMD" in
    *"$STATUSLINE_MARKER"*)
      # Ginee-owned — refresh path.
      CURRENT="$(printf '%s' "$CURRENT" | jq --arg cmd "$STATUSLINE_CMD" \
        '.statusLine.command = $cmd')"
      ;;
    *)
      # Adopter-customised — leave alone.
      ;;
  esac
fi

# --- hooks scaffolding ---
CURRENT="$(printf '%s' "$CURRENT" | jq '
  if has("hooks") | not then .hooks = {} else . end
  | if .hooks | has("PreToolUse") | not then .hooks.PreToolUse = [] else . end
')"

# --- PreToolUse entries (T2 + T3) ---
add_pretooluse_entry() {
  local marker="$1"; local matcher="$2"; local cmd="$3"
  local found
  found="$(printf '%s' "$CURRENT" | jq --arg m "$marker" '
    [.hooks.PreToolUse[]? | .hooks[]? | .command // "" | select(test($m; "F"))] | length > 0
  ')"
  if [ "$found" = "false" ]; then
    CURRENT="$(printf '%s' "$CURRENT" | jq \
      --arg matcher "$matcher" --arg cmd "$cmd" '
      .hooks.PreToolUse += [{
        matcher: $matcher,
        hooks: [{ type: "command", command: $cmd, timeout: 10 }]
      }]')"
  fi
}

add_pretooluse_entry "$EDIT_HOOK_MARKER" "Edit|Write|MultiEdit" "$EDIT_HOOK_CMD"
add_pretooluse_entry "$BASH_HOOK_MARKER" "Bash"                  "$BASH_HOOK_CMD"

# --- Persist if changed ---
if [ "$CURRENT" = "$ORIGINAL" ]; then
  echo ".claude/settings.json already current — no change"
else
  printf '%s\n' "$CURRENT" | jq '.' > "$SETTINGS"
  echo "Synced .claude/settings.json (statusLine + PreToolUse hooks)"
fi
