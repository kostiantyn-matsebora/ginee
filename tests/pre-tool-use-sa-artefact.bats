#!/usr/bin/env bats
# Pester-equivalent coverage for adapters/claude/hooks/pre-tool-use-sa-artefact.sh.
# Run from WSL / Linux: bats tests/pre-tool-use-sa-artefact.bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="$REPO_ROOT/adapters/claude/hooks/pre-tool-use-sa-artefact.sh"
  TMPDIR_TEST="$(mktemp -d)"
  cd "$TMPDIR_TEST"
  git init --quiet
  git config user.email t@t
  git config user.name t
  git commit --allow-empty --quiet -m initial
  mkdir -p local docs/adr
  cat > local/framework.config.yaml <<'EOF'
adr-directory: docs/adr/
architecture-doc: docs/architecture.md
EOF
}

teardown() {
  cd /
  rm -rf "$TMPDIR_TEST"
}

invoke_hook() {
  bash "$HOOK" --test-input "$1"
}

write_payload() {
  local path="$1"; local content="$2"
  printf '{"hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":%s,"content":%s}}' \
    "$(printf '%s' "$path"    | jq -Rs .)" \
    "$(printf '%s' "$content" | jq -Rs .)"
}

@test "parses cleanly (bash -n)" {
  run bash -n "$HOOK"
  [ "$status" -eq 0 ]
}

@test "exits 0 on non-Edit tool" {
  run invoke_hook '{"tool_name":"Bash","tool_input":{"command":"ls"}}'
  [ "$status" -eq 0 ]
}

@test "exits 0 on non-SA path (src/handler.ts)" {
  run invoke_hook "$(write_payload 'src/handler.ts' 'see other.ts:42 for context')"
  [ "$status" -eq 0 ]
}

@test "exits 0 on README.md outside SA-owned paths" {
  run invoke_hook "$(write_payload 'README.md' 'See handler.ts:142 here.')"
  [ "$status" -eq 0 ]
}

@test "allows clean content on local/requirements.md" {
  run invoke_hook "$(write_payload 'local/requirements.md' '# Requirements\n## FR-001\nThe system shall paginate.')"
  [ "$status" -eq 0 ]
}

@test "blocks file-line citation in local/requirements.md" {
  run invoke_hook "$(write_payload 'local/requirements.md' '## FR-001\nSee src/handler.ts:142.')"
  [ "$status" -eq 2 ]
  [[ "$output" == *"#182"* ]]
}

@test "blocks file-line citation in local/asr-utility-tree.md" {
  run invoke_hook "$(write_payload 'local/asr-utility-tree.md' '## ASR-001\nDerived from app/pagination.cs:47.')"
  [ "$status" -eq 2 ]
}

@test "blocks file-line citation in docs/adr/ADR-0001.md (config-derived path)" {
  run invoke_hook "$(write_payload 'docs/adr/ADR-0001-paging.md' '## Decision\nReplace approach.ts:88 with cursor pagination.')"
  [ "$status" -eq 2 ]
}

@test "blocks as-of <sha> on SA path" {
  # Use $'...' ANSI-C quoting so \n becomes a real newline; otherwise the
  # literal `\n` sits between the previous word char (`n`) and `A`s of`, which
  # voids the leading word boundary in the SHA regex.
  run invoke_hook "$(write_payload 'local/requirements.md' $'## FR-001\nAs of 1aaa215abc, pagination wraps.')"
  [ "$status" -eq 2 ]
  [[ "$output" == *"SHA"* ]]
}

@test "blocks commit <sha> on ADR path" {
  run invoke_hook "$(write_payload 'docs/adr/ADR-0002-latency.md' '## Context\nIntroduced in commit 1234567.')"
  [ "$status" -eq 2 ]
}

@test "honours SKIP_GINEE_COMPLIANCE=1" {
  SKIP_GINEE_COMPLIANCE=1 run invoke_hook "$(write_payload 'local/requirements.md' 'See src/x.ts:42.')"
  [ "$status" -eq 0 ]
}
