#!/usr/bin/env bash
# ginee — PreToolUse Task hook (#182 timing axis, bash port). Mirrors .ps1 sibling.
# Spec: migrations/sa-boundary-tightening.md. Requires: bash 4+, jq.

set -u

if [ "${SKIP_GINEE_COMPLIANCE:-0}" = "1" ]; then exit 0; fi

block() {
  local rule="$1"; local detail="$2"; local remediation="$3"
  printf '[ginee:gate] %s — %s\n' "$rule" "$detail" >&2
  printf '  Remediation: %s\n' "$remediation" >&2
  printf '  Bypass (emergency): SKIP_GINEE_COMPLIANCE=1\n' >&2
  printf '  Opt out repo-wide: local/framework.config.yaml § compliance.disabled: [pretooluse-task-hook]\n' >&2
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
  grep -qE '^[[:space:]]+-[[:space:]]+pretooluse-task-hook[[:space:]]*$' "$config"
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
[ "$tool_name" = "Task" ] || exit 0

root="$(repo_root)"
[ -n "$root" ] || exit 0
is_opt_out "$root" && exit 0

target="$(printf '%s' "$payload" | jq -r '.tool_input.subagent_type // .tool_input.agent // .tool_input.agent_name // .tool_input.target // .tool_input.recipient // empty' 2>/dev/null || true)"
[ -n "$target" ] || exit 0

# Match solution-architect (case-insensitive)
if ! printf '%s' "$target" | grep -qiE '\bsolution-?architect\b'; then exit 0; fi

prompt="$(printf '%s' "$payload" | jq -r '[.tool_input.prompt, .tool_input.description, .tool_input.message, .tool_input.task, .tool_input.body] | map(select(.)) | join("\n")' 2>/dev/null || true)"

# Phase 4/5/6 indicator (case-insensitive)
if ! printf '%s' "$prompt" | grep -qiE '(\b(in|at|during|mid-?)?[[:space:]]*phase[[:space:]-]*[456]\b|phase-(4|5|6)-(implementation|testing|bug-?fixing))'; then exit 0; fi

block 'SA dispatch in Phase 4 / 5 / 6 — categorical refusal (#182)' \
  "Task to solution-architect carries a Phase 4 / 5 / 6 indicator. SA \`phase-participation: [1, 2, 7]\`; categorical refusal during implementation phases." \
  'Engineer-surfaced architectural delta routes through team-lead per `core/roles/team-lead.md § Engineer-surfaced architectural-delta gate` — surface user-gate (defer / stop + re-enter Phase 1–2). SA is dispatched only in Phase 1, 2, or conditional Phase 7.'
