# ginee

**An AI software engineering team that behaves like a real one. Drops into your project, self-onboards, and gets to work.**

[![Latest Release](https://img.shields.io/github/v/release/kostiantyn-matsebora/ginee?label=release&color=0969da)](https://github.com/kostiantyn-matsebora/ginee/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

[![Claude Code](https://img.shields.io/badge/Claude%20Code-tier--1-D97757?logo=anthropic&logoColor=white)](adapters/claude/README.md)
[![GitHub Copilot CLI](https://img.shields.io/badge/Copilot%20CLI-tier--1-000?logo=githubcopilot&logoColor=white)](adapters/copilot-cli/README.md)
[![AGENTS.md](https://img.shields.io/badge/AGENTS.md-tier--2-0969da)](adapters/agents-md/README.md)
[![Generic](https://img.shields.io/badge/Generic-tier--3-lightgrey)](adapters/generic/README.md)

You're running AI coding agents across projects. Each tool has its own quirks, prompts,
agent files, slash commands. The team works differently in every repo. Phases get
skipped. Roles overlap. Long tasks crash with nothing to resume from. You re-explain
the same governance every single time.

**ginee makes the team portable, the process deterministic, and your project the source of truth.**

> Drop the framework into a repo, prompt `@team-lead run initial discovery`,
> and you have a 7-role engineering team that works the same way on Claude Code,
> Copilot CLI, Cursor, Codex, Windsurf, and anything that reads `AGENTS.md`.

---

## Why ginee?

```
ginee
├── 📐 PROCESS IS THE FRAMEWORK
│   ├── the phased lifecycle, dispatch rules, and iteration protocol are the spine
│   ├── agents, the knowledge index, self-onboarding, the adapters — all optimisations
│   │   on top; each makes the process cheaper to run on a real project
│   └── strip the optimisations away and the process still holds; you can run it by hand
│
├── 👥 WORKS LIKE A REAL TEAM
│   ├── roles dispatch each other, hand off, and review each other's work
│   ├── strict-domain rule — no role works outside its lane; mockup edits go to frontend,
│   │   architecture to SA, infra to devops, even when "while I'm in the area" is tempting
│   ├── cross-domain bugs use a propose → implement → verify cycle, not single-agent guessing
│   └── doc co-ownership pattern — solution-architect owns semantics, ai-engineer owns shape
│
├── 📥 THREE TASK SOURCES
│   ├── freeform requests ("Use ginee to add a /api/health endpoint")
│   ├── TODO files (root + nested per-component) — flips ☐ → ☒ only on user approval; never auto-adds
│   ├── GitHub issues — file / pick up / triage / promote; PRs auto-close via `Closes #N`
│   └── post-acceptance hook — if docs changed, ai-engineer proposes optimization automatically
│
├── 🎯 DETERMINISTIC
│   ├── same phased lifecycle, same dispatch rules, same gates
│   └── from one project to the next — no re-teaching the process
│
├── 🤖 CLIENT-AGNOSTIC
│   ├── Claude Code (tier-1) · Copilot CLI (tier-1) · AGENTS.md (tier-2) · generic (tier-3)
│   └── one set of role definitions; per-client renderings are pointer files only
│
├── 🔎 SELF-LEARNING
│   ├── zero stack/domain opinions baked in — team-lead learns your project on first run
│   ├── discovers tech stack, architecture, SDLC artefacts, TODO conventions
│   └── scans external catalogs (awesome-copilot) for additional specialist agents
│
├── 📚 REFERENCE-NOT-COPY
│   ├── project docs (architecture, mockups, diagrams) stay where they are
│   └── doc changes propagate instantly — framework never duplicates content
│
├── ⏱️ ITERATION PROTOCOL
│   ├── work > 15 min runs in 3–5 min stoppable batches with visible intermediate results
│   └── interrupt anytime; resume next day with zero rework
│
├── 🧱 EXTENSIBLE
│   ├── 5 pre-built specialists (security · ml · mobile · sre · data)
│   ├── plus author your own under local/roles/
│   └── plus auto-discover + translate agents from awesome-copilot catalog
│
├── 🔄 UPDATE-SAFE
│   ├── core/, adapters/, extras/ replaced on update
│   └── local/ (your bindings, custom roles) survives every upgrade
│
└── 📦 ZERO TOOLING
    ├── markdown only — copy-paste install always works
    └── shell installer + GitHub Releases for convenience
```

---

## Quick Start

### 1. Install

> **Project-level install.** The framework lives inside your project. Run the installer **from the root of the project / git repo you want to set up** — the current working directory becomes the install target. No GitHub auth required.

**One-liner** (recommended):

```bash
cd /path/to/your-project && curl -fsSL https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh | bash -s -- --adapter claude
```

```powershell
cd C:\path\to\your-project; $env:GINEE_ADAPTER='claude'; iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.ps1 | iex
```

Adapters: `claude` · `copilot-cli` · `agents-md` · `generic`.

**Download, inspect, then run** (when you want to read the installer first):

```bash
curl -fsSLO https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh
chmod +x install.sh
./install.sh --adapter claude
```

```powershell
iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.ps1 -OutFile install.ps1
.\install.ps1 -Adapter claude
```

Pin a release with `--ref v0.1.0` / `$env:GINEE_REF='v0.1.0'`.

### 2. Run discovery

Open your client in the project, then prompt:

```
/ginee-discovery                                # tier-1 slash command (Claude Code, Copilot CLI)
Run initial discovery                           # natural-language equivalent
act as team-lead and run initial discovery      # tier-2/3 fallback
```

Ginee scans the repo and writes `local/project-profile.md`, `local/bindings.md`, `local/framework.config.yaml`, then reports recommended specialists for your approval.

### 3. Give it work

Ginee is a team — once installed, you talk to *ginee*, not to a specific role. The team routes work internally per `local/bindings.md`. Two invocation paths:

- **Freeform** (works on any tier): `Use ginee to ...` — catch-all; the team self-dispatches.
- **Skill** (tier-1, Claude Code + Copilot CLI): `/ginee-<skill> [args]` — slash-command on the 10 framework skills. Natural-language phrasings like `Pick up #42` also match the skill description.

Three task sources:

**Freeform work** — describe what you want:

```
Use ginee to add a dark-mode toggle to the header
Use ginee to add a /api/health endpoint returning { status, version }
```

**TODO files** — flips `☐` → `☒` on Phase 8 approval; never auto-adds:

```
Use ginee to pick up the next TODO                                  # freeform
/ginee-pick-up                                                      # next unchecked TODO
/ginee-pick-up the dark-mode TODO in components/header/TODO.md
```

**GitHub issues** — file, pick up, or triage:

```
Use ginee to pick up issue #42                                      # freeform
/ginee-pick-up #42
/ginee-file-bug dashboard renders blank on Safari 17
/ginee-file-feature dark-mode toggle in header
/ginee-triage
/ginee-promote-discussion #17
```

PRs auto-close issues via `Closes #N`. Full 10-skill list + natural-language cheat sheet in [adapters/claude/install.md § How to invoke](adapters/claude/install.md). For tasks above ~15 minutes, the iteration protocol kicks in: 3–5 min stoppable batches with visible intermediate results. Interrupt anytime; resume next day with zero rework.

### 4. Update later

Re-run the installer with the update flag — `core/` + `adapters/` + `extras/` re-fetch from upstream; `local/` (your bindings, custom roles, discovered index) is preserved untouched.

```bash
./install.sh --update-only --adapter claude
```

```powershell
.\install.ps1 -UpdateOnly -Adapter claude
```

Piped (no local checkout):

```bash
GINEE_UPDATE_ONLY=1 GINEE_ADAPTER=claude bash -c "$(curl -fsSL https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh)"
```

```powershell
$env:GINEE_UPDATE_ONLY='1'; $env:GINEE_ADAPTER='claude'; iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.ps1 | iex
```

Check `core/MIGRATIONS/` after each update for breaking-change notes.

---

## How it works

> The framework ships **process**; your project ships **everything else**.

Every adopter project has:

```
your-project/
├── .agents/ginee/   ← framework (replaced on update; local/ survives)
│   ├── core/                   ← process spec + 7 cardinal role definitions + templates
│   ├── adapters/<client>/      ← per-client renderings (pointer files only)
│   ├── extras/roles/           ← pre-built specialists (opt-in)
│   └── local/                  ← YOUR bindings + custom roles (never replaced)
│       ├── project-profile.md
│       ├── bindings.md
│       ├── framework.config.yaml
│       └── roles/              ← your custom roles
│
├── .claude/agents/             ← (Claude adopters) thin pointers to .agents/ginee/core/roles/
├── AGENTS.md                   ← (AGENTS.md adopters) one pointer file
└── ... (your code, docs, mockups, tests — untouched)
```

The 7 cardinals:

| Role | Owns | Generic alias |
|---|---|---|
| `team-lead` | Dispatch routing, lifecycle gates, discovery, post-acceptance hook | orchestrator, project-manager |
| `solution-architect` | Architecture doc semantics, SAD freeze + CR/ADR governance | architect |
| `ai-engineer` | AI-asset + doc context economy, file-splitting, load topology | context-engineer |
| `frontend-engineer` | Client / UI engineering | client-engineer |
| `backend-engineer` | Server / API engineering | service-engineer |
| `devops-engineer` | Infra, CI/CD, containers, cloud, secrets | platform-engineer |
| `qa-engineer` | Functional / e2e / visual / scenario testing + thin runners | quality-engineer |

Plus 5 opt-in specialists in `extras/roles/` (security · ml · mobile · sre · data) and unlimited custom roles in `local/roles/`.

---

## Where to next

- **[PLAN.md](PLAN.md)** — design document + 11 locked decisions + verification plan.
- **[CLAUDE.md](CLAUDE.md)** — orientation for working ON the framework itself (the project dogfoods its own process).
- **[core/process.md](core/process.md)** — vendor-neutral team process spec (lifecycle, dispatch, iteration, coordination).
- **[core/roles/](core/roles/)** — 7 cardinal role definitions.
- **[adapters/](adapters/)** — per-client installation guides:
  - [Claude Code](adapters/claude/install.md) — tier-1, native subagents
  - [Copilot CLI](adapters/copilot-cli/install.md) — tier-1, native subagents + `/fleet` parallel
  - [AGENTS.md cross-tool](adapters/agents-md/install.md) — tier-2, persona model
  - [Generic fallback](adapters/generic/install.md) — tier-3, manual instructions
- **[extras/roles/](extras/roles/)** — pre-built specialist library.
- **[core/templates/role-authoring-template.md](core/templates/role-authoring-template.md)** — author your own custom role.

---

## License

[MIT](LICENSE) © 2026 Kostiantyn Matsebora.
