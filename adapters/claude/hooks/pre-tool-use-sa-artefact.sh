#!/usr/bin/env bash
# ginee — PreToolUse Edit/Write/MultiEdit hook on SA-owned paths (#182 content axis, bash port).
# Mirrors .ps1 sibling. Spec: migrations/sa-boundary-tightening.md. Requires: bash 4+, jq.

set -u

if [ "${SKIP_GINEE_COMPLIANCE:-0}" = "1" ]; then exit 0; fi

block() {
  local rule="$1"; local detail="$2"; local remediation="$3"
  printf '[ginee:gate] %s — %s\n' "$rule" "$detail" >&2
  printf '  Remediation: %s\n' "$remediation" >&2
  printf '  Bypass (emergency): SKIP_GINEE_COMPLIANCE=1\n' >&2
  printf '  Opt out repo-wide: local/framework.config.yaml § compliance.disabled: [pretooluse-sa-artefact-hook]\n' >&2
  exit 2
}

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || true
}

is_opt_out() {
  local root="$1"
  local config="$root/local/framework.config.yaml"
  [ -f "$config" ] || return 1
  grep -q '^compliance:[[:space:]]*$' "$config" || return 1
  grep -qE '^[[:space:]]+-[[:space:]]+pretooluse-sa-artefact-hook[[:space:]]*$' "$config"
}

# Echo SA-owned paths from local/framework.config.yaml + canonical defaults.
sa_owned_paths() {
  local root="$1"
  local config="$root/local/framework.config.yaml"
  printf '%s\n' 'local/requirements.md'
  printf '%s\n' 'local/asr-utility-tree.md'
  [ -f "$config" ] || return 0
  awk '/^[[:space:]]*(architecture-doc|adr-directory|diagrams-directory):/ {
    sub(/^[[:space:]]*[a-z-]+:[[:space:]]*/, "")
    gsub(/^["'\''][[:space:]]*|[[:space:]]*["'\'']$/, "")
    if ($0 != "" && $0 != "null" && $0 != "~") print
  }' "$config"
}

