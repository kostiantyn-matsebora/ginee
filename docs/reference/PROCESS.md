---
title: Reference — Process spec
description: "Phased lifecycle, dispatch + parallelism rules, iteration protocol, task model. Canonical spec."
permalink: /reference/PROCESS.html
---

# Process spec

> This page is a navigator. The canonical spec lives in the repo and is too detailed (and too live) to mirror verbatim in the docs. Always trust the source.

**Canonical:** [`core/process.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/process.md)

## Sections

| Topic | Where in the spec |
|---|---|
| Reading order + conflict resolution | [§ Reading order](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/process.md#reading-order) |
| Dispatch + parallelism rules | [§ Dispatch & parallelism rules](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/process.md#dispatch--parallelism-rules) |
| Task lifecycle Phases 1–8 | [§ Task lifecycle](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/process.md#task-lifecycle--phased-pipeline-with-maximum-parallelism) |
| Automatic mode (D12) | [§ Automatic mode](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/process.md#automatic-mode) |
| Engineering principles (config vs data, test oracles) | [§ Engineering principles](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/process.md#engineering-principles--apply-across-all-roles) |
| Documentation style — structure over prose | [§ Documentation style](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/process.md#documentation-style--structure-over-prose) |
| Coordination protocol | [§ Coordination protocol](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/process.md#coordination-protocol) |
| Task model (TODO / direct / issue) | [§ Task model](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/process.md#task-model) |

## Related specs (load-on-demand)

| Spec | Load trigger |
|---|---|
| [`core/iteration-protocol.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/iteration-protocol.md) | Phase 4 / 5 / 6 / 7 work &gt; 15 min, OR doc-roles pass, OR user-given timeframe |
| [`core/automatic-mode.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/automatic-mode.md) | Task prefixed `auto:` or PM proposes auto |
| [`core/doc-roles.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/doc-roles.md) | New role-owned doc landing, doc grows past threshold, cross-ref repair after split, structure dispute author vs ai-engineer (D25) |
| [`core/cross-domain-bugs.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/cross-domain-bugs.md) | Bug spans 2+ domains |
| [`core/cross-agent-handoff.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/cross-agent-handoff.md) | Specialist diagnoses a root cause outside their domain |
| [`core/post-task-check-in.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/post-task-check-in.md) | After every completed user request |
| [`core/github-integration.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/github-integration.md) | PM ops on GitHub issues / discussions |
| [`core/delivery-modes.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/delivery-modes.md) | PM resolving delivery mode pre-Phase-4 |
| [`core/index-protocol.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/index-protocol.md) | Discovery / staleness check / re-extraction |
