---
title: Changelog
description: "Release history."
permalink: /CHANGELOG.html
---

# Changelog

All notable changes to ginee. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); the framework adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## 0.11.0 — 2026-05-22

### Added

- **D26 — D22 scope extension to ginee-authored GitHub artefacts** ([#64](https://github.com/kostiantyn-matsebora/ginee/issues/64), [#65](https://github.com/kostiantyn-matsebora/ginee/pull/65)). D22 doc-authoring protocol previously scoped only adopter markdown. D26 extends to (a) GitHub issue bodies authored via `ginee-file-*` skills + (b) framework-authored comments — Phase-transition · sticky `ginee:score` / `ginee:review-cycle` · audit comments · per-thread review-replies.
  - **Same machinery as D22** — same 5 mandatory checks per `core/process.md § Documentation style § Mandatory checks before report-as-done`; same default-shape map (inventories → tables · steps → numbered lists · multi-rule prose → parent + sub-bullets).
  - **Lint covers every section, including Summary** — no section-by-length exemption. A one-sentence Summary still trips the mandatory checks if it packs a comma-separated inventory into a parenthetical clause.
  - **Enforcement** — LLM self-review embedded in the `ginee-file-*` skills + comment-cadence procedures. No external linter; no runtime dependencies. Violations surface as restructure suggestions in the user-approval prompt.
  - **Reporter-authored content unchanged** — D14 forbidden ("Never edit an issue body authored by another reporter") upheld. `ginee-pick-up` MAY surface a polite restructure advisory at pickup; never auto-edits.
  - **3 new bad/good example pairs** in `core/doc-authoring-examples.md` — Issue Summary (parenthetical-soup → bulleted scope) · Issue body section (semicolon-chained inventory → table) · Phase-transition comment (dense paragraph → structured transition).
  - **4 issue templates** under `core/templates/issues/` gain a D26 shape-rule banner at top.
  - **Adapter delta** — none (templates ship via existing `core/templates/issues/` copy step).
  - Migration: `core/MIGRATIONS/D26-doc-protocol-scope-extension.md`. Adopter action required: none — purely additive.

## 0.10.0 — 2026-05-22

### Added

- **D25 — Classical-architect SA model + doc-ownership redistribution** ([#37](https://github.com/kostiantyn-matsebora/ginee/issues/37), [#61](https://github.com/kostiantyn-matsebora/ginee/pull/61), [#62](https://github.com/kostiantyn-matsebora/ginee/pull/62)). `solution-architect` redefined from central-scribe + Phase-7-only sign-off to a **classical architect** with three activities across the whole lifecycle. Matches how real engineering teams operate (ginee's north star).
  - **Three activities.** **Design** — Phase 1 elicits FRs / NFRs / Constraints (`local/requirements.md`) + derives ASRs via ATAM utility tree (`local/asr-utility-tree.md`); Phase 2 authors target architecture; greenfield-vs-delta mode resolved at Phase 1. **Review** — any phase, on engineer-proposed architectural changes (contract / topology / stack / NFR-affecting); APPROVE / REJECT / REQUEST-CHANGES; no code edits. **Governance** — continuous, **scoped only to PRs touching SA-owned files** per `local/bindings.md § Source-of-truth ownership` (NOT every Phase 4 / 5 / 6 PR — keeps SA out of the bottleneck path).
  - **Two-file register split** — ASRs are an *outcome* of requirements, not the same level. `local/requirements.md` (FR / NFR / Constraints inputs) + `local/asr-utility-tree.md` (ASRs derived via ATAM). New templates: `core/templates/requirements-register.md` + `core/templates/asr-utility-tree.md`.
  - **Doc-ownership redistribution.** CRs · project-instruction file · work-breakdown → `team-lead` (coordination decisions, not architectural). CI/CD guide · infra runbooks · deployment guides → `devops-engineer`. Backend READMEs · API docs · service docs → `backend-engineer`. Frontend READMEs · component docs · style guides → `frontend-engineer`. Test plans · scenario docs · QA reports → `qa-engineer`. Architecture doc · ADRs · diagrams · requirements register · ASR utility tree stay with SA. Mockup unchanged. Every non-SA-owned doc edit is SA-reviewed for architectural coherence.
  - **`ai-engineer` counterpart generalized** — was SA ↔ ai-engineer pre-D25; now all-roles ↔ ai-engineer. `core/doc-co-ownership.md` **renamed** to `core/doc-roles.md` + rewritten.
  - **Process hooks** — `core/process.md § Phase 1 / 2 / 4 / 5 / 6 / 7` updated with SA hooks per the issue's phase-by-phase table. Phase 7 retained but **lighter** because governance ran continuously.
  - **CR template** moved from `solution-architect.details.md` → `team-lead.details.md` per the ownership reassignment. ADR template stays with SA.
  - **Adopter migration** — force re-attribution sweep on `@team-lead rediscover` (discovery Step 8c). Adopters MUST run rediscover on next upgrade; existing docs migrate to the new ownership map. Greenfield-flag detection added. New register files initialized from the discovered architecture doc when one exists. Full spec: `core/MIGRATIONS/D25-classical-architect.md`.
  - **All 5 adapter renderings refreshed** — `_shared/agents/{solution-architect,team-lead,ai-engineer,backend-engineer,frontend-engineer,devops-engineer,qa-engineer}.md` pointer files.
  - **User docs refreshed** ([#62](https://github.com/kostiantyn-matsebora/ginee/pull/62)) — `docs/CONCEPTS.md` (7-cardinal table + phased lifecycle + Source-of-truth ownership + new § Classical-architect SA model), `docs/GETTING_STARTED.md` (discovery + post-D25 rediscover callout), `docs/CHEATSHEET.md` (strict-domain + new § Classical-architect mini-block).

### Changed

- **CLAUDE.md § Hard constraints — binding `User-docs co-update` rule** ([#62](https://github.com/kostiantyn-matsebora/ginee/pull/62)). Every adopter-facing framework change (new skill · new D-decision · role-model change · new spec / template · new register / artefact) updates `docs/` (CONCEPTS · GETTING_STARTED · CHEATSHEET · index as applicable) **in the same PR**. Internal-only changes (D21 gate · CI internals · framework-dev hygiene · D18 script-quality · D19 backend-coverage) exempt. Phase-7 SA review verifies coverage. Codifies the recurring miss observed across pre-D25 feature PRs (#41 · #43 · #47 · #51 · #54 · #55 · #57) — backfilled in #59; binding from D25 onward.

## 0.9.0 — 2026-05-22

### Added

- **D24 — `ginee-address-review` skill / `@team-lead address-review #<PR>` command** ([#53](https://github.com/kostiantyn-matsebora/ginee/issues/53), [#57](https://github.com/kostiantyn-matsebora/ginee/pull/57)). PR review-comment ingestion under skill / command parity. Sits between Phase 7 (internal SA review) and Phase 8 (user acceptance) for PRs exposed to **external** review (peer maintainers, OSS contributors, user-as-reviewer). Pre-D24 the framework had no protocol for this interval — adopters briefed the orchestrator manually; no detection, no routing, no accountability, no comment cadence.
  - **7-step procedure** (`core/github-integration.md § Review-comment ingestion`) — resolve PR + verify checked-out branch == head; fetch `pulls/{N}/comments` + `/reviews`; deduplicate by `thread-id`; build routing records per `local/bindings.md § Source-of-truth ownership` (fallback `team-lead`; ambiguous → surface-closest role); surface consolidated plan table `# / thread / file:line / role / proposed action / action-type` for forced-interactive approval; dispatch specialists in parallel returning fix-track patches (Phase-6-shaped) or reply-track text + marker; squash fix patches into one cycle commit + push; post per-thread replies; post sticky cycle summary.
  - **Lossless coverage** — every plan-table thread MUST end the cycle as `fix` (patch landed) OR `reply` (text + marker). No silent drops. Same principle as `core/index-protocol.md § Lossless rule for index § Coverage rule`.
  - **Idempotency** — re-invocation rebuilds plan for net-new + revisited threads only; cycle ordinal increments; prior stickies preserved (immutable log).
  - **HTML markers** — two new prefixes (`<!-- ginee:review-reply r=<thread-id> -->` per-thread, `<!-- ginee:review-cycle n=<N> -->` sticky); join the D23 set (`ginee:score / value-prompt / complexity-estimate / score-recompute`).
  - **Skill / command parity principle** — codifies what was implicit pre-D24. Every user-invocable workflow ships both surfaces (skill in AgentSkills-capable clients; command in every adapter) with identical behaviour; skill is a thin wrapper loading the shared spec.
  - **`auto:` mode (D12)** — plan-table approval is a **forced-interactive trigger** per `core/automatic-mode.md § Forced-interactive triggers`. No exception for "trivial" remarks (slope; explicit out-of-scope).
  - **Explicit invocation only** — no extension of the D20 CI-watch loop; auto-detection of new review comments is out-of-scope.
  - **Adapter delta** — +1 cheat-sheet row per adapter (`claude` / `copilot-cli` / `agents-md` / `generic`). No install-script changes (skill auto-bridges via the existing `core/skills/` copy step).
  - **Skill count** — 11 → 12 (`docs/ARCHITECTURE.md` + CLAUDE.md D16 refreshed).
  - **Backward compatibility** — purely additive. No `local/` schema changes; no `core/MIGRATIONS/D24-*.md` (cheat-sheet refresh on next framework update is the only adopter-facing change).
  - **Out of scope** — drafting reviews on others' PRs; auto-resolving threads; cross-repo coordinated reviews; sentiment analysis; skill-only or command-only delivery.
  - Spec: `core/github-integration.md § Review-comment ingestion`. Dispatch: `core/roles/team-lead.details.md § Review-comment dispatch`. Template: `core/templates/pr-comment-cadence.md`. Skill: `core/skills/ginee-address-review/SKILL.md`.

## 0.8.0 — 2026-05-22

### Added

- **`ginee-update` skill — framework self-update via the orchestrator** ([#55](https://github.com/kostiantyn-matsebora/ginee/pull/55)). New uniform self-update surface for adopters. Triggers `@team-lead update [<tag|branch|sha>]` / *"update ginee"* / *"upgrade the framework"* / *"pull the latest ginee"* now load `core/skills/ginee-update/SKILL.md` and drive the existing `install.{ps1,sh} --update-only` flow — **no installer changes**. Preserves `local/`; refreshes `core/` + `adapters/` + `extras/`.
  - **7-step procedure** — locate framework → read current `core/VERSION` → resolve target ref (latest release / explicit tag / branch / SHA via `gh release view` with `iwr`/`curl` fallback) → compare versions (refuses downgrades unless `--allow-downgrade`) → **surface plan + wait for explicit user approval** (never auto-runs) → run installer per platform → report VERSION delta + CHANGELOG range + new `core/MIGRATIONS/*.md` files with their `Action required` excerpts.
  - **Post-update report** also diffs `local/index/manifest.yaml` SHA-256s against the freshly fetched `core/` — surfaces drift; offers `ginee-reindex` per the standard staleness flow (never auto-reindexes).
  - **Forbiddens** — never auto-run; never edit `local/*`; never mask installer failure (surfaces exit code + last 20 lines of stderr; no retry); never bypass an adopter's pinned `--ref` in `local/framework.config.yaml § framework.pinned-ref` without confirming.
  - **Cross-client coverage** — activation rows added to all four adapters (`claude` / `copilot-cli` / `agents-md` / `generic`) + `adapters/claude/CLAUDE-pointer.md` workflow list.
  - **Backward compatibility** — manual `./install.{ps1,sh} --update-only` continues to work unchanged. Adopters opt in by refreshing the framework once via the existing path (so the skill lands); future updates flow through the skill.
  - **Skill count** — 10 → 11 across CI workflow, `docs/ARCHITECTURE.md`, `docs/CHEATSHEET.md`, and the Claude pointer block.
  - Migration: `core/MIGRATIONS/ginee-update-skill.md`.

## 0.7.0 — 2026-05-21

### Changed

- **`ginee-reindex` reconciles index with current repo state** ([#49](https://github.com/kostiantyn-matsebora/ginee/issues/49), [#52](https://github.com/kostiantyn-matsebora/ginee/pull/52)). `@team-lead reindex [scope]` (and the `ginee-reindex` skill) now reconciles `local/index/` against the current repo state at the chosen scope via **three sweeps** instead of refusing every source not already in the manifest:
  - **Sweep 1 — SHA drift.** Re-extract on change for every in-scope manifest entry.
  - **Sweep 2 — new files.** For every in-scope class, list files matching its `source-glob`; any not yet in the manifest gets added + extracted with the class recipe.
  - **Sweep 3 — stale entries.** Manifest entry whose `source` no longer exists → prompt the user with `remove?`. **Never auto-deleted.**
  - **Scopes.** `reindex` (no arg) = whole repo; `reindex <file>` = the file's matching class only; `reindex <class>` = one class's `source-glob` only.
  - **Drops both skill forbiddens** that previously routed adopters to the heavier `ginee-rediscover` for net-new files — `reindex` now does what its name implies.
  - **Novel-class detection remains a `rediscover` responsibility** (sources matching no class glob — touches `project-profile` + `bindings` + may need consumer-coupling input).
  - **Backward compatibility** — manifest schema unchanged; `reindex <file-already-in-manifest>` continues to behave as before. No adopter migration action required.
  - Spec: `core/index-protocol.md § Reconciliation` (renamed from `§ Re-extraction`). Migration: `core/MIGRATIONS/reindex-reconcile.md`.

- **`team-lead` strict-domain hardening — close "feels fast → I'll just do it" bypass** ([#50](https://github.com/kostiantyn-matsebora/ginee/issues/50), [#51](https://github.com/kostiantyn-matsebora/ginee/pull/51)). Closes an observed regression where the orchestrator self-executed specialist-owned work on a "feels fast" heuristic — 5–7 min estimates ballooning into ~60 min main-thread sessions with no stop-and-report. Kernel + protocol wording now names the failure mode and blocks it.
  - **`core/roles/team-lead.md § Forbidden actions`** — new bullet: *"Never self-execute work in a specialist-owned surface, regardless of estimated size."* Includes the correct dispatch shape for ≤ 15 min work (explicit estimate flag → iteration-protocol load skipped).
  - **`core/process.md § Dispatch & parallelism rules`** — new row: *"Surface owns the dispatch decision"* — routing is owned by the touched surface, not by perceived effort.
  - **`core/process.md § Strict-domain rule`** — *"Size is not an exemption"* sub-bullet + pointer to the failure-modes catalogue.
  - **`core/iteration-protocol.md § Stoppable intermediate states`** — new `### Scope-overrun trigger` sub-section: > 2× initial estimate → mandatory stop-and-report. Applies symmetrically to specialists and orchestrator in-thread work.
  - **`core/roles/team-lead.details.md § Common failure modes`** — new regression-grade catalogue of observed orchestrator violations + correct dispatch shape per pattern.
  - **Adopter action** — none. Clarifications to existing rules; all changes additive. No config / API / surface change.
  - Migration: `core/MIGRATIONS/team-lead-strict-domain-hardening.md`.

## 0.6.0 — 2026-05-20

### Added

- **D23 — Triage scoring (value × complexity priority)** ([#46](https://github.com/kostiantyn-matsebora/ginee/issues/46), [#47](https://github.com/kostiantyn-matsebora/ginee/pull/47)). `ginee-triage` now ranks ready work by `score = value / complexity` (default WSJF cost-of-delay over job-size) instead of age alone. ATAM utility-tree convention on both axes — `value:high|medium|low` + `complexity:high|medium|low` label namespaces; numeric mapping `H=3, M=2, L=1` yields a 9-cell matrix (`HL=3.00` quick-win at the top, `LH=0.33` at the bottom). Source-of-truth = labels (queryable via `gh api`, mutable via `gh issue edit`, GH-native — reuses the `ginee:*` precedent from D14). 6 labels auto-provisioned by `team-lead` on first triage / pickup; advisory colors, adopter may recolor.
  - **TODO equivalent** — inline marker `☐ [v:H c:L] Description` (case-insensitive). Partial markers (`[v:H]` only / `[c:L]` only) handled; missing marker = score 0 (sorts last).
  - **`solution-architect` auto-estimates `complexity`** on pickup when missing — ATAM signals (touched-file count, role count, novel concepts vs existing pattern reuse). `value` is never auto-estimated — `team-lead` asks the user.
  - **Sticky `<!-- ginee:score v=1 -->` comment** per issue (hybrid topology) — `team-lead` posts on pickup, updates in place on every ginee-driven label change. 5-column table (Axis / Label / Numeric / Set by / Reasoning); `Reasoning` populated only for ginee-set rows (e.g. SA signals digest `1 file · 1 role · pattern reuse → L`), `—` for user-set, `unscored` for not-yet-set.
  - **Immutable audit comments** preserved alongside on key events — `<!-- ginee:complexity-estimate -->` (SA auto-estimate), `<!-- ginee:value-prompt -->` (user reply at pickup), `<!-- ginee:score-recompute -->` (explicit refresh).
  - **New trigger** `@team-lead recompute score #<N>` — re-reads current labels (catches manual `gh issue edit` between sessions), refreshes the sticky, posts a score-recompute audit comment with reason + delta.
  - **Adopter override** — `local/framework.config.yaml § triage.scoring-formula` accepts `value-over-complexity` (default) / `value-only` / `value-minus-complexity`.
  - **Backward compatibility** — adopters with no scoring labels see "Unscored" listings matching pre-D23 age-order. Untagged TODOs continue to work unchanged.
  - **Tests** — fulfilled by the worked-sort fixture in `core/triage-scoring.md § Examples`; no runtime `.ps1` / `.sh` helper ships (consistent with skill-as-markdown norm).
  - Spec: `core/triage-scoring.md`. Migration: `core/MIGRATIONS/D23-triage-scoring.md`.

## 0.5.1 — 2026-05-19

### Changed

- **Trimmed CLAUDE.md decision-register rows D17–D22** ([#36](https://github.com/kostiantyn-matsebora/ginee/issues/36), [#44](https://github.com/kostiantyn-matsebora/ginee/pull/44)). Six rows that had drifted into 650–1396-char prose paragraphs inlined into the always-loaded table are now ~250-char one-line pointers, sorted numerically. **Savings: CLAUDE.md −3.03 KB** (20.38 KB → 17.34 KB). Full prose retained in `PLAN.md § D17`–`§ D22` + per-decision `core/MIGRATIONS/D{17,18,19,20,21,22}-*.md` (load-on-demand). Adds D21 + D22 canonical-long-form rows to `PLAN.md` (previously missing — shipped straight into CLAUDE.md).
- **D21 — PLAN.md reclassified from "always-loaded" to "other watched"** in the context-economy gate. PLAN.md is the canonical design doc, read at session start but not auto-loaded by the harness on every dispatch (per #36 framing). Threshold relaxes from 25 lines / 1 KB to 50 lines / 2 KB. +1 Pester regression test.

## 0.5.0 — 2026-05-19

### Added

- **D22 — Doc-authoring protocol for adopter docs** ([#39](https://github.com/kostiantyn-matsebora/ginee/issues/39), [#42](https://github.com/kostiantyn-matsebora/ginee/pull/42)). Promotes `core/process.md § Documentation style — structure over prose` from aspirational → **binding** for adopter outputs (architecture doc, ADRs, CRs, READMEs, runbooks, scenarios, API docs).
  - **Three-file load topology** (anticipates upcoming #37 amplifying per-role doc authorship):
    - `core/process.md § Documentation style` (always-loaded, +1.17 KB once globally) — binding declaration + default-shape map + 5 mandatory checks.
    - `core/doc-authoring-protocol.md` (2 KB, load-on-demand at Phase 5 / report-as-done) — enforcement-via-discovered-stack + attestation format + out-of-scope.
    - `core/doc-authoring-examples.md` (5 KB, load on first-time / explicit request) — 6 paired bad / good examples (component inventory / design properties / ADR rationale / runbook / API table / scenario).
  - **No custom ginee lint.** Enforcement piggybacks on adopter tooling — `team-lead` discovery records markdown / prose linters (markdownlint, vale, proselint, prettier-md) via the existing `builtin:commands` + `builtin:conventions` recipes; roles run `${commands.lint.docs}` at Phase 5 / report-as-done. No-tool fallback recommends a baseline; adopter decides — never auto-install.
  - **Attestation** — one-line entry in phase-report Verification log + PR-description Verification log.
  - Cross-issue: hard-reject coupling with #37 (classical SA Review) deferred until #37 lands; TODO marker in migration note.
  - Spec + migration: `core/MIGRATIONS/D22-doc-authoring-protocol.md`.

### Fixed

- **D21 gate — `.details.md` mis-classification.** `Test-IsAlwaysLoaded` regex `^core/roles/[^/]+\.md$` was greedily matching `core/roles/*.details.md` as always-loaded; details files are now correctly classified as "other" tier. Regression test added.
- **D21 gate — YAML frontmatter false positives.** `Invoke-StructuralLint` was flagging every role kernel's `description:` field as a multi-sentence prose paragraph. Now skips the leading `---...---` frontmatter block. Regression test added.

## 0.4.0 — 2026-05-19

### Added

- **D21 — Context-economy enforcement gate** ([#38](https://github.com/kostiantyn-matsebora/ginee/issues/38), [#40](https://github.com/kostiantyn-matsebora/ginee/pull/40)). Three layers mechanically enforce the `CLAUDE.md § Framework authoring — context economy` rule on this repo's PRs:
  - Claude Code PostToolUse hook (`.claude/settings.json.example`, copy → `.claude/settings.json`).
  - Git `pre-commit` + `pre-push` hooks (`hooks/`, installed via `scripts/install-hooks.{ps1,sh}`).
  - GitHub Actions CI workflow (`.github/workflows/context-economy.yml`).
  - Shared check script: `scripts/context-economy-check.ps1` (cross-platform, no external deps beyond `git`).
  - Marker: git trailer `Optimized-By: ai-engineer` on any commit in PR range; waiver = PR label `context-economy:waived` + `**Context economy waiver:** <reason>` line in body.
  - Thresholds: 25 lines / 1 KB for always-loaded files (`CLAUDE.md`, `PLAN.md`, `core/process.md`, `core/roles/*.md`); 50 lines / 2 KB elsewhere.
  - Structural lint catches prose paragraphs with > 2 sentences in always-loaded files — the D18–D20 regression signature.
  - 28 Pester tests, 92.7% line coverage (> D19's 90% floor), PSScriptAnalyzer clean.
  - Spec + migration: `core/MIGRATIONS/D21-context-economy-gates.md`.
- **Repo went public** at [github.com/kostiantyn-matsebora/ginee](https://github.com/kostiantyn-matsebora/ginee). Documentation site live at [kostiantyn-matsebora.github.io/ginee](https://kostiantyn-matsebora.github.io/ginee/). Default install path is now anonymous — no GitHub auth required to fetch the framework.
- **Public OSS release prep** — `LICENSE` (MIT), `SECURITY.md`, `.github/CODEOWNERS`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/ISSUE_TEMPLATE/*.yml`.
- **Documentation site** under `docs/` — Jekyll cayman theme with indigo + amber palette, custom layout, theme toggle, page TOC.
- **Index protocol — per-file load triggers** (issue #11). Cardinal role `## Source of truth` tables gain a `Load when` column. Two-tier model: `always` for foundational reads + scope-loaded with trigger phrase. Specialist reports loaded set in first response. Adopter overrides via new `local/bindings.md § Per-role load-trigger overrides`.
- **Index protocol — consumer coupling** (issue #10). Every extracted class declares `consumed-by: [<role>...]` in `manifest.yaml`. Novel classes without a declared consumer are not extracted; discovery report flags any dormant index. New `local/bindings.md § Project-specific index citations` section wires novel classes to cardinal roles without editing upstream kernels.
- **Installer auto-migration** — `install.ps1` / `install.sh` detect pre-rebrand `.agents/engineering-team/` and rename to `.agents/ginee/` on first run, preserving `local/` contents.

### Changed

- **Installer: hybrid release-tarball + git-clone fetch path.** Default `--ref` changes from `main` to `latest` — resolves to the most recent published release via the `/releases/latest` HTTP redirect, downloads the release tarball, verifies SHA256 against the published `SHA256SUMS.txt`, then unpacks. No `git` required for tagged-release installs (the common path). `--ref main` / `--ref <branch>` / `--ref <sha>` still fall back to `git clone --depth 1 --branch <ref>` (requires `git` on PATH). Forks (`--repo` override) always use `git clone`. Each external operation emits a `>> ...` step banner; on failure, a structured dump of Ref / Target / RepoUrl / Adapter / PSVersion / cwd surfaces so future failures are diagnosable from the console alone. Fixes [adopter-reported "filename, directory name, or volume label syntax is incorrect" error](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/MIGRATIONS/installer-tarball-path.md) on Windows PowerShell, plus two related `install.ps1` issues — `param()` scope-leak under `iex` (pre-existing `$Ref` / `$Target` / `$Adapter` in caller scope defeated the defaults) and provider-prefixed `(Get-Location).Path` values that `git.exe` couldn't parse. Migration: `core/MIGRATIONS/installer-tarball-path.md`.
- **Release pipeline: extended exclude list** in `release.yml` rsync step. Tarballs cut from the next release onward ship "ready to use" — no install-time pruning needed for tag-sourced installs.
- **Orchestrator renamed: `project-manager` → `team-lead`.** Better matches the ginee tagline *"an AI software engineering team that behaves like a real one"* — engineering teams have team leads, not project managers. `project-manager` retained as a permanent alias alongside `orchestrator`; existing `@project-manager` dispatches continue to route unchanged. Files renamed: `core/roles/project-manager.md` → `team-lead.md` (+ `.details.md` counterpart) + `adapters/_shared/agents/project-manager.md` → `team-lead.md`. Installer auto-deletes the stale `.claude/agents/project-manager.md` / `.github/agents/project-manager.agent.md` pointer on `--update-only`. Migration: `core/MIGRATIONS/project-manager-renamed-team-lead.md`.
- **Installer + README simplified** for the public release. Removed "private repo" caveats + auth prerequisites; one-liner install is now the canonical path. `--repo` / `-RepoUrl` parameter retained for forks + local-checkout testing but no longer surfaced as the default workflow.
- **Rebrand: `engineering-team` → `ginee`** across all framework artefacts. D11 revised — `ginee` is now the formal public name (formerly the codename). Skill prefix `ginee-` is now consistent at every surface. Install path `.agents/engineering-team/` → `.agents/ginee/`. Env vars `ET_*` → `GINEE_*`. Tagline: *An AI software engineering team that behaves like a real one. Drops into your project, self-onboards, and gets to work.*
- **Index protocol — compression floor** (issue #9). New `§ Compression floor` sub-rule: `index-bytes / source-bytes ≥ 0.5 = recipe failed`. Remedies: rewrite recipe to drop bulk, or mark class `read-source-directly`. Per-class targets: ≤ 0.15 prose, ≤ 0.25 list-of-records, ≤ 0.15 structured-config inventory. Lossless rule clarified — coverage is about *existence-entries* (name + source-anchor), not *fidelity*. Full metadata stays in source.
- **D15 code-category recipes rewritten** (issue #9). `builtin:package-manifest` and `builtin:container-orchestration` now record inventory only (existence + anchors). Per-service ports / depends_on / replicas / resources / env-vars stay in compose / Helm / k8s source; per-dep listing stays in the manifest source.
- **Manifest schema extended** — entries gain `source-bytes`, `index-bytes`, `compression`, `consumed-by` fields.
- **`core/templates/bindings.md § Source of truth (read before any work)` renamed to `§ Source-of-truth ownership`** (issue #7). Section reframed as a governance / who-edits-what map. Raw doc paths no longer surface as a competing "read first" tier — `local/index/*` is the only default read surface.

### Fixed

- **D21 gate skips `push: main` post-merge.** GitHub's squash-merge strips the `Optimized-By: ai-engineer` trailer (only the PR title + `Co-authored-by` survive), so post-merge runs on `main` were producing false reds. The gate is now strictly a pre-merge `pull_request` check; direct-to-main pushes are out of scope for the gate (branch protection is the right tool).
- **Installer `-UpdateOnly` mode** now correctly re-fetches `core/`, `adapters/`, `extras/` after wiping them.
- **Installer skill copy on update** — existing `ginee-*` skill directories are cleared before re-copying (previously failed with "directory already exists").

## 0.1.0 — initial dogfood baseline

### Added

- **7 cardinal roles** (`project-manager`, `solution-architect`, `ai-engineer`, `frontend-engineer`, `backend-engineer`, `devops-engineer`, `qa-engineer`) with generic aliases.
- **Phase 1–8 lifecycle** in `core/process.md` — analysis / design / review / implementation / testing / bug fixing / SA review / user approval.
- **4 adapters** — `claude` (tier-1), `copilot-cli` (tier-1), `agents-md` (tier-2), `generic` (tier-3).
- **5 opt-in specialists** under `extras/roles/` — security · ml · mobile · sre · data.
- **`local/` layer** — `project-profile.md`, `bindings.md`, `framework.config.yaml`, `roles/`, `index/`. Survives framework updates.
- **Discovery flow** — `project-manager` writes `local/*` on first run; detects stack / architecture-doc / mockup / ADR / CR / scenario layout.
- **Index protocol (D13)** — extracted summaries under `local/index/`; SHA-256 staleness; doc-category recipes.
- **Code-derived index extension (D15)** — code/config sources added via `stack.yaml` / `topology.yaml` / `commands.yaml` / `conventions.yaml` / `runtime-facts.yaml` / `repo-map.idx`.
- **GitHub issues integration (D14)** — file / pick up / triage / promote workflows. Native `open`/`closed` + `ginee:*` labels. PR auto-close via `Fixes #N`.
- **AgentSkills (D16)** — 10 skills under `core/skills/ginee-*/SKILL.md`. Cross-client via per-adapter bridge.
- **Delivery modes (D17)** — Mode 1 (branch + PR) / Mode 2 (working-tree only) / Mode 3 (commit-no-push). Resolved by per-task prefix → Phase-3 answer → adopter default → framework default.
- **Automatic mode (D12)** — `auto:` per-task prefix elides intermediate gates; Phase 8 becomes a single Accept / Feedback / Reject delivery handoff.
- **17 locked decisions** documented in `PLAN.md`.
- **Iteration protocol** — estimation-first dispatch + 3–5 min stoppable batches for work &gt; 15 min.
- **Strict-domain rule** — forbidden role-crossings per `local/bindings.md § Project role boundaries`.
- **Cross-domain bugs** procedure in `core/cross-domain-bugs.md` — propose → implement → verify cycle.
- **Cross-agent hand-off** procedure in `core/cross-agent-handoff.md` — diagnose ≠ fix.

### Notes

This release represents the dogfood baseline used during the framework's own development. The first public-OSS-ready release will be tagged after the rebrand to `ginee` lands.
