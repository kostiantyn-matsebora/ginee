# GitHub Copilot CLI adapter

For projects using [GitHub Copilot CLI](https://docs.github.com/en/copilot/concepts/agents/copilot-cli).

The 7 cardinal roles install as native Copilot custom subagents at `.github/agents/<role>.agent.md`.

## Capability tier — 1 (native subagents + parallel dispatch)

Verified vs Copilot CLI GA (Feb 2026) + `/fleet` (Apr 2026) — parallel subagent orchestration. Custom-agents SDK — NLP-based invocation (mention by name) + automatic routing. Re-check per release.

## How it works

Subagent pointer files live in `.agents/ginee/adapters/_shared/agents/*.md` (shared with Claude Code adapter). Install copies them into `.github/agents/` renamed `.agent.md`. Canonical role definitions live once in `core/roles/`; pointers are thin.

**Pair with `agents-md` adapter** — Copilot CLI also reads `AGENTS.md` at project root.

## Smoke test

1. Install per `install.md`.
2. `copilot` → `@team-lead status` (confirm role loads).
3. Parallel iteration: `/fleet plan a 3-task implementation for FEATURE-X, dispatch frontend-engineer and backend-engineer in parallel per the iteration protocol`.

## Custom roles

1. Definition in `.agents/ginee/local/roles/<role>.md`.
2. Matching thin pointer at `.github/agents/<role>.agent.md`.
