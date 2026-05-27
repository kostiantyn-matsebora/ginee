#!/usr/bin/env bash
# ginee context-economy gate — bash hook installer.
# Idempotent. Re-run after pulling new hook versions.
#
# Usage:
#   scripts/install-hooks.sh         # install/skip-if-same
#   scripts/install-hooks.sh --force # overwrite existing

set -e

force=0
case "${1:-}" in
  --force|-f) force=1 ;;
esac

repo_root="$(git rev-parse --show-toplevel)"
hooks_path="$(git config --get core.hooksPath || true)"
if [ -z "$hooks_path" ]; then
  hooks_dir="$repo_root/.git/hooks"
elif [ "${hooks_path:0:1}" = "/" ]; then
  hooks_dir="$hooks_path"
else
  hooks_dir="$repo_root/$hooks_path"
fi
mkdir -p "$hooks_dir"

src="$repo_root/hooks"
if [ ! -d "$src" ]; then
  echo "Source hooks directory not found at $src" >&2
  exit 1
fi

for name in pre-commit commit-msg pre-push; do
  from="$src/$name"
  to="$hooks_dir/$name"
  [ -f "$from" ] || continue
  if [ -f "$to" ] && [ "$force" -ne 1 ]; then
    if cmp -s "$from" "$to"; then
      echo "context-economy: $name already up to date."
      continue
    fi
    echo "context-economy: $name exists and differs — re-run with --force to overwrite."
    continue
  fi
  cp "$from" "$to"
  chmod +x "$to"
  echo "context-economy: installed $name -> $to"
done

# Layer 1 — Claude Code project settings (copy template if absent).
claude_dest="$repo_root/.claude/settings.json"
claude_src="$repo_root/.claude/settings.json.example"
if [ -f "$claude_src" ]; then
  if [ ! -f "$claude_dest" ] || [ "$force" -eq 1 ]; then
    mkdir -p "$(dirname "$claude_dest")"
    cp "$claude_src" "$claude_dest"
    echo "context-economy: installed .claude/settings.json (Layer 1 hook)"
  else
    echo "context-economy: .claude/settings.json already exists — leaving untouched (re-run with --force to overwrite)."
  fi
fi

echo
echo 'Done. Hooks active on next git commit / git push / Claude Code edit.'
echo 'Bypass (use sparingly): SKIP_CONTEXT_ECONOMY=1 git commit ...'
