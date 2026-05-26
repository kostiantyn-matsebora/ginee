---
title: Concepts
description: "The mental model — 7-cardinal team, phased lifecycle, dispatch rules, iteration protocol, index protocol, delivery modes."
permalink: /CONCEPTS.html
---

# Concepts

The mental model behind ginee. Worth reading once; you'll use the same patterns on every project.

## The 7-cardinal team

ginee ships exactly **7 cardinal roles** — every adopter project has the same shape:

| Role | Concerns |
|---|---|
| `team-lead` | Orchestrator. Dispatch routing, lifecycle gates, discovery / rediscovery, post-acceptance hook, staleness checks. **Authors (D25)** CRs · project-instruction file · work-breakdown doc. |
| `solution-architect` | **Classical architect (D25) — three activities.** **Design** (Phase 1 elicit FRs/NFRs/Constraints + derive ASRs via ATAM utility tree; Phase 2 target architecture). **Review** (any phase, on engineer-proposed architectural changes; APPROVE/REJECT/REQUEST-CHANGES; no code edits). **Governance** (continuous, scoped to PRs touching SA-owned files). Authors architecture doc · ADRs · diagrams · requirements register · ASR utility tree. |
| `ai-engineer` | AI-asset + doc context economy, file-splitting, load topology, lossless restructures. **D25 counterpart generalized — was SA-only, now all-roles.** Between-phase only. |
| `frontend-engineer` | Client / UI implementation, mockup ownership, state, styling, fetch / realtime client wiring. **Authors (D25)** frontend READMEs · component docs · style guides. |
| `backend-engineer` | Server / API implementation, ORM entities, schema, realtime hub, auth middleware, wire contract. **Authors (D25)** backend READMEs · API docs · service docs. |
| `devops-engineer` | IaC, Dockerfiles, orchestration, CI workflows, gateway config, secrets, cost tracking. **Authors (D25)** CI/CD guide · infra runbooks · deployment guides. |
| `qa-engineer` | Scenario specs, e2e / functional / smoke tests, harness assertions, fixtures, seed scripts. **Authors (D25)** test plans · scenario docs · QA reports. |

**Why exactly 7?** Two slots are universal — every project has an orchestrator and AI-asset / doc upkeep. The remaining 5 cover the engineering surfaces every software project has: client, server, infra, quality, plus the architect who governs the design across them.

**Specialists in `extras/roles/`** — security · ml · mobile · sre · data — are opt-in. Adopt them when discovery surfaces the matching domain.

**Custom roles** live under `local/roles/` and register under `team-lead`. Use the `core/templates/role-authoring-template.md` shape.

## Compliance enforcement (Claude adapter)

Class A action-time gates layer onto charter rules so they're enforced at the tool-call layer, not via always-loaded text alone. Two pieces ship in the parent playbook ([#135](https://github.com/kostiantyn-matsebora/ginee/issues/135)):

