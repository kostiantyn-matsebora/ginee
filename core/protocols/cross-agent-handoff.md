---
audience: all-cardinals
load: on-demand
triggers: [cross-agent-handoff, cross-domain, handoff]
cap-bytes: 6144
reads-before-applying: []
---

# Cross-agent handoff — diagnose ≠ fix

**Load-on-demand.** Fetched when a specialist discovers a root cause **outside** their domain while working on their own task. The orchestrator may also load this file when a specialist's final report flags a cross-domain root cause that needs hand-off.

Default in-domain tasks do not load this file.

## Procedure

When a specialist discovers a root cause **outside** their domain:

1. **Diagnose fully; do NOT fix.** Cross-domain patches cause silent contract drift.
   - Write up: failing command, verbatim error, file + line, chain of reasoning.
   - Template: `core/templates/hand-off-note.md`.
2. **Hand off** to the owning specialist (routing in `local/bindings.md`). Package contents:
   - Symptom.
   - Verified root cause with evidence.
   - What the discoverer tried and ruled out.
   - Any local workaround in place + whether to remove it once the proper fix lands.
3. **Both specialists stay engaged.**
   - Owner fixes.
   - Discoverer reviews and removes workaround.
   - Not throw-over-the-wall.
4. **Workarounds are temporary, labelled as such.**
   - Stay only until owner lands proper fix.
   - Both specialists acknowledge in reports.
5. **Out-of-competence fixes are disallowed** — see `local/bindings.md` → "Project role boundaries".

## Orchestrator wiring

When a specialist flags a cross-domain root cause in their final report:

- Dispatch the owning specialist next.
- Pass the prior diagnosis verbatim.

## Doc updates route through the doc's owner

| Doc class | Owner |
|---|---|
| Architecture doc / project-instruction files / process docs / ADRs | `solution-architect` |
| Mockup (HTML / CSS / JS / SVG edits) | mockup-owning role |
| Mockup (governance review only) | `solution-architect` |

Engineers outside the owning domain MUST NOT edit these directly.

## Peer-resolved vs team-lead-escalated exchanges

Cross-cardinal exchanges fall into one of two resolution surfaces. Default surface is team-lead; peer-resolved is opt-in per exchange when ALL criteria match. Per `core/protocols/adapter-wrapper-pattern.md` — peer-resume is a host-capability of the active adapter's subagent surface.

| Exchange | Resolves at |
|---|---|
| Single defect → owning cardinal fix → re-verify (within in-flight phase) | **Peer-direct** — owning engineer resumes via adapter-native peer-resume; team-lead skipped |
| Contradictory parallel returns | **team-lead** (synthesis surface) |
| Cross-domain bug (root cause spans 2+ domains) | **team-lead** per `core/protocols/cross-domain-bugs.md` |
| Scope expansion / new acceptance criterion | **team-lead** |
| Architectural delta surfaced by engineer | **team-lead** per `core/roles/team-lead.md § Engineer-surfaced architectural-delta gate` |
| Phase 3 / 7 / 8 user gates | **team-lead** (no peer-direct path) |

**Triggers forcing team-lead re-entry mid-exchange.** Contradictory return · second cardinal needs to enter · scope expansion · architectural delta · iteration-protocol round-trip cap tripped per `core/protocols/iteration-protocol.md § Peer round-trip pattern`.

## `peer-exchange:` audit-trail discipline

Peer-direct exchanges happen in subagent transcripts, not main-thread context. The owning cardinal's phase-report return surfaces the exchange so team-lead synthesis has visibility on next re-entry.

| Surface | Content |
|---|---|
| Surfaced via | Bullet under `## Decisions made` of the *responding* cardinal's phase-report return — prefix `peer-exchange:` |
| Body shape | `peer-exchange: <originating> → <responding> · <one-line topic> · <outcome>` |
| Cardinality | One bullet per peer-direct round-trip; bundled rows forbidden |
| Adapter coupling | Where the active adapter has no host-enforced peer-resume tool, exchange MUST route through team-lead and the bullet MUST NOT appear |

Single audit-trail rule binds every cardinal via this protocol; no per-kernel addenda.
