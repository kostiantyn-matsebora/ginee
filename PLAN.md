# `ginee` — Reusable OSS Multi-Agent Engineering Framework

> **Status.** Design document. Captures the framework's architecture, locked decisions, phased delivery roadmap, and verification plan. Lives in the repo so it's portable across machines / collaborators / clones.

## Context

The current deployment-dashboard project runs a 5-agent collaboration model (solution-architect, frontend-engineer, backend-engineer, devops-engineer, qa-engineer) coordinated by `CLAUDE.md`. The model has been observed to work well — phased lifecycle, strict-domain rule, parallel dispatch, cross-domain bug cycle. This plan extracts that working pattern into an **OSS framework** — `ginee` — that any project can adopt with minimal friction, regardless of LLM client (Claude Code, Copilot, Cursor, Codex, Kuro, ...).

The framework ships **process knowledge only** — no domain, stack, architecture, or SDLC opinions. Project-specific knowledge is discovered automatically on first run and lives in a project-local layer that survives upstream updates. Project knowledge sources (markdown docs, diagrams, mockups) are **referenced**, never copied — doc changes propagate instantly.

---

## Final architecture

### Three-layer directory model

```
.agents/ginee/             ← drops into any project
├── core/                             ← immutable, replaced on update
│   ├── process.md                    ← phased lifecycle, strict-domain rule,
│   │                                   cross-domain cycle, parallel dispatch rules
│   ├── roles/                        ← 7 cardinal role definitions (vendor-neutral md)
│   │   ├── team-lead.md
│   │   ├── ai-engineer.md
│   │   ├── solution-architect.md
│   │   ├── frontend-engineer.md      (alias: client-engineer)
│   │   ├── backend-engineer.md       (alias: service-engineer)
│   │   ├── devops-engineer.md        (alias: platform-engineer)
│   │   └── qa-engineer.md            (alias: quality-engineer)
│   ├── templates/                    ← PR description, hand-off note,
│   │                                   discovery report, phase report
│   ├── MIGRATIONS/                   ← version-to-version migration notes
│   └── VERSION                       ← SemVer pin
│
├── adapters/                         ← per-client renderings of core
│   ├── claude/                       ← .claude/agents/*.md + CLAUDE pointer
│   ├── copilot/                      ← .github/copilot-instructions.md
│   ├── cursor/                       ← .cursor/rules/*.mdc
│   ├── codex/                        ← Codex instruction file
│   └── generic/                      ← fallback single-file instructions
│
├── extras/                           ← curated specialist-role library (opt-in)
│   └── roles/
│       ├── security-engineer.md
│       ├── ml-engineer.md
│       ├── mobile-engineer.md
│       ├── sre.md
│       └── data-engineer.md
│
├── local/                            ← project-specific, survives update
│   ├── project-profile.md            ← produced by discovery
│   ├── bindings.md                   ← role → owned paths/concerns
│   ├── framework.config.yaml         ← concept → path mapping
│   └── roles/                        ← user-authored custom roles
│
└── README.md                         ← install + per-client pointer lines
```

### Layer rules

| Layer | Owner | Replaced on update? | Editable by user? |
|---|---|---|---|
| `core/` | upstream framework | **yes** | no — overrides go in `local/` |
| `adapters/` | upstream framework | yes | no |
| `extras/` | upstream framework | yes | no — copy into `local/roles/` to use |
| `local/` | the project | **no, never** | yes |

### Reference, never copy (R6)

`.agents/ginee/local/framework.config.yaml` maps **concepts → project paths**:

```yaml
architecture-doc: docs/architecture.md
mockup: docs/mockup.html
api-contract: docs/api.md
adr-directory: docs/adr/
diagrams-directory: docs/diagrams/
todo: TODO
```

Roles read this config at runtime; renaming a doc = edit one line. No knowledge is copied into the framework.

---

## Bootstrap & lifecycle

### Install (manual baseline — D4)

1. Get the `.agents/ginee/` directory into your project (one of the channels below).
2. Open the project's client-specific instruction file (`CLAUDE.md`, `.github/copilot-instructions.md`, `.cursor/rules/`, ...).
3. Paste the **single pointer line** the README provides for that client.
4. Open your LLM, prompt: `@team-lead run initial discovery.`
5. `team-lead` writes `local/project-profile.md`, `local/bindings.md`, `local/framework.config.yaml`. Done.

### Distribution channels (D4 — ladder)

| Tier | Channel | Tooling |
|---|---|---|
| 0 | Copy-paste from cloned upstream repo | git |
| 1 | Download tarball from GitHub Releases | browser |
| 2 | One-line shell installer (`iwr ...\|iex` / `curl ...\|sh`) | shell |
| 3 *(fast-follower)* | `npx @org/ginee init / update` | Node |
| 4 *(fast-follower)* | GitHub template repo + sync GH Action | GitHub + CI |
| 5 *(v2.0)* | MCP server | MCP-capable client |

MVP delivers tiers 0–2 (same artefact at different convenience levels) + README with verbatim pointer lines per client.

### Self-learning (discovery)

`team-lead` runs an initial `discover` pass:

