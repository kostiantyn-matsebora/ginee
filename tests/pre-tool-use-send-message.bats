#!/usr/bin/env bats
# Pester-equivalent coverage for adapters/claude/hooks/pre-tool-use-send-message.sh.
# Run from WSL / Linux: bats tests/pre-tool-use-send-message.bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$REPO_ROOT/adapters/claude/hooks/pre-tool-use-send-message.sh"
  RULES="$REPO_ROOT/adapters/claude/hooks/carry-forward-rules.yaml"
  TMPDIR_TEST="$(mktemp -d)"
  cd "$TMPDIR_TEST"
  git init --quiet
  git config user.email t@t
  git config user.name t
  git commit --allow-empty --quiet -m initial
}

teardown() {
  cd /
  rm -rf "$TMPDIR_TEST"
}

invoke_hook() {
  bash "$HOOK" --rules-file "$RULES" --test-input "$1"
}

smsg_payload() {
  local target="$1"; local message="$2"
  printf '{"hook_event_name":"PreToolUse","tool_name":"SendMessage","tool_input":{"to":%s,"message":%s}}' \
    "$(printf '%s' "$target" | jq -Rs .)" \
    "$(printf '%s' "$message" | jq -Rs .)"
}

@test "parses cleanly (bash -n)" {
  run bash -n "$HOOK"
  [ "$status" -eq 0 ]
}

@test "exits 0 on a non-SendMessage tool" {
  run invoke_hook '{"tool_name":"Bash","tool_input":{"command":"ls"}}'
  [ "$status" -eq 0 ]
}

@test "exits 0 on Agent tool (first-dispatch out of scope)" {
  run invoke_hook '{"tool_name":"Agent","tool_input":{"subagent_type":"solution-architect","prompt":"do"}}'
  [ "$status" -eq 0 ]
}

@test "exits 0 on empty payload" {
  run invoke_hook ''
  [ "$status" -eq 0 ]
}

@test "exits 0 on missing target field" {
  run invoke_hook '{"tool_name":"SendMessage","tool_input":{"message":"hello"}}'
  [ "$status" -eq 0 ]
}

@test "exits 0 when anchor is present" {
  MSG='[carry-forward] Remember: lossless rule binds.
Now apply that to the next batch.'
  run invoke_hook "$(smsg_payload ai-engineer "$MSG")"
  [ "$status" -eq 0 ]
}

@test "tolerates leading blank lines before the anchor" {
  MSG='

[carry-forward] Remember: foo.
body'
  run invoke_hook "$(smsg_payload ai-engineer "$MSG")"
  [ "$status" -eq 0 ]
}

@test "blocks SendMessage to ai-engineer without anchor" {
  run invoke_hook "$(smsg_payload ai-engineer 'continue the optimization pass')"
  [ "$status" -eq 2 ]
  echo "$output" | grep -qE 'carry-forward'
  echo "$output" | grep -qE 'lossless rule binds'
}

@test "blocks SendMessage to solution-architect with SA-specific rule" {
  run invoke_hook "$(smsg_payload solution-architect 'review the next ADR draft')"
  [ "$status" -eq 2 ]
  echo "$output" | grep -qE 'APPROVE / REJECT / REQUEST-CHANGES only'
}

@test "blocks SendMessage to team-lead with team-lead rule" {
  run invoke_hook "$(smsg_payload team-lead 'pick up the next cardinal return')"
  [ "$status" -eq 2 ]
  echo "$output" | grep -qE 'skill-runner boundary'
}

@test "falls back to generic rule on unknown target" {
  run invoke_hook "$(smsg_payload unknown-cardinal 'continue')"
  [ "$status" -eq 2 ]
  echo "$output" | grep -qE "stay within your role"
}

@test "SKIP_GINEE_COMPLIANCE=1 bypasses" {
  SKIP_GINEE_COMPLIANCE=1 run invoke_hook "$(smsg_payload ai-engineer 'no anchor')"
  [ "$status" -eq 0 ]
}

@test "framework.config.yaml opt-out bypasses" {
  mkdir -p local
  cat > local/framework.config.yaml <<'EOF'
compliance:
  disabled:
    - pretooluse-send-message-hook
EOF
  run invoke_hook "$(smsg_payload ai-engineer 'no anchor')"
  [ "$status" -eq 0 ]
}
