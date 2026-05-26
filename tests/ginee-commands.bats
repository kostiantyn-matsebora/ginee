#!/usr/bin/env bats
# Bash-port coverage for adapters/claude/commands/ (T10 / #146).
# Run from WSL / Linux: bats tests/ginee-commands.bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  CMD_DIR="$REPO_ROOT/adapters/claude/commands"
}

@test "directory ships exactly the 6 documented commands" {
  expected=(ginee-dispatch ginee-phase-report ginee-self-lint ginee-commit ginee-pr ginee-issue-pickup)
  actual=()
  for f in "$CMD_DIR"/ginee-*.md; do
    name="$(basename "$f" .md)"
    actual+=("$name")
  done
  [ "${#actual[@]}" -eq 6 ]
  for e in "${expected[@]}"; do
    found=0
    for a in "${actual[@]}"; do [ "$a" = "$e" ] && found=1 && break; done
    [ "$found" -eq 1 ] || { echo "missing: $e"; return 1; }
  done
}

@test "every command has YAML frontmatter with description" {
  for f in "$CMD_DIR"/ginee-*.md; do
    grep -qE '^---$' "$f"
    grep -qE '^description:[[:space:]]*\S' "$f"
  done
}

@test "ginee-dispatch contains the 5 required dispatch-prompt sections" {
  f="$CMD_DIR/ginee-dispatch.md"
  grep -qE '^##[[:space:]]+Reading list'   "$f"
  grep -qE '^##[[:space:]]+Task'           "$f"
  grep -qE '^##[[:space:]]+Read discipline' "$f"
  grep -qE '^##[[:space:]]+Deliverable'    "$f"
  grep -qE '^##[[:space:]]+Required output' "$f"
  grep -qE '<!-- self-lint: pass -->'      "$f"
}

@test "ginee-phase-report contains every required phase-report section" {
  f="$CMD_DIR/ginee-phase-report.md"
  grep -qE 'Status:[[:space:]]+Done'                    "$f"
  grep -qE '^##[[:space:]]+Files touched'               "$f"
  grep -qE '^##[[:space:]]+Decisions made'              "$f"
  grep -qE '^##[[:space:]]+Verification log'            "$f"
  grep -qE '^##[[:space:]]+Open issues'                 "$f"
  grep -qE '^##[[:space:]]+Next dispatch needed'        "$f"
  grep -qE '^##[[:space:]]+Source reads \(this dispatch\)' "$f"
  grep -qE '<!-- self-lint: pass -->'                   "$f"
}

@test "ginee-self-lint enumerates 7 numbered checks + advisory rule" {
  f="$CMD_DIR/ginee-self-lint.md"
  count="$(grep -cE '^[[:space:]]*[1-9]+\.[[:space:]]+\*\*' "$f")"
  [ "$count" -ge 7 ]
  grep -qE 'never re-dispatch for format' "$f"
}

@test "ginee-commit puts Closes #N inside the body, not after trailers" {
  f="$CMD_DIR/ginee-commit.md"
  # Extract the fenced skeleton block carrying Closes #<N>; assert order within it.
  skeleton="$(awk '/^```$/{flag=!flag;next} flag' "$f" | awk '/Closes #<N>/{p=1} p')"
  [ -n "$skeleton" ]
  closes_line="$(printf '%s\n' "$skeleton" | grep -n 'Closes #<N>' | head -1 | cut -d: -f1)"
  optimized_line="$(printf '%s\n' "$skeleton" | grep -n 'Optimized-By: ai-engineer' | head -1 | cut -d: -f1)"
  co_line="$(printf '%s\n' "$skeleton" | grep -n 'Co-Authored-By: Claude Opus' | head -1 | cut -d: -f1)"
  [ -n "$closes_line" ] && [ -n "$optimized_line" ] && [ -n "$co_line" ]
  [ "$closes_line" -lt "$optimized_line" ]
  [ "$closes_line" -lt "$co_line" ]
  grep -qE 'git interpret-trailers' "$f"
}

@test "ginee-pr cites the pr-description template + heredoc pattern" {
  f="$CMD_DIR/ginee-pr.md"
  grep -qE 'core/templates/pr-description\.md' "$f"
  grep -qE '^##[[:space:]]+What'      "$f"
  grep -qE '^##[[:space:]]+Why'       "$f"
  grep -qE '^##[[:space:]]+Cites'     "$f"
  grep -qE '^##[[:space:]]+Issue linkage' "$f"
  grep -qE 'gh pr create'             "$f"
  grep -qE 'HEREDOC'                  "$f"
}

@test "ginee-issue-pickup cites comments + sub-issues + scoring + sticky" {
  f="$CMD_DIR/ginee-issue-pickup.md"
  grep -qE 'core/skills/ginee-pick-up/SKILL\.md' "$f"
  grep -qE 'gh issue view .* --comments'         "$f"
  grep -qE 'sub_issues'                          "$f"
  grep -qE 'core/protocols/triage-scoring\.md'   "$f"
  grep -qE 'ginee:score v=1'                     "$f"
}
