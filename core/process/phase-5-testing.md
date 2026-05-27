---
audience: all-cardinals
load: on-demand
triggers: [phase-5, testing]
cap-bytes: 4096
reads-before-applying: []
---

# Phase 5 — Testing

**Load triggers** — cardinals with `phase-participation:` including `5`. Heavy-role-bypass per `core/protocols/heavy-role-bypass.md` — TL2 single-cardinal verification (TL re-entry only on cross-domain bug · non-empty `## Open issues` · `## Hand-off` set · `Status: In-progress`). SA is NOT dispatched at Phase 5 under any condition.

- **Goal.** QA backstop — QA MUST independently re-execute every change-scoped suite the engineer reported AND MUST verify AC compliance against the issue / TODO / freeform task spec AND MUST run manual smoke against the running solution. NOT first-pass discovery; the engineer's `core/protocols/engineer-self-verify.md` loop already green-gated those suites in Phase 4. Engineer's green log is paper trail, never a waiver — QA re-runs every suite.
- **Scope — change-scoped by default.** Run only:

  | Layer | What runs |
  |---|---|
  | New / modified scenarios | functional / API / e2e / harness / script for touched code paths |
  | Per-project unit specs | in modified files |
  | Pre-existing scenarios | only if their covered contract was edited in Phase 2 or 4 |

- **Full regression — opt-in only.**
  - User must explicitly request it.
  - `team-lead` MAY remind it's available (wide-reach refactor / infra change / risky touch).
  - `team-lead` MUST warn of significant wall-clock + token cost.
  - Runs separately AFTER change-scoped pass is green.
  - Reports: pass/fail per suite + wall-clock + approximate token cost.
- **Discipline.**
  - Tests reference contracts, not implementation internals.
  - Oracles TIGHT per `core/process.md § Test oracles can be wrong`.
  - Manual smoke against the running solution (project's local-dev startup command), NOT design artefacts.
  - Iteration protocol when scope > 15 min — `core/protocols/iteration-protocol.md`.
- **SA — categorical refusal at Phase 5.** Red NFR-oracle is a defect routed to Phase 6 (engineer-owned fix) OR — when the failure indicates the architectural decision itself is wrong — `qa-engineer` flags an architectural-delta need in `## Open issues` + `## Next dispatch needed: team-lead · architectural-delta gate · <NFR-oracle red>`. Team-lead surfaces gate per `core/roles/team-lead.md § Engineer-surfaced architectural-delta gate`. No mid-phase SA dispatch.
- **`qa-engineer` pixel-check (optional, off by default).** Fires when `local/framework.config.yaml § qa.pixel-check.enabled: true` AND the change diff touches the visual surface AND seed-script + mockup-snapshot + app-render are configured. Inserts between change-scoped e2e and manual smoke; routes per drift source (front-end engineer · mockup-owning role · seed-script owner · team-lead for tolerance). Full spec: `core/protocols/pixel-check-protocol.md`.
- **Acceptance.**
  - Change-scoped suite green.
  - Oracles reflect correctness for touched surfaces.
  - Manual-smoke report recorded (caveat if not run, e.g. headless).
  - Failures → Phase 6.
  - Opt-in full regression is its own pass — not a precondition.