- **Per-cardinal `tools:` whitelist** ([T1](https://github.com/kostiantyn-matsebora/ginee/issues/137)) — `solution-architect` cannot `Edit` / `Write`; `ai-engineer` cannot `Bash`. Binary tool gate at the subagent level. Spec: [`migrations/cardinal-tools-whitelist.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/cardinal-tools-whitelist.md).
- **PreToolUse hook on `Edit` / `Write` / `MultiEdit`** ([T2](https://github.com/kostiantyn-matsebora/ginee/issues/138)) — exits 2 on hot-spec frontmatter omitted (D47) · `cap-bytes` exceeded without `Optimized-By` trailer · bare `D<N>` token introduced on `core/**` (D42) · `always` / `never` / `binding` / `mandatory` slipped past D48 · always-loaded surface bloat without trailer. Five charter rules graduate from advisory to blocking. Spec: [`migrations/pretooluse-edit-hook.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/pretooluse-edit-hook.md).

Opt out per-tactic via `local/framework.config.yaml § compliance.disabled: [<tactic-id>]`. Bypass per invocation via `SKIP_GINEE_COMPLIANCE=1` (emergency only).

## Phased task lifecycle

Every non-trivial task runs through **Phases 1–8**. Specialists within a phase run in parallel where independent; phases overlap wherever a contract surface decouples them.

| Phase | Goal | Acceptance |
|---|---|---|
| **1. Analysis** | Bound scope; identify touched domains. **(D25)** SA elicits FRs/NFRs/Constraints + derives ASRs via ATAM; resolves greenfield-vs-delta mode. | Scope clear enough to plan Phase 2; ≤ 1 unresolved scope question; ASR utility tree covers every quality-attribute-driver touched |
| **2. Design** | Lock contracts (architecture, mockup, wire, work breakdown). **(D25)** SA authors target architecture per resolved mode. | Fixed contract surfaces; harness green; cross-refs resolved; ASRs traceable to ADRs |
| **3. Design review** | Synchronous user-approval gate on Phase 2 | Explicit user approval |
| **4. Implementation** | Code mirroring approved contracts. **(D25)** SA governance dip on PRs touching SA-owned files; SA review on in-flight architectural-change proposals. | Compiles; per-project unit tests pass; no new lint errors |
| **5. Testing** | Change-scoped suites + manual smoke. **(D25)** SA governance dip if test surfaces architectural concern. | Touched-surface oracles green; manual-smoke report recorded |
| **6. Bug fixing** | Resolve defects from Phase 5. **(D25)** SA review on architectural fixes (vs local bug fixes). | Change-scoped oracles green; no regressions in touched surfaces |
| **7. SA review** | `solution-architect` checks invariants. **(D25)** Lighter — governance ran continuously across 4/5/6. | APPROVE or RETURN-TO-engineer with findings; ASR coverage verified |
| **8. User approval** | User confirms delivered work | TODO ☐ → ☒; issue closed; delivery finalize per mode |

**Auto mode (D12)** — prefix a task with `auto:` to elide intermediate gates (Phase 3 design review, iteration check-ins, engineer "stop and confirm"). Phase 8 becomes a single **delivery handoff** with Accept / Feedback / Reject. Forced back to interactive on UX changes, repeated defects, cross-domain cycles, or destructive actions.

## Compliance — Bash hook (T3)

A second PreToolUse hook ([#139](https://github.com/kostiantyn-matsebora/ginee/issues/139)) matches the `Bash` tool and blocks four destructive shell-command patterns: `git commit --no-verify`, `git push --force` on `main` / `master`, `git reset --hard` (with `SKIP_GINEE_COMPLIANCE` bypass), and `gh pr create` without `--body` / `--draft`. Allowlist preserves common legitimate workflows (force-with-lease on feature branches, soft reset, draft PRs).

Opt out per-tactic: `local/framework.config.yaml § compliance.disabled: [pretooluse-bash-hook]`. Full spec: [`migrations/pretooluse-bash-hook.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/pretooluse-bash-hook.md).

## Dispatch rules

| Rule | Action |
|---|---|
| Independent specialists in one phase | One message with N dispatch calls — **never serialize across messages** |
| Cross-phase overlap (e.g. test authoring during implementation) | One message; each prompt names the shared contract surface |
| Doc-only changes | `solution-architect` alone (or mockup-owning role alone for mockup-only) |
| Infra change affecting application config | Service-owner first (confirms app reads the new value), then `devops-engineer` |

**Strict-domain rule.** A bug in domain X is fixed by the engineer who owns X — never by an adjacent specialist "while they're in the area." Cross-domain bugs require collaboration, not single-specialist heroics.

## Compliance statusline (T4)

Tactic 4 of the parent playbook ships a single-line statusline ([#140](https://github.com/kostiantyn-matsebora/ginee/issues/140)) that surfaces compliance state in Claude Code's persistent status row — issue number · trailer status · cap-bytes headroom on the tightest hot-spec file. Class G (visible state, no enforcement) — partner to the action-time gates from T2 / T3.

Wire via `.claude/settings.json § statusLine`; opt out per-tactic: `local/framework.config.yaml § compliance.disabled: [compliance-statusline]`. Full spec: [`migrations/compliance-statusline.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/compliance-statusline.md).

## Iteration protocol

For Phase 4 / 5 / 6 / 7 work above 15 min OR any timeframe-bounded task:

1. **Estimation-first dispatch.** Each specialist returns task decomposition + per-task minutes **before** editing.
2. **Synthesis.** Orchestrator (or PM) synthesizes all specialist proposals into one batch for user approval.
3. **3–5 min iterations.** Each ends in a **stoppable intermediate state** — visible result, no half-finished edit on disk.
4. **Stop anywhere.** User can interrupt at any iteration boundary; resume next session with zero rework.

## Source-of-truth ownership

Per-project, the table in `local/bindings.md § Source-of-truth ownership` maps:

- **Default reads:** `local/index/*` (the extracted summaries).
- **Governance:** who edits each raw source.
- **Verbatim consumption:** where the full text lives when an index entry says "see source."

Roles **never** read raw `docs/**` "before any work." The index is the only default read surface; full source loads only when verbatim wording matters.

**D25 doc-ownership map** — per [`core/protocols/doc-roles.md § Authorship`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/doc-roles.md):

| Doc class | Owner |
|---|---|
| Architecture doc · ADRs · diagrams · requirements register (`local/requirements.md`) · ASR utility tree (`local/asr-utility-tree.md`) | `solution-architect` |
| CRs · project-instruction file · work-breakdown | `team-lead` |
| CI/CD guide · infra runbooks · deployment guides | `devops-engineer` |
| Backend READMEs · API docs · service docs | `backend-engineer` |
| Frontend READMEs · component docs · style guides | `frontend-engineer` |
| Test plans · scenario docs · QA reports | `qa-engineer` |
| Mockup | mockup-owning role (default `frontend-engineer`) |

Every non-SA-owned doc edit is **SA-reviewed for architectural coherence** before merge. `ai-engineer` runs shape + load-topology passes across the whole doc set (was SA ↔ ai-engineer pre-D25; now all-roles ↔ ai-engineer).

## Classical-architect SA model (D25)

Three activities across the lifecycle:

| Activity | When | Output |
|---|---|---|
| **Design** | Phase 1 elicit + Phase 2 target architecture | `local/requirements.md` (FRs/NFRs/Constraints) · `local/asr-utility-tree.md` (ASRs derived via ATAM) · architecture doc · ADRs · diagrams |
| **Review** | Any phase, on engineer-proposed architectural changes | APPROVE / REJECT / REQUEST-CHANGES verdict + rationale citing ADR / FR / NFR / ASR. No code edits. |
| **Governance** | Continuous, **scoped only to PRs touching SA-owned files** | Drift-flag in PR comment + dispatch back to owning engineer. Not every Phase 4/5/6 PR — keeps SA out of the bottleneck. |

**Greenfield vs delta** — resolved at Phase 1. Greenfield (no architecture doc) → SA authors a complete architecture doc + initial ADRs. Delta (existing doc) → SA produces ADR/CR proposals + ASR amendments; never rewrites the doc wholesale.

**Two-file register split** (ASRs are the outcome of requirements, not the same level):

- `local/requirements.md` — FRs / NFRs / Constraints (inputs).
- `local/asr-utility-tree.md` — Architecturally Significant Requirements derived from NFRs + Constraints via ATAM utility tree (outcomes).

**Architect-to-architect** — single-architect framework default. Multi-architect projects populate optional `local/bindings.md § Architects` slot.

**Engineer-proposed architectural changes** — when a fix / feature implies an architectural delta, the engineer drafts a proposal in their final report and routes to SA per § Review. Local bug fixes route engineer → engineer; no SA dispatch.

Full spec: [`core/roles/solution-architect.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/roles/solution-architect.md). Migration: [`migrations/classical-architect.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/classical-architect.md).

## Change governance gating + opt-out (D45)

Pre-D45, CR / ADR authorship was unconditional once team-lead / SA judged the trigger condition met. Adopters whose source-of-truth for requirement scope is GitHub issues (issue body = the requirement record) had no way to suppress redundant CR drafting; adopters making code changes with no architectural delta had no way to suppress redundant ADR drafting. D45 adds a pre-authorship intercept gate on both surfaces.

**Five-key gate** (`local/framework.config.yaml § change-governance`):

```yaml
change-governance:
  cr:
    enabled: true                       # set false → skip CR authorship
    skip-when-issue-source: true        # issue-sourced task → issue IS the requirement record
  adr:
    enabled: true                       # set false → skip ADR authorship
    require-architectural-delta: true   # no delta heuristic → skip ADR
  prompt-before-create: non-trivial     # always | never | non-trivial
```

**Architectural-delta heuristic** — ADR gate fires when the proposal touches ≥ 1 of: component boundaries · wire contracts · NFR-bearing claims · architecture invariants · stack / topology / infrastructure. SA judgment retained for borderline cases (refactor implying invariant shift · wire-shape breaking-vs-additive · NFR-adjacent threshold).

**Non-trivial heuristic** (drives `prompt-before-create: non-trivial`) — ≥ 2 architectural-delta triggers OR `local/requirements.md` register-diff non-empty.

**Per-task prefixes** override config at dispatch time (precedence: prefix > config > default):

| Prefix | Effect |
|---|---|
| `cr:` | Force CR authorship |
| `nocr:` | Skip CR authorship |
| `adr:` | Force ADR authorship |
| `noadr:` | Skip ADR authorship |

Combine freely with `auto:` · `branch:` / `wt:` / `commit:` · `model:<tier>` · `notrack:`. Example — `auto: branch: nocr: bump retry policy` (auto-mode, Mode 1, skip CR).

**Skip-reason logging** — when the gate skips, `## Decisions made` carries one row (`CR skipped — skip-reason: <enum>` / `ADR skipped — skip-reason: <enum>`). Fixed enum — `config-disabled` · `issue-source-skip` (CR only) · `no-architectural-delta` (ADR only) · `prefix-override` · `user-declined`.

**Adopter benefit — issue-as-CR.** Pre-D45 `team-lead` drafted a CR for every issue-sourced scope change, even when the issue body already recorded the change. Post-D45, `cr.skip-when-issue-source: true` (new default per issue #121) suppresses the redundant CR; the issue body remains the requirement record; PR `Closes #<N>` preserves traceability.

**Auto-mode interaction** — `prompt-before-create: always` OR `non-trivial` heuristic firing under auto-mode forces interactive pause per `core/protocols/automatic-mode.md § Forced-interactive triggers`. The gate is never silently elided.

Full spec: [`core/roles/team-lead.md § CR-gate`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/roles/team-lead.md) · [`core/roles/solution-architect.md § ADR-gate`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/roles/solution-architect.md) · [`core/process.md § Change governance`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/process.md). Migration: [`migrations/change-governance-opt-out.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/change-governance-opt-out.md).

## Index protocol

`local/index/` holds lightweight per-class summaries of the project's knowledge:

| Category | Examples |
|---|---|
| Documentation | `architecture.idx`, `architecture-fr.idx`, `api-matrix.yaml`, `ui-states.yaml`, `constraints.yaml`, `adr-index.idx`, `cr-index.idx`, `scenario-index.idx`, `glossary.idx`, `mockup-index.idx` |
| Code / config | `stack.yaml`, `topology.yaml`, `commands.yaml`, `conventions.yaml`, `runtime-facts.yaml`, `repo-map.idx` |

**Key invariants:**

- **Coverage rule** — every named record (FR / NFR / endpoint / state / ADR / dep / service / port / command / env-var / dir) has an existence-entry in the index.
- **Compression floor** — `index-bytes / source-bytes ≥ 0.5 = recipe failed`. Either drop bulk or mark `template: read-source-directly`.
- **Consumer coupling** — every extracted class declares `consumed-by: [<role>...]` in `manifest.yaml`. Novel classes without a consumer aren't extracted.
- **Per-file load triggers** — role kernel `Source of truth` tables carry a `Load when` column. `always` for foundational reads; trigger phrase for scope-loaded files. Specialist reports the loaded set in its first response.
- **SHA-256 staleness** — `team-lead` checks drift pre-dispatch; offers `@ai-engineer reindex <source>` or `@team-lead rediscover` on mismatch. Never auto-reindexes.

Full spec: [`core/protocols/index-protocol.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/index-protocol.md).

## Hot-spec frontmatter (D47)

Every hot-spec file in `core/` (the files cardinals load at dispatch time) carries a YAML frontmatter block at the top declaring its load contract:

```yaml
---
audience: <role | all-cardinals | team-lead-only>
load: always | on-demand
triggers: [keyword1, keyword2]                # required when load == on-demand
cap-bytes: <N>                                # explicit per-file byte budget
reads-before-applying: [path1, path2]         # explicit content-dependency chain; [] if none
---
```

**Scope.** `core/process.md` · `core/process/*.md` · `core/protocols/*.md` · `core/roles/*.md` · `core/roles/*.details.md`.

**Excluded.** `core/templates/*.md` (concrete output shapes) · `core/skills/ginee-*/SKILL.md` (already use AgentSkills frontmatter) · `local/roles/*.md` (adopter-owned per D37).

**Adopter impact.** None — `/ginee-update` lands the frontmatter wholesale. Adopters writing custom roles under `local/roles/` MAY adopt the same format but are not required to.

**Why.** Eliminates the per-dispatch inference cost — cardinals know from the file's head whether to load it, when its rules apply, and which other specs to consult first. Compounds across every adopter dispatch.

**Validator.** `scripts/context-economy-check.ps1` fails CI on missing frontmatter; same `Optimized-By: ai-engineer` trailer-bypass machinery as the existing context-economy gate (D21) + per-class doc-size caps (D44).

Full spec: [`core/protocols/hot-spec-format.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/hot-spec-format.md). Migration: [`migrations/hot-spec-frontmatter.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/hot-spec-frontmatter.md).

## Delivery modes

PM resolves one of three delivery modes per task — picked by precedence:

1. Per-task prefix: `branch:` / `wt:` / `commit:` at start of task description.
2. Per-task Phase-3 user answer.
3. Adopter default in `local/framework.config.yaml § delivery.default-mode`.
4. Framework default — `branch` for issue / TODO-sourced tasks; `wt` for freeform.

| Mode | Phase 4 commits | Phase 8 finalize |
|---|---|---|
| **1. Branch + PR** | `gh issue develop` (issue-sourced) or `git checkout -b`; commits on branch | `git push -u origin`; `gh pr create` with `Closes #<N>` |
| **2. Working-tree only** | No commits | PM surfaces `git diff`; user commits / discards manually |
| **3. Commit-no-push** | Commits on current branch | PM surfaces `git log --oneline`; user pushes manually |

Combinable with `auto:` — `auto: branch: fix the deploy logs spam` is valid.

Full spec: [`core/protocols/delivery-modes.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/delivery-modes.md).

## GitHub issues + discussions as a task source

ginee picks up GitHub issues with the same Phase 1–8 lifecycle as TODO lines and freeform requests:

- **File** via `/ginee-file-bug <title>` / `/ginee-file-feature <title>`. team-lead uses structured templates under `core/templates/issues/`, opens a labelled issue with `ginee:ready`.
- **Pick up** via `/ginee-pick-up #<N>`. team-lead swaps labels `:ready` → `:in-progress`, runs Phase 1–8, posts structured progress comments at transitions.
- **Triage** via `/ginee-triage` — lists ready issues + TODOs ranked by **score = value / complexity** per [§ Triage scoring](#triage-scoring-d23).
- **Promote** via `/ginee-promote-discussion #<N>` — surfaces a draft issue from a discussion thread.
- **Address review** via `/ginee-address-review #<PR>` — see [§ Review-comment ingestion](#review-comment-ingestion-d24).

Slash commands work on tier-1 clients (Claude Code, Copilot CLI). Natural-language phrasings (`File a bug titled X`, `Pick up #42`, `Triage`) also match the skill description. Tier-2/3 fallback uses `act as team-lead and ...`.

PRs reference the issue with `Fixes #<N>` / `Closes #<N>` — GitHub auto-closes on merge.

Full spec: [`core/protocols/github-integration.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/github-integration.md).

## Sub-issue dispatch — cross-session traceability + time-tracking (D39)

Pre-D39, every team-lead → cardinal dispatch lived only in the chat transcript — end the session, lose the state. D39 lands each cardinal dispatch as a GitHub **sub-issue** under the parent task issue. Cross-session resume now reads parent + open sub-issues; no transcript replay.

| Concern | Pre-D39 | After D39 |
|---|---|---|
| Cross-session resume | Replay transcript + grep commits | Read parent + open sub-issues |
| Mid-dispatch hand-off | One-shot hand-off note | Live sub-issue thread |
| Parallel-cardinal traceability | Buried in synthesis turn | One sub-issue per role, queryable |
| Effort attribution | Not surfaced anywhere | Per-comment `time:` + per-cardinal rollup |

**Scope.** Issue-sourced tasks only. TODO / freeform fall back to in-context dispatch (no parent issue to anchor sub-issues under).

**Lifecycle per dispatch.**

1. team-lead drafts the dispatch contract (scope · acceptance · spec links · phase · estimate).
2. Creates a sub-issue under the parent — title `[<phase>:<cardinal>] <task>`; body = contract per `core/templates/sub-issue-dispatch.md`; labels `ginee:role:<cardinal>` + `ginee:phase:<N>` + inherited `value:*` / `complexity:*`.
3. Cardinal executes; progress comments thread on the sub-issue — each carrying `time: <N>m` (since last comment) + `cumulative: <N>m` (since dispatch start).
4. D29 phase-report return doubles as the closing comment with mandatory `## Time spent` section. team-lead closes the sub-issue.
5. Parent's `<!-- ginee:dispatch-map -->` sticky aggregates per-cardinal time across all sub-issues.

**Stop-state.** `Status: In-progress` posts as a progress comment; sub-issue stays open. Next pickup reads the comment trail and resumes from where the cardinal stopped.

**Assignee precedence.** Non-empty human assignee on a sub-issue overrules the `ginee:role:<cardinal>` tag — cardinal dispatch suspended until the assignee clears. Rationale — GitHub's assignee column means a human is responsible; cardinals are not GitHub users; when both exist, the human wins.

**Opt-out (stop at first match).**

1. Per-task `notrack:` prefix (combinable with `auto:` / `branch:` / etc.).
2. `ginee:track:off` label on the parent issue (per-issue lifetime).
3. `local/framework.config.yaml § dispatch.tracking: in-context` (repo-wide).
4. Framework default — `sub-issues` when `github.repo` is configured.

**Time-tracking.** Cardinal-reported perceived effort (not session wall-clock). Granularity — minutes. Format `time: <N>m` (under 60m) or `time: <H>h <M>m` (60m+).

Full spec: [`migrations/sub-issue-dispatch.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/sub-issue-dispatch.md).

## Triage scoring (D23)

`/ginee-triage` ranks ready work by **score = value / complexity** (default WSJF cost-of-delay over job-size) instead of age. Two axes, same scale — ATAM utility-tree H/M/L (`H=3, M=2, L=1`).

| Axis | Source-of-truth | Set by |
|---|---|---|
| `value` | label `value:high|medium|low` | **Reporter** (never auto-guessed) |
| `complexity` | label `complexity:high|medium|low` | Reporter, OR `solution-architect` auto-estimate on pickup (ATAM signals: touched-file count, role count, novel concepts, pattern reuse) |

9-cell matrix (rounded): `HL = 3.00` quick-win at the top; `HH = MM = LL = 1.00`; `LH = 0.33` at the bottom. Adopter override: `local/framework.config.yaml § triage.scoring-formula` accepts `value-over-complexity` (default) / `value-only` / `value-minus-complexity`.

**TODO equivalent** — inline marker after the glyph (case-insensitive):

```
☐ [v:H c:L] Bump retry policy             # quick-win, scores 3.00
☐ [v:H] Investigate flaky pipeline        # complexity unknown — imputed L
☐ Refactor logger                          # unscored — sorts last
```

**Sticky comment** — `<!-- ginee:score v=1 -->`, one per issue, updated in place on ginee-driven label changes. Hybrid topology: live sticky state + immutable audit comments (`ginee:complexity-estimate` / `ginee:value-prompt` / `ginee:score-recompute`).

**Manual override** — `@team-lead recompute score #<N>` re-reads current labels (catches manual `gh issue edit` between sessions) and refreshes the sticky.

Pickup is **never** gated on score — score informs order, not eligibility. Full spec: [`core/protocols/triage-scoring.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/triage-scoring.md).

## Review-comment ingestion (D24)

`/ginee-address-review #<PR>` (or `@team-lead address-review #<PR>`) covers the interval **between Phase 7 (internal SA review) and Phase 8 (user accept)** when a PR is exposed to external review (peer maintainers, OSS contributors, user-as-reviewer). Skill + command parity — both run the same procedure under the same governance.

| Step | Action |
|---|---|
| 1 | Resolve `<PR>`; verify checked-out branch == PR head; fetch `pulls/{N}/comments` + `/reviews` |
| 2 | Deduplicate by `thread-id`; skip resolved + already-marked threads (unless newer reviewer comment landed) |
| 3 | Build routing records per `local/bindings.md § Source-of-truth ownership`; fallback `team-lead`; ambiguous → surface-closest role |
| 4 | Surface consolidated plan table — `# / thread / file:line / role / proposed action / action-type` |
| 5 | Dispatch specialists in parallel; each returns **fix-track** patch OR **reply-track** text + marker |
| 6 | Squash fix patches into one cycle commit + push; post per-thread replies |
| 7 | Post one sticky cycle summary — `Review cycle N: M remarks addressed (K code, M-K reply). HEAD: <sha>.` |

**Forced-interactive gate** — plan-table approval is non-bypassable; applies even in `auto:` mode per [`core/protocols/automatic-mode.md § Forced-interactive triggers`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/automatic-mode.md). No exception for "trivial" remarks.

**Lossless coverage** — every plan-table thread MUST end the cycle as `fix` OR `reply`. No silent drops.

**Idempotency** — markers `<!-- ginee:review-reply r=<thread-id> -->` (per-thread) + `<!-- ginee:review-cycle n=<N> -->` (sticky). Re-invocation covers net-new + revisited threads only; cycle ordinal increments; prior stickies preserved (immutable log).

**Explicit invocation only** — no extension of the D20 CI-watch loop; auto-detection of new review comments is out-of-scope.

Full spec: [`core/protocols/github-integration.md § Review-comment ingestion`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/github-integration.md#review-comment-ingestion).

## Doc-authoring protocol (D22 + D26)

When ginee authors markdown — adopter docs (D22) OR ginee-authored GitHub artefacts (D26) — `core/process.md § Documentation style — structure over prose` is binding, not aspirational. Six mandatory checks (D48 added RFC 2119 binding-strength signal — MUST · MUST NOT · SHOULD · SHOULD NOT · MAY — instead of `always` / `never` / `binding` / `mandatory` / `required` as rule modifiers); structure-default-by-class shape map.

**Scope:**

| Surface | Authored by | In scope since |
|---|---|---|
| Architecture doc · ADRs · CRs · READMEs · runbooks · scenarios · API docs | adopter roles | D22 |
| **GitHub issue bodies** authored via `ginee-file-*` skills | `team-lead` (you approve) | D26 |
| **Framework-authored GitHub comments** — Phase-transition · sticky `ginee:score` / `ginee:review-cycle` · audit comments · per-thread review-replies | `team-lead` + specialists | D26 |

**Default-shape map:**

| Doc class | Default shape |
|---|---|
| Component / endpoint / service inventory | Table |
| Step-by-step procedure / runbook | Numbered list |
| ADR rationale (decision + context + consequences) | Definition lines + bullets |
| Scenario / acceptance criteria | Given-When-Then bullets |
| Glossary / API matrix | Table |
| Rules with > 2 conditions | Parent bullet + sub-bullets — one rule per line |

**Lint covers every section, including Summary** (D26) — no section-by-length exemption. A one-sentence Summary still trips the mandatory checks if it packs a comma-separated inventory into a parenthetical clause.

**Enforcement — two paths:**

- **Adopter docs (D22)** — piggybacks on your discovered markdown / prose tooling (`markdownlint` / `vale` / `proselint` / `prettier-md`); roles run `${commands.lint.docs}` at Phase 5 / report-as-done.
- **ginee-authored issue bodies + comments (D26)** — LLM self-review embedded in the skills + comment-cadence procedures; no external linter; violations surface as restructure suggestions in the user-approval prompt.

**Reporter-authored content (your own issues, your own comments)** — never auto-edited; D14 forbidden upheld. `ginee-pick-up` MAY surface a polite restructure advisory but never rewrites your text.

**Scope (out-of-scope):**

- Legacy adopter docs (forward-only).
- Reporter-authored issue bodies / comments (D14 forbidden).
- Discussion bodies (read-only context per D14).
- Style / tone / branding (protocol governs **structure** only).

Full spec: [`core/protocols/doc-authoring-protocol.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/doc-authoring-protocol.md). Examples (9 bad/good pairs): [`core/protocols/doc-authoring-examples.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/doc-authoring-examples.md).

## Changelog + release-notes protocol (D40)

Extends the doc-authoring scope to the three release-surface files. Closes a recurring drift mode — pre-D40, release-notes sidecars repeatedly drifted into framework-dev voice + oversized bullets, requiring multi-pass rewrites after publish (the v0.12.0 sidecar took four passes to converge).

**Three surfaces, three voices, three caps:**

| Surface | Purpose | Voice | Bullet cap |
|---|---|---|---|
| `migrations/D<N>-*.md` | Full spec — schema · checks · rollback · file list | Framework-dev (precise jargon OK) | None — structured tables / lists |
| `docs/CHANGELOG.md` | Verbose record per Keep-a-Changelog | Framework-dev OK in sub-bullets; lead-in ≤ 25 words | Lead-in ≤ 25 words + sub-bullets |
| `.github/release-notes/v*.md` | Marketing on the GH Release page | **User-value voice** — adopter-visible benefit at line start | **≤ 20 words per bullet** + `(D<N>)` tag |

**Voice rule — sidecar.** Lead with the adopter-visible verb / outcome — *"`/ginee-update` works again"* not *"Step 1 no longer requires installer scripts inside `.agents/ginee/`"*; *"Lower LLM bills"* not *"Three vendor-neutral tiers declared as role-kernel `default-tier:`"*.

**5 mandatory checks** before publishing a sidecar — per-bullet word cap · user-value voice · `(D<N>)` tag suffix · no implementation boilerplate (file-update lists / "purely additive" stat blocks belong in the migration) · migration link in footer.

**Enforcement** — LLM self-review at draft time; one-line orchestrator advisory on violation; never auto-rewrites. Same machinery as D22 / D26 / D29 / D30.

**D34 carve-out** — sidecar D-tags stay bare (`(D31)`) rather than slug-glued (`D31-model-tier`); the slug form is required only in framework specs · adopter docs · cardinal returns. Sidecars carry the spec link in the footer.

**Scope (out-of-scope)** — retroactive rewrite of pre-D40 sidecars (forward-only); external markdown linter / CI gate (self-lint only); translation / localization; style / tone / branding beyond voice.

Adopter impact — **none** (framework-internal authoring rule; affects ginee maintainers writing release artefacts, not adopters).

Full spec: [`core/protocols/changelog-protocol.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/changelog-protocol.md) + [`migrations/changelog-protocol.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/changelog-protocol.md).

## Blueprint-diff gate for visual source-of-truth (D41)

Phase 4 entry precondition for any dispatch touching the configured visual source-of-truth artefact (mockup · Figma · image baseline · video · adopter-supplied). Closes the adopter-incident class where Phase 4 silently rewrote chrome elements while Phase 5/6 geometry oracles ran green.

**Procedure** — dispatching role runs the protocol as first step of any Phase 4 dispatch that touches the configured `visual-source-of-truth.path`:

1. Resolve config from `local/framework.config.yaml § visual-source-of-truth` (defaults derive from existing `mockup:` key when absent).
2. Compute the diff working-copy vs `blueprint-ref` (default `origin/main`) — per-type tool selection.
3. Classify each delta as Expected (inside issue scope) · Unexpected (outside issue scope) · Pre-existing (present before dispatch).
4. Surface to team-lead.
5. Gate Phase 4 edits — all-Expected/Pre-existing → edits proceed; any Unexpected → forced-interactive gate (auto-mode does NOT elide).

**Per-type diff tools:**

| `type` | Tool |
|---|---|
| `html-mockup` | `git diff <blueprint-ref> -- <path>` (built-in; universal) |
| `figma` | File-comparison URL or REST `GET /v1/files/<key>/versions` |
| `image` | Adopter-supplied perceptual diff — pixelmatch · odiff · Resemble.js · Playwright snapshot-compare |
| `video` | Manual review checkpoint |
| `other` | Adopter-supplied tool from `local/index/commands.yaml § commands.visual-diff` |

**4 mandatory checks** before edits begin — config resolved · diff computed · classification complete · surface logged in `## Verification log`. LLM self-review at draft time; one-line orchestrator advisory on violation; never auto-rewrites.

**Adopter impact** — adopters with `mockup:` configured get the gate on next dispatch with zero `local/framework.config.yaml` edits (defaults derived). Adopters with no mockup configured — protocol auto-skips. Override the defaults to point at a Figma URL · release-tag blueprint · frozen snapshot · adopter-supplied diff tool.

Full spec: [`core/protocols/blueprint-diff-protocol.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/blueprint-diff-protocol.md) + [`migrations/blueprint-diff-gate.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/blueprint-diff-gate.md).

## Subagent-return schema (D29)

Every cardinal-dispatch return is **schema-bound** per `core/templates/phase-report.md` — same machinery as the D22 / D26 doc-authoring protocol, scoped to the subagent-return surface. Goal: cut ~70% off subagent-return bloat (today's largest orchestration-thread contributor).

**Mandatory sections** (empty case: `(none)`):

| Section | Cardinality | Default shape |
|---|---|---|
| `## Files touched` | required | Table — `path` · `Δ lines` · `purpose` |
| `## Decisions made` | required | Bullets — `<imperative> — cite` (≤ 80 chars / bullet) |
| `## Verification log` | required | Table — `command` · `outcome` |
| `## Open issues` | required | Bullets — `<issue> — <owner>` |
| `## Next dispatch needed` | required | One-liner — `<role> · <surface> · <reason>` |
| `## Source reads (this dispatch)` | required (else `(none)`) | Table — `Path` · `Justification` · `Index entry consulted` |
| `## Hand-off` | conditional — forced handoff per `core/protocols/cross-agent-handoff.md` | `core/templates/hand-off-note.md` shape |
| `## Stop-state` | conditional — `Status: In-progress` | Done / In-progress / Not-started bullets |
| `## Notes` | **optional** — narrative escape hatch | Free prose · ≤ 200 words · ≤ 5-line code-snippet carve-out |

**7 mandatory checks before report-as-done** — 6 from D22 / D26 / D48 + *no narrative preamble* (first non-Status line must be a `##` section header). `## Source reads` joins as required-with-empty-case (matching `## Hand-off` / `## Stop-state` precedent) — count adjusted to reflect D48's RFC 2119 binding-strength check.

**Forbidden patterns** — narrative preamble · restated dispatch context · code snippets outside the Notes carve-out · verbose rationale outside `## Notes` · parenthetical comma-soup.

**Enforcement.** LLM self-review against the schema before returning. No external linter. Orchestrator surfaces a one-line advisory on violations and consumes anyway. **Single carve-out** — when raw source paths appear in `## Files touched` AND `## Source reads (this dispatch)` is missing or `(none)`, orchestrator re-dispatches for the justification cycle. Never auto-rewrites (analogous to D14 reporter-content forbidden).

**Index-first read order.** Cardinals consult `local/index/` summaries + role-kernel `Source of truth § always` rows before any raw source read; raw reads are fallback when an index entry's anchor points at a fragment needed verbatim OR the role authors new content in that source. Every raw read records a one-line justification in `## Source reads (this dispatch)`. Full bedrock rule: [`core/protocols/index-protocol.md § Read order`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/index-protocol.md).

Full schema: [`core/templates/phase-report.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/templates/phase-report.md). Bad/good example: [`core/protocols/doc-authoring-examples.md § 10`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/doc-authoring-examples.md). Migration: [`migrations/strict-subagent-return-schema.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/strict-subagent-return-schema.md).

**Output-schema sidecars (D49).** Five other high-frequency structured outputs the framework produces — dispatch prompts · sticky `ginee:score` · audit comments · sub-issue bodies + cadence · review-cycle replies + sticky — each get a sidecar under `core/protocols/` following the phase-report meta-template. See [`dispatch-prompt-schema.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/dispatch-prompt-schema.md) · [`score-comment-schema.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/score-comment-schema.md) · [`audit-comment-schema.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/audit-comment-schema.md) · [`sub-issue-dispatch-schema.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/sub-issue-dispatch-schema.md) · [`review-cycle-schema.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/review-cycle-schema.md).

## Adopt-vs-build option lists (D30)

Every Phase 2 design proposal **and** every iteration-protocol Propose step (Phase 4–7 sub-tasks > 15 min where adopt-vs-build is a live axis) MUST surface ≥ 1 adopt-existing-solution candidate **or** an explicit `(none viable — <reason>)` cite. Stops the LLM-default failure mode: authoring novel implementations when no rule binds the proposer to look outward first.

**Option-list schema** (4 candidate types):

| Candidate type | Required fields |
|---|---|
| `adopt` | name · version · source link · license · one-line fit rationale |
| `build` | scope · one-line rationale why adoption was rejected |
| `hybrid` | adopt portion (full citation) + build portion + boundary rationale |
| `(none viable — <reason>)` | one-line reason — empty-research escape hatch |

**Floor.** Hard: ≥ 1 `adopt` candidate OR `(none viable)`. Soft: encourage 2–3 adopt candidates for non-trivial scope.

**5 mandatory checks before surfacing** — adopt floor present · citations complete · tagging explicit (`adopt` / `build` / `hybrid` — no silent mixing) · empty research documented · fit rationale concrete (not hand-waved).

**License + supply-chain stance.** Framework requires the citation but expresses no opinion on which licenses pass. Adopters author a `local/` policy file if gating is wanted.

**Enforcement.** LLM self-review before surfacing the proposal. No external linter. Orchestrator surfaces a one-line advisory on violations but never auto-rewrites (analogous to D29).

Full spec: [`core/protocols/options-protocol.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/options-protocol.md). Bad/good example: [`core/protocols/doc-authoring-examples.md § 11`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/doc-authoring-examples.md). Migration: [`migrations/adopt-existing-solution.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/adopt-existing-solution.md).

## Per-role + per-task model tier (D31)

Routes reasoning-heavy roles to capable models and execution-heavy roles to cheaper ones. Tier names are vendor-neutral in `core/`; concrete model IDs live only in the adapter layer.

| Tier | Use | Default model (Claude adapter) | Default for |
|---|---|---|---|
| `reasoning` | Orchestration · synthesis · architectural calls | `claude-opus-4-7` | `team-lead` · `solution-architect` |
| `standard` | Implementation · tests · doc-shape · lint fixes | `claude-sonnet-4-6` | `ai-engineer` · `backend-engineer` · `frontend-engineer` · `devops-engineer` · `qa-engineer` |
| `fast` | Mechanical · label ops · sticky updates | `claude-haiku-4-5-20251001` | (opt-in for adopter-defined mechanical work) |

**Resolution order** — stop at first match: (1) per-task prefix `model:<tier>` in the dispatch line (combinable with `auto:` / `branch:` / `wt:` / `commit:`); (2) Phase-3 user answer; (3) `local/framework.config.yaml § model-tier.per-role.<role>`; (4) `core/roles/<role>.md` frontmatter `default-tier:`.

**Adapter behaviour.** The Claude adapter writes `model: <id>` into each `.claude/agents/<role>.md` frontmatter from the resolved tier (pre-resolved default at install; rewritten when `local/framework.config.yaml § model-tier` carries overrides). Cursor / Copilot CLI / Codex / generic emit a one-line install warning — those surfaces don't expose programmatic per-role model selection today; the per-task prefix is a documented user-side hint.

**Backward compatibility.** Purely additive. Absent `model-tier:` → framework defaults apply silently. Existing dispatches unaffected until adopter sets a tier or uses the prefix.

Full spec: [`migrations/model-tier.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/model-tier.md).

## Skill-runner vs team-lead (D28)

ginee skills (`/ginee-pick-up`, `/ginee-address-review`, `/ginee-triage`, `/ginee-promote-discussion`, ...) run inside a thin **skill-runner** — the Claude main thread, Cursor main loop, Copilot CLI main loop, or AGENTS.md-driven shell that executes the skill body. The skill-runner is **not** a role and **not** an orchestrator.

| Skill-runner does | Skill-runner does **not** |
|---|---|
| Parse prompt + identify task source | Draft a Phase 1–8 dispatch plan |
| Label / sticky / audit-comment ops | Synthesize parallel specialist returns |
| Branch ops per resolved delivery mode | Author lifecycle gate text (Phase 3 / 7 / 8) |
| The skill's **one named first-batch dispatch** | Re-dispatch specialists after the first batch |
| Report mechanical result to the user | Reconcile routing on engineer pushback |
| | Pick defaults ("I'll pick option 1 if you don't redirect") |
| | Read `local/bindings.md` to settle a routing question |

**Hand-back rule.** Every `ginee-*` skill dispatches `@team-lead` after its first mechanical batch. From there every orchestration decision flows through team-lead. If a routing or governance question arises mid-flight, the skill-runner dispatches `@team-lead` to answer — it never answers by reading project files itself.

**Why the rule.** Pre-D28 the skill-runner often drifted into orchestration on long sessions (issue #71): plan drafting in the main thread, synthesizing parallel returns, proposing default-selection options. The boundary is now structural — every skill carries an explicit hand-back step.

Full spec: [`core/process.md § Skill-runner — surface boundary`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/process.md#skill-runner--surface-boundary-d28). Migration: [`migrations/skill-runner-boundary.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/skill-runner-boundary.md).

## Framework self-update

`/ginee-update [<tag|branch|sha>]` drives the `install.{ps1,sh} --update-only` flow under explicit user approval — never auto-runs. **The installer lives at upstream, not inside `.agents/ginee/`** (per D27); the skill fetches `install.{ps1,sh}` from `raw.githubusercontent.com/<github.framework-repo>/<target-ref>/` to a temp dir, then runs it with the detected adapter + project root. team-lead resolves the target ref (latest release / explicit tag / branch / SHA), surfaces the update plan (current `core/VERSION` → target ref + installer command + preserved/replaced trees), waits for `yes`, then runs the installer per platform. Post-update report: VERSION delta + CHANGELOG range + new `migrations/*.md` files with `Action required` excerpts + `local/index/manifest.yaml` SHA drift offer.

Full spec: [`core/skills/ginee-update/SKILL.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/skills/ginee-update/SKILL.md).

## What ginee doesn't do

- **Auto-update.** The installer is invoked explicitly; never runs unattended.
- **Per-domain templates.** No architecture / API / mockup contracts. Adopters bring their own; ginee ships process only.
- **Multi-repo coordination.** One project at a time.
- **MCP server.** Deferred to v2.0.

## Next

- [**Reference**]({{ '/reference/' | relative_url }}) — canonical specs for each concept above.
- [**Cheatsheet**]({{ '/CHEATSHEET.html' | relative_url }}) — one-page reference of every command + label + phase you'll touch.
