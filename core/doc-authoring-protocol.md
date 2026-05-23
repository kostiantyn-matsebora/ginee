# Doc-authoring protocol — adopter docs + ginee-authored GitHub artefacts + subagent returns (D22 + D26 + D29)

**Load-on-demand at Phase 5 / report-as-done** for any doc-touching task. Default shape rules + mandatory checks live in `core/process.md § Documentation style` (always-loaded); this file carries scope + enforcement + attestation.

Examples gallery: `core/doc-authoring-examples.md` (load on first-time authoring / explicit request).

## Scope

| Surface | Authored by | In scope since |
|---|---|---|
| Architecture doc · ADRs · CRs · READMEs · runbooks · scenarios · API docs | adopter roles per `core/doc-roles.md` | D22 |
| Project-instruction file (`CLAUDE.md` / `AGENTS.md` / equivalent) | `team-lead` per D25 | D22 |
| Role definitions (`core/roles/`, `local/roles/`) · framework specs · skills | framework upstream / adopter `local/roles/` | D22 |
| **GitHub issue bodies** authored via `ginee-file-*` skills | `team-lead` (orchestrator drafts; user approves) | **D26** |
| **Framework-authored GitHub comments** — Phase-transition · sticky `ginee:score` / `ginee:review-cycle` · audit comments · per-thread review-replies | `team-lead` + specialists per the comment-cadence procedures | **D26** |
| **Subagent returns** — every cardinal-dispatch return per `core/templates/phase-report.md` schema | every cardinal role | **D29** |

**The lint covers every section, including Summary.** No section-by-length exemption — a one-sentence Summary still trips the mandatory checks if it packs a comma-separated inventory into a parenthetical.

**Subagent-return surface adds a 6th check** — *no narrative preamble* (first non-Status line must be a `##` section header). The 5 standing checks apply unchanged. Full schema: `core/templates/phase-report.md`.

### Out of scope

- **Reporter-authored issue bodies / comments.** Per D14 forbidden — *"Never edit an issue body authored by another reporter."* `ginee-pick-up` MAY surface a polite restructure advisory on pickup, but never auto-rewrites and never edits reporter content.
- **Existing adopter docs.** Forward-only — new + edited content follows the protocol; mass-restructure of legacy docs is a separate user-initiated task.
- **Discussion bodies.** Read-only context per D14; promote-to-issue first.
- **Style / tone / branding.** This protocol governs **structure**, not voice. Adopter style guides own those.
- **Framework-self-dev hygiene gates** (D21 context-economy gate · CI internals). Separate enforcement layer; cross-references the same Mandatory checks but runs via the gate script.

## Enforcement via discovered stack

ginee does **not** ship a doc linter. Adopter projects already configure markdown / prose tooling — ginee discovers it and triggers it.

| Stage | Mechanism |
|---|---|
| Discovery | `team-lead` records the lint command in `local/index/commands.yaml § commands.lint.docs` via the existing `builtin:commands` recipe. Linter configs (markdownlint / vale / proselint / prettier-md) recorded in `local/index/conventions.yaml` via `builtin:conventions`. |
| Author | Role consults `core/process.md § Documentation style` (always-loaded) for shape rules + mandatory checks. |
| Enforce | Role runs `${commands.lint.docs}` at Phase 5 / report-as-done; lint output goes into the phase report's Verification log. |
| No tool detected | Discovery report recommends a baseline — markdownlint (structural) + vale (prose). Adopter decides — never auto-install. |

## Attestation

Phase-report Verification-log entry (one line):

```
Doc-style protocol — <linter command>: PASS / N findings (see <path>).
```

If no linter discovered: `Doc-style protocol — no linter configured; self-checked against core/process.md § Mandatory checks.`

## Bypass

Binding. Bypass only via explicit user direction recorded in the phase report. Never silent.

## Enforcement for ginee-authored GitHub artefacts (D26)

Different from adopter-doc enforcement (which piggybacks on the discovered linter). For issue bodies + ginee-authored comments:

| Stage | Mechanism |
|---|---|
| Author | `ginee-file-*` skill drafts the body. Specialist drafts a Phase-transition / sticky / review-reply comment. |
| Self-lint | Author role runs the `core/process.md § Mandatory checks` against the drafted text **before** publishing — every section, including Summary. |
| Violation | Surfaces as a suggestion in the user-approval prompt. User accepts the restructure / rejects / overrides. No silent publish. |
| Publish | Only after user approval of the linted draft. |

**No external linter.** The check is LLM self-review against the same 5 mandatory rules used for adopter docs.

## Enforcement for subagent returns (D29)

Different again from D22 / D26. Returns are ephemeral (consumed by the orchestrator in-thread, not published), so the loop closes inside the dispatched role:

