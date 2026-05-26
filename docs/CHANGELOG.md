---
title: Changelog
description: "Release history."
permalink: /CHANGELOG.html
---

# Changelog

All notable changes to ginee. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); the framework adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## 0.22.0 — 2026-05-26

### Changed

- **`ai-engineer` cross-iteration dedup pass** ([#171](https://github.com/kostiantyn-matsebora/ginee/pull/171)). Six structural optimisation passes against the shipped framework (`core/` · `adapters/` · `extras/`) after hundreds of feature iterations introduced cross-file overlap without dedup checks. Findings via prompt-chaining — five parallel research agents audited disjoint file clusters (schemas+templates · skills · phase+protocols · doc-family · extras+adapters); merge plan synthesised from their reports.

  - **New shared blocks.** `core/protocols/role-kernel-shared.md` absorbs seven role-kernel boilerplate sections (Source-of-truth · Estimation-first · Adoption research · Reporting · Proposing-architectural-changes · Forbidden lead-in · Doc-authorship) cited by all 7 role kernels. `adapters/_shared/install-common.md` absorbs four adapter-install sections (Skill cheat sheet · Phase-file loading · Model tier · Updates) cited by all 4 adapter `install.md` files.

  - **Template ↔ schema merges.** `sub-issue-dispatch.md` absorbs `sub-issue-dispatch-schema.md`; `pr-comment-cadence.md` absorbs `review-cycle-schema.md`. Schema sidecars retained as thin pointers so existing cross-references resolve unchanged.

  - **Phase files** — derivable rosters dropped (read from `phase-participation:` frontmatter); heavy-role-bypass cites replace prose restatements in phases 5/6; iteration-protocol citation phrasing unified across phases 4/5/6.

  - **Doc-size-caps** — `Optimized-By: ai-engineer` trailer rule collapsed from 4 restatements to 1 canonical statement.

  - **Doc-authoring-examples** §11/§16/§17 collapsed to citations (canonical content already lived in `options-protocol.md` · `heavy-role-bypass.md` · `pixel-check-protocol.md`).

  - **Out-of-scope + Why sections** dropped from 13 protocols (user-approved as aggressive option; rationale lives in `PLAN.md`; runtime surface is rule-only).

  - **`phase-report.md`** — duplicate `## Orchestrator behaviour on non-compliant returns` section removed (orphan from a prior iteration).

  - **Hook + statusline script headers** tightened; functional code untouched (gated by Pester + PSScriptAnalyzer).

  - **Per-role context — measured impact.** Every cardinal's per-dispatch load dropped 19–28% (see `docs/reference/CONTEXT_COSTS.md`); shipped framework `core/` + `adapters/` + `extras/` 758 KB → 597 KB (−21.3%).

  - **Tightened per-role ceilings** in `scripts/templates/role-context-ceilings.json` to ~30% headroom on the post-dedup baseline (was 36–55% headroom under 0.21.0 ceilings). Future ordinary edits can grow per-role context by ~30% before tripping the `ai-engineer` dispatch gate; further growth requires an optimisation pass. Loosening any ceiling continues to require ai-engineer review per `docs/RELEASE.md` checklist step 3.

  - **No `local/*` surface affected; all `@<role>` + skill phrasings unchanged.** Old schema-sidecar paths still resolve via thin-pointer redirects.

  - **Optimized-By: ai-engineer** trailer present on every commit in the PR per `core/protocols/doc-size-caps.md § Enforcement`.

  Migration: none — purely additive on the adopter side. Re-run `/ginee-update` (or the bootstrap one-liner) to pick up the new shared files; `local/*` untouched.

### Fixed

- **YAML frontmatter parse failure on strict parsers.** Four files had `description:` values containing `: ` (literal colon + space) which strict YAML 1.1/1.2 parsers reject as compact-mapping syntax violations (`Nested mappings are not allowed in compact mappings`). Converted offending descriptions to folded-block scalar (`>-`) for `adapters/_shared/agents/ai-engineer.md` · `core/roles/ai-engineer.md` · `core/roles/solution-architect.md` · `core/skills/ginee-update/SKILL.md`. All four issues pre-existed on `main`; surfaced by the dedup-pass push and fixed forward. Full frontmatter audit (80 files) verified with `powershell-yaml` parser as part of the fix.

## 0.21.0 — 2026-05-26

### Added

- **Sub-issue pickup fast-path** ([#152](https://github.com/kostiantyn-matsebora/ginee/issues/152)). `ginee-pick-up` against a sub-issue with single `ginee:role:<cardinal>` label + populated dispatch-contract body (`core/templates/sub-issue-dispatch.md` shape) hands off to `@<cardinal>` directly, skipping the `@team-lead` re-route. Routing artefact already exists; re-deriving it cost one full ~15–40k token dispatch for zero new information. Re-entry through `@team-lead` mandatory on five trigger conditions — role-label gap · `## Open issues` non-empty · `## Hand-off` set · `Status: In-progress` · cross-domain bug. Parent issues + TODO + freeform sources unchanged. Migration: `migrations/sub-issue-fast-path.md`.

- **Lite-mode lifecycle prefix** ([#153](https://github.com/kostiantyn-matsebora/ginee/issues/153)). New `lite:` (alias `direct:`) prefix elides Phase 1–3 for trivial scope — typo / single-label tweak / single-doc-bullet — and dispatches one named cardinal directly into Phase 4. Phases 5–8 run normally. Resolution chain (stop at first match) — per-task prefix → issue-sourced `complexity:low` + single `ginee:role:<cardinal>` + `lifecycle.lite-mode.label-trigger: true` → `lifecycle.lite-mode.default: true` → framework default Phase 1–8. CR / ADR / Phase 7 / Phase 8 gates remain in effect — lite is orchestration cost reduction, not governance bypass. Composes freely with `auto:` · `branch:` / `wt:` / `commit:` · `model:<tier>` · `notrack:` · `cr:` / `nocr:` · `adr:` / `noadr:` · `fresh:`. Migration: `migrations/lite-mode.md`.

- **Heavy-role bypass — codify `team-lead` + SA invocation gates across Phase 4–7** ([#162](https://github.com/kostiantyn-matsebora/ginee/issues/162)). Generalizes #152's persistence-artefact-based bypass + explicit re-entry triggers into a shared protocol covering both heavy roles across Phase 4 / 5 / 6 / 7. Heavy roles are now invocation-gated, not phase-gated — default is *skip*; presence requires an affirmative trigger.

  - **Shared protocol** `core/protocols/heavy-role-bypass.md` consolidates the persistence-artefact table (sub-issue body for TL; blueprint+ADRs+AC for SA), the universal re-entry trigger table (10 rows across both roles), per-phase tracks TL1/TL2/TL3/TL4 + SA1/SA2/SA3, Phase 7 lead-elision detail, and transcript-grep recipes for spotting defensive dispatch in past tasks.

  - **Phase 4–7 rosters qualified** to cite the protocol. `team-lead.md` + `solution-architect.md` kernels cite the shared protocol instead of restating triggers.

  - **TL1 = #152** already shipped; TL2 (single-cardinal verification), TL3 (intra-domain bug-fix), TL4 (Phase 7 lead-elision on single-cardinal PR) land here. SA1 / SA2 / SA3 codify rules already half-present (the leak was orchestrators dispatching SA defensively despite the trigger not firing).

  - **Out of scope (heavy role stays mandatory):** Phase 1 / 2 / 3 / 8 for team-lead; Phase 1 / 2 / 7 for SA. Bypasses in these phases would corrupt the artefact chain downstream. Migration: `migrations/heavy-role-bypass.md`.

- **QA pixel-check — optional Phase 5 visual oracle** ([#163](https://github.com/kostiantyn-matsebora/ginee/issues/163)). Mockup graduates from design reference to runtime oracle. Optional Phase 5 stage diffs the rendered app against the mockup at a shared seed-state; catches CSS / layout / icon / copy / responsive-breakpoint regressions that survive behaviour green. Pairs with `core/protocols/blueprint-diff-protocol.md` — blueprint-diff catches mockup self-drift, pixel-check catches app-vs-mockup drift. Off by default (`qa.pixel-check.enabled: false`). Adopter picks alignment direction (`mockup-follows-seed` — seed is stable, re-snapshot mockup; or `seed-follows-mockup` — mockup is stable, author seed to match). Drift routes per source — app wrong → front-end engineer / Phase 6 · mockup outdated → mockup owner / Phase 2 · seed wrong → seed-script owner · tolerance too tight → `team-lead`. Oracle discipline — every mask justified with `# why: <reason>`, every tolerance bump cites the diff it would have caught at the prior threshold. Migration: `migrations/qa-pixel-check.md`.

### Per-role context

Team-lead loaded bytes grow 5.3% (69,402 → 73,060) driven by lite-mode prefix grammar in `core/process/dispatch.md` + heavy-role-bypass citation block in the kernel. Headroom drops from ~23% to ~19% against the 90,000-byte ceiling. Solution-architect grows 4.1% (44,025 → 45,808); engineers grow ~3% each from the phase-4/5/6 roster qualifiers. `docs/reference/CONTEXT_COSTS.md` snapshot regenerated; no ceiling breach; next dispatch.md-touching change may warrant an `ai-engineer` optimization pass.

## 0.20.0 — 2026-05-26

### Added

- **Compliance playbook — Tier 1 tactics 1 through 4** ([#135](https://github.com/kostiantyn-matsebora/ginee/issues/135)). Promotes the four most-violated charter rules from Class H (always-loaded text, LLM voluntary compliance) to Class A (action-time enforcement) and Class G (visible state) on the Claude adapter. Per-tactic opt-out via `local/framework.config.yaml § compliance.disabled: [<tactic-id>]`; per-invocation bypass via `SKIP_GINEE_COMPLIANCE=1`.

  - **T1 — Subagent `tools:` whitelist per cardinal** ([#137](https://github.com/kostiantyn-matsebora/ginee/issues/137)). Each pointer subagent at `adapters/_shared/agents/*.md` carries a tightly-scoped `tools:` field. `solution-architect` ships without `Edit` / `Write` — the "SA never edits code" charter rule is enforced at the tool-call layer, not via always-loaded text alone. `ai-engineer` ships without `Bash`. The 5 implementer cardinals retain full read/write/Bash; their path + command scopes are layered by T2 / T3. `Agent` deliberately omitted from team-lead's whitelist — Claude Code's `Agent` is top-level-only and subagents do not inherit it. Migration: `migrations/cardinal-tools-whitelist.md`.

  - **T2 — PreToolUse hook on `Edit` / `Write` / `MultiEdit`** ([#138](https://github.com/kostiantyn-matsebora/ginee/issues/138)). Cross-platform hook at `adapters/claude/hooks/pre-tool-use-edit.{ps1,sh}` exits 2 + stderr remediation on 5 violation classes — hot-spec frontmatter omission (D47) · `cap-bytes` overrun without `Optimized-By: ai-engineer` trailer queued (D44 + D47) · bare `D<N>` token introduction on `core/**` (D42) · `always` / `never` / `binding` / `mandatory` as rule modifier (D48) · always-loaded surface line-count bloat without trailer (D21). Pester (12 cases) + bats (11 cases) coverage; PSScriptAnalyzer + shellcheck clean. Migration: `migrations/pretooluse-edit-hook.md`.

  - **T3 — PreToolUse hook on `Bash`** ([#139](https://github.com/kostiantyn-matsebora/ginee/issues/139)). Cross-platform hook at `adapters/claude/hooks/pre-tool-use-bash.{ps1,sh}` blocks 4 destructive shell patterns — `git commit --no-verify` (or `-n`) · `git push --force` / `--force-with-lease` targeting `main` / `master` · `git reset --hard` · `gh pr create` without `--body` / `--body-file` / `--draft`. Allowlist preserves common legitimate workflows (force-with-lease on feature branches, soft reset, draft PRs). Pester (18 cases) + bats (17 cases) coverage. Migration: `migrations/pretooluse-bash-hook.md`.

  - **T4 — Compliance statusline** ([#140](https://github.com/kostiantyn-matsebora/ginee/issues/140)). Cross-platform single-line statusline at `adapters/claude/statusline.{ps1,sh}` surfaces compliance state in Claude Code's persistent status row — Class G (visible state, no enforcement). Format: `[ginee] #<N> · phase: ? · warm: ? · trailer: <ok|needed> · cap: <N>%`. Locally-derived fields ship now (issue # from branch · trailer status from `origin/main..HEAD` log · cap-bytes headroom on hot specs in diff); phase / warm / dispatches / self-lint print `?` placeholders until skill-runner-side warm-registry plumbing (D43) lands. Statusline MUST NOT crash the host — all paths wrapped in try/catch with bare `[ginee]` fallback. Migration: `migrations/compliance-statusline.md`.

  - **`.claude/settings.json` auto-merge on `/ginee-update`** ([#160](https://github.com/kostiantyn-matsebora/ginee/pull/160)). Closes the cross-tactic follow-up flagged in T2 / T3 / T4. Two new scripts — `core/scripts/sync-claude-settings.{ps1,sh}` — invoked from `install.ps1` / `install.sh` (claude branch) idempotently merge the `statusLine` block + 2 `PreToolUse` entries into the adopter's `.claude/settings.json`. Adopter customisations preserved — non-ginee `statusLine.command` is never replaced, existing PreToolUse entries with matching command paths are not duplicated, all other top-level keys (`env`, `theme`, `permissions`, ...) round-trip unchanged. Malformed JSON → warn + skip; bash adopters without `jq` → warn + skip + fall back to the manual snippet. Pester (9 cases) + bats (10 cases) coverage. Migration: `migrations/claude-settings-auto-merge.md`.

### Per-role context

No change vs 0.19.0. T1-T4 ship new files under `adapters/claude/hooks/` + `adapters/claude/statusline.{ps1,sh}` + `core/scripts/sync-claude-settings.{ps1,sh}` — none are role-kernel-loaded. `docs/reference/CONTEXT_COSTS.md` snapshot unchanged; team-lead headroom stays at ~23%; no role crossed the +10% material-shift threshold.

## 0.19.0 — 2026-05-25

### Added

- **Index-first read order — bedrock + dispatch-contract wiring + Source-reads audit trail** ([#125](https://github.com/kostiantyn-matsebora/ginee/issues/125)). Pre-this-release the consume-side rule of `core/protocols/index-protocol.md § Why` was buried at step 3 of `§ Role consumption pattern`. Cardinals silently fell through to full source reads whenever the dispatch prompt was free-text. Three coupled changes — top-level `## Read order` H2 promoted to bedrock; `core/protocols/triage-scoring.md § Auto-estimation on pickup` gains explicit `issue body + index entries only; raw reads require justification` clause; new `## Source reads (this dispatch)` mandatory-with-empty-case section in cardinal returns + narrow `### Format-only re-dispatch — single carve-out`. Adopter docs synced. Migration: `migrations/index-first-read-order.md`.

- **D45 — Change-governance gating + opt-out** ([#121](https://github.com/kostiantyn-matsebora/ginee/issues/121)). Pre-D45 CR / ADR authorship was unconditional once team-lead / SA judged the trigger condition met. D45 adds a pre-authorship intercept gate on both surfaces — ownership preserved per `core/protocols/doc-roles.md § Authorship`.
  - **Five-key gate** in `local/framework.config.yaml § change-governance` — `cr.enabled` · `cr.skip-when-issue-source` · `adr.enabled` · `adr.require-architectural-delta` · `prompt-before-create` (`always | never | non-trivial`).
  - **Per-task prefixes** — `cr:` / `nocr:` / `adr:` / `noadr:` resolved against config (precedence: prefix > config > default). Combine freely with `auto:` · `branch:` / `wt:` / `commit:` · `model:<tier>` · `notrack:`.
  - **Architectural-delta triggers (ADR gate)** — 5 triggers per `core/roles/solution-architect.md § ADR-gate`: component boundaries · wire contracts · NFR-bearing claims · architecture invariants · stack / topology / infrastructure. SA-judgment-retained cases preserved.
  - **Non-trivial heuristic** — fires when ≥ 2 delta triggers OR `local/requirements.md` register-diff non-empty.
  - **Skip-reason enum** logged under `## Decisions made`. CR: `config-disabled | issue-source-skip | prefix-override | user-declined`. ADR: `config-disabled | no-architectural-delta | prefix-override | user-declined`.
  - **Forced-interactive under auto-mode** — `prompt-before-create: always` OR `non-trivial` heuristic firing under `auto:` pauses + surfaces draft. Auto-mode does NOT elide this gate.
  - **Default change** — `cr.skip-when-issue-source: true` is the new default. Adopters who want pre-cutover behaviour set `false`.
  - Migration: `migrations/change-governance-opt-out.md`.

- **D46 — `core/` taxonomy flatten** (framework-hygiene; no associated issue). Pre-D46 the `core/` root mixed three concerns — the lifecycle spec (`process.md`), invariants (`VERSION`), and 12 ad-hoc protocol files that pre-dated the `protocols/` subdirectory.
  - **Moved files** — `automatic-mode.md` · `changelog-protocol.md` · `ci-watch.md` · `cross-agent-handoff.md` · `cross-domain-bugs.md` · `delivery-modes.md` · `doc-authoring-examples.md` · `doc-roles.md` · `github-integration.md` · `index-syntax.md` · `post-task-check-in.md` · `triage-scoring.md`. All via `git mv` (history preserved).
  - **Stays at root** — `core/process.md` (THE lifecycle spec) · `core/VERSION` (installer-fetch contract).
  - **No semantic change.** Every rule survives byte-for-byte; only paths changed. Watched-path patterns in `scripts/context-economy-check.ps1` already covered both locations.
  - **Reference sweep scope** — `core/**` · `adapters/**` · `extras/**` · `docs/**` · `migrations/<prior>.md` · `.github/workflows/` · `.github/ISSUE_TEMPLATE/` · `CLAUDE.md` · `PLAN.md`. `.github/release-notes/v*.md` not touched (point-in-time records).
  - **Adopter impact** — None for the typical install — `/ginee-update` replaces `<fw>/core/` wholesale. Adopters whose `local/` files cite framework spec paths run the sed snippet in the migration.
  - Migration: `migrations/core-taxonomy-flatten.md`.

- **D47 — Hot-spec frontmatter standard** ([#129](https://github.com/kostiantyn-matsebora/ginee/issues/129)). Pre-D47 the load topology of every hot-spec file was implicit — declared across CLAUDE.md's load-topology section + per-role kernel `Source of truth § always` rows + various per-spec preambles. The LLM paid the inference cost on every dispatch. D47 makes the load contract explicit at the head of each spec.
  - **5-key YAML frontmatter** — `audience` · `load` (`always` · `on-demand`) · `triggers` (required when `load: on-demand`) · `cap-bytes` (positive integer) · `reads-before-applying` (list; `[]` if none).
  - **New protocol — `core/protocols/hot-spec-format.md`** — declares schema + authoring rules + validator contract; self-applies as worked example.
  - **Sweep** — 41 hot-spec files acquire frontmatter via a single bounded PR. Lossless rule binds.
  - **Validator extension** — `scripts/context-economy-check.ps1` gains `Test-IsHotSpec` · `Get-HotSpecFileContent` · `Read-HotSpecFrontmatter` · `Test-HotSpecFrontmatter`. 6 failure reason codes (`missing` · `malformed` · `missing-key` · `invalid-load` · `empty-triggers` · `invalid-cap-bytes`). Same `Optimized-By: ai-engineer` trailer-bypass machinery as existing gates.
  - **Pester coverage** — 19 new test cases (61 total pass; 91.64% whole-script coverage); PSScriptAnalyzer clean.
  - **Role kernel frontmatter merge** — hot-spec keys appended INTO the existing Claude subagent frontmatter block (single `---` block).
  - **`cap-bytes` tiered above current file size** — corpus has hot specs from 4 KB to 32 KB. Sweep set each file's cap at the next clean tier. Subsequent load-on-demand splits are the canonical tightening path.
  - **Validator scope** — `core/process.md` · `core/process/*.md` · `core/protocols/*.md` · `core/roles/*.md` · `core/roles/*.details.md`. Excluded: `core/templates/*.md` · `core/skills/ginee-*/SKILL.md` (already use AgentSkills frontmatter) · `local/roles/*.md` (adopter-owned per D37).
  - Migration: `migrations/hot-spec-frontmatter.md`.

- **D48 — RFC 2119 keyword convention** ([#130](https://github.com/kostiantyn-matsebora/ginee/issues/130)). Pre-D48 the framework mixed binding-strength conventions — `**bold**` for emphasis, `always` for MUST-ish, `binding` for MUST NOT-bypass, `mandatory` / `required` for MUST. LLMs spent interpretation cycles disambiguating between emphasis and normative weight. D48 collapses the axis to RFC 2119 keywords (MUST · MUST NOT · SHOULD · SHOULD NOT · MAY).
  - **New mandatory check #6** added to `core/process.md § Documentation style § Mandatory checks before report-as-done` + `core/protocols/doc-authoring-protocol.md`.
  - **Standing-checks count refresh.** 5-standing-checks → 6; subagent-return-surface 6-checks → 7. Touchpoints — `core/process.md § Reporting`, `core/protocols/doc-authoring-protocol.md` (multiple lines), `docs/CONCEPTS.md`, `docs/CHEATSHEET.md`.
  - **Imperative voice carve-out.** Numbered procedures where every step is implicitly MUST do not need RFC 2119 keywords on every step.
  - **Enforcement.** LLM self-review at draft time; same machinery as the rest of the doc-authoring protocol. No external linter; no auto-rewrite.
  - **Scope.** Forward-only — existing rules across `core/`, `adapters/`, `extras/`, and authored adopter docs stay as-written until next edited.
  - **Paired bad/good example** added at `core/protocols/doc-authoring-examples.md § 14`.
  - Migration: `migrations/rfc2119-keywords.md`.

- **D49 — Output-schema sidecars** ([#131](https://github.com/kostiantyn-matsebora/ginee/issues/131)). Pre-D49 only `core/templates/phase-report.md` had an explicit cardinality table + section templates + forbidden patterns + self-lint marker. Every other structured output the framework produces (dispatch prompts · sticky `ginee:score` · audit comments · sub-issue body + cadence · per-thread review reply + sticky `ginee:review-cycle`) was reconstructed by pattern-matching prior examples on every dispatch. D49 closes the gap with five output-schema sidecars under `core/protocols/`.
  - **5 new specs** — `dispatch-prompt-schema.md` · `score-comment-schema.md` · `audit-comment-schema.md` · `sub-issue-dispatch-schema.md` · `review-cycle-schema.md`. Each follows the phase-report meta-template (Schema · Section templates · Forbidden patterns · Worked example · Self-lint checks).
  - **Lossless cross-ref consolidation** in 5 existing surfaces — sentence-appends only; no rule deleted or reworded.
  - **Audit-comment registry closed** at 3 marker types (`ginee:value-prompt` · `ginee:complexity-estimate` · `ginee:score-recompute`); new types via row addition.
  - Migration: `migrations/output-schema-sidecars.md`.

### Changed

- **Per-role context costs grew ~5–10%** vs v0.18.0 from D45–D49 spec additions:

  | Role | v0.18.0 | v0.19.0 | Δ | Headroom |
  |---|---:|---:|---:|---:|
  | `ai-engineer` | 23,854 | 25,241 | +5.8% | ~37% |
  | `qa-engineer` | 33,161 | 34,752 | +4.8% | ~37% |
  | `backend-engineer` | 33,847 | 35,703 | +5.5% | ~35% |
  | `frontend-engineer` | 34,099 | 35,966 | +5.5% | ~35% |
  | `devops-engineer` | 39,443 | 41,298 | +4.7% | ~36% |
  | `solution-architect` | 39,868 | 44,025 | **+10.4%** | ~32% |
  | `team-lead` | 63,694 | 69,402 | +9.0% | ~23% |

  All roles under ceiling; team-lead retains the smallest headroom at ~23% but stays above the 20% release-checklist floor. SA crosses the +10% material-shift threshold (D45 + D47 contributions). Full per-role snapshot in `docs/reference/CONTEXT_COSTS.md`.

## 0.18.0 — 2026-05-25

### Added

- **D44 — Per-class doc-size caps** ([#113](https://github.com/kostiantyn-matsebora/ginee/issues/113)). Pre-D44 the framework governed doc *shape* (D22 / D26 doc-authoring protocol) + *whole-PR delta* (D21 context-economy gates) but had no per-class *size* dimension. Load-on-demand doc classes (ADR · CR · UI mockup) could grow unbounded; once over an unbudgeted threshold every dispatch that loaded them paid the cost; `ai-engineer` learned about bloat ad-hoc, after it landed.
  - **Default caps.** ADR ≤ 4096 bytes · CR ≤ 6144 bytes · UI doc ≤ 4096 bytes. Bytes (not tokens) for v1 — matches existing `scripts/context-economy-check.ps1` semantics; token-count is a future refinement.
  - **Class detection by path prefix.** A file is classified ADR / CR / UI when its path starts with the configured `adr-directory:` / `cr-directory:` / `ui-directory:` from `local/framework.config.yaml` AND ends in `.md`. `ui-directory:` is a new key (default `docs/ui/`). Adopters who don't configure a directory see no enforcement for that class.
  - **Adopter override per class.** New `doc-size-caps:` block in `local/framework.config.yaml`: per-class `<class>: {cap-bytes: <N>}` raises or lowers vs framework default; per-class `<class>: disabled` opts out for that class entirely; absent block → all defaults apply silently.
  - **Enforcement — two layers, hard cap with trailer bypass.** (1) Gate layer — `scripts/context-economy-check.ps1` runs three new functions (`Read-DocSizeCapConfig` · `Get-DocClass` · `Get-DocSizeCapBreach`) on every changed file matching a configured class; checks *current total size* (not delta) against cap. Breach without `Optimized-By: ai-engineer` trailer fails the gate. Reuses the existing Claude Code hook · git hooks · CI workflow wiring — no new hooks, no new workflows. (2) PR-time CI layer — same script, run as a CI job on the PR target ref.
  - **Breach routing.** A cap breach is an `ai-engineer` dispatch trigger per `core/roles/ai-engineer.md § Process integration`. Scope = breaching file(s); lossless rule binds. Acceptance = file size at or below cap OR `Optimized-By: ai-engineer` trailer on the commit landing the optimization pass. Natural path is the framework's own load-on-demand pattern (extract to sibling spec, cross-ref from kernel) proven on D35 process split + the protocol family.
  - **4 mandatory checks** before pushing a breaching commit — class identified (one unambiguous answer) · cap resolved correctly (per-class entry → `disabled` → framework default) · lossless rule honoured · trailer present (exactly once). LLM self-review; `team-lead` surfaces one-line advisory on violation.
  - **Decisions affected.** D21 — extended with per-class check on top of whole-PR threshold; same trailer bypass. D22 — cross-referenced (size complements shape; 5 shape-checks unchanged). D25 — `ai-engineer` charter gains breach-as-dispatch-trigger; SA's doc-class ownership unchanged. D35 — load-on-demand pattern applied at doc level.
  - **Test coverage.** 10 new Pester cases in `tests/context-economy-check.Tests.ps1` — defaults · per-class override · `disabled` opt-out · adopter-specified directory · trailer bypass · `Read-DocSizeCapConfig` defaults · `Get-DocClass` matching. All 41 tests pass.
  - **Files updated** — `core/protocols/doc-size-caps.md` (NEW) · `core/process.md § Documentation style` · `core/templates/framework.config.yaml` · `core/roles/ai-engineer.md § Process integration` · `scripts/context-economy-check.ps1` · `tests/context-economy-check.Tests.ps1` · `migrations/doc-size-caps.md` (NEW) · `CLAUDE.md` + `PLAN.md` · this file · `.github/release-notes/v0.18.0.md`.
  - **Backwards compatibility.** Purely additive. `local/framework.config.yaml` schema gains optional `ui-directory:` + `doc-size-caps:` keys; absent → no-op. No installer change. No skill-trigger change. No `core/` rule walked back. Forward-only — pre-existing oversized docs surface as advisories on next touch; no retroactive sweep. Adopters who don't configure doc classes see no change.
  - Migration: `migrations/doc-size-caps.md`.

### Fixed

- **D43 — Claude adapter warm-reuse plumbing carve-out** ([#117](https://github.com/kostiantyn-matsebora/ginee/issues/117)). D36-warm-specialist-reuse placed the warm registry in team-lead's own context. On Claude that is architecturally unrealisable — team-lead is itself a subagent spawned via the `Agent` tool; its conversation does not survive across dispatches, and subagents do not inherit the `Agent` / `SendMessage` tools they would need (D32). A second dependent gap: `SendMessage` is gated behind `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (off by default). Net pre-D43 — the 15–50 k token / task savings warm reuse was designed for were silently never realised on every default Claude install.
  - **Env-var prerequisite.** `adapters/claude/install.md § Warm specialist reuse § Prerequisite` carries the `.claude/settings.json` snippet + restart note + claude-code#36196 / #42737 / #35240 references. Adopters who cannot enable it set `warm-reuse.enabled: false` per existing D36 opt-out.
  - **Registry ownership refined per adapter.** Team-lead-side on adapters where team-lead has the resume tool (D36 as written). Skill-runner-side on adapters where team-lead is a subagent without the resume tool (Claude today) — the main thread is the only surface with both durable cross-dispatch state and the `Agent` / `SendMessage` tools.
  - **Narrow D28-skill-runner-boundary carve-out.** Skill-runner gains mechanical-only *warm-reuse plumbing*: registry holder · team-lead bootstrap (`Agent` with `run_in_background: true` on first dispatch · team-lead agent-id capture · `SendMessage` to team-lead every later cycle) · specialist agent-id round-trip (capture on first `Agent` call · registry passed as input to team-lead's next dispatch · `SendMessage` instructions executed verbatim). Decision authority unchanged — warm-vs-fresh is team-lead's surface; skill-runner never reads `mode:` and second-guesses; never picks an agent-id when team-lead omitted the field; never spawns/releases outside an approved plan-line.
  - **Plan-line shape.** Every team-lead dispatch line carries `role: <cardinal>` · `mode: fresh-spawn | warm-resume` · `agent-id: <id>` (required on warm-resume) · standard dispatch contract + drift advisory. Skill-runner reads the line and either `Agent`-spawns (`fresh-spawn`, capture id into registry) or `SendMessage`-resumes (`warm-resume` to the named id).
  - **Loop.** `skill-runner first batch → spawns team-lead background + records team-lead-id → SendMessage(tl, "plan ...") → team-lead plans (with mode + agent-id per line) → user approve → skill-runner verbatim-executes → returns collected → SendMessage(tl, returns + updated registry) → team-lead synthesises + next plan → loop → Phase 8: release all recorded agent-ids; registry cleared`.
  - **Known caveats documented.** Raw-`agent-id` resume only (claude-code#42999); first-resume cache miss (claude-code#44724). Both upstream, both outside ginee's control. Registry stores raw ids; cache-miss cost amortised across warm-reuse savings.
  - **Decisions affected.** D28 — narrow carve-out for warm-reuse plumbing (mechanical only). D32 — verbatim-execution cycle extended with `mode:` / `agent-id:` plan-line fields. D36 — Claude adapter implications corrected (registry ownership adapter-specific). D35 — unchanged (carve-out lives in `core/process/dispatch.md`).
  - **Files updated** — `adapters/claude/install.md § Warm specialist reuse` (full rewrite: prerequisite · architecture · plan-line shape · loop · caveats · worked round-trip · opt-out) · `core/process/dispatch.md` (skill-runner surface-boundary table + warm-reuse parallelism row) · `migrations/warm-specialist-reuse.md § Adapter implications` (Claude bullet refined; cross-ref to new migration) · `migrations/warm-reuse-claude-plumbing.md` (NEW) · `PLAN.md` + `CLAUDE.md` (D43 row) · this file · `.github/release-notes/v0.18.0.md`.
  - **Backwards compatibility.** Purely additive. No `local/` schema change beyond the existing `warm-reuse.enabled` override (D36). No installer change. No script change. Adopters on Claude who enable the env var get the warm-reuse savings on next dispatch; adopters who skip see no behavioural change vs pre-D43 (warm reuse silently fell back before; now it does so explicitly, with the documented forced-fresh trigger surfacing the cause).
  - Migration: `migrations/warm-reuse-claude-plumbing.md`.

- **Skill-runner tracking-mode posture leak — D28 boundary + D39 resolution chain gap** ([#114](https://github.com/kostiantyn-matsebora/ginee/issues/114)). Pre-fix the load-bearing runtime specs (`core/process/dispatch.md § Skill-runner — surface boundary` · `core/protocols/github-integration.md § Sub-issue dispatch`) enumerated orchestration ops as plan / synthesis / gate text / re-dispatch / reconciliation / default selection / `local/bindings.md` lookup — but did **not** name tracking-mode posture. Skill-runner read the silence as permission, pre-resolved tracking to `in-context` from runtime conditions (deferred commits · worktree mode · no-PR linkage), and wrote the posture into the hand-off brief. Team-lead absorbed the line verbatim into Phase 1 "Forbidden this cycle"; three Phase 4 dispatches ran in-context with no sub-issues, no `<!-- ginee:dispatch-map -->` sticky, no per-cardinal time accounting, and a permanently unusable D39 resume protocol on that parent. Rules land in files the LLM actually loads at runtime — not in version-bound migration files that ship as switch-version instructions.
  - **Skill-runner surface boundary** (`core/process/dispatch.md`). New D39 interaction paragraph parallel to the existing D29 one — explicit *"never set, carry, or pre-resolve tracking-mode posture"* rule with the runtime-condition orthogonality clause. Forbidden-ops table row adds *tracking-mode posture (D39-sub-issue-dispatch four-tier resolution)*.
  - **Resolution chain closure** (`core/protocols/github-integration.md § Sub-issue dispatch`). New `**Chain is closed — team-lead re-derives on every parent dispatch.**` paragraph below the existing Resolution line. States no fifth tier exists; skill-runner never sets / recommends / carries posture; team-lead re-derives on every parent dispatch (initial pickup + cross-session resume); upstream postures discarded without inheritance; runtime conditions orthogonal; only adapter degradation demotes tier 4.
  - **Authoring failure mode** (`core/roles/team-lead.details.md § Sub-issue dispatch § Common failure modes`). New table row — *"Skill-runner-injected tracking-mode posture absorbed verbatim"* with the correct shape (discard + re-derive via chain). Pairs with the existing in-context-despite-sub-issue-mode-active row.
  - **Skill-runner forbiddens** (`core/skills/ginee-pick-up/SKILL.md`). § Forbidden D28 line extended — tracking-mode posture in the hand-off payload now explicitly listed alongside plan-drafting / synthesis / routing / default-selection.
  - **Files updated** — `core/process/dispatch.md` · `core/protocols/github-integration.md` · `core/roles/team-lead.details.md` · `core/skills/ginee-pick-up/SKILL.md` · this file. **Migration files unchanged** — D28-skill-runner-boundary.md and D39-sub-issue-dispatch.md are version-switch instructions, not load-bearing runtime context.
  - **Backwards compatibility** — purely additive. No `local/` schema change. No `framework.config.yaml` additions. No new D-number (clarification to existing D28 + D39 runtime specs). Adopter action: **none**. Existing in-flight tasks with skill-runner-injected postures finish as today; the rule binds on the **next** parent dispatch under any issue.

### Changed

- **D42 — Migrations are upstream-only; ginee runtime surface is D-free** ([#115](https://github.com/kostiantyn-matsebora/ginee/issues/115)). Two coupled changes from a single owner directive — *"ginee does not give a shit regarding Ds and what is it"*. Pre-D42 the installer shipped `core/MIGRATIONS/` (36 files / ~228 KB at the v0.17.0 cutover) and `/ginee-update` read those local files; framework spec files cited migrations + locked decisions by D-ID everywhere. Migration files were update-time-only artefacts paying a runtime distribution cost; D-ID citations conflated the owner's private decision log with rules the LLM follows at task time.
  - **(1) Migration relocation + fetch on demand.** `core/MIGRATIONS/` → `migrations/` at repo root via `git mv`. Filenames drop the `D<N>-` prefix (`installer-fetch-on-update.md`, `model-tier.md`, …). `install.{ps1,sh}` prune `migrations/` (new home) AND legacy `core/MIGRATIONS/` (pre-cutover cleanup). `/ginee-update` Step 7 rewritten as 6 sub-steps — enumerate (Contents API on `(old, new]` window) · fetch (raw URL to memory) · surface (H1 + 5-line summary + `## Action required` verbatim) · per-item `yes / skip / all-yes / all-skip` gate · report skips · network-failure inline. Same bootstrap-layer-fetch pattern as the D27 installer flow.
  - **(2) Ginee runtime surface is D-free.** Every `D<N>` / `(D<N>)` / `D<N>-<slug>` reference stripped from the LLM-loaded surface — `core/`, `adapters/_shared/`, `adapters/<X>/install.md` + companion files, `extras/`, `core/templates/issues/`. Rules now self-describe by location (`core/process.md § Skill-runner`), not by decision number. Self-lint marker `<!-- D29 self-lint: pass -->` → `<!-- self-lint: pass -->`.
  - **Walked back.** D34 (slug-glued taxonomy pairing) — `§ Taxonomy identifier pairing` section deleted from `core/protocols/doc-authoring-protocol.md`; mandatory-checks count reduced by one (renumbered). D40 (`(D<N>)` tag mandate on release-notes sidecars) — rule deleted from `core/protocols/changelog-protocol.md`; mandatory-checks count reduced by one (renumbered). Sidecars retain user-value voice + word-cap rules; tag suffix is no longer required.
  - **Kept D-history on**: `PLAN.md` (private design log) · `CLAUDE.md` (framework-dev orientation; pruned from adopter install) · `docs/**` (adopter-facing reference) · `.github/release-notes/v*.md` (release announcements; historical references OK) · `README.md`. These surfaces are not loaded by the LLM at adopter-task time; design-history references stay readable for humans and future maintainers tracing decisions.
  - **Migration files preserved upstream.** All 36 historical migrations + the new `migrations-upstream-only.md` cutover record remain at `migrations/` in the framework repo, addressable via github.com URLs and the `/ginee-update` fetch path indefinitely.
  - **Adopter migration.** None required. New installs land with no `<fw>/migrations/`. Pre-cutover installs get `<fw>/core/MIGRATIONS/` pruned mechanically on first D42+ update. Going forward, `/ginee-update` fetches the `(old, new]` migration window from upstream and surfaces each with a per-item approval gate.
  - **Files updated** — `migrations/` (36 files renamed via `git mv` to drop `D<N>-` prefix + NEW `migrations-upstream-only.md` cutover record) · `install.ps1` + `install.sh` (`migrations` + `core/MIGRATIONS` added to prune list; banner comment updated; rename-notice path updated to upstream URL) · `core/skills/ginee-update/SKILL.md` (Step 1 sentinel note · Step 7 rewritten as 6 sub-steps · `Forbidden` extended) · ~100 files under `core/` + `adapters/` + `extras/` + `core/templates/issues/` swept clean of D-references · `core/protocols/doc-authoring-protocol.md` (D34 § deleted; renumbered) · `core/protocols/changelog-protocol.md` (D40 `(D<N>)` tag mandate deleted; renumbered) · `core/templates/phase-report.md` (self-lint marker re-prefixed) · `CLAUDE.md` + `PLAN.md` (D42 entry + walked-back tags on D34 / D40) · this file · `.github/release-notes/v0.18.0.md` (NEW) · `tests/install.Tests.ps1` + `tests/install.bats` (new prune-step coverage).
  - **Backwards compatibility** — purely additive on the adopter-action surface. Installer flags unchanged · skill triggers unchanged · `local/*` schema unchanged · `framework.config.yaml` unchanged. Pre-cutover installs migrate forward mechanically; nothing to undo on the adopter side.
  - Migration: `migrations/migrations-upstream-only.md`.

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
  - **Files updated** — `core/protocols/blueprint-diff-protocol.md` (NEW, full spec) · `migrations/blueprint-diff-gate.md` (NEW) · `core/templates/framework.config.yaml` (`visual-source-of-truth:` block) · `core/process/phase-4-implementation.md` (entry precondition rule) · `core/roles/frontend-engineer.md` (Mockup-ownership trigger row) · `core/templates/phase-report.md` (Verification-log row example) · `core/process.md` (load-on-demand index entry) · `CLAUDE.md` + `PLAN.md` (D41 row) · `.github/release-notes/v0.17.0.md` (NEW) · `docs/CONCEPTS.md` + `docs/CHEATSHEET.md` (adopter-facing co-update).
  - **Backwards compatibility** — purely additive. New `visual-source-of-truth:` block defaults derived from existing `mockup:` key — adopters with mockup configured get the protocol on next dispatch without manual config edits. Adopters with no mockup configured — protocol auto-skips with cite `"visual-SoT untouched — protocol n/a"`. No script changes. No installer change. No test changes. Adopter action on upgrade: **none** (override patterns optional).
  - Migration: `migrations/blueprint-diff-gate.md`.

## 0.16.0 — 2026-05-24

### Added

- **D39 — Sub-issue dispatch — cross-session traceability + time-tracking** ([#106](https://github.com/kostiantyn-matsebora/ginee/issues/106)). Pre-D39 every `team-lead` → cardinal dispatch lived only in the chat transcript — session end = state evaporated; next-day pickup reconstructed from PR diffs + scattered commit messages. On issue-sourced tasks team-lead now creates one GitHub sub-issue per cardinal dispatch under the parent.
  - **Lifecycle.** Title `[<phase>:<cardinal>] <task>`; body per `core/templates/sub-issue-dispatch.md`; labels `ginee:role:*` + `ginee:phase:*` + inherited `value:*`/`complexity:*`. Cardinal posts progress comments carrying `time:` + `cumulative:`; D29 phase-report return doubles as the closing comment with mandatory `## Time spent`. Stop-state (`Status: In-progress`) → progress comment; sub-issue stays open. Parent sticky `<!-- ginee:dispatch-map -->` aggregates per-cardinal rollup.
  - **Assignee precedence** (per issue #106 owner comment) — non-empty human assignee overrules the `ginee:role:*` tag; cardinal suspended until cleared. Rationale: GitHub's assignee column means a human is responsible; cardinals are not GitHub users; when both exist, the human (visible accountability) wins.
  - **Opt-out resolution** — `notrack:` task prefix → `ginee:track:off` parent label → `local/framework.config.yaml § dispatch.tracking` → framework default (`sub-issues` on `github.repo`). TODO / freeform / no-`gh` adapters fall back to in-context.
  - **Resume across sessions** — parent + open sub-issues = full state; D36 registry is in-conversation only, sub-issue history bridges the cross-session gap.
  - **Decisions affected** — D14 (sub-issue surface gains dispatch-create) · D26 (sub-issue artefacts subject to 5-check self-lint) · D29 (conditional `## Time spent` section) · D33 (marker on closing comment) · D34 (slug-glued IDs in titles) · D35 (lifecycle lands in `core/process/dispatch.md`) · D36 / D17 (compatible).
  - **Files updated** — `migrations/sub-issue-dispatch.md` (NEW) · `core/templates/sub-issue-dispatch.md` (NEW) · `core/protocols/github-integration.md § Sub-issue dispatch` (NEW section) · `core/process/dispatch.md` (new rule row) · `core/roles/team-lead.md` (kernel bullet) · `core/roles/team-lead.details.md § Sub-issue dispatch` (NEW — authoring procedure + failure modes) · `core/templates/phase-report.md` (conditional `## Time spent` + in-flight cadence reference) · `core/templates/framework.config.yaml` (`dispatch.tracking:` block) · `CLAUDE.md` + `PLAN.md` (D39 row) · `docs/CHEATSHEET.md` + `docs/CONCEPTS.md` + this file.
  - **Backwards compatibility** — purely additive. New optional `dispatch.tracking:` key in `local/framework.config.yaml`; absent ⇒ default `sub-issues` on `github.repo`-configured adopters. Pre-existing in-flight tasks unchanged; sub-issue mode activates on the **next** dispatch under that parent. Adopters wanting legacy behaviour set `dispatch.tracking: in-context` once.
  - Migration: `migrations/sub-issue-dispatch.md`.

- **D40 — Changelog + release-notes protocol** ([#81](https://github.com/kostiantyn-matsebora/ginee/issues/81)). Codifies surface-specific voice + shape rules for the three release-surface files (`docs/CHANGELOG.md` · `.github/release-notes/v*.md` · `migrations/D<N>-*.md`). Closes a recurring drift mode — pre-D40 no spec bound these surfaces to surface-specific voice + word-count rules; the v0.12.0 sidecar took 4 authoring passes to converge.
  - **Topology.** Three surfaces, three voices, three caps. Migration spec — framework-dev voice, no cap. CHANGELOG — verbose record per Keep-a-Changelog; lead-in ≤ 25 words + sub-bullets. Release-notes sidecar — user-value voice, ≤ 20 words per bullet, `(D<N>)` tag suffix.
  - **Voice rule.** Sidecar bullets lead with the adopter-visible verb / outcome — *"`/ginee-update` works again"* not *"Step 1 no longer requires installer scripts inside `.agents/ginee/`"*.
  - **5 mandatory checks** before publishing a sidecar — per-bullet word cap · user-value voice · `(D<N>)` tag · no implementation boilerplate · migration link in footer.
  - **Enforcement** — LLM self-review at draft time; one-line orchestrator advisory on violation; never auto-rewrites; never re-dispatches purely for format. Same machinery as D22 / D26 / D29 / D30.
  - **D34 carve-out** — sidecar D-tags stay bare (`(D31)`); slug-glued form (`D31-model-tier`) is required only in framework specs · adopter docs · cardinal returns where copy-paste-to-filesystem-search matters. Sidecars carry the spec link in the footer.
  - **Spec location.** `core/protocols/changelog-protocol.md` is team-lead-loaded (release-artefact authoring lives on team-lead's surface per D25's doc-ownership map — framework-meta governance alongside CRs · work-breakdown). Moved from `core/process.md § Documentation style` to `core/roles/team-lead.md` kernel after code-review feedback; the 6 non-team-lead cardinals correctly pay zero bytes for this rule.
  - **Files updated** — `migrations/changelog-protocol.md` (NEW) · `core/protocols/changelog-protocol.md` (NEW, load-on-demand spec) · `core/protocols/doc-authoring-protocol.md § Scope` (release-surfaces row) · `core/protocols/doc-authoring-examples.md § 14` (NEW bad/good pair — sidecar bullet) · `core/roles/team-lead.md` (kernel bullet) · `docs/CONCEPTS.md` + `docs/CHEATSHEET.md` (adopter-facing) · `CLAUDE.md` + `PLAN.md` (D40 row) · this file.
  - **Backwards compatibility** — purely additive. Framework-internal authoring rule; no adopter file affected; no `local/*` schema change. Forward-only — pre-D40 sidecars (`v0.4.0` → `v0.15.0`) not retroactively rewritten. Adopter action: **none**.
  - Migration: `migrations/changelog-protocol.md`.

### Per-role context cost — team-lead only

`team-lead` grew **+2,047 bytes (~+3.4%)** since v0.15.0 — D39 + D40 each added a kernel bullet. **All 6 non-team-lead cardinals unchanged** (D39 cardinal-kernel addenda + D40 `core/process.md` pointer were both refactored to team-lead's surface after code-review feedback). Headroom on every role > 30%; no ceiling adjustments needed.

Full per-role snapshot: [`reference/CONTEXT_COSTS.html`](https://kostiantyn-matsebora.github.io/ginee/reference/CONTEXT_COSTS.html).

## 0.15.0 — 2026-05-24

### Added

- **D36 — Warm specialist reuse across dispatches within a task lifecycle** ([#90](https://github.com/kostiantyn-matsebora/ginee/issues/90)). Pre-D36 every `@<role>` dispatch fresh-spawned a subagent that reloaded its kernel, role-details, `core/process.md`, its `phase-participation:` files, and `local/index/*` — even when the same role had been dispatched earlier in the same task. D36 amortises the reload cost: on 2nd+ dispatch within one Phase 1–8 task AND within the role's D35-process-md-load-topology participation window, team-lead resumes the existing specialist via the adapter's native mechanism (Claude `SendMessage` to a `run_in_background: true` agent) instead of fresh-spawning. **Token savings:** 15–50 k tokens of duplicated reload eliminated per task on typical 3–5-dispatch workloads. Forced-fresh on stale state · worktree mismatch · `local/*` drift · explicit `fresh:` prefix · resume-failure. Adapters without resume capability fall back to fresh-spawn (no behavioural change). Adopter opt-out via `local/framework.config.yaml § warm-reuse.enabled: false`. Migration: `migrations/warm-specialist-reuse.md`.
- **D37 — Adapter pointers auto-load `local/roles/<role>.md` as cardinal extension** ([#94](https://github.com/kostiantyn-matsebora/ginee/issues/94)). Pre-D37 an adopter-authored `local/roles/<cardinal>.md` file was orphaned by every adapter — the documented pattern was silently broken. D37 adds `local/roles/<role>.md` as the final numbered read in every shared pointer at `adapters/_shared/agents/<role>.md`: load if present, augments charter, never replaces. Adopters who already author cardinal extensions gain auto-loading on next upgrade without any change on their side. Custom-new-role registration is unchanged (still registers via per-adapter pointer entry / `team-lead` discovery flow). D21-context-economy-gates watched-paths extended for `local/roles/*.md` at the "other watched" tier (50-line / 2 KB net-added). Migration: `migrations/local-role-extensions.md`.
- **D38 — Host capability tools — adapters expose, specialists discover and leverage** ([#85](https://github.com/kostiantyn-matsebora/ginee/issues/85)). Pre-D38 ginee specialists had no explicit awareness of capability tooling the host adapter exposes (skills · MCP servers · IDE integrations). Output quality varied based on whether the dispatched agent happened to know about a relevant tool. D38 adds an affinity-injection protocol: each adapter declares its capability tools in `install.md § Specialist-tool affinity` with role/task affinity hints; team-lead reads the table (cached per task) and surfaces matching tools as a one-line hint in each dispatch prompt. **Specialist judgment never overruled** — "prefer if available", not "must use". Claude adapter ships 4 reference rows (`frontend-design` · `code-review` · `verify` · `security-review`). Adapters lacking an affinity section → graceful degradation (no hint surfaced). Adopter opt-out via `local/framework.config.yaml § capability-tools` (`disabled: [<tool-id>, …]` or `enabled: false`). Migration: `migrations/host-capability-tools.md`.

## 0.14.0 — 2026-05-24

### Added

- **D35 — `core/process.md` load topology split** ([#89](https://github.com/kostiantyn-matsebora/ginee/issues/89)). Pre-D35 the 477-line lifecycle spec was always-loaded on every cardinal dispatch — every role paid the cost of phases it never participated in. D35 extracts the 8 phase blocks + orchestration content into `core/process/phase-<N>-<name>.md` + `core/process/dispatch.md`; slims `core/process.md` to common-only (Purpose · Reading order · Engineering principles · Doc style · Reporting · Coordination protocol · Load-on-demand index). Each cardinal kernel declares `phase-participation: [N, M, …]` in frontmatter; adapter loads only matching phase files. Roster: `team-lead [1-8]` + `dispatch.md` · `solution-architect [1, 2, 4, 5, 6, 7]` · `backend / frontend / devops [2, 4, 5, 6]` · `qa-engineer [5, 6]` · `ai-engineer []`. **Token reduction:** backend Phase 4 dispatch -38%; qa Phase 5 -48%; ai-engineer -58%. Spec: `migrations/process-md-load-topology.md`.
- **Per-role context-cost measurement + CI gate + adopter doc** ([#100](https://github.com/kostiantyn-matsebora/ginee/pull/100)). `scripts/measure-role-context.ps1` measures the framework-only context cost per cardinal on first dispatch. Auto-generates the snapshot in `docs/reference/CONTEXT_COSTS.md` from templates under `scripts/templates/` (substitution-only — no markdown formatting logic in the script). New Pester test (`tests/measure-role-context.Tests.ps1`) — 17 assertions including doc-currency gate, D35 phase-participation contract verification, and per-role byte ceilings from `scripts/templates/role-context-ceilings.json` (single source of truth shared by the test and the doc generator). Refresh flow: `pwsh -File scripts/measure-role-context.ps1 -UpdateDoc`.
- **Release checklist in `CLAUDE.md`**. 5 numbered steps before tagging — refresh snapshot · analyse movement vs. prior tag · tighten ceilings if stabilised · verify gate · commit + tag. Catches snapshot-drift across releases.

### Changed

- **`core/process.md` slimmed from 477 to ~180 lines.** All cardinals except `team-lead` see materially less always-loaded context. Migration is automatic on the next dispatch — anchor moves are documented in `migrations/process-md-load-topology.md § Anchor migration` for adopters citing `core/process.md § Phase N` from `local/*`.
- **`*-protocol.md` specs relocated to `core/protocols/`** ([#98](https://github.com/kostiantyn-matsebora/ginee/pull/98)). `core/doc-authoring-protocol.md` · `core/index-protocol.md` · `core/iteration-protocol.md` · `core/options-protocol.md` → `core/protocols/<name>.md`. Sweeps 65 files of internal references. Adopters citing the old paths from `local/*` should update their cites.
- **Team-lead-only kernel summaries relocated to `core/process/dispatch.md`** ([#99](https://github.com/kostiantyn-matsebora/ginee/pull/99)). `GitHub integration · Triage scoring · Post-task check-in` kernel summaries moved out of always-loaded `core/process.md`. Specialists no longer pay for orchestration-only spec summaries.
- **D21 watched-paths extended** — `core/process/*.md` + `core/protocols/*.md` join the "other watched" tier (50-line / 2 KB net-added).

### Fixed

- **Reference sidebar surfaces the new context-costs page** ([#101](https://github.com/kostiantyn-matsebora/ginee/pull/101)). The layout's hard-coded list was missed in #100 — the new page rendered without a sidebar entry. Layout now includes `CONTEXT_COSTS` in both the top-nav active-state detector and the section-nav sidebar.

## 0.13.0 — 2026-05-23

### Added

- **D34 — Taxonomy identifier short-name pairing** ([#88](https://github.com/kostiantyn-matsebora/ginee/issues/88)). Every cardinal output, ginee-authored GitHub artefact, and adopter doc cites taxonomy items in slug-glued form — `D28-skill-runner-boundary`, `ADR-0001-topology-derivation-five-pass`, `CR-0010-component-ci-pipeline`, `FR-04-deploy-rollback`, `NFR-02-cost-cap`, `ASR-03-availability-budget`. Slug is zero-cost for the agent (already in filename) and high-value for the reader — copy-paste into a filesystem search returns the spec immediately.
  - **Out of scope** — issue / PR / commit-SHA / NPM-package-name references stay bare. `#87`, `[PR #84](...)`, git SHAs, package names in code blocks are correct as-is.
  - **Resolution lookup** — file-backed via filesystem listing (`ls migrations/D<NN>-*.md`); inline-table (FR / NFR / ASR) via register-row noun-phrase slugify; index-class via `manifest.yaml § name:`.
  - **On resolution failure** — surface inline (`D28-?? (slug lookup failed)`); orchestrator carries forward to next dispatch; never invent a slug.
  - **Self-lint** — extends D22 / D26 / D29 mandatory check #5 (cross-references). Regex `\b(D|ADR-?|CR-?|FR-?|NFR-?|ASR-?)\d+\b` not followed by `-<slug>` trips. Excluded contexts: issue / PR / SHA / package-name references.
  - **Files updated** — `core/process.md § Mandatory checks` (check #5 extended) · `core/protocols/doc-authoring-protocol.md` (NEW § Taxonomy identifier pairing) · `core/templates/phase-report.md § ## Decisions made` (slug-glued cite-form) · `core/templates/pr-description.md § Cites` (CR / ADR / FR / NFR examples) · 2 framework issue templates · 7 cardinal role kernels (one-line addendum per `## Reporting`) · `core/protocols/doc-authoring-examples.md § 13` (NEW bad/good pair) · `CLAUDE.md` + `PLAN.md` (D34 row) · this file · `migrations/identifier-short-name-pairing.md` (NEW).
  - **Backwards compatibility** — purely additive. No `local/` schema change. No installer change. Reporter content unchanged. 6 checks count unchanged (rule extends check #5). Forward-only — historical outputs not rewritten; existing taxonomy files not renamed.
  - Migration: `migrations/identifier-short-name-pairing.md`. Adopter action: none.

### Fixed

- **D32 — Claude adapter accept-orchestrated subagent dispatch** ([#87](https://github.com/kostiantyn-matsebora/ginee/issues/87)). Claude Code's `Agent` / `Task` tool is top-level only — subagents do not inherit it, so team-lead-as-subagent under the D28 hand-back rule cannot fan out to specialists. Pre-D32 the dispatch silently degraded ("answer from your own context") on every multi-specialist phase. D32 narrows the D28 surface boundary on the Claude adapter only.
  - **Split.** Decision authority stays with team-lead; *mechanical execution of approved dispatch contracts* moves to the skill-runner.
  - **Cycle.** `skill-runner mechanical batch → @team-lead (plan) → user approve → skill-runner (mechanical dispatch verbatim, parallel where independent) → skill-runner collect returns → @team-lead (synthesis + next decision) → loop` until team-lead returns phase-complete.
  - **Skill-runner still banned** from plan drafting · synthesis · gate text · routing reconciliation · default selection · `local/bindings.md` lookup — D32 permits *execution* of team-lead's already-decided dispatches, never origination.
  - **Other adapters unaffected** — D28 hand-back rule unchanged on Cursor · Copilot CLI · Codex · generic.
  - **Files updated** — `adapters/claude/install.md` (new `§ Subagent dispatch limitation (D32)`) · `core/process.md § Skill-runner — surface boundary` (adapter-aware caveat) · `CLAUDE.md` (D32 row) · `migrations/claude-adapter-subagent-dispatch.md` (NEW).
  - **Backwards compatibility** — purely additive. No `local/` schema change. No `framework.config.yaml` keys. No installer change. Pre-D32 Claude-adapter invocations were silently degrading; D32 just documents the loop that makes them work.
  - Migration: `migrations/claude-adapter-subagent-dispatch.md`. Adopter action: none.

- **D33 — D29 phase-report schema enforcement hardening** ([#86](https://github.com/kostiantyn-matsebora/ginee/issues/86)). Pre-D33 the 6 mandatory checks at report-as-done were aspirational — agents skipped them silently when substance felt useful, and the orchestrator had no structural detection surface to surface the skip. The compound failure also breached the D28 skill-runner boundary: a non-compliant verbose return tempted the skill-runner to "clean up" the content into a tidy summary table, which is synthesis (team-lead's surface). D33 closes both gaps with a single-line marker.
  - **Marker** — literal `<!-- D29 self-lint: pass -->` on the last line of every cardinal-dispatch return. Agent's attestation that the 6 checks ran.
  - **Orchestrator behaviour on absence** — one-line advisory at receive-time + carry-forward rephrasing on the subagent's next dispatch; never re-dispatches for format; never auto-rewrites.
  - **Worked advisory table** — 5 violation classes paired with exact advisory text.
  - **D28 cross-reference** — skill-runner **forbidden** from cleaning up a non-compliant return before passing to team-lead. Cleanup is the regression-grade workaround issue #86 catalogued.
  - **Honest-fail rule** — if a check failed and could not be restructured (lifted to `## Notes`), still write the marker. Marker attests the *checks ran*, not that they *passed-with-zero-restructure*.
  - **Files updated** — `core/templates/phase-report.md` (new `§ Before-return checklist + mandatory marker (D33)` + extended orchestrator-behaviour section with advisory examples + carry-forward block) · 7 cardinal role kernels (`; end with <!-- D29 self-lint: pass --> marker (D33).` clause appended to each `## Reporting`) · `core/roles/team-lead.details.md § Common failure modes` (new D33 row) · `core/process.md § Skill-runner — surface boundary (D28)` (D29 / D33 interaction bullet) · `core/process.md § Reporting — schema-bound (D29)` (mandatory-marker bullet) · `core/protocols/doc-authoring-examples.md § 12` (NEW bad/good full-return example) · `CLAUDE.md` + `PLAN.md` + this file (D33 surface) · `migrations/phase-report-self-lint-hardening.md` (NEW).
  - **Backwards compatibility** — purely additive. Schema unchanged. 6 checks unchanged. No `local/` schema change. No installer change. Forward-only — existing closed dispatches not retroactively required.
  - Migration: `migrations/phase-report-self-lint-hardening.md`. Adopter action: none.

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
  - **Files updated** — `core/roles/*.md` (× 7) add `default-tier:` to frontmatter · `adapters/_shared/agents/*.md` (× 7) add pre-resolved `model:` to frontmatter · `core/templates/framework.config.yaml` adds optional `model-tier:` block · `core/process.md § Dispatch & parallelism rules` adds 5-line per-task tier subsection · `install.ps1` + `install.sh` Claude branch reads `model-tier:` overrides and rewrites pointer `model:` lines · `tests/install.Tests.ps1` Pester coverage · 4 adapter `install.md` files · `docs/CONCEPTS.md` + `docs/CHEATSHEET.md` + this file (D31 entries) · `CLAUDE.md` + `PLAN.md` (D31 row) · `migrations/model-tier.md` (NEW).
  - **Backwards compatibility** — purely additive. No `local/` schema change forced. Absent `model-tier:` → framework defaults apply silently. Existing dispatches unaffected until adopter sets a tier or uses the prefix. Forward-only.
  - Migration: `migrations/model-tier.md`. Adopter action: none.

- **D30 — Adopt-existing-solution as a first-class Phase-2 option** ([#75](https://github.com/kostiantyn-matsebora/ginee/issues/75)). Binds every Phase 2 design proposal AND every iteration-protocol Propose step (Phase 4–7 > 15-min sub-tasks with a live adopt-vs-build axis) to surface ≥ 1 adopt-existing-solution candidate — or an explicit `(none viable — <reason>)` cite. Stops the LLM-default failure mode of authoring novel implementations when no rule forces the proposer to look outward first.
  - **Schema** — 4 candidate types: `adopt` (name · version · source link · license · one-line fit rationale) · `build` (scope · rationale why adoption rejected) · `hybrid` (adopt portion + build portion + boundary rationale) · `(none viable — <reason>)` (empty-research escape hatch). Every candidate explicitly tagged; no silent mixing.
  - **Floor** — hard ≥ 1 `adopt` candidate OR `(none viable)`; soft encourage 2–3 for non-trivial scope.
  - **5 mandatory checks before surfacing** — adopt floor present · citations complete · tagging explicit · empty research documented (`(none viable — <reason>)`) · fit rationale concrete (not hand-waved).
  - **Forbidden patterns** — silently skipping adoption research · build-only option lists on a live axis · hand-waved adopt candidates (`"mature library"` alone) · silently mixing adopt + build without explicit `hybrid` tag · citing a library without fit rationale.
  - **License + supply-chain stance** — defer to adopter `local/`. Framework requires the citation but expresses no opinion on which licenses pass.
  - **Research depth** — cite-only baseline (name · version · source · license · fit). SBOM cross-check / full-ADR are escalations the proposer MAY adopt; not mandated.
  - **Enforcement** — LLM self-review against the schema before surfacing. No external linter; no runtime dependencies. Same machinery as D22 / D26 / D29. Orchestrator surfaces a one-line advisory on violations but never re-dispatches purely for format and never auto-rewrites.
  - **Spec topology** — new load-on-demand `core/protocols/options-protocol.md` carrying full schema · scope · 5 checks · forbidden patterns · enforcement · worked example. Always-loaded `process.md § Phase 2` + `iteration-protocol.md § Propose` carry tiny pointer lines only. Matches the D22 doc-authoring-protocol + D29 phase-report split.
  - **Files updated** — `core/protocols/options-protocol.md` (NEW spec) · `core/process.md § Phase 2 — Design & architecture` (option-shape rule pointer) · `core/protocols/iteration-protocol.md § Each iteration § Propose` (adopt-vs-build axis bullet) · `core/roles/solution-architect.md § Design § Phase 2` (first-class design axis) · 5 engineer kernels (backend · frontend · devops · qa · ai) add a 1-paragraph "Adoption research before authoring" pointer above `## Forbidden actions` · `core/protocols/doc-authoring-examples.md § 11` (NEW bad/good pair) · `docs/CONCEPTS.md` + `docs/CHEATSHEET.md` + this file (D30 entries) · `CLAUDE.md` + `PLAN.md` (D30 row) · `migrations/adopt-existing-solution.md` (NEW).
  - **Backwards compatibility** — purely additive. No `local/` schema change. No new commands. Existing proposals on closed tasks unaffected — forward-only.
  - Migration: `migrations/adopt-existing-solution.md`. Adopter action: none.

- **D29 — Strict subagent-return schema** ([#69](https://github.com/kostiantyn-matsebora/ginee/issues/69)). Binds every cardinal-dispatch return to a strict schema — same machinery as D22 / D26 doc-authoring protocol applied to the subagent-return surface. Cardinal returns were today's largest single contributor to orchestration-thread bloat (1,500–15,000 chars per dispatch typical). D29 cuts that by ~70%.
  - **Schema** — 5 mandatory sections (`## Files touched` · `## Decisions made` · `## Verification log` · `## Open issues` · `## Next dispatch needed`; empty case `(none)`) + 2 conditional (`## Hand-off` on forced handoff per `core/protocols/cross-agent-handoff.md`; `## Stop-state` when `Status: In-progress`) + 1 optional escape hatch (`## Notes` ≤ 200 words; ≤ 5-line code-snippet carve-out).
  - **6 mandatory checks before report-as-done** — 5 from D22 / D26 (no paragraph > 2 sentence terminators · no multi-sentence table cells · no bullet > 25 words without sub-bullets · inventories as tables · cross-references cite anchors) + *no narrative preamble* (first non-Status line must be a `##` section header).
  - **Forbidden patterns** — narrative preamble · restated dispatch context · code snippets outside the Notes carve-out · verbose rationale outside `## Notes` · parenthetical comma-soup.
  - **Enforcement** — LLM self-review against the schema before returning; no external linter. Orchestrator surfaces a one-line advisory on violations but never re-dispatches purely for format and never auto-rewrites (analogous to D14 reporter-content forbidden).
  - **Open-question picks.** `## Notes` cap ≤ 200 words. Code snippets banned outside a ≤ 5-line Notes carve-out. Iteration-protocol intermediate returns use the same schema with `(in-progress)` markers + required `## Stop-state`. Failed dispatches add the conditional `## Hand-off` section.
  - **Files updated** — `core/templates/phase-report.md` rewritten as schema · `core/process.md § Reporting` (new always-loaded section) · 7 role kernels gain or amend `## Reporting` with the schema pointer · `core/protocols/doc-authoring-protocol.md § Scope` extended + new § Enforcement for subagent returns · `core/protocols/doc-authoring-examples.md § 10` (new bad/good pair with measured 68.5% reduction on a real Phase-4 return) · `docs/CONCEPTS.md` + `docs/CHEATSHEET.md` + `CLAUDE.md` + `PLAN.md` (D29 entries).
  - **Worked measurement** — bad return 3,603 chars (narrative + restated context + per-file rationale + embedded code) → schema-bound 1,136 chars; reduction (3603 − 1136) / 3603 = 68.5%. Documented inside `core/protocols/doc-authoring-examples.md § 10`.
  - **Backwards compatibility** — purely additive. No `local/` schema change. No new commands. Existing dispatches on closed tasks unaffected — forward-only.
  - Migration: `migrations/strict-subagent-return-schema.md`. Adopter action: none.

- **D28 — Skill-runner / team-lead surface boundary** ([#71](https://github.com/kostiantyn-matsebora/ginee/issues/71)). Locks the structural rule that prevents the skill-runner main thread from orchestrating. Pre-D28 the framework's role definitions assigned orchestration to `team-lead` but no spec named the skill-runner (the thread running a `ginee-*` skill body — Claude main thread / Cursor main loop / Copilot CLI main loop / AGENTS.md-driven shell) as a distinct surface or banned it from making orchestration decisions. The slip recurred across long sessions: skill-runner authored Phase 1–8 plans itself, synthesized parallel specialist returns, answered routing-governance questions by reading `local/bindings.md` directly, proposed reconciliation options with default-selection ("I'll pick option 1 if you don't redirect").
  - **Skill-runner defined** — thin mechanical surface running a `ginee-*` skill body. Not a role; not an orchestrator. Carries only the operations the skill text spells out.
  - **Allowed (mechanical ops only)** — parse prompt + identify task source · label / sticky / audit-comment ops · branch ops per resolved delivery mode · the skill text's one named first-batch dispatch · report the mechanical result to the user.
  - **Forbidden (must dispatch `@team-lead`)** — plan drafting · synthesis of parallel specialist returns · lifecycle gate text · re-dispatch after the first batch · routing reconciliation on engineer pushback · default selection · `local/bindings.md` lookup to settle routing questions.
  - **Hand-back rule** — every `ginee-*` skill dispatches `@team-lead` after its first mechanical batch. From there every orchestration decision flows through team-lead. If a routing or governance question arises mid-flight, the skill-runner dispatches `@team-lead` to answer; it never answers by reading project files itself.
  - **Worked counter-example** from issue #71 lives in `core/process.md § Skill-runner — surface boundary` and `migrations/skill-runner-boundary.md`.
  - **Files updated** — `core/process.md` (new top-level § Skill-runner — surface boundary) · `core/roles/team-lead.md` (new Inbound trigger surfaces section with skill-runner hand-back row) · `core/roles/team-lead.details.md § Common failure modes` (new D28 row) · 4 skill files (`ginee-pick-up` · `ginee-address-review` · `ginee-triage` · `ginee-promote-discussion`) gain a hand-to-team-lead step + skill-runner-forbiddens entry · `core/protocols/github-integration.md § Inbound — pick up an issue` re-narrated to mark mechanical vs team-lead-owned steps.
  - **Backwards compatibility** — purely additive. No `local/` schema change. No new commands. No adapter re-install. Existing skill invocations continue working; only the regression path (skill-runner drifting into orchestration) is now structurally forbidden.
  - Migration: `migrations/skill-runner-boundary.md`. Adopter action: none.

### Fixed

- **D27 — `/ginee-update` now reaches a standard install** ([#67](https://github.com/kostiantyn-matsebora/ginee/issues/67)). Pre-D27 the `ginee-update` skill's Step 1 required `install.ps1` + `install.sh` + `core/VERSION` inside `.agents/ginee/`, but the bootstrap intentionally prunes the installers (they belong to the deploy layer, not runtime). Every standard install therefore exited at Step 1 with a misleading `framework not found at <path>` — making `/ginee-update` non-functional for everyone.
  - **Step 1 (Locate)** — now requires **only** `<fw>/core/VERSION`. `core/VERSION` is the framework existence sentinel; the installer is fetched on demand.
  - **Step 6 (Run)** — fetches `install.{ps1,sh}` from `https://raw.githubusercontent.com/<github.framework-repo>/<target-ref>/install.{ps1,sh}` to a temp dir, then executes via `pwsh -File` / `bash` with the detected adapter + project root passed explicitly. `<github.framework-repo>` resolves from `local/framework.config.yaml` (default `kostiantyn-matsebora/ginee`); `<adapter>` is the single non-`_shared` subdir under `<fw>/adapters/`; `<root>` is `<fw>/../..`.
  - **Trade-offs.** Three options considered: (a) skill fetches installer from upstream (chosen — symmetric with bootstrap, `.agents/ginee/` stays runtime-only, no version skew); (b) installer self-copies into `<fw>` (rejected — version-skew risk + pollutes runtime tree); (c) fallback chain (rejected — ambiguous resolution).
  - **Adapter delta.** All four `adapters/{claude,copilot-cli,agents-md,generic}/install.md § Updates` sections refreshed — drop the misleading `.\install.ps1 -UpdateOnly` "recommended" line (implied a co-located installer); replace with `/ginee-update` primary + bootstrap one-liner manual fallback.
  - **Chicken-and-egg.** Pre-D27 installs land the fix by running the manual bootstrap one-liner once (the documented #67 workaround); subsequent updates flow through the fixed `/ginee-update`.
  - **Installer itself unchanged.** D27 is purely a skill-internal change. No schema change to `local/framework.config.yaml`. `github.framework-repo` was already wired in D14.
  - Migration: `migrations/installer-fetch-on-update.md`. Adopter action: one-time bootstrap one-liner per the migration; no other action required.

## 0.11.0 — 2026-05-22

### Added

- **D26 — D22 scope extension to ginee-authored GitHub artefacts** ([#64](https://github.com/kostiantyn-matsebora/ginee/issues/64), [#65](https://github.com/kostiantyn-matsebora/ginee/pull/65)). D22 doc-authoring protocol previously scoped only adopter markdown. D26 extends to (a) GitHub issue bodies authored via `ginee-file-*` skills + (b) framework-authored comments — Phase-transition · sticky `ginee:score` / `ginee:review-cycle` · audit comments · per-thread review-replies.
  - **Same machinery as D22** — same 5 mandatory checks per `core/process.md § Documentation style § Mandatory checks before report-as-done`; same default-shape map (inventories → tables · steps → numbered lists · multi-rule prose → parent + sub-bullets).
  - **Lint covers every section, including Summary** — no section-by-length exemption. A one-sentence Summary still trips the mandatory checks if it packs a comma-separated inventory into a parenthetical clause.
  - **Enforcement** — LLM self-review embedded in the `ginee-file-*` skills + comment-cadence procedures. No external linter; no runtime dependencies. Violations surface as restructure suggestions in the user-approval prompt.
  - **Reporter-authored content unchanged** — D14 forbidden ("Never edit an issue body authored by another reporter") upheld. `ginee-pick-up` MAY surface a polite restructure advisory at pickup; never auto-edits.
  - **3 new bad/good example pairs** in `core/protocols/doc-authoring-examples.md` — Issue Summary (parenthetical-soup → bulleted scope) · Issue body section (semicolon-chained inventory → table) · Phase-transition comment (dense paragraph → structured transition).
  - **4 issue templates** under `core/templates/issues/` gain a D26 shape-rule banner at top.
  - **Adapter delta** — none (templates ship via existing `core/templates/issues/` copy step).
  - Migration: `migrations/doc-protocol-scope-extension.md`. Adopter action required: none — purely additive.

## 0.10.0 — 2026-05-22

### Added

- **D25 — Classical-architect SA model + doc-ownership redistribution** ([#37](https://github.com/kostiantyn-matsebora/ginee/issues/37), [#61](https://github.com/kostiantyn-matsebora/ginee/pull/61), [#62](https://github.com/kostiantyn-matsebora/ginee/pull/62)). `solution-architect` redefined from central-scribe + Phase-7-only sign-off to a **classical architect** with three activities across the whole lifecycle. Matches how real engineering teams operate (ginee's north star).
  - **Three activities.** **Design** — Phase 1 elicits FRs / NFRs / Constraints (`local/requirements.md`) + derives ASRs via ATAM utility tree (`local/asr-utility-tree.md`); Phase 2 authors target architecture; greenfield-vs-delta mode resolved at Phase 1. **Review** — any phase, on engineer-proposed architectural changes (contract / topology / stack / NFR-affecting); APPROVE / REJECT / REQUEST-CHANGES; no code edits. **Governance** — continuous, **scoped only to PRs touching SA-owned files** per `local/bindings.md § Source-of-truth ownership` (NOT every Phase 4 / 5 / 6 PR — keeps SA out of the bottleneck path).
  - **Two-file register split** — ASRs are an *outcome* of requirements, not the same level. `local/requirements.md` (FR / NFR / Constraints inputs) + `local/asr-utility-tree.md` (ASRs derived via ATAM). New templates: `core/templates/requirements-register.md` + `core/templates/asr-utility-tree.md`.
  - **Doc-ownership redistribution.** CRs · project-instruction file · work-breakdown → `team-lead` (coordination decisions, not architectural). CI/CD guide · infra runbooks · deployment guides → `devops-engineer`. Backend READMEs · API docs · service docs → `backend-engineer`. Frontend READMEs · component docs · style guides → `frontend-engineer`. Test plans · scenario docs · QA reports → `qa-engineer`. Architecture doc · ADRs · diagrams · requirements register · ASR utility tree stay with SA. Mockup unchanged. Every non-SA-owned doc edit is SA-reviewed for architectural coherence.
  - **`ai-engineer` counterpart generalized** — was SA ↔ ai-engineer pre-D25; now all-roles ↔ ai-engineer. `core/doc-co-ownership.md` **renamed** to `core/protocols/doc-roles.md` + rewritten.
  - **Process hooks** — `core/process.md § Phase 1 / 2 / 4 / 5 / 6 / 7` updated with SA hooks per the issue's phase-by-phase table. Phase 7 retained but **lighter** because governance ran continuously.
  - **CR template** moved from `solution-architect.details.md` → `team-lead.details.md` per the ownership reassignment. ADR template stays with SA.
  - **Adopter migration** — force re-attribution sweep on `@team-lead rediscover` (discovery Step 8c). Adopters MUST run rediscover on next upgrade; existing docs migrate to the new ownership map. Greenfield-flag detection added. New register files initialized from the discovered architecture doc when one exists. Full spec: `migrations/classical-architect.md`.
  - **All 5 adapter renderings refreshed** — `_shared/agents/{solution-architect,team-lead,ai-engineer,backend-engineer,frontend-engineer,devops-engineer,qa-engineer}.md` pointer files.
  - **User docs refreshed** ([#62](https://github.com/kostiantyn-matsebora/ginee/pull/62)) — `docs/CONCEPTS.md` (7-cardinal table + phased lifecycle + Source-of-truth ownership + new § Classical-architect SA model), `docs/GETTING_STARTED.md` (discovery + post-D25 rediscover callout), `docs/CHEATSHEET.md` (strict-domain + new § Classical-architect mini-block).

### Changed

- **CLAUDE.md § Hard constraints — binding `User-docs co-update` rule** ([#62](https://github.com/kostiantyn-matsebora/ginee/pull/62)). Every adopter-facing framework change (new skill · new D-decision · role-model change · new spec / template · new register / artefact) updates `docs/` (CONCEPTS · GETTING_STARTED · CHEATSHEET · index as applicable) **in the same PR**. Internal-only changes (D21 gate · CI internals · framework-dev hygiene · D18 script-quality · D19 backend-coverage) exempt. Phase-7 SA review verifies coverage. Codifies the recurring miss observed across pre-D25 feature PRs (#41 · #43 · #47 · #51 · #54 · #55 · #57) — backfilled in #59; binding from D25 onward.

## 0.9.0 — 2026-05-22

### Added

- **D24 — `ginee-address-review` skill / `@team-lead address-review #<PR>` command** ([#53](https://github.com/kostiantyn-matsebora/ginee/issues/53), [#57](https://github.com/kostiantyn-matsebora/ginee/pull/57)). PR review-comment ingestion under skill / command parity. Sits between Phase 7 (internal SA review) and Phase 8 (user acceptance) for PRs exposed to **external** review (peer maintainers, OSS contributors, user-as-reviewer). Pre-D24 the framework had no protocol for this interval — adopters briefed the orchestrator manually; no detection, no routing, no accountability, no comment cadence.
  - **7-step procedure** (`core/protocols/github-integration.md § Review-comment ingestion`) — resolve PR + verify checked-out branch == head; fetch `pulls/{N}/comments` + `/reviews`; deduplicate by `thread-id`; build routing records per `local/bindings.md § Source-of-truth ownership` (fallback `team-lead`; ambiguous → surface-closest role); surface consolidated plan table `# / thread / file:line / role / proposed action / action-type` for forced-interactive approval; dispatch specialists in parallel returning fix-track patches (Phase-6-shaped) or reply-track text + marker; squash fix patches into one cycle commit + push; post per-thread replies; post sticky cycle summary.
  - **Lossless coverage** — every plan-table thread MUST end the cycle as `fix` (patch landed) OR `reply` (text + marker). No silent drops. Same principle as `core/protocols/index-protocol.md § Lossless rule for index § Coverage rule`.
  - **Idempotency** — re-invocation rebuilds plan for net-new + revisited threads only; cycle ordinal increments; prior stickies preserved (immutable log).
  - **HTML markers** — two new prefixes (`<!-- ginee:review-reply r=<thread-id> -->` per-thread, `<!-- ginee:review-cycle n=<N> -->` sticky); join the D23 set (`ginee:score / value-prompt / complexity-estimate / score-recompute`).
  - **Skill / command parity principle** — codifies what was implicit pre-D24. Every user-invocable workflow ships both surfaces (skill in AgentSkills-capable clients; command in every adapter) with identical behaviour; skill is a thin wrapper loading the shared spec.
  - **`auto:` mode (D12)** — plan-table approval is a **forced-interactive trigger** per `core/protocols/automatic-mode.md § Forced-interactive triggers`. No exception for "trivial" remarks (slope; explicit out-of-scope).
  - **Explicit invocation only** — no extension of the D20 CI-watch loop; auto-detection of new review comments is out-of-scope.
  - **Adapter delta** — +1 cheat-sheet row per adapter (`claude` / `copilot-cli` / `agents-md` / `generic`). No install-script changes (skill auto-bridges via the existing `core/skills/` copy step).
  - **Skill count** — 11 → 12 (`docs/ARCHITECTURE.md` + CLAUDE.md D16 refreshed).
  - **Backward compatibility** — purely additive. No `local/` schema changes; no `migrations/D24-*.md` (cheat-sheet refresh on next framework update is the only adopter-facing change).
  - **Out of scope** — drafting reviews on others' PRs; auto-resolving threads; cross-repo coordinated reviews; sentiment analysis; skill-only or command-only delivery.
  - Spec: `core/protocols/github-integration.md § Review-comment ingestion`. Dispatch: `core/roles/team-lead.details.md § Review-comment dispatch`. Template: `core/templates/pr-comment-cadence.md`. Skill: `core/skills/ginee-address-review/SKILL.md`.

## 0.8.0 — 2026-05-22

### Added

- **`ginee-update` skill — framework self-update via the orchestrator** ([#55](https://github.com/kostiantyn-matsebora/ginee/pull/55)). New uniform self-update surface for adopters. Triggers `@team-lead update [<tag|branch|sha>]` / *"update ginee"* / *"upgrade the framework"* / *"pull the latest ginee"* now load `core/skills/ginee-update/SKILL.md` and drive the existing `install.{ps1,sh} --update-only` flow — **no installer changes**. Preserves `local/`; refreshes `core/` + `adapters/` + `extras/`.
  - **7-step procedure** — locate framework → read current `core/VERSION` → resolve target ref (latest release / explicit tag / branch / SHA via `gh release view` with `iwr`/`curl` fallback) → compare versions (refuses downgrades unless `--allow-downgrade`) → **surface plan + wait for explicit user approval** (never auto-runs) → run installer per platform → report VERSION delta + CHANGELOG range + new `migrations/*.md` files with their `Action required` excerpts.
  - **Post-update report** also diffs `local/index/manifest.yaml` SHA-256s against the freshly fetched `core/` — surfaces drift; offers `ginee-reindex` per the standard staleness flow (never auto-reindexes).
  - **Forbiddens** — never auto-run; never edit `local/*`; never mask installer failure (surfaces exit code + last 20 lines of stderr; no retry); never bypass an adopter's pinned `--ref` in `local/framework.config.yaml § framework.pinned-ref` without confirming.
  - **Cross-client coverage** — activation rows added to all four adapters (`claude` / `copilot-cli` / `agents-md` / `generic`) + `adapters/claude/CLAUDE-pointer.md` workflow list.
  - **Backward compatibility** — manual `./install.{ps1,sh} --update-only` continues to work unchanged. Adopters opt in by refreshing the framework once via the existing path (so the skill lands); future updates flow through the skill.
  - **Skill count** — 10 → 11 across CI workflow, `docs/ARCHITECTURE.md`, `docs/CHEATSHEET.md`, and the Claude pointer block.
  - Migration: `migrations/ginee-update-skill.md`.

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
  - Spec: `core/protocols/index-protocol.md § Reconciliation` (renamed from `§ Re-extraction`). Migration: `migrations/reindex-reconcile.md`.

- **`team-lead` strict-domain hardening — close "feels fast → I'll just do it" bypass** ([#50](https://github.com/kostiantyn-matsebora/ginee/issues/50), [#51](https://github.com/kostiantyn-matsebora/ginee/pull/51)). Closes an observed regression where the orchestrator self-executed specialist-owned work on a "feels fast" heuristic — 5–7 min estimates ballooning into ~60 min main-thread sessions with no stop-and-report. Kernel + protocol wording now names the failure mode and blocks it.
  - **`core/roles/team-lead.md § Forbidden actions`** — new bullet: *"Never self-execute work in a specialist-owned surface, regardless of estimated size."* Includes the correct dispatch shape for ≤ 15 min work (explicit estimate flag → iteration-protocol load skipped).
  - **`core/process.md § Dispatch & parallelism rules`** — new row: *"Surface owns the dispatch decision"* — routing is owned by the touched surface, not by perceived effort.
  - **`core/process.md § Strict-domain rule`** — *"Size is not an exemption"* sub-bullet + pointer to the failure-modes catalogue.
  - **`core/protocols/iteration-protocol.md § Stoppable intermediate states`** — new `### Scope-overrun trigger` sub-section: > 2× initial estimate → mandatory stop-and-report. Applies symmetrically to specialists and orchestrator in-thread work.
  - **`core/roles/team-lead.details.md § Common failure modes`** — new regression-grade catalogue of observed orchestrator violations + correct dispatch shape per pattern.
  - **Adopter action** — none. Clarifications to existing rules; all changes additive. No config / API / surface change.
  - Migration: `migrations/team-lead-strict-domain-hardening.md`.

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
  - **Tests** — fulfilled by the worked-sort fixture in `core/protocols/triage-scoring.md § Examples`; no runtime `.ps1` / `.sh` helper ships (consistent with skill-as-markdown norm).
  - Spec: `core/protocols/triage-scoring.md`. Migration: `migrations/triage-scoring.md`.

## 0.5.1 — 2026-05-19

### Changed

- **Trimmed CLAUDE.md decision-register rows D17–D22** ([#36](https://github.com/kostiantyn-matsebora/ginee/issues/36), [#44](https://github.com/kostiantyn-matsebora/ginee/pull/44)). Six rows that had drifted into 650–1396-char prose paragraphs inlined into the always-loaded table are now ~250-char one-line pointers, sorted numerically. **Savings: CLAUDE.md −3.03 KB** (20.38 KB → 17.34 KB). Full prose retained in `PLAN.md § D17`–`§ D22` + per-decision `migrations/D{17,18,19,20,21,22}-*.md` (load-on-demand). Adds D21 + D22 canonical-long-form rows to `PLAN.md` (previously missing — shipped straight into CLAUDE.md).
- **D21 — PLAN.md reclassified from "always-loaded" to "other watched"** in the context-economy gate. PLAN.md is the canonical design doc, read at session start but not auto-loaded by the harness on every dispatch (per #36 framing). Threshold relaxes from 25 lines / 1 KB to 50 lines / 2 KB. +1 Pester regression test.

## 0.5.0 — 2026-05-19

### Added

- **D22 — Doc-authoring protocol for adopter docs** ([#39](https://github.com/kostiantyn-matsebora/ginee/issues/39), [#42](https://github.com/kostiantyn-matsebora/ginee/pull/42)). Promotes `core/process.md § Documentation style — structure over prose` from aspirational → **binding** for adopter outputs (architecture doc, ADRs, CRs, READMEs, runbooks, scenarios, API docs).
  - **Three-file load topology** (anticipates upcoming #37 amplifying per-role doc authorship):
    - `core/process.md § Documentation style` (always-loaded, +1.17 KB once globally) — binding declaration + default-shape map + 5 mandatory checks.
    - `core/protocols/doc-authoring-protocol.md` (2 KB, load-on-demand at Phase 5 / report-as-done) — enforcement-via-discovered-stack + attestation format + out-of-scope.
    - `core/protocols/doc-authoring-examples.md` (5 KB, load on first-time / explicit request) — 6 paired bad / good examples (component inventory / design properties / ADR rationale / runbook / API table / scenario).
  - **No custom ginee lint.** Enforcement piggybacks on adopter tooling — `team-lead` discovery records markdown / prose linters (markdownlint, vale, proselint, prettier-md) via the existing `builtin:commands` + `builtin:conventions` recipes; roles run `${commands.lint.docs}` at Phase 5 / report-as-done. No-tool fallback recommends a baseline; adopter decides — never auto-install.
  - **Attestation** — one-line entry in phase-report Verification log + PR-description Verification log.
  - Cross-issue: hard-reject coupling with #37 (classical SA Review) deferred until #37 lands; TODO marker in migration note.
  - Spec + migration: `migrations/doc-authoring-protocol.md`.

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
  - Spec + migration: `migrations/context-economy-gates.md`.
- **Repo went public** at [github.com/kostiantyn-matsebora/ginee](https://github.com/kostiantyn-matsebora/ginee). Documentation site live at [kostiantyn-matsebora.github.io/ginee](https://kostiantyn-matsebora.github.io/ginee/). Default install path is now anonymous — no GitHub auth required to fetch the framework.
- **Public OSS release prep** — `LICENSE` (MIT), `SECURITY.md`, `.github/CODEOWNERS`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/ISSUE_TEMPLATE/*.yml`.
- **Documentation site** under `docs/` — Jekyll cayman theme with indigo + amber palette, custom layout, theme toggle, page TOC.
- **Index protocol — per-file load triggers** (issue #11). Cardinal role `## Source of truth` tables gain a `Load when` column. Two-tier model: `always` for foundational reads + scope-loaded with trigger phrase. Specialist reports loaded set in first response. Adopter overrides via new `local/bindings.md § Per-role load-trigger overrides`.
- **Index protocol — consumer coupling** (issue #10). Every extracted class declares `consumed-by: [<role>...]` in `manifest.yaml`. Novel classes without a declared consumer are not extracted; discovery report flags any dormant index. New `local/bindings.md § Project-specific index citations` section wires novel classes to cardinal roles without editing upstream kernels.
- **Installer auto-migration** — `install.ps1` / `install.sh` detect pre-rebrand `.agents/engineering-team/` and rename to `.agents/ginee/` on first run, preserving `local/` contents.

### Changed

- **Installer: hybrid release-tarball + git-clone fetch path.** Default `--ref` changes from `main` to `latest` — resolves to the most recent published release via the `/releases/latest` HTTP redirect, downloads the release tarball, verifies SHA256 against the published `SHA256SUMS.txt`, then unpacks. No `git` required for tagged-release installs (the common path). `--ref main` / `--ref <branch>` / `--ref <sha>` still fall back to `git clone --depth 1 --branch <ref>` (requires `git` on PATH). Forks (`--repo` override) always use `git clone`. Each external operation emits a `>> ...` step banner; on failure, a structured dump of Ref / Target / RepoUrl / Adapter / PSVersion / cwd surfaces so future failures are diagnosable from the console alone. Fixes [adopter-reported "filename, directory name, or volume label syntax is incorrect" error](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/installer-tarball-path.md) on Windows PowerShell, plus two related `install.ps1` issues — `param()` scope-leak under `iex` (pre-existing `$Ref` / `$Target` / `$Adapter` in caller scope defeated the defaults) and provider-prefixed `(Get-Location).Path` values that `git.exe` couldn't parse. Migration: `migrations/installer-tarball-path.md`.
- **Release pipeline: extended exclude list** in `release.yml` rsync step. Tarballs cut from the next release onward ship "ready to use" — no install-time pruning needed for tag-sourced installs.
- **Orchestrator renamed: `project-manager` → `team-lead`.** Better matches the ginee tagline *"an AI software engineering team that behaves like a real one"* — engineering teams have team leads, not project managers. `project-manager` retained as a permanent alias alongside `orchestrator`; existing `@project-manager` dispatches continue to route unchanged. Files renamed: `core/roles/project-manager.md` → `team-lead.md` (+ `.details.md` counterpart) + `adapters/_shared/agents/project-manager.md` → `team-lead.md`. Installer auto-deletes the stale `.claude/agents/project-manager.md` / `.github/agents/project-manager.agent.md` pointer on `--update-only`. Migration: `migrations/project-manager-renamed-team-lead.md`.
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
- **Cross-domain bugs** procedure in `core/protocols/cross-domain-bugs.md` — propose → implement → verify cycle.
- **Cross-agent hand-off** procedure in `core/protocols/cross-agent-handoff.md` — diagnose ≠ fix.

### Notes

This release represents the dogfood baseline used during the framework's own development. The first public-OSS-ready release will be tagged after the rebrand to `ginee` lands.
