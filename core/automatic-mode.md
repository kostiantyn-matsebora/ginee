# Automatic mode

Load-on-demand definition. `project-manager` fetches this file when activation is detected (`auto:` prefix or PM-proposed-then-user-accepted). Default tasks run interactive — do not load this file.

For low-risk or self-contained tasks, the lifecycle runs end-to-end without per-phase user gates, presenting a single **delivery handoff** at the end. Phase 8 user-approval invariant preserved as that one final gate; not waived.

## Activation

- **Explicit, per-task only.** Never session-wide; never inherited across tasks.
- **Triggers:**
  - User prefixes the task with `auto:`.
  - User addresses `project-manager` with `auto`.
  - `project-manager` proposes auto mode for a low-risk task (docs-only edit, isolated bug fix in a single owned path, mechanical refactor) AND user replies "yes, auto" or equivalent.
- **Never silent.** Orchestrator never enters auto mode without one of the triggers above.
- Recorded in orchestrator's plan for that task.

## Gates elided in auto mode

- **Phase 3 — Design review.** Auto-approved when Phase 2 produces no user-visible behaviour change OR the user already approved the broader direction. Material UX surfaces still escalate (see Forced-interactive triggers).
- **Iteration-protocol intermediate-batch user confirmations.** Iterations still run as 3–5 min stoppable batches, but orchestrator does NOT pause between batches. User may interrupt at any time; next batch boundary is the safe stop.
- **Per-step "stop and confirm" pauses inside engineers.** Engineers proceed once the iteration's intermediate state is recorded.

## Gates still respected in auto mode

- **Phase 7 — SA review.** Runs as normal. Automated; no user interaction required.
- **Destructive / external actions** (per "Executing actions with care" guidance in project-instruction files). Even in auto mode, do not push to shared branches, drop or downgrade dependencies, modify shared infrastructure, send messages, or contact external services without explicit consent. Default delivery handoff does NOT push.
- **Full regression remains opt-in** (per `core/process.md § Phase 5 Scope`). Auto mode does NOT request it. Delivery report records that full regression was not run and that the user may request it before accept.
- **Phase 8 user-approval invariant.** Preserved as the single delivery handoff at the end.

## Forced-interactive triggers — auto mode falls back to interactive when

| Trigger | Action |
|---|---|
| Phase 2 surfaces a design choice with material user-visible impact (new screen, changed wire shape adopters depend on, new external dependency, NFR-affecting trade-off) | Pause; surface Phase 2 artefacts per Phase 3; resume on approval. |
| Phase 6 fails to resolve the same defect after 2 iteration batches | Pause; surface defect, attempted fixes, proposed next step. |
| A cross-domain integration cycle is required (per `core/cross-domain-bugs.md`) | Pause; surface integration scope and dispatch plan. |
| A test oracle is found to be wrong (per `core/process.md § Test oracles can be wrong`) | Pause; surface observed vs asserted divergence and oracle-tightening proposal. |
| Token-budget consumed exceeds 1.5× the Phase 4/5 estimate OR wall-clock exceeds 2× the estimate | Pause; surface burn rate; request continue-or-stop. |
| Any planned action enters the "destructive / external" set above | Pause; surface action + reason + alternatives. |

On any trigger: `project-manager` halts dispatch, presents a short interactive-fallback report, resumes auto mode only on explicit user direction.

## Delivery handoff (replaces Phase 8 in auto mode)

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

## Orchestrator duties (project-manager)

`project-manager` is the only role that detects, sustains, and exits auto mode. Other specialists operate normally; they simply receive dispatches that skip intermediate user-confirmation pauses.

- **Detect activation.** The user prefixed the task with `auto:` / addressed `project-manager` with `auto`, OR `project-manager` proposed auto mode (low-risk task: docs-only, isolated bug fix, mechanical refactor in a single owned path) and the user said yes. Never enter auto mode silently — proposal without explicit yes = run the task interactively.
- **Record the mode** in the task plan so dispatched specialists know to operate without intermediate user confirmations.
- **Elide the gates** listed in § Gates elided in auto mode. Iterations still run as 3–5 min stoppable batches for observability — do NOT wait for user review between them.
- **Watch the forced-interactive triggers** (see § Forced-interactive triggers). On any trigger: halt dispatch, surface a short report, ask the user to direct, resume auto mode only on explicit instruction.
- **Track budget.** Estimate Phase 4/5 token + wall-clock at dispatch; record actuals; trip the threshold trigger when crossed.
- **Never push, never modify shared state silently.** The default delivery handoff produces commits only on explicit Accept; pushing requires a separate explicit user instruction. Auto mode is not a license to bypass "Executing actions with care".
- **Run the delivery handoff** (see § Delivery handoff) when the lifecycle completes. Do nothing destructive until the user picks.
- **On Accept**, commit per project convention; push only on explicit user instruction; transition the TODO `☐` → `☒`; then run the post-acceptance doc-optimization hook as usual.
- **On Feedback**, loop back to the appropriate earlier phase (typically Phase 6; occasionally Phase 4 or 2 if the remark is structural) and resume auto mode toward a fresh delivery handoff.
- **On Reject**, roll the working tree back to pre-task state. The TODO stays `☐`. Do not commit the rollback.
