# Hand-off Note Template

<!-- Use when an engineer discovers a root cause OUTSIDE their domain while working their own task (per core/process.md § Cross-agent handoff — diagnose ≠ fix). -->
<!-- Discoverer diagnoses fully and does NOT fix. Owning role takes the hand-off, fixes, and the discoverer reviews + removes any local workaround. -->
<!-- Replace bracketed placeholders. -->

---

## Hand-off

**From:** `<discovering role>`
**To:** `<owning role>` (per `local/bindings.md` → "Project role boundaries")
**Date:** `<YYYY-MM-DD>`
**Originating task:** `<short description + TODO ref or dispatch context>`

## Symptom

<!-- Concrete and reproducible. -->

- Failing command / step: `<verbatim>`
- Expected: `<one line>`
- Actual: `<one line>`
- Reproduces on: `<commit SHA | branch | environment>`

## Root cause (verified)

<!-- The bug, in the owning role's domain. Cite file + line + chain of reasoning. -->

```
<file:line> — <verbatim relevant excerpt or error>
```

- Why this is the cause: `<one or two sentences>`
- Why it's in the owning role's domain (not the discoverer's): `<one sentence — cite role boundary>`

## Evidence

| Step | Result |
|---|---|
| `<command / inspection>` | `<output / observation>` |

Attach logs / screenshots / diff snippets where load-bearing.

## What the discoverer tried and ruled out

| Hypothesis | Test | Result |
|---|---|---|
| `<hypothesis>` | `<what was checked>` | `Ruled out — <why>` |

<!-- Prevents the owner from re-running the same investigations. -->

## Workaround in place (if any)

- **Location:** `<file:line>`
- **What:** `<one line>`
- **Why:** `<one line — usually "unblock current task">`
- **Removal trigger:** `<who removes it + when — typically "discoverer, once owner's fix lands">`

Workarounds are labelled in the code (comment: `// WORKAROUND — see hand-off <date> to <owning role>`). Both roles acknowledge in their reports.

## Out-of-competence — discoverer will NOT fix

The forbidden role-crossings table (`local/bindings.md` → "Project role boundaries") makes this a hard stop. Patching across domains causes silent contract drift.

The owning role takes it from here.

## Coordination

- **Both roles stay engaged.** Owner fixes; discoverer reviews and removes the workaround.
- **Cross-reference.** Owner's commit/PR references this hand-off note; discoverer's removal commit references both.
