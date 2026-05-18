---
title: Getting Started
description: "Install ginee into your project, run discovery, dispatch your first task."
permalink: /GETTING_STARTED.html
---

# Getting Started

5 minutes from clone to first dispatch.

## Prerequisites

- A project / git repo to install into.
- One of: **Claude Code** · **GitHub Copilot CLI** · a client that reads **AGENTS.md** (Cursor, Codex, Windsurf, Gemini CLI, Goose, ...) · or any LLM with a `INSTRUCTIONS.md` reader (generic fallback).
- `git` available on `PATH` (the installer uses `git clone` to fetch the framework).

That's it. ginee is markdown-only — no Node, Python, or build step.

## 1. Install

> Run the installer **from the root of the project you want to set up**. The current working directory becomes the install target unless `--target` / `-Target` is passed.

### Linux / macOS / WSL

```bash
cd /path/to/your-project
curl -fsSL https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh | bash -s -- --adapter claude
```

### Windows PowerShell

```powershell
cd C:\path\to\your-project
$env:GINEE_ADAPTER='claude'; iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.ps1 | iex
```

### Adapter options

| Adapter | Client tier | Use when |
|---|---|---|
| `claude` | tier-1 | Claude Code (native subagents + skills) |
| `copilot-cli` | tier-1 | GitHub Copilot CLI (native subagents + `/fleet` parallel) |
| `agents-md` | tier-2 | Cursor, OpenAI Codex, Windsurf, Amp, Devin, Factory, Jules, GitHub Copilot IDE (read `AGENTS.md`) |
| `generic` | tier-3 | Any LLM that can read an `INSTRUCTIONS.md` |

### Pin a version

```bash
./install.sh --ref v0.1.0 --adapter claude
```

```powershell
$env:GINEE_REF='v0.1.0'; $env:GINEE_ADAPTER='claude'; iwr ... | iex
```

### What gets created

| Path | Owner | Replaced on update? |
|---|---|---|
| `.agents/ginee/core/` | upstream | yes |
| `.agents/ginee/adapters/<your-adapter>/` | upstream | yes |
| `.agents/ginee/extras/` | upstream | yes |
| `.agents/ginee/local/` | **you** | **no — survives updates** |
| `.claude/agents/` (claude adapter) | upstream | yes (pointer files) |
| `.claude/skills/ginee-*/` (claude adapter) | upstream | yes |
| `CLAUDE.md` (claude adapter) | hybrid | pointer block appended once |

`.agents/ginee/local/` is the only adopter-owned directory. Everything else is framework state.

## 2. Run discovery

Open your client in the project. Type:

```
Run initial discovery
```

What happens (a few minutes, fully visible):

1. `project-manager` scans the repo — detects stack, architecture-doc location, mockup, ADR / CR directories, scenario files, TODO conventions.
2. Writes three project-state files under `.agents/ginee/local/`:
   - `project-profile.md` — discovered tech / domain / SDLC artefacts.
   - `bindings.md` — role → owned paths, source-of-truth ownership, tie-breakers.
   - `framework.config.yaml` — concept → file-path mappings (architecture doc, mockup, ADR dir, CR dir, TODO file).
3. Extracts a knowledge index under `.agents/ginee/local/index/` — lightweight per-class summaries of architecture / ADRs / CRs / scenarios / mockup / stack / topology / commands / runtime-facts. Roles read the index first; originals only when an entry needs verbatim text.
4. Surfaces recommended specialist roles for your approval (security · ml · mobile · sre · data, depending on what discovery found in the project).

You'll see proposed changes before any file is written — approve or redirect each step.

## 3. First dispatch

Pick something concrete. Examples:

```
@frontend-engineer rename the dashboard header to "Operations Console"
@backend-engineer add a /api/health endpoint returning {status:"ok", version:VERSION}
@qa-engineer write a smoke scenario for the new health endpoint
```

The orchestrator (`project-manager`) routes the work. For tasks &gt; 15 minutes of estimated work, the [iteration protocol](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/iteration-protocol.md) kicks in: each specialist returns a task decomposition + per-task estimate **before** editing, you approve, then 3–5 min stoppable batches.

## 4. Update later

```bash
./install.sh --update-only --adapter claude
```

```powershell
.\install.ps1 -UpdateOnly -Adapter claude
```

`core/`, `adapters/`, `extras/` re-fetch from the framework upstream. `local/` (your bindings + custom roles + discovered index) is preserved untouched.

## What now

- **[Concepts]({{ '/CONCEPTS.html' | relative_url }})** — the 7-cardinal model, lifecycle phases, dispatch rules, iteration protocol. Worth reading once.
- **[Cheatsheet]({{ '/CHEATSHEET.html' | relative_url }})** — one-page reference for daily use.
- **[Reference]({{ '/reference/' | relative_url }})** — canonical specs: process, roles, index protocol.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `git clone` step fails | Network issue or `git` not on PATH | Check connectivity to github.com + `git --version`. ginee is public — no GitHub auth required for the default `--repo` |
| `.agents/engineering-team/` exists after update | Pre-rebrand install path | The installer auto-renames on next `--update-only` run — re-run and it migrates once |
| Specialist refuses to edit a file | Forbidden role-crossing per `local/bindings.md § Project role boundaries` | Dispatch the owning role instead — the strict-domain rule is intentional |
| Discovery surfaces "no architecture doc" | Project has no `docs/architecture.md` (or similar) yet | OK; PM works without one. Author one when ready and `@project-manager rediscover` |
| Index says "dormant" for a class | Class extracted but no role kernel cites it | Wire it via `local/bindings.md § Project-specific index citations`, or remove the class from extraction |

More in [CONTRIBUTING]({{ '/CONTRIBUTING.html' | relative_url }}) and the [issue templates](https://github.com/kostiantyn-matsebora/ginee/issues/new/choose).
