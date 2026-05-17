# DevOps Engineer — Domain Elaboration

Companion to `core/roles/devops-engineer.md`. The kernel file holds normative rules; this file holds elaboration, patterns, and stack-specific guidance.

## Hard constraints — devops implications

Canonical NFR list: `local/bindings.md` → "Hard constraints". Common devops-relevant patterns:

| Constraint | Implication |
|---|---|
| Single-cloud constraint | Stay within the project's chosen cloud. No mixing providers without an architecture-doc update. |
| Cost cap | Stay within the documented monthly budget. Any SKU bump needs explicit approval + doc update. |
| Internal-only / private networking | No public ingress on the application tier. External access via VPN, private endpoint, or a single hardened gateway. |
| Statelessness | Load-balancer / ingress config must not pin realtime clients to instances. Reconnects use resume tokens. |
| IaC-defined | No clickops in the cloud console. Every resource has an IaC definition. |
| Platform agnosticism | Standard containerised app on any OCI-compliant host. No proprietary compute-model bindings unless the architecture doc explicitly allows. |
| Retention (data) | Storage / backup settings preserve recoverability; any pruning job (typically backend-owned) defaults to the documented window. |

## IaC layout (generic shape)

Adapt to the project's chosen IaC tool. Common patterns:

- One root module per environment workspace (`dev`, `prod`) with per-environment variable files.
- Submodules for cross-cutting concerns:
  - `naming`
  - `network`
  - `<database>`
  - `<container-registry>`
  - `<container-runtime>-environment`
  - `<container-runtime>-app` (reused per service)
  - `<secret-vault>`
- Backend state:
  - Stored remotely (cloud-storage / IaC-tool-cloud / etc.).
  - One state per workspace.
  - State files **never** in repo.
- Every secret read from the secret vault by reference at runtime, not from variable files.
- Pin provider / module versions; pin patch versions to avoid drift.

## Container ownership

Files you own beyond the application-tier repo-structure tree (paths per `local/bindings.md`):

| File class | Notes |
|---|---|
| Gateway / reverse-proxy container | Single public-facing edge; routes by path + method per architecture doc. Only container with public ingress in the typical topology. |
| Client SPA container (when SPA is statically hosted) | Multi-stage: build stage runs the SPA build → runtime stage copies the dist into a static-serving image. Runtime image serves static + SPA history fallback. NO upstream proxying — gateway handles that. |
| Service container(s) | SDK → runtime; no SPA stage when the service is wire-only; internal-only at runtime. |
| Local-dev compose / orchestration | `dev_env/` (or per-project equivalent). |
| Scaled-validation compose / orchestration | Multi-replica setup to validate statelessness. |
| Local startup / teardown scripts | `start`, `stop` scripts (PowerShell / shell). |
| IaC modules + per-env roots | Per the project's IaC tool. |
| CI workflows | Release + PR validation. |
| Composite / reusable CI actions | Per the project's CI tool. |

## Container images

Generic rules:

- One image per deployable component.
  - All share one orchestration environment.
- Multi-stage builds; runtime images stay minimal.
- Each runtime image `EXPOSE`s the documented port.
- Tag with the git SHA and (optionally) `latest`.
  - Production references by digest, not tag.

## CI/CD pipelines

Generic shape (adapt to the project's CI tool):

- **PR validation workflow** — steps:
  1. Restore deps.
  2. Build.
  3. Unit test.
  4. Integration build (no push).
  5. IaC-tool `fmt` + `validate`.
  6. Script-suite tests (Pester / shellcheck / etc.) for any composite/script logic.
- **Release workflow** (on merge to the project's release branch) — steps:
  1. Build images.
  2. Push to the project's registry.
  3. Run schema migrations as a one-shot job against target DB.
  4. Update the deployed application to the new image digest.
  5. Run the smoke suite owned by `qa-engineer`.
- Secrets:
  - Stored in the CI tool's environment-secret mechanism with required reviewers on `prod`.
  - Never in workflow files or repo source.
- Document which secrets the application requires + which secrets each integration step requires in the architecture doc; mirror summaries in `local/bindings.md`.

## Database operational notes (when the project has one)

- SKU sized per the cost cap; HA/replica strategy per NFRs.
- Private access (vnet-injected / VPC-private); no public IP unless the architecture doc allows.
- Enable point-in-time restore (PITR) / equivalent — covers retention NFR from an ops perspective.
- Backups:
  - Keep automatic backups on.
  - Document the restore runbook alongside the IaC.

## Smoke after every deploy

You own deploy mechanics; `qa-engineer` provides the smoke suite. After IaC apply + image update:

1. Health endpoint returns success.
2. Real-time endpoint accepts subscriptions; post a tagged event; receive it within the documented latency budget.
3. Client loads from the gateway endpoint.
4. Persistence-layer schema matches the migration (run a schema diff).

Adjust per project specifics.
