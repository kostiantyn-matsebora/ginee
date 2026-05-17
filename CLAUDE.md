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
| D8 | Install directory: `engineering-team/` |
| D9 | Role names: hybrid — current names canonical + generic aliases (`client-engineer`, `service-engineer`, `platform-engineer`, `quality-engineer`) |
| D10 | Custom-role extension: both pre-built library + free-form authoring under `local/roles/` |
| D11 | Public name: `engineering-team` |

## Stack — non-negotiable

| Layer | Choice |
|---|---|
| Authoring | Markdown only |
| Distribution baseline | Copy-paste of the `engineering-team/` directory |
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

- All files under `engineering-team/` only — do not modify any other project from this directory.
- `core/`, `adapters/`, `extras/` are upstream-owned — replaced on update for adopters; we author them here.
- `local/` is adopter-owned — survives updates.
- Lossless rule for restructuring: any pass that touches structure must prove every rule/invariant survives (per `core/roles/ai-engineer.md`).
- SAD-freeze + CR/ADR pattern applies once this project's own architecture doc is finalized (not yet — currently in design phase).
- Follow `core/process.md § Documentation style — structure over prose` for all new docs.

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
