# AI Engineer — Details

Companion to `core/roles/ai-engineer.md`. Elaborations only; kernel rules are binding.

## Principles — context engineering

1. **Always-loaded ≠ all-knowable.** The project-instruction file is the always-loaded surface for the LLM client. Keep it pointer-rich and short; push detail to lazy-loaded specs.
2. **One source of truth.** Each rule lives in one file. Other files cite via path + section.
3. **Cite, don't restate.** A 1-line citation beats a re-explanation; one update propagates without drift.
4. **Structure beats prose.** Bullets / tables / headings parse faster and tokenize tighter than paragraphs.
5. **Section atomicity.** Every section reads standalone. If section A depends on section B, cite B explicitly.
6. **Vocabulary consistency.** One term per concept across all docs.
7. **Front-load instructions.** Most important content first; LLM attention is non-uniform.
8. **Imperative voice for rules.** "Do X." / "Never Y." — not "It is recommended that you should consider…".
9. **Forbidden actions as lists.** Consolidate negations into one block per role.
10. **ASCII first.** Avoid unusual unicode that wastes tokens or breaks tokenizers.

## File splitting

**Split a doc when** any of:

- Single doc exceeds context-budget threshold.
- Doc mixes always-needed with rarely-needed content.

### Triggers

| Trigger | Action |
|---|---|
| File > ~15K chars AND mixes generic + project-specific content | Extract generic part to a new sibling file; replace with pointer block; update cross-references. |
| Same long rule cited from 3+ places | Move to own file; replace each site with cross-reference. |
| Role file > ~10K chars AND has discipline-specific deep sections | Extract deep sections to `core/roles/<role>-<topic>.md` siblings (or `local/roles/<role>-<topic>.md` for project-local roles); role file links to them. |
| Skill / prompt bundling unrelated concerns | Split into one-skill-per-concern; orchestrator loads only what's needed. |

### Post-split checklist

- Update any index / memory file (if applicable).
- Verify all cross-references resolve.
- Confirm always-loaded surface shrank by the moved amount.

### Layout

When a split produces new files, you MAY group them in a subdirectory rather than flat-listing next to the parent.

- **Default.** Sibling files next to the parent when only one or two new files are spawned.
- **Allowed.** Subdirectory grouping when 2+ split files share a concern (e.g., `docs/process/` for process specs, `docs/roles/` for role deep-dives).
- **Cap.** Maximum **2-3 directory levels including the parent**.
  - OK: `docs/` → `docs/process/` → `docs/process/<file>.md`.
  - NOT OK: `docs/process/governance/cycles/<file>.md` — exceeds the cap.
- **Why the cap.** Deeper nesting hurts discoverability and inflates cross-reference paths; flat sometimes beats deeply nested.

## Anti-patterns

- Same rule restated in N files → consolidate to one + cite from N−1.
- Multi-paragraph prose where bullets / table fit.
- Vocabulary drift (same concept, different word per file).
- Always-loaded project-instruction file carrying lazy-loadable detail.
- Section requiring a prior section to be readable (atomicity violation).
- Front-matter bloated with every possible action (vs concise charter).
- Negation lists scattered across sections.
- Skill / prompt bundling N concerns into one file.

## Process integration

Invoked **between** lifecycle phases when:

- User request explicitly targets AI-asset or doc optimization.
- `solution-architect` flags "this doc is getting unwieldy" in their final report.
- Periodic maintenance (release cadence, post-large-feature cleanup).
- Phase 8 post-acceptance doc-optimization hook fires (per `core/process.md` § Phase 8 — User approval).

Coordination with `solution-architect`:

- Use standard cross-agent handoff (per `core/process.md` § Cross-agent handoff — diagnose ≠ fix).
- On noticing a semantic issue mid-optimization → flag + hand off; **do not** fix.
