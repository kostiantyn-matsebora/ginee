---
title: Architecture
description: "How ginee composes into a project — layered components, integration flow, runtime dispatch, update mechanism, extension points."
permalink: /ARCHITECTURE.html
---

# Architecture

ginee is **markdown-only**. No runtime, no daemon, no library to import. It's a set of structured documents that the host LLM client (Claude Code, Copilot CLI, Cursor, ...) reads as system-prompt context and acts on through its own tool surface.

This page shows how the parts compose — what's on disk, who owns what, and how a user prompt becomes a finished PR.

## Layered components — what's on disk

```
your-project/
├── .agents/ginee/              ← framework (4 layers, see below)
│   ├── core/                       ← LAYER 1: process spec (upstream)
│   ├── adapters/<your-client>/     ← LAYER 2: per-client rendering (upstream)
│   ├── extras/                     ← LAYER 3: opt-in specialists (upstream)
│   └── local/                      ← LAYER 4: adopter project state (YOU)
│
├── .claude/                    ← (claude adapter) host-client bridge
│   ├── agents/                     pointer files → core/roles/
│   └── skills/ginee-*/             10 AgentSkills (cross-tool path)
│
├── .github/                    ← (copilot-cli adapter) host-client bridge
│   └── agents/                     pointer files → core/roles/
│
├── AGENTS.md                   ← (agents-md adapter) cross-tool entry point
├── CLAUDE.md                   ← project's own — gains a pointer block
│
└── src/ · docs/ · tests/ ...   ← your code, docs, mockups (untouched)
```

The four layers under `.agents/ginee/` have distinct ownership + update behaviour:

| Layer | Path | Owned by | Replaced on update? | What's in it |
|---|---|---|---|---|
| 1. Process spec | `core/` | upstream framework | **yes** | Lifecycle / dispatch rules / role kernels / templates / specs / skills / migrations |
| 2. Adapter | `adapters/<client>/` | upstream framework | **yes** | Per-client pointer files + install steps |
| 3. Specialists | `extras/roles/` | upstream framework | **yes** | Opt-in role library (security · ml · mobile · sre · data) |
| 4. Project state | `local/` | **adopter** | **no — survives updates** | Discovered project profile, bindings, framework.config, index, custom roles |

The update-safety boundary is **strict**: re-running the installer with `--update-only` wipes layers 1–3 and re-fetches them; layer 4 is preserved verbatim.

## Layer 1 — `core/` — process spec

The heart of ginee. Vendor-neutral. Same content for every adopter.

