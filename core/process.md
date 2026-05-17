# Engineering Process

## Purpose

Generic, project-agnostic process model for a small multi-agent engineering team. Authoritative spec for every role (orchestrator + specialists). Project-specific knowledge (stack, repo layout, role roster, forbidden role-crossings, owned-paths bindings) lives in `local/bindings.md` and `local/project-profile.md` — never in this file.

## Reading order

| File | Role | Owner |
|---|---|---|
| `core/process.md` (this file) | Generic lifecycle, dispatch rules, principles | upstream framework |
| `core/roles/*.md` | Generic role charters (7 cardinals) | upstream framework |
| `local/bindings.md` | Per-project role → owned paths/concerns table | the project |
| `local/project-profile.md` | Per-project stack, domain, architecture artefacts | the project (written by `project-manager` on discovery) |
| `local/framework.config.yaml` | Concept → file-path mapping (architecture doc, mockup, API contract, ADR dir, TODO file, ...) | the project |

Conflict resolution: per-project routing → `local/bindings.md` wins; generic process rule → `core/process.md` wins. Bindings may NOT override generic process.

## Dispatch & parallelism rules

| Rule | Action |
|---|---|
| Independent work (no shared contract change) | Dispatch specialists in parallel in ONE message. |
| N independent specialists in one phase | ONE message with N dispatch calls. Never serialize across messages. |
| Cross-phase overlap (e.g. quality authoring tests while client implements) | ONE message with all overlapping specialists; each prompt names the shared contract surface (architecture-doc §X, mockup behaviour Y, wire shape Z). |
| Parallel-by-default for cross-domain Phase 2 | Default for Phase 2 of the cross-domain cycle is parallel. Justify any sequential Phase 2 dispatch in the dispatch prompt itself (one sentence). Habitual serialization is the failure mode. |
| Doc-only changes | `solution-architect` only (architecture-family) or mockup-owning role only (UI-only edit with no architecture implication). |
| Infrastructure changes affecting application config (env var, secret, endpoint URL) | Coordinate `devops-engineer` + affected service-owning role; service-owner first to confirm the app reads the new value, devops second. |

Overlap patterns — next phase starts when its contract surface is fixed, not when prior phase's code lands:

- **Test authoring overlaps implementation.** Once Phase 2 fixes wire shape / mockup behaviour, `qa-engineer` authors specs and fixtures in parallel with implementation. Both reference the contract, not each other's source.
- **Bug fix overlaps continued testing.** QA reports a defect; owning engineer fixes immediately while QA exercises other scenarios.
- **Doc update overlaps implementation.** `solution-architect` hands engineers the contract context; engineers proceed; SA updates architecture doc / project instructions / ADRs in parallel. The doc commit is a paper trail, not a gate.

Implementation gate: Phase 4 starts only when the Phase 2 contract surface is fixed AND the Phase 3 design-review gate has passed. No engineer codes against an unapproved design.

## Task lifecycle — phased pipeline with maximum parallelism

Binding. Phases are named and ordered; specialists within a phase run in parallel; phases overlap wherever a contract surface decouples them. Each phase: **Goal · Acceptance**.

### Phase 1 — Analysis
- **Goal.** Bound scope; identify touched domains. Read TODO line + relevant architecture sections + mockup + code. Surface ambiguities; decide Phase 2 dispatches.
- **Acceptance.** Scope bounded enough to plan Phase 2 dispatches. ≤ 1 unresolved scope question outstanding.

### Phase 2 — Design & architecture
- **Goal.** Lock contracts (system, API, visual, work breakdown) before any code. `solution-architect` ratifies the API contract before Phase 3; doc / mockup / wire-contract edits route to the owning role per `local/bindings.md`. Parallel where independent.
- **Acceptance.** Fixed wire shape + fixed mockup behaviour + fixed work breakdown. Visual / contract harness green (where one exists). Cross-references resolved. Artefacts presentable as a coherent whole.

### Phase 3 — Design review
- **Goal.** Synchronous gate: explicit user approval of Phase 2 design before implementation effort is spent. Orchestrator MUST present Phase 2 artefacts (architecture-doc diff, mockup link, API contract, work-breakdown). Remarks loop back to Phase 2. Distinct from Phase 8 (closes TODO line) and the TODO-workflow checkpoint (sits before Phase 1).
- **Acceptance.** Explicit user approval. Without it, Phase 4 does not start.
- **In automatic mode.** Elided when Phase 2 produces no user-visible behaviour change. Forced back to interactive per § Automatic mode → Forced-interactive triggers.

