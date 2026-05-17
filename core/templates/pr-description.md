# Pull-Request Description Template

<!-- Use for every PR landing code · tests · infra · docs.
     Every PR cites: requirement / NFR / mockup section / CR / ADR.
     Replace bracketed placeholders. Drop sections with no content. -->

---

## What

<!-- One or two sentences, imperative voice. -->

`<change summary>`

## Why

<!-- One or two sentences. Trigger = TODO line / CR / defect / explicit user request. Reference the source. -->

`<trigger + reference>`

## Cites

| Source | Reference |
|---|---|
| Requirement | `<FR-NN | NFR-NN>` |
| Architecture-doc section | `<§N or anchor>` |
| Mockup section / behaviour | `<section / interaction>` |
| CR | `<CR-NNNN>` (post-finalization) |
| ADR | `<ADR-NNNN>` (new architectural decision) |
| Hand-off note | `<path or link>` (when resolving cross-domain hand-off) |

**No source → no PR.** Uncited by something authoritative → write the doc update first, or flag the gap.

## Domain breakdown (for cross-domain PRs)

| Domain | Role | Files touched (top-level) | Verification |
|---|---|---|---|
| `<e.g. service-tier>` | `<role>` | `<path-glob>` | `<test command + outcome>` |
| `<e.g. client-tier>` | `<role>` | `<path-glob>` | `<test command + outcome>` |
| `<e.g. infra-tier>` | `<role>` | `<path-glob>` | `<test command + outcome>` |

## Cross-domain sign-offs

<!-- Required when PR touches any of:
     · wire-contract breaking change
     · infra change affecting application config
     · cross-domain bug fix -->

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

**Cost-cap NFR check:** `<still under | exceeds — explain>`.

## Verification log

| Command | Outcome |
|---|---|
| `<build / test / lint command>` | `<exit code / pass-fail / counts>` |

<!-- PRs touching a user-facing surface → manual smoke against the running stack (NOT the mockup). -->

- `<one line per new flow>`

**Manual smoke skipped** (e.g. headless): state so explicitly. **Never** claim PASS without doing it.

## Open issues / follow-ups

- `<issue>` — `<who/what is blocked>`
- `<follow-up TODO / CR / ADR opportunity>`

## Out of scope (explicit)

- `<what this PR deliberately does NOT do, to prevent reviewer scope-creep>`
