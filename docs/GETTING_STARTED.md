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

### Compliance enforcement (Claude adapter, opt-in)

The shipped `.claude/agents/<role>.md` pointer files carry a scoped `tools:` whitelist per cardinal (T1) — `solution-architect` cannot `Edit` / `Write`, `ai-engineer` cannot `Bash`. Spec: [`migrations/cardinal-tools-whitelist.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/cardinal-tools-whitelist.md).

A PreToolUse hook at `.agents/ginee/adapters/claude/hooks/pre-tool-use-edit.{ps1,sh}` (T2) blocks edits violating 5 charter rules (hot-spec frontmatter · `cap-bytes` · D-token introduction · RFC 2119 modifier · always-loaded bloat). Wire into your project's `.claude/settings.json § hooks.PreToolUse` per [adapters/claude/install.md § Compliance hooks](https://github.com/kostiantyn-matsebora/ginee/blob/main/adapters/claude/install.md#compliance-hooks). Bypass per call: `SKIP_GINEE_COMPLIANCE=1`. Opt out per-tactic: `local/framework.config.yaml § compliance.disabled: [<tactic-id>]`.

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
4. **(D25)** Initializes `local/requirements.md` (FRs/NFRs/Constraints from `core/templates/requirements-register.md`) + `local/asr-utility-tree.md` (ASRs via ATAM from `core/templates/asr-utility-tree.md`) — populated from discovered NFR / Constraint sections when an architecture doc exists; left as templates for `solution-architect` to fill on the first non-trivial task otherwise.
5. **(D25)** Detects greenfield — if no architecture doc found, flags `greenfield: true` in `local/project-profile.md`; `solution-architect` enters greenfield design mode on first non-trivial task.
6. Surfaces recommended specialist roles for your approval (security · ml · mobile · sre · data, depending on what discovery found in the project).

**On rediscover post-D25** — `@team-lead rediscover` runs Step 8c re-attribution sweep: existing adopter docs migrate to the new D25 ownership map (CRs · project-instruction · work-breakdown → `team-lead`; CI/CD guide · runbooks → `devops-engineer`; per-tier READMEs → tier engineers). Full migration spec: [`migrations/classical-architect.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/classical-architect.md).

You'll see proposed changes before any file is written — approve or redirect each step.

### Compliance hook — Bash (T3, opt-in)

