#!/usr/bin/env bats
# Pester-equivalent coverage for adapters/claude/hooks/session-start.sh.
# Run from WSL / Linux: bats tests/session-start.bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$REPO_ROOT/adapters/claude/hooks/session-start.sh"
  TMPDIR_TEST="$(mktemp -d)"
  cd "$TMPDIR_TEST"
  git init --quiet
  git config user.email t@t
  git config user.name t
  git checkout -b main --quiet
  git commit --allow-empty --quiet -m initial
  git update-ref refs/remotes/origin/main HEAD
}

teardown() {
  cd /
  rm -rf "$TMPDIR_TEST"
}

ss_payload() {
  printf '{"hook_event_name":"SessionStart"}'
}

@test "parses cleanly (bash -n)" {
  run bash -n "$HOOK"
  [ "$status" -eq 0 ]
}

@test "quiet on main with no in-progress issues" {
  run bash "$HOOK" --repo-root "$TMPDIR_TEST" --no-gh --test-input "$(ss_payload)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "quiet on empty payload (no inject)" {
  run bash "$HOOK" --repo-root "$TMPDIR_TEST" --no-gh --test-input ''
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "injects branch line on issue/<N>-... branch" {
  git checkout -b issue/148-session-start --quiet
  run bash "$HOOK" --repo-root "$TMPDIR_TEST" --no-gh --test-input "$(ss_payload)"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '\[ginee:resume\]'
  echo "$output" | grep -qE 'branch:[[:space:]]+issue/148-session-start'
}

@test "marks uncommitted changes" {
  git checkout -b issue/148-session-start --quiet
  echo x > dirty.txt
  run bash "$HOOK" --repo-root "$TMPDIR_TEST" --no-gh --test-input "$(ss_payload)"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE 'uncommitted changes'
}

@test "skips on non-issue branch" {
  git checkout -b feature/foo --quiet
  run bash "$HOOK" --repo-root "$TMPDIR_TEST" --no-gh --test-input "$(ss_payload)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "emits valid hookSpecificOutput envelope" {
  git checkout -b issue/148-session-start --quiet
  run bash "$HOOK" --repo-root "$TMPDIR_TEST" --no-gh --test-input "$(ss_payload)"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' >/dev/null
  echo "$output" | jq -e '.hookSpecificOutput.additionalContext | test("\\[ginee:resume\\]")' >/dev/null
}

@test "SKIP_GINEE_COMPLIANCE=1 bypasses the hook" {
  git checkout -b issue/148-session-start --quiet
  SKIP_GINEE_COMPLIANCE=1 run bash "$HOOK" --repo-root "$TMPDIR_TEST" --no-gh --test-input "$(ss_payload)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "framework.config.yaml opt-out bypasses the hook" {
  git checkout -b issue/148-session-start --quiet
  mkdir -p local
  cat > local/framework.config.yaml <<'EOF'
compliance:
  disabled:
    - session-start-hook
EOF
  run bash "$HOOK" --repo-root "$TMPDIR_TEST" --no-gh --test-input "$(ss_payload)"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