```
core/
├── process.md                  Phase 1–8 lifecycle, dispatch + parallelism rules,
│                               coordination protocol, task model, engineering principles
├── iteration-protocol.md       Estimation-first dispatch + 3–5 min stoppable batches
├── automatic-mode.md           D12 — per-task `auto:` opt-in; elides intermediate gates
├── index-protocol.md           local/index/ extraction, lossless rule, compression
│                               floor, consumer coupling, load triggers
├── index-syntax.md             .idx DSL grammar
├── delivery-modes.md           D17 — branch+PR / working-tree / commit-no-push
├── github-integration.md       D14 — issues + discussions as 4th task source
├── doc-co-ownership.md         SA ↔ ai-engineer ownership split
├── cross-domain-bugs.md        Propose → implement → verify cycle
├── cross-agent-handoff.md      Diagnose ≠ fix — structured hand-off procedure
├── post-task-check-in.md       After every completed user request
│
├── roles/                      7 cardinal role kernels (always present)
│   ├── team-lead.md             orchestrator + discovery
│   ├── solution-architect.md          architecture-doc semantics + governance
│   ├── ai-engineer.md                 doc context economy + load topology
│   ├── frontend-engineer.md           client UI + mockup
│   ├── backend-engineer.md            server APIs + persistence
│   ├── devops-engineer.md             IaC, CI/CD, containers, secrets
│   ├── qa-engineer.md                 scenarios, e2e, smoke, fixtures
│   └── *.details.md                   per-role deep-dives (load-on-demand)
│
├── templates/                  Standardized templates
│   ├── bindings.md                    `local/bindings.md` shape
│   ├── framework.config.yaml          `local/framework.config.yaml` shape
│   ├── role-authoring-template.md     for `local/roles/*.md` custom roles
│   ├── pr-description.md, hand-off-note.md, phase-report.md, ...
│   ├── issues/                        framework-internal PM workflow templates
│   └── index/                         per-class index file templates
│
├── skills/ginee-*/             10 AgentSkills (cross-client per agentskills.io)
│   ├── ginee-discovery/SKILL.md       initial discovery flow
│   ├── ginee-rediscover/SKILL.md      refresh on staleness
│   ├── ginee-pick-up/SKILL.md         unified task pickup (issue / TODO / freeform)
│   ├── ginee-triage/SKILL.md          list ready work across sources
│   ├── ginee-file-{bug,feature,...}   structured issue filing
│   ├── ginee-promote-discussion/      discussion → issue
│   └── ginee-reindex/                 targeted index re-extraction
│
├── MIGRATIONS/                 Version-to-version migration notes
│
└── VERSION                     SemVer (currently 0.1.0)
```

Every file in `core/` is markdown the LLM client loads as context. There's no compilation, no preprocessing — what you see is what the model reads.

## Layer 2 — `adapters/<client>/` — per-client rendering

Adapters are **pointer layers** between ginee's generic specs and a specific LLM client. They never duplicate `core/` content; they translate it for the host.

| Adapter | Tier | What it installs into the project |
|---|---|---|
| `claude` | tier-1 | `.claude/agents/*.md` (7 cardinal pointers) + `.claude/skills/ginee-*/` (10 skills) + CLAUDE.md pointer block |
| `copilot-cli` | tier-1 | `.github/agents/*.agent.md` (7 cardinal pointers) + `.agents/skills/ginee-*/` (cross-tool path) |
| `agents-md` | tier-2 | `AGENTS.md` at project root (single instruction file) — read by Cursor, OpenAI Codex, Windsurf, Amp, Devin, Factory, Jules, Copilot IDE |
| `generic` | tier-3 | `adapters/generic/INSTRUCTIONS.md` referenced manually — works with any LLM that reads a system-prompt file |

Each adapter contains:

```
adapters/<client>/
├── README.md           Capability tier + features supported
├── install.md          Step-by-step install + "How to invoke" cheat sheet
└── <client-specific>   Pointer files, theme-toggle scripts, etc.
```

Adapters update like `core/` (replaced on `--update-only`). Adding a new adapter is a contribution path — see [Contributing]({{ '/CONTRIBUTING.html' | relative_url }}).

## Layer 3 — `extras/roles/` — opt-in specialists

Specialist roles outside the 7-cardinal baseline. Enabled per project based on what discovery surfaces.

| Specialist | Activates when |
|---|---|
| `security-engineer` | Project has auth / secret / network-policy NFRs |
| `ml-engineer` | Project ships an ML model or serving tier |
| `mobile-engineer` | Project includes a native mobile client |
| `sre` | Project has SLOs, runbooks, or post-deploy ops requirements |
| `data-engineer` | Project has a data warehouse, lake, or pipeline orchestrator |

Same role-kernel shape as cardinals (see [Reference → Role kernels]({{ '/reference/ROLES.html' | relative_url }})). Adopters approve specialists during discovery — `team-lead` proposes, user accepts.

## Layer 4 — `local/` — adopter project state

The only mutable layer for adopters. Owned per project. Survives every framework update.

```
local/
├── project-profile.md          Discovered tech stack, domain, SDLC artefacts
├── bindings.md                 Role → owned paths, source-of-truth ownership,
│                               tie-breakers, forbidden role-crossings,
│                               project-specific index citations
├── framework.config.yaml       Concept → file-path mappings (architecture doc,
│                               mockup, ADR dir, CR dir, TODO file, github.repo,
│                               delivery.default-mode, index.classes)
│
├── index/                      Extracted knowledge index (see § Index component below)
│   ├── manifest.yaml           SHA-256 + recipes + compression + consumed-by per class
│   ├── architecture.idx, architecture-fr.idx, api-matrix.yaml, ui-states.yaml,
│   │   constraints.yaml, adr-index.idx, cr-index.idx, scenario-index.idx,
│   │   glossary.idx, mockup-index.idx          (doc category)
│   └── stack.yaml, topology.yaml, commands.yaml, conventions.yaml,
│       runtime-facts.yaml, repo-map.idx        (code category)
│
└── roles/                      Adopter-authored custom roles
    └── <your-role>.md          Same shape as core/roles/*.md (see role-authoring-template)
```

**Discovery writes most of this on first run.** Adopters edit `bindings.md` and `framework.config.yaml` to refine PM's auto-discovered defaults; everything else is regenerated on `@team-lead rediscover` or `@ai-engineer reindex`.

## The installer

`install.ps1` (PowerShell) and `install.sh` (POSIX) are the only operational scripts in the framework. Both do the same thing:

1. **Step 0 — Migrate legacy path.** If pre-rebrand `.agents/engineering-team/` exists and `.agents/ginee/` doesn't, rename once. Preserves `local/` contents.
2. **Step 1 — Fetch framework.** Fresh install → `git clone`. `--update-only` → preserve `local/`, wipe `core/` + `adapters/` + `extras/`, clone fresh into a temp dir, copy the three upstream layers into place, restore `local/`.
3. **Step 2 — Prune framework-dev cruft.** Drop `.github/` (release CI for the framework repo, not adopter), `PLAN.md`, `CLAUDE.md` (framework's own — would shadow the adopter's), `README.md`, other adapters, install scripts themselves.
4. **Step 3 — Install the chosen adapter.** Copy pointer files into client-specific paths (`.claude/agents/`, `.github/agents/`, `AGENTS.md`, etc.). Copy `ginee-*` skills into the client's skills path. Wipe and re-copy on `--update-only` to handle renamed skills cleanly.
5. **Step 4 — Append CLAUDE.md pointer block.** Idempotent via a sentinel header (`## Engineering team framework`). If the sentinel is already present, skip; if no `CLAUDE.md` exists, create one from the pointer template.

Adopters re-run the installer with `--update-only` whenever they want fresh framework state. `local/` is never touched.

## The index — load-on-demand knowledge layer

The most distinctive runtime component. Solves a token-economy problem: pulling raw `docs/architecture.md` (30–50 KB), the mockup (30–100 KB), ADR + CR + scenario corpora (often 100K+ each) into every dispatch wastes context before any work happens.

**The index extracts lightweight per-class summaries** under `local/index/`. Roles read summaries first; raw sources only when verbatim text matters.

### Components

```
manifest.yaml                       ← single source of truth for what's indexed
  ├── class                            (architecture / adr / cr / scenario / mockup /
  │                                    constraints / glossary / stack / topology /
  │                                    commands / conventions / runtime-facts / repo-map
  │                                    + adopter novel classes)
  ├── category                         doc | code
  ├── recipe                           builtin:<id> or inline novel recipe
  ├── source / source-glob             where the originals live
  ├── sha256 / sha256-by-file          drift detection
  ├── source-bytes / index-bytes       compression accounting
  ├── compression                      index-bytes / source-bytes (must be < 0.5)
  ├── consumed-by                      [<role>...] — at least one role must cite
  └── index-files                      list of files produced
```

### Three invariants

| Invariant | What it enforces |
|---|---|
| **Coverage rule** | Every named record (FR / NFR / endpoint / ADR / dep / service / port / command / env-var / dir) has an existence-entry in the index with a source-anchor citation. Fidelity stays in source. |
| **Compression floor** | `index-bytes / source-bytes ≥ 0.5` = failed extraction. Rewrite recipe to drop bulk, or mark class `read-source-directly` (no index file; roles read source via `repo-map.idx`). Per-class targets: ≤ 0.15 prose, ≤ 0.25 list-of-records, ≤ 0.15 structured-config inventory. |
| **Consumer coupling** | Every extracted class declares `consumed-by: [<role>...]`. Novel classes without a consumer are not extracted; dormant index files surface in the discovery report. |

### Load triggers (per-file)

Role kernel `## Source of truth` tables carry a `Load when` column with two tiers:

- **`always`** — foundational, loaded on every dispatch (single-digit KB combined).
- **scope-loaded** — trigger phrase like `wire / endpoint touch`, `dep bump`, `Phase 5/6 testing`, `deploy / infra work`. Loaded only when the task description matches.

Specialist reports its loaded set in its first response — adopters see per-dispatch baseline cost.

### Lifecycle

```
DISCOVERY (initial)
   team-lead enumerates classes
   → ai-engineer extracts per recipe
   → writes manifest.yaml + index files
   → sample-and-check: existence + compression
   → dormant-index audit
   → adopter reviews + approves

PRE-DISPATCH (every task)
   team-lead identifies sources the task may consume
   → computes current SHA-256, compares with manifest
   → on drift: flag + offer @ai-engineer reindex or @team-lead rediscover
   → never auto-reindexes

RE-EXTRACTION
   ai-engineer reads changed sources
   → re-extracts per recorded recipe
   → updates manifest + index files
   → re-runs sample-and-check
```

Full spec: [`core/index-protocol.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/index-protocol.md).

## Skills — workflow entry points

10 AgentSkills under `core/skills/ginee-*/SKILL.md` follow the [agentskills.io](https://agentskills.io) standard. Each is a directory with YAML frontmatter (`name`, `description`) + a markdown procedure body. The skill name's prefix `ginee-` avoids collisions with adopter-authored skills.

| Skill | Purpose |
|---|---|
| `ginee-discovery` | Initial project discovery — writes `local/*`, extracts initial index |
| `ginee-rediscover` | Refresh discovery after major doc / structure changes |
| `ginee-pick-up` | Unified pickup across task sources (`#N` / TODO line / freeform) |
| `ginee-triage` | List ready work across sources (issues + framework upstream + TODOs) |
| `ginee-file-bug` / `ginee-file-feature` | Structured filing in the primary repo |
| `ginee-file-framework-bug` / `ginee-file-framework-feature` | Filing against the ginee upstream repo (metadata-only; needs `github.framework-repo`) |
| `ginee-promote-discussion` | Promote a GitHub discussion to a draft issue |
| `ginee-reindex` | Targeted re-extraction for a changed source |

The adapter install step bridges `core/skills/ginee-*` into the host client's expected path. AgentSkills-compatible clients auto-activate skills on natural-language match.

## Integration process — from clone to first dispatch

Three phases, each visible + reversible.

### Phase 1 — Install

```
1. Run install.sh / install.ps1 from your project root
   │
   ├─ Detects legacy .agents/engineering-team/ → renames to .agents/ginee/
   │
   ├─ git clone the framework into .agents/ginee/
   │  (or refreshes core/+adapters/+extras/ if --update-only)
   │
   ├─ Prunes framework-dev cruft (.github/, PLAN.md, CLAUDE.md, other adapters)
   │
   ├─ Installs chosen adapter
   │  • claude    → .claude/agents/*.md + .claude/skills/ginee-*/
   │  • copilot   → .github/agents/*.agent.md + .agents/skills/ginee-*/
   │  • agents-md → AGENTS.md at project root
   │  • generic   → manual pointer to .agents/ginee/adapters/generic/INSTRUCTIONS.md
   │
   └─ Appends pointer block to CLAUDE.md (idempotent via sentinel)