### Phase 4 — Implementation
- **Goal.** Working code mirroring approved Phase 2 contracts. Each engineering role implements its part in its owned paths (per `local/bindings.md`); Phase 5 overlaps once Phase 3 passes; parallel where independent. Runs under `### Iteration protocol`.
- **Acceptance.** Compiles / builds clean. Per-project unit tests pass. No new lint or type errors.

### Phase 5 — Testing
- **Goal.** Verify implementation against contracts via executable suites + manual smoke against the running solution.
- **Scope — change-scoped by default.** Run only tests covering changed surfaces: new/modified functional / API / e2e / harness / script scenarios for touched code paths; per-project unit specs in modified files; any pre-existing scenario whose covered contract was edited in Phase 2 or 4. **Full regression is opt-in** — only when the user explicitly asks; `project-manager` may remind it's available (wide-reach refactors, infra changes, risky touches) and MUST warn of significant wall-clock + token cost. Tests reference contracts, not implementation internals. Oracles TIGHT per § Test oracles can be wrong. Manual smoke runs against the running solution (project's local-dev startup command), NOT against design artefacts. Runs under `### Iteration protocol`. Opt-in full regression runs after change-scoped pass is green and is reported separately (pass/fail per suite, wall-clock + approximate token cost).
- **Acceptance.** Change-scoped suite green; oracles accurately reflect correctness for touched surfaces. Manual-smoke report recorded (caveat if not run, e.g. headless). Failures route to Phase 6. Opt-in full regression, when requested, is its own pass — not a precondition.

### Phase 6 — Bug fixing
- **Goal.** Resolve defects from Phase 5 (or manual smoke) until all change-scoped oracles are green. Owning engineer fixes the failing surface; QA exercises other scenarios in parallel — a bug fix never freezes the test run. Routes back to the specific Phase 4 surface, not a full Phase 4 rerun. Runs under `### Iteration protocol`.
- **Acceptance.** Change-scoped oracles green; no regression in touched surfaces. Manual smoke re-run if a user-visible surface was touched. Opt-in full regression is part of that opt-in pass — not a Phase 6 gate.

### Phase 7 — SA review
- **Goal.** `solution-architect` confirms compliance with architecture invariants, requirements, and mockup behavioural contracts. Verifies Phase 5 manual-smoke section was actually written (empty = REJECT, return to Phase 5). Sign-off; no code edits. Runs under `### Iteration protocol` when follow-up architecture-doc edits exceed 15 min.
- **Acceptance.** APPROVE (with or without pending additive architecture-doc edits) or RETURN-TO-engineer with specific findings.

### Phase 8 — User approval
- **Goal.** User confirms delivered work satisfies the TODO line. Orchestrator surfaces per the Task model; if manual smoke wasn't run (e.g. headless), asks the user to run it. User picks "Yes — mark complete" or "No — needs more work" (loops back to Phase 6 with feedback).
- **Acceptance.** User selects "Yes — mark complete". On accept: TODO line `☐` → `☒`, project-progress refresh (if used), commit only when the user explicitly asks.
- **In automatic mode.** Realized as the **delivery handoff** (§ Automatic mode → Delivery handoff). User-approval invariant preserved (single explicit accept); three actions — Accept / Feedback / Reject — replace yes/no.
- **Post-acceptance doc optimization hook.** If the task touched any documentation (project-instruction files, architecture docs, role definitions, ADRs, CRs, READMEs), orchestrator MUST dispatch `ai-engineer` to run `### Iteration protocol` scoped to the doc diff. Polish step, not a gate. If first proposal batch returns "no productive proposals", hook completes immediately. No user permission required; user sees the cumulative optimization diff in the final report and may accept or revert as a unit.

### Cross-phase rule

Artefact classes do not cross phases. A change needing both design and code runs through Phase 2 first (docs), then Phase 4 (solution).

### Relation to the cross-domain bugs cycle

