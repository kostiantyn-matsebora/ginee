---
title: Reference
description: "Canonical specs for ginee — process, role kernels, index protocol, GitHub integration, delivery modes, automatic mode."
permalink: /reference/
---

# Reference

The canonical specs. These mirror the `core/*.md` files in the [source repo](https://github.com/kostiantyn-matsebora/ginee/tree/main/core) — links below take you there directly so you always see the latest authoritative version.

## Per-page

- [**Process spec**]({{ '/reference/PROCESS.html' | relative_url }}) — Phase 1–8 lifecycle, dispatch + parallelism rules, iteration protocol, doc co-ownership, task model.
- [**Role kernels**]({{ '/reference/ROLES.html' | relative_url }}) — the 7 cardinals + 5 specialists. What each owns, what each must not edit, source-of-truth tables with load triggers.
- [**Index protocol**]({{ '/reference/INDEX_PROTOCOL.html' | relative_url }}) — `local/index/` extraction, lossless coverage + compression floor, consumer coupling, per-file load triggers, manifest schema.

## Specs by concern

| Concern | Canonical spec | Linked from |
|---|---|---|
| Phased lifecycle, dispatch, iteration | [`core/process.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/process.md) | Concepts § Phased task lifecycle |
| Iteration protocol detail | [`core/iteration-protocol.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/iteration-protocol.md) | Concepts § Iteration protocol |
| Automatic mode | [`core/automatic-mode.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/automatic-mode.md) | Concepts § Phased task lifecycle (auto mode) |
| Index protocol + recipes | [`core/index-protocol.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/index-protocol.md) | Concepts § Index protocol |
| `.idx` DSL grammar | [`core/index-syntax.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/index-syntax.md) | Index protocol |
| Doc roles (all-roles authorship + ai-engineer shape — D25) | [`core/doc-roles.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/doc-roles.md) | Process spec |
| Cross-domain bugs | [`core/cross-domain-bugs.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/cross-domain-bugs.md) | Process spec |
| Cross-agent hand-off | [`core/cross-agent-handoff.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/cross-agent-handoff.md) | Process spec |
| Post-task check-in | [`core/post-task-check-in.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/post-task-check-in.md) | Process spec |
| GitHub integration | [`core/github-integration.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/github-integration.md) | Concepts § GitHub issues |
| Delivery modes | [`core/delivery-modes.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/delivery-modes.md) | Concepts § Delivery modes |
| Cardinal role kernels | [`core/roles/*.md`](https://github.com/kostiantyn-matsebora/ginee/tree/main/core/roles) | Concepts § The 7-cardinal team |
| Specialist roles (opt-in) | [`extras/roles/*.md`](https://github.com/kostiantyn-matsebora/ginee/tree/main/extras/roles) | Concepts § Specialists |
| Templates (bindings, PR, hand-off, ...) | [`core/templates/*.md`](https://github.com/kostiantyn-matsebora/ginee/tree/main/core/templates) | Contributing |
| Migration notes | [`core/MIGRATIONS/*.md`](https://github.com/kostiantyn-matsebora/ginee/tree/main/core/MIGRATIONS) | Per-decision (D13 / D14 / D15 / D16 / D17 / etc.) |

## Locked decisions

All locked decisions (D1–D17) live in [`PLAN.md § Locked decisions`](https://github.com/kostiantyn-matsebora/ginee/blob/main/PLAN.md#locked-decisions). The framework's design rationale + alternatives considered + dates.

Some highlights:

| # | Decision |
|---|---|
| D5 | 7 cardinal roles (5 engineering + team-lead + ai-engineer) |
| D8 | Install directory: `.agents/ginee/` |
| D11 | Public framework name: `ginee` |
| D12 | Automatic mode (per-task `auto:` opt-in) |
| D13 | Project-doc index in `local/index/` (D15 broadens to code-derived) |
| D14 | GitHub issues + discussions as 4th task source |
| D15 | Code-derived knowledge index (extension of D13) |
| D16 | AgentSkills as per-adapter invocation surface |
| D17 | Delivery modes — branch+PR / wt / commit-no-push |

## API surface

ginee is **markdown-only**. There's no programmatic API, no library to import, no build artefact. The "API" is:

- **Role kernels** — describe what each specialist accepts as a dispatch.
- **Templates** — bindings, PR description, hand-off note, phase report, etc. Shape the inputs to the framework.
- **Skills** under `core/skills/ginee-*/SKILL.md` — surfaced via AgentSkills-compatible clients. Trigger via natural language ("Run initial discovery", "File a bug for X", etc.).
- **Install scripts** — `install.ps1` / `install.sh` with documented CLI parameters.

The full surface is in the source repo. Each spec is &lt; 500 lines and self-contained.
