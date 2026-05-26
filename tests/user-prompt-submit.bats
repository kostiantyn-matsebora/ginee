#!/usr/bin/env bats
# Pester-equivalent coverage for adapters/claude/hooks/user-prompt-submit.sh.
# Run from WSL / Linux: bats tests/user-prompt-submit.bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$REPO_ROOT/adapters/claude/hooks/user-prompt-submit.sh"
  TRIGGERS="$REPO_ROOT/adapters/claude/hooks/keyword-triggers.yaml"
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

# Invokes the hook against a known triggers file (the framework's checked-in one).
invoke_hook() {
  bash "$HOOK" --triggers-file "$TRIGGERS" --test-input "$1"
}

upsh_payload() {
  printf '{"hook_event_name":"UserPromptSubmit","prompt":%s}' "$(printf '%s' "$1" | jq -Rs .)"
}

@test "parses cleanly (bash -n)" {
  run bash -n "$HOOK"
  [ "$status" -eq 0 ]
}

@test "exits 0 with empty stdout on a benign prompt" {
  run invoke_hook "$(upsh_payload 'just chatting about the weather')"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exits 0 on empty payload" {
  run invoke_hook ''
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exits 0 when prompt field missing" {
  run invoke_hook '{"hook_event_name":"UserPromptSubmit"}'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "injects ginee-pick-up on 'pick up #141'" {
  run invoke_hook "$(upsh_payload 'pick up #141 please')"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '\[ginee:context:ginee-pick-up\]'
  echo "$output" | grep -qE 'core/skills/ginee-pick-up/SKILL\.md'
}

@test "emits valid hookSpecificOutput envelope" {
  run invoke_hook "$(upsh_payload 'pick up #141')"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.hookEventName == "UserPromptSubmit"' >/dev/null
  echo "$output" | jq -e '.hookSpecificOutput.additionalContext | test("ginee-pick-up")' >/dev/null
}

@test "injects automatic-mode on 'auto:' prefix" {
  run invoke_hook "$(upsh_payload 'auto: pick up #141')"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '\[ginee:context:automatic-mode\]'
}

@test "compound prompt injects multiple contexts" {
  run invoke_hook "$(upsh_payload 'auto: pick up #141 in branch:')"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '\[ginee:context:ginee-pick-up\]'
  echo "$output" | grep -qE '\[ginee:context:automatic-mode\]'
  echo "$output" | grep -qE '\[ginee:context:delivery-modes\]'
}

@test "injects dispatch-prompt-schema on @solution-architect" {
  run invoke_hook "$(upsh_payload 'dispatch @solution-architect for an ADR')"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '\[ginee:context:dispatch-prompt-schema\]'
}

@test "SKIP_GINEE_COMPLIANCE=1 bypasses the hook" {
  SKIP_GINEE_COMPLIANCE=1 run invoke_hook "$(upsh_payload 'pick up #141')"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "framework.config.yaml opt-out bypasses the hook" {
  mkdir -p local
  cat > local/framework.config.yaml <<'EOF'
compliance:
  disabled:
    - user-prompt-submit-hook
EOF
  run invoke_hook "$(upsh_payload 'pick up #141')"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
