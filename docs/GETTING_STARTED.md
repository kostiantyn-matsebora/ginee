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
- `curl` (Linux/macOS) or `Invoke-WebRequest` (Windows; built in to PowerShell). `git` is **only** required if you install from a branch / commit (`--ref main` or `--ref <sha>`); tagged-release installs download a verified tarball over HTTPS.

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

### Ref resolution

`--ref` controls what gets installed:

| Value | Source | Notes |
|---|---|---|
| `latest` (default) | Release tarball | Resolves to the most recent published release via the `/releases/latest` redirect. No `git` needed. |
| `vX.Y.Z` (e.g. `v0.1.0`) | Release tarball | Pin to a specific release. Verified against `SHA256SUMS.txt`. No `git` needed. |
| `main` / branch / SHA | `git clone --depth 1` | Fall-back path. Requires `git` on PATH. |

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
/ginee-discovery                                # tier-1 slash command (Claude Code, Copilot CLI)
Run initial discovery                           # natural-language equivalent
act as team-lead and run initial discovery      # tier-2/3 fallback
```

What happens (a few minutes, fully visible):

1. `team-lead` scans the repo — detects stack, architecture-doc location, mockup, ADR / CR directories, scenario files, TODO conventions.
2. Writes three project-state files under `.agents/ginee/local/`:
   - `project-profile.md` — discovered tech / domain / SDLC artefacts.
   - `bindings.md` — role → owned paths, source-of-truth ownership, tie-breakers.
   - `framework.config.yaml` — concept → file-path mappings (architecture doc, mockup, ADR dir, CR dir, TODO file).
3. Extracts a knowledge index under `.agents/ginee/local/index/` — lightweight per-class summaries of architecture / ADRs / CRs / scenarios / mockup / stack / topology / commands / runtime-facts. Roles read the index first; originals only when an entry needs verbatim text.
4. Surfaces recommended specialist roles for your approval (security · ml · mobile · sre · data, depending on what discovery found in the project).

You'll see proposed changes before any file is written — approve or redirect each step.

## 3. Give it work

Ginee is a team — talk to *ginee*, not to a specific role. The team routes work internally per `local/bindings.md`. Two invocation paths:

- **Freeform** (any tier): `Use ginee to ...` — catch-all; the team self-dispatches.
- **Skill** (tier-1, Claude Code + Copilot CLI): `/ginee-<skill> [args]` — slash-command on the 10 framework skills. Natural-language phrasings like `Pick up #42` also match the skill description. Cheat sheet in [adapters/claude/install.md § How to invoke](https://github.com/kostiantyn-matsebora/ginee/blob/main/adapters/claude/install.md#how-to-invoke).

Three task sources:

**Freeform work** — describe what you want:

```
Use ginee to rename the dashboard header to "Operations Console"
Use ginee to add a /api/health endpoint returning { status, version }
```

**TODO files** — flips `☐` → `☒` on Phase 8 approval; never auto-adds:

```
Use ginee to pick up the next TODO                          # freeform
/ginee-pick-up                                              # next unchecked TODO
/ginee-pick-up the health-endpoint TODO in api/TODO.md
```

**GitHub issues** — file, pick up, or triage:

```
Use ginee to pick up issue #42                              # freeform
/ginee-pick-up #42
/ginee-file-bug dashboard renders blank on Safari 17
/ginee-file-feature dark-mode toggle in header
/ginee-triage
/ginee-promote-discussion #17
```

PRs auto-close issues via `Closes #N`. For tasks &gt; 15 minutes of estimated work, the [iteration protocol](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/iteration-protocol.md) kicks in: each specialist returns a task decomposition + per-task estimate **before** editing, you approve, then 3–5 min stoppable batches.

## 4. Update later

From a local checkout of the installer:

```bash
./install.sh --update-only --adapter claude
```

```powershell
.\install.ps1 -UpdateOnly -Adapter claude
```

Or piped (no local checkout needed):

```bash
GINEE_UPDATE_ONLY=1 GINEE_ADAPTER=claude bash -c "$(curl -fsSL https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh)"
```

```powershell
$env:GINEE_UPDATE_ONLY='1'; $env:GINEE_ADAPTER='claude'; iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.ps1 | iex
```

`core/`, `adapters/`, `extras/` re-fetch from the framework upstream. `local/` (your bindings + custom roles + discovered index) is preserved untouched. Read `.agents/ginee/core/MIGRATIONS/` after each update for breaking-change notes.

## What now

- **[Concepts]({{ '/CONCEPTS.html' | relative_url }})** — the 7-cardinal model, lifecycle phases, dispatch rules, iteration protocol. Worth reading once.
- **[Cheatsheet]({{ '/CHEATSHEET.html' | relative_url }})** — one-page reference for daily use.
- **[Reference]({{ '/reference/' | relative_url }})** — canonical specs: process, roles, index protocol.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `git clone` step fails | Branch/SHA ref + `git` not on PATH | Switch to a tagged ref (`--ref latest` or `--ref v0.1.0`) — those use the tarball path and skip `git`. Otherwise install `git` and re-run. |
| SHA256 verification fails | Network corruption or a tampered mirror | Re-run; if it persists, file an issue. The installer aborts before unpacking so nothing is written on mismatch. |
| `.agents/engineering-team/` exists after update | Pre-rebrand install path | The installer auto-renames on next `--update-only` run — re-run and it migrates once |
| Specialist refuses to edit a file | Forbidden role-crossing per `local/bindings.md § Project role boundaries` | Dispatch the owning role instead — the strict-domain rule is intentional |
| Discovery surfaces "no architecture doc" | Project has no `docs/architecture.md` (or similar) yet | OK; PM works without one. Author one when ready and `@team-lead rediscover` |
| Index says "dormant" for a class | Class extracted but no role kernel cites it | Wire it via `local/bindings.md § Project-specific index citations`, or remove the class from extraction |

More in [CONTRIBUTING]({{ '/CONTRIBUTING.html' | relative_url }}) and the [issue templates](https://github.com/kostiantyn-matsebora/ginee/issues/new/choose).
