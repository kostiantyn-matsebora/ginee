# INSTRUCTIONS.md — Engineering Team Framework (generic fallback)

Project uses the [`ginee`](.agents/ginee/) framework — vendor-neutral multi-agent collaboration model + generic engineering process.

**When to use:**
- LLM client doesn't natively support AGENTS.md, CLAUDE.md, GEMINI.md, or per-tool subagent directories.
- Manually point your client at this file as its instructions / system-prompt context.

## Read before any work

1. `.agents/ginee/core/process.md` — process spec (lifecycle, dispatch & parallelism, iteration protocol, doc co-ownership, task model, post-acceptance hooks).
2. `.agents/ginee/local/bindings.md` — project routing, role boundaries, stack.
3. `.agents/ginee/local/project-profile.md` — discovered project context.

## Cardinal roles (read on demand)

| Role | Charter at | Alias |
|---|---|---|
| `project-manager` | `.agents/ginee/core/roles/project-manager.md` | — (orchestrator) |
| `solution-architect` | `.agents/ginee/core/roles/solution-architect.md` | architect |
| `ai-engineer` | `.agents/ginee/core/roles/ai-engineer.md` | context-engineer |
| `frontend-engineer` | `.agents/ginee/core/roles/frontend-engineer.md` | client-engineer |
| `backend-engineer` | `.agents/ginee/core/roles/backend-engineer.md` | service-engineer |
| `devops-engineer` | `.agents/ginee/core/roles/devops-engineer.md` | platform-engineer |
| `qa-engineer` | `.agents/ginee/core/roles/qa-engineer.md` | quality-engineer |

## Custom roles

- Location — `.agents/ginee/local/roles/`.
- Source — copy from `.agents/ginee/extras/roles/` or author per `.agents/ginee/core/templates/role-authoring-template.md`.

## Orchestration

- **Dispatch.**
  - Mention the role by name, or describe the task surface.
  - The LLM acts as that persona.
- **Orchestrator.** `project-manager`.
- **First install.** Prompt `act as project-manager and run initial discovery`.

## Coordination rules (always apply)

| Rule | What | Reference |
|---|---|---|
| Strict-domain | No role works outside its domain. | `core/process.md § Strict-domain rule` |
| Estimation-first dispatch | Phase 4/5/6 work > 15 min — dispatched role responds first with task decomposition + per-task estimates. | — |
| Iteration protocol | Scope > 15 min — work in 3–5 min batches with visible intermediate results. | — |
| Doc co-ownership | `solution-architect` owns documentation semantics; `ai-engineer` owns shape + load topology. | — |
| SAD freeze + CR/ADR | After SAD finalized — requirements changes → `docs/cr/`; architecture changes → `docs/adr/`. | — |

## Capability tier — **3** (instructions-only, no native role routing)

Generic fallback. Behavior:
- LLM impersonates each cardinal persona when mentioned.
- No multi-agent isolation.
- Sequential execution.
- No parallel dispatch.

For tier-1 or tier-2 clients, use one of:

| Adapter | Tier | Clients |
|---|---|---|
| `.agents/ginee/adapters/claude/` | 1 | Claude Code |
| `.agents/ginee/adapters/copilot-cli/` | 1 | Copilot CLI |
| `.agents/ginee/adapters/agents-md/` | 2 | Codex / Cursor / Windsurf / Amp / Devin / Factory / Jules / Copilot IDE |
