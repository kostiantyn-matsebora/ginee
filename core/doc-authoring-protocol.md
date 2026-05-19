# Doc-authoring protocol — adopter docs (D22)

**Load-on-demand.** Fetched when:

- Any role authors or edits a markdown artefact in an adopter project (architecture doc, ADR, CR, README, runbook, API doc, scenario, phase-report-on-disk).
- `solution-architect` enters Review activity on a doc-touching PR.
- `qa-engineer` adds doc-style to its acceptance criteria.

Default tasks not touching markdown do not load this file.

## Why

Adopter docs are read by **two audiences**:

- **Humans** — devs, stakeholders, oncall. Dense prose hurts scan-time.
- **LLMs** — ginee re-loads adopter docs via `local/index/*`. Dense prose burns tokens before any work has started.

`core/process.md § Documentation style — structure over prose` already declares the rule; D22 promotes it from aspirational to **binding** for adopter outputs and wires per-role discovery + enforcement.

## Principle

Convert prose into the smallest readable structure that preserves every rule. Same charter as `CLAUDE.md § Framework authoring — context economy`, applied to adopter outputs.

## Default-shape map

| Doc artefact | Default shape |
|---|---|
| Component / service / image inventory | Table |
| Endpoint / event / env-var inventory | Table |
| Design properties, invariants, NFRs | Bullet list — one rule per bullet |
| Sequence / workflow / runbook steps | Numbered list |
| Term definitions | `**Term.** Gloss.` lines |
| Trade-off / decision-rationale | Two-column table (option / consequence) |
| Narrative *why* (rationale only) | Prose — tight, < 4 sentences |

## Mandatory checks before report-as-done

1. No paragraph contains > 2 rules (sentence terminators are the heuristic — `. ` `! ` `? `).
2. No table cell contains a multi-sentence sub-paragraph.
3. No bullet runs > 25 words *unless* it carries nested sub-bullets.
4. Inventories (services, components, endpoints, env vars) are tables, not prose.
5. Cross-references cite section anchors (`§Name`, `#anchor`); never restate content.

## Enforcement via discovered stack

ginee does **not** ship a doc linter. Adopter projects already configure markdown / prose tooling — ginee discovers it and triggers it.

| Stage | Mechanism |
|---|---|
| Discovery | `team-lead` records markdown-lint / prose-lint commands in `local/index/commands.yaml § commands.lint.docs` via the existing `builtin:commands` recipe. |
| Discovery (config) | `.markdownlint.json` / `.vale.ini` / `.prettierrc` / `proselint.cfg` records under `local/index/conventions.yaml` via the existing `builtin:conventions` recipe. |
| Author | Role consults this protocol + the discovered config when writing. |
| Enforce | Role runs `${commands.lint.docs}` at Phase 5 / report-as-done; lint output appears in the phase report's Verification log. |
| No tool detected | Discovery report recommends a baseline (markdownlint for structural, vale for prose) under `team-lead` § Discovery flow gap-section. Adopter decides — never auto-install. |

Supported tool families (recognised by the conventions + commands recipes):

- **Structural** — markdownlint / markdownlint-cli2 / prettier (markdown rules).
- **Prose** — vale / proselint / write-good / alex.
- **Cross-refs** — markdown-link-check / lychee.

## Attestation

Phase-report Verification-log entry (one line):

```
Doc-style protocol — <linter command>: PASS / N findings (see <path>).
```

If no linter discovered: `Doc-style protocol — no linter configured; self-checked against § Mandatory checks above.`

## Examples gallery

### 1. Component inventory

**Bad.**

> The system is a microservices architecture with container co-location of the Write + Read API services. Four container images: deployment-dashboard-api, deployment-dashboard-fetcher (optional pull-mode worker), deployment-dashboard-frontend (Angular SPA on nginx), and deployment-dashboard-gateway (nginx routing + SSE pass-through, the only host-published service).

**Good.**