```

Result: `local/` is empty (just `.gitkeep`), everything else is in place.

### Phase 2 — Discovery

```
User: "Run initial discovery"
   │
   ▼
team-lead (orchestrator)
   │
   ├─ Step 1: detect stack
   │   • language / runtime / framework / ORM / data-store / container-runtime
   │   • from package manifests + lockfiles + Dockerfiles
   │
   ├─ Step 2: detect SDLC artefacts
   │   • architecture-doc location, mockup, ADR / CR directories
   │   • scenario files, TODO conventions
   │   • CI workflow, IaC layout
   │
   ├─ Step 3: write local/project-profile.md
   │
   ├─ Step 4: write local/bindings.md
   │   • role → owned paths
   │   • source-of-truth ownership
   │   • tie-breakers
   │   • forbidden role-crossings
   │
   ├─ Step 5: write local/framework.config.yaml
   │   • concept → path mappings
   │   • github.repo (inferred from origin)
   │   • delivery.default-mode (framework default)
   │
   ├─ Step 6: scan extras/roles/ + external catalogs
   │   • propose specialist roles based on stack
   │   • user approves
   │
   └─ Step 7: dispatch ai-engineer → extract index
       │
       ├─ enumerate classes (doc + code + novel)
       ├─ resolve consumer per class
       ├─ extract per recipe → writes local/index/*
       ├─ sample-and-check (existence + compression)
       └─ dormant-index audit → discovery report
```

Result: `local/` is populated. The framework knows the project.

### Phase 3 — Dispatch loop

```
USER prompt: "@frontend-engineer add a dark-mode toggle to the header"
   │
   ▼
HOST CLIENT (Claude Code / Copilot CLI / Cursor / ...)
   │  reads pointer file from adapter layer
   │  (e.g. .claude/agents/frontend-engineer.md)
   ▼
ADAPTER LAYER
   │  pointer cites core/roles/frontend-engineer.md
   ▼
ROLE KERNEL (core/roles/frontend-engineer.md)
   │  loads always-tier index files per Source-of-truth table
   │  • local/index/architecture-fr.idx
   │  • local/index/constraints.yaml
   │  • local/index/ui-states.yaml
   │  • local/index/conventions.yaml
   │  evaluates scope triggers → loads matching scope-tier files
   │  • mockup touch → local/index/mockup-index.idx
   ▼
SPECIALIST execution
   │  Phase 1: analyze scope → identify touched files / domains
   │  Phase 2: design → mockup change + state-machine update
   │  Phase 3: design review → user approval
   │  Phase 4: implementation → edits via host tools
   │  Phase 5: testing → @qa-engineer dispatched in parallel
   │  Phase 6: bug fixing if needed
   │  Phase 7: SA review → architecture invariants honoured
   │  Phase 8: user approval → delivery per mode
   ▼
WORK PRODUCT
   • Mode 1: feature branch + PR with Closes #N
   • Mode 2: working-tree diff surfaced; user commits manually
   • Mode 3: commits on current branch; user pushes manually
```

The user sees every transition. Long tasks run under the iteration protocol — 3–5 min stoppable batches with visible intermediate results.

## Update mechanism

Re-running the installer with `--update-only`:

```
local/      ← BACKED UP to temp dir
core/       ← WIPED
adapters/   ← WIPED
extras/     ← WIPED

git clone (fresh upstream into temp dir)

core/       ← COPIED from temp
adapters/   ← COPIED from temp
extras/     ← COPIED from temp

local/      ← RESTORED from temp backup
```

`local/` byte-for-byte unchanged. Migration notes under `core/MIGRATIONS/<name>.md` flag any post-update action adopters need to take manually (rename a section, re-extract a class, update `bindings.md`, etc.).

The installer also re-runs the adapter-install steps — pointer files in `.claude/agents/`, `.github/agents/`, `AGENTS.md` etc. are refreshed. `CLAUDE.md` pointer block is preserved (idempotent via sentinel).

## Extension points

Three ways to add to ginee without forking:

| Extension | Location | When |
|---|---|---|
| **Custom roles** | `local/roles/<role>.md` | Project needs a specialist outside the 5 in `extras/` — e.g. a `data-scientist` for an ML-research project, or a `compliance-engineer` for a regulated domain. Use [`core/templates/role-authoring-template.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/templates/role-authoring-template.md). |
| **Novel index classes** | `local/framework.config.yaml § index.classes` + `local/bindings.md § Project-specific index citations` | Project has a doc class outside `architecture / adr / cr / scenario / mockup / glossary` — e.g. RFCs, runbooks, threat-models, model-cards. Declare `consumed-by` so the class doesn't sit dormant. |
| **Project-specific kernel citations** | `local/bindings.md § Per-role load-trigger overrides` | Default cardinal kernel `Load when` defaults don't match the project's actual workflow — e.g. backend tasks routinely touch infra on this project, promote `topology.yaml` from scope-loaded to `always` for `backend-engineer`. |

Upstream framework changes (new cardinal role, new spec, new locked decision) go through the [contributor flow]({{ '/CONTRIBUTING.html' | relative_url }}) against the ginee repo itself.

## Host LLM client integration

| Client | Capability tier | Native subagents | Native skills | Dispatch surface |
|---|---|---|---|---|
| **Claude Code** | tier-1 | yes — `.claude/agents/*.md` | yes — `.claude/skills/<name>/SKILL.md` | Natural-language routing; subagent description match |
| **GitHub Copilot CLI** | tier-1 | yes — `.github/agents/*.agent.md` | yes — `.agents/skills/<name>/SKILL.md` (cross-tool path) | Natural-language + `/fleet` for parallel dispatch |
| **Cursor** | tier-2 | personas in `AGENTS.md` | (via AgentSkills, where supported) | `@<role>` literal mention |
| **OpenAI Codex / Windsurf / Amp / Devin / Factory / Jules / Copilot IDE** | tier-2 | personas in `AGENTS.md` | (varies per client) | Natural-language or `@<role>` per client |
| **Generic LLM** | tier-3 | impersonation via `INSTRUCTIONS.md` | n/a | "act as team-lead and ..." pattern |

Same process, same role kernels, same lifecycle — execution path degrades gracefully on lower tiers.

## What ginee deliberately doesn't ship

- **No runtime / daemon / SaaS.** Everything is markdown read by the host LLM client.
- **No code-generation engine.** Specialists invoke the host's built-in tools (Read, Edit, Bash) — ginee never executes anything itself.
- **No telemetry.** Discovery + dispatch are entirely local to the adopter's machine + LLM session.
- **No vendor lock-in.** Same spec works on Claude Code, Copilot, Cursor, Codex, generic. Adopters pick the client.
- **No per-domain templates** (e.g. no architecture-doc template, no API-contract template). Adopters bring their own; ginee ships process only.
- **No MCP server.** Deferred to v2.0.

## Where to next

- [**Concepts**]({{ '/CONCEPTS.html' | relative_url }}) — the mental model behind these components.
- [**Reference**]({{ '/reference/' | relative_url }}) — canonical specs for each component.
- [**Cheatsheet**]({{ '/CHEATSHEET.html' | relative_url }}) — daily-use commands.
- [**Source repo**](https://github.com/kostiantyn-matsebora/ginee) — `core/`, `adapters/`, `extras/`, install scripts.
