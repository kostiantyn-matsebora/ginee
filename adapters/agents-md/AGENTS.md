# AGENTS.md — Engineering Team Framework

Project uses the [`ginee`](.agents/ginee/) framework — vendor-neutral multi-agent collaboration model + generic engineering process.

## Read before any work

1. `.agents/ginee/core/process.md` — process spec (lifecycle, dispatch & parallelism, iteration protocol, doc co-ownership, task model, post-acceptance hooks).
2. `.agents/ginee/local/bindings.md` — project routing, role boundaries, stack.
3. `.agents/ginee/local/project-profile.md` — discovered project context.

## Cardinal roles (read on demand)

| Role | Charter at | Alias |
|---|---|---|
| `team-lead` | `.agents/ginee/core/roles/team-lead.md` | — (orchestrator) |
| `solution-architect` | `.agents/ginee/core/roles/solution-architect.md` | architect |
| `ai-engineer` | `.agents/ginee/core/roles/ai-engineer.md` | context-engineer |
| `frontend-engineer` | `.agents/ginee/core/roles/frontend-engineer.md` | client-engineer |
| `backend-engineer` | `.agents/ginee/core/roles/backend-engineer.md` | service-engineer |
| `devops-engineer` | `.agents/ginee/core/roles/devops-engineer.md` | platform-engineer |
| `qa-engineer` | `.agents/ginee/core/roles/qa-engineer.md` | quality-engineer |

## Custom roles (project-specific)

- Location — `.agents/ginee/local/roles/`.
- Source — copy from `.agents/ginee/extras/roles/` (security, ml, mobile, sre, data) or author per `.agents/ginee/core/templates/role-authoring-template.md`.

## Orchestration

- **Dispatch.** Mention the role that owns the surface (e.g. `@frontend-engineer`, `@solution-architect`).
- **Orchestrator.** `team-lead`. Invoke for:
  - Ambiguous scope.
  - First-run discovery.
- **First install.** Prompt `@team-lead run initial discovery`. Produces:
  - `local/project-profile.md`
  - `local/bindings.md`
  - `local/framework.config.yaml`

## Coordination rules (always apply)

| Rule | What | Reference |
|---|---|---|
| Strict-domain | No role works outside its domain. | `core/process.md § Strict-domain rule` |
| Estimation-first dispatch | Phase 4/5/6 work > 15 min — dispatched role responds first with task decomposition + per-task estimates. | `core/protocols/iteration-protocol.md` |
| Iteration protocol | Scope > 15 min — work in 3–5 min batches with visible intermediate results. | `core/protocols/iteration-protocol.md` |
| Doc co-ownership | `solution-architect` owns documentation semantics; `ai-engineer` owns shape + load topology. | `core/process.md § Doc co-ownership` |
| SAD freeze + CR/ADR | After SAD finalized — requirements changes → `docs/cr/`; architecture changes → `docs/adr/`. | `core/roles/solution-architect.md § SAD freeze + change governance` |