| Image | Tier | Role | Host-published |
|---|---|---|---|
| `deployment-dashboard-api` | service | Write + Read API (co-located per ADR-0002) | no |
| `deployment-dashboard-fetcher` | worker | Optional pull-mode adapter | no |
| `deployment-dashboard-frontend` | client | Angular SPA on nginx | no |
| `deployment-dashboard-gateway` | edge | nginx routing + SSE pass-through | **yes** |

Framing decision in ADR-0006; co-location mechanics in ADR-0002.

### 2. Design properties (README intro)

**Bad.**

> The system is read-only / notification-only: it tracks deployments, it does not trigger them. Tool-agnostic by design — the backend never talks to a CI/CD tool directly; integrators POST to `/api/deployments` from a pipeline step. An optional Dashboard.Fetcher worker can translate pull → push for tools without notify steps.

**Good.**

- **Read-only / notification-only** — tracks deployments; never triggers them.
- **Tool-agnostic** — backend never talks to CI/CD directly. Integrators POST `/api/deployments` from a pipeline step.
- **Pull→push adapter** — optional `Dashboard.Fetcher` worker for tools without notify steps.

### 3. ADR rationale

**Bad.**

> We chose Postgres over MySQL because we need rich JSONB support for the events table, we already operate Postgres in production for the auth service, and the team is more familiar with Postgres tooling, plus the cost difference is negligible at our scale.

**Good.**

| Driver | Postgres | MySQL |
|---|---|---|
| JSONB ergonomics | native, indexable | bolt-on |
| Existing ops experience | auth service already on PG | new operational surface |
| Team familiarity | high | low |
| Cost at our scale | negligible delta | negligible delta |

**Decision:** Postgres. Drivers 1–3 dominate; driver 4 is neutral.

### 4. Runbook procedure

**Bad.**

> If the deployment fails, first check the logs in CloudWatch, then look at the recent deploys in the dashboard, then if you see a pattern of timeouts you should roll back via the deploy CLI, otherwise file an incident in PagerDuty.

**Good.**

1. Read failing-deploy logs — `awslogs get /ecs/<service> --start='-15m'`.
2. Open the deploys dashboard — `<dashboard-url>`.
3. **Decision.**
   - Timeout pattern (≥ 3 of last 5 deploys) → roll back: `deploy rollback <service> <prev-rev>`.
   - Other → file PagerDuty incident with the log link.

### 5. API endpoint table

**Bad.**

> The `/api/deployments` endpoint accepts POST with a JSON body containing service, environment, version, status (succeeded/failed), and an optional commit SHA, returning 202 on accept or 422 on validation failure.

**Good.**

| Method + Path | `POST /api/deployments` |
|---|---|
| Request | `{ service, environment, version, status, commitSha? }` |
| Response 202 | `{ id, receivedAt }` |
| Response 422 | `{ field, error }[]` |
| Auth | bearer (`X-Integrator-Token`) |

### 6. Scenario doc

**Bad.**

> When the user clicks the deploy button, if they are authenticated and have the deploy role and the target environment is not locked, then the system should create a new deployment, log the event, and update the dashboard in real time; otherwise it should show an error.

**Good.**

- **Given** authenticated user with `role:deploy`.
- **And** target environment is not locked.
- **When** user clicks `Deploy`.
- **Then** new deployment created.
- **And** event logged to audit-trail.
- **And** dashboard updates within 500 ms (NFR-04).

Negative paths:

- Missing role → 403, no deployment created.
- Locked environment → 409, no deployment created.

## Bypass

The protocol is binding. Bypass only via explicit user direction recorded in the phase report. Never silent.

## Out of scope

- **Existing adopter docs.** Forward-only — new + edited content follows the protocol. Mass-restructure of legacy docs is a separate user-initiated task.
- **Style preferences.** This protocol governs **structure**, not tone / voice / branding. Adopter style guides own those.
- **Framework-self-dev.** Already covered by D21 + `CLAUDE.md § Framework authoring — context economy`.
