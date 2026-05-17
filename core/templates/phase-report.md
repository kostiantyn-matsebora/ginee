# Phase Report Template

Use this shape for the structured final report at the end of any phase (per `core/process.md` § Iteration protocol and § Stoppable intermediate states). Specialists report up to `project-manager`; `project-manager` consolidates and reports to the user.

Replace bracketed placeholders. Drop any section that yields no content (do not leave empty headings).

---

## Phase: `<lifecycle phase | iteration-N | hand-off>`

**Role:** `<role name>` (`<alias>`)
**Task:** `<one-line task description>`
**Source:** `<TODO line | direct instruction | hand-off from <role>>`
**Status:** `Done | In-progress | Blocked | Hand-off`

## Files touched

| Path (absolute) | Delta (lines / chars) | Note |
|---|---|---|
| `<path>` | `+N / -M` | `<one-line why>` |

## Decisions made

| Decision | Rationale | Cites |
|---|---|---|
| `<short imperative>` | `<one sentence>` | `<FR-NN / NFR-NN / ADR-NNNN / mockup section>` |

## Verification log

| Command / check | Outcome | Note |
|---|---|---|
| `<command>` | `<exit code / pass-fail / count>` | `<one line if non-obvious>` |

- Manual smoke (when user-facing surface touched): `<one line per new flow, e.g. "drawer opens; history loads; correlation attribute round-trips">`
- Lossless self-check (for `ai-engineer` doc work): `<sample of rules / invariants spot-checked + result>`

## Open issues

- `<issue>` — `<who/what is blocked / what's ambiguous>`
- `<follow-up surfaced but not addressed in this pass>` — `<should it become a TODO? a CR? an ADR?>`

## Iteration breakdown (when run under the Iteration protocol)

| Sub-task | Estimate | Actual | Result |
|---|---|---|---|
| `<sub-task>` | `<min>` | `<min>` | `Done | In-progress | Not-started` |

## Next dispatch needed

- **Role:** `<role>` — **Reason:** `<one-line>` — **Scope:** `<one-line>`
- For cross-domain hand-offs, attach a `core/templates/hand-off-note.md` instance.

## Stop-state (when interrupted)

- **Done.** `<sub-tasks completed, files touched>`
- **In-progress.** `<sub-task interrupted, partial state recorded, concrete resume instructions>`
- **Not-started.** `<sub-tasks remaining in the approved batch, original estimates intact>`
