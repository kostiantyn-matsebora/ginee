#!/usr/bin/env bats
# Pester-equivalent coverage for adapters/claude/statusline.sh.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  STATUSLINE="$REPO_ROOT/adapters/claude/statusline.sh"
  TMPDIR_TEST="$(mktemp -d)"
  cd "$TMPDIR_TEST"
  git init --quiet
  git config user.email test@example.com
  git config user.name test
  git commit --allow-empty --quiet -m initial
  # Configure origin/main to point at HEAD so `origin/main..HEAD` resolves.
  git update-ref refs/remotes/origin/main HEAD
}

teardown() {
  cd /
  rm -rf "$TMPDIR_TEST"
}

run_statusline() {
  echo '{"session_id":"test"}' | bash "$STATUSLINE"
}

@test "parses cleanly (bash -n)" {
  run bash -n "$STATUSLINE"
  [ "$status" -eq 0 ]
}

@test "always exits 0" {
  run run_statusline
  [ "$status" -eq 0 ]
}

@test "output starts with [ginee] prefix" {
  run run_statusline
  echo "$output" | grep -qE '^\[ginee\]'
}

@test "output fits within 100 chars" {
  run run_statusline
  [ "${#output}" -le 100 ]
}

@test "emits a phase placeholder" {
  run run_statusline
  echo "$output" | grep -qE 'phase:[[:space:]]+\?'
}

@test "emits a trailer field" {
  run run_statusline
  echo "$output" | grep -qE 'trailer:[[:space:]]+(ok|needed)'
}

@test "outputs nothing when opt-out is set" {
  mkdir -p local
  cat > local/framework.config.yaml <<'EOF'
compliance:
  disabled:
    - compliance-statusline
EOF
  run run_statusline
  [ -z "$output" ]
}

@test "prints '(no repo)' outside a git tree" {
  outside="$(mktemp -d)"
  cd "$outside"
  run run_statusline
  echo "$output" | grep -qE '\[ginee\].*no repo'
  rm -rf "$outside"
}
