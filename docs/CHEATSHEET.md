---
title: Cheatsheet
description: "One-page quick reference — every command, label, phase, and pattern you'll touch."
permalink: /CHEATSHEET.html
---

# Cheatsheet

One page. Daily use. Bookmark it.

## Install / update

```bash
# Fresh install
curl -fsSL https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh | bash -s -- --adapter claude
.\install.ps1 -Adapter claude        # PowerShell

# Pin version
./install.sh --ref v0.1.0 --adapter claude
$env:GINEE_REF='v0.1.0'; iwr ... | iex

# Update (preserves local/) — installer is NOT co-located (D27); use /ginee-update or the bootstrap one-liner:
GINEE_UPDATE_ONLY=1 GINEE_ADAPTER=claude bash -c "$(curl -fsSL https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh)"
$env:GINEE_UPDATE_ONLY='1'; $env:GINEE_ADAPTER='claude'; iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.ps1 | iex
```

Adapters: `claude` · `copilot-cli` · `agents-md` · `generic`.

## First-day workflow

```
Run initial discovery                  # ginee-discovery skill
```

Then:

```
@<role> <task>                         # dispatch a specialist
auto: <task>                           # elide per-phase gates (D12)
branch: <task>                         # force feature-branch + PR mode (D17)
wt: <task>                             # working-tree only — no commits
commit: <task>                         # commit-no-push
auto: branch: <task>                   # combine — auto mode + branch+PR
```

## Framework skills (tier-1: Claude Code, Copilot CLI)

Slash commands `/ginee-<skill> [args]`. Natural-language phrasings also match. Tier-2/3 fallback: `act as team-lead and …`.

```
/ginee-discovery                          # initial onboarding (Step 2 of install)
/ginee-rediscover                         # full re-discovery + re-extraction
/ginee-file-bug <title>                   # opens issue in primary repo (current)
/ginee-file-feature <title>
/ginee-file-framework-bug <title>         # opens issue in ginee upstream repo
/ginee-file-framework-feature <title>
/ginee-pick-up #<N>                       # GitHub issue (primary repo)
/ginee-pick-up <todo-ref>                 # TODO line (path:line / "TODO about X")
/ginee-pick-up <freeform-description>     # direct instruction
/ginee-triage                             # list ready issues + TODOs
/ginee-triage framework                   # list ready framework upstream issues
/ginee-promote-discussion #<N>            # discussion → draft issue
/ginee-reindex                            # reconcile index with current repo state (whole repo)
/ginee-reindex <file|class>               # scoped reconciliation
/ginee-update                             # update framework to latest release (preserves local/)
/ginee-update <tag|branch|sha>            # update to a named ref
/ginee-address-review #<PR>               # ingest review comments on an open PR (D24)
```

## Freeform requests (any tier)

```
Use ginee to <task description>           # team self-dispatches; no skill needed
```

## Phase lifecycle

| Phase | Goal | Gate |
|---|---|---|
| 1. Analysis | Bound scope | ≤ 1 unresolved scope question |
| 2. Design | Lock contracts | Contract surfaces fixed |
| 3. Design review | User approval of Phase 2 | **Explicit user OK** (elided in auto mode if no UX impact) |
| 4. Implementation | Working code | Compiles + unit tests pass |
| 5. Testing | Change-scoped suites + manual smoke | Touched-surface oracles green |
| 6. Bug fixing | Resolve Phase 5 defects | No regressions |
| 7. SA review | Architecture compliance | APPROVE or RETURN-TO-engineer |
| 8. User approval | Delivery accept | TODO ☐ → ☒; issue closed; PR per mode |

## GitHub label scheme

