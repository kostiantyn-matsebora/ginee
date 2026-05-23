#!/usr/bin/env bats
# Coverage for install.sh.
# Mirrors the testable surface in install.Tests.ps1: arg parsing + the
# apply_model_tier_overrides helper (extracted + sourced so tests don't
# touch the network-dependent fetch path).
# Run from WSL / Linux: bats tests/install.bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  INSTALL_SH="$REPO_ROOT/install.sh"
  TMPDIR_TEST="$(mktemp -d)"

  # Extract the apply_model_tier_overrides function block + source it for unit
  # testing — same pattern as install.Tests.ps1's regex extraction. The block
  # lives between the "--- Model-tier overrides (D31)" banner and the next
  # "--- 3. Adapter prompt" banner.
  MT_HELPER="$TMPDIR_TEST/mt-helper.sh"
  awk '
    /^# --- Model-tier overrides \(D31\)/ { capture=1 }
    /^# --- 3\. Adapter prompt/           { capture=0 }
    capture                                { print }
  ' "$INSTALL_SH" > "$MT_HELPER"
  # Source the helper into the test shell so apply_model_tier_overrides is callable.
  # shellcheck disable=SC1090
  source "$MT_HELPER"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

# --- arg parsing + script integrity --------------------------------------

@test "parses cleanly (bash -n)" {
  run bash -n "$INSTALL_SH"
  [ "$status" -eq 0 ]
}

@test "rejects an unknown arg and exits non-zero" {
  run bash "$INSTALL_SH" --bogus-flag-not-real
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown arg"* ]]
}

@test "--help prints usage and exits 0" {
  run bash "$INSTALL_SH" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"ginee installer"* ]]
  [[ "$output" == *"--adapter"* ]]
}

@test "rejects an invalid --adapter and exits non-zero before network fetch" {
  TARGET="$TMPDIR_TEST/it-target"
  mkdir -p "$TARGET"
  run bash "$INSTALL_SH" --target "$TARGET" --adapter "bogus-not-a-real-adapter" </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid --adapter"* ]]
}

# --- apply_model_tier_overrides — sourced helper -------------------------

# Helper: write a pointer file with the cardinal-shaped frontmatter
new_pointer_file() {
  local agents_dir="$1" role="$2" existing_model="${3:-}"
  local file="$agents_dir/$role.md"
  mkdir -p "$agents_dir"
  if [ -n "$existing_model" ]; then
    cat > "$file" <<EOF
---
name: $role
description: Test pointer for $role.
model: $existing_model
---

body
EOF
  else
    cat > "$file" <<EOF
---
name: $role
description: Test pointer for $role.
---

body
EOF
  fi
  echo "$file"
}

@test "apply_model_tier_overrides: no-op when config file is missing" {
  agents_dir="$TMPDIR_TEST/agents-missing"
  missing_cfg="$TMPDIR_TEST/missing.yaml"
  file="$(new_pointer_file "$agents_dir" "team-lead" "claude-opus-4-7")"
  before="$(cat "$file")"
  run apply_model_tier_overrides "$agents_dir" "$missing_cfg"
  [ "$status" -eq 0 ]
  after="$(cat "$file")"
  [ "$before" = "$after" ]
}

@test "apply_model_tier_overrides: no-op when model-tier section absent" {
  agents_dir="$TMPDIR_TEST/agents-no-mt"
  cfg="$TMPDIR_TEST/no-mt.yaml"
  cat > "$cfg" <<'EOF'
architecture-doc: docs/architecture.md
delivery:
  default-mode: branch
EOF
  file="$(new_pointer_file "$agents_dir" "team-lead" "claude-opus-4-7")"
  before="$(cat "$file")"
  run apply_model_tier_overrides "$agents_dir" "$cfg"
  [ "$status" -eq 0 ]
  after="$(cat "$file")"
  [ "$before" = "$after" ]
}

