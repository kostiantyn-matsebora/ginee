#!/usr/bin/env bats
# T11 / #147 — warm-cardinal-default migration coverage (bash port of Pester sibling).
# Run from WSL / Linux: bats tests/warm-cardinal-default.bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  MIGRATION="$REPO_ROOT/migrations/warm-cardinal-default.md"
  WARM_SPEC="$REPO_ROOT/migrations/warm-specialist-reuse.md"
  CFG_TEMPLATE="$REPO_ROOT/core/templates/framework.config.yaml"
}

@test "migration spec cites parent #135 and predecessor migrations" {
  grep -q '#135'                                  "$MIGRATION"
  grep -q 'warm-specialist-reuse\.md'             "$MIGRATION"
  grep -q 'warm-reuse-claude-plumbing\.md'        "$MIGRATION"
  grep -q 'cardinal-tools-whitelist\.md'          "$MIGRATION"
  grep -q 'pretooluse-edit-hook\.md'              "$MIGRATION"
}

@test "migration spec documents framework-scoped deny rules" {
  grep -qF 'Edit(.agents/ginee/core/**)'        "$MIGRATION"
  grep -qF 'Write(.agents/ginee/adapters/**)'   "$MIGRATION"
  grep -qF 'MultiEdit(.agents/ginee/extras/**)' "$MIGRATION"
  grep -qF 'Bash(rm -rf:*)'                     "$MIGRATION"
  grep -qF 'Bash(git push --force:*)'           "$MIGRATION"
  grep -qF 'Bash(git reset --hard:*)'           "$MIGRATION"
}

@test "migration spec documents the main-thread-permissions opt-out tactic-id" {
  grep -qE 'compliance\.disabled:[[:space:]]*\[main-thread-permissions\]' "$MIGRATION"
}

@test "migration spec enumerates the dispatch-count soft cap default 15" {
  grep -qE 'warm-reuse\.dispatch-cap' "$MIGRATION"
  grep -qE 'default 15'               "$MIGRATION"
}

@test "migration spec documents Carry-forward summary handoff format" {
  grep -qE '^##[[:space:]]+Carry-forward summary' "$MIGRATION"
  grep -q 'Key decisions to inherit'              "$MIGRATION"
  grep -q 'Open work items'                       "$MIGRATION"
  grep -q 'Re-read before proceeding'             "$MIGRATION"
}

@test "warm-specialist-reuse spec gains dispatch-cap trigger row" {
  grep -q 'dispatch-cap'              "$WARM_SPEC"
  grep -q 'warm-cardinal-default\.md' "$WARM_SPEC"
}

@test "framework.config.yaml template documents warm-reuse.dispatch-cap default 15" {
  awk '/warm-reuse:/{found=1} found && /dispatch-cap:[[:space:]]+15/{ok=1} END{exit !ok}' "$CFG_TEMPLATE"
}

@test "framework.config.yaml template lists T11 tactic-id main-thread-permissions" {
  grep -q 'main-thread-permissions' "$CFG_TEMPLATE"
}
