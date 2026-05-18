---
title: Reference — Role kernels
description: "The 7 cardinals + 5 specialists. What each owns, what each must NOT edit, source-of-truth tables with load triggers."
permalink: /reference/ROLES.html
---

# Role kernels

> Navigator page. The canonical role kernels live in the repo. Each ~80–150 lines.

## Cardinals (always present)

| Role | Canonical kernel | Details (load-on-demand) |
|---|---|---|
| `team-lead` | [`core/roles/team-lead.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/roles/team-lead.md) | [`core/roles/team-lead.details.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/roles/team-lead.details.md) |
| `solution-architect` | [`core/roles/solution-architect.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/roles/solution-architect.md) | [`core/roles/solution-architect.details.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/roles/solution-architect.details.md) |
| `ai-engineer` | [`core/roles/ai-engineer.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/roles/ai-engineer.md) | [`core/roles/ai-engineer.details.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/roles/ai-engineer.details.md) |
| `frontend-engineer` | [`core/roles/frontend-engineer.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/roles/frontend-engineer.md) | [`core/roles/frontend-engineer.details.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/roles/frontend-engineer.details.md) |
| `backend-engineer` | [`core/roles/backend-engineer.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/roles/backend-engineer.md) | [`core/roles/backend-engineer.details.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/roles/backend-engineer.details.md) |
| `devops-engineer` | [`core/roles/devops-engineer.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/roles/devops-engineer.md) | [`core/roles/devops-engineer.details.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/roles/devops-engineer.details.md) |
| `qa-engineer` | [`core/roles/qa-engineer.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/roles/qa-engineer.md) | [`core/roles/qa-engineer.details.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/roles/qa-engineer.details.md) |

## Specialists (opt-in via `extras/roles/`)

| Role | When to enable | Canonical |
|---|---|---|
| `security-engineer` | Project has auth / secret / network-policy NFRs | [`extras/roles/security-engineer.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/extras/roles/security-engineer.md) |
| `ml-engineer` | Project ships an ML model, training pipeline, or serving tier | [`extras/roles/ml-engineer.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/extras/roles/ml-engineer.md) |
| `mobile-engineer` | Project includes a native iOS / Android / cross-platform mobile client | [`extras/roles/mobile-engineer.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/extras/roles/mobile-engineer.md) |
| `sre` | Project has SLOs, runbooks, or post-deploy operational requirements | [`extras/roles/sre.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/extras/roles/sre.md) |
| `data-engineer` | Project has a data warehouse, lake, orchestrator, or dataset catalog | [`extras/roles/data-engineer.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/extras/roles/data-engineer.md) |

## Custom roles

Author under `local/roles/<your-role>.md` using [`core/templates/role-authoring-template.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/templates/role-authoring-template.md).

`team-lead` discovers new `local/roles/*.md` files on next dispatch — no registration needed.

## Role kernel anatomy

Every cardinal kernel has the same shape (skim a single one to learn the pattern):

1. **Front-matter** — `name`, `description` (when to dispatch + what NOT to do), `aliases` (generic synonyms).
2. **`## Source of truth`** — two-tier load table (`always` + scope-loaded with trigger phrase). Per-file `Load when` column.
3. **`## Estimation-first dispatch`** — iteration-protocol entry point for work &gt; 15 min.
4. **Domain-specific sections** — wire contract / mockup ownership / cost cap / etc.
5. **`## Forbidden actions (strict-domain)`** — role-specific negations. Hard stops.
6. **`## Reporting`** — what the final report must include.

## Generic aliases

Each cardinal carries `aliases` in its front-matter so adopters can use the more generic name if it fits their project:

| Cardinal | Aliases |
|---|---|
| `frontend-engineer` | `client-engineer`, `ui-engineer` |
| `backend-engineer` | `service-engineer`, `server-engineer` |
| `devops-engineer` | `platform-engineer`, `sre-light`, `infra-engineer` |
| `qa-engineer` | `quality-engineer`, `test-engineer`, `sdet` |
| `solution-architect` | `architect`, `system-architect` |

`ai-engineer` is role-name-canonical — no aliases. `team-lead` accepts `orchestrator` + `project-manager` (legacy name pre-2026-05-18) as aliases.
