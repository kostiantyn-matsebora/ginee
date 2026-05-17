# Engineering Process

## Purpose

- Generic, project-agnostic process model for a small multi-agent engineering team.
- Authoritative spec for every role (orchestrator + specialists).
- **Project-specific knowledge lives elsewhere** — never in this file:
  - Stack, repo layout, role roster, forbidden role-crossings, owned-paths bindings → `local/bindings.md` + `local/project-profile.md`.

## Reading order

| File | Role | Owner |
|---|---|---|
| `core/process.md` (this file) | Generic lifecycle, dispatch rules, principles | upstream framework |
| `core/roles/*.md` | Generic role charters (7 cardinals) | upstream framework |
| `local/bindings.md` | Per-project role → owned paths/concerns table | the project |
| `local/project-profile.md` | Per-project stack, domain, architecture artefacts | the project (written by `project-manager` on discovery) |
| `local/framework.config.yaml` | Concept → file-path mapping (architecture doc, mockup, API contract, ADR dir, TODO file, ...) | the project |

**Conflict resolution:**

| Conflict class | Winner |
|---|---|
| Per-project routing | `local/bindings.md` |
| Generic process rule | `core/process.md` (this file) |

Bindings may NOT override generic process.

## Dispatch & parallelism rules

| Rule | Action |
|---|---|
| Independent work (no shared contract change) | Dispatch specialists in parallel in ONE message. |
| N independent specialists in one phase | ONE message with N dispatch calls. Never serialize across messages. |
| Cross-phase overlap (e.g. quality authoring tests while client implements) | ONE message with all overlapping specialists; each prompt names the shared contract surface (architecture-doc §X, mockup behaviour Y, wire shape Z). |
| Parallel-by-default for cross-domain Phase 2 | Default for Phase 2 of the cross-domain cycle is parallel. Justify any sequential Phase 2 dispatch in the dispatch prompt itself (one sentence). Habitual serialization is the failure mode. |
| Doc-only changes | `solution-architect` only (architecture-family) or mockup-owning role only (UI-only edit with no architecture implication). |
| Infrastructure changes affecting application config (env var, secret, endpoint URL) | Coordinate `devops-engineer` + affected service-owning role; service-owner first to confirm the app reads the new value, devops second. |

**Overlap patterns** — next phase starts when its contract surface is fixed, not when prior phase's code lands:

- **Test authoring overlaps implementation.**
  - Trigger: Phase 2 fixes wire shape / mockup behaviour.
  - `qa-engineer` authors specs and fixtures in parallel with implementation.
  - Both reference the contract — not each other's source.
- **Bug fix overlaps continued testing.**
  - QA reports a defect.
  - Owning engineer fixes immediately.
  - QA continues exercising other scenarios in parallel.
- **Doc update overlaps implementation.**
  - `solution-architect` hands engineers the contract context.
  - Engineers proceed.
  - SA updates architecture doc / project-instruction files / ADRs in parallel.
  - The doc commit is a paper trail, not a gate.

**Implementation gate.**

- Phase 4 starts only when:
  - Phase 2 contract surface is fixed, AND
  - Phase 3 design-review gate has passed.
- No engineer codes against an unapproved design.

## Task lifecycle — phased pipeline with maximum parallelism

**Binding.**

- Phases are named and ordered.
- Specialists within a phase run in parallel.
- Phases overlap wherever a contract surface decouples them.
- Each phase carries: **Goal · Acceptance** (and additional anchors where the phase warrants).

### Phase 1 — Analysis

- **Goal.** Bound scope; identify touched domains.
- **Reads.** TODO line + relevant architecture sections + mockup + code.
- **Output.** Phase 2 dispatch plan; surfaced ambiguities.
- **Acceptance.** Scope bounded enough to plan Phase 2. ≤ 1 unresolved scope question.

### Phase 2 — Design & architecture

- **Goal.** Lock contracts before any code — system, API, visual, work breakdown.
- **Dispatch.** Owning role per `local/bindings.md`:

  | Surface | Owner |
  |---|---|
  | Architecture doc, API contract ratification | `solution-architect` |
  | Mockup | mockup-owning role |
  | Wire contract | service-owning role |
  | Work breakdown | each engineer contributes their slice |

  Parallel where independent.
