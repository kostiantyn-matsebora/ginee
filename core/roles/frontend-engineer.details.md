# Frontend Engineer — Domain Elaboration

Companion to `core/roles/frontend-engineer.md`. The kernel file holds normative rules; this file holds elaboration, patterns, and stack-specific guidance.

## Same-origin code rules

When the project's deployment topology routes through a single reverse proxy / edge:

- Use **same-origin** fetch URLs (`'/api/...'`, `'/events'`, etc.) — never absolute origin literals.
- Configure the dev server's proxy config to forward `/api/*` (and any realtime endpoint) to the gateway URL locally. Dev and prod use identical relative paths; no environment switching.
- Do not assume any access to backend-served static files — services typically serve JSON only.

When the project has a different topology, follow what `local/bindings.md` documents.

## Workspace layout

Tree + dependency rules: `local/bindings.md` → "Repository structure" → client tier. Enforce via the project's lint config + workspace path mappings. Each library exposes its public surface explicitly; no deep imports across libraries.

Anything that touches browser globals (`EventSource`, `WebSocket`, `localStorage`, `IntersectionObserver`, etc.) lives in the project's `shared/` (or equivalent) tier as a service so feature libraries can unit-test without a DOM.

## Declarative configuration — client specifics

Per `core/process.md` § Configuration vs. data:

- Configuration → environment file / build-time config / dev-server proxy config. Never as string literals inside components, services, or store actions.
- Fixture data (mockup's fixture block for tests/dev fallback) → dedicated `*.fixture.*` or JSON file in `shared/`, NOT inline literals inside spec files or feature components.
- If a value would differ between local dev and production, it's configuration — express as a typed `environment` field, not as a conditional in code.

## Stack — generic rules

Canonical stack: `local/bindings.md` → "Stack". The specific framework, state library, styling approach, and realtime client are project-specific. Generic invariants:

| Concern | Rule |
|---|---|
| Framework | Whatever `local/bindings.md` records. Use that — do not introduce a parallel framework. |
| State | Whatever `local/bindings.md` records. Keep state derivation pure and signal-driven where the framework supports it. |
| Real-time | Browser-native primitives (`EventSource`, `WebSocket`, `fetch` streaming) unless the project mandates a library. |
| Forms / HTTP | Framework built-ins unless the project mandates otherwise. |

Do NOT introduce additional UI kits, styling languages (Sass / Less when the project uses utility CSS), large date libraries when small helpers suffice, or any bundler outside the project-mandated one. See `local/bindings.md` → "Do not introduce".

## Real-time client (when the project has one)

- One realtime connection instance for the page lifetime, opened in a service layer.
- Honour resume-token semantics on reconnect (e.g. `Last-Event-ID` for SSE, sequence IDs for WebSocket protocols, change-stream tokens for change feeds).
- Reconnect with exponential backoff up to a cap on error; never block the UI.
- On reconnect, optionally re-pull the full state once via REST to recover from missed events.

## Build-step rule (when the architecture doc constrains it)

Some projects declare "no build step in the browser" — the application loads without requiring an end-user to run a bundler. A build step at container-build time (CI, Docker layer) is allowed and expected; what's prohibited is requiring a developer or end-user to run a bundler to view the application. The container / artifact ships pre-built.

When the project's architecture doc states this constraint, uphold it.
