# Cross-domain bugs — integration + compliance cycle

Load-on-demand definition. Fetched when a bug or task is detected to span 2+ domains. Default single-domain tasks do not load this file.

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
