# Engineering Team — Project Instructions

## What this project is

`engineering-team` is a vendor-neutral OSS framework that packages a **7-cardinal multi-agent collaboration model** + a **generic engineering process** for any LLM coding tool (Claude Code, GitHub Copilot, Cursor, Codex, or fallback generic).

The framework ships **process knowledge only** — no domain, stack, architecture, or SDLC opinions. Project-specific knowledge is discovered on first run by the `project-manager` role and lives in a `local/` layer that survives upstream updates. Project knowledge sources (markdown docs, diagrams, mockups) are **referenced**, never copied — doc changes propagate instantly.

This is the **framework's own development repo**, not an adopter project.

## Source of truth (read before any work)

| File / location | Role |
|---|---|
| `PLAN.md` | Design document + 11 locked decisions (D1–D11) + phased roadmap + verification |
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
engineering-team/
├── core/                       # vendor-neutral spec — IMMUTABLE for adopters; we author here
│   ├── VERSION                 # SemVer (currently 0.1.0)
│   ├── process.md              # 33K — phased lifecycle + coordination + principles
│   ├── roles/                  # 7 cardinal role definitions
│   │   ├── project-manager.md  # orchestrator + discovery flow
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

## Locked decisions (D1–D11)

Canonical in the plan file. Summary:

| # | Decision |
|---|---|
| D1 | Hybrid shape — vendor-neutral core + per-client adapters (+ optional MCP in v2.0) |
| D2 | MCP server deferred to v2.0 |
| D3 | All four gap clusters addressed: client-agnosticism, self-learning, generic-vs-project split, update-safety |
| D4 | Copy-paste distribution MUST be supported (+ tarball + curl-install + npx as fast-followers) |
| D5 | **7 cardinal roles** (5 engineering + project-manager + ai-engineer; revised 6 → 7 on 2026-05-16) — extensible via `local/roles/` + `extras/roles/` library |
| D6 | Discovery refresh: both manual `rediscover` + auto-flag staleness |
| D7 | Coexistence with existing instruction files: adopt (additive, pointer-line only) |
| D8 | Install directory: `.agents/engineering-team/` (amended 2026-05-17 from `engineering-team/` — dot-prefix convention + `.agents/` namespace for agent tooling; survives root clutter) |
| D9 | Role names: hybrid — current names canonical + generic aliases (`client-engineer`, `service-engineer`, `platform-engineer`, `quality-engineer`) |
| D10 | Custom-role extension: both pre-built library + free-form authoring under `local/roles/` |
| D11 | Public name: `engineering-team` |
| D12 | Automatic mode (added 2026-05-17) — per-task opt-in (`auto:` prefix or PM-proposed-then-user-accepted); elides Phase 3 + iteration intermediate gates; falls back to interactive on defined triggers (material UX, repeated defect, cross-domain cycle, wrong oracle, budget/time overrun, destructive actions); replaces Phase 8 with a delivery handoff (Accept/Feedback/Reject); never commits or pushes silently |
| D13 | Project-doc index in `local/index/` (added 2026-05-17) — heavy adopter docs (architecture, mockup, ADRs, CRs, scenarios, custom doc classes) extracted to lightweight summaries with SHA-256 staleness tracking in `local/index/manifest.yaml`; roles read index first, originals on demand; `ai-engineer` owns extraction + re-extraction (built-in recipes for common classes + novel-class recipe for adopter-specific doc types); `project-manager` checks SHA-256 drift pre-dispatch and dispatches `ai-engineer` to re-index; full spec `core/index-protocol.md` |
| D14 | GitHub issues + discussions as task source (added 2026-05-17) — `project-manager` files issues (`@project-manager file bug` / `file feature` using structured templates under `core/templates/issues/`), picks them up (`pick up #<N>`), triages ready issues (`triage`), and promotes discussions to issues (`promote discussion #<N>`); native `open`/`closed` + configurable labels (`engineering-team:ready` / `:in-progress` / `:blocked`) replace `☐`/`☒` glyphs for issue-sourced tasks; PRs auto-close issues via `Closes #N` linkage; tool surface is agnostic (`gh` CLI baseline, GitHub MCP / HTTPS fallback); pickup is always explicit (never auto). **Two repos.** Primary (`github.repo`, inferred from origin) — adopter's own project. Framework upstream (`github.framework-repo`, set at install) — lets adopters file feedback against engineering-team itself via the metadata-only variants: `file framework-bug` / `file framework-feature` / `triage framework` / `promote discussion framework#<N>`. No `pick up framework#<N>` — addressing a framework issue requires the framework source, so the user clones the framework repo and runs plain `pick up #<N>` from there. Framework-targeted ops use framework-specific templates (`framework-bug-report.md`, `framework-feature-request.md`) capturing affected framework artefact + version + adapter + locked-decision impact. Working in the framework repo itself (origin == framework) naturally uses framework templates via target-based selection. Full spec `core/github-integration.md` |

## Stack — non-negotiable

| Layer | Choice |
|---|---|
| Authoring | Markdown only |
| Distribution baseline | Copy-paste of the framework source into `.agents/engineering-team/` in the adopter project |
| Distribution upgrades | Tarball (GitHub Releases) + one-line shell installer (`iwr...iex` / `curl...sh`) |
| Future fast-follower | `npx @org/engineering-team init / update` (Node.js) |
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

- All files under this `engineering-team/` framework repo only — do not modify any other project from this directory. (This refers to the framework's own source repo; in adopter projects the framework lives at `.agents/engineering-team/`.)
- `core/`, `adapters/`, `extras/` are upstream-owned — replaced on update for adopters; we author them here.
- `local/` is adopter-owned — survives updates.
- Lossless rule for restructuring: any pass that touches structure must prove every rule/invariant survives (per `core/roles/ai-engineer.md`).
- SAD-freeze + CR/ADR pattern applies once this project's own architecture doc is finalized (not yet — currently in design phase).
- Follow `core/process.md § Documentation style — structure over prose` and `## Framework authoring — context economy` below for all new docs.

## Framework authoring — context economy

The framework is load-bearing LLM context for every adopter on every task. Aggregate weight is the dominant adopter cost: today `core/` alone is ~160K, before `local/`, project docs, or task materials. Every byte we add multiplies across every dispatch in every project. Treat token weight as a first-class constraint, on par with correctness.

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
