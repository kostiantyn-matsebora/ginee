# Migration — CLAUDE.md hard-constraints bookending

**Target release:** next minor after 2026-05-26.
**Affected adopters:** Claude Code adapter only.
**Closes:** [#145](https://github.com/kostiantyn-matsebora/ginee/issues/145).
**Parent:** [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135) — tactic 9 / Tier 2, Class H (recency-optimized).

## What changed

Two files gain a hard-constraints bookend — verbatim list at the **top** and the **bottom** of their content. LLMs read first / last more carefully; middle drifts.

| File | Bookend headings |
|---|---|
| Framework's own `CLAUDE.md` | `## HARD CONSTRAINTS (always)` · `## HARD CONSTRAINTS — RECAP` |
| `adapters/claude/CLAUDE-pointer.md` (block adopters paste into their `CLAUDE.md`) | `### HARD CONSTRAINTS (always)` · `### HARD CONSTRAINTS — RECAP` |

The 5 hard constraints — bookended verbatim:

1. **Self-lint marker** — every cardinal return ends with `<!-- self-lint: pass -->`. No exceptions.
2. **SA never edits** — `solution-architect` returns APPROVE / REJECT / REQUEST-CHANGES only; never `Edit` / `Write` (subagent `tools:` whitelist enforces).
3. **Context-economy trailer** — any commit > ~50 net-added lines on `core/` · `adapters/` · `extras/` carries `Optimized-By: ai-engineer`.
4. **Runtime stays D-free** — `core/**` · `adapters/**` · `extras/**` · migration filenames carry no `D<N>` tokens. `PLAN.md` is the sole D-log.
5. **`local/**` only via discovery** — never edit from main thread; route to the discovery skill.

The 5 rules restate invariants already enforced elsewhere (subagent `tools:` whitelist · context-economy gate · D-free runtime rule · discovery flow). Bookending adds zero new rule surface — only attention amplification.

## Why

Parent #135 § Force taxonomy — Class H (always-loaded text) is recency-sensitive. Long always-loaded files lose middle-content attention; bookending positions the operative rules at both retained ends. LLM compliance failures observed under task pressure all involved silent drop of constraints buried in `CLAUDE.md`'s middle.

Same content, two positions → marginal token cost, large recency gain.

## Architecture

| Surface | Owns |
|---|---|
| `CLAUDE.md` (framework dev repo) | h2 bookend; framework-dev LLM picks up the constraints on every turn |
| `adapters/claude/CLAUDE-pointer.md` | h3 bookend within the ginee block; adopter LLMs picks up the constraints on every turn after pasting per `adapters/claude/install.md § Steps` |

Adopter side uses h3 because the pointer block lives under an h2 in the adopter's `CLAUDE.md`. Framework side uses h2 because `CLAUDE.md` is the whole file.

`#5` is a no-op in the framework repo (no `local/` in framework-self-dev); kept verbatim because the acceptance criterion is *same 5, verbatim across both surfaces*.

## Verification

| Step | Expected |
|---|---|
| Manual diff of framework `CLAUDE.md` | Two new sections; existing content unchanged byte-for-byte except the two insertion points |
| Manual diff of `adapters/claude/CLAUDE-pointer.md` | Two new sections inside the block; existing pointer body unchanged |
| Context-economy gate — `pwsh scripts/context-economy-check.ps1 -BaseRef origin/main` | `pass` (net add < ~50 lines per file) |
| Size budget — framework `CLAUDE.md` line count post-edit | ≤ 85 lines (was 67; +14 lines bookending) |

No script tests — this is doc-only. `tests/` unchanged.

## Decisions affected

- **Parent playbook #135** — ninth tactic shipped; Tier 2 final.
- **`core/process.md` § Documentation style** — unchanged; bookending is a Class H *recency optimisation*, not a new style rule.
- **`adapters/claude/install.md § Steps`** — unchanged; the paste-the-block step continues to work; adopters who paste freshly get the bookend automatically.

## Forward-only

Purely additive. Adopters who do not re-paste the pointer block keep their existing structure; no breaking change. `/ginee-update` rewrites the pointer-block body between `## Engineering team framework` and the next `---` — fresh paste lands the new bookend on next update.

## Out of scope

- **Per-cardinal bookending in role kernels.** Considered; deferred — role kernels load on phase-bound dispatch, not every turn; recency-bias gains smaller.
- **Multi-block rotating recap** that varies the bottom section each load. Considered; deferred — no evidence of habituation to the verbatim recap at this scale.
- **Adopter-side bookending of non-ginee content.** Adopter decides whether to bookend the rest of their `CLAUDE.md`; ginee owns only its pointer block.
