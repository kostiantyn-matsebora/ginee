#!/usr/bin/env bats
# Pester-equivalent coverage for adapters/claude/hooks/pre-tool-use-edit.sh.
# Run from WSL / Linux: bats tests/pre-tool-use-edit.bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$REPO_ROOT/adapters/claude/hooks/pre-tool-use-edit.sh"
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
  # $1 = JSON payload. Returns hook exit code; stderr available via $output.
  printf '%s' "$1" | bash "$HOOK"
}

@test "parses cleanly (bash -n)" {
  run bash -n "$HOOK"
  [ "$status" -eq 0 ]
}

@test "exits 0 on a tool name outside Edit/Write/MultiEdit" {
  run invoke_hook '{"tool_name":"Read","tool_input":{"file_path":"x.md"}}'
  [ "$status" -eq 0 ]
}

@test "exits 0 on an empty payload" {
  run invoke_hook ''
  [ "$status" -eq 0 ]
}

@test "exits 0 on a benign Write outside core/" {
  run invoke_hook '{"tool_name":"Write","tool_input":{"file_path":"README.txt","content":"hello"}}'
  [ "$status" -eq 0 ]
}

@test "blocks Write to core/process.md without frontmatter (Violation 1)" {
  run invoke_hook '{"tool_name":"Write","tool_input":{"file_path":"core/process.md","content":"no frontmatter"}}'
  [ "$status" -eq 2 ]
  echo "$output" | grep -qE 'hot-spec frontmatter required'
}

@test "allows Write to core/process.md with valid frontmatter" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"core/process.md","content":"---\naudience: all-cardinals\nload: always\ntriggers: []\ncap-bytes: 12000\nreads-before-applying: []\n---\n\nBody.\n"}}'
  run invoke_hook "$payload"
  [ "$status" -eq 0 ]
}

@test "blocks Write under core/protocols/ that adds a D-token (Violation 3)" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"core/protocols/new.md","content":"---\naudience: all-cardinals\nload: on-demand\ntriggers: [foo]\ncap-bytes: 2000\nreads-before-applying: []\n---\n\nThis cites D42 — should be blocked.\n"}}'
  run invoke_hook "$payload"
  [ "$status" -eq 2 ]
  echo "$output" | grep -qE 'D<N> token introduction blocked'
}

@test "blocks Write that adds 'always' as a rule modifier (Violation 4)" {
  payload='{"tool_name":"Write","tool_input":{"file_path":"core/protocols/style.md","content":"---\naudience: all-cardinals\nload: on-demand\ntriggers: [style]\ncap-bytes: 2000\nreads-before-applying: []\n---\n\nLines must always end with a period.\n"}}'
  run invoke_hook "$payload"
  [ "$status" -eq 2 ]
  echo "$output" | grep -qE 'RFC 2119 keyword convention'
}

@test "exits 0 when SKIP_GINEE_COMPLIANCE=1" {
  SKIP_GINEE_COMPLIANCE=1 run invoke_hook '{"tool_name":"Write","tool_input":{"file_path":"core/process.md","content":"no frontmatter"}}'
  [ "$status" -eq 0 ]
}

@test "opt-out via local/framework.config.yaml exits 0" {
  mkdir -p local
  cat > local/framework.config.yaml <<'EOF'
compliance:
  disabled:
    - pretooluse-edit-hook
EOF
  run invoke_hook '{"tool_name":"Write","tool_input":{"file_path":"core/process.md","content":"no frontmatter"}}'
  [ "$status" -eq 0 ]
}

@test "non-matching opt-out still blocks" {
  mkdir -p local
  cat > local/framework.config.yaml <<'EOF'
compliance:
  disabled:
    - some-other-tactic
EOF
  run invoke_hook '{"tool_name":"Write","tool_input":{"file_path":"core/process.md","content":"no frontmatter"}}'
  [ "$status" -eq 2 ]
}

@test "fails open when jq is not on PATH (graceful degrade)" {
  # Simulate by stripping jq from PATH for this run.
  EMPTY_PATH="$(dirname "$(command -v bash)")"
  PATH="$EMPTY_PATH" run invoke_hook '{"tool_name":"Write","tool_input":{"file_path":"core/process.md","content":"no frontmatter"}}'
  [ "$status" -eq 0 ]
}
