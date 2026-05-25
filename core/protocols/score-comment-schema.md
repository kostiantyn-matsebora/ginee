---
audience: team-lead-only
load: on-demand
triggers: [ginee:score, sticky score comment, recompute score, triage score sticky]
cap-bytes: 6144
reads-before-applying: [core/protocols/triage-scoring.md]
---

# Score-comment schema

**Load-on-demand.** Loaded when `team-lead` posts / refreshes the sticky `ginee:score` comment — initial pickup · `@team-lead recompute score #<N>` · any ginee-driven label change.

Rules (axes · formula · trigger list · forbidden) live in `core/protocols/triage-scoring.md § Score comment + audit trail`. This file binds the **shape**.

## Schema

One sticky per issue. Idempotent via header marker. Refresh in place; never duplicate.

| Element | Required | Source |
|---|---|---|
| Header marker `<!-- ginee:score v=1 -->` | yes | Fixed string; first line; case-sensitive |
| `## Triage score: <combo> = <number>` heading | yes | `<combo>` = `<value-letter><complexity-letter>` (unscored → `—`); `<number>` per resolved formula |
| Axes table — 5 columns | yes | `Axis · Label · Numeric · Set by · Reasoning` |
| Formula line | yes | `Formula: <formula> (<scoring-formula key>)` |
| Last-updated line | yes | `Last updated: <ISO 8601 UTC> by ginee team-lead` |
| Recompute note | yes | One line citing `ginee-triage` re-derivation from labels |

## Section templates

### Sticky body

```
<!-- ginee:score v=1 -->
## Triage score: <combo> = <number>

| Axis | Label | Numeric | Set by | Reasoning |
|---|---|---|---|---|
| value | `<high|medium|low|unscored>` | <3|2|1|—> | <@handle (source)> | <one-line | —> |
| complexity | `<high|medium|low|unscored>` | <3|2|1|—> | <@handle (source)> | <one-line | —> |

- Formula: `<formula>` (`<scoring-formula key>`)
- Last updated: <ISO 8601 UTC> by ginee team-lead
- Recomputed live by `ginee-triage` from labels — see audit trail below.
```

### `Reasoning` column policy

| Row state | `Reasoning` content |
|---|---|
| Most-recent change was a ginee auto-estimate | One-line digest (e.g. `1 file · 1 role · pattern reuse → L`) |
| Most-recent change was reporter / user `gh issue edit` | `—` |
| Axis not yet set | `unscored` |

### `Set by` column values

| Source | Rendered as |
|---|---|
| User-set (reporter / manual edit) | `@<handle> (reporter)` OR `@<handle> (manual edit)` |
| SA auto-estimate of complexity | `@solution-architect (auto-estimate)` |
| `team-lead` imputed `c=L` | `@team-lead (imputed c=L)` |
| User reply to ginee value-prompt at pickup | `@<handle> (user reply to ginee prompt)` |

## Forbidden patterns

1. **Multiple sticky comments per issue.** Always update via the marker; never post a second `ginee:score` body.
2. **Editing or deleting an immutable audit comment.** Schema in `core/protocols/audit-comment-schema.md`.
3. **Auto-detecting manual `gh issue edit` changes between sessions.** User invokes `recompute score #N` to refresh.
4. **Adopter-secret data** — issue body / labels only; never local repo paths · SHA-256 fingerprints · PII.
5. **Numeric out of bounds.** `<number>` follows `core/protocols/triage-scoring.md § Score formula`; unscored → `0`.

## Worked example

```
<!-- ginee:score v=1 -->
## Triage score: HM = 1.5

| Axis | Label | Numeric | Set by | Reasoning |
|---|---|---|---|---|
| value | `high` | 3 | @kostiantyn-matsebora (reporter) | — |
| complexity | `medium` | 2 | @solution-architect (auto-estimate) | 13 files · 3 roles · pattern reuse · no code → M |

- Formula: `value / complexity` (`value-over-complexity`)
- Last updated: 2026-05-25T18:20:04Z by ginee team-lead
- Recomputed live by `ginee-triage` from labels — see audit trail below.
```

## Self-lint checks

Run all 5 against the drafted sticky **before** posting / updating:

1. Header marker is the literal string `<!-- ginee:score v=1 -->` on line 1.
2. `<combo>` letters match label letters (`H`/`M`/`L`/`—`); `<number>` matches the resolved formula.
3. Axes table has exactly 2 data rows (`value` · `complexity`); 5 columns; no extras.
4. `Reasoning` column populated per the row-state table; empty cells use `—` not blank.
5. No adopter-secret data — no local paths · SHA fingerprints · PII.

Append, as the **last line**, the literal attestation marker `<!-- self-lint: pass -->`.

<!-- self-lint: pass -->