The four-phase model in § Cross-domain bugs is the specific instantiation of this lifecycle for bugs cutting across two or more domains. Its Phases 1–4 map onto lifecycle Phases 2 (contract change), 4 (domain implementations), 5–6 (integration + bug fixing), and 7 (compliance review). The design-review gate (lifecycle Phase 3) still applies when the bug requires user-visible behaviour change.

## Automatic mode

For low-risk or self-contained tasks, the lifecycle runs end-to-end without per-phase user gates, presenting only a single **delivery handoff** at the end. Phase 8 user-approval invariant preserved as that one final gate; not waived.

### Activation

- **Explicit, per-task only.** Never session-wide; never inherited across tasks.
- **Triggers.** User prefixes the task with `auto:` or addresses `project-manager` with `auto`. Alternatively, `project-manager` may **propose** auto mode for a task it judges low-risk (docs-only edit, isolated bug fix in a single owned path, mechanical refactor) — user must reply "yes, auto" or equivalent. Orchestrator never enters auto mode silently.
- Recorded in orchestrator's plan for that task.

### Gates elided in auto mode

- **Phase 3 — Design review.** Auto-approved when Phase 2 produces no user-visible behaviour change OR the user already approved the broader direction. Material UX surfaces still escalate (see Forced-interactive triggers).
- **Iteration-protocol intermediate-batch user confirmations.** Iterations still run as 3–5 min stoppable batches, but orchestrator does NOT pause between batches. User may interrupt at any time; next batch boundary is the safe stop.
- **Per-step "stop and confirm" pauses inside engineers.** Engineers proceed once the iteration's intermediate state is recorded.

### Gates still respected in auto mode

- **Phase 7 — SA review.** Runs as normal. Automated; no user interaction required.
- **Destructive / external actions** (per "Executing actions with care" guidance in project-instruction files). Even in auto mode, do not push to shared branches, drop or downgrade dependencies, modify shared infrastructure, send messages, or contact external services without explicit consent. Default delivery handoff does NOT push.
- **Full regression remains opt-in** (per § Phase 5 Scope). Auto mode does NOT request it. Delivery report records that full regression was not run and that the user may request it before accept.
- **Phase 8 user-approval invariant.** Preserved as the single delivery handoff at the end.

### Forced-interactive triggers — auto mode falls back to interactive when

| Trigger | Action |
|---|---|
| Phase 2 surfaces a design choice with material user-visible impact (new screen, changed wire shape adopters depend on, new external dependency, NFR-affecting trade-off) | Pause; surface Phase 2 artefacts per Phase 3; resume on approval. |
| Phase 6 fails to resolve the same defect after 2 iteration batches | Pause; surface defect, attempted fixes, proposed next step. |
| A cross-domain integration cycle is required (per § Cross-domain bugs) | Pause; surface integration scope and dispatch plan. |
| A test oracle is found to be wrong (per § Test oracles can be wrong) | Pause; surface observed vs asserted divergence and oracle-tightening proposal. |
| Token-budget consumed exceeds 1.5× the Phase 4/5 estimate OR wall-clock exceeds 2× the estimate | Pause; surface burn rate; request continue-or-stop. |
| Any planned action enters the "destructive / external" set above | Pause; surface action + reason + alternatives. |

On any trigger: `project-manager` halts dispatch, presents a short interactive-fallback report, resumes auto mode only on explicit user direction.

### Delivery handoff (replaces Phase 8 in auto mode)

- Working tree contains all changes. **Nothing committed yet; nothing pushed.**
- `project-manager` produces a **delivery report**:
  - TODO line(s) addressed.
  - Phase 2 / 4 / 5 artefact deltas summarized (files touched, contracts changed).
  - Change-scoped test results (pass/fail per suite, manual-smoke note).
  - SA review sign-off.
  - "Full regression: not run (auto mode). Request before accept if desired."
  - Any forced-interactive escalations during the run.
  - Suggested commit message(s) per project's commit convention from `local/bindings.md`.
- `project-manager` presents three actions:
  1. **Accept** — `project-manager` commits per project convention. Push only if user explicitly says push. On accept, transition TODO `☐` → `☒`.
  2. **Feedback** — user supplies remarks; `project-manager` loops back to the relevant earlier phase (typically Phase 6) and resumes auto mode toward a fresh delivery handoff.
  3. **Reject** — `project-manager` rolls the working tree back to pre-task state. User may re-prompt with adjustments.
