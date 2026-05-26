# Migration — PostToolUse self-check reminder (core/** edits)

**Target release:** next minor after 2026-05-26.
**Affected adopters:** Claude Code adapter only.
**Closes:** [#142](https://github.com/kostiantyn-matsebora/ginee/issues/142).
**Parent:** [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135) — tactic 6 / Tier 2, Class B force.

## What changed

A new cross-platform PostToolUse hook lives at:

- `adapters/claude/hooks/post-tool-use-edit.ps1` — PowerShell (primary).
- `adapters/claude/hooks/post-tool-use-edit.sh` — bash port (jq-dependent).

When `.claude/settings.json` wires this hook into the existing `hooks.PostToolUse` entry for `Edit|Write|MultiEdit`, Claude Code invokes it after each edit completes. It coexists with `scripts/context-economy-check.ps1` (already wired in the same entry); the structural gate fires first (JSON-shaped lint output), the self-check follows (LLM-facing `hookSpecificOutput.additionalContext` reminder).

The hook is **path-aware**: it fires only when the resolved file path begins with `core/`. Edits in `tests/**`, `local/**`, `adapters/**`, `extras/**`, `migrations/**` pass through silently.

Injection body (≤ 6 lines):

```
[ginee:self-check] You just edited <path>. Verify before continuing:
- frontmatter present + valid (hot-spec contract: core/protocols/hot-spec-format.md)
- size <= cap-bytes; if exceeded, dispatch ai-engineer + commit with Optimized-By: ai-engineer trailer
- runtime surface stayed D-free (no bare D<N> tokens introduced — PLAN.md only)
- lossless invariant: every prior rule survives byte-for-byte
- always-loaded surface: consider whether an ai-engineer optimization pass is needed before merge   ← only on core/process.md or core/roles/<role>.md (excluding *.details.md)
```

## Why

Parent issue #135 § Force taxonomy — Class B (action-time injection) succeeds but injects a reminder before the next action. The dominant failure mode for `core/**` edits was the LLM completing the edit successfully (structural gate green) and then forgetting to verify the lossless / D-free / cap-bytes invariants before the *next* edit. T6 plants the self-check reminder in the LLM's context window immediately after each successful edit so the next action sees it.

Pairs with T2 (#138) — T2 blocks at action-time when an invariant is violated; T6 reinforces *between* actions when the invariant is technically satisfied but the chain of edits may drift. Six lines per fire is the ceiling per parent #135's anti-pattern: longer reminders tune out.

## Architecture

| Surface | Owns |
|---|---|
| Hook script (`post-tool-use-edit.{ps1,sh}`) | Read payload · resolve repo root · check opt-out · path-gate to `core/**` · compose 5- or 6-line reminder · emit stdout JSON with `hookSpecificOutput.additionalContext` |
| `.claude/settings.json § hooks.PostToolUse` | The hook is appended to the existing entry whose matcher is `Edit\|Write\|MultiEdit` (next to the structural context-economy gate). Both run; order is sync-script-defined |
| `local/framework.config.yaml § compliance.disabled: [posttooluse-edit-hook]` | Per-tactic opt-out |

The hook is **pure** over the payload — no side effects, no git read, no network. Always-loaded detection is path-only (`core/process.md` + `core/roles/*.md` minus `*.details.md` siblings); the hook does not parse frontmatter at runtime to keep cost negligible.

## Verification

| Step | Expected |
|---|---|
| Pester — `tests/post-tool-use-edit.Tests.ps1` | 14 / 14 pass — parse-clean · 6 pass-through (non-Edit, empty, malformed, tests/, adapters/, local/) · 6 core/** injection · 1 opt-out |
| bats — `tests/post-tool-use-edit.bats` | 13 / 13 pass — equivalent surface against the `.sh` port |
| Manual smoke — `echo '{"tool_name":"Edit","tool_input":{"file_path":"core/process.md"}}' \| pwsh -F adapters/claude/hooks/post-tool-use-edit.ps1` | stdout JSON contains `[ginee:self-check]` + `always-loaded surface` reminder |

## Decisions affected

- **#135 parent playbook** — sixth tactic shipped. Establishes the post-edit reminder pattern (Class B).
- **Structural / behavioural separation on PostToolUse.** `scripts/context-economy-check.ps1` (existing) reports structural lint as JSON. `post-tool-use-edit.ps1` (new) reports LLM-facing reminders as `additionalContext`. The two are co-tenant on the same matcher — adopters' `.claude/settings.json` lists them in order under one PostToolUse entry.

## Forward-only

Purely additive — 2 hook scripts + 2 test files + 1 PostToolUse hook command appended to the existing entry in `.claude/settings.json.example`. `core/scripts/sync-claude-settings.{ps1,sh}` was extended with a sibling-aware merge helper that locates the existing context-economy entry and appends the new command to its `hooks` array (rather than creating a duplicate PostToolUse entry).

## Out of scope

- **Frontmatter-driven always-loaded detection at runtime.** The hook uses a path allow-list (`core/process.md` + `core/roles/*.md` minus `*.details.md`) for speed. If/when the always-loaded set grows beyond those two patterns, switch to frontmatter parsing.
- **Cross-adapter parity.** Cursor / Copilot / Codex / generic have no PostToolUse equivalent today.
- **Per-violation opt-out.** Single tactic-id `posttooluse-edit-hook`.
