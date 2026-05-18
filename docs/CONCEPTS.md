---
title: Concepts
description: "The mental model — 7-cardinal team, phased lifecycle, dispatch rules, iteration protocol, index protocol, delivery modes."
permalink: /CONCEPTS.html
---

# Concepts

The mental model behind ginee. Worth reading once; you'll use the same patterns on every project.

## The 7-cardinal team

ginee ships exactly **7 cardinal roles** — every adopter project has the same shape:

| Role | Concerns |
|---|---|
| `team-lead` | Orchestrator. Dispatch routing, lifecycle gates, discovery / rediscovery, post-acceptance hook, staleness checks. |
| `solution-architect` | Architecture doc semantics, SAD freeze, CR / ADR governance, mockup review (no edits), tie-breaker resolution. |
| `ai-engineer` | AI-asset + doc context economy, file-splitting, load topology, lossless restructures. Between-phase only. |
| `frontend-engineer` | Client / UI implementation, mockup ownership, state, styling, fetch / realtime client wiring. |
| `backend-engineer` | Server / API implementation, ORM entities, schema, realtime hub, auth middleware, wire contract. |
| `devops-engineer` | IaC, Dockerfiles, orchestration, CI workflows, gateway config, secrets, cost tracking. |
| `qa-engineer` | Scenario specs, e2e / functional / smoke tests, harness assertions, fixtures, seed scripts. |

**Why exactly 7?** Two slots are universal — every project has an orchestrator and AI-asset / doc upkeep. The remaining 5 cover the engineering surfaces every software project has: client, server, infra, quality, plus the architect who governs the design across them.

**Specialists in `extras/roles/`** — security · ml · mobile · sre · data — are opt-in. Adopt them when discovery surfaces the matching domain.

**Custom roles** live under `local/roles/` and register under `team-lead`. Use the `core/templates/role-authoring-template.md` shape.

## Phased task lifecycle

Every non-trivial task runs through **Phases 1–8**. Specialists within a phase run in parallel where independent; phases overlap wherever a contract surface decouples them.

| Phase | Goal | Acceptance |
|---|---|---|
| **1. Analysis** | Bound scope; identify touched domains | Scope clear enough to plan Phase 2; ≤ 1 unresolved scope question |
| **2. Design** | Lock contracts (architecture, mockup, wire, work breakdown) | Fixed contract surfaces; harness green; cross-refs resolved |
| **3. Design review** | Synchronous user-approval gate on Phase 2 | Explicit user approval |
| **4. Implementation** | Code mirroring approved contracts | Compiles; per-project unit tests pass; no new lint errors |
| **5. Testing** | Change-scoped suites + manual smoke | Touched-surface oracles green; manual-smoke report recorded |
| **6. Bug fixing** | Resolve defects from Phase 5 | Change-scoped oracles green; no regressions in touched surfaces |
| **7. SA review** | `solution-architect` checks invariants | APPROVE or RETURN-TO-engineer with findings |
| **8. User approval** | User confirms delivered work | TODO ☐ → ☒; issue closed; delivery finalize per mode |

**Auto mode (D12)** — prefix a task with `auto:` to elide intermediate gates (Phase 3 design review, iteration check-ins, engineer "stop and confirm"). Phase 8 becomes a single **delivery handoff** with Accept / Feedback / Reject. Forced back to interactive on UX changes, repeated defects, cross-domain cycles, or destructive actions.

## Dispatch rules

| Rule | Action |
|---|---|
| Independent specialists in one phase | One message with N dispatch calls — **never serialize across messages** |
| Cross-phase overlap (e.g. test authoring during implementation) | One message; each prompt names the shared contract surface |
| Doc-only changes | `solution-architect` alone (or mockup-owning role alone for mockup-only) |
| Infra change affecting application config | Service-owner first (confirms app reads the new value), then `devops-engineer` |

**Strict-domain rule.** A bug in domain X is fixed by the engineer who owns X — never by an adjacent specialist "while they're in the area." Cross-domain bugs require collaboration, not single-specialist heroics.

## Iteration protocol

For Phase 4 / 5 / 6 / 7 work above 15 min OR any timeframe-bounded task:

1. **Estimation-first dispatch.** Each specialist returns task decomposition + per-task minutes **before** editing.
2. **Synthesis.** Orchestrator (or PM) synthesizes all specialist proposals into one batch for user approval.
3. **3–5 min iterations.** Each ends in a **stoppable intermediate state** — visible result, no half-finished edit on disk.
4. **Stop anywhere.** User can interrupt at any iteration boundary; resume next session with zero rework.

