#!/usr/bin/env bats
# Pester-equivalent coverage for scripts/install-hooks.sh.
# Run from WSL / Linux: bats tests/install-hooks.bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  INSTALL_HOOKS="$REPO_ROOT/scripts/install-hooks.sh"
  TMPDIR_TEST="$(mktemp -d)"
  cd "$TMPDIR_TEST"
  git init --quiet
  # Source hooks the installer expects to find
  mkdir -p hooks
  printf '#!/usr/bin/env bash\necho pre-commit hook\n' > hooks/pre-commit
  printf '#!/usr/bin/env bash\necho pre-push hook\n'   > hooks/pre-push
  # .example claude settings the installer also copies
  mkdir -p .claude
  printf '{ "hooks": {} }' > .claude/settings.json.example
}

teardown() {
  cd /
  rm -rf "$TMPDIR_TEST"
}

@test "parses cleanly (bash -n)" {
  run bash -n "$INSTALL_HOOKS"
  [ "$status" -eq 0 ]
}

@test "fails when run outside a git tree" {
  outside="$(mktemp -d)"
  cd "$outside"
  run bash "$INSTALL_HOOKS"
  [ "$status" -ne 0 ]
  rm -rf "$outside"
}

@test "installs both pre-commit and pre-push into .git/hooks/" {
  run bash "$INSTALL_HOOKS"
  [ "$status" -eq 0 ]
  [ -f .git/hooks/pre-commit ]
  [ -f .git/hooks/pre-push ]
  grep -q 'pre-commit hook' .git/hooks/pre-commit
  grep -q 'pre-push hook'   .git/hooks/pre-push
  [ -x .git/hooks/pre-commit ]
  [ -x .git/hooks/pre-push ]
}

@test "installs .claude/settings.json from .example when absent" {
  rm -f .claude/settings.json
  run bash "$INSTALL_HOOKS"
  [ "$status" -eq 0 ]
  [ -f .claude/settings.json ]
  grep -q '"hooks"' .claude/settings.json
}

@test "idempotent — re-run with identical hooks reports 'already up to date'" {
  run bash "$INSTALL_HOOKS"
  [ "$status" -eq 0 ]
  run bash "$INSTALL_HOOKS"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already up to date"* ]]
}

@test "leaves an existing differing hook untouched without --force" {
  mkdir -p .git/hooks
  printf '# user customisation\n' > .git/hooks/pre-commit
  before="$(cat .git/hooks/pre-commit)"
  run bash "$INSTALL_HOOKS"
  [ "$status" -eq 0 ]
  after="$(cat .git/hooks/pre-commit)"
  [ "$before" = "$after" ]
  [[ "$output" == *"exists and differs"* ]]
}

@test "--force overwrites an existing differing hook" {
  mkdir -p .git/hooks
  printf '# user version\n' > .git/hooks/pre-commit
  run bash "$INSTALL_HOOKS" --force
  [ "$status" -eq 0 ]
  grep -q 'pre-commit hook' .git/hooks/pre-commit
}

@test "leaves an existing .claude/settings.json untouched without --force" {
  printf '{ "user": "value" }' > .claude/settings.json
  run bash "$INSTALL_HOOKS"
  [ "$status" -eq 0 ]
  grep -q '"user"' .claude/settings.json
}

@test "honours core.hooksPath when set" {
  mkdir -p custom-hooks
  git config core.hooksPath custom-hooks
  run bash "$INSTALL_HOOKS"
  [ "$status" -eq 0 ]
  [ -f custom-hooks/pre-commit ]
  [ -f custom-hooks/pre-push ]
  [ ! -f .git/hooks/pre-commit ]
}

@test "fails when source hooks/ directory is missing" {
  rm -rf hooks
  run bash "$INSTALL_HOOKS"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Source hooks directory not found"* ]]
}
