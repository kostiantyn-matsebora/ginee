# Discovery Report Template

`project-manager` produces this on first run (or when the user invokes `@project-manager rediscover`). Surfaces the detected project shape to the user and recommends optional specialists from `extras/roles/`.

Replace bracketed placeholders. Drop sections that yield no content for the project (mark `(none detected)`).

---

## Discovery Report

**Project:** `<project name>` (`<repo root>`)
**Generated:** `<YYYY-MM-DD>`
**Trigger:** `initial discovery | rediscovery | profile-staleness flag`
**By:** `project-manager`

## Detected stack

| Tier | Choice | Evidence |
|---|---|---|
| Primary language(s) | `<e.g. TypeScript / C# / Python / Go>` | `<file(s) that revealed it — package.json, *.csproj, pyproject.toml, go.mod>` |
| Server framework | `<e.g. ASP.NET Core / Express / FastAPI / Spring Boot>` | `<files>` |
| Client framework | `<e.g. Angular / React / Vue / Svelte / Flutter / SwiftUI>` | `<files>` |
| Data store | `<e.g. PostgreSQL / MongoDB / DynamoDB / SQLite>` | `<files>` |
| Real-time mechanism | `<SSE / WebSocket / change-stream / push>` | `<files>` |
| Container runtime | `<Docker / Podman / none>` | `<files>` |
| IaC | `<Terraform / Pulumi / Bicep / none>` | `<files>` |
| CI/CD | `<GitHub Actions / GitLab CI / Azure Pipelines / Jenkins / none>` | `<files>` |

## Detected domain

`<2–4 sentences describing what the project does, derived from README + top-level docs. No invention.>`

## Architecture artefacts (referenced — not copied)

| Concept | Path | Owner per default routing |
|---|---|---|
| Architecture doc | `<path or (none detected)>` | `solution-architect` |
| Mockup | `<path or (none detected)>` | `frontend-engineer` |
| API contract | `<path or (none detected)>` | `backend-engineer` (proposes) → `solution-architect` (ratifies) |
| ADR directory | `<path or (none detected)>` | `solution-architect` |
| CR directory | `<path or (none detected)>` | `solution-architect` |
| Diagrams directory | `<path or (none detected)>` | `solution-architect` |
| Project-instruction file | `<path of CLAUDE.md / .github/copilot-instructions.md / .cursor/rules/*.mdc / etc.>` | per-tool — see adapter |

## SDLC artefacts

| Concept | Path |
|---|---|
| TODO file (root) | `<path or (none detected)>` |
| TODO files (nested) | `<comma-separated paths or (none detected)>` |
| CI workflows | `<paths or (none detected)>` |
| Local-dev startup | `<path or (none detected)>` |
| Local-dev orchestration | `<paths or (none detected)>` |
| Test directories | `<paths or (none detected)>` |
| Fixtures directory | `<path or (none detected)>` |

## Active roles (7 cardinals)

| Role | Status | Bindings file ref |
|---|---|---|
| `project-manager` | always active | n/a |
| `solution-architect` | `active | inactive` | `local/bindings.md` |
| `frontend-engineer` | `active | inactive — no client tier detected` | `local/bindings.md` |
| `backend-engineer` | `active | inactive — no server tier detected` | `local/bindings.md` |
| `devops-engineer` | `active | inactive — no infra/CI detected` | `local/bindings.md` |
| `qa-engineer` | `active | inactive — no test surface detected` | `local/bindings.md` |
| `ai-engineer` | always available (between-phase invocation) | n/a |

## Suggested specialists (from `extras/roles/`)

Recommendations, not enabled. User copies any into `local/roles/` to opt in.

| Specialist | Why suggested |
|---|---|
| `<e.g. security-engineer>` | `<e.g. project contains auth code under `<path>` and `<file>` references encryption — security review surface present>` |
| `<e.g. ml-engineer>` | `<e.g. `<dir>` contains ML training pipelines + model artefacts>` |
| `<e.g. mobile-engineer>` | `<e.g. `<dir>` contains iOS/Android app shell>` |
| `<e.g. sre>` | `<e.g. project declares uptime SLO in `<file>`>` |
| `<e.g. data-engineer>` | `<e.g. project contains ETL pipelines / data warehouse references>` |

## Artefacts written

| Path (absolute) | Source template |
|---|---|
| `local/project-profile.md` | `core/templates/project-profile.md` |
| `local/bindings.md` | `core/templates/bindings.md` |
| `local/framework.config.yaml` | `core/templates/framework.config.yaml` |

## Next step for the user

1. Review the three `local/*` files.
2. Refine `local/bindings.md` if the auto-detected forbidden-role-crossings table needs project-specific entries.
3. (Optional) Copy any suggested specialist from `extras/roles/` into `local/roles/`.
4. Begin work — dispatch `@project-manager <task>` per `core/process.md` § Task model.
