---
title: Changelog
description: "Release history."
permalink: /CHANGELOG.html
---

# Changelog

All notable changes to ginee. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); the framework adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Fixed

- **Skill-runner tracking-mode posture leak — D28 boundary + D39 resolution chain gap** ([#114](https://github.com/kostiantyn-matsebora/ginee/issues/114)). Pre-fix the load-bearing runtime specs (`core/process/dispatch.md § Skill-runner — surface boundary` · `core/github-integration.md § Sub-issue dispatch`) enumerated orchestration ops as plan / synthesis / gate text / re-dispatch / reconciliation / default selection / `local/bindings.md` lookup — but did **not** name tracking-mode posture. Skill-runner read the silence as permission, pre-resolved tracking to `in-context` from runtime conditions (deferred commits · worktree mode · no-PR linkage), and wrote the posture into the hand-off brief. Team-lead absorbed the line verbatim into Phase 1 "Forbidden this cycle"; three Phase 4 dispatches ran in-context with no sub-issues, no `<!-- ginee:dispatch-map -->` sticky, no per-cardinal time accounting, and a permanently unusable D39 resume protocol on that parent. Rules land in files the LLM actually loads at runtime — not in version-bound migration files that ship as switch-version instructions.
  - **Skill-runner surface boundary** (`core/process/dispatch.md`). New D39 interaction paragraph parallel to the existing D29 one — explicit *"never set, carry, or pre-resolve tracking-mode posture"* rule with the runtime-condition orthogonality clause. Forbidden-ops table row adds *tracking-mode posture (D39-sub-issue-dispatch four-tier resolution)*.
  - **Resolution chain closure** (`core/github-integration.md § Sub-issue dispatch`). New `**Chain is closed — team-lead re-derives on every parent dispatch.**` paragraph below the existing Resolution line. States no fifth tier exists; skill-runner never sets / recommends / carries posture; team-lead re-derives on every parent dispatch (initial pickup + cross-session resume); upstream postures discarded without inheritance; runtime conditions orthogonal; only adapter degradation demotes tier 4.
  - **Authoring failure mode** (`core/roles/team-lead.details.md § Sub-issue dispatch § Common failure modes`). New table row — *"Skill-runner-injected tracking-mode posture absorbed verbatim"* with the correct shape (discard + re-derive via chain). Pairs with the existing in-context-despite-sub-issue-mode-active row.
  - **Skill-runner forbiddens** (`core/skills/ginee-pick-up/SKILL.md`). § Forbidden D28 line extended — tracking-mode posture in the hand-off payload now explicitly listed alongside plan-drafting / synthesis / routing / default-selection.
  - **Files updated** — `core/process/dispatch.md` · `core/github-integration.md` · `core/roles/team-lead.details.md` · `core/skills/ginee-pick-up/SKILL.md` · this file. **Migration files unchanged** — D28-skill-runner-boundary.md and D39-sub-issue-dispatch.md are version-switch instructions, not load-bearing runtime context.
  - **Backwards compatibility** — purely additive. No `local/` schema change. No `framework.config.yaml` additions. No new D-number (clarification to existing D28 + D39 runtime specs). Adopter action: **none**. Existing in-flight tasks with skill-runner-injected postures finish as today; the rule binds on the **next** parent dispatch under any issue.

## 0.17.0 — 2026-05-24

### Added

- **D41 — Pre-implementation blueprint-diff gate for visual source-of-truth** ([#111](https://github.com/kostiantyn-matsebora/ginee/issues/111)). Adds a Phase 4 entry precondition for any dispatch touching the configured `visual-source-of-truth.path` — structural diff vs `blueprint-ref` (default `origin/main`), classification of every delta as Expected / Unexpected / Pre-existing, surface to team-lead before edits begin. Closes the adopter-incident class proven on `kostiantyn-matsebora/deployment-dashboard#54` — Phase 4 silently rewrote a mockup section from scratch; chrome elements (status badge · version-block · timestamps · prev-failed warning · lastSuccessful row) vanished; Phase 5/6 geometry oracles ran green across four bug-fix iterations; user caught it via manual screenshot comparison only.
  - **Form — Option B** (Phase 4 first-step in role dispatch). Rejected Option A (Phase 3 gate addition — regression slipped at Phase 4 start, not at design review). Rejected Option C (new Phase 3.5 lifecycle phase — bloats the 8-phase model for a check that fits cleanly as a Phase 4 dispatch precondition). Option B matches the established protocol pattern — D22 / D26 / D29 / D30 / D40 all use load-on-demand specs with N mandatory checks + LLM self-review + one-line orchestrator advisory.
  - **Configuration.** New `local/framework.config.yaml § visual-source-of-truth` block — `type` (html-mockup · figma · image · video · other) · `path` · `blueprint-ref` · `scope-discriminator` · `enabled`. All keys optional; framework defaults derive from existing `mockup:` key when present.
  - **Per-type diff tools.** `html-mockup` → `git diff <blueprint-ref> -- <path>` (universal); `figma` → file-comparison URL or REST `GET /v1/files/<key>/versions`; `image` → adopter-supplied perceptual diff (pixelmatch · odiff · Resemble.js · Playwright snapshot-compare); `video` → manual review checkpoint; `other` → adopter-supplied tool from `local/index/commands.yaml § commands.visual-diff`.
  - **Procedure.** Resolve config → compute diff → classify each entry (Expected / Unexpected / Pre-existing) → surface to team-lead → gate Phase 4 edits. All-Expected/Pre-existing → edits proceed; any Unexpected → forced-interactive gate (auto-mode does NOT elide; same carve-out as D24).
  - **4 mandatory checks** before edits begin — config resolved · diff computed · classification complete · surface logged in `## Verification log`. LLM self-review against these four; orchestrator one-line advisory on violation.
  - **Adopt-vs-build (D30).** Diff tooling layer adopts existing tools per type (`git diff`, Figma compare, pixelmatch / odiff). Protocol layer is build — `(none viable — surveyed Conftest/Rego, Spectral, htmlhint; none ship a markdown-spec-driven pre-edit blueprint-diff gate for multi-agent workflows)`.
  - **Decisions affected** — D12 (forced-interactive on unexpected delta) · D14 (issue body drives Expected classification) · D17 (mode-independent) · D22 (doc-shape applies to surrounding return text) · D25 (mockup-owning role gains diff-and-surface obligation) · D29 (Verification-log row example added; no new section) · D30 (per-type adopt + protocol-layer build) · D36 (warm-resumed specialist re-runs on each new dispatch) · D39 (sub-issue closing comment's `## Verification log` carries the outcome).
  - **Files updated** — `core/protocols/blueprint-diff-protocol.md` (NEW, full spec) · `core/MIGRATIONS/D41-blueprint-diff-gate.md` (NEW) · `core/templates/framework.config.yaml` (`visual-source-of-truth:` block) · `core/process/phase-4-implementation.md` (entry precondition rule) · `core/roles/frontend-engineer.md` (Mockup-ownership trigger row) · `core/templates/phase-report.md` (Verification-log row example) · `core/process.md` (load-on-demand index entry) · `CLAUDE.md` + `PLAN.md` (D41 row) · `.github/release-notes/v0.17.0.md` (NEW) · `docs/CONCEPTS.md` + `docs/CHEATSHEET.md` (adopter-facing co-update).
  - **Backwards compatibility** — purely additive. New `visual-source-of-truth:` block defaults derived from existing `mockup:` key — adopters with mockup configured get the protocol on next dispatch without manual config edits. Adopters with no mockup configured — protocol auto-skips with cite `"visual-SoT untouched — protocol n/a"`. No script changes. No installer change. No test changes. Adopter action on upgrade: **none** (override patterns optional).
  - Migration: `core/MIGRATIONS/D41-blueprint-diff-gate.md`.

## 0.16.0 — 2026-05-24

### Added

- **D39 — Sub-issue dispatch — cross-session traceability + time-tracking** ([#106](https://github.com/kostiantyn-matsebora/ginee/issues/106)). Pre-D39 every `team-lead` → cardinal dispatch lived only in the chat transcript — session end = state evaporated; next-day pickup reconstructed from PR diffs + scattered commit messages. On issue-sourced tasks team-lead now creates one GitHub sub-issue per cardinal dispatch under the parent.
  - **Lifecycle.** Title `[<phase>:<cardinal>] <task>`; body per `core/templates/sub-issue-dispatch.md`; labels `ginee:role:*` + `ginee:phase:*` + inherited `value:*`/`complexity:*`. Cardinal posts progress comments carrying `time:` + `cumulative:`; D29 phase-report return doubles as the closing comment with mandatory `## Time spent`. Stop-state (`Status: In-progress`) → progress comment; sub-issue stays open. Parent sticky `<!-- ginee:dispatch-map -->` aggregates per-cardinal rollup.
  - **Assignee precedence** (per issue #106 owner comment) — non-empty human assignee overrules the `ginee:role:*` tag; cardinal suspended until cleared. Rationale: GitHub's assignee column means a human is responsible; cardinals are not GitHub users; when both exist, the human (visible accountability) wins.
  - **Opt-out resolution** — `notrack:` task prefix → `ginee:track:off` parent label → `local/framework.config.yaml § dispatch.tracking` → framework default (`sub-issues` on `github.repo`). TODO / freeform / no-`gh` adapters fall back to in-context.
  - **Resume across sessions** — parent + open sub-issues = full state; D36 registry is in-conversation only, sub-issue history bridges the cross-session gap.
  - **Decisions affected** — D14 (sub-issue surface gains dispatch-create) · D26 (sub-issue artefacts subject to 5-check self-lint) · D29 (conditional `## Time spent` section) · D33 (marker on closing comment) · D34 (slug-glued IDs in titles) · D35 (lifecycle lands in `core/process/dispatch.md`) · D36 / D17 (compatible).
  - **Files updated** — `core/MIGRATIONS/D39-sub-issue-dispatch.md` (NEW) · `core/templates/sub-issue-dispatch.md` (NEW) · `core/github-integration.md § Sub-issue dispatch` (NEW section) · `core/process/dispatch.md` (new rule row) · `core/roles/team-lead.md` (kernel bullet) · `core/roles/team-lead.details.md § Sub-issue dispatch` (NEW — authoring procedure + failure modes) · `core/templates/phase-report.md` (conditional `## Time spent` + in-flight cadence reference) · `core/templates/framework.config.yaml` (`dispatch.tracking:` block) · `CLAUDE.md` + `PLAN.md` (D39 row) · `docs/CHEATSHEET.md` + `docs/CONCEPTS.md` + this file.
  - **Backwards compatibility** — purely additive. New optional `dispatch.tracking:` key in `local/framework.config.yaml`; absent ⇒ default `sub-issues` on `github.repo`-configured adopters. Pre-existing in-flight tasks unchanged; sub-issue mode activates on the **next** dispatch under that parent. Adopters wanting legacy behaviour set `dispatch.tracking: in-context` once.
  - Migration: `core/MIGRATIONS/D39-sub-issue-dispatch.md`.

- **D40 — Changelog + release-notes protocol** ([#81](https://github.com/kostiantyn-matsebora/ginee/issues/81)). Codifies surface-specific voice + shape rules for the three release-surface files (`docs/CHANGELOG.md` · `.github/release-notes/v*.md` · `core/MIGRATIONS/D<N>-*.md`). Closes a recurring drift mode — pre-D40 no spec bound these surfaces to surface-specific voice + word-count rules; the v0.12.0 sidecar took 4 authoring passes to converge.
  - **Topology.** Three surfaces, three voices, three caps. Migration spec — framework-dev voice, no cap. CHANGELOG — verbose record per Keep-a-Changelog; lead-in ≤ 25 words + sub-bullets. Release-notes sidecar — user-value voice, ≤ 20 words per bullet, `(D<N>)` tag suffix.
  - **Voice rule.** Sidecar bullets lead with the adopter-visible verb / outcome — *"`/ginee-update` works again"* not *"Step 1 no longer requires installer scripts inside `.agents/ginee/`"*.
  - **5 mandatory checks** before publishing a sidecar — per-bullet word cap · user-value voice · `(D<N>)` tag · no implementation boilerplate · migration link in footer.
  - **Enforcement** — LLM self-review at draft time; one-line orchestrator advisory on violation; never auto-rewrites; never re-dispatches purely for format. Same machinery as D22 / D26 / D29 / D30.
  - **D34 carve-out** — sidecar D-tags stay bare (`(D31)`); slug-glued form (`D31-model-tier`) is required only in framework specs · adopter docs · cardinal returns where copy-paste-to-filesystem-search matters. Sidecars carry the spec link in the footer.
  - **Spec location.** `core/changelog-protocol.md` is team-lead-loaded (release-artefact authoring lives on team-lead's surface per D25's doc-ownership map — framework-meta governance alongside CRs · work-breakdown). Moved from `core/process.md § Documentation style` to `core/roles/team-lead.md` kernel after code-review feedback; the 6 non-team-lead cardinals correctly pay zero bytes for this rule.
  - **Files updated** — `core/MIGRATIONS/D40-changelog-protocol.md` (NEW) · `core/changelog-protocol.md` (NEW, load-on-demand spec) · `core/protocols/doc-authoring-protocol.md § Scope` (release-surfaces row) · `core/doc-authoring-examples.md § 14` (NEW bad/good pair — sidecar bullet) · `core/roles/team-lead.md` (kernel bullet) · `docs/CONCEPTS.md` + `docs/CHEATSHEET.md` (adopter-facing) · `CLAUDE.md` + `PLAN.md` (D40 row) · this file.
  - **Backwards compatibility** — purely additive. Framework-internal authoring rule; no adopter file affected; no `local/*` schema change. Forward-only — pre-D40 sidecars (`v0.4.0` → `v0.15.0`) not retroactively rewritten. Adopter action: **none**.
  - Migration: `core/MIGRATIONS/D40-changelog-protocol.md`.

### Per-role context cost — team-lead only

`team-lead` grew **+2,047 bytes (~+3.4%)** since v0.15.0 — D39 + D40 each added a kernel bullet. **All 6 non-team-lead cardinals unchanged** (D39 cardinal-kernel addenda + D40 `core/process.md` pointer were both refactored to team-lead's surface after code-review feedback). Headroom on every role > 30%; no ceiling adjustments needed.

Full per-role snapshot: [`reference/CONTEXT_COSTS.html`](https://kostiantyn-matsebora.github.io/ginee/reference/CONTEXT_COSTS.html).

## 0.15.0 — 2026-05-24

### Added

- **D36 — Warm specialist reuse across dispatches within a task lifecycle** ([#90](https://github.com/kostiantyn-matsebora/ginee/issues/90)). Pre-D36 every `@<role>` dispatch fresh-spawned a subagent that reloaded its kernel, role-details, `core/process.md`, its `phase-participation:` files, and `local/index/*` — even when the same role had been dispatched earlier in the same task. D36 amortises the reload cost: on 2nd+ dispatch within one Phase 1–8 task AND within the role's D35-process-md-load-topology participation window, team-lead resumes the existing specialist via the adapter's native mechanism (Claude `SendMessage` to a `run_in_background: true` agent) instead of fresh-spawning. **Token savings:** 15–50 k tokens of duplicated reload eliminated per task on typical 3–5-dispatch workloads. Forced-fresh on stale state · worktree mismatch · `local/*` drift · explicit `fresh:` prefix · resume-failure. Adapters without resume capability fall back to fresh-spawn (no behavioural change). Adopter opt-out via `local/framework.config.yaml § warm-reuse.enabled: false`. Migration: `core/MIGRATIONS/D36-warm-specialist-reuse.md`.
- **D37 — Adapter pointers auto-load `local/roles/<role>.md` as cardinal extension** ([#94](https://github.com/kostiantyn-matsebora/ginee/issues/94)). Pre-D37 an adopter-authored `local/roles/<cardinal>.md` file was orphaned by every adapter — the documented pattern was silently broken. D37 adds `local/roles/<role>.md` as the final numbered read in every shared pointer at `adapters/_shared/agents/<role>.md`: load if present, augments charter, never replaces. Adopters who already author cardinal extensions gain auto-loading on next upgrade without any change on their side. Custom-new-role registration is unchanged (still registers via per-adapter pointer entry / `team-lead` discovery flow). D21-context-economy-gates watched-paths extended for `local/roles/*.md` at the "other watched" tier (50-line / 2 KB net-added). Migration: `core/MIGRATIONS/D37-local-role-extensions.md`.
- **D38 — Host capability tools — adapters expose, specialists discover and leverage** ([#85](https://github.com/kostiantyn-matsebora/ginee/issues/85)). Pre-D38 ginee specialists had no explicit awareness of capability tooling the host adapter exposes (skills · MCP servers · IDE integrations). Output quality varied based on whether the dispatched agent happened to know about a relevant tool. D38 adds an affinity-injection protocol: each adapter declares its capability tools in `install.md § Specialist-tool affinity` with role/task affinity hints; team-lead reads the table (cached per task) and surfaces matching tools as a one-line hint in each dispatch prompt. **Specialist judgment never overruled** — "prefer if available", not "must use". Claude adapter ships 4 reference rows (`frontend-design` · `code-review` · `verify` · `security-review`). Adapters lacking an affinity section → graceful degradation (no hint surfaced). Adopter opt-out via `local/framework.config.yaml § capability-tools` (`disabled: [<tool-id>, …]` or `enabled: false`). Migration: `core/MIGRATIONS/D38-host-capability-tools.md`.

## 0.14.0 — 2026-05-24

### Added

- **D35 — `core/process.md` load topology split** ([#89](https://github.com/kostiantyn-matsebora/ginee/issues/89)). Pre-D35 the 477-line lifecycle spec was always-loaded on every cardinal dispatch — every role paid the cost of phases it never participated in. D35 extracts the 8 phase blocks + orchestration content into `core/process/phase-<N>-<name>.md` + `core/process/dispatch.md`; slims `core/process.md` to common-only (Purpose · Reading order · Engineering principles · Doc style · Reporting · Coordination protocol · Load-on-demand index). Each cardinal kernel declares `phase-participation: [N, M, …]` in frontmatter; adapter loads only matching phase files. Roster: `team-lead [1-8]` + `dispatch.md` · `solution-architect [1, 2, 4, 5, 6, 7]` · `backend / frontend / devops [2, 4, 5, 6]` · `qa-engineer [5, 6]` · `ai-engineer []`. **Token reduction:** backend Phase 4 dispatch -38%; qa Phase 5 -48%; ai-engineer -58%. Spec: `core/MIGRATIONS/D35-process-md-load-topology.md`.
- **Per-role context-cost measurement + CI gate + adopter doc** ([#100](https://github.com/kostiantyn-matsebora/ginee/pull/100)). `scripts/measure-role-context.ps1` measures the framework-only context cost per cardinal on first dispatch. Auto-generates the snapshot in `docs/reference/CONTEXT_COSTS.md` from templates under `scripts/templates/` (substitution-only — no markdown formatting logic in the script). New Pester test (`tests/measure-role-context.Tests.ps1`) — 17 assertions including doc-currency gate, D35 phase-participation contract verification, and per-role byte ceilings from `scripts/templates/role-context-ceilings.json` (single source of truth shared by the test and the doc generator). Refresh flow: `pwsh -File scripts/measure-role-context.ps1 -UpdateDoc`.
- **Release checklist in `CLAUDE.md`**. 5 numbered steps before tagging — refresh snapshot · analyse movement vs. prior tag · tighten ceilings if stabilised · verify gate · commit + tag. Catches snapshot-drift across releases.

### Changed

- **`core/process.md` slimmed from 477 to ~180 lines.** All cardinals except `team-lead` see materially less always-loaded context. Migration is automatic on the next dispatch — anchor moves are documented in `core/MIGRATIONS/D35-process-md-load-topology.md § Anchor migration` for adopters citing `core/process.md § Phase N` from `local/*`.
- **`*-protocol.md` specs relocated to `core/protocols/`** ([#98](https://github.com/kostiantyn-matsebora/ginee/pull/98)). `core/doc-authoring-protocol.md` · `core/index-protocol.md` · `core/iteration-protocol.md` · `core/options-protocol.md` → `core/protocols/<name>.md`. Sweeps 65 files of internal references. Adopters citing the old paths from `local/*` should update their cites.
- **Team-lead-only kernel summaries relocated to `core/process/dispatch.md`** ([#99](https://github.com/kostiantyn-matsebora/ginee/pull/99)). `GitHub integration · Triage scoring · Post-task check-in` kernel summaries moved out of always-loaded `core/process.md`. Specialists no longer pay for orchestration-only spec summaries.
- **D21 watched-paths extended** — `core/process/*.md` + `core/protocols/*.md` join the "other watched" tier (50-line / 2 KB net-added).

### Fixed

- **Reference sidebar surfaces the new context-costs page** ([#101](https://github.com/kostiantyn-matsebora/ginee/pull/101)). The layout's hard-coded list was missed in #100 — the new page rendered without a sidebar entry. Layout now includes `CONTEXT_COSTS` in both the top-nav active-state detector and the section-nav sidebar.

## 0.13.0 — 2026-05-23

### Added

- **D34 — Taxonomy identifier short-name pairing** ([#88](https://github.com/kostiantyn-matsebora/ginee/issues/88)). Every cardinal output, ginee-authored GitHub artefact, and adopter doc cites taxonomy items in slug-glued form — `D28-skill-runner-boundary`, `ADR-0001-topology-derivation-five-pass`, `CR-0010-component-ci-pipeline`, `FR-04-deploy-rollback`, `NFR-02-cost-cap`, `ASR-03-availability-budget`. Slug is zero-cost for the agent (already in filename) and high-value for the reader — copy-paste into a filesystem search returns the spec immediately.
  - **Out of scope** — issue / PR / commit-SHA / NPM-package-name references stay bare. `#87`, `[PR #84](...)`, git SHAs, package names in code blocks are correct as-is.
  - **Resolution lookup** — file-backed via filesystem listing (`ls core/MIGRATIONS/D<NN>-*.md`); inline-table (FR / NFR / ASR) via register-row noun-phrase slugify; index-class via `manifest.yaml § name:`.
  - **On resolution failure** — surface inline (`D28-?? (slug lookup failed)`); orchestrator carries forward to next dispatch; never invent a slug.
  - **Self-lint** — extends D22 / D26 / D29 mandatory check #5 (cross-references). Regex `\b(D|ADR-?|CR-?|FR-?|NFR-?|ASR-?)\d+\b` not followed by `-<slug>` trips. Excluded contexts: issue / PR / SHA / package-name references.
  - **Files updated** — `core/process.md § Mandatory checks` (check #5 extended) · `core/protocols/doc-authoring-protocol.md` (NEW § Taxonomy identifier pairing) · `core/templates/phase-report.md § ## Decisions made` (slug-glued cite-form) · `core/templates/pr-description.md § Cites` (CR / ADR / FR / NFR examples) · 2 framework issue templates · 7 cardinal role kernels (one-line addendum per `## Reporting`) · `core/doc-authoring-examples.md § 13` (NEW bad/good pair) · `CLAUDE.md` + `PLAN.md` (D34 row) · this file · `core/MIGRATIONS/D34-identifier-short-name-pairing.md` (NEW).
  - **Backwards compatibility** — purely additive. No `local/` schema change. No installer change. Reporter content unchanged. 6 checks count unchanged (rule extends check #5). Forward-only — historical outputs not rewritten; existing taxonomy files not renamed.
  - Migration: `core/MIGRATIONS/D34-identifier-short-name-pairing.md`. Adopter action: none.

### Fixed

- **D32 — Claude adapter accept-orchestrated subagent dispatch** ([#87](https://github.com/kostiantyn-matsebora/ginee/issues/87)). Claude Code's `Agent` / `Task` tool is top-level only — subagents do not inherit it, so team-lead-as-subagent under the D28 hand-back rule cannot fan out to specialists. Pre-D32 the dispatch silently degraded ("answer from your own context") on every multi-specialist phase. D32 narrows the D28 surface boundary on the Claude adapter only.
  - **Split.** Decision authority stays with team-lead; *mechanical execution of approved dispatch contracts* moves to the skill-runner.
  - **Cycle.** `skill-runner mechanical batch → @team-lead (plan) → user approve → skill-runner (mechanical dispatch verbatim, parallel where independent) → skill-runner collect returns → @team-lead (synthesis + next decision) → loop` until team-lead returns phase-complete.
  - **Skill-runner still banned** from plan drafting · synthesis · gate text · routing reconciliation · default selection · `local/bindings.md` lookup — D32 permits *execution* of team-lead's already-decided dispatches, never origination.
  - **Other adapters unaffected** — D28 hand-back rule unchanged on Cursor · Copilot CLI · Codex · generic.
  - **Files updated** — `adapters/claude/install.md` (new `§ Subagent dispatch limitation (D32)`) · `core/process.md § Skill-runner — surface boundary` (adapter-aware caveat) · `CLAUDE.md` (D32 row) · `core/MIGRATIONS/D32-claude-adapter-subagent-dispatch.md` (NEW).
  - **Backwards compatibility** — purely additive. No `local/` schema change. No `framework.config.yaml` keys. No installer change. Pre-D32 Claude-adapter invocations were silently degrading; D32 just documents the loop that makes them work.
  - Migration: `core/MIGRATIONS/D32-claude-adapter-subagent-dispatch.md`. Adopter action: none.

- **D33 — D29 phase-report schema enforcement hardening** ([#86](https://github.com/kostiantyn-matsebora/ginee/issues/86)). Pre-D33 the 6 mandatory checks at report-as-done were aspirational — agents skipped them silently when substance felt useful, and the orchestrator had no structural detection surface to surface the skip. The compound failure also breached the D28 skill-runner boundary: a non-compliant verbose return tempted the skill-runner to "clean up" the content into a tidy summary table, which is synthesis (team-lead's surface). D33 closes both gaps with a single-line marker.
  - **Marker** — literal `<!-- D29 self-lint: pass -->` on the last line of every cardinal-dispatch return. Agent's attestation that the 6 checks ran.
  - **Orchestrator behaviour on absence** — one-line advisory at receive-time + carry-forward rephrasing on the subagent's next dispatch; never re-dispatches for format; never auto-rewrites.
  - **Worked advisory table** — 5 violation classes paired with exact advisory text.
  - **D28 cross-reference** — skill-runner **forbidden** from cleaning up a non-compliant return before passing to team-lead. Cleanup is the regression-grade workaround issue #86 catalogued.
  - **Honest-fail rule** — if a check failed and could not be restructured (lifted to `## Notes`), still write the marker. Marker attests the *checks ran*, not that they *passed-with-zero-restructure*.
  - **Files updated** — `core/templates/phase-report.md` (new `§ Before-return checklist + mandatory marker (D33)` + extended orchestrator-behaviour section with advisory examples + carry-forward block) · 7 cardinal role kernels (`; end with <!-- D29 self-lint: pass --> marker (D33).` clause appended to each `## Reporting`) · `core/roles/team-lead.details.md § Common failure modes` (new D33 row) · `core/process.md § Skill-runner — surface boundary (D28)` (D29 / D33 interaction bullet) · `core/process.md § Reporting — schema-bound (D29)` (mandatory-marker bullet) · `core/doc-authoring-examples.md § 12` (NEW bad/good full-return example) · `CLAUDE.md` + `PLAN.md` + this file (D33 surface) · `core/MIGRATIONS/D33-d29-enforcement-hardening.md` (NEW).
  - **Backwards compatibility** — purely additive. Schema unchanged. 6 checks unchanged. No `local/` schema change. No installer change. Forward-only — existing closed dispatches not retroactively required.
  - Migration: `core/MIGRATIONS/D33-d29-enforcement-hardening.md`. Adopter action: none.

## 0.12.1 — 2026-05-23

### Fixed

- **Cardinal subagents dispatch on the standard tier without a per-call `model:` override** ([#82](https://github.com/kostiantyn-matsebora/ginee/issues/82), [#83](https://github.com/kostiantyn-matsebora/ginee/pull/83)). Claude Code's lazy YAML frontmatter parser was consuming the inline `# D31 — <tier> tier; override via …` comment on the `model:` line as part of the model ID; Sonnet-tier dispatches (`ai-engineer` · `backend-engineer` · `devops-engineer` · `frontend-engineer` · `qa-engineer`) failed with `There's an issue with the selected model (claude-sonnet-4-6  # D31 — …)`. Opus-tier dispatches (`team-lead` · `solution-architect`) prefix-matched and masked the bug. **Fix**: comment moved to its own line directly above a bare `model:` line in all 7 cardinal templates under `adapters/_shared/agents/`.
- **`Set-ClaudeAgentModel` (install.ps1)** emits the same comment-above shape so re-running install / `/ginee-update` no longer reintroduces the inline-comment shape — and consumes any pre-existing `# D31 — …` comment line directly above the model line during rewrite (no comment accumulation across re-runs). +2 Pester regression tests.

## 0.12.0 — 2026-05-23

### Added

- **D31 — Per-role + per-task model tier** ([#76](https://github.com/kostiantyn-matsebora/ginee/issues/76)). Routes reasoning-heavy roles to capable models and execution-heavy roles to cheaper ones. Tier names vendor-neutral in `core/`; concrete model IDs live only in the adapter layer. Purely additive — absent `model-tier:` config → framework defaults apply silently.
  - **3 tiers** — `reasoning` (orchestration · synthesis · architectural; Claude map `claude-opus-4-7`) · `standard` (implementation · tests · doc-shape · lint fixes; `claude-sonnet-4-6`) · `fast` (mechanical · label ops · sticky updates; `claude-haiku-4-5-20251001`). Three buckets cover the load profile; D28 (skill-runner boundary) + D29 (bounded returns) make the `fast` tier safe.
  - **Defaults per role** — `team-lead` + `solution-architect` → `reasoning`; `ai-engineer` + 4 engineer cardinals → `standard`. `default-tier:` declared in each role-kernel YAML frontmatter.
  - **Resolution order** (per dispatch — stop at first match) — (1) per-task prefix `model:<tier>` in the dispatch line (combinable with `auto:` / `branch:` / `wt:` / `commit:`); (2) Phase-3 user answer; (3) `local/framework.config.yaml § model-tier.per-role.<role>`; (4) `core/roles/<role>.md` frontmatter `default-tier:`.
  - **Adapter behaviour.** Claude — install reads `local/framework.config.yaml § model-tier` overrides (when present) + writes `model: <id>` into each `.claude/agents/<role>.md` frontmatter. Pre-resolved defaults shipped in the `_shared/agents/*.md` pointer files. Per-task `model:` prefix is an orchestrator hint translated via `Task` tool's `model` field. Cursor / Copilot CLI / Codex / generic — no programmatic per-role model selection today; install emits one-line warning; per-task prefix documented as user hint.
  - **License + supply-chain stance.** Two adopt candidates surfaced for the schema concept (Aider `--model` / `--weak-model` / `--editor-model` split — Apache-2.0; Continue.dev `config.yaml` model role pointers — Apache-2.0); the wiring layer adopts Claude Code's built-in subagent `model:` frontmatter (client-bundled). Schema itself is build (vendor-neutral tier abstraction over markdown-keyed roles — no off-the-shelf framework ships this surface).
  - **Files updated** — `core/roles/*.md` (× 7) add `default-tier:` to frontmatter · `adapters/_shared/agents/*.md` (× 7) add pre-resolved `model:` to frontmatter · `core/templates/framework.config.yaml` adds optional `model-tier:` block · `core/process.md § Dispatch & parallelism rules` adds 5-line per-task tier subsection · `install.ps1` + `install.sh` Claude branch reads `model-tier:` overrides and rewrites pointer `model:` lines · `tests/install.Tests.ps1` Pester coverage · 4 adapter `install.md` files · `docs/CONCEPTS.md` + `docs/CHEATSHEET.md` + this file (D31 entries) · `CLAUDE.md` + `PLAN.md` (D31 row) · `core/MIGRATIONS/D31-model-tier.md` (NEW).
  - **Backwards compatibility** — purely additive. No `local/` schema change forced. Absent `model-tier:` → framework defaults apply silently. Existing dispatches unaffected until adopter sets a tier or uses the prefix. Forward-only.
  - Migration: `core/MIGRATIONS/D31-model-tier.md`. Adopter action: none.

- **D30 — Adopt-existing-solution as a first-class Phase-2 option** ([#75](https://github.com/kostiantyn-matsebora/ginee/issues/75)). Binds every Phase 2 design proposal AND every iteration-protocol Propose step (Phase 4–7 > 15-min sub-tasks with a live adopt-vs-build axis) to surface ≥ 1 adopt-existing-solution candidate — or an explicit `(none viable — <reason>)` cite. Stops the LLM-default failure mode of authoring novel implementations when no rule forces the proposer to look outward first.
  - **Schema** — 4 candidate types: `adopt` (name · version · source link · license · one-line fit rationale) · `build` (scope · rationale why adoption rejected) · `hybrid` (adopt portion + build portion + boundary rationale) · `(none viable — <reason>)` (empty-research escape hatch). Every candidate explicitly tagged; no silent mixing.
  - **Floor** — hard ≥ 1 `adopt` candidate OR `(none viable)`; soft encourage 2–3 for non-trivial scope.
  - **5 mandatory checks before surfacing** — adopt floor present · citations complete · tagging explicit · empty research documented (`(none viable — <reason>)`) · fit rationale concrete (not hand-waved).
  - **Forbidden patterns** — silently skipping adoption research · build-only option lists on a live axis · hand-waved adopt candidates (`"mature library"` alone) · silently mixing adopt + build without explicit `hybrid` tag · citing a library without fit rationale.
  - **License + supply-chain stance** — defer to adopter `local/`. Framework requires the citation but expresses no opinion on which licenses pass.
  - **Research depth** — cite-only baseline (name · version · source · license · fit). SBOM cross-check / full-ADR are escalations the proposer MAY adopt; not mandated.
  - **Enforcement** — LLM self-review against the schema before surfacing. No external linter; no runtime dependencies. Same machinery as D22 / D26 / D29. Orchestrator surfaces a one-line advisory on violations but never re-dispatches purely for format and never auto-rewrites.
  - **Spec topology** — new load-on-demand `core/protocols/options-protocol.md` carrying full schema · scope · 5 checks · forbidden patterns · enforcement · worked example. Always-loaded `process.md § Phase 2` + `iteration-protocol.md § Propose` carry tiny pointer lines only. Matches the D22 doc-authoring-protocol + D29 phase-report split.
  - **Files updated** — `core/protocols/options-protocol.md` (NEW spec) · `core/process.md § Phase 2 — Design & architecture` (option-shape rule pointer) · `core/protocols/iteration-protocol.md § Each iteration § Propose` (adopt-vs-build axis bullet) · `core/roles/solution-architect.md § Design § Phase 2` (first-class design axis) · 5 engineer kernels (backend · frontend · devops · qa · ai) add a 1-paragraph "Adoption research before authoring" pointer above `## Forbidden actions` · `core/doc-authoring-examples.md § 11` (NEW bad/good pair) · `docs/CONCEPTS.md` + `docs/CHEATSHEET.md` + this file (D30 entries) · `CLAUDE.md` + `PLAN.md` (D30 row) · `core/MIGRATIONS/D30-adopt-existing-solution.md` (NEW).
  - **Backwards compatibility** — purely additive. No `local/` schema change. No new commands. Existing proposals on closed tasks unaffected — forward-only.
  - Migration: `core/MIGRATIONS/D30-adopt-existing-solution.md`. Adopter action: none.

- **D29 — Strict subagent-return schema** ([#69](https://github.com/kostiantyn-matsebora/ginee/issues/69)). Binds every cardinal-dispatch return to a strict schema — same machinery as D22 / D26 doc-authoring protocol applied to the subagent-return surface. Cardinal returns were today's largest single contributor to orchestration-thread bloat (1,500–15,000 chars per dispatch typical). D29 cuts that by ~70%.
  - **Schema** — 5 mandatory sections (`## Files touched` · `## Decisions made` · `## Verification log` · `## Open issues` · `## Next dispatch needed`; empty case `(none)`) + 2 conditional (`## Hand-off` on forced handoff per `core/cross-agent-handoff.md`; `## Stop-state` when `Status: In-progress`) + 1 optional escape hatch (`## Notes` ≤ 200 words; ≤ 5-line code-snippet carve-out).
  - **6 mandatory checks before report-as-done** — 5 from D22 / D26 (no paragraph > 2 sentence terminators · no multi-sentence table cells · no bullet > 25 words without sub-bullets · inventories as tables · cross-references cite anchors) + *no narrative preamble* (first non-Status line must be a `##` section header).
  - **Forbidden patterns** — narrative preamble · restated dispatch context · code snippets outside the Notes carve-out · verbose rationale outside `## Notes` · parenthetical comma-soup.
  - **Enforcement** — LLM self-review against the schema before returning; no external linter. Orchestrator surfaces a one-line advisory on violations but never re-dispatches purely for format and never auto-rewrites (analogous to D14 reporter-content forbidden).
  - **Open-question picks.** `## Notes` cap ≤ 200 words. Code snippets banned outside a ≤ 5-line Notes carve-out. Iteration-protocol intermediate returns use the same schema with `(in-progress)` markers + required `## Stop-state`. Failed dispatches add the conditional `## Hand-off` section.
  - **Files updated** — `core/templates/phase-report.md` rewritten as schema · `core/process.md § Reporting` (new always-loaded section) · 7 role kernels gain or amend `## Reporting` with the schema pointer · `core/protocols/doc-authoring-protocol.md § Scope` extended + new § Enforcement for subagent returns · `core/doc-authoring-examples.md § 10` (new bad/good pair with measured 68.5% reduction on a real Phase-4 return) · `docs/CONCEPTS.md` + `docs/CHEATSHEET.md` + `CLAUDE.md` + `PLAN.md` (D29 entries).
  - **Worked measurement** — bad return 3,603 chars (narrative + restated context + per-file rationale + embedded code) → schema-bound 1,136 chars; reduction (3603 − 1136) / 3603 = 68.5%. Documented inside `core/doc-authoring-examples.md § 10`.
  - **Backwards compatibility** — purely additive. No `local/` schema change. No new commands. Existing dispatches on closed tasks unaffected — forward-only.
  - Migration: `core/MIGRATIONS/D29-strict-subagent-return-schema.md`. Adopter action: none.

- **D28 — Skill-runner / team-lead surface boundary** ([#71](https://github.com/kostiantyn-matsebora/ginee/issues/71)). Locks the structural rule that prevents the skill-runner main thread from orchestrating. Pre-D28 the framework's role definitions assigned orchestration to `team-lead` but no spec named the skill-runner (the thread running a `ginee-*` skill body — Claude main thread / Cursor main loop / Copilot CLI main loop / AGENTS.md-driven shell) as a distinct surface or banned it from making orchestration decisions. The slip recurred across long sessions: skill-runner authored Phase 1–8 plans itself, synthesized parallel specialist returns, answered routing-governance questions by reading `local/bindings.md` directly, proposed reconciliation options with default-selection ("I'll pick option 1 if you don't redirect").
  - **Skill-runner defined** — thin mechanical surface running a `ginee-*` skill body. Not a role; not an orchestrator. Carries only the operations the skill text spells out.
  - **Allowed (mechanical ops only)** — parse prompt + identify task source · label / sticky / audit-comment ops · branch ops per resolved delivery mode · the skill text's one named first-batch dispatch · report the mechanical result to the user.
  - **Forbidden (must dispatch `@team-lead`)** — plan drafting · synthesis of parallel specialist returns · lifecycle gate text · re-dispatch after the first batch · routing reconciliation on engineer pushback · default selection · `local/bindings.md` lookup to settle routing questions.
  - **Hand-back rule** — every `ginee-*` skill dispatches `@team-lead` after its first mechanical batch. From there every orchestration decision flows through team-lead. If a routing or governance question arises mid-flight, the skill-runner dispatches `@team-lead` to answer; it never answers by reading project files itself.
  - **Worked counter-example** from issue #71 lives in `core/process.md § Skill-runner — surface boundary` and `core/MIGRATIONS/D28-skill-runner-boundary.md`.
  - **Files updated** — `core/process.md` (new top-level § Skill-runner — surface boundary) · `core/roles/team-lead.md` (new Inbound trigger surfaces section with skill-runner hand-back row) · `core/roles/team-lead.details.md § Common failure modes` (new D28 row) · 4 skill files (`ginee-pick-up` · `ginee-address-review` · `ginee-triage` · `ginee-promote-discussion`) gain a hand-to-team-lead step + skill-runner-forbiddens entry · `core/github-integration.md § Inbound — pick up an issue` re-narrated to mark mechanical vs team-lead-owned steps.
  - **Backwards compatibility** — purely additive. No `local/` schema change. No new commands. No adapter re-install. Existing skill invocations continue working; only the regression path (skill-runner drifting into orchestration) is now structurally forbidden.
  - Migration: `core/MIGRATIONS/D28-skill-runner-boundary.md`. Adopter action: none.

### Fixed

- **D27 — `/ginee-update` now reaches a standard install** ([#67](https://github.com/kostiantyn-matsebora/ginee/issues/67)). Pre-D27 the `ginee-update` skill's Step 1 required `install.ps1` + `install.sh` + `core/VERSION` inside `.agents/ginee/`, but the bootstrap intentionally prunes the installers (they belong to the deploy layer, not runtime). Every standard install therefore exited at Step 1 with a misleading `framework not found at <path>` — making `/ginee-update` non-functional for everyone.
  - **Step 1 (Locate)** — now requires **only** `<fw>/core/VERSION`. `core/VERSION` is the framework existence sentinel; the installer is fetched on demand.
  - **Step 6 (Run)** — fetches `install.{ps1,sh}` from `https://raw.githubusercontent.com/<github.framework-repo>/<target-ref>/install.{ps1,sh}` to a temp dir, then executes via `pwsh -File` / `bash` with the detected adapter + project root passed explicitly. `<github.framework-repo>` resolves from `local/framework.config.yaml` (default `kostiantyn-matsebora/ginee`); `<adapter>` is the single non-`_shared` subdir under `<fw>/adapters/`; `<root>` is `<fw>/../..`.
  - **Trade-offs.** Three options considered: (a) skill fetches installer from upstream (chosen — symmetric with bootstrap, `.agents/ginee/` stays runtime-only, no version skew); (b) installer self-copies into `<fw>` (rejected — version-skew risk + pollutes runtime tree); (c) fallback chain (rejected — ambiguous resolution).
  - **Adapter delta.** All four `adapters/{claude,copilot-cli,agents-md,generic}/install.md § Updates` sections refreshed — drop the misleading `.\install.ps1 -UpdateOnly` "recommended" line (implied a co-located installer); replace with `/ginee-update` primary + bootstrap one-liner manual fallback.
  - **Chicken-and-egg.** Pre-D27 installs land the fix by running the manual bootstrap one-liner once (the documented #67 workaround); subsequent updates flow through the fixed `/ginee-update`.
  - **Installer itself unchanged.** D27 is purely a skill-internal change. No schema change to `local/framework.config.yaml`. `github.framework-repo` was already wired in D14.
  - Migration: `core/MIGRATIONS/D27-installer-fetch-on-update.md`. Adopter action: one-time bootstrap one-liner per the migration; no other action required.

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
  - **Lossless coverage** — every plan-table thread MUST end the cycle as `fix` (patch landed) OR `reply` (text + marker). No silent drops. Same principle as `core/protocols/index-protocol.md § Lossless rule for index § Coverage rule`.
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
  - Spec: `core/protocols/index-protocol.md § Reconciliation` (renamed from `§ Re-extraction`). Migration: `core/MIGRATIONS/reindex-reconcile.md`.

- **`team-lead` strict-domain hardening — close "feels fast → I'll just do it" bypass** ([#50](https://github.com/kostiantyn-matsebora/ginee/issues/50), [#51](https://github.com/kostiantyn-matsebora/ginee/pull/51)). Closes an observed regression where the orchestrator self-executed specialist-owned work on a "feels fast" heuristic — 5–7 min estimates ballooning into ~60 min main-thread sessions with no stop-and-report. Kernel + protocol wording now names the failure mode and blocks it.
  - **`core/roles/team-lead.md § Forbidden actions`** — new bullet: *"Never self-execute work in a specialist-owned surface, regardless of estimated size."* Includes the correct dispatch shape for ≤ 15 min work (explicit estimate flag → iteration-protocol load skipped).
  - **`core/process.md § Dispatch & parallelism rules`** — new row: *"Surface owns the dispatch decision"* — routing is owned by the touched surface, not by perceived effort.
  - **`core/process.md § Strict-domain rule`** — *"Size is not an exemption"* sub-bullet + pointer to the failure-modes catalogue.
  - **`core/protocols/iteration-protocol.md § Stoppable intermediate states`** — new `### Scope-overrun trigger` sub-section: > 2× initial estimate → mandatory stop-and-report. Applies symmetrically to specialists and orchestrator in-thread work.
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
    - `core/protocols/doc-authoring-protocol.md` (2 KB, load-on-demand at Phase 5 / report-as-done) — enforcement-via-discovered-stack + attestation format + out-of-scope.
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
