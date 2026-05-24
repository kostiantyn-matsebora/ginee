# Sub-issue dispatch — body template (D39)

Authored by `team-lead` per `core/MIGRATIONS/D39-sub-issue-dispatch.md`. One sub-issue per cardinal dispatch under the parent task issue. D26-binding — self-lint per `core/process.md § Mandatory checks before report-as-done` before posting.

## Title

```
[<phase>:<cardinal>] <task-one-liner>
```

Examples:

- `[4:backend-engineer] Implement /v1/items pagination per ADR-0014-cursor-pagination`
- `[5:qa-engineer] Author scenario suite for FR-12-bulk-import`
- `[7:solution-architect] Governance review of PR #142 (touches docs/architecture.md)`

## Labels (set at create)

| Namespace | Value |
|---|---|
| `ginee:role:<cardinal>` | one of the 7 cardinals |
| `ginee:phase:<N>` | `1` … `8` — updated on phase transition |
| `value:<H|M|L>` | inherited from parent |
| `complexity:<H|M|L>` | inherited from parent |

## Body shape

```markdown
<!-- ginee:sub-issue-dispatch v=1 parent=#<parent-number> -->

## Dispatch contract

**Cardinal:** `<role>` (alias: `<alias-if-any>`)
**Phase:** <N> — <phase-name>
**Parent:** #<parent-number>
**Estimate:** <H>h <M>m (per iteration-protocol; updates as sub-tasks land)
**Delivery mode:** Mode <1|2|3> per `core/delivery-modes.md`

## Scope

<one paragraph OR bulleted scope — what's in, what's out>

## Acceptance

- [ ] <criterion 1 — testable / observable>
- [ ] <criterion 2>
- [ ] <criterion 3>

## Spec links

| Spec | Surface |
|---|---|
| `<path>` | `<§ section>` |
| `<path>` | `<§ section>` |

## Initial state

| Track | Status |
|---|---|
| time | `time: 0m` · `cumulative: 0m` |
| sub-tasks | (none started — cardinal owns decomposition + per-task estimate per `core/protocols/iteration-protocol.md`) |
| blockers | (none) |
```

## Comment cadence — cardinal-authored

| Trigger | Shape |
|---|---|
| Sub-task start | `Started: <sub-task>. time: 0m (since last comment). cumulative: <N>m.` |
| Sub-task complete | `Done: <sub-task>. <commit-sha-link-if-any>. time: <N>m. cumulative: <N>m.` |
| Blocker | `Blocked: <reason>. Needs: <unblock action>. time: <N>m. cumulative: <N>m.` Plus label swap on sub-issue: add `ginee:blocked`. |
| Hand-off request | `Hand-off: <reason> → @<role>`. Embed `core/templates/hand-off-note.md` shape. time + cumulative. Plus team-lead authors the new sub-issue for the recipient role. |
| Phase change within dispatch (rare — single-dispatch usually = single-phase) | `Phase <N> → <N+1>: <reason>. time: <N>m. cumulative: <N>m.` Plus label swap on sub-issue: `ginee:phase:<N>` → `ginee:phase:<N+1>`. |

D26 binding — every comment self-lints against the 5 mandatory checks before posting.

## Closing comment — phase-report return

Cardinal's D29 phase-report return per `core/templates/phase-report.md` doubles as the closing comment. **`## Time spent` section is mandatory in sub-issue mode** — one-liner: `<H>h <M>m perceived effort; <N> progress comments on sub-issue #<M>.`

Marker `<!-- D29 self-lint: pass -->` on the last line (D33).

team-lead posts the return as the closing comment, then closes:

```
gh issue close <M> --reason completed
```

Stop-state returns (`Status: In-progress`) do NOT close — they post as a progress comment; sub-issue stays open per `core/MIGRATIONS/D39-sub-issue-dispatch.md § Stop-state interaction`.

## Forbidden

- Never edit the dispatch contract body after create. Scope changes → close + open a new sub-issue (audit trail is append-only).
- Never close a sub-issue with `--reason not_planned` on completed work; only on cancelled / superseded dispatches.
- Never reuse a sub-issue across dispatches — each dispatch = one sub-issue.
- Never federate sub-issues across repos.
- Never post inline code blocks > 5 lines (D29 carve-out applies — link the commit / paste path instead).
- Never include the cardinal's full reasoning prose — `## Notes` cap (200 words) per D29 applies to closing comments too.