- **Acceptance.**
  - Fixed wire shape + mockup behaviour + work breakdown.
  - Visual / contract harness green (where one exists).
  - Cross-references resolved.
  - Artefacts presentable as a coherent whole.

### Phase 3 — Design review

- **Goal.** Synchronous gate — explicit user approval of Phase 2 before implementation.
- **Action.** Orchestrator MUST present: architecture-doc diff + mockup link + API contract + work-breakdown.
- **Outcomes.**
  - Approval → Phase 4 dispatches.
  - Remarks → loop back to Phase 2.
- **Distinct from.** Phase 8 (closes TODO); TODO-workflow checkpoint (sits before Phase 1).
- **Acceptance.** Explicit user approval. Without it, Phase 4 does not start.
- **In automatic mode.** Elided when Phase 2 produces no user-visible behaviour change. Forced back to interactive per `core/automatic-mode.md § Forced-interactive triggers`.

### Phase 4 — Implementation

- **Goal.** Working code mirroring approved Phase 2 contracts.
- **Rules.**
  - Each engineering role implements its part in its owned paths (`local/bindings.md`).
  - Parallel where independent.
  - Phase 5 overlaps once Phase 3 passes.
  - Runs under `### Iteration protocol`.
- **Acceptance.**
  - Compiles / builds clean.
  - Per-project unit tests pass.
  - No new lint or type errors.

### Phase 5 — Testing

- **Goal.** Verify implementation against contracts: executable suites + manual smoke against the running solution.
- **Scope — change-scoped by default.** Run only:

  | Layer | What runs |
  |---|---|
  | New / modified scenarios | functional / API / e2e / harness / script for touched code paths |
  | Per-project unit specs | in modified files |
  | Pre-existing scenarios | only if their covered contract was edited in Phase 2 or 4 |

- **Full regression — opt-in only.**
  - User must explicitly request it.
  - `project-manager` MAY remind it's available (wide-reach refactor / infra change / risky touch).
  - `project-manager` MUST warn of significant wall-clock + token cost.
  - Runs separately AFTER change-scoped pass is green.
  - Reports: pass/fail per suite + wall-clock + approximate token cost.
