# ginee — Project Instructions

## What this project is

`ginee` is an **AI software engineering team that behaves like a real one** — drops into your project, self-onboards, and gets to work. A vendor-neutral OSS framework that packages a **7-cardinal multi-agent collaboration model** + a **generic engineering process** for any LLM coding tool (Claude Code, GitHub Copilot, Cursor, Codex, or fallback generic).

- **Ships process knowledge only** — no domain, stack, architecture, or SDLC opinions.
- **Project-specific knowledge** is discovered on first run by `team-lead` and lives in `local/` (survives upstream updates).
- **Project knowledge sources** (markdown docs, diagrams, mockups) are *referenced*, never copied — doc changes propagate instantly.

This is the **framework's own development repo**, not an adopter project.

## Source of truth (read before any work)

| File / location | Role |
|---|---|
| `PLAN.md` | Design document + 17 locked decisions (D1–D17) + phased roadmap + verification |
| `core/process.md` | Vendor-neutral process spec (lifecycle, dispatch rules, iteration protocol, doc co-ownership) |
| `core/roles/*.md` | 7 cardinal role definitions |
| `core/templates/*.md` | Standardized templates (phase-report, hand-off-note, etc.) |
| `adapters/<client>/` | Per-client renderings of `core/` |
| `extras/roles/*.md` | Specialist roles library (security / ml / mobile / sre / data) — opt-in for adopters |
| `local/` | Per-project bindings filled by adopters (this repo's own `local/` is empty — we ARE the framework) |

## Process model — dogfooded

This project follows the process it defines. Before any non-trivial work, read `core/process.md`. Key sections:

- Dispatch & parallelism rules
- Task lifecycle (Phases 1–8)
- Iteration protocol — propose → review → implement
- Timeframe-bounded autonomous work
- Stoppable intermediate states
- Doc co-ownership (`solution-architect` ↔ `ai-engineer`)
- Task model (root TODO / nested TODO / direct instruction)
- Post-acceptance doc optimization hook

## Repository structure

```
ginee/
├── core/                       # vendor-neutral spec — IMMUTABLE for adopters; we author here
│   ├── VERSION                 # SemVer (currently 0.1.0)
│   ├── process.md              # 33K — phased lifecycle + coordination + principles
│   ├── roles/                  # 7 cardinal role definitions
│   │   ├── team-lead.md        # orchestrator + discovery flow (alias: project-manager)
│   │   ├── ai-engineer.md      # context economy, doc shape, file splitting
│   │   ├── solution-architect.md  # SAD freeze + CR/ADR governance
│   │   ├── frontend-engineer.md   # alias: client-engineer
│   │   ├── backend-engineer.md    # alias: service-engineer
│   │   ├── devops-engineer.md     # alias: platform-engineer
│   │   └── qa-engineer.md         # alias: quality-engineer
│   ├── templates/              # 8 templates (phase-report, hand-off-note, discovery-report,
│   │                           #              pr-description, bindings, framework.config.yaml,
│   │                           #              project-profile, role-authoring-template)
│   └── MIGRATIONS/             # version-to-version migration notes (empty until first breaking)
│
├── adapters/                   # per-client renderings of core/
│   ├── claude/                 # Claude Code subagents + CLAUDE-pointer.md
│   ├── copilot/                # single .github/copilot-instructions.md
│   ├── cursor/                 # per-role .cursor/rules/*.mdc
│   ├── codex/                  # AGENTS.md or equivalent
│   └── generic/                # fallback INSTRUCTIONS.md
│
├── extras/                     # specialist roles library — opt-in for adopters
│   └── roles/                  # security / ml / mobile / sre / data (Mega-3 deliverable)
│
├── local/                      # per-project bindings — empty for framework repo itself
│   └── roles/                  # adopter-authored custom roles
│
└── CLAUDE.md                   # this file
```

## Locked decisions (D1–D29)

Canonical in the plan file. Summary:

| # | Decision |
|---|---|
| D1 | Hybrid shape — vendor-neutral core + per-client adapters (+ optional MCP in v2.0) |
| D2 | MCP server deferred to v2.0 |
| D3 | All four gap clusters addressed: client-agnosticism, self-learning, generic-vs-project split, update-safety |
| D4 | Copy-paste distribution MUST be supported (+ tarball + curl-install + npx as fast-followers) |
| D5 | **7 cardinal roles** (5 engineering + team-lead + ai-engineer; revised 6 → 7 on 2026-05-16; orchestrator renamed `project-manager` → `team-lead` on 2026-05-18, `project-manager` retained as alias) — extensible via `local/roles/` + `extras/roles/` library |
| D6 | Discovery refresh: both manual `rediscover` + auto-flag staleness |
| D7 | Coexistence with existing instruction files: adopt (additive, pointer-line only) |
| D8 | Install directory: `.agents/ginee/` (amended 2026-05-17 from a root-level dir; revised 2026-05-18 from `.agents/engineering-team/` per D11 rebrand — `.agents/` namespace for agent tooling; survives root clutter) |
| D9 | Role names: hybrid — current names canonical + generic aliases (`client-engineer`, `service-engineer`, `platform-engineer`, `quality-engineer`) |
| D10 | Custom-role extension: both pre-built library + free-form authoring under `local/roles/` |
| D11 | Public framework name: **`ginee`** (revised 2026-05-18 from `engineering-team`). Tagline: *An AI software engineering team that behaves like a real one. Drops into your project, self-onboards, and gets to work.* Skill prefix `ginee-` consistent at every surface (formerly codename, now formal name). |
| D12 | **Automatic mode** (2026-05-17). <ul><li>Per-task opt-in via `auto:` prefix.</li><li>Elides intermediate gates.</li><li>Phase 8 → Accept/Feedback/Reject delivery handoff.</li><li>Never commits silently.</li><li>Spec: `core/automatic-mode.md`.</li></ul> |
| D13 | **Project-doc index** in `local/index/` (2026-05-17). <ul><li>Heavy adopter docs → lightweight summaries.</li><li>SHA-256 staleness in `manifest.yaml`.</li><li>Roles read index first; originals on demand.</li><li>`ai-engineer` extracts (built-in + novel-class recipes).</li><li>`team-lead` flags drift pre-dispatch.</li><li>Spec: `core/index-protocol.md`.</li></ul> |
| D14 | **GitHub issues + discussions** as 4th task source (2026-05-17). <ul><li>PM ops: file / pick up / triage / promote.</li><li>State: native `open`/`closed` + `ginee:*` labels (replace `☐`/`☒`).</li><li>PRs auto-close via `Closes #N`.</li><li>Two repos: primary (`github.repo`, origin-inferred) + framework upstream (`github.framework-repo`).</li><li>Framework variants (`file framework-bug` / `framework-feature` / `triage framework` / `promote discussion framework#<N>`) — metadata-only; no cross-repo pickup.</li><li>Spec: `core/github-integration.md`.</li></ul> |
| D15 | **Code-derived knowledge index** in `local/index/` (2026-05-17). <ul><li>D13 broadens from "documentation-derived" to "extracted"; same machinery (manifest + SHA-256 + recipes + lossless rule).</li><li>6 new code-category templates: `stack.yaml` / `topology.yaml` / `commands.yaml` / `conventions.yaml` / `runtime-facts.yaml` / `repo-map.idx`.</li><li>Manifest entries carry `category: doc | code`.</li><li>Built-in recipes: `builtin:package-manifest` / `builtin:container-orchestration` (+ `builtin:iac`) / `builtin:commands` / `builtin:conventions` / `builtin:runtime-facts` / `builtin:repo-structure`.</li><li>**Never read real `.env` or production secrets** — schema lives in `.env.example`.</li><li>Spec: `core/index-protocol.md`. Migration: `core/MIGRATIONS/D15-code-derived-index.md`.</li></ul> |
| D16 | **AgentSkills as per-adapter invocation surface** (2026-05-17; skill count revised 2026-05-22 from 10 → 12 with `ginee-update` + `ginee-address-review` additions). <ul><li>12 skills under `core/skills/ginee-*/SKILL.md` per the [AgentSkills standard](https://agentskills.io); cross-client (Claude Code, Cursor, Copilot, Codex, Gemini CLI, Goose, ~30+).</li><li>Skill names prefixed `ginee-` to avoid collisions.</li><li>`ginee-pick-up` + `ginee-triage` unified across task sources (issues + TODOs + freeform).</li><li>Each adapter's install step bridges `core/skills/ginee-*` into the client's expected path (`.claude/skills/`, `.github/skills/`, `.cursor/skills/`, ...).</li><li>Framework specs keep `@<role>` notation as vendor-neutral shorthand; adapters translate.</li><li>Migration: `core/MIGRATIONS/D16-agent-skills.md`.</li></ul> |
| D17 | **Delivery modes** (2026-05-17). Three modes — branch+PR / wt / commit-no-push — resolved by per-task prefix → Phase-3 answer → `framework.config.yaml § delivery.default-mode` → framework default. Combinable with `auto:` per D12 (auto default = `wt`). Full: PLAN.md § D17 + `core/delivery-modes.md` + `core/MIGRATIONS/D17-delivery-modes.md`. |
| D18 | **DevOps script-quality obligation** (2026-05-19). Every devops-owned `.ps1` / `.sh` change ships lint + Pester/bats + coverage on changed+added lines (`devops-scripts.coverage-threshold`, default 90). Full: PLAN.md § D18 + `core/MIGRATIONS/D18-devops-script-quality.md`. Closes [#28](https://github.com/kostiantyn-matsebora/ginee/issues/28) + [#30](https://github.com/kostiantyn-matsebora/ginee/issues/30). |
| D19 | **Backend coverage floor** (2026-05-19). `backend-engineer` ships ≥ `unit-backend.coverage-threshold` (default 90, configurable) line coverage on changed+added lines + SA per-task waiver + DTO/data-type exemption. Full: PLAN.md § D19 + `core/MIGRATIONS/D19-backend-coverage-floor.md`. Closes [#29](https://github.com/kostiantyn-matsebora/ginee/issues/29). |
| D20 | **Automatic mode — post-PR CI watch** (2026-05-19). Auto + Mode 1 enters CI-watch + iterate-fix-recheck loop after `gh pr create`; default policy `poll`; never auto-merge / auto-approve / mask a flake. Full: PLAN.md § D20 + `core/ci-watch.md` + `core/MIGRATIONS/D20-ci-watch.md`. Closes [#34](https://github.com/kostiantyn-matsebora/ginee/issues/34). |
| D21 | **Context-economy enforcement gate** (2026-05-19). Three layers — Claude Code hook + git hooks + CI workflow — block over-threshold framework edits on this repo's PRs without `Optimized-By: ai-engineer` trailer. Full: PLAN.md § D21 + `scripts/context-economy-check.ps1` + `core/MIGRATIONS/D21-context-economy-gates.md`. Closes [#38](https://github.com/kostiantyn-matsebora/ginee/issues/38). |
| D22 | **Doc-authoring protocol for adopter docs** (2026-05-19). Promotes `core/process.md § Documentation style` from aspirational → binding for adopter outputs. Three-file topology: rules in process.md (always-loaded), enforcement in `core/doc-authoring-protocol.md`, examples in `core/doc-authoring-examples.md`. No custom ginee lint — discovers adopter tooling. Full: PLAN.md § D22 + `core/MIGRATIONS/D22-doc-authoring-protocol.md`. Closes [#39](https://github.com/kostiantyn-matsebora/ginee/issues/39). |
| D23 | **Triage scoring — value × complexity priority** (2026-05-20). `ginee-triage` ranks by `score = value / complexity` (WSJF default; `H=3, M=2, L=1`). ATAM / utility-tree convention: `value:high|medium|low` + `complexity:high|medium|low` label namespaces (queryable, GH-native). TODO marker `[v:H c:L]` (case-insensitive). SA auto-estimates complexity on pickup; value stays reporter-defined. Sticky `<!-- ginee:score v=1 -->` comment per issue (hybrid: in-place updated current state + immutable audit comments on key events) with `Reasoning` column for ginee-set rows. Adopter override `triage.scoring-formula`. Full: PLAN.md § D23 + `core/triage-scoring.md` + `core/MIGRATIONS/D23-triage-scoring.md`. Closes [#46](https://github.com/kostiantyn-matsebora/ginee/issues/46). |
| D24 | **PR review-comment ingestion — skill + command parity** (2026-05-22). `ginee-address-review` skill + `@team-lead address-review #<PR>` command run the same 7-step procedure: fetch `pulls/{N}/comments` + `/reviews`, route per `local/bindings.md § Source-of-truth ownership`, surface plan table for approval (forced-interactive even in `auto:` — no exception), reconcile fix-track patches into one cycle commit + per-thread replies + sticky summary. Markers `ginee:review-reply r=<id>` (per-thread) + `ginee:review-cycle n=<N>` (sticky). Lossless coverage + idempotency. Explicit invocation only — no D20 CI-watch extension. Parity principle: every user-invocable workflow ships both surfaces with identical behaviour. Full: PLAN.md § D24 + `core/github-integration.md § Review-comment ingestion` + `core/roles/team-lead.details.md § Review-comment dispatch` + `core/templates/pr-comment-cadence.md`. Closes [#53](https://github.com/kostiantyn-matsebora/ginee/issues/53). |
| D25 | **Classical-architect SA model — design / review / governance** (2026-05-22). SA redefined from central-scribe + Phase-7-only sign-off to **three activities across the lifecycle**: <ul><li>**Design** — Phase 1 elicits FRs / NFRs / Constraints in `local/requirements.md` + derives ASRs in `local/asr-utility-tree.md` via ATAM utility tree (ASRs = outcome of requirements, not same level — two-file split). Phase 2 authors target architecture; greenfield-vs-delta mode resolved at Phase 1.</li><li>**Review** — any phase, on engineer-proposed architectural changes; APPROVE / REJECT / REQUEST-CHANGES; no code edits.</li><li>**Governance** — continuous, **scoped only to PRs touching SA-owned files** per `local/bindings.md § Source-of-truth ownership` (NOT every Phase 4/5/6 PR).</li></ul> **Doc-ownership redistribution** — CRs · project-instruction file · work-breakdown moved to `team-lead`; per-tier docs (CI/CD guide · runbooks · READMEs · API docs · test plans · scenario docs) moved to tier engineers. SA reviews architectural coherence on every non-SA-owned doc PR. **`ai-engineer` counterpart generalized** — was SA ↔ ai-engineer; now all-roles ↔ ai-engineer. `core/doc-co-ownership.md` renamed → `core/doc-roles.md`. **Backwards compatibility** — force re-attribution sweep on `rediscover` (D6); migration spec `core/MIGRATIONS/D25-classical-architect.md`. **New templates** — `core/templates/requirements-register.md` + `core/templates/asr-utility-tree.md`. Full: PLAN.md § D25 + `core/roles/solution-architect.md` + `core/doc-roles.md` + `core/process.md § Phase 1 / 2 / 4 / 5 / 6 / 7`. Closes [#37](https://github.com/kostiantyn-matsebora/ginee/issues/37). |
| D26 | **D22 scope extension — ginee-authored GitHub issue bodies + framework-authored comments** (2026-05-22). D22 protocol previously scoped only adopter docs; D26 extends to (a) issue bodies authored via `ginee-file-*` skills + (b) framework-authored comments (Phase-transition · sticky `ginee:score` / `ginee:review-cycle` · audit comments · per-thread review-replies). Same 5 mandatory checks per `core/process.md § Documentation style`; same default-shape map. **Lint covers every section, including Summary** — no section-by-length exemption. Self-lint runs inside the `ginee-file-*` skills + comment-cadence procedures before publishing; no external linter. Reporter-authored content unchanged (D14 forbidden upheld); `ginee-pick-up` MAY surface a polite restructure advisory at pickup but never auto-edits. 4 issue templates gain D26 shape-rule banner. 3 new bad/good example pairs in `core/doc-authoring-examples.md` (Summary · body section · Phase-transition comment). Full: PLAN.md § D26 + `core/doc-authoring-protocol.md § Scope` + `core/MIGRATIONS/D26-doc-protocol-scope-extension.md`. Closes [#64](https://github.com/kostiantyn-matsebora/ginee/issues/64). |
| D27 | **`ginee-update` fetches installer from upstream** (2026-05-22). Skill Step 1 needs only `<fw>/core/VERSION` (installer is bootstrap-layer, intentionally pruned from `.agents/ginee/`); Step 6 downloads `install.{ps1,sh}` from `raw.githubusercontent.com/<upstream>/<target>/` to temp, then runs with `-Target <root> -Adapter <detected> -Ref <target> -RepoUrl https://github.com/<upstream> -UpdateOnly`. Adapter = single non-`_shared` subdir under `<fw>/adapters/`; `<upstream>` from `github.framework-repo` (default `kostiantyn-matsebora/ginee`); `<root>` = `<fw>/../..`. Installer itself unchanged. Adapter `install.md § Updates` sections refreshed to drop misleading co-located installer path. Chicken-and-egg: pre-D27 installs land the fix via one-time bootstrap one-liner (the documented #67 workaround). Full: PLAN.md § D27 + `core/MIGRATIONS/D27-installer-fetch-on-update.md`. Closes [#67](https://github.com/kostiantyn-matsebora/ginee/issues/67). |
| D28 | **Skill-runner / team-lead surface boundary** (2026-05-22). Skill-runner = thin mechanical surface running a `ginee-*` skill body; not a role, not an orchestrator. Allowed: parse/identify source · label·sticky·audit-comment ops · branch ops · the skill's one named first-batch dispatch. Forbidden (must dispatch `@team-lead`): plan drafting · synthesis of parallel returns · gate text · re-dispatch · routing reconciliation · default selection · `local/bindings.md` lookup to settle routing. Hand-back rule: every `ginee-*` skill dispatches `@team-lead` after first mechanical batch. Full: PLAN.md § D28 + `core/process.md § Skill-runner — surface boundary` + `core/MIGRATIONS/D28-skill-runner-boundary.md`. Closes [#71](https://github.com/kostiantyn-matsebora/ginee/issues/71). |
| D29 | **Strict subagent-return schema** (2026-05-23). Every cardinal-dispatch return is schema-bound per `core/templates/phase-report.md` — same machinery as D22 / D26, scoped to the subagent-return surface. <ul><li>**Mandatory sections** — `## Files touched` · `## Decisions made` · `## Verification log` · `## Open issues` · `## Next dispatch needed` (empty case `(none)`); conditional `## Hand-off` (forced handoff) + `## Stop-state` (`Status: In-progress`); optional `## Notes` (≤ 200 words; ≤ 5-line code-snippet carve-out).</li><li>**6 mandatory checks** before report-as-done — 5 from D22 / D26 + *no narrative preamble*.</li><li>**Forbidden** — narrative preamble · restated dispatch context · code outside Notes carve-out · verbose rationale outside Notes · parenthetical comma-soup.</li><li>**Enforcement** — LLM self-review (no external linter); orchestrator surfaces one-line advisory on violations, never re-dispatches purely for format, never auto-rewrites.</li><li>**Worked measurement** — 3,603 → 1,136 chars (68.5% reduction) on a real Phase-4 return; documented in `core/doc-authoring-examples.md § 10`.</li><li>**Forward-only**; purely additive — no `local/` schema change.</li></ul> Full: PLAN.md § D29 + `core/process.md § Reporting` + `core/templates/phase-report.md` + `core/MIGRATIONS/D29-strict-subagent-return-schema.md`. Closes [#69](https://github.com/kostiantyn-matsebora/ginee/issues/69). |
| D30 | **Adopt-existing-solution as a first-class Phase-2 option** (2026-05-23). Every Phase 2 design proposal AND iteration-protocol Propose step (Phase 4–7 > 15-min sub-tasks with a live adopt-vs-build axis) MUST surface ≥ 1 adopt candidate — with name · version · source link · license · one-line fit rationale — OR an explicit `(none viable — <reason>)` cite. Same self-lint machinery as D22 / D26 / D29. <ul><li>**Schema** — 4 candidate types: `adopt` (full citation) · `build` (rationale why adoption rejected) · `hybrid` (adopt portion + build portion + boundary) · `(none viable — <reason>)`. Every candidate explicitly tagged; no silent mixing.</li><li>**Floor** — hard ≥ 1 `adopt` candidate OR `(none viable)`; soft encourage 2–3 for non-trivial scope.</li><li>**5 mandatory checks** — adopt floor present · citations complete · tagging explicit · empty research documented · fit rationale concrete.</li><li>**License stance** — defer to adopter `local/`; framework requires the citation but takes no opinion on which licenses pass.</li><li>**Enforcement** — LLM self-review before surfacing the proposal; orchestrator one-line advisory on violation; never auto-rewrites.</li><li>**Forward-only**; purely additive — no `local/` schema change.</li></ul> Full: PLAN.md § D30 + `core/options-protocol.md` + `core/MIGRATIONS/D30-adopt-existing-solution.md`. Closes [#75](https://github.com/kostiantyn-matsebora/ginee/issues/75). |
| D31 | **Per-role + per-task model tier** (2026-05-23). Three vendor-neutral tiers (`reasoning` · `standard` · `fast`) declared as role-kernel `default-tier:`; per-adapter `<tier> → <id>` map. Resolution: per-task prefix `model:<tier>` → Phase-3 answer → `local/framework.config.yaml § model-tier.per-role.<role>` → kernel `default-tier:`. Claude adapter writes `model: <id>` into `.claude/agents/<role>.md` frontmatter; non-Claude adapters emit install warning. Purely additive — absent `model-tier:` → defaults apply. Full: PLAN.md § D31 + `core/MIGRATIONS/D31-model-tier.md`. Closes [#76](https://github.com/kostiantyn-matsebora/ginee/issues/76). |
| D32 | **Claude adapter — accept-orchestrated subagent dispatch** (2026-05-23). Claude Code `Agent` tool is top-level only → D28 hand-back silently degrades on Claude. D32 narrows D28 *adapter-specific*: team-lead owns plan/synthesis/next-decision (re-invoked each cycle); skill-runner executes approved contract verbatim, passes returns through. Other adapters keep D28. Purely additive. Full: `core/MIGRATIONS/D32-claude-adapter-subagent-dispatch.md`. Closes [#87](https://github.com/kostiantyn-matsebora/ginee/issues/87). |
| D33 | **D29 phase-report schema enforcement hardening** (2026-05-23). Pre-D33 the 6 mandatory checks at report-as-done were aspirational — agents skipped them silently and the orchestrator had no structural detection surface. D33 adds the literal `<!-- D29 self-lint: pass -->` marker as the agent's attestation line (last line of every return). Marker absence = structural skip signal; orchestrator surfaces the one-line advisory at receive-time + carries the rule forward to the next dispatch. **Skill-runner explicitly forbidden** from "cleaning up" a non-compliant return before passing to team-lead (D28 boundary holds even when the return missed self-lint). New paired bad/good full-return example in `core/doc-authoring-examples.md § 12`. Purely additive — no `local/` change, schema unchanged, 6 checks unchanged. Full: `core/MIGRATIONS/D33-d29-enforcement-hardening.md`. Closes [#86](https://github.com/kostiantyn-matsebora/ginee/issues/86). |
| D34 | **Taxonomy identifier short-name pairing** (2026-05-23). Every cardinal output, ginee-authored GitHub artefact, and adopter doc cites taxonomy items in slug-glued form — `D28-skill-runner-boundary` · `ADR-0001-topology-derivation-five-pass` · `CR-0010-component-ci-pipeline` · `FR-04-deploy-rollback` · `NFR-02-cost-cap` · `ASR-03-availability-budget`. Bare IDs force a context-switch; slug-glued lets the reader copy-paste into a filesystem search (matches on-disk filename convention). **Out of scope** — issue / PR / commit-SHA / package-name references stay bare. **Resolution lookup** — file-backed via filesystem listing · inline-table via register row noun-phrase slugify · index-class via `manifest.yaml § name:`. **Self-lint** extends D22 / D26 / D29 mandatory check #5 (cross-references) — regex `\b(D|ADR-?|CR-?|FR-?|NFR-?|ASR-?)\d+\b` not followed by `-<slug>` trips. Same machinery as D22 / D26 / D29 — LLM self-review at draft time; no external linter. Resolution failure surfaces inline (`D28-?? (slug lookup failed)`); never invent a slug. Forward-only — historical outputs not rewritten. Purely additive — no `local/` change, schema unchanged, 6 checks count unchanged. Full: `core/doc-authoring-protocol.md § Taxonomy identifier pairing (D34)` + `core/MIGRATIONS/D34-identifier-short-name-pairing.md`. Closes [#88](https://github.com/kostiantyn-matsebora/ginee/issues/88). |

## Stack — non-negotiable

| Layer | Choice |
|---|---|
| Authoring | Markdown only |
| Distribution baseline | Copy-paste of the framework source into `.agents/ginee/` in the adopter project |
| Distribution upgrades | Tarball (GitHub Releases) + one-line shell installer (`iwr...iex` / `curl...sh`) |
| Future fast-follower | `npx @org/ginee init / update` (Node.js) |
| Versioning | SemVer in `core/VERSION`; migration notes in `core/MIGRATIONS/` |
| Update mechanism | User re-fetches `core/` + `adapters/` + `extras/`; `local/` survives |

## Phased delivery (current state)

| Phase | Status | Notes |
|---|---|---|
| Skeleton (directories + `VERSION`) | done | 11 directories, version `0.1.0` |
| Mega-1 — `core/process.md` + 7 cardinal roles + 8 templates | done | 17 files, ~148K |
| Mega-2 — 5 client adapters (claude / copilot / cursor / codex / generic) | in progress | background dispatch active |
| Mega-3 — `extras/roles/` library + `README.md` + install scripts + GH Release workflow | pending | |
| v2.0 — MCP server | deferred | |

## Hard constraints

- All files under this `ginee/` framework repo only — do not modify any other project from this directory. (This refers to the framework's own source repo; in adopter projects the framework lives at `.agents/ginee/`.)
- `core/`, `adapters/`, `extras/` are upstream-owned — replaced on update for adopters; we author them here.
- `local/` is adopter-owned — survives updates.
- Lossless rule for restructuring: any pass that touches structure must prove every rule/invariant survives (per `core/roles/ai-engineer.md`).
- SAD-freeze + CR/ADR pattern applies once this project's own architecture doc is finalized (not yet — currently in design phase).
- Follow `core/process.md § Documentation style — structure over prose` and `## Framework authoring — context economy` below for all new docs.
- PowerShell scripts (`*.ps1` anywhere in this repo): every change passes [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) (rules per `PSScriptAnalyzerSettings.psd1` — default minus narrow, justified exclusions) AND is covered by passing [Pester](https://pester.dev) tests under `tests/<script>.Tests.ps1`. Both enforced as merge gates by `lint-powershell` + `test-powershell` CI jobs.
- GitHub issue pickup — before Phase 2 on any picked-up issue, ALWAYS fetch **both**:
  - Comments — `gh issue view <N> --comments` — owner often pins option-picks or scope clarifications there (e.g. issue #29 specifies "Option B + DTO exempt + configurable threshold" only in a comment, not the body).
  - Sub-issues — `gh api repos/<owner>/<repo>/issues/<N>/sub_issues` — sub-issues carry scope expansions the parent body alone does not surface (e.g. issue #28 has #30 "add linting" as a sub-issue with no body — title-only requirements still bind).
  - Skip either → Phase 2 plan is wrong; redo cost > the 2 extra API calls.
- **User-docs co-update (D25 — binding).** Every adopter-facing framework change (new skill · new D-decision · role-model change · new spec / template · new register / artefact) updates `docs/` (`CONCEPTS.md` · `GETTING_STARTED.md` · `CHEATSHEET.md` · `index.md` as applicable) **in the same PR**. Internal-only changes exempt — D21 context-economy gate · CI internals · framework-dev hygiene · D18 script-quality · D19 backend-coverage. Phase-7 SA review verifies coverage when the change touches adopter-facing surface. Recurring miss across pre-D25 feature PRs (#41 · #43 · #47 · #51 · #54 · #55 · #57) — backfilled in #59; binding from D25 onward.

## Framework authoring — context economy

- **Load-bearing LLM context for every adopter on every task.** `core/` alone is ~160K today, before `local/`, project docs, or task materials.
- **Aggregate weight is the dominant adopter cost** — every byte multiplies across every dispatch in every project.
- **Treat token weight as a first-class constraint, on par with correctness.**

- **Concise + LLM-optimized.** Every framework file (`core/`, `adapters/`, `extras/`) is loaded into the model's context on every adopter task. Write for that audience. Cut filler, redundant restatements, marketing tone, and "in this section we will explore" preambles. Every sentence must earn its tokens.
- **Structure over prose — always.** Convert prose into the smallest readable structure that preserves every rule. Available shapes:
  - Bullets, numbered lists, tables, headings, nested sub-lists, multi-level trees, definition lines (`term — gloss`).
  - Any combination — bullets containing tables, tables with bulleted cells, nested sub-bullets under a parent bullet — is fair game when it improves LLM parse-ability OR human scannability.
  - **Line count is not the constraint; byte count + parseability are.** A 10-line nested list that replaces a 4-line dense paragraph is a win: same bytes (or fewer), each rule on its own line, no connectives to disambiguate.
  - Conversion rules:
    - Steps / sequences → numbered list.
    - Choices, mappings, triggers→actions, role→responsibility → table.
    - "X means Y" → `**X.** Y` on its own line.
    - Multi-rule bullet ("do A; also B; warn about C") → parent bullet + sub-bullets, one rule per line.
    - Prose paragraph stating > 2 rules → restructure. No exceptions.
  - Same rule as `core/process.md § Documentation style`, but in framework files it is **binding, not aspirational**.
- **Dispatch `ai-engineer` to optimize framework files** whenever a file grows materially, a new artefact lands, or a structural change touches more than one file. `ai-engineer`'s charter is context economy + load topology — that's exactly the work. Hard threshold: any framework file change above ~50 lines net-added should be followed by an `ai-engineer` optimization pass under the lossless rule before commit. Adding new role files, templates, or adapter sections always triggers an optimization pass.
- **Gate (D21).** Three layers enforce threshold + structural-lint on this repo's PRs:
  - Claude Code PostToolUse hook — `.claude/settings.json.example` (copy → `.claude/settings.json`).
  - Git pre-commit / pre-push — `hooks/`, installed via `scripts/install-hooks.{ps1,sh}`.
  - CI workflow — `.github/workflows/context-economy.yml`.
  - Marker: git trailer `Optimized-By: ai-engineer` on any commit in PR range.
  - Waiver: PR label `context-economy:waived` + `**Context economy waiver:** <reason>` in body.
  - Spec: `scripts/context-economy-check.ps1`. Migration: `core/MIGRATIONS/D21-context-economy-gates.md`.

## Resuming work in a new session

1. Read `CLAUDE.md` (this file) + `PLAN.md` + `core/process.md`.
2. Check task list for any in-flight or pending tasks.
3. Determine current phase from "Phased delivery" table above.
4. Continue per the iteration protocol — propose → review → implement; iterations of 3–5 min if scope > 15 min.

## Out of scope (do not implement)

- MCP server (deferred to v2.0).
- Auto-update CLI that modifies adopter projects without explicit user invocation.
- Per-domain templates (architecture / API / mockup contracts) — adopters bring their own; framework only ships process.
- Multi-organization / multi-repo aggregation — single-repo at a time.
