# AGENTS.md — Engineering Team Framework

Project uses the [`engineering-team`](.agents/engineering-team/) framework — vendor-neutral multi-agent collaboration model + generic engineering process.

## Read before any work

1. `.agents/engineering-team/core/process.md` — process spec (lifecycle, dispatch & parallelism, iteration protocol, doc co-ownership, task model, post-acceptance hooks).
2. `.agents/engineering-team/local/bindings.md` — project routing, role boundaries, stack.
3. `.agents/engineering-team/local/project-profile.md` — discovered project context.

## Cardinal roles (read on demand)

| Role | Charter at | Alias |
|---|---|---|
| `project-manager` | `.agents/engineering-team/core/roles/project-manager.md` | — (orchestrator) |
| `solution-architect` | `.agents/engineering-team/core/roles/solution-architect.md` | architect |
| `ai-engineer` | `.agents/engineering-team/core/roles/ai-engineer.md` | context-engineer |
| `frontend-engineer` | `.agents/engineering-team/core/roles/frontend-engineer.md` | client-engineer |
| `backend-engineer` | `.agents/engineering-team/core/roles/backend-engineer.md` | service-engineer |
| `devops-engineer` | `.agents/engineering-team/core/roles/devops-engineer.md` | platform-engineer |
| `qa-engineer` | `.agents/engineering-team/core/roles/qa-engineer.md` | quality-engineer |

## Custom roles (project-specific)

- Location — `.agents/engineering-team/local/roles/`.
- Source — copy from `.agents/engineering-team/extras/roles/` (security, ml, mobile, sre, data) or author per `.agents/engineering-team/core/templates/role-authoring-template.md`.

## Orchestration

- **Dispatch.** Mention the role that owns the surface (e.g. `@frontend-engineer`, `@solution-architect`).
- **Orchestrator.** `project-manager` — invoke for ambiguous scope or first-run discovery.
- **First install.** Prompt `@project-manager run initial discovery` → produces `local/project-profile.md` + `local/bindings.md` + `local/framework.config.yaml`.

## Coordination rules (always apply)

| Rule | What | Reference |
|---|---|---|
| Strict-domain | No role works outside its domain. | `core/process.md § Strict-domain rule` |
| Estimation-first dispatch | Phase 4/5/6 work > 15 min — dispatched role responds first with task decomposition + per-task estimates. | `core/process.md § Iteration protocol` |
| Iteration protocol | Scope > 15 min — work in 3–5 min batches with visible intermediate results. | `core/process.md § Iteration protocol` |
| Doc co-ownership | `solution-architect` owns documentation semantics; `ai-engineer` owns shape + load topology. | `core/process.md § Doc co-ownership` |
| SAD freeze + CR/ADR | After SAD finalized — requirements changes → `docs/cr/`; architecture changes → `docs/adr/`. | `core/roles/solution-architect.md § SAD freeze + change governance` |
