# Migration — hot-spec frontmatter standard

**Target release:** next minor.
**Affected adopters:** all adopters with `.agents/ginee/` installed; auto-applies on next `/ginee-update`.
**Closes:** [#129](https://github.com/kostiantyn-matsebora/ginee/issues/129).

## What changed

- New spec `core/protocols/hot-spec-format.md` defines the YAML-frontmatter standard for hot specs (`audience` · `load` · `triggers` · `cap-bytes` · `reads-before-applying`).
- The spec self-applies — its own frontmatter is the worked example.
- `scripts/context-economy-check.ps1` extended to validate frontmatter presence + key completeness + size cap on every changed file in scope (`core/process.md` · `core/process/*.md` · `core/protocols/*.md` · `core/roles/*.md`). Same `Optimized-By: ai-engineer` trailer bypass as per-class caps.
- Phase 4 sweep landed frontmatter on the in-scope files; no rule text changed.

## Why

Pre-cutover the load-decision (who reads this file, when, with what prereqs) was implicit — readers inferred it from prose preambles and from `core/protocols/index-protocol.md § Read order` heuristics. Inference is a per-dispatch tax that scales with `core/` byte-weight. Frontmatter pulls the decision to a fixed surface the LLM parses once and the validator gates mechanically.

- **Token economy.** Single-pass frontmatter parse replaces re-derivation per dispatch across every adopter.
- **Validator surface.** Size cap + completeness move from "ai-engineer notices ad-hoc" to a gate matching the existing doc-size-caps machinery.
- **Self-documenting load topology.** New specs declare audience + trigger up front; reviewers see the load envelope without reading the body.

## Adopter migration

**Nothing to do.** `/ginee-update` replaces `<fw>/core/` wholesale (preserving `local/`); frontmatter lands automatically.

`local/roles/<role>.md` (adopter custom roles per the local-role-extensions cutover) is **not** in validator scope — adopter-owned files are unaffected.

## Files touched (this migration)

| Surface | Change |
|---|---|
| `core/protocols/hot-spec-format.md` | New spec (self-applies frontmatter) |
| `core/process.md` · `core/process/*.md` · `core/protocols/*.md` · `core/roles/*.md` | Frontmatter added (Phase 4 sweep; no rule changes) |
| `scripts/context-economy-check.ps1` | Frontmatter validator added (Phase 4 devops) |
| `tests/context-economy-check.Tests.ps1` | Coverage for the new validator |
| `local/**` | Not touched — out of validator scope |
| `core/skills/*/SKILL.md` · `core/templates/*.md` | Not touched — AgentSkills frontmatter / template files own those surfaces |
| `PLAN.md` · `CLAUDE.md` | New decision row added (history surface) |

## Action required

None — `/ginee-update` lands the change mechanically. Adopters with `local/roles/<role>.md` cardinal extensions are unaffected.