| Label | Meaning |
|---|---|
| `ginee:ready` | Pickup candidate (`☐` equivalent) |
| `ginee:in-progress` | PM has dispatched; phases 1–7 in flight |
| `ginee:blocked` | Stoppable intermediate state; awaiting user / external |
| `value:high|medium|low` | Triage scoring — reporter-defined business impact (D23) |
| `complexity:high|medium|low` | Triage scoring — reporter or SA auto-estimate (D23) |
| `ginee:role:<cardinal>` | **D39** — sub-issue dispatch — identifies cardinal owning the dispatch |
| `ginee:phase:<N>` | **D39** — sub-issue dispatch — current lifecycle phase (1–8) |
| `ginee:track:off` | **D39** — set on parent to opt out of sub-issue tracking for that issue |
| (closed issue) | Done — implicit, no label change needed |

## Sub-issue dispatch (D39)

On issue-sourced tasks, team-lead creates one GitHub sub-issue per cardinal dispatch under the parent — labelled by role + phase, threading progress comments + cumulative time, closed on phase-report return. Cross-session resume reads parent + open sub-issues; no transcript replay.

```
notrack: <task>                    # opt out of sub-issue tracking for this task
```

Per-issue opt-out — apply `ginee:track:off` label on the parent issue.

Repo-wide opt-out — `local/framework.config.yaml`:

```yaml
dispatch:
  tracking: in-context             # sub-issues (default on github.repo) | in-context
  time-tracking: false             # turn off the time-tracking surface
```

**Assignee precedence** — non-empty human assignee on a sub-issue overrules the `ginee:role:<cardinal>` label; cardinal dispatch suspended until cleared. Reassign to empty to resume.

Progress-comment shape (cardinal-authored on the sub-issue):

```
Started: <sub-task>. time: 0m. cumulative: 12m.
Done: <sub-task>. <commit-link>. time: 18m. cumulative: 30m.
```

Phase-report return doubles as the closing comment; mandatory `## Time spent: <H>h <M>m perceived effort; <N> progress comments on sub-issue #<M>.`

## Triage scoring (D23)

```
score = value / complexity                # H=3, M=2, L=1 (ATAM H/M/L)
```

| value \ complexity | H | M | L |
|---|---|---|---|
| **H** | 1.00 | 1.50 | **3.00** (quick-win) |
| **M** | 0.67 | 1.00 | 2.00 |
| **L** | 0.33 | 0.50 | 1.00 |

`/ginee-triage` sort key: `Score DESC, Age DESC`. Unscored grouped at bottom. TODO marker `☐ [v:H c:L] Description` (case-insensitive). Sticky `<!-- ginee:score v=1 -->` comment per issue; refresh via `@team-lead recompute score #<N>`. Override formula: `local/framework.config.yaml § triage.scoring-formula`.

## Classical-architect SA model (D25)

SA has **three activities** across the lifecycle:

| Activity | When | What |
|---|---|---|
| **Design** | Phase 1 elicit + Phase 2 architecture | Authors `local/requirements.md` (FR/NFR/Constraints) + `local/asr-utility-tree.md` (ASRs via ATAM) + architecture doc + ADRs |
| **Review** | Any phase, on engineer-proposed arch changes | APPROVE / REJECT / REQUEST-CHANGES; never edits code |
| **Governance** | Continuous, scoped to PRs touching SA-owned files | Drift-flag + dispatch back to owning engineer |

**D25 doc-ownership map** (per `core/protocols/doc-roles.md`):

| Doc class | Owner |
|---|---|
| Architecture doc · ADRs · requirements register · ASR utility tree · diagrams | `solution-architect` |
| CRs · project-instruction file · work-breakdown | `team-lead` |
| CI/CD guide · infra runbooks | `devops-engineer` |
| Backend READMEs · API docs · service docs | `backend-engineer` |
| Frontend READMEs · component docs · style guides | `frontend-engineer` |
| Test plans · scenario docs · QA reports | `qa-engineer` |
| Mockup | mockup-owning role (default `frontend-engineer`) |

**Engineer-proposed architectural change** (delta to contract / topology / stack / NFR-affecting): draft in final report → SA `§ Review` → APPROVE/REJECT/REQUEST-CHANGES → engineer implements after APPROVE. Local bug fixes (no architectural delta) route engineer → engineer; no SA dispatch.

