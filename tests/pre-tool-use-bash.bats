#!/usr/bin/env bats
# Pester-equivalent coverage for adapters/claude/hooks/pre-tool-use-bash.sh.
# Run from WSL / Linux: bats tests/pre-tool-use-bash.bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$REPO_ROOT/adapters/claude/hooks/pre-tool-use-bash.sh"
  TMPDIR_TEST="$(mktemp -d)"
  cd "$TMPDIR_TEST"
  git init --quiet
  git config user.email test@example.com
  git config user.name test
  git commit --allow-empty --quiet -m initial
}

teardown() {
  cd /
  rm -rf "$TMPDIR_TEST"
}

invoke_hook() {
  printf '%s' "$1" | bash "$HOOK"
}

bash_payload() {
  printf '{"tool_name":"Bash","tool_input":{"command":%s}}' "$(printf '%s' "$1" | jq -Rs .)"
}

@test "parses cleanly (bash -n)" {
  run bash -n "$HOOK"
  [ "$status" -eq 0 ]
}

@test "exits 0 on a non-Bash tool" {
  run invoke_hook '{"tool_name":"Read","tool_input":{"file_path":"x"}}'
  [ "$status" -eq 0 ]
}

@test "exits 0 on empty payload" {
  run invoke_hook ''
  [ "$status" -eq 0 ]
}

@test "exits 0 on a benign command (ls -la)" {
  run invoke_hook "$(bash_payload 'ls -la')"
  [ "$status" -eq 0 ]
}

@test "exits 0 on a normal git commit" {
  run invoke_hook "$(bash_payload 'git commit -m "feat: add foo"')"
  [ "$status" -eq 0 ]
}

@test "blocks git commit --no-verify (Violation 1)" {
  run invoke_hook "$(bash_payload 'git commit -m msg --no-verify')"
  [ "$status" -eq 2 ]
  echo "$output" | grep -qE 'git commit --no-verify blocked'
}

@test "blocks git commit -n short flag" {
  run invoke_hook "$(bash_payload 'git commit -n -m msg')"
  [ "$status" -eq 2 ]
}

@test "blocks git push --force origin main (Violation 2)" {
  run invoke_hook "$(bash_payload 'git push --force origin main')"
  [ "$status" -eq 2 ]
  echo "$output" | grep -qE 'force on main'
}

@test "blocks git push -f master" {
  run invoke_hook "$(bash_payload 'git push -f origin master')"
  [ "$status" -eq 2 ]
}

@test "allows git push --force-with-lease on feature branch" {
  run invoke_hook "$(bash_payload 'git push --force-with-lease origin feat/wip')"
  [ "$status" -eq 0 ]
}

@test "blocks git reset --hard (Violation 3)" {
  run invoke_hook "$(bash_payload 'git reset --hard HEAD~1')"
  [ "$status" -eq 2 ]
  echo "$output" | grep -qE 'git reset --hard blocked'
}

@test "allows git reset --soft" {
  run invoke_hook "$(bash_payload 'git reset --soft HEAD~1')"
  [ "$status" -eq 0 ]
}

@test "blocks gh pr create with no body (Violation 4)" {
  run invoke_hook "$(bash_payload 'gh pr create --title x')"
  [ "$status" -eq 2 ]
  echo "$output" | grep -qE 'missing PR body'
}

@test "allows gh pr create --body" {
  run invoke_hook "$(bash_payload 'gh pr create --title x --body y')"
  [ "$status" -eq 0 ]
}

@test "allows gh pr create --draft" {
  run invoke_hook "$(bash_payload 'gh pr create --draft --title x')"
  [ "$status" -eq 0 ]
}

@test "exits 0 when SKIP_GINEE_COMPLIANCE=1" {
  SKIP_GINEE_COMPLIANCE=1 run invoke_hook "$(bash_payload 'git reset --hard HEAD~1')"
  [ "$status" -eq 0 ]
}

@test "opt-out via local/framework.config.yaml exits 0" {
  mkdir -p local
  cat > local/framework.config.yaml <<'EOF'
compliance:
  disabled:
    - pretooluse-bash-hook
EOF
  run invoke_hook "$(bash_payload 'git reset --hard HEAD~1')"
  [ "$status" -eq 0 ]
}