@test "apply_model_tier_overrides: rewrites the model line when an override applies" {
  agents_dir="$TMPDIR_TEST/agents-override"
  cfg="$TMPDIR_TEST/full.yaml"
  cat > "$cfg" <<'EOF'
model-tier:
  per-role:
    ai-engineer: reasoning
  adapters:
    claude:
      reasoning: claude-opus-4-7
      standard: claude-sonnet-4-6
EOF
  file="$(new_pointer_file "$agents_dir" "ai-engineer" "claude-sonnet-4-6")"
  run apply_model_tier_overrides "$agents_dir" "$cfg"
  [ "$status" -eq 0 ]
  after="$(cat "$file")"
  [[ "$after" == *"model: claude-opus-4-7"* ]]
  [[ "$after" == *"D31"*"reasoning tier"* ]]
  [[ "$after" != *"model: claude-sonnet-4-6"* ]]
}

@test "apply_model_tier_overrides: leaves files without a matching override untouched" {
  agents_dir="$TMPDIR_TEST/agents-untouched"
  cfg="$TMPDIR_TEST/partial.yaml"
  cat > "$cfg" <<'EOF'
model-tier:
  per-role:
    ai-engineer: reasoning
  adapters:
    claude:
      reasoning: claude-opus-4-7
EOF
  file="$(new_pointer_file "$agents_dir" "qa-engineer" "claude-sonnet-4-6")"
  before="$(cat "$file")"
  run apply_model_tier_overrides "$agents_dir" "$cfg"
  [ "$status" -eq 0 ]
  after="$(cat "$file")"
  [ "$before" = "$after" ]
}

@test "apply_model_tier_overrides: injects model line when pointer lacks one" {
  agents_dir="$TMPDIR_TEST/agents-inject"
  cfg="$TMPDIR_TEST/inject.yaml"
  cat > "$cfg" <<'EOF'
model-tier:
  per-role:
    devops-engineer: fast
  adapters:
    claude:
      fast: claude-haiku-4-5-20251001
EOF
  file="$(new_pointer_file "$agents_dir" "devops-engineer" "")"
  run apply_model_tier_overrides "$agents_dir" "$cfg"
  [ "$status" -eq 0 ]
  after="$(cat "$file")"
  [[ "$after" == *"model: claude-haiku-4-5-20251001"* ]]
  [[ "$after" == *"D31"*"fast tier"* ]]
}

@test "apply_model_tier_overrides: skips when tier is set but adapter map lacks that tier" {
  agents_dir="$TMPDIR_TEST/agents-skip"
  cfg="$TMPDIR_TEST/skip.yaml"
  cat > "$cfg" <<'EOF'
model-tier:
  per-role:
    backend-engineer: fast
  adapters:
    claude:
      reasoning: claude-opus-4-7
EOF
  file="$(new_pointer_file "$agents_dir" "backend-engineer" "claude-sonnet-4-6")"
  before="$(cat "$file")"
  run apply_model_tier_overrides "$agents_dir" "$cfg"
  [ "$status" -eq 0 ]
  after="$(cat "$file")"
  [ "$before" = "$after" ]
}

@test "apply_model_tier_overrides: ignores comments inside the model-tier block" {
  agents_dir="$TMPDIR_TEST/agents-comments"
  cfg="$TMPDIR_TEST/comments.yaml"
  cat > "$cfg" <<'EOF'
model-tier:
  per-role:
    # this is a comment
    backend-engineer: standard
  adapters:
    claude:
      # commented map entry
      standard: claude-sonnet-4-6
EOF
  file="$(new_pointer_file "$agents_dir" "backend-engineer" "claude-opus-4-7")"
  run apply_model_tier_overrides "$agents_dir" "$cfg"
  [ "$status" -eq 0 ]
  after="$(cat "$file")"
  [[ "$after" == *"model: claude-sonnet-4-6"* ]]
}
