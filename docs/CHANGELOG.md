---
title: Changelog
description: "Release history."
permalink: /CHANGELOG.html
---

# Changelog

All notable changes to ginee. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); the framework adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

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
