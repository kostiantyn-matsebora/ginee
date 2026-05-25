# Migration — RFC 2119 keyword convention

**Target release:** next minor.
**Affected adopters:** all adopters with `.agents/ginee/` installed; auto-applies on next `/ginee-update`.
**Closes:** [#130](https://github.com/kostiantyn-matsebora/ginee/issues/130).

## What changed

`core/protocols/doc-authoring-protocol.md` + `core/process.md § Documentation style § Mandatory checks before report-as-done` gain a new mandatory check on the binding-strength signal:

> Binding-strength signal uses RFC 2119 keywords — MUST · MUST NOT · SHOULD · SHOULD NOT · MAY. Do not use `always` / `never` / `binding` / `mandatory` / `required` as rule modifiers. Imperative voice alone is permitted inside numbered procedures where every step is implicitly MUST.

The standing-checks count rises from 5 to 6; the subagent-return-surface count from 6 to 7 (the additional *no narrative preamble* check unchanged).

## Why

Pre-cutover the framework mixed binding-strength conventions across files — `**bold**` for emphasis, `always` for MUST-ish, `binding` for MUST NOT-bypass, `mandatory` / `required` for MUST. The LLM spent interpretation cycles disambiguating between mere emphasis and normative weight. Adopting the published RFC 2119 vocabulary collapses the axis to five precise keywords; readers (human + LLM) read the keyword and know the binding strength without context.

## Adopter migration

Nothing to do — forward-only. Existing rules across `core/`, `adapters/`, `extras/`, and authored adopter docs stay as-written until they're next edited. New authoring + edits going forward apply the check.

## Files touched (this migration)

| Path | Change |
|---|---|
| `core/process.md § Documentation style § Mandatory checks before report-as-done` | New check #6 — RFC 2119 binding-strength signal |
| `core/protocols/doc-authoring-protocol.md` | New section `## Mandatory check — binding-strength signal` + standing-checks-count refresh (5 → 6, 6 → 7) |
| `core/protocols/doc-authoring-examples.md` | New `§ 14` paired bad/good example |
| `migrations/rfc2119-keywords.md` | This file (NEW) |
| `CLAUDE.md` · `PLAN.md` | D48 row added |

## Action required

None — `/ginee-update` lands the new check mechanically; the convention applies on next authoring pass per file.
