---
title: Reference — Index protocol
description: "local/index/ extraction, lossless coverage + compression floor, consumer coupling, per-file load triggers, manifest schema."
permalink: /reference/INDEX_PROTOCOL.html
---

# Index protocol

> Navigator page. Canonical spec in the repo.

**Canonical:** [`core/protocols/index-protocol.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/index-protocol.md)

## What the index is

`local/index/` holds **lightweight per-class summaries** of every doc + code source ginee learned about during discovery. Roles read the index first; raw sources only when an index entry says "see source for full statement" or the role is authoring new content.

The win — measured on a real adopter (deployment-dashboard, ~470 KB raw docs):

| Tier | Before | After (full stack: #9 + #10 + #11) |
|---|---|---|
| Per-dispatch baseline (devops trivial task) | ~56 KB | ~12 KB |
| Per-dispatch baseline (frontend trivial task) | ~64 KB | ~25 KB |
| Per-dispatch baseline (backend trivial task) | ~43 KB | ~12 KB |

## Sections

| Topic | Where in the spec |
|---|---|
| Why the index exists | [§ Why](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/index-protocol.md#why) |
| Where compression pays off | [§ Where compression pays off](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/index-protocol.md#where-compression-pays-off--and-where-it-doesnt) |
| Source types (doc + code categories) | [§ Source types](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/index-protocol.md#source-types) |
| Manifest schema (sha256, byte-size, consumed-by) | [§ Manifest shape](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/index-protocol.md#manifest-shape) |
| Consumer coupling | [§ Consumer coupling](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/index-protocol.md#consumer-coupling) |
| Dormant-index audit | [§ Dormant-index audit](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/index-protocol.md#dormant-index-audit) |
| Lifecycle — initial extraction + staleness + re-extraction | [§ Lifecycle](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/index-protocol.md#lifecycle) |
| Lossless rule (coverage + compression floor + sample-and-check) | [§ Lossless rule for index](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/index-protocol.md#lossless-rule-for-index) |
| Role consumption pattern (load triggers + reporting + overrides) | [§ Role consumption pattern](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/index-protocol.md#role-consumption-pattern) |
| Adopter-declared classes | [§ Extension — adopter-declared classes](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/index-protocol.md#extension--adopter-declared-classes) |

## Recipes (in `ai-engineer.details.md`)

| Source category | Built-in recipes |
|---|---|
| **Doc** | `builtin:architecture` · `builtin:mockup` · `builtin:adr` · `builtin:cr` · `builtin:scenario` |
| **Code / config** | `builtin:package-manifest` · `builtin:container-orchestration` (+ `builtin:iac`) · `builtin:commands` · `builtin:conventions` · `builtin:runtime-facts` · `builtin:repo-structure` |
| **Novel class** | Adopter-specific; `ai-engineer` authors the recipe per the [novel-class recipe](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/roles/ai-engineer.details.md#novel-class-recipe) procedure |

## `.idx` DSL grammar

The compact flat-record format used by `.idx` index files. Canonical: [`core/protocols/index-syntax.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/protocols/index-syntax.md).

## Migration notes

| Migration | When applied |
|---|---|
| [`D15-code-derived-index.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/code-derived-index.md) | D13 extended to code/config sources |
| [`index-compression-floor.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/index-compression-floor.md) | Issue #9 — compression floor + inventory-only D15 recipes |
| [`novel-class-consumer-coupling.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/novel-class-consumer-coupling.md) | Issue #10 — consumed-by field + dormant audit |
| [`index-load-triggers.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/index-load-triggers.md) | Issue #11 — per-file load triggers in role kernels |
| [`bindings-source-of-truth-rename.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/migrations/bindings-source-of-truth-rename.md) | Issue #7 — bindings.md heading rename + reframe |