# Is the given relative path SA-owned?
is_sa_owned() {
  local rel="$1"; local root="$2"
  rel="${rel//\\//}"
  local p
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    p="${p%/}"
    p="${p//\\//}"
    # exact match (case-insensitive)
    if [ "$(printf '%s' "$rel" | tr '[:upper:]' '[:lower:]')" = "$(printf '%s' "$p" | tr '[:upper:]' '[:lower:]')" ]; then
      return 0
    fi
    # prefix match for a directory
    case "$rel" in
      "$p"/*) return 0 ;;
    esac
  done < <(sa_owned_paths "$root")
  # Canonical heuristic fallback when local/framework.config.yaml is absent.
  if printf '%s' "$rel" | grep -qiE '(^|/)adr/.+\.md$'; then return 0; fi
  if printf '%s' "$rel" | grep -qiE '(^|/)architecture\.md$'; then return 0; fi
  return 1
}

PAYLOAD=""
if [ "${1:-}" = "--test-input" ] && [ -n "${2:-}" ]; then
  PAYLOAD="$2"
else
  PAYLOAD="$(cat 2>/dev/null || true)"
fi
payload="$PAYLOAD"
[ -n "$payload" ] || exit 0

tool_name="$(printf '%s' "$payload" | jq -r '.tool_name // empty' 2>/dev/null || true)"
case "$tool_name" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

root="$(repo_root)"
[ -n "$root" ] || exit 0
is_opt_out "$root" && exit 0

file_path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[ -n "$file_path" ] || exit 0

# Resolve absolute → repo-relative
rel="$file_path"
case "$file_path" in
  /*|[A-Za-z]:*)
    if command -v realpath >/dev/null 2>&1; then
      resolved="$(realpath -m -- "$file_path" 2>/dev/null || true)"
      root_resolved="$(realpath -m -- "$root" 2>/dev/null || true)"
      if [ -n "$resolved" ] && [ -n "$root_resolved" ]; then
        case "$resolved" in
          "$root_resolved"/*) rel="${resolved#"$root_resolved"/}" ;;
        esac
      fi
    fi
    ;;
esac
rel="${rel//\\//}"

if ! is_sa_owned "$rel" "$root"; then exit 0; fi

# Compute proposed post-edit content.
new_content=""
old_content=""
if [ "$tool_name" = "Write" ]; then
  new_content="$(printf '%s' "$payload" | jq -r '.tool_input.content // empty' 2>/dev/null || true)"
  [ -f "$file_path" ] && old_content="$(cat -- "$file_path")"
elif [ "$tool_name" = "Edit" ]; then
  old_str="$(printf '%s' "$payload" | jq -r '.tool_input.old_string // empty' 2>/dev/null || true)"
  new_str="$(printf '%s' "$payload" | jq -r '.tool_input.new_string // empty' 2>/dev/null || true)"
  if [ -f "$file_path" ]; then
    old_content="$(cat -- "$file_path")"
    # Replace literal old_str with new_str using awk (preserves multi-line).
    new_content="$(printf '%s' "$old_content" | awk -v o="$old_str" -v n="$new_str" 'BEGIN{ getline c; while (1){ p=index(c,o); if (p==0){ print c; while ((getline x) > 0) print x; exit } print substr(c,1,p-1) n substr(c,p+length(o)); while ((getline x) > 0) print x; exit }}')"
    # Fallback when awk replacement fails to apply — use new_str as the added body.
    [ -n "$new_content" ] || new_content="$new_str"
  else
    new_content="$new_str"
  fi
elif [ "$tool_name" = "MultiEdit" ]; then
  if [ -f "$file_path" ]; then
    old_content="$(cat -- "$file_path")"
    new_content="$old_content"
  fi
  # Apply each edit in order.
  edit_count="$(printf '%s' "$payload" | jq -r '.tool_input.edits | length' 2>/dev/null || echo 0)"
  i=0
  while [ "$i" -lt "$edit_count" ]; do
    o="$(printf '%s' "$payload" | jq -r ".tool_input.edits[$i].old_string // empty" 2>/dev/null || true)"
    n="$(printf '%s' "$payload" | jq -r ".tool_input.edits[$i].new_string // empty" 2>/dev/null || true)"
    new_content="$(printf '%s' "$new_content" | awk -v o="$o" -v n="$n" 'BEGIN{ rs=""; getline rs; while (1){ p=index(rs,o); if (p==0){ print rs; while ((getline x) > 0) print x; exit } rs=substr(rs,1,p-1) n substr(rs,p+length(o)); break }; print rs; while ((getline x) > 0) print x }')"
    i=$((i+1))
  done
fi

# Compute the added body (newContent minus oldContent lines).
added_body="$new_content"
if [ -n "$old_content" ]; then
  added_body="$(diff <(printf '%s' "$old_content") <(printf '%s' "$new_content") | sed -nE 's/^> //p')"
fi

# Violation 1: <file>:<line> citations into the working tree.
if printf '%s' "$added_body" | grep -qiE '\b[A-Za-z0-9._/-]+\.(ts|tsx|js|jsx|py|cs|go|java|rb|rs|cpp|c|h|hpp|swift|kt|m|mm|scala|php|sh|ps1|psm1|sql|html|css|scss|sass|less|vue|svelte|tf|hcl|yaml|yml|toml|ini|env|conf|md|mdx):[0-9]+\b'; then
  sample="$(printf '%s' "$added_body" | grep -oiE '\b[A-Za-z0-9._/-]+\.(ts|tsx|js|jsx|py|cs|go|java|rb|rs|cpp|c|h|hpp|swift|kt|m|mm|scala|php|sh|ps1|psm1|sql|html|css|scss|sass|less|vue|svelte|tf|hcl|yaml|yml|toml|ini|env|conf|md|mdx):[0-9]+\b' | head -3 | paste -sd ', ' -)"
  block 'SA-artefact implementation rendering — <file>:<line> citation (#182)' \
    "$rel would introduce line-numbered citations into the working tree (sample: $sample). SA-owned artefacts MUST NOT cite line numbers." \
    'Replace with architectural-mechanism phrasing (cite the mechanism + rationale rooted in NFR / constraint, not the code site) OR move the content to an engineer-owned per-tier doc via `## Next dispatch needed`. Full check schema: `core/templates/phase-report.md § SA-artefact content self-lint`.'
fi

# Violation 2: commit SHAs in evidence context.
if printf '%s' "$added_body" | grep -qiE '\b(as of|prior to|since|at commit|at sha|commit|revision|rev)[[:space:]]+[0-9a-f]{7,40}\b'; then
  sample="$(printf '%s' "$added_body" | grep -oiE '\b(as of|prior to|since|at commit|at sha|commit|revision|rev)[[:space:]]+[0-9a-f]{7,40}\b' | head -3 | paste -sd ', ' -)"
  block 'SA-artefact implementation rendering — commit SHA as evidence (#182)' \
    "$rel would cite commit SHA(s) as evidence (sample: $sample). SA-owned artefacts MUST NOT cite commit SHAs." \
    'Commit SHAs belong in PR descriptions (`core/templates/pr-description.md`), not SA artefacts. Replace with mechanism + rationale, or move to engineer-owned doc.'
fi

exit 0
