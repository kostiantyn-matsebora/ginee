# Backend Engineer — Domain Elaboration

Companion to `core/roles/backend-engineer.md`. The kernel file holds normative rules; this file holds elaboration, patterns, and stack-specific guidance.

## Workspace layout

Tree + dependency rules: `local/bindings.md` → "Repository structure" → server tier. Generic invariants:

- Executable / deployable host(s) and library projects are separated as the architecture mandates. Don't conflate them.
- Cross-tier shared code lives in a `shared/` (or equivalent) tier. Do not import from one feature library into another.
- Auth / API-key / authz middleware is applied at composition time at the host boundary, on the specific endpoint groups the architecture doc names. Never global when the architecture says scoped; never scoped when the architecture says global.
- Unit tests live alongside their source project.

## Declarative configuration — backend specifics

Per `core/process.md` § Configuration vs. data:

- Configuration → app-settings / env-files / environment variables. Never as string literals inside controllers, services, or middleware.
- Hosted-service defaults (e.g. retention windows) come from configuration; single explicit default at the binding site, not hardcoded fallbacks scattered through code.
- Test fixtures and expected data live in declarative resources (`*.json` test resources, data-driven test rows derived from a documented source). No inline literals when the source is a documented fixture file.
- "For production X, for dev Y" inside source code is a configuration concern — push into config files or env vars.

## Stack — generic rules

Canonical stack: `local/bindings.md` → "Stack". The specific language, web framework, ORM, database, and realtime mechanism are project-specific. Generic invariants:

| Concern | Rule |
|---|---|
| Web framework | Whatever `local/bindings.md` records. Do not introduce a parallel framework. |
| ORM / persistence | Whatever `local/bindings.md` records. Honour migration conventions. |
| Storage for unit tests | Whatever `local/bindings.md` records (in-memory, embedded, or Testcontainers). |
| Auth on writes | Per architecture-doc § Security. |
| Container port | Per `local/bindings.md`. |

Do NOT introduce in-memory event buses, caching layers, mapper libraries, validation libraries when built-ins suffice, or any cloud-proprietary SDK that breaks platform agnosticism unless the architecture doc mandates it.

## Network topology — what the service serves

Read `local/bindings.md` → "Network topology" for project specifics. Common patterns:

- Service serves wire data (JSON / RPC) only — no static-asset middleware, no SPA fallback route. The client SPA ships in its own container behind the same gateway.
- Service container is **internal-only** in dev/prod orchestration — reached exclusively via a reverse-proxy / gateway. No CORS headers if the project is single-origin via gateway.
- Adjust per project: if the project hosts the SPA inside the service, the architecture doc says so and the rule above does not apply.

## Real-time path (when the project has one)

Generic shape (adapt to the project's specific mechanism):

1. After a successful write commit, publish a notification — never before commit.
2. Read side opens a long-lived subscription to the broker via a dedicated connection (not from the request-scoped pool).
3. Realtime writer formats per the architecture-doc event-format section. Honour resume-token / replay semantics; a small in-memory ring buffer for best-effort replay is acceptable when the broker doesn't replay.
