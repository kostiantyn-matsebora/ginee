# ginee — Project Instructions

## HARD CONSTRAINTS (always)

1. **Self-lint marker** — every cardinal return ends with `<!-- self-lint: pass -->`. No exceptions.
2. **SA never edits** — `solution-architect` returns APPROVE / REJECT / REQUEST-CHANGES only; never `Edit` / `Write` (subagent `tools:` whitelist enforces).
3. **Context-economy trailer** — any commit > ~50 net-added lines on `core/` · `adapters/` · `extras/` carries `Optimized-By: ai-engineer`.
4. **Runtime stays D-free** — `core/**` · `adapters/**` · `extras/**` · migration filenames carry no `D<N>` tokens. `PLAN.md` is the sole D-log.
5. **`local/**` only via discovery** — never edit from main thread; route to the discovery skill.

## What this is

`ginee` — vendor-neutral OSS framework for any LLM coding tool. Ships process knowledge only; project-specific knowledge lives in `local/`.

- **Model.** 7-cardinal multi-agent collaboration + generic engineering process
- **Adapter targets.** Claude Code · Copilot · Cursor · Codex · generic fallback
- **Repo scope.** Framework's own dev repo, not an adopter project

## Where things live (load on demand)

| Path | What's there | When to load |
|---|---|---|
| `core/process.md` + `core/process/phase-*.md` | Vendor-neutral lifecycle spec | Orchestration / phase-bound dispatch |
| `core/roles/*.md` | 7 cardinal role charters | Per-cardinal dispatch (adapter loads matching `phase-participation:`) |
| `core/protocols/*.md` | Named workflow specs (automatic-mode · delivery-modes · ci-watch · triage-scoring · github-integration · doc-roles · doc-authoring-* · changelog · cross-domain-bugs · index-* · iteration · options · blueprint-diff · doc-size-caps · hot-spec-format · output-schema sidecars) | When the named workflow triggers |
| `core/templates/*.md` | Phase report · hand-off · pr-description · bindings · framework.config.yaml · issues | When authoring that artefact |
| `core/skills/ginee-*/SKILL.md` | Per-skill invocation surface | Per skill invocation |
| `adapters/<client>/` | Per-client renderings of `core/` | Per active adapter |
| `extras/roles/*.md` | Specialist roles (security · ml · mobile · sre · data) — opt-in | Adopter opts in |
| `local/` | Adopter-owned; empty for this framework repo | When working in an adopter project |
| `PLAN.md` | Owner's design log — D1–D49 + rationale + roadmap | Tracing why a D-decision was made (on demand only, NOT a routine read) |
| `migrations/<slug>.md` | Per-cutover adopter switching instructions | Authoring a migration; `/ginee-update` fetches |
| `docs/RELEASE.md` | Release checklist (version bump procedure) | Before bumping `core/VERSION` |
| `README.md` | Install + adopter-facing overview | Onboarding |

## Hard constraints

- All work confined to this framework repo — do not modify external projects.
- `core/` · `adapters/` · `extras/` are upstream-owned; `local/` is adopter-owned (survives updates).
- Lossless rule — restructure passes MUST preserve every rule / invariant (`core/roles/ai-engineer.md`).
- Follow `core/process.md § Documentation style` + § Framework authoring (below) for all new docs.
- Scripts (`*.ps1` · `*.sh`) MUST lint + pass tests on every change — merge gate, no waiver.
  - PowerShell — PSScriptAnalyzer + Pester at `tests/<name>.Tests.ps1`
  - bash — shellcheck + bats-core at `tests/<name>.bats` (WSL only on Windows)
- GitHub issue pickup — before Phase 2 ALWAYS fetch BOTH:
  - Comments — `gh issue view <N> --comments` (reporters pin scope clarifications)
  - Sub-issues — `gh api repos/<owner>/<repo>/issues/<N>/sub_issues` (carry scope expansions)
- User-docs co-update (binding) — every adopter-facing change updates `docs/` (`CONCEPTS.md` · `GETTING_STARTED.md` · `CHEATSHEET.md` · `index.md`) in the same PR. Internal-only changes (context-economy gate · CI internals · script-quality · backend-coverage) exempt.
- D-IDs are owner's private log — runtime surface (`core/**` · `adapters/_shared/**` · `adapters/<X>/install.md` · `extras/**` · `core/templates/issues/**`) MUST stay D-free. Cite rules by location (`core/process.md § <section>`), not by D-number. New owner decisions log to `PLAN.md` only. Migration filenames carry no `D<N>-` prefix.

## Framework authoring — context economy

Every framework file (`core/` · `adapters/` · `extras/`) loads into model context on every adopter task. Aggregate weight is the dominant adopter cost; treat token weight as first-class on par with correctness.

- **Concise + LLM-optimized.** Cut filler, marketing tone, "in this section we will explore" preambles. Every sentence earns its tokens.
- **Structure over prose — binding here, not aspirational.** Convert prose into the smallest readable structure that preserves every rule:
  - Steps → numbered list. Choices / mappings → table. "X means Y" → `**X.** Y` on its own line.
  - Multi-rule bullet ("do A; also B; warn C") → parent + sub-bullets, one rule per line.
  - Prose paragraph stating > 2 rules → restructure.
- **Dispatch `ai-engineer` to optimize** when a framework file grows materially OR a structural change touches > 1 file. Hard threshold: any change above ~50 net-added lines triggers an optimization pass under the lossless rule.
- **Adapter binding.** Every new rule in `core/` classifies enforcement per adapter — Claude: hook · slash command · subagent `tools:` whitelist · always-loaded text. Default soft-force (always-loaded); upgrade to hard-force when the rule has a verifiable signal. Per-adapter mapping: playbook [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135). Sister playbooks for Cursor / Copilot / Codex / generic file as their tooling matures.
- **Gate.** Three layers enforce threshold + structural-lint on this repo's PRs:
  - Claude Code PostToolUse hook — `.claude/settings.json.example` (copy → `.claude/settings.json`)
  - Git pre-commit / pre-push — `hooks/`, installed via `scripts/install-hooks.{ps1,sh}`
  - CI workflow — `.github/workflows/context-economy.yml`
  - Marker: git trailer `Optimized-By: ai-engineer` on any commit in PR range
  - Waiver: PR label `context-economy:waived` + `**Context economy waiver:** <reason>` in PR body
  - Spec: `scripts/context-economy-check.ps1`

## Out of scope

- MCP server (deferred to v2.0).
- Auto-update CLI that modifies adopter projects without explicit user invocation.
- Per-domain templates (architecture / API / mockup contracts) — adopters bring their own.
- Multi-organization / multi-repo aggregation — single-repo at a time.

## HARD CONSTRAINTS — RECAP

1. **Self-lint marker** — every cardinal return ends with `<!-- self-lint: pass -->`. No exceptions.
2. **SA never edits** — `solution-architect` returns APPROVE / REJECT / REQUEST-CHANGES only; never `Edit` / `Write` (subagent `tools:` whitelist enforces).
3. **Context-economy trailer** — any commit > ~50 net-added lines on `core/` · `adapters/` · `extras/` carries `Optimized-By: ai-engineer`.
4. **Runtime stays D-free** — `core/**` · `adapters/**` · `extras/**` · migration filenames carry no `D<N>` tokens. `PLAN.md` is the sole D-log.
5. **`local/**` only via discovery** — never edit from main thread; route to the discovery skill.
