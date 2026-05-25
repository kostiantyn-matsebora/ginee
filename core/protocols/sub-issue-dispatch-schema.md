# Sub-issue dispatch schema

**Load-on-demand.** Loaded when `team-lead` opens a sub-issue per cardinal dispatch (sub-issue-tracking mode active per `core/protocols/github-integration.md § Sub-issue dispatch`), or when a cardinal posts progress / closing comments on a sub-issue.

Procedure + resolution chain + assignee precedence + forbidden ops live in `core/protocols/github-integration.md § Sub-issue dispatch`. Literal artefact templates (title · labels · body · comment shapes) live in `core/templates/sub-issue-dispatch.md`. This file binds the **rules + self-lint** across the lifecycle.

## Schema

One sub-issue per `team-lead` → cardinal dispatch under the parent task issue. Three surfaces:

| Surface | Authored by | Cardinality | Cite |
|---|---|---|---|
| **Dispatch contract body** | `team-lead` at create | 1 per sub-issue (frozen — scope change = close + new sub-issue) | `core/templates/sub-issue-dispatch.md § Body` |
| **Progress comments** | dispatched cardinal during execution | 0..N per sub-issue per phase | `core/templates/sub-issue-dispatch.md § Comment cadence` |
| **Closing comment** | dispatched cardinal at return | 1 per sub-issue (phase-report return doubles as closing comment) | `core/templates/phase-report.md` |

| Element | Required on | Source |
|---|---|---|
| Title `[<phase>:<cardinal>] <task-one-liner>` | dispatch contract | `core/templates/sub-issue-dispatch.md § Title` |
| Header marker `<!-- ginee:sub-issue-dispatch v=1 parent=#<parent-number> -->` | dispatch contract body | Fixed; first body line |
| Labels — `ginee:role:<cardinal>` · `ginee:phase:<N>` · inherited `value:*`/`complexity:*` | sub-issue at create | `core/templates/sub-issue-dispatch.md § Labels` |
| Body sections — `Dispatch contract` · `Scope` · `Acceptance` · `Spec links` · `Initial state` | dispatch contract body | `core/templates/sub-issue-dispatch.md § Body` |
| Time fields `time: <N>m` · `cumulative: <N>m` | every progress comment | `core/templates/sub-issue-dispatch.md § Comment cadence` |
| `## Time spent` section | closing comment | `core/templates/phase-report.md § ## Time spent` |
| Self-lint marker `<!-- self-lint: pass -->` | every surface (body · progress · closing) | Last line per `core/protocols/doc-authoring-protocol.md § Enforcement for ginee-authored GitHub artefacts` |

## Section templates

Literal skeletons live in `core/templates/sub-issue-dispatch.md`. This file does not duplicate them. Cross-refs:

- Dispatch contract body — `core/templates/sub-issue-dispatch.md § Body`.
- Progress comment cadence table — `core/templates/sub-issue-dispatch.md § Comment cadence — cardinal-authored on the sub-issue`.
- Closing comment — `core/templates/sub-issue-dispatch.md § Closing comment` + `core/templates/phase-report.md`.

## Forbidden patterns

1. **Editing the dispatch-contract body after create.** Scope change = close + open new sub-issue. Per `core/templates/sub-issue-dispatch.md § Forbidden`.
2. **Reusing a sub-issue across dispatches.** 1 dispatch = 1 sub-issue.
3. **Closing with `--reason not_planned` on completed work.** Reserved for cancelled / superseded dispatches.
4. **Inline code blocks > 5 lines** in body or comment. Per `core/templates/sub-issue-dispatch.md § Forbidden` + `## Notes` carve-out in `core/templates/phase-report.md`.
5. **Carrying tracking-mode posture in skill-runner hand-off briefs.** Per `core/process/dispatch.md § Skill-runner — surface boundary`.
6. **Federating sub-issues across repos.** One repo per `github.repo`.

## Worked example

| Surface | Content |
|---|---|
| Title | `[4:backend-engineer] Implement /v1/items pagination per ADR-0014-cursor-pagination` |
| Labels | `ginee:role:backend-engineer` · `ginee:phase:4` · `value:high` · `complexity:medium` |
| Body header | `<!-- ginee:sub-issue-dispatch v=1 parent=#142 -->` (body per `core/templates/sub-issue-dispatch.md § Body`) |
| Progress 1 | `Started: cursor encode/decode. time: 0m. cumulative: 0m.` |
| Progress 2 | `Done: cursor encode/decode. abc1234. time: 22m. cumulative: 22m.` |
| Closing | phase-report return with `## Time spent`: `1h 04m perceived effort; 2 progress comments on sub-issue #198.` |
| Close op | `gh issue close 198 --reason completed` |

## Self-lint checks

Run against every surface — body · progress comment · closing comment — **before** posting:

1. Title matches the `[<phase>:<cardinal>] <task-one-liner>` form (body surface only).
2. Header marker present on the body; first body line.
3. Labels include exactly one `ginee:role:*` · one `ginee:phase:*` · inherited scoring labels.
4. Every progress comment carries both `time: <N>m` AND `cumulative: <N>m`.
5. Closing comment includes the `## Time spent` section per `core/templates/phase-report.md`.
6. Doc-authoring 5 mandatory checks per `core/process.md § Documentation style § Mandatory checks`.

Append, as the **last line** of each posted surface, the literal attestation marker `<!-- self-lint: pass -->`.

<!-- self-lint: pass -->
