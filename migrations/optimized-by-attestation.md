# Migration — Optimized-By trailer attestation gate (push-time)

**Target release:** next minor after 2026-05-27.
**Affected adopters:** Claude Code adapter (framework-self-dev + adopter projects).
**Closes:** (T13 — sister tactic to playbook #135; sub-issue TBD).
**Parent:** [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135) — tactic 13 / Tier 3 follow-up, Class A *consent-required gate* (new force axis).

## What changed

A new cross-platform PreToolUse hook gates the `Optimized-By: ai-engineer` trailer claim at **push time**, not commit time:

- `adapters/claude/hooks/attest-optimized-by.ps1` — PowerShell (primary).
- `adapters/claude/hooks/attest-optimized-by.sh` — bash port (jq-dependent).

When the LLM issues `git push`, the hook scans the to-be-pushed range (`<upstream>..HEAD`, falling back to `origin/main..HEAD` / `origin/master..HEAD` when no upstream is configured) for **any** commit whose body carries `Optimized-By: ai-engineer`. If found AND the session transcript does NOT contain an `Agent(subagent_type=ai-engineer)` dispatch, the hook emits `hookSpecificOutput.permissionDecision: "ask"` with reason `"[ginee:attest] Push range <range> contains a commit with Optimized-By: ai-engineer trailer, but no Agent(subagent_type=ai-engineer) dispatch found in this session's transcript. Proceed anyway (cross-session optimization · manual lossless pass · WIP push) or cancel + run the ai-engineer optimization pass first?"`.

The user picks **allow** (cross-session work, manual lossless pass, judgment call) or **deny** (cancel + dispatch ai-engineer first).

## Why push-time, not commit-time

Adopter (and framework-self-dev) workflow:

1. User / agents make incremental WIP commits — no trailer yet.
2. Before push, ai-engineer is dispatched for an optimization pass.
3. ai-engineer proposes lossless restructuring; user accepts / rejects.
4. The optimization commit lands carrying `Optimized-By: ai-engineer`.
5. Push covers the whole range.

Gating at *commit* time would either fire on every WIP commit (false positive) or require the LLM to pre-decide which commit carries the trailer. Gating at *push* time matches the natural workflow: the trailer's claim covers the entire range; attestation runs against the range; dispatch evidence is in the same session's transcript at the time of push.

This also generalises across surfaces — framework-self-dev pushes contain commits touching `core/**` · `adapters/**` · `extras/**`; adopter pushes contain commits touching docs / prompts / `local/` content. The hook is **path-agnostic** — the trailer's presence in any commit in the range is the sole signal. No per-adapter path-filter configuration required.

The context-economy gate (`scripts/context-economy-check.ps1`) already enforces the path-bounded threshold rule at PR-range level; T13 sits upstream of that gate, attesting that the trailer claim corresponds to an actual cardinal dispatch.

## Why ask-mode, not hard-block

Attestation is *judgment-bearing*, not guard-rail. Legitimate cases — dispatch happened in a prior session, dispatch happened externally, push is WIP and the trailer landed on a draft — all map naturally to "user picks allow." Hard-block (exit 2) would force the user to either re-dispatch ai-engineer (sometimes unnecessary) or invoke `SKIP_GINEE_COMPLIANCE=1` (defeats the gate's purpose).

Ask-mode introduces a **new force-class axis**: existing Class A is binary gate (allow / deny by rule). Ask-mode is *consent-required gate* — the gate prompts; the user supplies the decision. Generalises beyond T13 to any attestation-shaped rule.

## Architecture

| Surface | Owns |
|---|---|
| Hook script (`attest-optimized-by.{ps1,sh}`) | Read payload · self-filter on `git push` · resolve range (`<upstream>..HEAD` or `origin/main..HEAD` fallback) · scan range bodies for `Optimized-By: ai-engineer` · scan transcript for `Agent(subagent_type=ai-engineer)` dispatch · emit `permissionDecision: "ask"` when claim unverified |
| `.claude/settings.json § hooks.PreToolUse` (matcher: `Bash`) | Wires the hook alongside T3 `pre-tool-use-bash.ps1`. Synced by `core/scripts/sync-claude-settings.{ps1,sh}` |
| `local/framework.config.yaml § compliance.disabled: [optimized-by-attestation]` | Per-tactic opt-out |

Self-filter chain (each step short-circuits to `exit 0`):

1. Empty / malformed payload → pass.
2. `tool_name != "Bash"` → pass.
3. `tool_input.command` doesn't match `\bgit\s+push\b` → pass.
4. Repo root unresolved → pass.
5. `compliance.disabled` lists `optimized-by-attestation` → pass.
6. Range unresolvable (no upstream, no `origin/main`, no `origin/master`) → pass.
7. Range bodies don't contain `Optimized-By: ai-engineer` → pass.
8. Transcript contains `"subagent_type":"ai-engineer"` → pass.

Only when **all** eight pre-conditions hold does the hook emit `permissionDecision: "ask"`. No false positives on routine pushes; no false negatives on the trailer-claim loophole.

## Verification

| Step | Expected |
|---|---|
| Pester — `tests/attest-optimized-by.Tests.ps1` | 13 / 13 pass — parse-clean · 4 pass-through (non-Bash · non-git-push · no trailer · trailer + dispatch) · 3 ask-mode (basic · trailer not at tip · push variants) · 2 opt-out (env + framework.config.yaml) · 3 fail-open (empty · malformed · empty range) |
| bats — `tests/attest-optimized-by.bats` | 11 / 11 pass — equivalent surface |
| PSScriptAnalyzer — `Invoke-ScriptAnalyzer adapters/claude/hooks/attest-optimized-by.ps1` | clean |
| shellcheck — `shellcheck adapters/claude/hooks/attest-optimized-by.sh` | clean (deferred to CI) |
| Manual smoke — make a commit with Optimized-By trailer, then `pwsh -F adapters/claude/hooks/attest-optimized-by.ps1` with no ai-engineer dispatch in transcript | stdout JSON contains `"permissionDecision":"ask"` |

## Decisions affected

- **Parent playbook #135** — extends with a thirteenth tactic + new force-class axis (*consent-required gate*).
- **Context-economy gate (`scripts/context-economy-check.ps1`)** — unchanged at gate level; T13 closes the *attestation* loophole upstream of the gate (at push time, before the trailer reaches the gate's PR-range scan).
- **`CLAUDE.md § Framework authoring — context economy`** — unchanged in rule text; T13 makes the rule's *"Dispatch ai-engineer to optimize"* directive externally verifiable, where previously it was voluntary-compliance.
- **`adapters/claude/install.md § Compliance hooks + statusline`** — gains T13 row + reference link.

## Forward-only

Purely additive — adds 2 files under `adapters/claude/hooks/` + 2 tests + a new PreToolUse entry in `.claude/settings.json` (auto-merged via `core/scripts/sync-claude-settings.{ps1,sh}`). Adopters who run `/ginee-update` get the hook automatically. Per-tactic opt-out via `local/framework.config.yaml § compliance.disabled: [optimized-by-attestation]`.

## Out of scope

- **Hard-block (exit 2) variant.** Considered; rejected — attestation is judgment-bearing. Ask-mode is the right force class.
- **Commit-time gate.** Considered; rejected — would false-positive on WIP commits or require pre-deciding which commit carries the trailer. Push-time matches the natural workflow.
- **Path-bounded filter on the staged diff.** Considered; rejected — the trailer's presence in the range is sufficient signal. The context-economy gate already enforces the path-bounded threshold separately.
- **Cross-session dispatch detection** via persistent state file. Considered; deferred — would require a registry the framework doesn't keep on disk. Ask-mode handles the cross-session case naturally (user picks allow with awareness).
- **Verification of dispatch *outcome*** — the hook only checks dispatch happened, not whether the dispatch returned an optimization. Returns are visible to the user in the transcript; over-claim is detectable on review.
- **Cross-adapter parity.** T13 ships on the Claude adapter only. Cursor / Copilot / Codex / generic playbooks gain attestation gates when their tooling matures to support the equivalent of `permissionDecision: "ask"`.
