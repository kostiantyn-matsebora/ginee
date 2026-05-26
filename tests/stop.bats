#!/usr/bin/env bats
# Pester-equivalent coverage for adapters/claude/hooks/stop.sh.
# Run from WSL / Linux: bats tests/stop.bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$REPO_ROOT/adapters/claude/hooks/stop.sh"
  TMPDIR_TEST="$(mktemp -d)"
  cd "$TMPDIR_TEST"
  git init --quiet
  git config user.email t@t
  git config user.name t
  git commit --allow-empty --quiet -m initial
  # Branch name without leading digits ⇒ no GH issue check.
  git checkout -b feat-test --quiet
}

teardown() {
  cd /
  rm -rf "$TMPDIR_TEST"
}

invoke_hook() {
  bash "$HOOK" --test-input "$1"
}

stop_payload() {
  local transcript="$1"; local active="${2:-false}"
  if [ -n "$transcript" ]; then
    printf '{"hook_event_name":"Stop","transcript":%s,"stop_hook_active":%s}' \
      "$(printf '%s' "$transcript" | jq -Rs .)" "$active"
  else
    printf '{"hook_event_name":"Stop","stop_hook_active":%s}' "$active"
  fi
}

@test "parses cleanly (bash -n)" {
  run bash -n "$HOOK"
  [ "$status" -eq 0 ]
}

@test "exits 0 on empty payload" {
  run invoke_hook ''
  [ "$status" -eq 0 ]
}

@test "exits 0 when transcript has no specialist return" {
  run invoke_hook "$(stop_payload 'just a casual exchange')"
  [ "$status" -eq 0 ]
}

@test "anti-loop guard: stop_hook_active=true never blocks" {
  TRANSCRIPT='## Files touched
core/process.md
(no marker)'
  run invoke_hook "$(stop_payload "$TRANSCRIPT" true)"
  [ "$status" -eq 0 ]
}

@test "Block 1: missing self-lint marker blocks" {
  TRANSCRIPT='## Files touched
core/process.md

## Decisions made
extended.

## Verification log
ok.

## Open issues
(none)

## Next dispatch needed
(none)

## Source reads (this dispatch)
core/process.md

(no marker)'
  run invoke_hook "$(stop_payload "$TRANSCRIPT")"
  [ "$status" -eq 2 ]
  echo "$output" | grep -qE 'self-lint marker'
}

@test "Block 1: present marker passes" {
  TRANSCRIPT='## Files touched
core/process.md

<!-- self-lint: pass -->'
  run invoke_hook "$(stop_payload "$TRANSCRIPT")"
  [ "$status" -eq 0 ]
}

@test "Block 3: gh pr create without acceptance blocks" {
  TRANSCRIPT='gh pr create --title "feat: x" --body "..."
PR opened successfully.'
  run invoke_hook "$(stop_payload "$TRANSCRIPT")"
  [ "$status" -eq 2 ]
  echo "$output" | grep -qE 'PR opened without CI-watch sign-off'
}

@test "Block 3: gh pr create with acceptance signal passes" {
  TRANSCRIPT='gh pr create --title "feat: x" --body "..."
User: looks good, merged.'
  run invoke_hook "$(stop_payload "$TRANSCRIPT")"
  [ "$status" -eq 0 ]
}

@test "SKIP_GINEE_COMPLIANCE=1 bypasses" {
  TRANSCRIPT='## Files touched
core/process.md
(no marker)'
  SKIP_GINEE_COMPLIANCE=1 run invoke_hook "$(stop_payload "$TRANSCRIPT")"
  [ "$status" -eq 0 ]
}

@test "framework.config.yaml opt-out bypasses" {
  mkdir -p local
  cat > local/framework.config.yaml <<'EOF'
compliance:
  disabled:
    - stop-hook
EOF
  TRANSCRIPT='## Files touched
core/process.md
(no marker)'
  run invoke_hook "$(stop_payload "$TRANSCRIPT")"
  [ "$status" -eq 0 ]
}
