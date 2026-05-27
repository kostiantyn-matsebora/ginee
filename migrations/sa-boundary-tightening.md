# Migration — SA boundary tightening: timing + content axes

**Target release:** next minor.
**Affected adopters:** every adopter project; orchestration shift is invisible to most workflows but SA dispatches in Phase 4/5/6 STOP working.
**Issue:** [#182](https://github.com/kostiantyn-matsebora/ginee/issues/182).

## Adapter binding — hard-force (Claude)

Both axes upgraded from soft-force (always-loaded text) to hard-force via PreToolUse hooks on the Claude adapter. Per `core/protocols/dispatch.md § Adapter binding` + playbook [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135) force-class taxonomy:

| Axis | Tactic | Class | Mechanism |
|---|---|---|---|
| Timing — SA dispatch in Phase 4/5/6 | T14 | A (PreToolUse Task hook) | `adapters/claude/hooks/pre-tool-use-task.{ps1,sh}` — blocks dispatch when `subagent_type=solution-architect` AND prompt carries a Phase 4/5/6 indicator. Exit 2 + stderr remediation. |
| Content — `<file>:<line>` citation in SA artefacts | T15a | A (PreToolUse Edit/Write hook) | `adapters/claude/hooks/pre-tool-use-sa-artefact.{ps1,sh}` — blocks Edit / Write / MultiEdit on SA-owned paths (per `local/framework.config.yaml § architecture-doc · adr-directory · diagrams-directory` + canonical `local/requirements.md` + `local/asr-utility-tree.md`) when added content matches `<file>:<line>` pattern. |
| Content — commit SHA in evidence context | T15b | A (PreToolUse Edit/Write hook) | Same hook; matches `(as of|prior to|since|at commit|at sha|commit|revision|rev)\s+[0-9a-f]{7,40}` in added content. |
| Content — adopter identifiers · handler-body snippets · "how to wire it" prescriptions · repeated file paths | soft-force (Class H always-loaded text + Class A-indirect slash command) | H / D | LLM self-review backstop via SA's pre-report-as-done content self-lint per `core/templates/phase-report.md § SA-artefact content self-lint`; `/ginee-self-lint` slash command consumes the check. Pattern-matching adopter identifiers is brittle outside controlled vocabularies — hard-force regex deferred. |
| Timing + Content — bookended CLAUDE.md hard constraints | T9 reuse | H | Constraints #3 (SA Phase 4/5/6 refusal) + #4 (SA artefacts no implementation rendering) carry top + bottom in `CLAUDE.md` and `adapters/claude/CLAUDE-pointer.md`. |
| SA SendMessage continuation carry-forward | T8 reuse | D | `adapters/claude/hooks/carry-forward-rules.yaml § solution-architect` extended — every warm-SA continuation reminded to stay out of Phase 4/5/6 + skip implementation rendering. |
| UserPromptSubmit keyword trigger | T5 reuse | D | `adapters/claude/hooks/keyword-triggers.yaml § sa-boundary-and-content` injects the SA boundary spec excerpt on mentions of `@solution-architect`, `ADR`, `architecture-doc`, `ASR`, `architecture review`. |

Wired through the installer — `core/scripts/sync-claude-settings.{ps1,sh}` registers the two new PreToolUse entries (`pre-tool-use-task` + `pre-tool-use-sa-artefact`) on adopter `.claude/settings.json` on next `/ginee-update`. Per-tactic opt-out: `local/framework.config.yaml § compliance.disabled: [pretooluse-task-hook]` · `[pretooluse-sa-artefact-hook]`. Emergency bypass per call: `SKIP_GINEE_COMPLIANCE=1`.

## What changed — two sibling rules

### Axis 1 — Timing: SA out of implementation phases

| Surface | Before | After |
|---|---|---|
| `core/roles/solution-architect.md` frontmatter | `phase-participation: [1, 2, 4, 5, 6, 7]` | `phase-participation: [1, 2, 7]` |
| Phase 4 SA governance dip | Fired on PRs touching SA-owned files | **Categorically refused** — no dispatch under any condition |
| Phase 5 SA NFR-oracle dip | Fired on red NFR-oracle | **Categorically refused** — red NFR routes to Phase 6 OR team-lead architectural-delta gate |
| Phase 6 SA architectural-fix review | Fired on blueprint-diff threshold cross | **Categorically refused** — fix proposals route through team-lead gate |
| Phase 7 SA governance review | Fired every task as final coherence check | **Conditional** — fires only on (a) task introduced architectural changes OR (b) Phase-1 `post-implementation-governance: yes`. Default = skip. |
| Heavy-role-bypass SA1/SA2/SA3 tracks | Default-skip + per-trigger fire | **RETIRED** — categorical refusal replaces default-skip |
| Engineer mid-flight architectural proposal | Direct SA dispatch via `§ Review` | Routes through team-lead's new `§ Engineer-surfaced architectural-delta gate` — user picks *defer to next design cycle* OR *stop + re-enter Phase 1–2* |
| Out-of-process Review | "Any phase, on engineer-proposed architectural changes" | Periodic / drift / explicit user; targets architecture-of-record; NEVER engineer mid-flight |

Phase-1 SA design dip gains a mandatory `## Decisions made` row: `post-implementation-governance: yes/no` — team-lead consumes this to gate the conditional Phase 7 dispatch.

### Axis 2 — Content: implementation rendering forbidden in every SA artefact

New `§ Implementation rendering — out of scope of every SA artefact` in `core/roles/solution-architect.md`. Architecture doc · ADRs · requirements register · ASR utility tree · diagrams MUST NOT contain:

| Forbidden category | Example |
|---|---|
| Adopter function / method / member identifier | `_actualGraphHeights` · `onGraphStateChange()` |
| Line-numbered citation into the working tree | `host.component.ts:142` |
| Commit SHA as evidence | `as of 1aaa215` |
| Handler-body / wiring code snippet | Multi-line fenced code exhibiting function body / event handler / template binding |
| "How to implement" / "how to wire it" prescription | Imperative steps prescribing implementation order |
| Repeated adopter file path as architectural basis | Same working-tree path cited > 2× as the basis for a decision |

**Allowed exception:** snippets ≤ 5 lines that *illustrate a contract surface* (interface declaration · wire-shape type · event-payload type · public API signature).

`core/roles/solution-architect.details.md § ADR template` gains an inverse-checklist + a worked **architectural mechanism vs implementation rendering** example pair.

`core/templates/phase-report.md § SA-artefact content self-lint` is the new pre-report-as-done check. Every SA return touching an architecture-family artefact MUST carry one `## Verification log` row: `SA-artefact content self-lint: PASS / <N findings>` per touched artefact. Findings → restructure (replace with architectural-mechanism phrasing) OR lift to engineer-owned per-tier doc via `## Next dispatch needed`.

## Action required

**No adopter-side schema break.** Existing ADRs / architecture docs continue to load; the new content rules apply on next SA edit. Adopters with pre-existing architecture artefacts that carry implementation rendering MAY:

1. Run `@team-lead rediscover` to refresh role bindings (cheap; harmless if already current).
2. On next architecture-doc / ADR edit, SA self-lints the touched artefact + restructures findings inline (small edits) OR surfaces a follow-up dispatch to the owning engineer to relocate the content (larger edits).
3. No bulk rewrite required — the rules apply forward; existing artefacts are not retroactively flagged.

**Workflows that break:**

- Direct `@solution-architect` dispatch in Phase 4 / 5 / 6 — now a hard violation. Re-route through team-lead's gate.
- "SA reviews this PR" mid-implementation — now routes through team-lead with user gate.
- Phase 7 SA review on every task — now skipped by default. SA pre-flags `post-implementation-governance: yes` at Phase 1 when needed.

## Files affected (framework upstream)

**Rewritten:**

- `core/roles/solution-architect.md` — frontmatter `phase-participation` · § Three activities · § Review (out-of-process) · § Governance (Phase 7 conditional) · § What you own → new § Implementation rendering — out of scope · § Forbidden actions (content depth-bound rules) · § Engineer-surfaced architectural delta — routed through team-lead.
- `core/roles/solution-architect.details.md` — § ADR template (inverse-checklist + architectural-mechanism vs implementation-rendering pair) · § Architectural-change review flow (both paths route through team-lead).
- `core/roles/team-lead.md` — new § SA dispatch — Phases 4 / 5 / 6 categorically excluded · new § Engineer-surfaced architectural-delta gate · lifecycle gate enforcement table updated.
- `core/templates/phase-report.md` — new § SA-artefact content self-lint.

**Updated:**

- `core/process.md` — phase-participation summary line.
- `core/process/phase-1-analysis.md` — `post-implementation-governance: yes/no` output.
- `core/process/phase-4-implementation.md` — SA categorical refusal note.
- `core/process/phase-5-testing.md` — SA categorical refusal note.
- `core/process/phase-6-bug-fixing.md` — SA categorical refusal note.
- `core/process/phase-7-sa-review.md` — conditional dispatch language.
- `core/protocols/heavy-role-bypass.md` — SA1/SA2/SA3 retired; SA mid-phase re-entry triggers removed.
- `core/protocols/role-kernel-shared.md` — §E (Proposing architectural changes) routes through team-lead.
- `core/protocols/doc-roles.md` — § SA architectural-coherence review — Phase 7 / out-of-process only.
- `core/protocols/automatic-mode.md` — engineer-surfaced architectural-delta gate added to forced-interactive triggers; Phase 7 SA noted as conditional.
- `core/protocols/doc-authoring-examples.md` — § 16 SA1–SA3 retired marker.
- `core/templates/asr-utility-tree.md` — Phase 4 engineer-arch-change path rewritten.
- `adapters/_shared/agents/solution-architect.md` — description + read-first list refreshed.

**Tests:**

- `tests/measure-role-context.Tests.ps1` — SA phase-participation expectation `[1, 2, 7]`.

**Docs (adopter-facing):**

- `docs/CONCEPTS.md` — SA model refined; phased lifecycle table updated.
- `docs/CHEATSHEET.md` — classical-architect SA model section refined; Phase 7 row updated.
- `docs/CHANGELOG.md` — Unreleased § Changed entry.

## Backward compatibility

- **No `local/` schema break.** Adopter `local/bindings.md` continues to work.
- **Existing architecture artefacts** continue to load; new content rules apply on next SA edit.
- **Custom `local/roles/solution-architect.md`** overriding the kernel — adopter MUST review for stale Phase 4/5/6 dispatch language; otherwise their override silently keeps the old behavior.

## Rollback

Not recommended. The boundary tightening eliminates a documented misuse pattern (`docs/adr/ADR-0012-*.md` revs 5–5.3 in `kostiantyn-matsebora/deployment-dashboard` — joint downstream consequence of both axes). Rolling back re-opens the path for SA artefacts to accrete engineer-manual content.

If a project genuinely needs the old SA model:

1. Restore `core/roles/solution-architect.md` frontmatter `phase-participation: [1, 2, 4, 5, 6, 7]`.
2. Restore `core/process/phase-{4,5,6}-*.md` SA dispatch notes.
3. Restore `core/protocols/heavy-role-bypass.md` SA1/SA2/SA3 tracks.
4. Revert `core/templates/phase-report.md § SA-artefact content self-lint`.

Adopter-side override path: author `local/roles/solution-architect.md` restating the prior `phase-participation` and removing the content depth-bound rules — auto-loaded as the final read in the SA chain.

## Issue reference

Implemented per [issue #182](https://github.com/kostiantyn-matsebora/ginee/issues/182) — "[Framework Bug] solution-architect violates classical-architect boundaries".
