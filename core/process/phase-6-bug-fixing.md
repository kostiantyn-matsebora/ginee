---
audience: all-cardinals
load: on-demand
triggers: [phase-6, bug-fixing]
cap-bytes: 4096
reads-before-applying: []
---

# Phase 6 — Bug fixing

**Load triggers** — any cardinal whose `phase-participation:` includes `6`. Per-role roster: owning engineering cardinal · `qa-engineer` (parallel exercises) · `solution-architect` (review on architectural fix — bypass default per SA3 in `core/protocols/heavy-role-bypass.md`) · `team-lead` (TL3 intra-domain bug-fix bypasses — re-entry only on cross-domain bug per `core/protocols/cross-domain-bugs.md`).

- **Goal.** Resolve defects from Phase 5 (or manual smoke) until all change-scoped oracles are green.
- **Rules.**
  - Owning engineer fixes the failing surface.
  - QA exercises other scenarios in parallel — a fix never freezes the test run.
  - Routes back to the specific Phase 4 surface, not a full Phase 4 rerun.
  - Runs under `core/protocols/iteration-protocol.md`.
- **`solution-architect` review on architectural fixes.** If a proposed fix involves an architectural change (vs. local bug fix), SA reviews per `§ Review`. APPROVE → engineer implements; REJECT / REQUEST-CHANGES → iterate. Local bug fixes route directly engineer → engineer, no SA dispatch.
- **Acceptance.**
  - Change-scoped oracles green.
  - No regression in touched surfaces.
  - Manual smoke re-run if a user-visible surface was touched.
  - Opt-in full regression is part of that opt-in pass — not a Phase 6 gate.
