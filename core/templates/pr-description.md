# Pull-Request Description Template

Use for every PR that lands code, tests, infrastructure, or docs. Cite the requirement / NFR / mockup section / CR / ADR; document cross-domain sign-offs; flag any cost impact.

Replace bracketed placeholders. Drop sections that yield no content.

---

## What

`<one or two sentences — imperative voice. e.g. "Add picker UI for correlation attribute on the matrix Glance view; persist selection in URL.">`

## Why

`<one or two sentences explaining the trigger — a TODO line, a CR, a defect, an explicit user request. Reference the source.>`

## Cites

| Source | Reference |
|---|---|
| Requirement | `<FR-NN | NFR-NN>` |
| Architecture-doc section | `<§N or anchor>` |
| Mockup section / behaviour | `<section / interaction>` |
| CR | `<CR-NNNN>` (when post-finalization) |
| ADR | `<ADR-NNNN>` (when a new architectural decision was needed) |
| Hand-off note | `<path or link>` (when this PR resolves a cross-domain hand-off) |

No source → no PR. If the work isn't cited by something authoritative, write the doc update first or flag the gap.

## Domain breakdown (for cross-domain PRs)

| Domain | Role | Files touched (top-level) | Verification |
|---|---|---|---|
| `<e.g. service-tier>` | `<role>` | `<path-glob>` | `<test command + outcome>` |
| `<e.g. client-tier>` | `<role>` | `<path-glob>` | `<test command + outcome>` |
| `<e.g. infra-tier>` | `<role>` | `<path-glob>` | `<test command + outcome>` |

## Cross-domain sign-offs

For wire-contract breaking changes, infra changes affecting application config, or any cross-domain bug fix:

- [ ] `solution-architect` — architecture-doc / CR / ADR landed
- [ ] `backend-engineer` — wire shape confirmed
- [ ] `frontend-engineer` — client adapts to new shape
- [ ] `devops-engineer` — env var / secret / endpoint provisioned
- [ ] `qa-engineer` — fixtures + assertions match new contract
- [ ] manual smoke against running stack (per `core/process.md` § Cross-domain bugs cycle Phase 3) — `<one-line result per new flow>`

## Cost impact (when applicable)

Devops-led PRs that add resources or bump SKUs:

| Item | Before | After | Delta |
|---|---|---|---|
| `<resource>` | `<USD/mo>` | `<USD/mo>` | `<+/- USD>` |
| **Total** | | | |

Cost-cap NFR check: `<still under | exceeds — explain>`.

## Verification log

| Command | Outcome |
|---|---|
| `<build / test / lint command>` | `<exit code / pass-fail / counts>` |

For PRs that touch a user-facing surface, **manual smoke** result against the running stack (not the mockup):

- `<one line per new flow>`

If manual smoke wasn't possible (e.g. headless), state so explicitly. Do not claim PASS without doing it.

## Open issues / follow-ups

- `<issue>` — `<who/what is blocked>`
- `<follow-up TODO / CR / ADR opportunity>`

## Out of scope (explicit)

- `<what this PR deliberately does NOT do, to prevent reviewer scope-creep>`