- Auto mode NEVER commits, pushes, or transitions the TODO without the user's explicit accept at this gate.

## Engineering principles — apply across all roles

### Configuration vs. data — declarative over imperative

Binds every role. Signal it belongs in a declarative file = "hard to change without editing imperative code".

**Configuration** (URLs, ports, env vars, feature flags, retention windows, defaults) → declarative files per tier (project stack determines format):

| Tier | Typical file |
|---|---|
| Service runtime | environment file / app-settings config |
| Client runtime | environment file / build-config |
| Container orchestration | `docker-compose.*.yml` / Helm values |
| IaC | `*.tfvars` / Pulumi config / etc. |
| Scripting / tooling | `*.json` / `*.yaml` config files |

Never as literals inside controllers, components, scripts, or test specs.

**Data** (fixtures, seed sets, snapshot baselines, expected payloads, scenarios) → dedicated declarative files. Never as inline literals inside test code.

**Imperative code stays thin** — scripts/runners/wrappers read declarative files and call the underlying tool. Exceptions require a doc update before they land.

### Test oracles can be wrong

A test that passes against broken software is a defect in the oracle, not a green light. When test results contradict observed behaviour, trust the observed behaviour and route to the test owner to tighten the assertion. Examples: harness anchored to wrapper not inner element; POST asserting status without response shape; UI element opened without exercising its action. Tightening is `qa-engineer`'s job; respecting that signal is everyone's.

## Documentation style — structure over prose

Applies to **all** written artefacts: project-instruction files, role definitions (`core/roles/`, `local/roles/`), future skills, architecture doc, mockup, ADRs, per-component READMEs.

- **Default to structure.** Bullets, numbered lists, tables, headings — not prose paragraphs.
- **Steps / actions / instructions → bullet list.** Never a multi-sentence paragraph.
- **Pairs, mappings, choices → table.** "Before / after", "concern → owner", "endpoint → status code".
- **One idea per bullet.** A bullet wanting three sentences → promote to sub-list or table.
- **Headings carry weight.** `##` / `###` to chunk; don't bury rules inside walls of prose.
- **Code shapes go in fenced code blocks.** Wire formats, env vars, file paths, commands.
- **Cross-reference, don't duplicate.** Cite the section ("per architecture-doc §X"); don't restate.
- **Drop filler.** No "It is important to note that…", "Please ensure…", "In general…". Lead with the verb or noun.
- **Prose is for narrative exposition only** — explaining *why*. Keep tight.

## Coordination protocol

- Every PR description cites the requirement / NFR / section of the architecture doc — or the mockup section — implemented or validated. (See `core/templates/pr-description.md`.)
- Wire-contract breaking changes (API shape, event format, env var names) → flag in PR title; service-owning role, client-owning role, and devops all confirm before merge.
- Cost-relevant changes (new resource, larger SKU) → fresh estimate vs. project cost cap in PR description; `devops-engineer` owns this.

### Strict-domain rule — no specialist works outside its domain

A bug in domain X is fixed by the engineer who owns X — never by an adjacent specialist "while they're in the area". Cross-domain bugs require collaboration, not single-specialist heroics.

Project-specific forbidden role-crossings table lives in `local/bindings.md` under "Project role boundaries". Each row is a hard stop — propose a hand-off in the final report instead.

### Doc co-ownership — solution-architect ↔ ai-engineer

Documentation (project-instruction files, this file, ADRs, READMEs, role definitions, skills) is co-owned: `solution-architect` owns **semantics**; `ai-engineer` owns **shape and load topology**. Neither overrides the other's invariants. Runs under `### Iteration protocol` below.

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

Generalized loop for **all team work in Phases 4–7** (Implementation, Testing, Bug fixing, SA review) with estimated total scope > 15 min, and for doc co-ownership passes between `ai-engineer` and `solution-architect`. User intervention bounded to kickoff approval and final report.

**Estimation-first dispatch.** Before any code / tests / fixes / doc edits, each dispatched specialist MUST respond with task decomposition + per-task time estimate (no edits yet). Orchestrator synthesizes, surfaces total + per-task breakdown to the user when scope warrants, waits for approval or redirect before any specialist enters implement. Applies to Phase 4, Phase 5, Phase 6, Phase 7, and `ai-engineer` ↔ SA doc co-ownership passes.

**Sizing.**

