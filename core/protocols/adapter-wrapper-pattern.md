---
audience: all-cardinals
load: on-demand
triggers: [adapter-wrapper, wrapper-anchor, frontmatter-as-constraint, charter-redundancy, subagent-surface]
cap-bytes: 8192
reads-before-applying: []
---

# Adapter wrapper-anchor pattern — frontmatter-as-constraint

Loaded when: a framework author classifies a new rule's enforcement surface (per `CLAUDE.md § Framework authoring — context economy` adapter-enforcement bullet) · a charter restructure pass triggers a redundancy audit between charter prose and wrapper frontmatter · per-adapter playbook authoring (`#135` sisters for Cursor / Copilot / Codex / generic) · a new cardinal role added to an adapter shipping a host-enforced subagent surface. Default cardinal dispatches do NOT load.

Per-adapter rendering follows; the protocol itself stays vendor-neutral.

## 1. Purpose + scope

Names the **wrapper-anchor** as a vendor-neutral design property of any adapter exposing a host-enforced subagent surface. The wrapper file at `.<adapter>/agents/<role>.<ext>` (or adapter-equivalent) is the constraint-bearing anchor at runtime; the vendor-neutral charter at `core/roles/<role>.md` stays instructional.

Applies to: any adapter whose host enforces frontmatter mechanically (Claude native subagents · Cursor subagents · adapter equivalents). Instructions-only adapters (no subagent surface) fall back to charter-prose soft force per `core/protocols/doc-authoring-protocol.md`.

## 2. Definitions

- **Charter.** Vendor-neutral role spec (`core/roles/<role>.md`).
- **Wrapper.** Per-adapter subagent file declaring host-enforceable properties via frontmatter.
- **Anchor.** The wrapper's role as the constraint-bearing surface at runtime — host enforces the frontmatter mechanically before the LLM acts.

## 3. Design invariant

Any property of a role that the host adapter can enforce mechanically — tool surface · model tier · routing surface · phase-participation — MUST be declared in the wrapper's frontmatter; the corresponding charter prose MUST NOT restate the rule as the constraint source.

**Rationale.** Drift between charter prose and wrapper frontmatter · ambiguous constraint source at runtime · wasted hot-context budget on rules the host already enforces.

**In-scope properties (hardenable via host enforcement):**

- Tool whitelist (`tools:`)
- Model resolution (`model:` or per-adapter tier mapping)
- Routing surface (`description:` or adapter-equivalent)
- Phase-participation declaration

**Out-of-scope properties (LLM-judgement; stay in charter-prose):**

- Process-step ordering (Propose → Review → Implement · phase entry conditions)
- Self-lint markers (`<!-- self-lint: pass -->`)
- Narrative invariants (lossless rule · diagnose ≠ fix · APPROVE / REJECT / REQUEST-CHANGES voice)
- Cross-reference fidelity

Charter MAY reference frontmatter (`tools whitelist enforces this — see wrapper frontmatter`); MUST NOT restate the host-enforced rule as imperative prose.

## 4. Force-class mapping per property

Per `#135 § Force taxonomy` (8 classes A–H). Mapping vendor-neutral; per-adapter playbook (Claude sister at `#135`; Cursor / Copilot / Codex / generic siblings file as tooling matures) renders per surface.

| Wrapper property | Force class |
|---|---|
| Tool surface (`tools:`) | A — action-time gate (host blocks tool call before execution) |
| Model tier (`model:` / per-tier map) | A — action-time gate (host resolves model at dispatch) |
| Routing surface (`description:`) | E — routing constraint (host matches natural-language prompt to subagent) |
| Phase-participation declaration | A-adjacent — host loads role only on matching-phase dispatch |
| Hot-context body text | H — hot-context text (LLM-self-lint only; soft) |

## 5. Per-adapter availability matrix

| Adapter | Native-subagent surface | Frontmatter enforcement strength | Routing surface |
|---|---|---|---|
| Claude | native subagent file | hard (host enforces tool whitelist + model + phase-participation gates) | native description-matched routing |
| Cursor | native subagent file | partial (TBD — pending compliance-playbook authoring per `#135` sister issues) | native description-matched routing |
| Copilot | TBD | TBD | TBD |
| Codex | TBD | TBD | TBD |
| generic | instructions-only fallback | soft (charter-prose only; no host enforcement) | instructions-only fallback |

## 6. Audit method — charter ↔ frontmatter redundancy

**Redundant** = ALL of:

1. Violation surface is a host-enforceable action class (tool call · model · routing · phase-load).
2. ≥ 1 active wrapper's frontmatter blocks the violation mechanically on ≥ 1 shipping adapter.
3. Charter restates the rule with an RFC 2119 modal at the same scope.

### Matching rules (manual)

| Step | Action |
|---|---|
| 1 | Pair charter rule with the wrapper field that could enforce it. |
| 2 | Check the active wrapper's frontmatter on each adapter; frontmatter present + enforcing → redundancy candidate. |
| 3 | Read context — charter as constraint source → redundant; charter as cross-reference → not redundant. |
| 4 | Confirm scope equivalence — charter narrower → keep, rephrase to reference frontmatter as base. |

### Outcome classes

| Class | Definition | Remediation |
|---|---|---|
| Full | Charter rule + frontmatter constraint fully overlap in scope + force | Delete charter rule; replace with one-line reference to frontmatter if context demands |
| Partial | Frontmatter covers the host-enforced surface; charter adds rationale / scope-narrowing | Restructure — keep rationale / scope-narrowing; remove imperative restatement |
| None | Charter rule scope or force has no frontmatter counterpart | Keep as-is |

### Forbidden

Audit MUST NOT delete a charter rule whose frontmatter constraint is present only on a subset of shipping adapters. Instructions-only adopters still need the charter rule as soft force.

### Cadence + scope

Periodic out-of-process Review trigger per `core/roles/solution-architect.md § Review`. NOT a one-shot Phase 4 `ai-engineer` hot-edit task — audit outcome routes through `core/protocols/doc-roles.md § Authorship` as an ADR amendment or charter restructure.

## 7. Tie to playbook #135

The wrapper-anchor design property formalised in this protocol is the canonical Tier-1 / Class-A entry of the adapter-compliance playbook (`#135 § Force taxonomy`). Class A names *action-time gates* (tool calls blocked before execution); the wrapper-anchor names the *vendor-neutral primitive* — the per-adapter subagent surface declaring a host-enforceable frontmatter — that any Class-A tactic builds on. Per-adapter Tier-1 implementations land in each `adapters/<x>/install.md` + the adapter's compliance playbook (Claude sister already exists at `#135`; Cursor / Copilot / Codex / generic siblings file as their tooling matures per the `CLAUDE.md § Framework authoring` adapter-enforcement bullet from `#180`).

<!-- self-lint: pass -->
