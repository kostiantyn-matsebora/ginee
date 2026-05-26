#!/usr/bin/env bats
# Pester-equivalent coverage for adapters/claude/hooks/post-tool-use-edit.sh.
# Run from WSL / Linux: bats tests/post-tool-use-edit.bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$REPO_ROOT/adapters/claude/hooks/post-tool-use-edit.sh"
  TMPDIR_TEST="$(mktemp -d)"
  cd "$TMPDIR_TEST"
  git init --quiet
  git config user.email t@t
  git config user.name t
  git commit --allow-empty --quiet -m initial
  # mkdir core so REL resolution works
  mkdir -p core/protocols core/roles
  touch core/process.md
}

teardown() {
  cd /
  rm -rf "$TMPDIR_TEST"
}

invoke_hook() {
  bash "$HOOK" --test-input "$1"
}

posttool_payload() {
  local tool="$1"; local path="$2"
  printf '{"hook_event_name":"PostToolUse","tool_name":"%s","tool_input":{"file_path":%s},"tool_response":{"success":true}}' \
    "$tool" "$(printf '%s' "$path" | jq -Rs .)"
}

@test "parses cleanly (bash -n)" {
  run bash -n "$HOOK"
  [ "$status" -eq 0 ]
}

@test "exits 0 with empty stdout on a non-Edit tool" {
  run invoke_hook '{"tool_name":"Bash","tool_input":{"command":"ls"}}'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exits 0 on empty payload" {
  run invoke_hook ''
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exits 0 with empty stdout on edits outside core/ (tests/)" {
  run invoke_hook "$(posttool_payload Edit tests/foo.Tests.ps1)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exits 0 with empty stdout on edits outside core/ (adapters/)" {
  run invoke_hook "$(posttool_payload Edit adapters/claude/install.md)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exits 0 with empty stdout on edits outside core/ (local/)" {
  run invoke_hook "$(posttool_payload Edit local/bindings.md)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "injects self-check on Edit to core/process.md" {
  run invoke_hook "$(posttool_payload Edit core/process.md)"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '\[ginee:self-check\]'
  echo "$output" | grep -qE 'core/process\.md'
}

@test "emits valid hookSpecificOutput envelope" {
  run invoke_hook "$(posttool_payload Edit core/protocols/foo.md)"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.hookEventName == "PostToolUse"' >/dev/null
  echo "$output" | jq -e '.hookSpecificOutput.additionalContext | test("self-check")' >/dev/null
}

@test "reminder body <= 6 lines for non-always-loaded path" {
  run invoke_hook "$(posttool_payload Edit core/protocols/foo.md)"
  [ "$status" -eq 0 ]
  line_count="$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext' | wc -l | awk '{print $1+1}')"
  [ "$line_count" -le 6 ]
}

@test "always-loaded reminder fires on core/process.md" {
  run invoke_hook "$(posttool_payload Edit core/process.md)"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.additionalContext | test("always-loaded surface")' >/dev/null
}

@test "always-loaded reminder fires on core/roles/team-lead.md" {
  run invoke_hook "$(posttool_payload Edit core/roles/team-lead.md)"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.additionalContext | test("always-loaded surface")' >/dev/null
}

@test "always-loaded reminder skipped for *.details.md sibling" {
  run invoke_hook "$(posttool_payload Edit core/roles/team-lead.details.md)"
  [ "$status" -eq 0 ]
  if echo "$output" | jq -e '.hookSpecificOutput.additionalContext | test("always-loaded surface")' >/dev/null; then
    return 1
  fi
}

@test "SKIP_GINEE_COMPLIANCE=1 bypasses the hook" {
  SKIP_GINEE_COMPLIANCE=1 run invoke_hook "$(posttool_payload Edit core/process.md)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
