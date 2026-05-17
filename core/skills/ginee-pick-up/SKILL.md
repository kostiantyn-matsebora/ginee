---
name: ginee-pick-up
description: Pick up a GitHub issue from the primary repo and run it through the engineering-team Phase 1–8 lifecycle. Use when the user asks to 'pick up issue #N', 'work on issue #N', 'start on #N'. Fetches the issue, swaps engineering-team:ready → engineering-team:in-progress label, parses the structured body, runs Phase 1 analysis, then dispatches through the standard lifecycle with comments at each transition.
---

# Pick up issue — primary repo

Run the inbound issue-pickup workflow per `.agents/engineering-team/core/github-integration.md § Inbound — pick up an issue`. Always targets the primary repo (= the working tree's origin); there is no `framework-` variant — addressing a framework issue requires working in the framework repo.

## Activation

- User asks "pick up issue #N" / "work on issue N" / "start on #N" / "begin issue N".

## Procedure

1. Load `.agents/engineering-team/core/github-integration.md` and `.agents/engineering-team/core/process.md § Task lifecycle`.
2. Fetch the issue: `gh issue view <N> --repo <primary-repo> --json title,body,labels,state,comments` (or GitHub MCP equivalent).
3. Validate:
   - State must be `OPEN`. If `CLOSED` → stop and ask the user.
   - Labels include `ready-label`. If missing → ask the user to add it before pickup.
4. Parse the structured body. Map `## Affected area` → owning specialist per `local/bindings.md`.
5. Swap labels: remove `ready-label`, add `in-progress-label` via `gh issue edit <N> --remove-label <r> --add-label <i>` (or MCP).
6. Run Phase 1 analysis treating the parsed body as the task description; surface ambiguities; produce Phase 2 dispatch plan.
7. Run iteration protocol per `.agents/engineering-team/core/iteration-protocol.md` when total scope > 15 min: return decomposition + per-task estimates before editing.
8. Standard Phase 1–8 dispatch. Post a structured comment at each major transition per the spec's Comment cadence table:
   - Phase 3 design review surfaced → architecture diff + work breakdown + "awaiting approval".
   - Phase 7 SA review outcome → APPROVE / RETURN-TO + findings.
   - Phase 8 acceptance → summary + PR/commit links + "closing on accept".
   - Stoppable intermediate → done / in-progress / not-started lists.
9. On Phase 8 acceptance, close the issue with a final summary comment.

## Forbidden

- Never pick up without label swap (step 5).
- Never edit the reporter-authored issue body — comments only.
- Never close silently — final comment required.
- Never skip Phase 3 design review when the issue body presents multiple design options (automatic mode does NOT elide Phase 3 for design choice).