1. Detect tech stack (package files, lockfiles, language footprint).
2. Detect domain (README, top-level docs).
3. Detect architecture artefacts (`docs/architecture*.md`, ADRs, diagrams, mockups).
4. Detect SDLC artefacts (`.github/workflows/`, CI configs).
5. Detect roles needed → suggest enabling extras from the framework's `extras/roles/` library.
6. **Scan external agent catalogs** — cross-reference the project profile against curated cross-tool libraries (canonical: [awesome-copilot agents](https://github.com/github/awesome-copilot/blob/main/docs/README.agents.md)). Surface stack/domain-matched candidates with provenance + which cardinal each would coordinate under.
7. Detect `TODO` conventions (root + nested).
8. Write `local/project-profile.md`, `local/bindings.md`, `local/framework.config.yaml`.
9. Report — recommend `extras/` specialists + external-catalog candidates. **User approves per item.** None are auto-added.
10. For each user-approved external agent — translate to the framework's role shape (per `core/templates/role-authoring-template.md`), record `source:` + `last-synced:` provenance, add `local/bindings.md` routing entry + role-boundaries forbidden-actions row. Schedule periodic re-sync against upstream.

### Refresh model (D6 — both)

- **Manual:** user invokes `@team-lead rediscover`.
- **Auto-flag:** `team-lead` reads `project-profile.md` before every task; if it encounters files/patterns not in the profile, flags staleness in its first response and offers `rediscover`.

### Coexistence (D7 — adopt)

Init never overwrites the existing instruction file. It only appends (or asks the user to append) a single pointer line. Existing project rules continue to apply.

### Update

User re-fetches the upstream `.agents/ginee/` and replaces `core/`, `adapters/`, `extras/`. `local/` is untouched.
`core/VERSION` is SemVer; breaking releases ship a migration note in `core/MIGRATIONS/<from>-to-<to>.md`.

### Role extension (D5, D10 — both)

- **Pre-built specialists:** `extras/roles/` ships with security-engineer, ml-engineer, mobile-engineer, sre, data-engineer. User copies any into `local/roles/` to enable.
- **Free-form authoring:** user creates `local/roles/<custom-role>.md` following a documented template. `team-lead` discovers it on next prompt and adds it to the routing table.
- `team-lead` always remains orchestrator — custom roles register **under** PM, not alongside.

### Client-agnosticism (D1, D9)

Adapters render the **same** vendor-neutral `core/` into each client's native format. Each adapter declares its capability tier based on the **current** state of the client (re-evaluated per release — subagent support evolves fast):

- **Tier-1 — native subagents + parallel dispatch.** Cardinals render as real subagent files the client loads natively. Verified for this MVP cycle: Claude Code (`.claude/agents/`), GitHub Copilot CLI (custom-agents SDK + `/fleet` for parallel orchestration, GA Feb 2026). Re-check per release.
- **Tier-2 — single-agent persona model.** Cardinals become named personas the single LLM impersonates by name in chat. Same process model, sequential execution. Used for clients without native subagents at this release.
- **Tier-3 — instructions-only fallback.** Generic adapter for any LLM tool not specifically supported. Single concatenated instructions file; cardinals as in-prompt personas.

Tier assignments are NOT permanent — each adapter's `README.md` records the verification date and links to the client's current docs. Adapters move tiers up as clients evolve.

Role names: ship current ones as canonical (`frontend-engineer`, ...) with generic aliases (`client-engineer`, ...) declared via front-matter — users can refer to either form.

---

## Phased delivery (MVP roadmap)

| Phase | Deliverable | Source |
|---|---|---|
| P1 | `core/process.md` | extracted + genericised from current `CLAUDE.md` |
| P2 | `core/roles/*.md` (7 cardinals) | genericised from `.claude/agents/*.md` + new `team-lead.md` + new `ai-engineer.md` |
| P3 | `core/templates/*.md` | extract templates implicit in current process |
| P4 | `adapters/claude/` | new — smoke-tested by re-importing into deployment-dashboard |
| P5 | `team-lead`'s discovery flow | new — tested against deployment-dashboard |
| P6 | `adapters/copilot-cli/` (Copilot CLI tier-1) | new |
| P7 | `adapters/agents-md/` (shared AGENTS.md for Codex / Cursor / Windsurf / Amp / Devin / Factory / Jules / Copilot IDE — tier-2) + `adapters/generic/` (INSTRUCTIONS.md fallback — tier-3) | new |
| P8 | `extras/roles/*.md` (5–6 specialists) | new |
| P9 | `README.md` with per-client pointer lines + tier-0/1/2 distribution | new + `install.ps1` / `install.sh` + GH Release workflow |
| Fast-follower | `npx` CLI + GitHub template repo | new |
| v2.0 | MCP server | new |

---

## Verification

| Test | Procedure | Pass criteria |
|---|---|---|
| **Self-host** | Apply framework to the deployment-dashboard repo; replace `.claude/agents/*.md` with adapter outputs; run a full TODO cycle. | All 8 lifecycle phases execute; harness stays green; behavior indistinguishable from pre-extraction. |
| **Greenfield** | Apply to a small Flutter app or a data-pipeline repo. | Discovery produces a sensible profile + bindings; PM routes correctly to relevant roles; non-applicable cardinal roles are deactivated cleanly. |
| **Client-portability** | Apply to a project using Cursor or Copilot. | Role-persona prompts produce coherent same-process behavior; pointer line + adapter file are the only artefacts touched. |
| **Update safety** | Bump `core/VERSION`; modify a `core/` file upstream; re-fetch into a project with `local/` customisations. | `local/` survives untouched; `core/` reflects upstream; migration note (if any) is surfaced. |
| **Reference integrity** | Rename `docs/architecture.md` → `docs/sad.md` in a consumer project; update `local/framework.config.yaml`. | All roles continue to read the right file without any `core/` change. |

---

## Decisions locked

| # | Decision | Choice |
|---|---|---|
| D1 | Framework shape | **Hybrid** — vendor-neutral core spec + per-client adapter packs. |
| D2 | MCP server | **Out of MVP**; v2.0. |
| D3 | Gaps to solve before locking design | All four clusters: client-agnosticism, self-learning, generic-vs-project split, update + customization safety. |
| D4 | Distribution baseline | **Copy-paste of a directory MUST be supported.** Other simpler channels welcome on top. |
| D5 | Role topology | **7 cardinal roles (5 engineering + team-lead + ai-engineer); extensible; team-lead always orchestrator.** ai-engineer is the universal meta-engineering cardinal — every adopting project has AI assets and docs that need optimization; revised from 6 to 7 on 2026-05-16. Orchestrator renamed from `project-manager` to `team-lead` on 2026-05-18 (better matches the "team that behaves like a real one" tagline — engineering teams have team leads, not project managers); `project-manager` retained as alias for back-compat. |
| D6 | Discovery refresh model | **Both** — manual `rediscover` + auto-flag staleness. |
| D7 | Coexistence with existing instruction files | **Adopt (additive)** — single pointer line only. |
| D8 | Install directory name | **`.agents/ginee/`** (amended 2026-05-17 from a root-level dir; revised 2026-05-18 from `.agents/engineering-team/` as part of the D11 rebrand) — dot-prefix matches the convention every other agent/IDE tool uses (`.claude/`, `.cursor/`, `.github/`, `.vscode/`); `.agents/` namespace leaves room for other agent frameworks to coexist without polluting the project root. |
| D9 | Role names | **Hybrid** — keep current names as canonical; generic aliases via front-matter (`client-engineer`, `service-engineer`, ...). |
| D10 | Custom-role extension | **Both** — pre-built `extras/` library + free-form authoring under `local/roles/`. |
| D11 | Public framework name | **`ginee`** (revised 2026-05-18 from `engineering-team`). Tagline: *An AI software engineering team that behaves like a real one. Drops into your project, self-onboards, and gets to work.* Skill prefix `ginee-` (originally codename, now formal name — consistent at all surfaces). Install path `.agents/ginee/` (revised from `.agents/engineering-team/` per D8). |
| D12 | Automatic mode (added 2026-05-17) | **Per-task opt-in.** The user may run a task end-to-end without per-phase gates by prefixing it with `auto:` (or `team-lead` may propose auto mode for low-risk tasks; user must say yes). Elides Phase 3 design review (when no UX impact), iteration intermediate-batch confirmations, and engineer "stop and confirm" pauses. Falls back to interactive on forced-interactive triggers (material UX change, unresolved defect after 2 iterations, cross-domain cycle, wrong test oracle, budget/time overruns, destructive/external actions). Replaces Phase 8 with a **delivery handoff**: working-tree changes prepared but not committed, delivery report produced, user picks Accept (commit per convention; push only on explicit ask) / Feedback (loop to relevant phase) / Reject (revert working tree). The Phase 8 user-approval invariant is preserved as that single final gate. |
| D13 | Project-doc index in `local/index/` (added 2026-05-17) | **Extracted summaries + SHA-256 staleness.** Adopter projects accumulate substantial docs (architecture, mockup, ADRs, CRs, scenarios, plus adopter-specific classes like RFCs, runbooks, threat models, model cards, data dictionaries). Pulling full source into context on every dispatch burns tokens (140K+ scenario corpora observed). Discovery extracts lightweight per-doc-class summaries to `local/index/`; roles read the index first and originals only on demand. `local/index/manifest.yaml` tracks SHA-256 per source — `team-lead` checks drift pre-dispatch and dispatches `ai-engineer` to re-extract on mismatch. `ai-engineer` owns extraction with **built-in recipes** for common doc classes + a **novel-class recipe** for adopter-specific doc types (RFC, runbook, threat-model, model-card, etc.). Extension via `framework.config.yaml § index.classes` for adopter-declared classes. Full spec: `core/index-protocol.md`. |
| D14 | GitHub issues + discussions as task source (added 2026-05-17) | **Fourth task source alongside TODO files + direct instructions.** Adopters file work where they already do (issues, discussions); the framework picks it up via the standard Phase 1–8 lifecycle and closes the loop with issue comments + PR linkage. `team-lead` handles both directions: outbound (`@team-lead file bug` / `file feature` — uses structured templates under `core/templates/issues/` and creates labelled issues), inbound (`@team-lead pick up #<N>` and `triage` — never auto-picks), and `@team-lead promote discussion #<N>` for ideas → issues. Native `open`/`closed` + configurable labels (`ginee:ready` / `:in-progress` / `:blocked` defaults) replace the `☐`/`☒` glyph mechanic for issue-sourced tasks. PR descriptions auto-close issues via `Closes #N` linkage. Tool surface is vendor-agnostic — `gh` CLI baseline, GitHub MCP / generic HTTPS as alternates. **Two repos tracked.** Primary (`github.repo`, inferred from `git remote get-url origin`) — adopter's own project. Framework upstream (`github.framework-repo`, set at install by the curl/tarball script) — lets adopters file framework feedback against ginee itself via the **metadata-only** `framework-` prefix variants: `file framework-bug` / `file framework-feature` / `triage framework` / `promote discussion framework#<N>`. **No `pick up framework#<N>`** — addressing a framework issue needs the framework source, so the workflow is: clone the framework repo separately, cd into it (origin == framework), run plain `pick up #<N>`; target-based template selection auto-picks framework-* templates because target = origin = framework. Framework-targeted templates (`framework-bug-report.md`, `framework-feature-request.md`) capture affected framework artefact (process / role-kernel / role-details / template / adapter / extras-role / spec) + framework version + adapter in use + locked-decision impact + backward-compatibility (migration note required?). Framework-targeted ops fail fast with "framework-repo not configured" when `github.framework-repo` is unset — no silent fallback to primary. Discussions are read-only context — must be promoted to an issue before pickup. Full spec: `core/github-integration.md`. |
| D15 | Code-derived knowledge index (added 2026-05-17) | **Extension of D13 to non-doc sources via Approach A.** Index protocol broadens from "documentation-derived" to "extracted" — same `local/index/manifest.yaml`, same SHA-256 staleness check, same `ai-engineer` recipe pattern, same lossless rule. Each manifest entry now carries `category: doc | code` to distinguish source provenance. Six new code-category templates land under `core/templates/index/`: `stack.yaml` (tech stack by tier + direct deps + Dockerfile FROM), `topology.yaml` (services × ports × depends_on × replicas + networks + volumes + ingress + IaC summary), `commands.yaml` (build/test/lint/format/deploy/dev command catalog), `conventions.yaml` (formatter + linters + naming + pre-commit + ignored), `runtime-facts.yaml` (declared env-vars with secret + tier + consumed-by), `repo-map.idx` (top-level directory inventory with path → owner-role lookup). Built-in recipes: `builtin:package-manifest`, `builtin:container-orchestration` (+ `builtin:iac` for TF/Pulumi/Bicep), `builtin:commands`, `builtin:conventions`, `builtin:runtime-facts`, `builtin:repo-structure`. Discovery flow Step 8b enumeration extended with code-category heuristics + globs. Pre-dispatch staleness check covers both categories (doc drift for design/governance/scenario work; code drift for stack/topology/commands/conventions/runtime-facts work). Sample-and-check lossless rule extended: code verifies declared dependency / service / port / command / convention rule / env-var / top-level directory at cited anchor. **Critical safeguard for `builtin:runtime-facts`** — never reads real `.env` or production appsettings; schema lives in `.env.example`; declared values in compose/k8s redacted if secret-looking. Approaches B (parallel `core/code-knowledge-protocol.md`) and C (per-role facts files under `local/facts/<role>.yaml`) considered + rejected during Phase 2 — B duplicates machinery for marginal mental-model gain; C addresses a different problem (role-scoped reads) that can layer on top later without conflict. Spec: `core/index-protocol.md`. Migration: `core/MIGRATIONS/D15-code-derived-index.md`. |
| D16 | AgentSkills as per-adapter invocation surface (added 2026-05-17) | **Framework workflows ship as Skills per the [AgentSkills standard](https://agentskills.io).** Original "slash commands" framing in issue #2 pivoted during Phase 1 — skills are the cross-client standard (Claude Code, Cursor, GitHub Copilot, VS Code, OpenAI Codex, Gemini CLI, Goose, ~30+ clients); slash commands are deprecated in Claude Code in favour of skills. **10 skills under `core/skills/ginee-*/SKILL.md`** — each a directory with YAML frontmatter (`name`, `description` required per spec) + Markdown procedure body. **Skill prefix `ginee-`** (formal framework name per D11) — avoids name collisions with adopter-authored skills. **Unified skills** — `ginee-pick-up` handles all task sources (GitHub issue `#N`, TODO line, freeform request); `ginee-triage` lists ready work across all sources (issues + framework upstream + TODOs). **Bridging** — each adapter's install step copies/symlinks `core/skills/ginee-*` into the client's expected skill-discovery path (`.claude/skills/`, `.github/skills/`, `.cursor/skills/`, etc.). Symlinks preferred (auto-update). **Adapter docs** — each adapter's `install.md` gains a "How to invoke" section translating framework `@<role>` notation into client-native invocations (Cursor literal, Copilot natural-language, generic `act as <role>`). Framework specs keep `@<role>` as vendor-neutral shorthand. Migration: `core/MIGRATIONS/D16-agent-skills.md`. |
| D17 | Delivery modes (added 2026-05-17) | **PM resolves one of three delivery modes per task** — **Mode 1** feature branch + PR (`git checkout -b <slug>`; commits on branch; Phase-8 `gh pr create` per `core/templates/pr-description.md` + `Closes #<N>` for issue-sourced) / **Mode 2** working-tree only (no commits; PM surfaces `git diff` at Phase 8; user commits / discards manually) / **Mode 3** commit-no-push (commits per batch on current branch; PM surfaces commit list at Phase 8; user pushes manually). **Approach C** — resolution by precedence: (1) per-task prefix `branch:` / `wt:` / `commit:` at start of task description (combinable with `auto:` per D12); (2) per-task user answer when PM asks at Phase 3; (3) adopter default from `local/framework.config.yaml § delivery.default-mode`; (4) framework default (`branch` for issue/TODO-sourced, `wt` for freeform). PM always reports the resolved mode at Phase 3 with a one-line override offer. **Auto-mode default = Mode 2 (wt)** — aligns with D12's "working-tree changes prepared but not committed" invariant; adopter can override. **Auto-mode delivery handoff Accept** branches per mode (push + PR / commit + push / push current branch). **Mode-discipline forbiddens** — never act outside the resolved mode; never silently switch mid-task; never auto-pick Mode 3 on `main`/`master`/`trunk` of multi-developer repos. Spec: `core/delivery-modes.md`. Migration: `core/MIGRATIONS/D17-delivery-modes.md`. |
| D19 | Backend coverage floor (added 2026-05-19) | **`backend-engineer` ships ≥ `unit-backend.coverage-threshold` line coverage on the changed + added line set** (`local/framework.config.yaml`, framework default `90`) for every backend source change. Tests **executed and pass** via `unit-backend.runner` before the engineer reports the iteration complete. **Option B** (per issue owner's comment) — hard threshold + SA-granted per-task waiver. Waivers documented in the PR description; never silent; never retroactive. Waivers allowed for: mechanical changes (rename / formatting / type-only), infrastructure-adjacent (DI registration, config binding), baseline-matching (project baseline below threshold). **Functionality-first ordering** — behavioural paths first, error / status-code branches second, edge / boundary third, wiring / DI plumbing last (smoke-only). Coverage chasing on getters / constructors / DI to hit the number while leaving real logic shallow violates the rule. **Exemptions** — DTOs / records / pure data types; generated code; configuration / option-binding classes (covered via integration tests). **No coverage tooling configured** → surface as discovery gap to `team-lead`; never silently lower the bar. Per-stack tools in `core/roles/backend-engineer.details.md § Coverage tooling`: `coverlet` (.NET) / `jest --coverage` (Node) / `pytest-cov` (Python) / `go test -cover` (Go) / `jacoco` (Java) / `simplecov` (Ruby) / `cargo-llvm-cov` (Rust). Failed run / sub-threshold = stoppable intermediate state per `core/iteration-protocol.md`. CI runs the same runner with the same threshold — no duplicate CI-only implementation. Closes [#29](https://github.com/kostiantyn-matsebora/ginee/issues/29). Migration: `core/MIGRATIONS/D19-backend-coverage-floor.md`. |
| D18 | DevOps script-quality obligation (added 2026-05-19) | **DevOps authors lint + unit tests + coverage for every devops-owned PowerShell / bash script change**, in the same task / same PR. Three deliverables — **Lint** (`PSScriptAnalyzer` / `shellcheck` — zero error-level findings on changed/added scripts; config beside scripts); **Unit tests** (`Pester *.Tests.ps1` / `bats-core *.bats` — every changed/added function or top-level branch covered); **Coverage** (`Invoke-Pester -CodeCoverage` / `bashcov` or `kcov` — line coverage on the **changed + added** line set ≥ `local/framework.config.yaml § devops-scripts.coverage-threshold`, framework default `90`). Authorship boundary moves from `qa-engineer` to `devops-engineer` for files in the devops-owned tree; QA retains seed / cleanup / smoke / scenario-harness ownership. Failed lint / failing tests / sub-threshold coverage = stoppable intermediate state per `core/iteration-protocol.md`, not a follow-up ticket. Data-only files exempt (`*.psd1` config manifests, generated files, fixture JSON). Scope is `changed + added` lines — untouched legacy not retroactively gated; optional `devops-scripts.coverage-grace: <until-date | issue-N>` declares a finite catch-up window. No-tooling-configured surfaces as a discovery gap to `team-lead`; rule never silently lowers the bar. CI runs the same gate at PR validation step 6 — local + CI invoke the same runners with the same threshold. Closes [#28](https://github.com/kostiantyn-matsebora/ginee/issues/28) + [#30](https://github.com/kostiantyn-matsebora/ginee/issues/30). Migration: `core/MIGRATIONS/D18-devops-script-quality.md`. |
| D20 | Automatic mode — post-PR CI watch (added 2026-05-19) | **Automatic mode + Mode 1 enters a synchronous CI-watch state after `gh pr create`** and runs an **iterate-fix-recheck loop** until all required checks are green OR a forced-handback trigger fires. Pre-D20 the orchestrator exited Phase 8 at "PR opened," forcing the human to copy-paste failure logs back into a new turn — that defeated automatic mode's single-delivery-handoff invariant. **Default policy `poll`** (synchronous polling inside the current turn) extends the handoff to "CI green." Three adopter alternatives: **`async`** (resume on next prompt), **`hybrid`** (synchronous probe for `ci-watch-sync-probe-minutes` then fall through to `async`), **`disabled`** (preserves pre-D20 behaviour). All four policies share the failure-classification + iterate-fix-recheck machinery; only the wait mechanism differs. **Failure classification** — attributable (`paths:` filter overlap / log cites changeset file / changeset test name), flake (regex corpus, adopter-extensible via `ci-flake-patterns`), or unattributable. Attributable → Phase 6 dispatch + push fix to same branch + re-enter watch (capped at `ci-watch-max-fix-cycles`, default `3`). Flake → one auto-rerun per cycle when `ci-auto-retry-flakes: true`. Unattributable / mixed → forced handback. **Forced-handback triggers** — unattributable failure / same check fails twice after fix / flake recurs after retry / `ci-watch-timeout-minutes` exceeded / `ci-watch-max-fix-cycles` reached / user interrupt / budget ceiling. **Notification surfaces** — at most three PR comments per fix cycle (`"CI watch started"` / `"CI fix pushed (cycle N of M)"` / `"CI complete — all green"`); no per-poll spam; optional `## CI status` placeholder in `core/templates/pr-description.md` updated only on exit-clean or final handback. **All-green definition** — `ci-required-checks: strict` (every reported check) or `branch-protection-aware` (only required checks per `gh api .../branches/<b>/protection`). **Latest-run-only** — `gh pr checks` reports latest CI run; stale check_run results never influence verdict. **Never auto-merge, never auto-approve, never auto-dismiss reviews, never edit changeset to mask a flake.** New keys under `local/framework.config.yaml § automatic-mode`: `ci-watch`, `ci-watch-policy`, `ci-watch-poll-seconds`, `ci-watch-timeout-minutes`, `ci-watch-sync-probe-minutes`, `ci-watch-max-fix-cycles`, `ci-required-checks`, `ci-auto-retry-flakes`, `ci-flake-patterns`. Affects D12 (auto-mode delivery handoff Accept extended), D14 (PR linkage gains CI-watch surface), D17 (Mode 1 finalize gains post-`gh pr create` step). Closes [#34](https://github.com/kostiantyn-matsebora/ginee/issues/34). Spec: `core/ci-watch.md`. Migration: `core/MIGRATIONS/D20-ci-watch.md`. |
| D21 | Context-economy enforcement gate (added 2026-05-19) | **Three layers mechanically enforce CLAUDE.md § Framework authoring — context economy on this repo's PRs.** Layer 1 — Claude Code PostToolUse hook (`.claude/settings.json.example`, copy → `.claude/settings.json`) runs the check after every Edit / Write / MultiEdit. Layer 2 — git pre-commit + pre-push hooks (`hooks/`, installed via `scripts/install-hooks.{ps1,sh}`) block local commits / pushes that breach. Layer 3 — GitHub Actions workflow (`.github/workflows/context-economy.yml`) is the final guardrail on PR; the `push: main` trigger was dropped after launch because GitHub's squash-merge strips the `Optimized-By: ai-engineer` trailer, producing false reds on main. **Shared check script** — `scripts/context-economy-check.ps1` (cross-platform pwsh 7+, no external deps beyond `git`). **Marker** — git trailer `Optimized-By: ai-engineer` on any commit in the PR range; threshold breach without the trailer fails the gate. **Thresholds** — 25 lines / 1 KB net-added for always-loaded files (`CLAUDE.md`, `PLAN.md`, `core/process.md`, `core/roles/*.md`); 50 lines / 2 KB for other watched (`core/*.md` specs, `core/roles/*.details.md`, `core/skills/**`, `core/templates/**`, `adapters/**`, `extras/roles/**`). **Structural lint** — flags non-bullet, non-table, non-code-fence, non-heading paragraphs with > 2 sentence terminators in always-loaded files (the D18–D20 regression signature). **Waiver** — PR label `context-economy:waived` + `**Context economy waiver:** <reason>` line in PR body; both required. **Activation** — `scripts/install-hooks.ps1` / `install-hooks.sh` drop hooks + Claude settings into place. Adopter-project doc enforcement is a separate concern (D22 governs that). Closes [#38](https://github.com/kostiantyn-matsebora/ginee/issues/38). Spec: `scripts/context-economy-check.ps1`. Migration: `core/MIGRATIONS/D21-context-economy-gates.md`. |
| D23 | Triage scoring — value × complexity priority (added 2026-05-20) | **`ginee-triage` ranks ready work by derived `score = value / complexity`** (default WSJF cost-of-delay over job-size). Two label namespaces — `value:high|medium|low` + `complexity:high|medium|low` — carry the data; labels are source-of-truth (queryable via `gh api`, mutable via `gh issue edit`, visible in GH UI, consistent with the `ginee:*` precedent from D14). **Option B** chosen over A (body-field regex; mutation requires body edit) and C (sidecar marker comments; noisy + most moving parts). **Scale = ATAM / utility-tree H/M/L** for both axes (Bass / Clements / Kazman, *Software Architecture in Practice*; matches ASR-scenario convention). Numeric mapping `H = 3, M = 2, L = 1` — yields a 9-cell matrix with `HL = 3.00` (highest priority quick-win), `HH = MM = LL = 1.00`, `LH = 0.33` (lowest); deterministic, no XS/S/M/L/XL / "critical" aliases. **Reporter sets `value`** at file-time (template label-picker or `gh issue create --label value:high`); the framework never auto-guesses user impact. **`solution-architect` auto-estimates `complexity`** on pickup when missing — ATAM-style signals: touched-file count (many → H), role count (N domains → H), novel concepts (novel → H), existing pattern reuse (reuse → L); result recorded as marker comment (`<!-- ginee:complexity-estimate by=solution-architect value=H -->`) + `complexity:high|medium|low` label. **Missing `value`** on pickup → `team-lead` asks user (H / M / L) before Phase 2; never auto-fills. **TODO-line equivalent** — inline marker `☐ [v:H c:L] Description` (case-insensitive); partial markers (`[v:H]` only / `[c:L]` only) handled; missing marker = score 0 (sorts last). **Sort key** — `Score DESC, Age DESC`; unscored bucket grouped at bottom (pre-D23 age-order preserved within bucket). **Adopter override** — `local/framework.config.yaml § triage.scoring-formula` accepts `value-over-complexity` (default) / `value-only` / `value-minus-complexity`. **Sticky score comment** (hybrid topology) — `team-lead` posts a `<!-- ginee:score v=1 -->` comment on pickup, one per issue, updated in place on every ginee-driven label change; immutable audit comments preserved alongside on key events (`<!-- ginee:complexity-estimate -->` from SA auto-estimate; `<!-- ginee:value-prompt -->` from the user-reply at pickup; `<!-- ginee:score-recompute -->` from explicit `@team-lead recompute score #<N>`). Table has 5 columns — Axis / Label / Numeric / Set by / Reasoning; `Reasoning` populated only for ginee-set rows (e.g. SA signals digest `1 file · 1 role · pattern reuse → L`), `—` for user-set, `unscored` for not-yet-set. **`@team-lead recompute score #<N>`** workflow re-reads current labels (catches manual `gh issue edit` between sessions) and refreshes the sticky + posts a score-recompute audit comment. **Labels auto-provisioned** by `team-lead` on first triage / pickup via `gh label create` (6 labels total — advisory colors, adopter may recolor; never recreated / overwritten). **Tests** — fulfilled by the worked-sort fixture in `core/triage-scoring.md § Examples`; no runtime `.ps1` / `.sh` helper ships (consistent with skill-as-markdown norm; would require pwsh / bash in every adopter env for a one-line ratio). **Forbidden** — never auto-set `value`; never overwrite existing `complexity:*` without surfacing; never gate pickup on score (informs order, not eligibility); never use any scale other than H/M/L. **Backward compatibility** — adopters with no scoring labels see "Unscored" listings matching pre-D23 age-order. Closes [#46](https://github.com/kostiantyn-matsebora/ginee/issues/46). Spec: `core/triage-scoring.md`. Migration: `core/MIGRATIONS/D23-triage-scoring.md`. |
| D22 | Doc-authoring protocol for adopter docs (added 2026-05-19) | **Promotes `core/process.md § Documentation style — structure over prose` from aspirational → binding for adopter outputs** (architecture doc, ADRs, CRs, READMEs, runbooks, scenarios, API docs). **Three-file load topology** designed to survive D37 (classical SA + per-engineer doc ownership) amplification — every cardinal will be a doc author on most tasks, so the protocol's load multiplies per role per task. The split: (1) `core/process.md § Documentation style` (always-loaded, +1.17 KB once globally) holds the binding declaration + default-shape map + 5 mandatory checks; (2) `core/doc-authoring-protocol.md` (2 KB, load-on-demand at Phase 5 / report-as-done) carries enforcement-via-discovered-stack + attestation format + out-of-scope; (3) `core/doc-authoring-examples.md` (5 KB, load on first-time authoring of a doc class / explicit request) holds 6 paired bad / good examples (component inventory / design properties / ADR rationale / runbook / API table / scenario). **No custom ginee lint** — adopter projects already configure markdown / prose tooling; ginee discovers it. `team-lead` records markdown-lint commands in `local/index/commands.yaml § commands.lint.docs` via the existing `builtin:commands` recipe; linter configs (markdownlint / vale / proselint / prettier-md) under `local/index/conventions.yaml` via `builtin:conventions`. Roles run `${commands.lint.docs}` at Phase 5 / report-as-done; output goes to phase report's Verification log. **No tool detected** → discovery report recommends a baseline (markdownlint structural + vale prose); adopter decides — never auto-install. **Attestation** — one-line entry in phase-report Verification log + PR-description Verification log. **Out of scope** — mass-restructure of legacy adopter docs (forward-only); style / tone / branding (this protocol governs structure only); framework-self-dev (D21 covers that). **Cross-issue coupling with #37** (classical SA Review) — when #37 lands, SA Review gains doc-style compliance as a hard-reject criterion; D22 ships TODO marker, no behaviour change. Closes [#39](https://github.com/kostiantyn-matsebora/ginee/issues/39). Migration: `core/MIGRATIONS/D22-doc-authoring-protocol.md`. |
| D24 | PR review-comment ingestion — skill + command parity (added 2026-05-22) | **`ginee-address-review` skill + `@team-lead address-review #<PR>` command — same 7-step procedure under same governance.** Sits between Phase 7 (internal SA review) and Phase 8 (user acceptance) for PRs exposed to **external** review (peer maintainers, OSS contributors, user-as-reviewer). Pre-D24 the framework had no protocol for this interval — no detection, no routing, no accountability, no comment cadence. **7-step procedure** (`core/github-integration.md § Review-comment ingestion`): (1) Resolve `<PR>` + verify checked-out branch == PR head; fetch `pulls/{N}/comments` + `/reviews`. (2) Deduplicate by `thread-id`; skip resolved + skip threads with current `<!-- ginee:review-reply r=<id> -->` marker AND no newer reviewer comment. (3) Build routing records per `local/bindings.md § Source-of-truth ownership`; fallback `team-lead`; ambiguous → surface-closest role. (4) Surface plan table — `# / thread / file:line / role / proposed action / action-type` — forced-interactive gate per `core/automatic-mode.md § Forced-interactive triggers` (push + reply on external PR = destructive/external set). (5) Dispatch specialists in parallel; each returns fix-track patch (Phase-6-shaped per `core/process.md`) OR reply-track text + marker. (6) Squash fix patches into one cycle commit + push; post per-thread replies with `<!-- ginee:review-reply r=<id> -->`. (7) Post sticky `<!-- ginee:review-cycle n=<N> -->` summary per `core/templates/pr-comment-cadence.md`. **Lossless coverage** — every plan-table thread → fix OR reply; no silent drops; same principle as `core/index-protocol.md § Lossless rule for index § Coverage rule`. **Idempotency** — re-invocation covers net-new + revisited threads only; cycle ordinal increments; prior stickies preserved (immutable log). **HTML markers** — two new prefixes (`ginee:review-reply r=<id>` per-thread, `ginee:review-cycle n=<N>` sticky); join existing D23 `ginee:score / value-prompt / complexity-estimate / score-recompute`. **Skill/command parity principle** — every user-invocable workflow ships both forms with identical behaviour; skill is a thin wrapper. Codifies what was implicit pre-D24 (pick-up / triage / promote / file / discovery / reindex / update already shipped both). **`auto:` mode (D12) — no exception** for "trivial" remarks (slope; explicit out-of-scope). **No `framework-` variant** — addressing a PR requires the working source at that branch. **No D20 CI-watch extension** — invocation is explicit only. **Comment cap** — 1 sticky per cycle, 1 reply per addressed thread per cycle, 0 mid-cycle chatter. **Adapter delta** — 4 install.md cheat-sheet rows; no install change (skill auto-bridges via existing copy step). **Skill count** 11 → 12 (D16 refreshed). **Out of scope** — drafting on others' PRs; auto-resolving threads; cross-repo; sentiment analysis; skill-only or command-only delivery (parity mandatory). **No `core/MIGRATIONS/D24-*.md`** — purely additive; cheat-sheet refresh is the only adopter-facing change. Closes [#53](https://github.com/kostiantyn-matsebora/ginee/issues/53). Spec: `core/github-integration.md § Review-comment ingestion`. Dispatch: `core/roles/team-lead.details.md § Review-comment dispatch`. Template: `core/templates/pr-comment-cadence.md`. Skill: `core/skills/ginee-address-review/SKILL.md`. |

---

## Appendix — gap analysis (working notes preserved)

| # | Gap | Resolution |
|---|---|---|
| G1 | Subagent capability varies per client and evolves rapidly. (Earlier draft assumed "agents are Claude Code only" — stale by early 2026.) | Vendor-neutral core + per-client adapters. Each adapter declares its **capability tier** based on current client state; tier assignments are revisited per release. On clients with native subagents, cardinals render as real subagents; on clients without, cardinals become personas the single LLM impersonates. Same process model, degraded execution path on tier-2/3. |
| G2 | "Maximally deterministic" against nondeterministic LLMs is overclaim. | Reframed as deterministic *process / templates / gates / artefact classes*. |
| G3 | "Self-learning" was undefined. | `team-lead` runs `discover`; output = `local/project-profile.md` + `local/bindings.md` + `local/framework.config.yaml`. |
| G4 | 5 fixed roles don't fit every project. | 7 cardinals stay (5 + PM + ai-engineer); `extras/` library + `local/roles/` extension covers specialisations. |
| G5 | "Reference, don't copy" needs an indirection layer. | `local/framework.config.yaml` maps concepts → project paths. |
| G6 | `CLAUDE.md` mixes generic process with project bindings. | Hard split: `core/process.md` (generic) ↔ `local/bindings.md` (per-project). |
| G7 | First-run onboarding undefined. | Defined: install → pointer line → `@team-lead run initial discovery`. |
| G8 | Update vs user customisation conflict. | Two-tier filesystem: `core/` replaced, `local/` survives. |
| G9 | Versioning + migrations. | SemVer in `core/VERSION`; migrations in `core/MIGRATIONS/`. |
| G10 | Conflict with existing project process docs. | Adopt mode default — pointer line only; no overwrite. |
| G11 | Discovery staleness over time. | Manual `rediscover` + PM auto-flag on profile mismatch. |
| G12 | Determinism across clients with very different capability. | Capability tiers (full subagents / single-agent personas / instructions-only) documented per client; same process model. |
