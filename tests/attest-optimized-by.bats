#!/usr/bin/env bats
# Pester-equivalent coverage for adapters/claude/hooks/attest-optimized-by.sh.
# Push-time attestation: scans <upstream>..HEAD for Optimized-By: ai-engineer;
# missing-dispatch transcript → permissionDecision: "ask".

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$REPO_ROOT/adapters/claude/hooks/attest-optimized-by.sh"
  TMPDIR_TEST="$(mktemp -d)"
  cd "$TMPDIR_TEST"
  git init --quiet
  git config user.email t@t
  git config user.name t
  git commit --allow-empty --quiet -m base
  git tag base
}

teardown() {
  cd /
  rm -rf "$TMPDIR_TEST"
}

# add_commit "<body>" — appends an empty commit with the given message body.
add_commit() {
  git commit --allow-empty --quiet -m "$1"
}

make_transcript() {
  local tx
  tx="$(mktemp)"
  printf '%s' "$1" > "$tx"
  printf '%s' "$tx"
}

payload() {
  jq -n --arg tool "$1" --arg cmd "$2" --arg tp "${3:-}" '{
    hook_event_name: "PreToolUse",
    tool_name: $tool,
    tool_input: { command: $cmd },
    transcript_path: $tp
  }'
}

invoke() {
  # $1 payload, $2 transcript_override (optional)
  bash "$HOOK" --repo-root "$TMPDIR_TEST" --range-override 'base..HEAD' \
    --test-input "$1" ${2:+--transcript-override "$2"}
}

@test "parses cleanly (bash -n)" {
  run bash -n "$HOOK"
  [ "$status" -eq 0 ]
}

@test "exits 0 on non-Bash tool" {
  run invoke "$(payload Edit 'irrelevant')"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exits 0 on Bash command that is not git push" {
  run invoke "$(payload Bash 'git status')"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exits 0 on git push when range has no Optimized-By trailer" {
  add_commit "feat: plain change"
  run invoke "$(payload Bash 'git push')"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exits 0 on git push when trailer in range AND dispatch in transcript" {
  add_commit "$(printf 'feat: X\n\nOptimized-By: ai-engineer')"
  tx="$(make_transcript '{"type":"tool_use","name":"Agent","input":{"subagent_type":"ai-engineer","prompt":"opt"}}')"
  run invoke "$(payload Bash 'git push' "$tx")" "$tx"
  rm -f "$tx"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "emits ask when trailer in range + no dispatch in transcript" {
  add_commit "feat: WIP"
  add_commit "fix: edge case"
  add_commit "$(printf 'chore: pass\n\nOptimized-By: ai-engineer')"
  tx="$(make_transcript 'nothing about ai-engineer here')"
  run invoke "$(payload Bash 'git push' "$tx")" "$tx"
  rm -f "$tx"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.hookEventName == "PreToolUse"' >/dev/null
  echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "ask"' >/dev/null
  echo "$output" | jq -e '.hookSpecificOutput.permissionDecisionReason | test("Optimized-By: ai-engineer trailer")' >/dev/null
}

@test "emits ask when trailer is in any commit in the range, not just the tip" {
  add_commit "$(printf 'feat: pass\n\nOptimized-By: ai-engineer')"
  add_commit "fix: follow-up — no trailer"
  tx="$(make_transcript 'no dispatch')"
  run invoke "$(payload Bash 'git push' "$tx")" "$tx"
  rm -f "$tx"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "ask"' >/dev/null
}

@test "emits ask for git push variants (-u origin branch, --force-with-lease)" {
  add_commit "$(printf 'feat: X\n\nOptimized-By: ai-engineer')"
  tx="$(make_transcript 'no dispatch')"
  for push in 'git push origin HEAD' 'git push -u origin feat/x' 'git push --force-with-lease'; do
    run invoke "$(payload Bash "$push" "$tx")" "$tx"
    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "ask"' >/dev/null
  done
  rm -f "$tx"
}

@test "SKIP_GINEE_COMPLIANCE=1 bypasses the hook" {
  add_commit "$(printf 'feat: X\n\nOptimized-By: ai-engineer')"
  tx="$(make_transcript 'no dispatch')"
  SKIP_GINEE_COMPLIANCE=1 run invoke "$(payload Bash 'git push' "$tx")" "$tx"
  rm -f "$tx"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "framework.config.yaml opt-out bypasses the hook" {
  add_commit "$(printf 'feat: X\n\nOptimized-By: ai-engineer')"
  mkdir -p local
  cat > local/framework.config.yaml <<'EOF'
compliance:
  disabled:
    - optimized-by-attestation
EOF
  tx="$(make_transcript 'no dispatch')"
  run invoke "$(payload Bash 'git push' "$tx")" "$tx"
  rm -f "$tx"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exits 0 on empty range (no commits ahead of base)" {
  run invoke "$(payload Bash 'git push')"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