| Estimated total scope | Approach |
|---|---|
| ≤ 15 min | Single iteration: specialist proposes full pass; reviewer (orchestrator / SA / user as appropriate) reviews; specialist implements. |
| > 15 min | Multiple short iterations of 3–5 min each; each produces a visible partial result. Specialist scopes the next batch (3–7 sub-tasks) at the start of each iteration. |

**Each iteration.**
1. **Propose.** Specialist submits structured proposal listing each sub-task: change / where / why / risk / time estimate (+ lossless evidence for doc work). No edits yet.
2. **Review.** Reviewer responds per item — accept / decline / accept-with-modification, each with one-line reasoning. Reviewer = `solution-architect` for doc co-ownership semantics; orchestrator (surfacing to user when scope warrants) for Phase 4–7 engineering work.
3. **Implement.** Specialist executes accepted items — applies reviewer's modifications, runs domain self-check (build / lint / harness / lossless check as applicable), updates cross-references in dependent files. Ends in a stoppable intermediate state per `### Stoppable intermediate states`.

**Loop termination.** Specialist reports "no further productive proposals" in next batch, OR specialist/reviewer hit semantic territory only the user can decide, OR pre-agreed budget exhausted, OR user stops at any iteration boundary.

**Conflict resolution.** `solution-architect` wins on doc semantics; the domain-owning specialist wins on implementation craft within their domain (per `local/bindings.md` → "Project role boundaries"); user wins on product intent. Specialist may re-propose with new evidence ONCE per item; second decline is final.

**Orchestrator role.** Dispatches the three steps each iteration. Surfaces the estimation batch before implement; surfaces intermediate results on user request or when an iteration revealed something to redirect on.

### Stoppable intermediate states

Each iteration under `### Iteration protocol` must leave the system in a valid, resumable state:

- Engineers do not leave half-written code that breaks the build, fails type-check, or fails per-project unit tests.
- QA does not leave partial test runs that pollute fixtures, leave seeded data behind, or leave the local stack in a non-reproducible state.
- Bug fixes do not half-apply (e.g. service half of a contract change landed, client half pending — gate behind a feature flag or stage the contract change behind a no-op default).
- Doc edits do not leave broken cross-references or orphaned sections.

User can stop the team at any iteration boundary. Orchestrator's stop report includes:

- **Done** — sub-tasks completed, with files touched.
- **In-progress** — sub-task interrupted, with partial state recorded and concrete resume instructions (same partial-result format as `### Timeframe-bounded autonomous work`).
- **Not-started** — sub-tasks remaining in the approved batch, with original estimates intact.

Continuation from the recorded state must require zero rework.

### Timeframe-bounded autonomous work

When the user gives a timeframe (e.g., "spend 30 min on X", "do as much as you can in an hour"), orchestrator treats it as a budget for autonomous work:

- Work autonomously for the full period — drive multi-specialist loops, run sequential dispatches, iterate.
- Boundary is the checkpoint — report at the end, not before.
- Results may be **full** (everything done), **partial** (ran out of budget), or **early** (done sooner than expected). All three acceptable; honesty about which is required.
- No per-iteration check-ins. Only valid mid-flight interrupts: scope creep, genuine ambiguity, semantic conflict the orchestrator can't resolve.
- For partial results, report must include a clear **done / in-progress / not-started** breakdown + concrete resume instructions.
- Runs iterations through `### Iteration protocol` until the timeframe expires, each ending in a stoppable intermediate state.

### Cross-domain bugs — integration + compliance cycle

When a bug spans two or more domains, work follows a four-phase model — parallel where independent, sequential only where a real dependency exists.

**Phase 1 — contract change (sequential).** If the bug requires a contract change (architecture invariant, requirement addition, wire shape, env var), `solution-architect` lands the doc change first. Engineers cannot start their parts until the contract wording exists.

**Phase 2 — domain implementations (parallel by default).** Each engineering domain implements its own part independently. Orchestrator MUST dispatch all independent domain parts in a single message. Domain parts are independent when (a) domain A's deliverable is not required to compile, run, or pass tests in domain B's source tree, and (b) both domains can reference the Phase 1 contract wording without needing each other's code. Sequential is correct only when one domain's output is a literal input to the next (e.g. a generated type the next specialist imports).

