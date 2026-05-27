---
description: Run the 7 phase-report self-lint checks (+ SA-artefact content axis when applicable) against the last cardinal return. Returns PASS or violation summary.
argument-hint: [optional path to return text]
---

Run the 7 self-lint checks against the last cardinal return (or the text at `$ARGUMENTS` if supplied). Report PASS or the first violation; advisory only — never re-dispatch for format alone.

Checks per `core/templates/phase-report.md § Mandatory checks before report-as-done`:

1. **Section cardinality** — every required section present (use `(none)` when empty).
2. **No narrative preamble** — first non-Status line is a `##` section header.
3. **No restated dispatch context** — cite the dispatch prompt; don't restate.
4. **No code snippets outside `## Notes`** — diff stats + path cite in body.
5. **No verbose rationale outside `## Notes`** — one-line decision + cite in `## Decisions made`.
6. **Inventories in tables, not parenthetical comma-soup.**
7. **Marker present** — literal `<!-- self-lint: pass -->` as the LAST line (case-sensitive).

## SA-artefact content axis (#182) — applies when the return touches an architecture-family artefact

Per `core/templates/phase-report.md § SA-artefact content self-lint`. If `## Files touched` includes the architecture doc · any ADR · `local/requirements.md` · `local/asr-utility-tree.md` · any file under `diagrams-directory`, the return MUST carry one `## Verification log` row per touched artefact:

```
SA-artefact content self-lint: PASS / <N findings>
```

Verify the row exists AND the authored content does not contain:

| Forbidden category | Detection signal |
|---|---|
| `<file>:<line>` citation into the working tree | grep for `\b[\w./-]+\.(ts|tsx|js|py|cs|go|java|rb|md|...):\d+\b` |
| Commit SHA in evidence context | grep for `\b(as of|prior to|since|at commit|at sha|commit|revision|rev)\s+[0-9a-f]{7,40}\b` |
| Adopter function / member identifier | LLM judgment — names a working-tree symbol (not a contract surface) |
| Handler-body / wiring code snippet | LLM judgment — multi-line code exhibiting body / event handler / template binding (≤ 5-line interface declaration is allowed) |
| "How to wire it" / "how to implement" prescription | LLM judgment — imperative second-person steps prescribing implementation order |
| Repeated adopter file path as architectural basis | Same working-tree path cited > 2× as basis for a claim |

Hits on the two verifiable signals (`<file>:<line>` · commit SHA) are caught by the PreToolUse hook `pre-tool-use-sa-artefact.ps1` at edit time — this slash command is the LLM self-review backstop for the soft-force categories (adopter identifiers · handler bodies · wiring prescriptions · repeated paths).

On violation: surface one-line advisory per `core/templates/phase-report.md § Worked advisories`. Format-only violations (preamble · marker absence · table shape) consume anyway — never re-dispatch. Substantive omissions (source paths touched without `## Source reads`; SA-artefact content self-lint row missing when architecture-family file in `## Files touched`) do trigger the single re-dispatch carve-out.
