# Engineering Process

## Purpose

Generic, project-agnostic process model for a small multi-agent engineering team. Read by every role (orchestrator + specialists) as the authoritative process spec. Project-specific knowledge (stack, repo layout, role roster, forbidden role-crossings table, owned-paths bindings) lives in `local/bindings.md` and the project's discovery profile (`local/project-profile.md`) — never in this file.

## Reading order

| File | Role | Owner |
|---|---|---|
| `core/process.md` (this file) | Generic lifecycle, dispatch rules, principles | upstream framework |
| `core/roles/*.md` | Generic role charters (7 cardinals) | upstream framework |
| `local/bindings.md` | Per-project role → owned paths/concerns table | the project |
| `local/project-profile.md` | Per-project stack, domain, architecture artefacts | the project (written by `project-manager` on discovery) |
| `local/framework.config.yaml` | Concept → file-path mapping (architecture doc, mockup, API contract, ADR dir, TODO file, ...) | the project |

Conflict between this file and `local/bindings.md` on a per-project routing question → `local/bindings.md` wins. Conflict on a generic process rule → `core/process.md` wins; the project may NOT override generic process via bindings.

## Dispatch & parallelism rules

Single canonical section. Apply to every cross-domain dispatch decision.

| Rule | Action |
|---|---|
| Independent work (no shared contract change) | Dispatch specialists in parallel in ONE message. |
| N independent specialists in one phase | ONE message with N dispatch calls. Never serialize across messages. |
| Cross-phase overlap (e.g. quality authoring tests while client implements) | ONE message with all overlapping specialists; each prompt names the shared contract surface (architecture-doc §X, mockup behaviour Y, wire shape Z). |
| Parallel-by-default for cross-domain Phase 2 | Default for Phase 2 of the cross-domain cycle (see below) is parallel. Justify any sequential Phase 2 dispatch in the dispatch prompt itself (one sentence — e.g. "client needs service's generated types as input"). Habitual serialization is the failure mode. |
| Doc-only changes | `solution-architect` only (architecture-family) or the mockup-owning role only (UI-only edit with no architecture implication). |
| Infrastructure changes affecting application config (env var, secret, endpoint URL) | Coordinate `devops-engineer` + the affected service-owning role; service-owner first to confirm the app reads the new value, devops second. |

