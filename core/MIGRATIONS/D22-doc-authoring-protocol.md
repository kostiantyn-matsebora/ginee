# D22 — Doc-authoring protocol for adopter docs

**Date.** 2026-05-19.
**Closes.** [#39](https://github.com/kostiantyn-matsebora/ginee/issues/39).

## What changed

`core/process.md § Documentation style — structure over prose` was already declared to apply to adopter outputs (architecture doc, ADRs, READMEs, mockup). D22 promotes the rule from **aspirational → binding**, gives every cardinal role a concise authoring protocol, and wires **discovery-driven enforcement** so adopter docs are linted with the adopter's existing tooling.

| Layer | What it does | Where it lives |
|---|---|---|
| Authoring guide | Default-shape map + 6 paired examples + mandatory checks. Humans + LLMs read this when authoring adopter docs. | `core/doc-authoring-protocol.md` |
| Per-role hook | One Source-of-truth line per cardinal role pointing at the protocol. | `core/roles/*.md` (7 files) |
| Process declaration | Binding line + cross-link in `§ Documentation style`. | `core/process.md` |
| Attestation | One-line Verification-log entry in phase report + PR description. | `core/templates/phase-report.md`, `core/templates/pr-description.md` |
| Discovery | `team-lead` runs the existing `builtin:commands` + `builtin:conventions` recipes, which now recognise markdown / prose linters. | `core/roles/ai-engineer.details.md § Recipes` |
| Enforcement | Each role runs `${commands.lint.docs}` at Phase 5 / report-as-done. Output appears in the phase report. | Discovered command in `local/index/commands.yaml` |

## No custom lint

Earlier drafts proposed a custom `ginee-doc-style-lint` skill. **Dropped** — adopter projects already configure markdownlint / vale / prettier / proselint; shipping a parallel lint duplicates them, costs context (load-bearing logic in every dispatch), and ignores the discovered stack. The protocol document carries the rules; enforcement piggybacks on the adopter's tooling.

If no linter is discovered, `team-lead` recommends one in the discovery report. Adopter decides — never auto-install.

## Cross-issue ordering

| Issue | State | Coupling |
|---|---|---|
| [#37](https://github.com/kostiantyn-matsebora/ginee/issues/37) (classical SA Review activity) | open | When #37 lands, the SA Review activity gains doc-style compliance as a hard-reject criterion. D22 includes a TODO marker; no behaviour change at #39's merge time. |
| [#38](https://github.com/kostiantyn-matsebora/ginee/issues/38) (framework-self-dev gate) | shipped in 0.4.0 | Distinct concern. D22 governs adopter outputs; D21 governs `core/` / `adapters/` / `extras/`. The two never overlap. |

## Activation

Automatic on update. Roles fetch `core/doc-authoring-protocol.md` on-demand when authoring markdown. Discovery picks up adopter lint configs on next `rediscover`.

## Out of scope

- **Mass-restructure of legacy adopter docs.** Forward-only — new + edited content follows the protocol.
- **Style / tone / branding rules.** Protocol governs **structure**. Adopter style guides own the rest.
- **Custom ginee lint.** Permanently rejected — see § No custom lint.