| Stage | Mechanism |
|---|---|
| Author | Dispatched cardinal drafts the return per `core/templates/phase-report.md` schema. |
| Self-lint | Role runs the 6 mandatory checks (5 from D22 / D26 + *no narrative preamble*) against the draft **before** returning. Violations → restructure; un-restructurable content → lift into capped `## Notes`. |
| Violation reaches orchestrator | `team-lead` surfaces a one-line advisory (`"Return missed self-lint: <violation>; consuming anyway"`), consumes the return, never re-dispatches purely for format, never auto-rewrites (analogous to D14 reporter-content forbidden). |
| Iteration-protocol intermediate return | Same schema with sections marked `(in-progress)`; `## Stop-state` required; `Status: In-progress`. |
| Failed dispatch (forced handoff per `core/cross-agent-handoff.md`) | Same schema + required `## Hand-off` section embedding `core/templates/hand-off-note.md`. |

**No external linter.** LLM self-review against the schema; identical machinery to D22 / D26 enforcement loop. Forward-only — pre-D29 returns are not retroactively rewritten.

## Taxonomy identifier pairing (D34)

**Rule.** Every cardinal output, ginee-authored artefact, and adopter doc that cites a taxonomy item carries the **identifier + short name in slug-glued form** — matches the on-disk filename convention. Bare identifiers force the reader to context-switch (open the file, read the title, return); slug-glued form lets the reader copy-paste the citation directly into a filesystem search.

**Form.**

| Class | Pattern | Example |
|---|---|---|
| D-decision | `D<NN>-<slug>` | `D28-skill-runner-boundary` · `D33-d29-enforcement-hardening` |
| ADR | `ADR-<NNNN>-<slug>` | `ADR-0001-topology-derivation-five-pass` |
| CR | `CR-<NNNN>-<slug>` | `CR-0010-component-ci-pipeline` |
| FR | `FR-<NN>-<slug>` | `FR-04-deploy-rollback` |
| NFR | `NFR-<NN>-<slug>` | `NFR-02-cost-cap` |
| ASR | `ASR-<NN>-<slug>` | `ASR-03-availability-budget` |
| Index class | `<class-name>` | `repo-map` · `architecture-fr` · `runtime-facts` |

**Out of scope** — issue numbers, PR numbers, commit SHAs, version tags, NPM/PyPI/RubyGems package names are NOT taxonomy IDs and stay bare. `#87` is correct; `[#87](https://github.com/.../issues/87)` is correct; `#87-claude-subagent-dispatch` is wrong (issue titles are reporter-mutable; PR titles drift).

### Resolution lookup

Cardinal MUST resolve the short name **before** emitting the output — never emit a bare identifier as fallback. If lookup fails, surface the resolution failure (one line) instead of degrading silently.

| Artefact class | Short-name source | Lookup |
|---|---|---|
| File-backed — D-decisions / ADRs / CRs / migrations | Filename slug after the numeric prefix | `ls core/MIGRATIONS/D<NN>-*.md` / `ls <adr-directory>/ADR-<NNNN>-*.md` / `ls <cr-directory>/CR-<NNNN>-*.md` — derivable via filesystem listing |
| Inline-table — FRs / NFRs / ASRs in `local/requirements.md` + `local/asr-utility-tree.md` | First noun phrase of the row's description, ≤ 5 words, kebab-cased | Read the register row; lift the descriptor; slugify |
| Index-class entries | `name:` field per class in `local/index/manifest.yaml § indexed[]` | Read the manifest entry; use `name:` verbatim |

**On resolution failure** (file missing · register row missing · manifest entry missing) — surface the failure inline: `D28-?? (slug lookup failed: core/MIGRATIONS/D28-*.md not found)`. The orchestrator carries the failure forward to the next dispatch.

### Self-lint check

Extends the existing D22 / D26 / D29 mandatory check #5 (cross-references cite anchors). The check fires on draft scan for any identifier matching the regex `\b(D|ADR-?|CR-?|FR-?|NFR-?|ASR-?)\d+\b` **not** followed by `-` + a slug. Hit → restructure to slug-glued form before publishing / returning.

Issue / PR / commit-SHA contexts are excluded — `#87` · `PR #84` · git SHAs · markdown links to issue / PR URLs do not trip.

### Enforcement

Same machinery as D22 / D26 / D29 — LLM self-review against the rule at draft time. No external linter; no runtime dependencies. Orchestrator on violation: one-line advisory (`"Output cited <bare-id> without slug; consuming anyway."`); consumes the output; never re-dispatches purely for format; never auto-rewrites.

**Forward-only.** Historical cardinal outputs (chat history, prior PR comments, prior issue bodies) are not rewritten. The rule applies to outputs produced after kernel reload.
