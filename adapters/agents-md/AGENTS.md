# AGENTS.md — Engineering Team Framework

This project uses the [`engineering-team`](.agents/engineering-team/) framework — a vendor-neutral multi-agent collaboration model + generic engineering process.

## Read before any work

1. `.agents/engineering-team/core/process.md` — the team's process spec (lifecycle, dispatch & parallelism rules, iteration protocol, doc co-ownership, task model, post-acceptance hooks)
2. `.agents/engineering-team/local/bindings.md` — this project's specific routing, role boundaries, stack
3. `.agents/engineering-team/local/project-profile.md` — discovered project context

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

- `.agents/engineering-team/local/roles/` — copy from `.agents/engineering-team/extras/roles/` (curated specialists: security, ml, mobile, sre, data) or author per `.agents/engineering-team/core/templates/role-authoring-template.md`.

## Orchestration

Dispatch any task by mentioning the role that owns the surface (e.g. `@frontend-engineer`, `@solution-architect`). The orchestrator is `project-manager` — invoke it for ambiguous scope or first-run discovery.

**On first install**, prompt: `@project-manager run initial discovery`. This produces `local/project-profile.md` + `local/bindings.md` + `local/framework.config.yaml`.

## Coordination rules (always apply)

- **Strict-domain rule** — no role works outside its domain. See `core/process.md § Strict-domain rule`.
- **Estimation-first dispatch** — for Phase 4/5/6 work > 15 min, the dispatched role responds first with task decomposition + per-task estimates. See `core/process.md § Iteration protocol`.
- **Iteration protocol** — for scope > 15 min, work in 3–5 min batches with visible intermediate results. See `core/process.md § Iteration protocol`.
- **Doc co-ownership** — `solution-architect` owns documentation semantics; `ai-engineer` owns shape and load topology. See `core/process.md § Doc co-ownership`.
- **SAD freeze + CR/ADR governance** — once SAD is finalized, requirements changes go to `docs/cr/` and architecture changes to `docs/adr/`. See `core/roles/solution-architect.md § SAD freeze + change governance`.
