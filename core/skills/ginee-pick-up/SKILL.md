---
name: ginee-pick-up
description: Pick up a task from any source and run it through the ginee Phase 1–8 lifecycle. Task source can be a GitHub issue (`#N`), a TODO line in any TODO file (root or nested), or a freeform description. Use when the user asks to 'pick up #N', 'work on issue N', 'pick up the TODO about X', 'start working on Y', or otherwise explicitly invokes the lifecycle on a specific task.
---

# Pick up task — unified

Single entrypoint for all task sources defined in `.agents/ginee/core/process.md § Task model`. Detects the source from the user's prompt and routes to the matching workflow.

## Activation

User asks "pick up X" / "work on X" / "start on X" / "begin X" where X is one of:

- A GitHub issue: `#<N>`, `issue #<N>`, `issue N`.
- A TODO line: file path + line (`TODO:12`), quoted line text, or "the TODO about Y".
- Freeform: a description with no issue/TODO reference.

## Procedure

### Step 1 — identify task source

- `#<N>` or `issue N` → GitHub issue (primary repo).
- TODO reference → TODO line.
- Otherwise → freeform.

### Step 2 — per source

**GitHub issue** — per `.agents/ginee/core/protocols/github-integration.md § Inbound — pick up an issue`:

1. Fetch + parse the issue.
2. Validate `OPEN` state + `ready-label`.
3. **Scoring labels + sticky comment** per `.agents/ginee/core/protocols/triage-scoring.md § Score comment + audit trail`:
   - Missing `value:*` → ask user (H / M / L); add `value:high|medium|low` label; post `<!-- ginee:value-prompt -->` audit comment.
   - Missing `complexity:*` → dispatch `solution-architect` for H / M / L estimate; post `<!-- ginee:complexity-estimate by=solution-architect value=H at=<ISO> -->` audit comment + add `complexity:high|medium|low` label.
   - Post / update the sticky `<!-- ginee:score v=1 -->` comment (one per issue; find via marker; never duplicate). `Reasoning` column populated only for ginee-set rows.
4. Swap labels: `ready-label` → `in-progress-label`.
5. Run Phase 1–8.
6. Post structured comments at major transitions (Phase 3 design review / Phase 7 SA review / Phase 8 acceptance / stoppable intermediate).
7. Close on Phase 8 acceptance with final summary comment + PR/commit links.

**TODO line** — per `.agents/ginee/core/process.md § Task model § TODO file rules`:

1. Read the TODO line at the cited path + line; parse optional `[v:N c:M]` marker per `.agents/ginee/core/protocols/triage-scoring.md`.
2. Confirm with the user this is the intended task.
3. Run Phase 1–8.
4. On Phase 8 acceptance, flip `☐` → `☒` on the source line.

**Freeform user request** — per `.agents/ginee/core/process.md § Task model` (direct-instruction source):

1. Treat the prompt as the task description.
2. Run Phase 1–8. No per-source artefact to update.

### Step 2.5 — sub-issue fast-path (GitHub issue only)

Sub-issues carry the dispatch decision in labels + body per `core/protocols/github-integration.md § Sub-issue dispatch`; skill-runner dispatches the labelled cardinal, skipping `@team-lead` — routing artefact exists.

**Detect parentage.** `gh api repos/{owner}/{repo}/issues/{N}` exposes the `parent_issue` field; confirm via `gh api repos/{owner}/{repo}/issues/{parent}/sub_issues`.

**Fast-path applies when ALL hold.**

- Parent resolves (issue is a sub-issue).
- Exactly one `ginee:role:<cardinal>` label.
- Body carries the dispatch contract per `core/templates/sub-issue-dispatch.md` (`## Scope` · `## Acceptance` · `## Spec links` · `## Phase` · `## Estimate`).

Parent issues are unchanged — Step 3 routes them to `@team-lead`.

**Re-entry — `@team-lead` re-loaded when ANY trigger fires.**

| Trigger | Source |
|---|---|
| Role label missing or conflicting | pre-dispatch check |
| Cardinal return — `## Open issues` non-empty | cross-cardinal synthesis needed |
| Cardinal return — `## Hand-off` set | routing change — re-plan |
| Cardinal return — `Status: In-progress` | stop-state re-decision |
| Cross-domain bug surfaced | `core/protocols/cross-domain-bugs.md` |

Skill-runner never synthesizes a cardinal return — on trigger, dispatch `@team-lead` with the return as inbound payload. Same forbiddens as `core/process/dispatch.md § Skill-runner — surface boundary`.

### Step 3 — hand off

After Step 2 mechanical ops (label swap · sticky post · branch resolution) and **before any Phase 1 plan drafting**, skill-runner dispatches the resolved target per `core/process.md § Skill-runner — surface boundary`:

| Source shape | Target | Inbound payload |
|---|---|---|
| Parent issue · TODO · freeform | `@team-lead` | parsed task body + scoring labels + label-swap result + (issue-sourced) branch |
| Sub-issue · fast-path gate pass (Step 2.5) | `@<cardinal>` (from role label) | parsed dispatch body + scoring labels + label-swap result + branch |

From here on every orchestration decision — Phase 1–8 plan drafting · specialist routing · synthesis of parallel returns · lifecycle gate text · re-dispatch · routing reconciliation · default selection — flows through team-lead (or, under the Step 2.5 fast-path, through the dispatched cardinal until any re-entry trigger fires). The skill-runner never:

- Drafts a Phase 1–8 plan in the main thread.
- Reads `local/bindings.md` to settle a routing question — it dispatches team-lead instead.
- Synthesizes specialist returns or proposes reconciliation options.
- Picks defaults ("I'll pick option 1 if you don't redirect"). Defaults belong to team-lead.

### Step 4 — common lifecycle (team-lead-owned)

team-lead runs the full lifecycle per `.agents/ginee/core/roles/team-lead.md` + `.agents/ginee/core/process.md`:

- Dispatches specialists per `local/bindings.md`.
- Runs iteration protocol per `.agents/ginee/core/protocols/iteration-protocol.md` when total scope > 15 min.
- Enforces gates at Phase 3 (design review), Phase 7 (SA review), Phase 8 (user approval).

## Forbidden

- Never pick up without identifying the source first — rules differ per source.
- GitHub issue: never edit the reporter-authored body — comments only.
- TODO item: never auto-add new TODO lines (`§ TODO file rules` — never auto-generated, never auto-extended).
- Never silently close out — Phase 8 acceptance is always surfaced.
- Never run the framework-upstream variant from an adopter project — addressing a framework issue requires working in the framework repo (where origin = framework; plain `pick up #<N>` works).
- **Skill-runner forbiddens.** After Step 3 hand-off the skill-runner must not draft plans · synthesize parallel returns · answer routing/governance questions by reading project files · propose default-selection options · re-dispatch specialists in the main thread · **set, recommend, or carry a tracking-mode posture in the hand-off payload — the four-tier resolution chain (`core/protocols/github-integration.md § Sub-issue dispatch`) is closed and re-derived by team-lead on every parent dispatch**. Every such decision dispatches `@team-lead`. Full boundary: `.agents/ginee/core/process/dispatch.md § Skill-runner — surface boundary`.
