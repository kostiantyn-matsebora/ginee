#!/usr/bin/env bats
# Pester-equivalent coverage for core/scripts/migrate-engineering-team-to-ginee.sh.
# Run from WSL / Linux: bats tests/migrate-engineering-team-to-ginee.bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  MIGRATE_SRC="$REPO_ROOT/core/scripts/migrate-engineering-team-to-ginee.sh"
  TMPDIR_TEST="$(mktemp -d)"
  # Mirror the layout the script expects: <root>/.agents/ginee/core/scripts/<script>
  # + <root>/.agents/ginee/local/ alongside (script resolves local/ via ../../local).
  SCRIPT_COPY_DIR="$TMPDIR_TEST/.agents/ginee/core/scripts"
  LOCAL_DIR="$TMPDIR_TEST/.agents/ginee/local"
  mkdir -p "$SCRIPT_COPY_DIR" "$LOCAL_DIR"
  cp "$MIGRATE_SRC" "$SCRIPT_COPY_DIR/"
  SCRIPT_COPY="$SCRIPT_COPY_DIR/migrate-engineering-team-to-ginee.sh"
  chmod +x "$SCRIPT_COPY"
  CONFIG_PATH="$LOCAL_DIR/framework.config.yaml"
  cat > "$CONFIG_PATH" <<'EOF'
github:
  framework-repo: kostiantyn-matsebora/engineering-team
  ready-label: engineering-team:ready
  in-progress-label: engineering-team:in-progress
EOF
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

@test "parses cleanly (bash -n)" {
  run bash -n "$MIGRATE_SRC"
  [ "$status" -eq 0 ]
}

@test "dry-run leaves files untouched" {
  before="$(cat "$CONFIG_PATH")"
  run bash "$SCRIPT_COPY" --dry-run
  [ "$status" -eq 0 ]
  after="$(cat "$CONFIG_PATH")"
  [ "$before" = "$after" ]
  [[ "$output" == *"dry-run"* ]]
}

@test "real run rewrites every engineering-team occurrence to ginee" {
  run bash "$SCRIPT_COPY"
  [ "$status" -eq 0 ]
  content="$(cat "$CONFIG_PATH")"
  [[ "$content" != *engineering-team* ]]
  [[ "$content" == *"kostiantyn-matsebora/ginee"* ]]
  [[ "$content" == *"ginee:ready"* ]]
  [[ "$content" == *"ginee:in-progress"* ]]
}

@test "idempotent: re-run on already-rewritten tree is a no-op" {
  run bash "$SCRIPT_COPY"
  [ "$status" -eq 0 ]
  first="$(cat "$CONFIG_PATH")"
  run bash "$SCRIPT_COPY"
  [ "$status" -eq 0 ]
  second="$(cat "$CONFIG_PATH")"
  [ "$first" = "$second" ]
}

@test "reports 'local/ is clean' when no hits remain" {
  run bash "$SCRIPT_COPY"   # first pass rewrites
  [ "$status" -eq 0 ]
  run bash "$SCRIPT_COPY"   # second pass should be clean
  [ "$status" -eq 0 ]
  [[ "$output" == *"local/ is clean"* ]]
}

@test "fails with clear error when local/ is missing" {
  rm -rf "$LOCAL_DIR"
  run bash "$SCRIPT_COPY"
  [ "$status" -ne 0 ]
  [[ "$output" == *"local/ not found"* ]]
}

@test "rejects unknown args" {
  run bash "$SCRIPT_COPY" --bogus
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown arg"* ]]
}
