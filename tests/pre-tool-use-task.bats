#!/usr/bin/env bats
# Pester-equivalent coverage for adapters/claude/hooks/pre-tool-use-task.sh.
# Run from WSL / Linux: bats tests/pre-tool-use-task.bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$REPO_ROOT/adapters/claude/hooks/pre-tool-use-task.sh"
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
  bash "$HOOK" --test-input "$1"
}

task_payload() {
  local subagent="$1"; local prompt="$2"
  printf '{"hook_event_name":"PreToolUse","tool_name":"Task","tool_input":{"subagent_type":%s,"prompt":%s}}' \
    "$(printf '%s' "$subagent" | jq -Rs .)" \
    "$(printf '%s' "$prompt"   | jq -Rs .)"
}

@test "parses cleanly (bash -n)" {
  run bash -n "$HOOK"
  [ "$status" -eq 0 ]
}

@test "exits 0 on non-Task tool" {
  run invoke_hook '{"tool_name":"Bash","tool_input":{"command":"ls"}}'
  [ "$status" -eq 0 ]
}

@test "exits 0 on empty payload" {
  run invoke_hook ''
  [ "$status" -eq 0 ]
}

@test "exits 0 when Task targets backend-engineer in Phase 4" {
  run invoke_hook "$(task_payload 'backend-engineer' 'Implement Phase 4 backend changes')"
  [ "$status" -eq 0 ]
}

@test "exits 0 when Task targets SA in Phase 1" {
  run invoke_hook "$(task_payload 'solution-architect' 'Run Phase 1 design dip and elicit FRs/NFRs')"
  [ "$status" -eq 0 ]
}

@test "exits 0 when Task targets SA in Phase 2" {
  run invoke_hook "$(task_payload 'solution-architect' 'Author Phase 2 architecture doc + ADRs')"
  [ "$status" -eq 0 ]
}

@test "exits 0 when Task targets SA in Phase 7" {
  run invoke_hook "$(task_payload 'solution-architect' 'Phase 7 governance review of the PR')"
  [ "$status" -eq 0 ]
}

@test "blocks SA dispatch in Phase 4" {
  run invoke_hook "$(task_payload 'solution-architect' 'Review the architecture changes in Phase 4 implementation')"
  [ "$status" -eq 2 ]
  [[ "$output" == *"#182"* ]]
}

@test "blocks SA dispatch in Phase 5" {
  run invoke_hook "$(task_payload 'solution-architect' 'Address NFR-oracle red mid-Phase 5')"
  [ "$status" -eq 2 ]
}

@test "blocks SA dispatch in Phase 6" {
  run invoke_hook "$(task_payload 'solution-architect' 'Review the architectural fix proposal during Phase 6')"
  [ "$status" -eq 2 ]
}

@test "blocks SA dispatch mentioning phase-4-implementation file" {
  run invoke_hook "$(task_payload 'solution-architect' 'Read phase-4-implementation.md and dispatch')"
  [ "$status" -eq 2 ]
}

@test "honours SKIP_GINEE_COMPLIANCE=1" {
  SKIP_GINEE_COMPLIANCE=1 run invoke_hook "$(task_payload 'solution-architect' 'Phase 4 dip')"
  [ "$status" -eq 0 ]
}