A second PreToolUse hook at `.agents/ginee/adapters/claude/hooks/pre-tool-use-bash.{ps1,sh}` blocks 4 destructive shell-command patterns (`git commit --no-verify`, `git push --force` on trunk, `git reset --hard`, `gh pr create` without body). Wire per [adapters/claude/install.md § Compliance hooks — Bash](https://github.com/kostiantyn-matsebora/ginee/blob/main/adapters/claude/install.md#compliance-hooks--bash-t3). Opt out: `local/framework.config.yaml § compliance.disabled: [pretooluse-bash-hook]`.

## 3. Give it work

Ginee is a team — talk to *ginee*, not to a specific role. The team routes work internally per `local/bindings.md`. Two invocation paths:

- **Freeform** (any tier): `Use ginee to ...` — catch-all; the team self-dispatches.
- **Skill** (tier-1, Claude Code + Copilot CLI): `/ginee-<skill> [args]` — slash-command on the 13 framework skills. Natural-language phrasings like `Pick up #42` also match the skill description. Cheat sheet in [adapters/claude/install.md § How to invoke](https://github.com/kostiantyn-matsebora/ginee/blob/main/adapters/claude/install.md#how-to-invoke).

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
/ginee-triage                                               # ranked by score = value / complexity (D23)
/ginee-promote-discussion #17
/ginee-address-review #42                                   # ingest review comments on an open PR (D24)
/ginee-iterate                                              # auto-engages when you reply to a live cardinal — relays to the warm agent instead of editing from the main thread
```

`/ginee-iterate` auto-engages when the warm registry holds an active cardinal AND your next reply targets files the cardinal owns — your "fix the button" / "modal flashes" replies route to the warm agent verbatim via `SendMessage`, preserving warm-reuse savings across the cycle. Hand-back to `@team-lead` on `## Open issues` / `## Hand-off` / stop-state. Full spec: [`core/skills/ginee-iterate/SKILL.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/skills/ginee-iterate/SKILL.md).

`/ginee-triage` ranks ready work by **score = value / complexity** per [D23 triage scoring](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/triage-scoring.md) — `value:high|medium|low` + `complexity:high|medium|low` labels (ATAM H/M/L, `H=3, M=2, L=1`). On pickup, missing `value` → team-lead asks you; missing `complexity` → `solution-architect` auto-estimates. Sticky `<!-- ginee:score v=1 -->` comment per issue.

`/ginee-address-review` covers the interval **between Phase 7 (internal SA review) and Phase 8 (user accept)** when a PR is exposed to external reviewers — fetches `pulls/{N}/comments` + `/reviews`, routes each remark to the owning specialist, surfaces a consolidated plan table for your approval (no exception even in `auto:` mode), then reconciles fixes into one cycle commit + per-thread replies. Lossless coverage (every remark → fix OR reply) + idempotent re-invocation. Full spec: [`core/protocols/github-integration.md § Review-comment ingestion`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/github-integration.md#review-comment-ingestion).

PRs auto-close issues via `Closes #N`. For tasks &gt; 15 minutes of estimated work, the [iteration protocol](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/iteration-protocol.md) kicks in: each specialist returns a task decomposition + per-task estimate **before** editing, you approve, then 3–5 min stoppable batches.

### Adopter docs (architecture, ADRs, runbooks) — doc-authoring protocol (D22)

When ginee authors adopter markdown (architecture doc, ADRs, CRs, READMEs, runbooks, scenarios, API docs), the [doc-authoring protocol](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/doc-authoring-protocol.md) is **binding**: structure over prose (tables / bullets / definitions), 5 mandatory checks, and the discovered markdown / prose linter (`markdownlint` / `vale` / `proselint` / `prettier-md`) runs at Phase 5. No linter configured → discovery report recommends a baseline; you decide — never auto-installed.

### Compliance statusline — T4 (opt-in, visible-state)

`.agents/ginee/adapters/claude/statusline.{ps1,sh}` surfaces compliance state in Claude Code's status row (issue # · trailer · cap headroom). Wire per [adapters/claude/install.md § Compliance statusline](https://github.com/kostiantyn-matsebora/ginee/blob/main/adapters/claude/install.md#compliance-statusline-t4). Opt out: `local/framework.config.yaml § compliance.disabled: [compliance-statusline]`.

### Compliance — Tier 2 hooks (T5 / T6 / T7 / T8, opt-in)

Four more hooks complete the playbook's enforcement surface:

- **T5 — UserPromptSubmit** — task-keyword detection (`pick up #N` · `auto:` · `triage` · `@<role>` · …) injecting spec excerpts into the prompt before the LLM sees it. Patterns / bodies in `.agents/ginee/adapters/claude/hooks/keyword-triggers.yaml`.
- **T6 — PostToolUse on `core/**`** — ≤ 6-line self-check reminder after every successful edit (frontmatter · cap-bytes · D-free · lossless · always-loaded). Coexists with the structural context-economy gate.
- **T7 — Stop** — refuses turn-end on incomplete-work signals (missing `<!-- self-lint: pass -->`, PR opened without acceptance, open `ginee:in-progress` issue without Phase-8 close). Anti-loop guard prevents trapping.
- **T8 — PreToolUse `SendMessage`** — blocks warm-cardinal continuations missing the `[carry-forward] Remember: <rule>` anchor. Per-cardinal rules in `.agents/ginee/adapters/claude/hooks/carry-forward-rules.yaml`.

All four wire automatically via `/ginee-update`. Bypass per call: `SKIP_GINEE_COMPLIANCE=1`. Per-tactic opt-out IDs: `user-prompt-submit-hook`, `posttooluse-edit-hook`, `stop-hook`, `pretooluse-send-message-hook`. Full specs per [adapters/claude/install.md § Compliance hooks + statusline](https://github.com/kostiantyn-matsebora/ginee/blob/main/adapters/claude/install.md#compliance-hooks--statusline-per-playbook-135).

### Compliance — Tier 3 closeout (T9 / T10 / T11 / T12 / T13, opt-in)

The last batch of the playbook closes out the recency-optimisation pass + slash command suite + main-thread permission lockdown + session-resume hook + attestation gate:

- **T9 — CLAUDE.md bookending** — 5 hard constraints (self-lint marker · SA never edits · context-economy trailer · D-free runtime · `local/**` only via discovery) appear at the top AND bottom of `CLAUDE.md` so they survive recency drift. Adopters who re-paste the pointer block (or run `/ginee-update`) inherit both ends automatically.
- **T10 — slash command suite** — six deterministic-template commands ship under `.claude/commands/ginee-*.md` (`/ginee-dispatch <role> <task>` · `/ginee-phase-report` · `/ginee-self-lint` · `/ginee-commit` · `/ginee-pr` · `/ginee-issue-pickup #N`). Replaces LLM free-form composition with schema-bound prompts at the moment of composition.
- **T11 — main-thread permission lockdown + dispatch-cap** — `.claude/settings.json § permissions.deny` blocks `Edit` / `Write` / `MultiEdit` on `.agents/ginee/{core,adapters,extras}/**` + destructive Bash from the main thread; real work routes through cardinals. Adopter project code untouched. Optional `local/framework.config.yaml § warm-reuse.dispatch-cap: 15` triggers forced-fresh + `## Carry-forward summary` payload when a warm cardinal accumulates too many dispatches.
- **T12 — SessionStart resume hook** — scans `issue/<N>-…` branch state + open `ginee:in-progress` GitHub issues at session boundary; injects `[ginee:resume]` block via `hookSpecificOutput.additionalContext`. Quiet on empty; offline-safe.
- **T13 — Optimized-By attestation gate (ask-mode, push-time)** — sister tactic. When `git push` would push a range carrying `Optimized-By: ai-engineer` trailer in any commit, the hook scans the session transcript for an `Agent(subagent_type=ai-engineer)` dispatch. Absent → Claude Code surfaces its native permission prompt; user picks allow (cross-session work · manual lossless pass · WIP push) or deny (cancel + dispatch first). Path-agnostic — fires equally on framework-self-dev (`core/**` · `adapters/**` · `extras/**`) and adopter pushes (docs / prompts / `local/`). Closes the trailer-claim loophole the gate could not catch on its own.

All five wire automatically via `/ginee-update`. New per-tactic opt-out IDs: `slash-commands`, `main-thread-permissions`, `session-start-hook`, `optimized-by-attestation`. Full specs per [adapters/claude/install.md § Compliance hooks + statusline](https://github.com/kostiantyn-matsebora/ginee/blob/main/adapters/claude/install.md#compliance-hooks--statusline-per-playbook-135).

## 4. Update later

**Preferred — `/ginee-update` skill** (tier-1; works once you have ginee 0.8.0+ installed):

```
/ginee-update                                  # latest published release
/ginee-update v0.9.0                           # pin to a tag
/ginee-update main                             # track a branch (git required)
"update ginee" / "upgrade the framework"       # natural-language equivalent
```

team-lead loads `core/skills/ginee-update/SKILL.md`, resolves the target ref, **surfaces the plan + waits for your explicit approval** (never auto-runs), fetches the installer from upstream at the target ref (per D27 — the installer lives at upstream, not inside `.agents/ginee/`), drives `install.{ps1,sh} --update-only`, then reports VERSION delta + CHANGELOG range + new `migrations/*.md` files. Refuses downgrades unless `--allow-downgrade` is passed.

**Manual fallback — bootstrap one-liner** (the installer is intentionally NOT inside `.agents/ginee/` per D27 — fetch from upstream every time):

```bash
GINEE_UPDATE_ONLY=1 GINEE_ADAPTER=claude bash -c "$(curl -fsSL https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh)"
```

```powershell
$env:GINEE_UPDATE_ONLY='1'; $env:GINEE_ADAPTER='claude'; iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.ps1 | iex
```

`core/`, `adapters/`, `extras/` re-fetch from the framework upstream. `local/` (your bindings + custom roles + discovered index) is preserved untouched. Read `.agents/ginee/migrations/` after each update for breaking-change notes.

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
