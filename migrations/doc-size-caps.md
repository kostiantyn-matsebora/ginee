# Migration — Per-class doc size caps

**Target release:** next minor after 2026-05-25.
**Affected adopters:** every adopter on every adapter — opt-in by enabling the existing context-economy CI workflow + setting class-directory keys in `local/framework.config.yaml`. Zero behavioural change for adopters who don't configure ADRs · CRs · UI docs.
**Closes:** [#113](https://github.com/kostiantyn-matsebora/ginee/issues/113).
**Spec:** [`core/protocols/doc-size-caps.md`](../core/protocols/doc-size-caps.md).

## What changed

`scripts/context-economy-check.ps1` gains a per-class total-file-size check on top of the existing delta-threshold gate. Three doc classes carry default caps:

| Class | Default cap (bytes) | Class directory key (in `local/framework.config.yaml`) |
|---|---|---|
| ADR | 4096 | `adr-directory` |
| CR | 6144 | `cr-directory` |
| UI doc | 4096 | `ui-directory` |

The check compares each changed file's **current total size** (not delta) against its class cap. Breach without an `Optimized-By: ai-engineer` trailer fails the gate — same trailer-bypass machinery as the delta-threshold check; same Claude Code hook + git hooks + CI workflow wiring.

## Why

`core/process.md § Documentation style` + the doc-authoring protocol govern *shape*. Neither governs *size*. Once a load-on-demand doc class crosses an unbudgeted threshold, every dispatch that loads it pays the cost — and `ai-engineer` only learns about the bloat ad-hoc, after it lands. Per-class size caps add the missing dimension at the doc-class granularity where the spend actually lands.

## Adopter migration

**Nothing required if you don't track ADRs · CRs · UI docs.** Defaults apply silently to absent class directories; no breach can fire.

**To enable enforcement** in your project:

1. Set the class-directory keys in `local/framework.config.yaml` to match your project layout:

   ```yaml
   adr-directory: docs/adr/        # or wherever your ADRs live
   cr-directory: docs/cr/
   ui-directory: docs/ui/          # new key — comment out if you don't track UI docs
   ```

2. (Optional) Override caps or opt out per class:

   ```yaml
   doc-size-caps:
     adr:
       cap-bytes: 6144              # raise the framework default
     cr:
       cap-bytes: 8192
     # ui: disabled                 # opt out for this class entirely
   ```

3. The existing context-economy gate (Claude Code hook · git hooks · CI workflow) picks up the per-class check automatically — no workflow changes required.

**Existing oversized docs** — forward-only. Breaches surface on the next touch of an over-cap file; no retroactive sweep. Matches the doc-authoring protocol enforcement scope.

## Breach routing

A per-class cap breach is an `ai-engineer` dispatch trigger:

- **Scope** — the breaching file(s); the lossless rule binds (no rule deletion).
- **Acceptance** — file size at or below cap OR `Optimized-By: ai-engineer` trailer on the commit landing the optimization pass (records that the pass ran; a load-on-demand split or scope reduction is the natural outcome rather than literal byte-reduction).
- **Path** — same load-on-demand split pattern proven on `core/automatic-mode.md` · `core/protocols/options-protocol.md` · `core/protocols/doc-authoring-protocol.md`.

## Decisions affected

- **Per the existing context-economy gates** — extended with a per-class check on top of the existing whole-PR threshold. Same trailer bypass; same hook + workflow wiring.
- **Per the doc-authoring protocol** — size cap complements shape rules; size is an orthogonal axis. The five mandatory shape-checks remain unchanged; the four mandatory size-cap-pass checks live in `core/protocols/doc-size-caps.md § Mandatory checks before pushing a breaching commit`.
- **Per the classical-architect role model** — `ai-engineer` charter gains breach-as-dispatch-trigger; SA still owns architecture-doc semantics. The cap covers *shape and load topology*; SA's doc-class ownership is unchanged.
- **Per the framework's own load-on-demand pattern** — applied at the doc level. The same approach used to split `core/process.md` (D35) and the protocol family (`core/automatic-mode.md` · `options-protocol.md` · etc.) becomes binding for any over-cap doc.

## Files updated

| File | Change |
|---|---|
| `core/protocols/doc-size-caps.md` (NEW) | Full spec — defaults · override · enforcement · breach routing · mandatory checks · out-of-scope. |
| `core/process.md § Documentation style` | New table row cross-referencing the spec. |
| `core/templates/framework.config.yaml` | `ui-directory:` key + `doc-size-caps:` block (commented; documented defaults). |
| `core/roles/ai-engineer.md § Process integration` | Breach-as-dispatch-trigger bullet. |
| `scripts/context-economy-check.ps1` | `Read-DocSizeCapConfig` + `Get-DocClass` + `Get-DocSizeCapBreach` functions; integration into `Invoke-ContextEconomyCheckMain` main loop; report extension. |
| `tests/context-economy-check.Tests.ps1` | 10 new Pester cases — defaults · per-class override · `disabled` opt-out · adopter-specified directory · trailer bypass · helper coverage. |

## Out of scope (v1)

- **Token-count caps.** Byte-count for v1; coupling to a specific tokenizer is undesirable. Open question.
- **Soft-advisory variant.** User explicitly requested hard cap with trailer-bypass; soft warnings are not part of v1.
- **Caps for non-listed classes** — architecture-doc · README · runbook · scenario · API docs. Revisit if/when there is a motivating breach.
- **Retroactive sweep of existing docs.** Forward-only.
- **Per-section caps.** File-level only; subsection caps would require a parser.
- **Adapter-side CI workflow templates** for adopters who don't already have `.github/workflows/context-economy.yml` running. Adopters who run the existing workflow get the per-class check automatically; bootstrapping the workflow for fresh adopters is a separate concern.

## Backwards compatibility

Purely additive on the adopter-action surface. `local/framework.config.yaml` schema gains the `ui-directory:` key + `doc-size-caps:` block — both optional; both default to no-op when absent. Installer flags unchanged. Skill triggers unchanged. No `core/` rule walked back.

Forward-only. Pre-existing oversized docs surface as advisories on next touch; no one-time repo-wide audit. Adopters who do nothing on upgrade see no change.