**Greenfield vs delta** — discovery detects "no architecture doc" → `greenfield: true` in `local/project-profile.md` → SA enters greenfield design on first non-trivial task. Delta mode produces ADR + ASR amendments; never rewrites the architecture doc wholesale.

Migration on upgrade: `@team-lead rediscover` runs Step 8c re-attribution sweep per [`migrations/classical-architect.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/classical-architect.md).

## Change governance (D45)

Pre-authorship gate on CR / ADR drafting. Adopter-controlled via `local/framework.config.yaml § change-governance`.

```yaml
change-governance:
  cr:
    enabled: true                       # set false → skip CR authorship
    skip-when-issue-source: true        # issue IS the requirement record
  adr:
    enabled: true                       # set false → skip ADR authorship
    require-architectural-delta: true   # no delta heuristic → skip ADR
  prompt-before-create: non-trivial     # always | never | non-trivial
```

| Prefix | Effect |
|---|---|
| `cr:` | Force CR authorship (overrides config) |
| `nocr:` | Skip CR authorship (overrides config) |
| `adr:` | Force ADR authorship (overrides config) |
| `noadr:` | Skip ADR authorship (overrides config) |

Combine with `auto:` · `branch:` · `wt:` · `commit:` · `model:<tier>` · `notrack:`.

**Architectural-delta triggers** (ADR gate) — component boundaries · wire contracts · NFR-bearing claims · architecture invariants · stack / topology / infrastructure.

**Non-trivial heuristic** — ≥ 2 delta triggers OR `local/requirements.md` register-diff non-empty.

**Skip-reason enum** — `config-disabled` · `issue-source-skip` (CR) · `no-architectural-delta` (ADR) · `prefix-override` · `user-declined`. Logged under `## Decisions made` in the phase-report.

Full spec: [`migrations/change-governance-opt-out.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/change-governance-opt-out.md).

## Address review on a PR (D24)

```
/ginee-address-review #<PR>               # ingest review comments + reviews
@team-lead address-review #<PR>           # command equivalent (every adapter)
```

Procedure: fetch `pulls/{N}/comments` + `/reviews` → dedup by `thread-id` (skip resolved + already-marked) → route each remark per `local/bindings.md § Source-of-truth ownership` → **surface plan table for approval (forced-interactive, even in `auto:`)** → dispatch specialists in parallel → squash fixes into one cycle commit + push → post per-thread replies + one sticky cycle summary. Lossless coverage (every remark → fix OR reply). Markers `<!-- ginee:review-reply r=<id> -->` (per-thread) + `<!-- ginee:review-cycle n=<N> -->` (sticky).

## Subagent-return schema (D29)

Every cardinal-dispatch return is schema-bound per `core/templates/phase-report.md`.

```
Status: Done | In-progress | Blocked | Hand-off

## Files touched           # table — path · Δ lines · purpose       (required; (none) if empty)
## Decisions made          # bullets — imperative + cite (≤ 80 ch)  (required; (none) if empty)
## Verification log        # table — command · outcome              (required)
## Open issues             # bullets — issue + owner (≤ 80 ch)      (required; (none) if empty)
## Next dispatch needed    # one-liner — role · surface · reason    (required; (none) if empty)
## Source reads (this dispatch)  # table — path · justification · index entry  (required; (none) if empty)
## Hand-off                # core/templates/hand-off-note.md         (forced-handoff only)
## Stop-state              # Done / In-progress / Not-started        (Status: In-progress only)
## Notes                   # free prose · ≤ 200 words                (optional escape hatch)
```

**7 mandatory checks before report-as-done** — 6 from D22 / D26 / D48 (D48 added RFC 2119 binding-strength signal) + *no narrative preamble*. Forbidden — narrative preamble · restated dispatch context · code snippets outside the Notes carve-out · verbose rationale outside `## Notes` · parenthetical comma-soup. Target reduction vs free-form returns: ~70%.

**Index-first read order** — cardinals consult `local/index/` summaries first; raw source reads are fallback + require a one-line justification in `## Source reads`. Orchestrator's single format-only re-dispatch carve-out fires when raw source appears in `## Files touched` AND `## Source reads` is missing / `(none)`. Bedrock: `core/protocols/index-protocol.md § Read order`.

## Release-surface authoring (D40)

Three surfaces, three voices, three caps — applies only to maintainers drafting release artefacts.

| Surface | Voice | Bullet cap |
|---|---|---|
| `migrations/D<N>-*.md` | Framework-dev (precise jargon OK) | None — structured tables / lists |
| `docs/CHANGELOG.md` | Framework-dev in sub-bullets; lead-in ≤ 25 words | Lead-in ≤ 25 words + sub-bullets |
| `.github/release-notes/v*.md` | **User-value** — adopter benefit at line start | **≤ 20 words per bullet** + `(D<N>)` tag |

**Sidecar self-lint** — 5 checks before publish: word cap · user-value voice · `(D<N>)` tag · no implementation boilerplate · migration link in footer.

**Pattern** — lead with adopter verb (`/ginee-update works again` not `Step 1 no longer requires installer scripts inside .agents/ginee/`). Full spec: [`core/protocols/changelog-protocol.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/changelog-protocol.md).

## Blueprint-diff gate (D41)

Phase 4 entry precondition — every dispatch touching `local/framework.config.yaml § visual-source-of-truth.path` diffs vs `blueprint-ref` first, classifies deltas, surfaces to team-lead before edits.

```yaml
# local/framework.config.yaml — defaults derive from `mockup:` when block absent
visual-source-of-truth:
  type: html-mockup           # html-mockup | figma | image | video | other
  path: docs/mockup.html
  blueprint-ref: origin/main  # or v1.2.0, snapshot path, Figma version URL
  scope-discriminator: block-glob
  enabled: true
```

| Delta class | Outcome |
|---|---|
| Expected (inside issue scope) | Edits proceed |
| Pre-existing | Edits proceed |
| Unexpected (outside issue scope) | Forced-interactive gate — auto-mode does NOT elide |

**4 mandatory checks** before edits begin — config resolved · diff computed · classification complete · `## Verification log` row written. Inapplicable case (no edit on configured path) — cite `"visual-SoT untouched — protocol n/a"` and skip.

Full spec: [`core/protocols/blueprint-diff-protocol.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/blueprint-diff-protocol.md).

## Option-list shape (D30)

Every Phase 2 design proposal + every iteration-protocol Propose step (Phase 4–7 > 15-min sub-tasks with a live adopt-vs-build axis) MUST surface ≥ 1 adopt candidate OR an explicit `(none viable — <reason>)` cite.

```
Options:
- adopt — <name> v<version> — <license> — <source link>
  — fit: <one-line concrete rationale, citing constraint / NFR / stack>
- adopt — <name> v<version> — <license> — <source link>
  — fit: <one-line>
- build — <scope> — rationale: <why surveyed adopts rejected>
# OR if research empty:
- (none viable — <one-line reason>)
- build — <scope> — see ADR draft.
```

**5 mandatory checks before surfacing** — adopt floor present · citations complete (name · version · source · license · fit) · tagging explicit (`adopt` / `build` / `hybrid` — no silent mixing) · empty research documented · fit rationale concrete (not hand-waved). Self-lint runs in-thread; no external linter. **License gating** — framework expresses no opinion; adopters wire policy in `local/`. Inapplicable sub-tasks cite *"axis n/a — <reason>"* and skip.

Full spec: `core/protocols/options-protocol.md`. Example: `core/protocols/doc-authoring-examples.md § 11`.

## Model tier (D31)

Three tiers (vendor-neutral); per-task prefix combinable with `auto:` / `branch:` / `wt:` / `commit:`:

```
reasoning  ← team-lead · solution-architect           (Claude default: claude-opus-4-7)
standard   ← ai-engineer · 4 engineer cardinals       (Claude default: claude-sonnet-4-6)
fast       ← opt-in for mechanical work                (Claude default: claude-haiku-4-5-20251001)
```

Per-task prefix examples:

```
model:reasoning Add the new ASR utility-tree leaves for the latency NFR.
auto: model:fast Re-label stale issues with ginee:blocked.
branch: model:reasoning Pick up #N
```

**Resolution order** (stop at first match) — (1) `model:<tier>` prefix · (2) Phase-3 user answer · (3) `local/framework.config.yaml § model-tier.per-role.<role>` · (4) `core/roles/<role>.md` `default-tier:`.

**Adapter override.** Edit `local/framework.config.yaml § model-tier` (per-role tier + per-adapter tier→model map); re-run installer to apply.

Full spec: `migrations/model-tier.md`.

## Source-of-truth pattern

```
local/index/*               ← default read every dispatch
docs/* (raw)                ← on demand only (verbatim wording matters)
local/bindings.md           ← governance + tie-breakers
local/project-profile.md    ← discovered project context
local/framework.config.yaml ← concept → path mappings
```

## Strict-domain rule (forbidden role-crossings)

Per `local/bindings.md § Project role boundaries`. Each row is a hard stop.

| Role | Must NOT edit |
|---|---|
| `solution-architect` | mockup, server source, client source, IaC, Dockerfiles, CI workflows. **(D25)** CRs · project-instruction · work-breakdown → `team-lead`; per-tier docs → tier engineers. SA reviews these for architectural coherence; does not edit. |
| `frontend-engineer` | server source (incl. SQL in API endpoints), IaC, Dockerfiles, CI workflows |
| `backend-engineer` | client source, mockup, IaC, Dockerfiles, CI workflows |
| `devops-engineer` | application code, schema migrations, application config content |
| `qa-engineer` | mockup, production server / client code (owns test code only) |
| `ai-engineer` | rules / invariants / requirements (semantics → **the doc's authoring role per D25**, not SA-only); production / test / IaC code |
| `team-lead` | everything except `local/*` written during discovery + **(D25)** CRs · project-instruction · work-breakdown which team-lead authors |

Cross-domain need surfaced mid-task → **propose hand-off in final report**. Never patch across. **Engineer-proposed architectural changes (D25)** route to `solution-architect § Review` (APPROVE / REJECT / REQUEST-CHANGES).

## Index file Load-when tiers

Per cardinal role kernel `## Source of truth`:

- **always** — foundational; loaded every dispatch (single-digit KB combined).
- **scope-loaded** — trigger phrase (e.g. `wire/endpoint touch`, `infra work`, `dep bump`, `test authoring`). Loaded only when the task description matches.

Specialist reports loaded set in first response.

## Iteration protocol (work &gt; 15 min)

1. Estimation-first dispatch — task decomposition + per-task minutes **before** edits.
2. User approves the batch.
3. 3–5 min iterations, each stoppable.
4. Stop anywhere → resume next session with zero rework.

## Delivery modes (D17)

| Prefix | Mode | Phase 8 |
|---|---|---|
| `branch:` | feature branch + PR | `gh pr create` with `Closes #<N>` |
| `wt:` | working-tree only | PM surfaces `git diff`; user commits / discards |
| `commit:` | commit-no-push | PM surfaces `git log`; user pushes |

Framework defaults: `branch` for issue / TODO-sourced; `wt` for freeform. Auto-mode default: `wt`.

## Common pitfalls

| Symptom | Likely cause | Fix |
|---|---|---|
| Specialist refuses to edit a file | Forbidden role-crossing | Dispatch the owning role |
| Index is dormant ("no consumer") | Novel class extracted but no kernel cites it | Wire via `local/bindings.md § Project-specific index citations` or remove the class |
| `local/index/` &gt; 30% of `docs/` size | Recipe over-extracting | Run `/ginee-reindex` against the worst class; check compression target ≤ 0.5 |
| Discovery flagged staleness on a doc | SHA-256 drift | `/ginee-reindex <source>` (scoped) or `/ginee-reindex` (whole-repo — also catches net-new files) or `/ginee-rediscover` |
| New doc / config landed but isn't in `local/index/` | Net-new file within existing class | `/ginee-reindex` reconciles; `/ginee-rediscover` only needed for novel classes (new directory / new tool) |
| PR didn't auto-close issue on merge | Stacked PR merged into non-default branch first | Manual `gh issue close <N> --comment "..."` |
| Trivial task loads full 64 KB baseline | Role kernel `Load when` not honoured | Specialist should report loaded set; if it doesn't, your kernel may be stale — `/ginee-update` to refresh |
| Framework feels out of date / missing a recent feature | Local install behind upstream | `/ginee-update` (latest release) or `/ginee-update <tag>` (named ref); never auto-updates — adopter approves the plan |
| Triage shows everything "Unscored" | No `value:*` / `complexity:*` labels yet | Reporter sets `value` at file-time; SA auto-estimates `complexity` on pickup; or `@team-lead recompute score #<N>` after `gh issue edit` |
| Review comments piling up on a PR | No invocation yet | `/ginee-address-review #<PR>` — plan-table approval is forced-interactive even in `auto:` |
| Adopter doc PR fails markdown lint | D22 doc-authoring protocol — discovered linter ran | Apply default-shape map (tables / bullets / definitions) per `core/protocols/doc-authoring-protocol.md`; verify with `${commands.lint.docs}` |
| ginee-filed issue / framework-authored comment has dense parenthetical-soup prose | D26 scope extension — self-lint missed it | Restructure per default-shape map (tables for inventories · bullets for multi-rule · no parenthetical comma-lists in sentences); covers every section, including Summary |

## Where things live

```
.agents/ginee/
├── core/                       # upstream — process spec + role kernels + templates
│   ├── process.md              # common — principles · doc style · reporting · index (D35)
│   ├── process/                # D35 — phase + dispatch files, load-on-demand per role
│   │   ├── phase-{1..8}-*.md   #   one file per lifecycle phase
│   │   └── dispatch.md         #   orchestration — skill-runner · parallelism · auto mode
│   ├── protocols/              # load-on-demand protocol specs (D46 — all named workflows here)
│   │   ├── automatic-mode.md             # D12 auto-mode
│   │   ├── delivery-modes.md             # D17 branch / wt / commit
│   │   ├── ci-watch.md                   # D20 post-PR CI watch
│   │   ├── triage-scoring.md             # D23 value × complexity
│   │   ├── doc-authoring-protocol.md     # D22 / D26 / D29 enforcement
│   │   ├── doc-authoring-examples.md     # paired bad/good examples
│   │   ├── doc-roles.md                  # D25 all-roles authorship
│   │   ├── doc-size-caps.md              # D44 per-class size caps
│   │   ├── index-protocol.md             # local/index/ extraction + load triggers
│   │   ├── index-syntax.md               # .idx DSL grammar
│   │   ├── iteration-protocol.md         # estimation-first dispatch
│   │   ├── options-protocol.md           # D30 adopt-vs-build shape
│   │   ├── blueprint-diff-protocol.md    # D41 visual-SoT diff gate
│   │   ├── changelog-protocol.md         # D40 release-surface authoring
│   │   ├── github-integration.md         # issue / PR / label flow
│   │   ├── cross-agent-handoff.md        # structured hand-off
│   │   ├── cross-domain-bugs.md          # propose → implement → verify
│   │   └── post-task-check-in.md         # after every completed request
│   ├── roles/                  # 7 cardinal role kernels (each declares phase-participation:)
│   └── templates/              # bindings, PR description, hand-off note,
│                               # requirements-register (D25), asr-utility-tree (D25)
├── adapters/<client>/          # upstream — per-client renderings (pointer files)
├── extras/roles/               # upstream — opt-in specialists
└── local/                      # YOU OWN THIS — survives every update
    ├── project-profile.md
    ├── bindings.md
    ├── framework.config.yaml
    ├── requirements.md         # D25 — FRs / NFRs / Constraints (SA-authored)
    ├── asr-utility-tree.md     # D25 — ASRs derived via ATAM (SA-authored)
    ├── index/                  # extracted summaries
    └── roles/                  # your custom roles
```