- **Discipline.**
  - Tests reference contracts, not implementation internals.
  - Oracles TIGHT per `### Test oracles can be wrong`.
  - Manual smoke against the running solution (project's local-dev startup command), NOT design artefacts.
  - Runs under `### Iteration protocol`.
- **Acceptance.**
  - Change-scoped suite green.
  - Oracles reflect correctness for touched surfaces.
  - Manual-smoke report recorded (caveat if not run, e.g. headless).
  - Failures → Phase 6.
  - Opt-in full regression is its own pass — not a precondition.

### Phase 6 — Bug fixing

- **Goal.** Resolve defects from Phase 5 (or manual smoke) until all change-scoped oracles are green.
- **Rules.**
  - Owning engineer fixes the failing surface.
  - QA exercises other scenarios in parallel — a fix never freezes the test run.
  - Routes back to the specific Phase 4 surface, not a full Phase 4 rerun.
  - Runs under `### Iteration protocol`.
- **Acceptance.**
  - Change-scoped oracles green.
  - No regression in touched surfaces.
  - Manual smoke re-run if a user-visible surface was touched.
  - Opt-in full regression is part of that opt-in pass — not a Phase 6 gate.

### Phase 7 — SA review

- **Goal.** `solution-architect` confirms compliance with architecture invariants, requirements, mockup behavioural contracts.
- **Checks.**
  - Architecture invariants honoured.
  - Mockup behavioural contract honoured.
  - Phase 5 manual-smoke section was actually written (empty = REJECT, return to Phase 5).
- **Constraint.** Sign-off only; no code edits.
- **Iteration.** Runs under `### Iteration protocol` when follow-up architecture-doc edits exceed 15 min.
- **Acceptance.**
  - APPROVE (with or without pending additive architecture-doc edits), OR
  - RETURN-TO-engineer with specific findings.

### Phase 8 — User approval

- **Goal.** User confirms delivered work satisfies the TODO line.
- **Action.** Orchestrator surfaces per the Task model. If manual smoke wasn't run (e.g. headless), asks the user to run it.
- **User choices.**
  - "Yes — mark complete" → see Acceptance below.
  - "No — needs more work" → loop back to Phase 6 with feedback.
- **Acceptance.**
  - TODO line `☐` → `☒`.
  - Project-progress refresh (if used).
  - Commit only when the user explicitly asks.
- **In automatic mode.** Realized as the **delivery handoff** per `core/automatic-mode.md § Delivery handoff`.
  - User-approval invariant preserved: single explicit accept.
  - Accept / Feedback / Reject replace yes/no.
- **Post-acceptance doc-optimization hook.** If the task touched any documentation (project-instruction files, architecture docs, role definitions, ADRs, CRs, READMEs):
  - Orchestrator MUST dispatch `ai-engineer` to run `### Iteration protocol` scoped to the doc diff.
  - Polish step, not a gate.
  - First proposal batch returns "no productive proposals" → hook completes immediately.
  - No user permission required to invoke.
  - User sees the cumulative optimization diff in the final report; may accept or revert as a unit.

### Cross-phase rule

- Artefact classes do not cross phases.
- A change needing both design and code:
  1. Phase 2 — land design artefacts in docs.
  2. Phase 4 — land code artefacts in solution.

### Relation to the cross-domain bugs cycle

- Source: `core/cross-domain-bugs.md` — specific instantiation of this lifecycle for bugs cutting across 2+ domains.
- **Phase mapping:**

  | Cross-domain phase | Lifecycle phase |
  |---|---|
  | 1 — contract change | 2 (design) |
  | 2 — domain implementations | 4 (implementation) |
  | 3 — integration + bug fixing | 5–6 (test + fix) |
  | 4 — compliance review | 7 (SA review) |

- Lifecycle Phase 3 (design review) still applies when the bug requires user-visible behaviour change.

## Automatic mode

- **Trigger.** Task prefixed `auto:`, OR `project-manager`-proposed and user-accepted.
- **Effect.** Lifecycle runs end-to-end without per-phase user gates; presents a single final delivery handoff.
- **Default.** Interactive (no auto mode).
- **Full definition** — activation triggers, gates elided/respected, forced-interactive triggers, delivery handoff procedure: `core/automatic-mode.md`. `project-manager` loads on activation.
- **Invariant preserved.** Phase 8 user-approval = the single delivery-handoff gate.

## Engineering principles — apply across all roles

### Configuration vs. data — declarative over imperative

- Binds every role.
- Signal a value belongs in a declarative file: "hard to change without editing imperative code".

**Configuration** (URLs, ports, env vars, feature flags, retention windows, defaults):

- Lives in declarative files per tier (project stack determines format):

  | Tier | Typical file |
  |---|---|
  | Service runtime | environment file / app-settings config |
  | Client runtime | environment file / build-config |
  | Container orchestration | `docker-compose.*.yml` / Helm values |
  | IaC | `*.tfvars` / Pulumi config / etc. |
  | Scripting / tooling | `*.json` / `*.yaml` config files |

- **Never** as literals inside controllers, components, scripts, or test specs.

**Data** (fixtures, seed sets, snapshot baselines, expected payloads, scenarios):

- Lives in dedicated declarative files.
- **Never** as inline literals inside test code.

**Imperative code stays thin.**

- Scripts / runners / wrappers read declarative files and call the underlying tool.
- Exceptions require a doc update before they land.

### Test oracles can be wrong

- A passing test against broken software = defect in the oracle, not a green light.
- Test results contradict observed behaviour → trust observed behaviour; route to test owner to tighten assertion.
- Examples of weak oracles:
  - Harness anchored to wrapper, not inner element.
  - POST asserting status without response shape.
  - UI element opened without exercising its action.
- Tightening is `qa-engineer`'s job; respecting the signal is everyone's.

## Documentation style — structure over prose

Applies to **all** written artefacts:

- Project-instruction files.
- Role definitions (`core/roles/`, `local/roles/`).
- Future skills.
- Architecture doc, mockup, ADRs.
- Per-component READMEs.

- **Default to structure** — bullets, numbered lists, tables, headings. Not prose paragraphs.
- **Steps / actions / instructions** → bullet list. Never a multi-sentence paragraph.
- **Pairs, mappings, choices** → table. Examples: "Before / after", "concern → owner", "endpoint → status code".
- **One idea per bullet.** A bullet wanting three sentences → promote to sub-list or table.
- **Headings carry weight.**
  - Use `##` / `###` to chunk.
  - Don't bury rules inside walls of prose.
- **Code shapes go in fenced code blocks** — wire formats, env vars, file paths, commands.
- **Cross-reference, don't duplicate.** Cite the section ("per architecture-doc §X"); don't restate.
- **Drop filler.**
  - No "It is important to note that…", "Please ensure…", "In general…".
  - Lead with the verb or noun.
- **Prose is for narrative exposition only** — explaining *why*. Keep tight.

## Coordination protocol

| Trigger | Rule |
|---|---|
| Any PR | Cite requirement / NFR / architecture-doc section / mockup section implemented or validated. Template: `core/templates/pr-description.md`. |
| Wire-contract breaking change (API shape, event format, env-var names) | Flag in PR title. Service-owning role + client-owning role + `devops-engineer` all confirm before merge. |
| Cost-relevant change (new resource, larger SKU) | Fresh estimate vs. project cost cap in PR description. `devops-engineer` owns. |

### Strict-domain rule — no specialist works outside its domain

- A bug in domain X is fixed by the engineer who owns X.
- Never by an adjacent specialist "while they're in the area".
- Cross-domain bugs require collaboration, not single-specialist heroics.
- **Project-specific forbidden role-crossings table:** `local/bindings.md` → "Project role boundaries".
  - Each row is a hard stop.
  - Propose a hand-off in the final report instead.

### Doc co-ownership — solution-architect ↔ ai-engineer

- **Ownership split:**
  - `solution-architect` owns documentation **semantics**.
  - `ai-engineer` owns **shape + load topology**.
  - Neither overrides the other's invariants.
- **Runs under** `### Iteration protocol` below.
- **Full definition** (routing table + lossless edit rule + dispatch triggers): `core/doc-co-ownership.md`.
- **Load triggers** (when to fetch the full file):
  - New rule landing.
  - Doc grows past size threshold.
  - Cross-reference repair after a split/move.
  - Structure dispute (SA vs. ai-engineer).

### Iteration protocol — propose → review → implement

**Scope.** Generalized loop applied to:

- All team work in Phases 4–7 (Implementation, Testing, Bug fixing, SA review) with estimated total scope > 15 min.
- Doc co-ownership passes between `ai-engineer` and `solution-architect`.

**User intervention** bounded to:

- Kickoff approval.
- Final report.

**Estimation-first dispatch.**

- Before any code / tests / fixes / doc edits, each dispatched specialist MUST respond with:
  - Task decomposition.
  - Per-task time estimate.
  - No edits yet.
- Orchestrator:
  1. Synthesizes all specialist proposals.
  2. Surfaces total + per-task breakdown to the user when scope warrants.
  3. Waits for approval or redirect before any specialist enters implement.
- **Applies to** Phase 4, Phase 5, Phase 6, Phase 7, and `ai-engineer` ↔ SA doc co-ownership passes.

**Sizing.**

| Estimated total scope | Approach |
|---|---|
| ≤ 15 min | Single iteration: specialist proposes full pass; reviewer (orchestrator / SA / user as appropriate) reviews; specialist implements. |
| > 15 min | Multiple short iterations of 3–5 min each; each produces a visible partial result. Specialist scopes the next batch (3–7 sub-tasks) at the start of each iteration. |

**Each iteration.**

1. **Propose.**
   - Specialist submits structured proposal listing each sub-task: change / where / why / risk / time estimate.
   - For doc work, also include lossless evidence.
   - No edits yet.
2. **Review.**
   - Reviewer responds per item: accept / decline / accept-with-modification, each with one-line reasoning.
   - **Reviewer identity:**

     | Work class | Reviewer |
     |---|---|
     | Doc co-ownership semantics | `solution-architect` |
     | Phase 4–7 engineering | orchestrator (surfacing to user when scope warrants) |
3. **Implement.**
   - Specialist executes accepted items.
   - Applies reviewer's modifications.
   - Runs domain self-check: build / lint / harness / lossless check as applicable.
   - Updates cross-references in dependent files.
   - Ends in a stoppable intermediate state per `### Stoppable intermediate states`.

**Loop termination** — any one of:

- Specialist reports "no further productive proposals" in the next batch.
- Specialist or reviewer hits semantic territory only the user can decide.
- Pre-agreed budget exhausted.
- User stops at any iteration boundary.

**Conflict resolution.**

- **Doc semantics** → `solution-architect` wins.
- **Implementation craft within a specialist's domain** → domain-owning specialist wins (per `local/bindings.md` → "Project role boundaries").
- **Product intent** → user wins.
- **Re-proposal limit.** Specialist may re-propose with new evidence ONCE per item. Second decline is final.

**Orchestrator role.**

- Dispatches the three steps each iteration.
- Surfaces the estimation batch before implement.
- Surfaces intermediate results when:
  - User requests, OR
  - An iteration revealed something to redirect on.

### Stoppable intermediate states

Each iteration under `### Iteration protocol` must leave the system in a valid, resumable state:

| Role | What "stoppable" means |
|---|---|
| Engineers | No half-written code that breaks build, type-check, or per-project unit tests. |
| QA | No partial test runs that pollute fixtures, leave seeded data behind, or leave local stack non-reproducible. |
| Bug fixes | No half-applied contract changes (e.g. service half landed, client half pending) — gate behind feature flag or stage behind no-op default. |
| Doc edits | No broken cross-references or orphaned sections. |

**User stops at any iteration boundary.** Orchestrator's stop report:

- **Done.** Sub-tasks completed, with files touched.
- **In-progress.** Sub-task interrupted, with partial state recorded + concrete resume instructions (same partial-result format as `### Timeframe-bounded autonomous work`).
- **Not-started.** Sub-tasks remaining in the approved batch, with original estimates intact.

Continuation from the recorded state must require zero rework.

### Timeframe-bounded autonomous work

**Trigger.** User gives a timeframe (e.g., "spend 30 min on X", "do as much as you can in an hour"). Orchestrator treats it as a budget for autonomous work.

- **Autonomy.** Work autonomously for the full period:
  - Drive multi-specialist loops.
  - Run sequential dispatches.
  - Iterate.
- **Checkpoint.** Boundary is the checkpoint — report at the end, not before.
- **Result classes** — all three acceptable; honesty about which is required:

  | Class | Meaning |
  |---|---|
  | **Full** | Everything done within the budget. |
  | **Partial** | Ran out of budget mid-way. |
  | **Early** | Done sooner than expected. |

- **No per-iteration check-ins.** Valid mid-flight interrupts:
  - Scope creep.
  - Genuine ambiguity.
  - Semantic conflict the orchestrator can't resolve.
- **Partial results** — report must include:
  - **done / in-progress / not-started** breakdown.
  - Concrete resume instructions.
- **Iteration.** Runs through `### Iteration protocol` until the timeframe expires; each iteration ends in a stoppable intermediate state.

### Cross-domain bugs — integration + compliance cycle

- **Trigger.** A bug spans 2+ domains.
- **Model.** Four-phase:
  1. Contract change.
  2. Parallel domain implementations.
  3. Integration verification with manual smoke.
  4. Compliance review.
- **Full procedure** (manual-smoke checklist + anti-pattern rules): `core/cross-domain-bugs.md`. Load when a cross-domain bug or task is detected.
- **Lifecycle mapping:** cycle Phases 1 / 2 / 3 / 4 → lifecycle Phases 2 / 4 / 5–6 / 7.

### Cross-agent handoff — diagnose ≠ fix

When a specialist discovers a root cause **outside** their domain while working on their own task:

1. **Diagnose fully; do NOT fix.** Cross-domain patches cause silent contract drift.
   - Write up: failing command, verbatim error, file + line, chain of reasoning.
   - Template: `core/templates/hand-off-note.md`.
2. **Hand off** to the owning specialist (routing in `local/bindings.md`). Package contents:
   - Symptom.
   - Verified root cause with evidence.
   - What the discoverer tried and ruled out.
   - Any local workaround in place + whether to remove it once the proper fix lands.
3. **Both specialists stay engaged.** Owner fixes; discoverer reviews and removes workaround. Not throw-over-the-wall.
4. **Workarounds are temporary, labelled as such.** Stay only until owner lands proper fix; both specialists acknowledge in reports.
5. **Out-of-competence fixes are disallowed** — see `local/bindings.md` → "Project role boundaries".

**Orchestrator wiring.** When a specialist flags a cross-domain root cause in their final report:

- Dispatch the owning specialist next.
- Pass the prior diagnosis verbatim.

**Doc updates route through the doc's owner:**

| Doc class | Owner |
|---|---|
| Architecture doc / project-instruction files / process docs / ADRs | `solution-architect` |
| Mockup (HTML / CSS / JS / SVG edits) | mockup-owning role |
| Mockup (governance review only) | `solution-architect` |

Engineers outside the owning domain never edit these directly.

## Task model

Phase 1–8 applies to any task. A task originates from one of three sources:

| Source | Scope | State mechanic |
|---|---|---|
| Repo-root `TODO` (file name per `local/framework.config.yaml` → `todo`) | Project-wide | Glyphs `☐` / `☒`; orchestrator updates the line on completion |
| Nested `TODO` (e.g., `client/TODO`, `service/api/TODO`) | Component-scoped | Same glyph mechanic, scoped to that component file |
| Direct user instruction | Ad hoc; scope inferred from the instruction | No `TODO` file; no glyph mechanic |

**TODO file rules.**

- User-curated at any location — never auto-generated, never auto-extended.
- Glyphs:
  - `☐` = open.
  - `☒` = completed.

### Post-task check-in

**After every completed user request** (work delivered or question answered), in this order:

1. **Pick the next pending item to surface.**
   - If user was operating in a component context AND a nested `TODO` exists at that component → check it first.
   - Otherwise → check the repo-root `TODO`.
   - If both have pending items and context is ambiguous → ask which to consult.
   - If neither has pending items → say so and stop. Never invent an item.

2. **Ask the user** — three fixed options, include the verbatim `TODO` line in the prompt:
   | Option | Effect |
   |---|---|
   | **Elaborate** | User explains the item before any work begins. Wait, then proceed. |
   | **Start implementing** | Proceed immediately using the routing rules above. |
   | **Something else** | Wait for the user's next message; handle as a new request. |

3. **When a `TODO`-sourced task completes**, ask:
   | Option | Effect |
   |---|---|
   | **Yes — mark complete** | Edit the relevant `TODO` file (root or nested) to change that line's `☐` → `☒`. No reorder, no delete, no commit unless asked. |
   | **No — needs more work** | Keep as `☐`; ask what's missing; iterate. |

4. **For direct-instruction tasks.**
   - No `TODO` state to update.
   - Acceptance = user's explicit confirmation.
   - Skip the glyph mechanic.
   - Post-Phase-8 hook still applies.

**Cross-cutting rules:**

- `TODO` checks happen **between** user requests — not mid-request.
- `TODO` items are user-grained, larger than in-conversation tasks. Mark both when the same work completes.
- **Never auto-add** to any `TODO` file.
  - Mention follow-up work → *offer* to add it.
  - Do not act unilaterally.
- User says "skip TODO" for this turn → honour it; resume next turn.
- **Discovering nested `TODO`s.**
  - Orchestrator may glob for `**/TODO` on session start or when entering a component context.
  - Surface them only if the user is operating in that context.
