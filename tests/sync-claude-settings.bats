#!/usr/bin/env bats
# Pester-equivalent coverage for core/scripts/sync-claude-settings.sh.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SYNC="$REPO_ROOT/core/scripts/sync-claude-settings.sh"
  TGT="$(mktemp -d)"
}

teardown() {
  rm -rf "$TGT"
}

@test "parses cleanly (bash -n)" {
  run bash -n "$SYNC"
  [ "$status" -eq 0 ]
}

@test "creates settings.json with statusLine + 2 PreToolUse entries on fresh target" {
  run bash "$SYNC" --target "$TGT"
  [ "$status" -eq 0 ]
  [ -f "$TGT/.claude/settings.json" ]
  # statusLine present
  jq -e '.statusLine.command | test("adapters/claude/statusline.ps1$")' "$TGT/.claude/settings.json" >/dev/null
  # 2 PreToolUse entries
  count="$(jq -r '.hooks.PreToolUse | length' "$TGT/.claude/settings.json")"
  [ "$count" = "2" ]
  jq -e '.hooks.PreToolUse[] | .matcher == "Edit|Write|MultiEdit"' "$TGT/.claude/settings.json" >/dev/null
  jq -e '.hooks.PreToolUse[] | .matcher == "Bash"' "$TGT/.claude/settings.json" >/dev/null
}

@test "is idempotent on re-run" {
  bash "$SYNC" --target "$TGT" >/dev/null
  before="$(cat "$TGT/.claude/settings.json")"
  bash "$SYNC" --target "$TGT" >/dev/null
  after="$(cat "$TGT/.claude/settings.json")"
  [ "$before" = "$after" ]
}

@test "preserves unrelated top-level keys (env, theme)" {
  mkdir -p "$TGT/.claude"
  cat > "$TGT/.claude/settings.json" <<'EOF'
{ "env": { "DEBUG": "true" }, "theme": "dark" }
EOF
  bash "$SYNC" --target "$TGT" >/dev/null
  [ "$(jq -r '.env.DEBUG' "$TGT/.claude/settings.json")" = "true" ]
  [ "$(jq -r '.theme' "$TGT/.claude/settings.json")" = "dark" ]
  jq -e '.statusLine.command | test("statusline.ps1$")' "$TGT/.claude/settings.json" >/dev/null
}

@test "does NOT overwrite an adopter-customised statusLine" {
  mkdir -p "$TGT/.claude"
  cat > "$TGT/.claude/settings.json" <<'EOF'
{ "statusLine": { "type": "command", "command": "my-custom-status.sh" } }
EOF
  bash "$SYNC" --target "$TGT" >/dev/null
  [ "$(jq -r '.statusLine.command' "$TGT/.claude/settings.json")" = "my-custom-status.sh" ]
  count="$(jq -r '.hooks.PreToolUse | length' "$TGT/.claude/settings.json")"
  [ "$count" = "2" ]
}

@test "refreshes a ginee-owned statusLine command when path drifts" {
  mkdir -p "$TGT/.claude"
  cat > "$TGT/.claude/settings.json" <<'EOF'
{ "statusLine": { "type": "command", "command": "pwsh -NoProfile -File OLD/PATH/adapters/claude/statusline.ps1" } }
EOF
  bash "$SYNC" --target "$TGT" >/dev/null
  expected='pwsh -NoProfile -File .agents/ginee/adapters/claude/statusline.ps1'
  [ "$(jq -r '.statusLine.command' "$TGT/.claude/settings.json")" = "$expected" ]
}

@test "does NOT duplicate an existing pre-tool-use-edit PreToolUse entry" {
  mkdir -p "$TGT/.claude"
  cat > "$TGT/.claude/settings.json" <<'EOF'
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Edit",
        "hooks": [{ "type": "command",
                    "command": "pwsh -NoProfile -File some/path/adapters/claude/hooks/pre-tool-use-edit.ps1",
                    "timeout": 5 }] }
    ]
  }
}
EOF
  bash "$SYNC" --target "$TGT" >/dev/null
  edit_count="$(jq -r '[.hooks.PreToolUse[] | .hooks[] | select(.command | test("pre-tool-use-edit"))] | length' "$TGT/.claude/settings.json")"
  [ "$edit_count" = "1" ]
  bash_count="$(jq -r '[.hooks.PreToolUse[] | .hooks[] | select(.command | test("pre-tool-use-bash"))] | length' "$TGT/.claude/settings.json")"
  [ "$bash_count" = "1" ]
}

@test "malformed JSON: leaves file untouched, exits 0" {
  mkdir -p "$TGT/.claude"
  junk='{ this is not json'
  printf '%s' "$junk" > "$TGT/.claude/settings.json"
  run bash "$SYNC" --target "$TGT"
  [ "$status" -eq 0 ]
  [ "$(cat "$TGT/.claude/settings.json")" = "$junk" ]
}

@test "honours --framework-rel in emitted commands" {
  bash "$SYNC" --target "$TGT" --framework-rel "vendor/ginee" >/dev/null
  expected='pwsh -NoProfile -File vendor/ginee/adapters/claude/statusline.ps1'
  [ "$(jq -r '.statusLine.command' "$TGT/.claude/settings.json")" = "$expected" ]
}

@test "exits cleanly when jq is missing (warning only)" {
  TMP_BIN="$(mktemp -d)"
  for tool in bash mkdir cat printf grep mv rm; do
    if cmd="$(command -v "$tool" 2>/dev/null)"; then
      ln -s "$cmd" "$TMP_BIN/$tool" 2>/dev/null || true
    fi
  done
  PATH="$TMP_BIN" run bash "$SYNC" --target "$TGT"
  rm -rf "$TMP_BIN"
  [ "$status" -eq 0 ]
}
