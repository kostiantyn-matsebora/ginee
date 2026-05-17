# Project Bindings — `local/bindings.md` Template

This file is **per-project**. It lives at `local/bindings.md`, NOT in `core/`. `project-manager` writes it during the discovery flow; you maintain it as the project evolves.

`local/bindings.md` records project-specific knowledge that the generic process needs to dispatch correctly:

- Role → owned paths/concerns mapping.
- Project role boundaries (forbidden role-crossings table).
- Hard constraints (cost cap, hosting cloud, retention NFR, etc.).
- Project stack ("non-negotiable" list + "do not introduce" list).
- Source-of-truth tie-breaker rules.
- Repository structure overview.

Replace bracketed placeholders. Drop sections that yield no content for the project.

---

# Project Bindings — `<project name>`

## Source of truth (read before any work)

Authoritative files — every role reads them:

| File | Role | Edited by |
|---|---|---|
| `<architecture-doc path>` | Requirements, constraints, components, data model, API contract, decisions | `solution-architect` |
| `<mockup path>` (if present) | Visual + behavioural contract for the client | mockup-owning role (default `frontend-engineer`); `solution-architect` (governance review, no edits) |
| `<ADR directory path>` | Architecture decision records | `solution-architect` |
| `<CR directory path>` | Change requests | `solution-architect` |

**Tie-breaker** (when the architecture doc and the mockup disagree):
- Visual / interactive behaviour → mockup wins; flag the architecture doc for update.
- API / data / stack / infrastructure → architecture doc wins; flag the mockup for update.

Conflict between request / instinct / existing code and the docs → **stop, flag for the owning role**. Doc update lands first, code follows.

## Repository structure

Top-level directories — keep work in the directory that matches the concern.

```
<project root>/
├── <backend or service path>/
├── <frontend or client path>/
├── <infrastructure path>/
├── <local-dev directory>/
├── <testing directory>/
├── <docs directory>/
├── <CI directory>/
└── ...
```

Per-tier dependency rules: `<list per-tier rules here — e.g. "feature libraries may only reference shared; shared may not reference feature libraries">`

## Stack — non-negotiable

| Layer | Choice |
|---|---|
| Server language / framework | `<e.g. C# / .NET 10, ASP.NET Core Minimal API>` |
| Server ORM | `<e.g. EF Core 10 + Npgsql>` |
| Storage | `<e.g. PostgreSQL 16; SQLite in-memory for unit tests>` |
| Real-time | `<e.g. SSE over PostgreSQL LISTEN/NOTIFY>` |
| Client framework | `<e.g. Angular 20 standalone + zoneless + NgRx Signal Store + Tailwind>` |
| Edge / gateway | `<e.g. nginx reverse proxy, single public ingress, no CORS>` |
| Container runtime | `<e.g. OCI-compliant containers, port 8080>` |
| Hosting | `<e.g. Azure Container Apps + Azure Container Registry + Azure Postgres Flexible Server + Azure Key Vault>` |
| IaC | `<e.g. Terraform azurerm ≥ 4.x, state in Azure Storage>` |
| CI/CD | `<e.g. GitHub Actions>` |

## Do not introduce

| Forbidden | Why |
|---|---|
| `<library / pattern / platform>` | `<one line>` |

## Hard constraints (from NFRs)

| Constraint | Source | Implication |
|---|---|---|
| `<e.g. Single-cloud (Azure-only)>` | `<NFR-NN>` | `<implication for code/IaC>` |
| `<e.g. Cost cap ≤ $30/mo>` | `<NFR-NN>` | `<implication>` |
| `<e.g. Live updates within 5 s>` | `<NFR-NN>` | `<implication>` |
| `<e.g. Internal-only; no public ingress>` | `<NFR-NN>` | `<implication>` |
| `<e.g. Stateless backend>` | `<NFR-NN>` | `<implication>` |
| `<e.g. IaC-defined>` | `<NFR-NN>` | `<implication>` |
| `<e.g. ≥ 90 days data retention>` | `<NFR-NN>` | `<implication>` |

A task that would violate any → **stop, propose a doc update first**.

## Roles — deterministic routing

The 7 cardinals + any project-local roles under `local/roles/`. Route work per this table — do not do role-owned work yourself in the orchestrator thread.

| Role | Concerns |
|---|---|
| `project-manager` | Discovery / rediscovery, dispatch routing, parallel / serial decisions, TODO check-ins, lifecycle gate enforcement, post-acceptance doc-optimization hook trigger. |
| `solution-architect` | `<architecture-doc path>`; mockup governance review (no edits); `<CI/CD integration guide path>`; project-instruction file rules / routing / repo-structure; ADRs and CRs; coherence audits; tie-breaker resolution. |
| `frontend-engineer` (alias `client-engineer`) | `<client tier paths>`; `<mockup path>` (HTML/CSS/JS/SVG/embedded fixtures); state management; styling; client-side fetch / realtime. |
| `backend-engineer` (alias `service-engineer`) | `<server tier paths>`; ORM entities / migrations; database schema, indexes; realtime hub; auth middleware; wire-format JSON contract. |
| `devops-engineer` (alias `platform-engineer`) | `<infra path>`; Dockerfiles; compose / orchestration; IaC; CI workflows; reverse-proxy / gateway config; secret provisioning; cost tracking. |
| `qa-engineer` (alias `quality-engineer`) | `<testing path>`; scenario specs; e2e / functional / smoke; harness assertions; fixtures; seed / cleanup scripts. |
| `ai-engineer` | Optimization passes on AI assets + docs; structure / topology / token economy; lossless restructures. Invoked between phases. |
| `<local custom role>` | `<owned paths/concerns>` |

Task spans two roles → dispatch in parallel per `core/process.md` § Dispatch & parallelism rules.

## Project role boundaries

Project-specific forbidden role-crossings table. Each row is a hard stop — propose a hand-off in the final report instead.

| Role | Must NOT edit |
|---|---|
| `solution-architect` | `<mockup path>` (HTML/CSS/JS); `<server source files>`; `<client source files>`; IaC, Dockerfiles, compose, CI workflows. |
| `frontend-engineer` | `<server source files>` (including SQL inside read-API endpoints); IaC, Dockerfiles, CI workflows. |
| `backend-engineer` | `<client source files>`; `<mockup path>`; IaC, Dockerfiles, CI workflows. |
| `devops-engineer` | Project manifests / lockfiles for the application tiers; application source code; client config. |
| `qa-engineer` | `<mockup path>`; production server code; production client code. QA owns test code, fixtures, scenarios, runner scripts — never production surfaces. |
| `ai-engineer` | Any rule / invariant / routing entry / requirement (semantics — owned by `solution-architect`); production code; test code; IaC; CI workflows. |
| `project-manager` | Everything except `local/*` files written during discovery. Orchestrator does not edit production surfaces. |

## Out of scope (do not implement)

Project-specific exclusions:

- `<scope boundary 1 — e.g. "Triggering or managing deployments — system is read-only.">`
- `<scope boundary 2 — e.g. "Multi-tenant or multi-org aggregation.">`
- `<scope boundary 3 — e.g. "Role-based access control on read endpoints — delegated to a sidecar.">`
