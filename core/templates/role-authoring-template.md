---
name: <your-role-name>
description: <One paragraph — what this role owns, when to dispatch it, and what it MUST NOT do.>
aliases: [<generic-alias-1>, <generic-alias-2>]
---

# Role Authoring Template

<!-- Copy to local/roles/<your-role-name>.md. Fill sections that apply; drop ones you don't need. Do NOT leave empty headings. -->
<!-- project-manager discovers local/roles/*.md on next prompt and adds the role to routing. Custom roles register UNDER project-manager — never alongside. -->
<!-- Mirrors structure of the 7 cardinal role files in core/roles/*.md. LLMs route faster on consistent shapes. -->

---

## Source of truth

<!-- Read these before every task (per core/process.md § Reading order). -->

- `<doc 1 — path in local/framework.config.yaml or absolute>` — `<one-line why>`
- `<doc 2>` — `<one-line why>`
- `<mockup, when relevant>` — `<one-line why>`

Conflict resolution: per `core/process.md` § Coordination protocol and `local/bindings.md` → "Source of truth" tie-breaker.

## Estimation-first dispatch

<!-- When dispatched above the 15-min threshold (per core/process.md § Iteration protocol), respond first with: -->

- A **task decomposition** — sub-tasks in active voice.
- A **per-task time estimate** — minutes per sub-task.

No edits yet. Wait for orchestrator/user approval. Then proceed per Iteration protocol in 3–5 min iterations, each ending in a stoppable intermediate state.

## What you own (and only you edit)

<!-- Look up exact paths in local/bindings.md. -->

| Path / surface | What it is |
|---|---|
| `<path-glob 1>` | `<one-line>` |
| `<path-glob 2>` | `<one-line>` |

## What you do NOT own (and must NOT edit)

<!-- Cross-reference local/bindings.md → "Project role boundaries" for the project-wide forbidden table. -->

- `<thing 1>` → `<owning role>`. `<why>`.
- `<thing 2>` → `<owning role>`. `<why>`.

When a problem requires changes outside your domain, **stop and hand off** per `core/process.md` § Cross-agent handoff — diagnose ≠ fix.

## Workspace layout

<!-- Per-tier dependency rules (mirror or extend local/bindings.md → "Repository structure"). -->

- `<rule 1>` — `<one line>`
- `<rule 2>` — `<one line>`

## Declarative configuration only

<!-- Per core/process.md § Configuration vs. data. -->

- Configuration → `<file>`. Never as string literals inside `<surface>`.
- Data / fixtures → `<file>`. Never inline literals inside `<surface>`.

## Stack — role specifics

<!-- Canonical stack: local/bindings.md → "Stack". Role specifics: -->

| Concern | Choice |
|---|---|
| `<concern 1>` | `<rule>` |
| `<concern 2>` | `<rule>` |

Do NOT introduce `<X / Y / Z>` — see `local/bindings.md` → "Do not introduce".

## Required behaviours

<!-- Drive from the FR table in the architecture doc. List FRs/NFRs this role primarily owns or implements. -->

## When proposing changes

- `<role-specific lead — e.g. "Lead with cost delta">`
- `<role-specific lead 2>`
- For wire-shape changes, flag for cross-domain consumers in your final report.

## Forbidden actions (strict-domain)

- **Never** `<action 1>`.
- **Never** `<action 2>`.
- **Never** `<action 3>`.

## Reporting

<!-- Use core/templates/phase-report.md for the structured final report. Highlight role-specific sections: -->

- `<role-specific reporting expectation>`
- `<role-specific verification log entry>`
