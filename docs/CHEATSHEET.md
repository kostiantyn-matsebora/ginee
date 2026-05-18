---
title: Cheatsheet
description: "One-page quick reference — every command, label, phase, and pattern you'll touch."
permalink: /CHEATSHEET.html
---

# Cheatsheet

One page. Daily use. Bookmark it.

## Install / update

```bash
# Fresh install
curl -fsSL https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh | bash -s -- --adapter claude
.\install.ps1 -Adapter claude        # PowerShell

# Pin version
./install.sh --ref v0.1.0 --adapter claude
$env:GINEE_REF='v0.1.0'; iwr ... | iex

# Update (preserves local/)
./install.sh --update-only --adapter claude
.\install.ps1 -UpdateOnly -Adapter claude
```

Adapters: `claude` · `copilot-cli` · `agents-md` · `generic`.

## First-day workflow

```
Run initial discovery                  # ginee-discovery skill
```

Then:

```
@<role> <task>                         # dispatch a specialist
auto: <task>                           # elide per-phase gates (D12)
branch: <task>                         # force feature-branch + PR mode (D17)
wt: <task>                             # working-tree only — no commits
commit: <task>                         # commit-no-push
auto: branch: <task>                   # combine — auto mode + branch+PR
```

## PM commands (orchestrator)

```
@project-manager run initial discovery
@project-manager rediscover                              # full re-discovery + re-extraction
@project-manager file bug <title>                        # opens issue in primary repo (current)
@project-manager file feature <title>
@project-manager file framework-bug <title>              # opens issue in ginee upstream repo
@project-manager file framework-feature <title>
@project-manager pick up #<N>                            # primary repo only
@project-manager triage                                  # list ready issues
@project-manager triage framework                        # list ready framework upstream issues
@project-manager promote discussion #<N>                 # discussion → draft issue
```

## AI-engineer commands (context + index)

```
@ai-engineer reindex <source>                            # targeted re-extraction
@ai-engineer extract code-derived sources                # D15 retro-extraction
@ai-engineer extract <novel-class>                       # after wiring consumer in bindings.md
@ai-engineer audit consumed-by                           # surface dormant indexes
```

## Phase lifecycle

| Phase | Goal | Gate |
|---|---|---|
| 1. Analysis | Bound scope | ≤ 1 unresolved scope question |
| 2. Design | Lock contracts | Contract surfaces fixed |
| 3. Design review | User approval of Phase 2 | **Explicit user OK** (elided in auto mode if no UX impact) |
| 4. Implementation | Working code | Compiles + unit tests pass |
| 5. Testing | Change-scoped suites + manual smoke | Touched-surface oracles green |
| 6. Bug fixing | Resolve Phase 5 defects | No regressions |
| 7. SA review | Architecture compliance | APPROVE or RETURN-TO-engineer |
| 8. User approval | Delivery accept | TODO ☐ → ☒; issue closed; PR per mode |

## GitHub label scheme

| Label | Meaning |
|---|---|
| `ginee:ready` | Pickup candidate (`☐` equivalent) |
| `ginee:in-progress` | PM has dispatched; phases 1–7 in flight |
| `ginee:blocked` | Stoppable intermediate state; awaiting user / external |
| (closed issue) | Done — implicit, no label change needed |

## Source-of-truth pattern

```
local/index/*               ← default read every dispatch
docs/* (raw)                ← on demand only (verbatim wording matters)
local/bindings.md           ← governance + tie-breakers
local/project-profile.md    ← discovered project context
local/framework.config.yaml ← concept → path mappings
```

## Strict-domain rule (forbidden role-crossings)

Per `local/bindings.md § Project role boundaries`. Each row is a hard stop.

| Role | Must NOT edit |
|---|---|
| `solution-architect` | mockup, server source, client source, IaC, Dockerfiles, CI workflows |
| `frontend-engineer` | server source (incl. SQL in API endpoints), IaC, Dockerfiles, CI workflows |
| `backend-engineer` | client source, mockup, IaC, Dockerfiles, CI workflows |
| `devops-engineer` | application code, schema migrations, application config content |
| `qa-engineer` | mockup, production server / client code (owns test code only) |
| `ai-engineer` | rules / invariants / requirements (semantics → SA); production / test / IaC code |
| `project-manager` | everything except `local/*` written during discovery |

Cross-domain need surfaced mid-task → **propose hand-off in final report**. Never patch across.

## Index file Load-when tiers

Per cardinal role kernel `## Source of truth`:

- **always** — foundational; loaded every dispatch (single-digit KB combined).
- **scope-loaded** — trigger phrase (e.g. `wire/endpoint touch`, `infra work`, `dep bump`, `test authoring`). Loaded only when the task description matches.

Specialist reports loaded set in first response.

## Iteration protocol (work &gt; 15 min)

1. Estimation-first dispatch — task decomposition + per-task minutes **before** edits.
2. User approves the batch.
3. 3–5 min iterations, each stoppable.
4. Stop anywhere → resume next session with zero rework.

## Delivery modes (D17)

| Prefix | Mode | Phase 8 |
|---|---|---|
| `branch:` | feature branch + PR | `gh pr create` with `Closes #<N>` |
| `wt:` | working-tree only | PM surfaces `git diff`; user commits / discards |
| `commit:` | commit-no-push | PM surfaces `git log`; user pushes |

Framework defaults: `branch` for issue / TODO-sourced; `wt` for freeform. Auto-mode default: `wt`.

## Common pitfalls

| Symptom | Likely cause | Fix |
|---|---|---|
| Specialist refuses to edit a file | Forbidden role-crossing | Dispatch the owning role |
| Index is dormant ("no consumer") | Novel class extracted but no kernel cites it | Wire via `local/bindings.md § Project-specific index citations` or remove the class |
| `local/index/` &gt; 30% of `docs/` size | Recipe over-extracting | Run `@ai-engineer reindex` against the worst class; check compression target ≤ 0.5 |
| Discovery flagged staleness on a doc | SHA-256 drift | `@ai-engineer reindex <source>` (targeted) or `@project-manager rediscover` |
| PR didn't auto-close issue on merge | Stacked PR merged into non-default branch first | Manual `gh issue close <N> --comment "..."` |
| Trivial task loads full 64 KB baseline | Role kernel `Load when` not honoured | Specialist should report loaded set; if it doesn't, your kernel may be stale — `--update-only` to refresh |

## Where things live

```
.agents/ginee/
├── core/                       # upstream — process spec + role kernels + templates
│   ├── process.md              # phased lifecycle, dispatch, iteration
│   ├── roles/                  # 7 cardinal role kernels
│   ├── index-protocol.md       # local/index/ extraction + load triggers
│   ├── github-integration.md   # issue / PR / label flow
│   ├── delivery-modes.md       # branch / wt / commit
│   └── templates/              # bindings, PR description, hand-off note
├── adapters/<client>/          # upstream — per-client renderings (pointer files)
├── extras/roles/               # upstream — opt-in specialists
└── local/                      # YOU OWN THIS — survives every update
    ├── project-profile.md
    ├── bindings.md
    ├── framework.config.yaml
    ├── index/                  # extracted summaries
    └── roles/                  # your custom roles
```