**Phase 3 — integration verification (sequential, at the join point).** The specialist closest to the user-facing surface (mockup-owning role for UI bugs, service-owning role for API bugs, devops for deploy bugs) runs the shared oracle end-to-end and confirms all Phase 2 deliverables compose correctly.

**Automated tests are necessary but not sufficient.** For any change adding or modifying user-facing behaviour, Phase 3 also requires a **manual smoke** by the integrator **against the running solution** (project's local-dev startup command) — NOT against the mockup or other design artefact:
1. Wipe and re-seed the local stack before opening the user-facing surface.
2. Exercise every NEW user-facing flow in real conditions — not "the page renders", but "the feature does the thing".
3. Compare running system vs. mockup or architecture doc (mockup = oracle; running system = SUT). If a feature looks wrong but tests say "PASS", route to `qa-engineer` to tighten assertions — NOT call it green.
4. Record manual smoke results in the Phase 3 report (one line per new feature).

If integrator cannot run the user-facing surface (e.g. headless), state so explicitly. Do not claim manual smoke as PASS without doing it. If integration fails (automated OR manual), return to the specific Phase 2 domain that broke — not a full rerun.

**Phase 4 — compliance review (sequential, final).** `solution-architect` reviews against architecture invariants and the mockup contract. Sign-off, no edits. If invariants violated, returns to Phase 2. SA's review must verify the integrator's manual-smoke report was actually written (empty section = REJECT, return to Phase 3).

**Sign-off in PR description.** Each domain notes which part it owned; integrator notes verification command/output; `solution-architect` notes which requirement / section the result satisfies.

### Cross-agent handoff — diagnose ≠ fix

When a specialist discovers a root cause **outside** their domain while working on their own task:

1. **Diagnose fully; do NOT fix.** Cross-domain patches cause silent contract drift. Write up: failing command, verbatim error, file + line, chain of reasoning. (Template: `core/templates/hand-off-note.md`.)
2. **Hand off** to the owning specialist (project routing table in `local/bindings.md`). Package: symptom, verified root cause with evidence, what the discoverer tried and ruled out, any local workaround in place + whether to remove it once the proper fix lands.
3. **Both specialists stay engaged.** Owner fixes; discoverer reviews and removes any workaround. Not throw-over-the-wall.
4. **Workarounds are temporary, labelled as such.** Stay only until the owning specialist lands the proper fix; both specialists acknowledge in reports.
5. **Out-of-competence fixes are disallowed** — see `local/bindings.md` → "Project role boundaries" for the complete forbidden list.

Main thread orchestrates the hand-off — when a specialist flags a root cause outside their domain in their final report, dispatch the owning specialist next with the prior diagnosis verbatim.

**Doc updates always route through the doc's owner.**
- Architecture doc / project-instruction files / process docs / ADRs → `solution-architect`.
- Mockup → mockup-owning role for HTML/CSS/JS/SVG edits; `solution-architect` for governance review only.
- Engineers outside the owning domain never edit these files directly.

## Task model

Phase 1–8 applies to any task. A task originates from one of three sources:

| Source | Scope | State mechanic |
|---|---|---|
| Repo-root `TODO` (file name per `local/framework.config.yaml` → `todo`) | Project-wide | Glyphs `☐` / `☒`; orchestrator updates the line on completion |
| Nested `TODO` (e.g., `client/TODO`, `service/api/TODO`) | Component-scoped | Same glyph mechanic, scoped to that component file |
| Direct user instruction | Ad hoc; scope inferred from the instruction | No `TODO` file; no glyph mechanic |

`TODO` at any location is user-curated — never auto-generated, never auto-extended. Glyphs: `☐` = open, `☒` = completed.

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

4. **For direct-instruction tasks** — no `TODO` state to update. Acceptance is the user's explicit confirmation. Skip the glyph mechanic; the post-Phase-8 hook still applies.

- `TODO` checks happen **between** user requests — not in the middle of one.
- `TODO` items are user-grained, larger than in-conversation tasks. Mark both when the same work completes.
- Never auto-add to any `TODO` file. Mention follow-up work → *offer* to add it; do not act unilaterally.
- User says "skip TODO" for this turn → honour it; resume next turn.
- **Discovering nested `TODO`s.** Orchestrator may glob for `**/TODO` on session start or when entering a component context — but only surface them if the user is operating in that context.
