# Pull-Request Description Template

<!-- Use for every PR landing code, tests, infra, or docs. Cite the requirement / NFR / mockup section / CR / ADR. -->
<!-- Replace bracketed placeholders. Drop sections that yield no content. -->

---

## What

`<one or two sentences — imperative voice>`

## Why

`<one or two sentences — trigger (TODO line / CR / defect / explicit user request). Reference the source.>`

## Cites

| Source | Reference |
|---|---|
| Requirement | `<FR-NN | NFR-NN>` |
| Architecture-doc section | `<§N or anchor>` |
| Mockup section / behaviour | `<section / interaction>` |
| CR | `<CR-NNNN>` (post-finalization) |
| ADR | `<ADR-NNNN>` (new architectural decision) |
| Hand-off note | `<path or link>` (when resolving cross-domain hand-off) |

No source → no PR. If uncited by something authoritative, write the doc update first or flag the gap.

## Domain breakdown (for cross-domain PRs)

| Domain | Role | Files touched (top-level) | Verification |
|---|---|---|---|
| `<e.g. service-tier>` | `<role>` | `<path-glob>` | `<test command + outcome>` |
| `<e.g. client-tier>` | `<role>` | `<path-glob>` | `<test command + outcome>` |
| `<e.g. infra-tier>` | `<role>` | `<path-glob>` | `<test command + outcome>` |

## Cross-domain sign-offs

<!-- For wire-contract breaking changes, infra changes affecting application config, or any cross-domain bug fix. -->

- [ ] `solution-architect` — architecture-doc / CR / ADR landed
- [ ] `backend-engineer` — wire shape confirmed
- [ ] `frontend-engineer` — client adapts to new shape
- [ ] `devops-engineer` — env var / secret / endpoint provisioned
- [ ] `qa-engineer` — fixtures + assertions match new contract
- [ ] manual smoke against running stack (per `core/cross-domain-bugs.md` Phase 3) — `<one-line result per new flow>`

## Cost impact (when applicable)

<!-- Devops-led PRs that add resources or bump SKUs. -->

| Item | Before | After | Delta |
|---|---|---|---|
| `<resource>` | `<USD/mo>` | `<USD/mo>` | `<+/- USD>` |
| **Total** | | | |

Cost-cap NFR check: `<still under | exceeds — explain>`.

## Verification log

| Command | Outcome |
|---|---|
| `<build / test / lint command>` | `<exit code / pass-fail / counts>` |

<!-- For PRs touching a user-facing surface, manual smoke against the running stack (not the mockup). -->

- `<one line per new flow>`

If manual smoke wasn't possible (e.g. headless), state so explicitly. Do not claim PASS without doing it.

## Open issues / follow-ups

- `<issue>` — `<who/what is blocked>`
- `<follow-up TODO / CR / ADR opportunity>`

## Out of scope (explicit)

- `<what this PR deliberately does NOT do, to prevent reviewer scope-creep>`
