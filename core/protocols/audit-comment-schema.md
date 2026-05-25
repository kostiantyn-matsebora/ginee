---
audience: team-lead-only
load: on-demand
triggers: [ginee:value-prompt, ginee:complexity-estimate, ginee:score-recompute, audit comment, audit trail]
cap-bytes: 6144
reads-before-applying: [core/protocols/triage-scoring.md, core/protocols/github-integration.md]
---

# Audit-comment schema

**Load-on-demand.** Loaded when `team-lead` / skill-runner posts an immutable audit comment on an issue — pickup-time value-prompt response · SA complexity auto-estimate · sticky-score recompute.

Trigger taxonomy + behavioural rules live in `core/protocols/triage-scoring.md § Immutable audit comments — key-event trail`. This file binds the **shape** shared across all audit-comment types.

## Schema

One audit comment per key event. Append-only. Sits alongside the sticky `ginee:score` comment per `core/protocols/score-comment-schema.md`. Never edited; never deleted.

| Element | Required | Source |
|---|---|---|
| Marker line `<!-- ginee:<type> <fields> -->` | yes | First line; one of the registered types below |
| Bolded outcome line | yes | `**<outcome>:** <one-line>` |
| Body — one paragraph | yes | Context · cite source rule · digest of inputs |
| Cite footer | yes | `Per <core/protocols/...md § ...section>.` |

## Registered audit types

| Type | Marker | Body shape |
|---|---|---|
| **value-prompt** | `<!-- ginee:value-prompt by=<@handle> value=<H\|M\|L> at=<ISO> -->` | One-line outcome (`user set value=high during pickup of #N`) + cite `core/protocols/triage-scoring.md § Auto-estimation on pickup`. |
| **complexity-estimate** | `<!-- ginee:complexity-estimate by=solution-architect value=<H\|M\|L> at=<ISO> -->` | SA signal digest (`<N> files · <M> roles · <pattern-reuse-note> → <H\|M\|L>`) + cite `core/protocols/triage-scoring.md § Auto-estimation on pickup`. |
| **score-recompute** | `<!-- ginee:score-recompute by=<@handle> at=<ISO> -->` | Reason + delta from previous sticky state + cite `core/protocols/triage-scoring.md § Score comment + audit trail`. |

**Closed registry.** Adding a new audit type = `team-lead` proposes a row addition in this file (Phase 2 design surface); marker form follows the existing `ginee:<type> <key=value …>` shape.

## Section templates

### value-prompt

```
<!-- ginee:value-prompt by=<@handle> value=<H|M|L> at=<ISO> -->
**Value set by reporter:** <High|Medium|Low>

Pick-up flow — reporter-defined value score per `core/protocols/triage-scoring.md`.
<follow-up: "SA complexity estimate follows." OR "Complexity already set; sticky refresh follows.">
```

### complexity-estimate

```
<!-- ginee:complexity-estimate by=solution-architect value=<H|M|L> at=<ISO> -->
**Complexity auto-estimate: <High|Medium|Low>** — by `@solution-architect`

<N> files · <M> roles · <pattern-reuse note> · <code/no-code note> → <H|M|L>.
<one-line rationale on the dominant signal.>

Per `core/protocols/triage-scoring.md § Auto-estimation on pickup`.
```

### score-recompute

```
<!-- ginee:score-recompute by=<@handle> at=<ISO> -->
**Sticky score recomputed.**

<reason>. Delta vs previous sticky: <axis>: <old> → <new>.

Per `core/protocols/triage-scoring.md § Score comment + audit trail`.
```

## Forbidden patterns

1. **Editing or deleting a posted audit comment.** Immutable by contract.
2. **Posting an audit comment for a user-driven `gh issue edit` label change.** GitHub's own activity log already records it.
3. **Mixing two events in one comment.** One event = one comment; correlate via `at=<ISO>`.
4. **Free-text marker forms** — `<!-- ginee:auto-estimate -->` / `<!-- complexity by SA -->` / etc. Marker must match the registered form byte-for-byte.
5. **Adopter-secret data** — same rule as `core/protocols/score-comment-schema.md § Forbidden patterns`.

## Worked example

```
<!-- ginee:complexity-estimate by=solution-architect value=M at=2026-05-25T18:20:01Z -->
**Complexity auto-estimate: Medium** — by `@solution-architect`

13 files · 3 roles · 5-section phase-report pattern reuse · 4-of-5 specs consolidate scattered text · no code/validator → M.
File-count leans high, but the *kind* of work is established-pattern doc authoring with heavy consolidation.

Per `core/protocols/triage-scoring.md § Auto-estimation on pickup`.
```

## Self-lint checks

Run all 5 against the drafted comment **before** posting:

1. Marker is the literal registered form for the chosen type; `key=value` pairs match the type's contract.
2. Bolded outcome line present; one line; verb-first or label-first.
3. Body paragraph cites the source rule by `core/protocols/...md § ...section`.
4. No marker-form drift — never invent a new audit type without adding the row to the registry table first.
5. No adopter-secret data — issue body + labels + SA signals only.

Append, as the **last line**, the literal attestation marker `<!-- self-lint: pass -->`.

<!-- self-lint: pass -->
