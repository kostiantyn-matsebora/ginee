# GitHub Copilot CLI adapter

For projects using [GitHub Copilot CLI](https://docs.github.com/en/copilot/concepts/agents/copilot-cli).

The 7 cardinal roles install as native Copilot custom subagents at `.github/agents/<role>.agent.md`.

## Capability tier — **1** (native subagents + parallel dispatch)

Verified against:

- Copilot CLI GA (Feb 2026) + `/fleet` command (Apr 2026) — parallel subagent orchestration.
- Custom-agents SDK — NLP-based subagent invocation (direct mention by name) + automatic routing.

Re-check per release.

## What this adapter ships

| Path | What it is |
|---|---|
| `README.md` | This file |
| `install.md` | Step-by-step install procedure |

**Subagent pointer files:**
- Live in `.agents/ginee/adapters/_shared/agents/*.md`.
- Shared with the Claude Code adapter.
- Install copies them into `.github/agents/` and renames to `.agent.md`.
- No duplication.

## How it works

Copilot CLI custom-agent files use the `.agent.md` extension with YAML front-matter.

Shared pointer files carry only:

- Front-matter (`name`, `description`) — Copilot CLI's routing fields.
- A 4-line body instructing the subagent to read:
  - `.agents/ginee/core/roles/<role>.md` (canonical charter)
  - `core/process.md`
  - `local/bindings.md`
  - `local/project-profile.md`

Key properties:
- Canonical role definitions live once in `core/roles/`.
- Subagent files are pure pointers.

## Pointer for AGENTS.md (recommended)

- Copilot CLI also reads `AGENTS.md` at the project root.
- Install the `agents-md` adapter alongside this one for cross-tool consistency.

## Smoke test

1. Install per `install.md`.
2. Open Copilot CLI: `copilot`
3. Mention a role: `@project-manager status` — confirm it loads.
4. Run a parallel iteration via `/fleet`:
   ```
   /fleet plan a 3-task implementation for FEATURE-X, dispatch frontend-engineer and backend-engineer in parallel per the iteration protocol
   ```

## Custom roles

1. Place custom subagent definitions in `.agents/ginee/local/roles/<role>.md`.
2. Create a matching `.github/agents/<role>.agent.md` thin pointer.