Overlap patterns (next phase starts when its contract surface is fixed, not when the prior phase's code lands):

- **Test authoring overlaps implementation.** Once the wire shape / mockup behaviour is fixed (Phase 2 output), `qa-engineer` authors specs and fixtures in parallel with implementation roles coding. Both reference the contract, not each other's source.
- **Bug fix overlaps continued testing.** When QA reports a defect, the owning engineer fixes immediately while QA continues exercising other scenarios.
- **Doc update overlaps implementation.** `solution-architect` hands engineers the contract context (decision wording, requirement delta, wire-shape change); engineers proceed; SA updates architecture doc / project instructions / ADRs in parallel. The doc commit is a paper trail, not a gate.

Implementation gate: Phase 4 (implementation) starts only when the Phase 2 contract surface is fixed AND the Phase 3 design-review gate has passed. No engineer codes against an unapproved design.

## Task lifecycle — phased pipeline with maximum parallelism

**Guidance — binding, not flavour.** Operate the lifecycle as a real software-engineering team operates: separation of concerns, contract-driven parallelism, testing as a first-class deliverable, fail-fast on contract drift, no idle specialists. Phases are named and ordered; specialists within a phase run in parallel; phases overlap wherever a contract surface decouples them.

Each phase below: **Goal · Actions · Artefacts · Criteria of acceptance.**

### Phase 1 — Analysis
- **Goal.** Understand the problem; define scope boundary; identify which domains the work touches.
- **Actions.** Read the relevant `TODO` line, relevant architecture sections, mockup, existing code as needed. Surface ambiguities. Ask clarifying questions when scope is unclear. Decide which specialists Phase 2 will dispatch.
- **Artefacts.** Problem statement + scope boundary in the orchestrator's plan or the discovering specialist's final report. Occasionally a discovery note under the project's docs directory.
- **Acceptance.** Scope bounded sufficiently for the orchestrator to plan Phase 2 dispatches. ≤ 1 unresolved scope question outstanding.

### Phase 2 — Design & architecture
- **Goal.** Lock contracts (system, API, visual, work breakdown) before any code is written. User must be able to review the design as a coherent whole.
- **Actions.** `solution-architect` edits the architecture document + ratifies API contract before Phase 3 opens. The mockup-owning role edits the mockup + design notes. The service-owning role drafts the wire contract (UI-visible side is the client-owning role's). All engineers contribute to the work breakdown. Dispatched in parallel where independent.
- **Artefacts.** Documents under the project's docs directory: architecture doc, mockup, design notes, API contract proposals, ADRs. Project-instruction-file amendments where process/governance changes.
- **Acceptance.** Fixed wire shape + fixed mockup behaviour + fixed work breakdown. Visual / contract harness green (where one exists). All cross-references resolved. Artefacts presentable as a coherent whole.

### Phase 3 — Design review
- **Goal.** Explicit user approval of the Phase 2 design before implementation effort is spent.
- **Actions.** Synchronous gate. Orchestrator MUST present Phase 2 artefacts (architecture-doc diff, mockup link, API contract, work-breakdown) to the user. User approves or returns remarks; remarks loop back to Phase 2. Distinct from Phase 8 (closes the `TODO` line) and from the `TODO`-workflow checkpoint (sits before Phase 1).
- **Artefacts.** None — verbal / chat approval.
- **Acceptance.** Explicit user approval. Without it, Phase 4 does not start.

### Phase 4 — Implementation
- **Goal.** Working code that mirrors the approved Phase 2 contracts.
- **Actions.** Each engineering role implements its part of the approved contract in its owned paths (per `local/bindings.md`). Test authoring (Phase 5) overlaps once Phase 3 has passed. Dispatched in parallel where independent. Runs under `### Iteration protocol — propose → review → implement` with estimation-first dispatch and stoppable intermediate states (see `### Stoppable intermediate states`).
- **Artefacts.** Code in role-owned paths. Build/runtime configuration files, scripts.
- **Acceptance.** Compiles / builds clean. Per-project unit tests pass. No new lint or type errors. Presentable to Phase 5.

### Phase 5 — Testing
- **Goal.** Verify implementation against contracts via executable suites + manual smoke against the running solution.
- **Scope — change-scoped by default.** Run only the tests that cover the changed surfaces: new and modified functional / API / e2e / harness / script scenarios for the touched code paths, plus per-project unit specs in modified files, plus any pre-existing scenario whose covered contract was edited in Phase 2 or 4. **Do not run the full regression suite by default** — it is slow and consumes a large token budget. Full regression is **opt-in**: only run it when the user explicitly asks. `project-manager` may remind the user that a full regression run is available and worth doing (especially for wide-reach refactors, infrastructure changes, or risky touches), and MUST warn that it can take significant wall-clock time and consume a large token budget. The user decides; default stays change-scoped.
- **Actions.** `qa-engineer` authors and runs functional / API / e2e / harness / script tests / smoke for the changed surfaces. Tests reference contracts, not implementation internals. Oracles must be TIGHT per **Test oracles can be wrong** below. Manual smoke runs against the running solution (per the project's local-dev startup command), NOT against design artefacts. Runs under `### Iteration protocol` with estimation-first dispatch and stoppable intermediate states. When the user opts into full regression, it runs after the change-scoped pass is green and is reported separately.
- **Artefacts.** Test code in the project's test directory + per-project unit specs alongside source. Manual-smoke report. When full regression is run, a separate regression report with pass/fail counts per suite and the wall-clock + approximate token cost.
- **Acceptance.** Change-scoped suite executes green; oracle pass/fail accurately reflects correctness for the touched surfaces. Manual-smoke report recorded (with explicit caveat if smoke could not be run — e.g. headless). Failures route to Phase 6. Full regression, when requested, is its own pass on top of this gate, not a precondition for it.

### Phase 6 — Bug fixing
- **Goal.** Resolve defects found in Phase 5 (or manual smoke) until all oracles for the touched surfaces are green with no regressions in those surfaces.
- **Actions.** Engineer owning the failing surface fixes the defect. QA continues exercising other scenarios in parallel — a bug fix never freezes the test run. Routes back to the specific Phase 4 surface that broke, not a full Phase 4 rerun. Runs under `### Iteration protocol` with estimation-first dispatch and stoppable intermediate states.
- **Artefacts.** Edits to existing Phase 4 / Phase 5 artefacts.
- **Acceptance.** Change-scoped oracles green; no regression introduced in the touched surfaces. Manual smoke re-run if a user-visible surface was touched. Full regression, when the user opted into it in Phase 5, is part of that opt-in pass — not a Phase 6 gate.

### Phase 7 — SA review
- **Goal.** Confirm the result complies with architecture invariants, requirements, and mockup contracts before user approval.
- **Actions.** `solution-architect` reads the diff against architecture invariants (UX-responsiveness, layout-state contracts, module-dependency rules, etc.) and the mockup's behavioural contract. Verifies the Phase 5 manual-smoke section was actually written (empty section = REJECT, return to Phase 5). Sign-off; no code edits. Runs under `### Iteration protocol` when the review surfaces follow-up architecture-doc edits that exceed the 15-min threshold.
- **Artefacts.** Sign-off note in PR / final report; rarely a new ADR.
- **Acceptance.** APPROVE (with or without pending additive architecture-doc edits) or RETURN-TO-engineer with specific findings.

### Phase 8 — User approval
- **Goal.** User confirms the delivered work satisfies the `TODO` line.
- **Actions.** Orchestrator surfaces the work to the user per the Task model. If manual smoke wasn't run (e.g. headless), the orchestrator asks the user to run it. User picks "Yes — mark complete" or "No — needs more work" (loops back to Phase 6 with specific feedback).
- **Artefacts.** `TODO` line transition `☐` → `☒`. Project-progress refresh (if used). Commit (only when the user explicitly asks).
- **Acceptance.** User selects "Yes — mark complete".
- **Post-acceptance doc optimization hook.** If the task touched any documentation (project-instruction files, architecture docs, role definitions, ADRs, CRs, READMEs), the orchestrator MUST dispatch `ai-engineer` to run the Iteration protocol scoped to the doc diff from this task. Runs as a polish step, not a gate — does not block declaring the task complete. If `ai-engineer`'s first proposal batch returns "no productive proposals", the hook completes immediately (no-op acceptable). No user permission required to invoke; the user sees the cumulative optimization diff in the final report and may accept or revert as a unit.

### Cross-phase rule

Artefact classes do not cross phases. A change that needs both design and code runs through Phase 2 first (artefacts land in docs), then Phase 4 (artefacts land in the solution).

### Relation to the cross-domain bugs cycle

The four-phase model in "Cross-domain bugs — integration + compliance cycle" below is the specific instantiation of this lifecycle for bugs that cut across two or more domains. Its Phases 1–4 map onto lifecycle Phases 2 (contract change), 4 (domain implementations), 5–6 (integration + bug fixing), and 7 (compliance review). The design-review gate (lifecycle Phase 3) still applies when the bug requires user-visible behaviour change.

## Engineering principles — apply across all roles

### Configuration vs. data — declarative over imperative

Binds every role. Signal it belongs in a declarative file = "hard to change without editing imperative code".

**Configuration** (URLs, ports, env vars, feature flags, retention windows, defaults) → declarative files per tier. The project's stack determines the file format; representative tiers:

| Tier | Typical file |
|---|---|
| Service runtime | environment file / app-settings config |
| Client runtime | environment file / build-config |
| Container orchestration | `docker-compose.*.yml` / Helm values |
| IaC | `*.tfvars` / Pulumi config / etc. |
| Scripting / tooling | `*.json` / `*.yaml` config files |

Never as literals inside controllers, components, scripts, or test specs.

**Data** (fixtures, seed sets, snapshot baselines, expected payloads, scenarios) → dedicated declarative files (fixture JSON files, scenario markdown files, etc.). Never as inline literals inside test code.

**Imperative code stays thin** — scripts, runners, entry-point wrappers read from declarative files and call the underlying tool. A 200-line wrapper baking in URLs, tokens, and fixture payloads is a refactor target.

Exceptions require a doc update before they land.

### Test oracles can be wrong

A test that passes against broken software is a defect in the oracle, not a green light. When test results contradict observed behaviour, trust the observed behaviour and route to the test owner to tighten the assertion. Examples:

- A geometric harness anchored against the wrapper instead of the inner element passes on visual elements that visibly don't align.
- A test that POSTs and asserts a success status without asserting the response body shape passes even if the API returns garbage.
- A test that opens a UI element without exercising its action passes on a broken action.

The oracle is part of the contract. Tightening it is `qa-engineer`'s job; respecting that signal is everyone's.

## Documentation style — structure over prose

Applies to **all** written artefacts: project-instruction files, role definitions (`core/roles/`, `local/roles/`), future skills, the architecture doc, the mockup, ADRs, per-component READMEs.

- **Default to structure.** Bullets, numbered lists, tables, headings — not prose paragraphs.
- **Steps / actions / instructions → bullet list.** Never a multi-sentence paragraph.
- **Pairs, mappings, choices → table.** "Before / after", "old / new", "concern → owner", "endpoint → status code".
- **One idea per bullet.** Short, declarative, parseable. A bullet wanting three sentences → promote to sub-list or table.
- **Headings carry weight.** `##` / `###` to chunk; don't bury rules inside walls of prose.
- **Code shapes go in fenced code blocks.** Wire formats, env vars, file paths, commands.
- **Cross-reference, don't duplicate.** Cite the section ("per architecture-doc §X"); don't restate.
- **Drop filler.** No "It is important to note that…", "Please ensure…", "In general…". Lead with the verb or the noun.
- **Prose is for narrative exposition only** — explaining *why* something is the way it is. Keep tight.

When editing a doc, watch for prose paragraphs that should be a list, table, or table-of-rules — convert them.

## Coordination protocol

- Every PR description cites the requirement / NFR / section of the architecture doc — or the mockup section — implemented or validated. (See `core/templates/pr-description.md`.)
- Wire-contract breaking changes (API shape, event format, env var names) → flag in the PR title; service-owning role, client-owning role, and devops all confirm before merge.
- Cost-relevant changes (new resource, larger SKU) → fresh estimate vs. the project cost cap in the PR description; `devops-engineer` owns this.

### Strict-domain rule — no specialist works outside its domain

Clear boundaries between specialists are non-negotiable. A bug in domain X is fixed by the engineer who owns X — never by an adjacent specialist "while they're in the area". Cross-domain bugs require collaboration, not single-specialist heroics.

Project-specific forbidden role-crossings table lives in `local/bindings.md` under "Project role boundaries". Each row is a hard stop — propose a hand-off in the final report instead.

**Pattern.** A typical UX-responsiveness invariant exemplifies the collaboration pattern this rule enforces — an invariant defined by `solution-architect` in the architecture doc, encoded as a harness assertion by `qa-engineer`, and satisfied by the mockup-owning role in mockup CSS/JS. Each domain stays in its lane; end-to-end correctness comes through composition, not boundary-crossing.

### Doc co-ownership — solution-architect ↔ ai-engineer

Documentation (project-instruction files, this file, ADRs, READMEs, role definitions, skills) is co-owned: `solution-architect` owns **semantics**; `ai-engineer` owns **shape and load topology**. The two roles never override each other's invariants. Doc co-ownership runs under the generalized `### Iteration protocol — propose → review → implement` below.

| Scenario | Routing |
|---|---|
| New rule / invariant / routing entry / governance decision → write content | `solution-architect`. `ai-engineer` may run a structural pass after. |
| Existing doc grows past size threshold or exhibits duplication | `ai-engineer` compacts / splits. SA post-reviews to verify no rule lost. |
| Cross-references break from a split or move | `ai-engineer` updates references; SA verifies semantic continuity. |
| Doc edit needed AND scope is unclear | Pair-dispatch in one phase — SA edits content; `ai-engineer` edits shape. SA first. |
| Disagreement (SA wants prose for clarity; `ai-engineer` wants table for compactness) | SA wins on semantics; `ai-engineer` may propose alternative structure that preserves clarity. |

**Hard rule — `ai-engineer`'s edits are lossless.** Before completing any optimization pass, `ai-engineer` must spot-check that every rule, invariant, routing entry, and gate in the diff appears (verbatim or semantically identical) in the new structure. If any cannot be proved → revert and re-plan.

**Dispatch trigger.** `ai-engineer` is not part of the standard Phase 1–8 lifecycle. Invoked between phases when:
- User explicitly targets AI-asset or doc optimization.
- SA flags "this doc is getting unwieldy" in their final report.
- Periodic maintenance (release cadence, post-large-feature cleanup).
- Phase 8 post-acceptance doc-optimization hook fires (see Phase 8).

### Iteration protocol — propose → review → implement

Generalized loop for **all team work in Phases 4–7** (Implementation, Testing, Bug fixing, SA review) with estimated total scope > 15 min, and for doc co-ownership passes between `ai-engineer` and `solution-architect`. Dispatched specialists work in iterations under this protocol; user intervention is bounded to kickoff approval and the final report.

The cycle:

- **propose** = each dispatched specialist responds with a task decomposition + per-task time estimate (no code / tests / fixes / edits yet).
- **review** = orchestrator synthesizes proposals across all dispatched specialists and surfaces the batch (total + per-task breakdown) to the user when the scope warrants; user approves the batch or redirects.
- **implement** = each specialist executes its approved batch in iterations of 3–5 min, each iteration producing a visible, resumable result per `### Stoppable intermediate states` below.

**Estimation-first dispatch.** Before any code / tests / fixes / doc edits, each dispatched specialist MUST respond with a task decomposition (list of sub-tasks) + per-task time estimate. Orchestrator synthesizes across all specialists, surfaces total + per-task breakdown to the user, and waits for approval or redirect before letting any specialist enter the implement step. This applies to Phase 4 (implementation), Phase 5 (testing), Phase 6 (bug fixing), Phase 7 (SA review), and to `ai-engineer` ↔ SA doc co-ownership passes.

**Sizing the iterations.**

| Estimated total scope | Approach |
|---|---|
| ≤ 15 min | Single iteration: specialist proposes the full pass; reviewer (orchestrator / SA / user as appropriate) reviews; specialist implements. |
| > 15 min | Multiple short iterations of 3–5 min each; each iteration produces a visible partial result. Specialist scopes the next batch (3–7 sub-tasks) at the start of each iteration. |

**Each iteration.**

1. **Propose.** Dispatched specialist submits a structured proposal listing each sub-task: change / where / why / risk / time estimate (+ lossless evidence for doc work). No edits yet.
2. **Review.** Reviewer responds per item — accept / decline / accept-with-modification, each with one-line reasoning. Reviewer = `solution-architect` for doc co-ownership semantics; orchestrator (surfacing to user when scope warrants) for Phase 4–7 engineering work.
3. **Implement.** Specialist executes accepted items — applies reviewer's modifications, runs domain self-check (build / lint / harness / lossless check as applicable), updates cross-references in dependent files. Each iteration ends in a stoppable intermediate state.

**Loop termination.**

- Specialist reports "no further productive proposals" in its next batch, OR
- Specialist or reviewer hit semantic territory only the user can decide, OR
- Pre-agreed budget exhausted, OR
- User stops the team at any iteration boundary per `### Stoppable intermediate states`.

**Conflict resolution.** Tie-breaker: `solution-architect` wins on doc semantics; the domain-owning specialist wins on implementation craft within their domain (per `local/bindings.md` → "Project role boundaries"); user wins on product intent. Specialist may re-propose with new evidence ONCE per item; second decline is final.

**Orchestrator role.** Drives the loop — dispatches the three steps each iteration. Surfaces the estimation batch to the user before the implement step begins; surfaces intermediate results after each iteration when the user has asked for visibility or when an iteration revealed something the user should redirect on. User involvement otherwise bounded to kickoff (scope + budget) and final report.

### Stoppable intermediate states

Each iteration under `### Iteration protocol` must leave the system in a valid, resumable state:

- Engineers do not leave half-written code that breaks the build, fails type-check, or fails per-project unit tests.
- QA does not leave partial test runs that pollute fixtures, leave seeded data behind, or leave the local stack in a non-reproducible state.
- Bug fixes do not half-apply (e.g. service half of a contract change landed, client half pending — gate behind a feature flag or stage the contract change behind a no-op default).
- Doc edits do not leave broken cross-references or orphaned sections.

User can stop the team at any iteration boundary. Orchestrator's stop report includes:

- **Done** — sub-tasks completed, with files touched.
- **In-progress** — sub-task interrupted, with the partial state recorded and the concrete resume instructions (same partial-result format as `### Timeframe-bounded autonomous work`).
- **Not-started** — sub-tasks remaining in the approved batch, with original estimates intact.

The user must be able to continue next day or later from the recorded state with zero rework — no recovering half-finished refactors, no re-deriving which test was running, no guessing which contract version is on disk.

### Timeframe-bounded autonomous work

When the user gives a timeframe (e.g., "spend 30 min on X", "do as much as you can in an hour"), the orchestrator treats it as a budget for autonomous work:

- Work autonomously for the full period — drive multi-specialist loops, run sequential dispatches, iterate.
- The boundary is the checkpoint — report at the end, not before.
- Results may be **full** (everything done), **partial** (ran out of budget), or **early** (done sooner than expected). All three are acceptable; honesty about which is required.
- No per-iteration check-ins. Only valid mid-flight interrupts: scope creep, genuine ambiguity, semantic conflict the orchestrator can't resolve.
- For partial results, the report must include a clear **done / in-progress / not-started** breakdown + concrete instructions to resume.

Pairs with the Iteration protocol above: timeframe-bounded work runs iterations through that protocol until the timeframe expires, with each iteration ending in a stoppable intermediate state per `### Stoppable intermediate states`.

### Cross-domain bugs — integration + compliance cycle

When a bug spans two or more domains, the work follows a four-phase model. The orchestrator dispatches each phase deliberately — parallel where work is independent, sequential only where a real dependency exists.

**Phase 1 — contract change (sequential).** If the bug requires a contract change (architecture invariant, requirement addition, wire shape, env var), `solution-architect` lands the doc change first. Engineers cannot start their parts until the contract wording exists.

**Phase 2 — domain implementations (parallel by default).** Each engineering domain implements its own part independently. The orchestrator MUST dispatch all independent domain parts in a single message. Domain parts are independent when:
- Domain A's deliverable is not required to compile, run, or pass tests in domain B's source tree.
- Both domains can reference the Phase 1 contract wording without needing each other's code.

Sequential is correct only when one domain's output is a literal input to the next (e.g. a generated type the next specialist imports).

**Phase 3 — integration verification (sequential, at the join point).** The specialist closest to the user-facing surface (mockup-owning role for UI bugs, service-owning role for API bugs, devops for deploy bugs) runs the shared oracle end-to-end and confirms all Phase 2 deliverables compose correctly.

**Automated tests are necessary but not sufficient.** For any change that adds or modifies user-facing behaviour, Phase 3 also requires a **manual smoke** by the integrator **against the running solution** (per the project's local-dev startup command) — NOT against the mockup or other design artefact:

1. Wipe and re-seed the local stack to a clean state before opening the browser / running the user-facing surface.
2. Exercise every NEW user-facing flow in real conditions — clicks, dropdowns, toggles, switchers, picker UIs. Not "the page renders"; "the feature does the thing".
3. Compare the running system's behaviour against the mockup or the architecture doc's described behaviour (mockup is the oracle; running system is the subject under test). If a feature looks wrong but tests say "PASS", route to `qa-engineer` to tighten assertions — NOT call it green.
4. Record manual smoke results in the Phase 3 report (one line per new feature).

If the integrator cannot run the user-facing surface (e.g. headless), state so explicitly. Do not claim manual smoke as PASS without doing it. If integration fails (automated OR manual), return to the specific Phase 2 domain that broke — not a full rerun.

**Phase 4 — compliance review (sequential, final).** `solution-architect` reviews against architecture invariants and the mockup contract. Sign-off, no edits. If invariants are violated, returns to Phase 2. SA's review must verify the integrator's manual-smoke report was actually written (empty section = REJECT, return to Phase 3).

**Sign-off in PR description.** Each domain notes which part it owned; the integrator notes the verification command/output; `solution-architect` notes which requirement / section the result satisfies.

**Generic worked example.** A UI invariant exception in a particular view — e.g. "in View X, attribute Y renders inline rather than as a separate label":

| Phase | Dispatch | Role(s) | Work |
|---|---|---|---|
| 1 | sequential | `solution-architect` | Amend the architecture-doc invariant with the View-X exception sentence. |
| 2 | **parallel — one message** | `qa-engineer` **and** mockup-owning role | qa: add `viewExceptions.viewX` flag to the harness config + branch the spec. Mockup-owning role: implement the inline render in the View-X template + mirror the invariant into the mockup head comment. |
| 3 | sequential | mockup-owning role | Run the harness; expect all-green. |
| 4 | sequential | `solution-architect` | Compliance review against amended invariant; sign-off without edits. |

**Anti-pattern.** Dispatching `qa-engineer` and the mockup-owning role serially in Phase 2. Their deliverables touch different source trees (harness directory vs mockup file) and both reference only the Phase 1 architecture wording — no input/output dependency. Serializing doubles wall-clock time for no benefit.

The anti-pattern this replaces: `solution-architect` editing mockup HTML/CSS/JS directly across multiple failed rounds. That was a strict-domain violation regardless of intent — mockup edits are mockup-owning-role craft.

### Cross-agent handoff — diagnose ≠ fix

When a specialist discovers a root cause **outside** their domain while working on their own task:

1. **Diagnose fully; do NOT fix.** Cross-domain patches cause silent contract drift. Write up: failing command, verbatim error, file + line, chain of reasoning. (Template: `core/templates/hand-off-note.md`.)
2. **Hand off** to the owning specialist (project routing table in `local/bindings.md`). Hand-off package includes: symptom, verified root cause with evidence, what the discoverer tried and ruled out, any local workaround in place + whether to remove it once the proper fix lands.
3. **Both specialists stay engaged.** Owner fixes; discoverer reviews and removes any workaround. Not throw-over-the-wall.
4. **Workarounds are temporary, labelled as such.** Example: devops adds a defensive ignore-file to mask a host-side leak. Stays only until the owning specialist lands the proper fix; both specialists acknowledge in reports.
5. **Out-of-competence fixes are disallowed** — see `local/bindings.md` → "Project role boundaries" for the complete forbidden list. Pattern examples:
   - Client-owning role "just tweaks" SQL in a service endpoint → no.
   - Devops "just edits" a build manifest to dodge a dependency issue → no.
   - Service-owning role "just rewrites" an E2E spec → no.
   - `solution-architect` "just patches" mockup CSS to satisfy an invariant → no; hand off to the mockup-owning role.

Main thread orchestrates the hand-off — when a specialist flags a root cause outside their domain in their final report, dispatch the owning specialist next with the prior diagnosis verbatim.

**Doc updates always route through the doc's owner.**
- Architecture doc / project-instruction files / process docs / ADRs → `solution-architect`.
- Mockup → mockup-owning role for HTML/CSS/JS/SVG edits; `solution-architect` for governance review only.

When any engineer flags a needed change, the next dispatch is the owning specialist with the flagged change. Engineers outside the owning domain never edit these files directly.

## Task model

The phased lifecycle (Phase 1–8) applies to any task. A task originates from one of three sources:

| Source | Scope | State mechanic |
|---|---|---|
| Repo-root `TODO` (file name per `local/framework.config.yaml` → `todo`) | Project-wide | Glyphs `☐` / `☒`; orchestrator updates the line on completion |
| Nested `TODO` (e.g., `client/TODO`, `service/api/TODO`) | Component-scoped | Same glyph mechanic, scoped to that component file |
| Direct user instruction | Ad hoc; scope inferred from the instruction | No `TODO` file; no glyph mechanic |

`TODO` at any location is user-curated — never auto-generated, never auto-extended. Glyphs: `☐` = open, `☒` = completed.

### Post-task check-in

**After every completed user request** (work delivered or question answered), in this order:

1. **Pick the next pending item to surface.**
   - If the user was operating in a component context AND a nested `TODO` exists at that component → check it first.
   - Otherwise → check the repo-root `TODO`.
   - If both have pending items and the context is ambiguous → ask which to consult.
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

4. **For direct-instruction tasks** — no `TODO` state to update. Acceptance is the user's explicit confirmation. Skip the glyph mechanic; the post-Phase-8 hook still applies (per `### Phase 8 — User approval`).

Rules:
- `TODO` checks happen **between** user requests — not in the middle of one.
- `TODO` items are user-grained, larger than in-conversation tasks. Mark both when the same work completes.
- Never auto-add to any `TODO` file. Mention follow-up work → *offer* to add it; do not act unilaterally.
- User says "skip TODO" for this turn → honour it; resume next turn.
- **Discovering nested `TODO`s.** Orchestrator may glob for `**/TODO` on session start or when entering a component context — but only surface them if the user is operating in that context.
