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

> Drop the framework into a repo, prompt `@project-manager run initial discovery`,
> and you have a 7-role engineering team that works the same way on Claude Code,
> Copilot CLI, Cursor, Codex, Windsurf, and anything that reads `AGENTS.md`.

---

## Why ginee?

```
ginee
├── 👥 WORKS LIKE A REAL TEAM
│   ├── roles dispatch each other, hand off, and review each other's work
│   ├── strict-domain rule — no role works outside its lane; mockup edits go to frontend,
│   │   architecture to SA, infra to devops, even when "while I'm in the area" is tempting
│   ├── cross-domain bugs use a propose → implement → verify cycle, not single-agent guessing
│   └── doc co-ownership pattern — solution-architect owns semantics, ai-engineer owns shape
│
├── ☐ TODO-DRIVEN WORKFLOW
│   ├── reads root TODO, nested per-component TODOs, or just your direct instruction
│   ├── flips ☐ → ☒ only on user approval; never auto-adds; honours "skip TODO" cues
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
│   ├── zero stack/domain opinions baked in — project-manager learns your project on first run
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

### 1. Get the framework into your project

> **Project-level install.** The framework lives inside your project (it creates `./.agents/ginee/` and writes adapter files into `./.claude/`, `./.github/agents/`, or `./AGENTS.md`). Always run the installer **from the root of the project / git repo you want to set up** — the current working directory becomes the install target.

**Option A — download the installer into your project root, then run it** (recommended while the framework repo is private):

```bash
cd /path/to/your-project
curl -fsSLO https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh
chmod +x install.sh
./install.sh --adapter claude          # or copilot-cli | agents-md | generic
```

```powershell
cd C:\path\to\your-project
iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.ps1 -OutFile install.ps1
.\install.ps1 -Adapter claude          # or copilot-cli | agents-md | generic
```

> The `raw.githubusercontent.com` URL returns 404 while this repo is private — authenticate first (`gh auth login` and configure git credentials) so the script's `git clone` step can fetch the framework. Once the repo is public, both downloads work anonymously.

**Option B — one-liner pipe** (works once the framework repo is public):

```bash
cd /path/to/your-project && curl -fsSL https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh | bash -s -- --adapter claude
```

```powershell
cd C:\path\to\your-project; $env:GINEE_ADAPTER='claude'; iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.ps1 | iex
```

Pin a release with `--ref v0.1.0` / `$env:GINEE_REF='v0.1.0'`.

> Copy-paste is the canonical baseline. The installer is a convenience: drop the `.agents/ginee/` directory into your project root and run the install steps in [`adapters/<your-client>/install.md`](adapters/) manually.

### 2. Run discovery

Open your client in the project, then prompt:

```
@project-manager run initial discovery
```

(or `act as project-manager and run initial discovery` for tier-2/3 clients without `@mention` routing)

`project-manager` writes `local/project-profile.md`, `local/bindings.md`, `local/framework.config.yaml`, scans external catalogs for additional candidates, and reports recommended specialists for your approval.

### 3. Work

Dispatch tasks by mentioning the role that owns the surface:

```
@frontend-engineer add a dark-mode toggle to the header
@solution-architect this needs a new FR — write the CR
@qa-engineer cover the new toggle with scenarios + a visual smoke
```

The orchestrator (`project-manager`) routes ambiguous scope. For long tasks the iteration protocol kicks in: 3–5 min batches with visible intermediate results and a stop-anywhere contract.

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
| `project-manager` | Dispatch routing, lifecycle gates, discovery, post-acceptance hook | orchestrator |
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
