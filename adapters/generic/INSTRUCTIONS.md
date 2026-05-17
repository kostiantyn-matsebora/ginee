# INSTRUCTIONS.md — Engineering Team Framework (generic fallback)

This project uses the [`engineering-team`](engineering-team/) framework — a vendor-neutral multi-agent collaboration model + generic engineering process.

**Use this file when your LLM client doesn't natively support AGENTS.md, CLAUDE.md, GEMINI.md, or per-tool subagent directories.** Manually point your client at this file as its instructions / system-prompt context.

## Read before any work

1. `engineering-team/core/process.md` — the team's process spec (lifecycle, dispatch & parallelism rules, iteration protocol, doc co-ownership, task model, post-acceptance hooks)
2. `engineering-team/local/bindings.md` — this project's specific routing, role boundaries, stack
3. `engineering-team/local/project-profile.md` — discovered project context

## Cardinal roles (read on demand)

| Role | Charter at | Alias |
|---|---|---|
| `project-manager` | `engineering-team/core/roles/project-manager.md` | — (orchestrator) |
| `solution-architect` | `engineering-team/core/roles/solution-architect.md` | architect |
| `ai-engineer` | `engineering-team/core/roles/ai-engineer.md` | context-engineer |
| `frontend-engineer` | `engineering-team/core/roles/frontend-engineer.md` | client-engineer |
| `backend-engineer` | `engineering-team/core/roles/backend-engineer.md` | service-engineer |
| `devops-engineer` | `engineering-team/core/roles/devops-engineer.md` | platform-engineer |
| `qa-engineer` | `engineering-team/core/roles/qa-engineer.md` | quality-engineer |

## Custom roles

- `engineering-team/local/roles/` — project-specific additions (copy from `engineering-team/extras/roles/` or author per `engineering-team/core/templates/role-authoring-template.md`).

## Orchestration

Mention the role by name or describe the task surface; the LLM acts as that persona. The orchestrator is `project-manager`.

**On first install**, prompt: `act as project-manager and run initial discovery`.

## Coordination rules (always apply)

- **Strict-domain rule** — no role works outside its domain. See `core/process.md § Strict-domain rule`.
- **Estimation-first dispatch** — for Phase 4/5/6 work > 15 min, the dispatched role responds first with task decomposition + per-task estimates.
- **Iteration protocol** — for scope > 15 min, work in 3–5 min batches with visible intermediate results.
- **Doc co-ownership** — `solution-architect` owns documentation semantics; `ai-engineer` owns shape and load topology.
- **SAD freeze + CR/ADR governance** — once SAD is finalized, requirements changes go to `docs/cr/` and architecture changes to `docs/adr/`.

## Capability tier — **3** (instructions-only, no native role routing)

Generic fallback — the LLM impersonates each cardinal persona when mentioned. No multi-agent isolation; sequential execution; no parallel dispatch.

For tier-1 or tier-2 clients, use one of:
- `engineering-team/adapters/claude/` — Claude Code (tier-1)
- `engineering-team/adapters/copilot-cli/` — Copilot CLI (tier-1)
- `engineering-team/adapters/agents-md/` — Codex / Cursor / Windsurf / Amp / Devin / Factory / Jules / Copilot IDE (tier-2)
