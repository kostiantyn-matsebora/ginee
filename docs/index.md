---
title: Home
description: "ginee — an AI software engineering team that behaves like a real one. Drops into your project, self-onboards, and gets to work."
permalink: /
---

# ginee

[![Latest Release](https://img.shields.io/github/v/release/kostiantyn-matsebora/ginee?label=release&color=4f46e5)](https://github.com/kostiantyn-matsebora/ginee/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-4f46e5)](https://github.com/kostiantyn-matsebora/ginee/blob/main/LICENSE)

[![Claude Code](https://img.shields.io/badge/Claude%20Code-tier--1-D97757?logo=anthropic&logoColor=white)](https://github.com/kostiantyn-matsebora/ginee/blob/main/adapters/claude/README.md)
[![GitHub Copilot CLI](https://img.shields.io/badge/Copilot%20CLI-tier--1-000?logo=githubcopilot&logoColor=white)](https://github.com/kostiantyn-matsebora/ginee/blob/main/adapters/copilot-cli/README.md)
[![AGENTS.md](https://img.shields.io/badge/AGENTS.md-tier--2-4f46e5)](https://github.com/kostiantyn-matsebora/ginee/blob/main/adapters/agents-md/README.md)
[![Generic](https://img.shields.io/badge/Generic-tier--3-64748b)](https://github.com/kostiantyn-matsebora/ginee/blob/main/adapters/generic/README.md)

**An AI software engineering team that behaves like a real one. Drops into your project, self-onboards, and gets to work.**

You're running AI coding agents across projects. Each tool has its own quirks, prompts,
agent files, slash commands. The team works differently in every repo. Phases get
skipped. Roles overlap. Long tasks crash with nothing to resume from. You re-explain
the same governance every single time.

**ginee makes the team portable, the process deterministic, and your project the source of truth.**

> Drop the framework into a repo, prompt "Run initial discovery", and you have a 7-role
> engineering team that works the same way on Claude Code, Copilot CLI, Cursor, Codex,
> Windsurf, and anything that reads `AGENTS.md`.

---

## Why ginee?

<div class="why-ginee-grid">
  <article class="why-card">
    <h3><span class="why-emoji">📐</span> Process is the framework</h3>
    <p>The phased lifecycle, dispatch rules, and iteration protocol are the spine. Agents, the knowledge index, self-onboarding, the adapters — all optimisations on top. Strip them away and the process still holds; you could run it by hand.</p>
  </article>
  <article class="why-card">
    <h3><span class="why-emoji">👥</span> Works like a real team</h3>
    <p>Roles dispatch each other, hand off, and review each other's work. Strict-domain rule keeps each specialist in its lane; cross-domain bugs go through a propose → implement → verify cycle, not single-agent guessing.</p>
  </article>
  <article class="why-card">
    <h3><span class="why-emoji">🎯</span> Deterministic process</h3>
    <p>Same phased lifecycle (Phases 1–8), same dispatch rules, same gates — from one project to the next. No re-teaching what "Phase 3" means.</p>
  </article>
  <article class="why-card">
    <h3><span class="why-emoji">🤖</span> Client-agnostic</h3>
    <p>Claude Code (tier-1) · Copilot CLI (tier-1) · AGENTS.md (tier-2) · generic (tier-3). One set of role definitions; per-client renderings are pointer files only.</p>
  </article>
  <article class="why-card">
    <h3><span class="why-emoji">🔎</span> Self-learning</h3>
    <p>Zero stack/domain opinions baked in. <code>team-lead</code> learns your project on first run — tech stack, architecture, SDLC artefacts, TODO conventions, doc layout.</p>
  </article>
  <article class="why-card">
    <h3><span class="why-emoji">📥</span> Three task sources</h3>
    <p>Freeform requests, TODO files (root + nested per-component), and GitHub issues (file / pick up / triage / promote). TODOs flip ☐ → ☒ only on user approval; PRs auto-close issues via <code>Closes #N</code>.</p>
  </article>
  <article class="why-card">
    <h3><span class="why-emoji">📚</span> Reference, not copy</h3>
    <p>Project docs (architecture, mockups, diagrams) stay where they are. Doc changes propagate instantly — the framework never duplicates content.</p>
  </article>
  <article class="why-card">
    <h3><span class="why-emoji">⏱️</span> Iteration protocol</h3>
    <p>Work &gt; 15 min runs in 3–5 min stoppable batches with visible intermediate results. Interrupt anytime; resume next day with zero rework.</p>
  </article>
  <article class="why-card">
    <h3><span class="why-emoji">🧱</span> Extensible</h3>
    <p>5 pre-built specialists (security · ml · mobile · sre · data). Plus author your own under <code>local/roles/</code>.</p>
  </article>
  <article class="why-card">
    <h3><span class="why-emoji">🔄</span> Update-safe</h3>
    <p><code>core/</code>, <code>adapters/</code>, <code>extras/</code> replaced on update. <code>local/</code> (your bindings, custom roles) survives every upgrade.</p>
  </article>
  <article class="why-card">
    <h3><span class="why-emoji">🛡️</span> Compliance by construction</h3>
    <p>Per-cardinal <code>tools:</code> whitelists on the Claude adapter convert charter rules into hard gates — <code>solution-architect</code> cannot edit code; <code>ai-engineer</code> cannot run shells. Opt out per tactic via <code>local/framework.config.yaml § compliance.disabled</code>.</p>
  </article>
</div>

---

## Quick start

### 1. Install into your project

```bash
cd /path/to/your-project
curl -fsSL https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh | bash -s -- --adapter claude
```

```powershell
cd C:\path\to\your-project
$env:GINEE_ADAPTER='claude'; iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.ps1 | iex
```

Adapters: `claude` (Claude Code) · `copilot-cli` (GitHub Copilot CLI) · `agents-md` (Cursor / Codex / Windsurf / Gemini) · `generic` (fallback).

Default `--ref` is `latest` — downloads + SHA256-verifies the published release tarball; no `git` required. Pin with `--ref v0.1.0`, or track a branch / commit with `--ref main` / `--ref <sha>` (falls back to `git clone`).

### 2. Run discovery

Open your client in the project, then prompt:

```
/ginee-discovery                                # tier-1 slash command
Run initial discovery                           # natural-language equivalent
```

`team-lead` writes `local/project-profile.md`, `local/bindings.md`, `local/framework.config.yaml`, extracts a knowledge index under `local/index/`, scans external catalogs for specialist candidates, and reports recommended roles for your approval.

### 3. Give it work

Talk to *ginee* — the team self-dispatches per `local/bindings.md`. Two invocation paths:

- **Freeform** (any tier): `Use ginee to ...`.
- **Skill** (tier-1, Claude Code + Copilot CLI): `/ginee-<skill> [args]`. Natural-language phrasings also match.

Three task sources:

```
# Freeform — any source, any tier
Use ginee to add a dark-mode toggle to the header

# TODO files — /ginee-pick-up on tier-1
Use ginee to pick up the next TODO            # freeform
/ginee-pick-up                                # skill, next unchecked TODO

# GitHub issues — /ginee-* slash commands on tier-1
Use ginee to pick up issue #42                # freeform
/ginee-pick-up #42
/ginee-file-bug Safari 17 dashboard blank
/ginee-triage                                 # ranked by D23 score = value / complexity
/ginee-address-review #42                     # ingest review comments on an open PR (D24)
/ginee-update                                 # refresh framework — preserves local/
```

Full 12-skill cheat sheet in [`adapters/claude/install.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/adapters/claude/install.md#how-to-invoke). For long tasks, the iteration protocol kicks in automatically: 3–5 min batches with visible intermediate results and a stop-anywhere contract.

[**Full Getting Started guide →**]({{ '/GETTING_STARTED.html' | relative_url }})

---

## The 7 cardinals

<p>
<span class="role-badge role-badge--orchestrator">team-lead</span>
<span class="role-badge">solution-architect</span>
<span class="role-badge">ai-engineer</span>
<span class="role-badge">frontend-engineer</span>
<span class="role-badge">backend-engineer</span>
<span class="role-badge">devops-engineer</span>
<span class="role-badge">qa-engineer</span>
</p>

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

[**More on the 7-cardinal model →**]({{ '/CONCEPTS.html' | relative_url }}#the-7-cardinal-team)

---

## Where to next

- [**Getting Started**]({{ '/GETTING_STARTED.html' | relative_url }}) — install, discovery, first dispatch.
- [**Concepts**]({{ '/CONCEPTS.html' | relative_url }}) — 7-cardinal model, lifecycle, dispatch rules, iteration protocol, index protocol, delivery modes.
- [**Reference**]({{ '/reference/' | relative_url }}) — process spec, role kernels, index protocol — the canonical specs.
- [**Cheatsheet**]({{ '/CHEATSHEET.html' | relative_url }}) — one-page quick reference for daily use.
- [**Contributing**]({{ '/CONTRIBUTING.html' | relative_url }}) — issue templates, PR conventions, how to add a role.
- [**Source repo**](https://github.com/kostiantyn-matsebora/ginee) — `core/`, `adapters/`, `extras/`, install scripts.