## Source-of-truth ownership

Per-project, the table in `local/bindings.md § Source-of-truth ownership` maps:

- **Default reads:** `local/index/*` (the extracted summaries).
- **Governance:** who edits each raw source.
- **Verbatim consumption:** where the full text lives when an index entry says "see source."

Roles **never** read raw `docs/**` "before any work." The index is the only default read surface; full source loads only when verbatim wording matters.

## Index protocol

`local/index/` holds lightweight per-class summaries of the project's knowledge:

| Category | Examples |
|---|---|
| Documentation | `architecture.idx`, `architecture-fr.idx`, `api-matrix.yaml`, `ui-states.yaml`, `constraints.yaml`, `adr-index.idx`, `cr-index.idx`, `scenario-index.idx`, `glossary.idx`, `mockup-index.idx` |
| Code / config | `stack.yaml`, `topology.yaml`, `commands.yaml`, `conventions.yaml`, `runtime-facts.yaml`, `repo-map.idx` |

**Key invariants:**

- **Coverage rule** — every named record (FR / NFR / endpoint / state / ADR / dep / service / port / command / env-var / dir) has an existence-entry in the index.
- **Compression floor** — `index-bytes / source-bytes ≥ 0.5 = recipe failed`. Either drop bulk or mark `template: read-source-directly`.
- **Consumer coupling** — every extracted class declares `consumed-by: [<role>...]` in `manifest.yaml`. Novel classes without a consumer aren't extracted.
- **Per-file load triggers** — role kernel `Source of truth` tables carry a `Load when` column. `always` for foundational reads; trigger phrase for scope-loaded files. Specialist reports the loaded set in its first response.
- **SHA-256 staleness** — `team-lead` checks drift pre-dispatch; offers `@ai-engineer reindex <source>` or `@team-lead rediscover` on mismatch. Never auto-reindexes.

Full spec: [`core/index-protocol.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/index-protocol.md).

## Delivery modes

PM resolves one of three delivery modes per task — picked by precedence:

1. Per-task prefix: `branch:` / `wt:` / `commit:` at start of task description.
2. Per-task Phase-3 user answer.
3. Adopter default in `local/framework.config.yaml § delivery.default-mode`.
4. Framework default — `branch` for issue / TODO-sourced tasks; `wt` for freeform.

| Mode | Phase 4 commits | Phase 8 finalize |
|---|---|---|
| **1. Branch + PR** | `gh issue develop` (issue-sourced) or `git checkout -b`; commits on branch | `git push -u origin`; `gh pr create` with `Closes #<N>` |
| **2. Working-tree only** | No commits | PM surfaces `git diff`; user commits / discards manually |
| **3. Commit-no-push** | Commits on current branch | PM surfaces `git log --oneline`; user pushes manually |

Combinable with `auto:` — `auto: branch: fix the deploy logs spam` is valid.

Full spec: [`core/delivery-modes.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/delivery-modes.md).

## GitHub issues + discussions as a task source

ginee picks up GitHub issues with the same Phase 1–8 lifecycle as TODO lines and direct instructions:

- **File** via `@team-lead file bug <title>` / `file feature <title>`. PM uses structured templates under `core/templates/issues/`, opens a labelled issue with `ginee:ready`.
- **Pick up** via `@team-lead pick up #<N>`. PM swaps labels `:ready` → `:in-progress`, runs Phase 1–8, posts structured progress comments at transitions.
- **Triage** via `@team-lead triage` — lists ready issues by age, scope, cross-references.
- **Promote** via `@team-lead promote discussion #<N>` — surfaces a draft issue from a discussion thread.

PRs reference the issue with `Fixes #<N>` / `Closes #<N>` — GitHub auto-closes on merge.

Full spec: [`core/github-integration.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/github-integration.md).

## What ginee doesn't do

- **Auto-update.** The installer is invoked explicitly; never runs unattended.
- **Per-domain templates.** No architecture / API / mockup contracts. Adopters bring their own; ginee ships process only.
- **Multi-repo coordination.** One project at a time.
- **MCP server.** Deferred to v2.0.

## Next

- [**Reference**]({{ '/reference/' | relative_url }}) — canonical specs for each concept above.
- [**Cheatsheet**]({{ '/CHEATSHEET.html' | relative_url }}) — one-page reference of every command + label + phase you'll touch.
