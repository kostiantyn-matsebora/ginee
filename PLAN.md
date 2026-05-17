# `engineering-team` — Reusable OSS Multi-Agent Engineering Framework

> **Status.** Design document. Captures the framework's architecture, locked decisions, phased delivery roadmap, and verification plan. Lives in the repo so it's portable across machines / collaborators / clones.

## Context

The current deployment-dashboard project runs a 5-agent collaboration model (solution-architect, frontend-engineer, backend-engineer, devops-engineer, qa-engineer) coordinated by `CLAUDE.md`. The model has been observed to work well — phased lifecycle, strict-domain rule, parallel dispatch, cross-domain bug cycle. This plan extracts that working pattern into an **OSS framework** — `engineering-team` — that any project can adopt with minimal friction, regardless of LLM client (Claude Code, Copilot, Cursor, Codex, Kuro, ...).

The framework ships **process knowledge only** — no domain, stack, architecture, or SDLC opinions. Project-specific knowledge is discovered automatically on first run and lives in a project-local layer that survives upstream updates. Project knowledge sources (markdown docs, diagrams, mockups) are **referenced**, never copied — doc changes propagate instantly.

---

## Final architecture

### Three-layer directory model

```
.agents/engineering-team/             ← drops into any project
├── core/                             ← immutable, replaced on update
│   ├── process.md                    ← phased lifecycle, strict-domain rule,
│   │                                   cross-domain cycle, parallel dispatch rules
│   ├── roles/                        ← 7 cardinal role definitions (vendor-neutral md)
│   │   ├── project-manager.md
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

`.agents/engineering-team/local/framework.config.yaml` maps **concepts → project paths**:

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

1. Get the `.agents/engineering-team/` directory into your project (one of the channels below).
2. Open the project's client-specific instruction file (`CLAUDE.md`, `.github/copilot-instructions.md`, `.cursor/rules/`, ...).
3. Paste the **single pointer line** the README provides for that client.
4. Open your LLM, prompt: `@project-manager run initial discovery.`
5. `project-manager` writes `local/project-profile.md`, `local/bindings.md`, `local/framework.config.yaml`. Done.

### Distribution channels (D4 — ladder)

| Tier | Channel | Tooling |
|---|---|---|
| 0 | Copy-paste from cloned upstream repo | git |
| 1 | Download tarball from GitHub Releases | browser |
| 2 | One-line shell installer (`iwr ...\|iex` / `curl ...\|sh`) | shell |
| 3 *(fast-follower)* | `npx @org/engineering-team init / update` | Node |
| 4 *(fast-follower)* | GitHub template repo + sync GH Action | GitHub + CI |
| 5 *(v2.0)* | MCP server | MCP-capable client |

MVP delivers tiers 0–2 (same artefact at different convenience levels) + README with verbatim pointer lines per client.

### Self-learning (discovery)

`project-manager` runs an initial `discover` pass:

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

- **Manual:** user invokes `@project-manager rediscover`.
- **Auto-flag:** `project-manager` reads `project-profile.md` before every task; if it encounters files/patterns not in the profile, flags staleness in its first response and offers `rediscover`.

### Coexistence (D7 — adopt)

Init never overwrites the existing instruction file. It only appends (or asks the user to append) a single pointer line. Existing project rules continue to apply.

### Update

User re-fetches the upstream `.agents/engineering-team/` and replaces `core/`, `adapters/`, `extras/`. `local/` is untouched.
`core/VERSION` is SemVer; breaking releases ship a migration note in `core/MIGRATIONS/<from>-to-<to>.md`.

### Role extension (D5, D10 — both)

- **Pre-built specialists:** `extras/roles/` ships with security-engineer, ml-engineer, mobile-engineer, sre, data-engineer. User copies any into `local/roles/` to enable.
- **Free-form authoring:** user creates `local/roles/<custom-role>.md` following a documented template. `project-manager` discovers it on next prompt and adds it to the routing table.
- `project-manager` always remains orchestrator — custom roles register **under** PM, not alongside.

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
| P2 | `core/roles/*.md` (7 cardinals) | genericised from `.claude/agents/*.md` + new `project-manager.md` + new `ai-engineer.md` |
| P3 | `core/templates/*.md` | extract templates implicit in current process |
| P4 | `adapters/claude/` | new — smoke-tested by re-importing into deployment-dashboard |
| P5 | `project-manager`'s discovery flow | new — tested against deployment-dashboard |
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
| D5 | Role topology | **7 cardinal roles (5 engineering + project-manager + ai-engineer); extensible; project-manager always orchestrator.** ai-engineer is the universal meta-engineering cardinal — every adopting project has AI assets and docs that need optimization; revised from 6 to 7 on 2026-05-16. |
| D6 | Discovery refresh model | **Both** — manual `rediscover` + auto-flag staleness. |
| D7 | Coexistence with existing instruction files | **Adopt (additive)** — single pointer line only. |
| D8 | Install directory name | **`.agents/engineering-team/`** (amended 2026-05-17 from `engineering-team/`) — dot-prefix matches the convention every other agent/IDE tool uses (`.claude/`, `.cursor/`, `.github/`, `.vscode/`); `.agents/` namespace leaves room for other agent frameworks to coexist without polluting the project root. |
| D9 | Role names | **Hybrid** — keep current names as canonical; generic aliases via front-matter (`client-engineer`, `service-engineer`, ...). |
| D10 | Custom-role extension | **Both** — pre-built `extras/` library + free-form authoring under `local/roles/`. |
| D11 | Public framework name | **`engineering-team`** |
| D12 | Automatic mode (added 2026-05-17) | **Per-task opt-in.** The user may run a task end-to-end without per-phase gates by prefixing it with `auto:` (or `project-manager` may propose auto mode for low-risk tasks; user must say yes). Elides Phase 3 design review (when no UX impact), iteration intermediate-batch confirmations, and engineer "stop and confirm" pauses. Falls back to interactive on forced-interactive triggers (material UX change, unresolved defect after 2 iterations, cross-domain cycle, wrong test oracle, budget/time overruns, destructive/external actions). Replaces Phase 8 with a **delivery handoff**: working-tree changes prepared but not committed, delivery report produced, user picks Accept (commit per convention; push only on explicit ask) / Feedback (loop to relevant phase) / Reject (revert working tree). The Phase 8 user-approval invariant is preserved as that single final gate. |
| D13 | Project-doc index in `local/index/` (added 2026-05-17) | **Extracted summaries + SHA-256 staleness.** Adopter projects accumulate substantial docs (architecture, mockup, ADRs, CRs, scenarios, plus adopter-specific classes like RFCs, runbooks, threat models, model cards, data dictionaries). Pulling full source into context on every dispatch burns tokens (140K+ scenario corpora observed). Discovery extracts lightweight per-doc-class summaries to `local/index/`; roles read the index first and originals only on demand. `local/index/manifest.yaml` tracks SHA-256 per source — `project-manager` checks drift pre-dispatch and dispatches `ai-engineer` to re-extract on mismatch. `ai-engineer` owns extraction with **built-in recipes** for common doc classes + a **novel-class recipe** for adopter-specific doc types (RFC, runbook, threat-model, model-card, etc.). Extension via `framework.config.yaml § index.classes` for adopter-declared classes. Full spec: `core/index-protocol.md`. |
| D14 | GitHub issues + discussions as task source (added 2026-05-17) | **Fourth task source alongside TODO files + direct instructions.** Adopters file work where they already do (issues, discussions); the framework picks it up via the standard Phase 1–8 lifecycle and closes the loop with issue comments + PR linkage. `project-manager` handles both directions: outbound (`@project-manager file bug` / `file feature` — uses structured templates under `core/templates/issues/` and creates labelled issues), inbound (`@project-manager pick up #<N>` and `triage` — never auto-picks), and `@project-manager promote discussion #<N>` for ideas → issues. Native `open`/`closed` + configurable labels (`engineering-team:ready` / `:in-progress` / `:blocked` defaults) replace the `☐`/`☒` glyph mechanic for issue-sourced tasks. PR descriptions auto-close issues via `Closes #N` linkage. Tool surface is vendor-agnostic — `gh` CLI baseline, GitHub MCP / generic HTTPS as alternates. Repo discovery: infer from `git remote get-url origin` with optional `github.repo` override in `local/framework.config.yaml`. Discussions are read-only context — must be promoted to an issue before pickup. Full spec: `core/github-integration.md`. |

---

## Appendix — gap analysis (working notes preserved)

| # | Gap | Resolution |
|---|---|---|
| G1 | Subagent capability varies per client and evolves rapidly. (Earlier draft assumed "agents are Claude Code only" — stale by early 2026.) | Vendor-neutral core + per-client adapters. Each adapter declares its **capability tier** based on current client state; tier assignments are revisited per release. On clients with native subagents, cardinals render as real subagents; on clients without, cardinals become personas the single LLM impersonates. Same process model, degraded execution path on tier-2/3. |
| G2 | "Maximally deterministic" against nondeterministic LLMs is overclaim. | Reframed as deterministic *process / templates / gates / artefact classes*. |
| G3 | "Self-learning" was undefined. | `project-manager` runs `discover`; output = `local/project-profile.md` + `local/bindings.md` + `local/framework.config.yaml`. |
| G4 | 5 fixed roles don't fit every project. | 7 cardinals stay (5 + PM + ai-engineer); `extras/` library + `local/roles/` extension covers specialisations. |
| G5 | "Reference, don't copy" needs an indirection layer. | `local/framework.config.yaml` maps concepts → project paths. |
| G6 | `CLAUDE.md` mixes generic process with project bindings. | Hard split: `core/process.md` (generic) ↔ `local/bindings.md` (per-project). |
| G7 | First-run onboarding undefined. | Defined: install → pointer line → `@project-manager run initial discovery`. |
| G8 | Update vs user customisation conflict. | Two-tier filesystem: `core/` replaced, `local/` survives. |
| G9 | Versioning + migrations. | SemVer in `core/VERSION`; migrations in `core/MIGRATIONS/`. |
| G10 | Conflict with existing project process docs. | Adopt mode default — pointer line only; no overwrite. |
| G11 | Discovery staleness over time. | Manual `rediscover` + PM auto-flag on profile mismatch. |
| G12 | Determinism across clients with very different capability. | Capability tiers (full subagents / single-agent personas / instructions-only) documented per client; same process model. |
