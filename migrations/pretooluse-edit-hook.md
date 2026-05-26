# Migration — PreToolUse hook on Edit / Write / MultiEdit

**Target release:** next minor after 2026-05-26.
**Affected adopters:** Claude Code adapter only.
**Closes:** [#138](https://github.com/kostiantyn-matsebora/ginee/issues/138).
**Parent:** [#135](https://github.com/kostiantyn-matsebora/ginee/issues/135) — tactic 2 / Tier 1, Class A force.
**Prior:** [`migrations/cardinal-tools-whitelist.md`](cardinal-tools-whitelist.md) (#137, T1 — binary tool gate).

## What changed

A new cross-platform PreToolUse hook lives at:

- `adapters/claude/hooks/pre-tool-use-edit.ps1` — PowerShell (primary; cross-platform via pwsh 7+).
- `adapters/claude/hooks/pre-tool-use-edit.sh` — bash port (jq-dependent fallback for adopters without pwsh).

When `.claude/settings.json` wires this hook into `hooks.PreToolUse` (matcher `Edit|Write|MultiEdit`), Claude Code invokes it before each edit. The hook reads Claude's JSON payload from stdin, composes the proposed post-edit content, and exits 2 + stderr message when any of five violation classes fire:

| # | Violation | Source rule |
|---|---|---|
| 1 | Hot-spec edit lacking frontmatter post-edit | `core/protocols/hot-spec-format.md` (D47) |
| 2 | File size > `cap-bytes` without `Optimized-By: ai-engineer` trailer queued on branch | `core/protocols/doc-size-caps.md` (D44) + frontmatter (D47) |
| 3 | Edit on `core/**` introducing a bare `D<N>` token | runtime D-free invariant (D42) |
| 4 | Added content using `always` / `never` / `binding` / `mandatory` as a rule modifier | RFC 2119 keyword convention (D48) |
| 5 | Always-loaded surface (`load: always`) line-count bloat (> 50 lines) without trailer | context-economy gate (D21) |

The matching set of hot-spec paths and always-loaded files is detected from frontmatter, not hard-coded — so adopter custom roles authoring hot-spec-style files participate automatically.

## Why

Parent issue #135 § Force taxonomy — Class H (always-loaded charter text) was the main lever ginee shipped for protocol compliance. Under task pressure the LLM voluntary-compliance budget drains; recent-prompt content beats charter rules in attention. T2 promotes 5 specific rules — each documented in always-loaded specs today — to **Class A** (action-time gate, exit 2 blocks the tool call). These five are the most-violated charter rules in the playbook's audit window: hot-spec frontmatter omitted; oversized always-loaded files committed without optimization; bare D-tokens re-introduced after the D42 cleanup; voluntarist modifiers slipped past the D48 RFC 2119 switch; always-loaded surface bloat shipped without the `Optimized-By` trailer.

Pairs with T1 (#137) — T1 removes whole tools from a role's whitelist (binary Class A); T2 fills in the path-conditional and content-conditional rules that `tools:` cannot express.

## Architecture

| Surface | Owns |
|---|---|
| Hook script (`pre-tool-use-edit.{ps1,sh}`) | Reads payload · resolves repo root · checks per-tactic opt-out · classifies path · composes proposed content · runs 5 violation checks · exits 2 with stderr on first hit. Pure function over the payload + repo state — no side effects on the working tree. |
| `.claude/settings.json` (adopter-owned) | Maps the `Edit|Write|MultiEdit` matcher to the hook command. Adopter authors / updates this; framework provides a `.claude/settings.json.example` template + `adapters/claude/install.md § Compliance hooks` instructions. |
| `local/framework.config.yaml § compliance.disabled` (adopter-owned) | Per-tactic opt-out. Listing `pretooluse-edit-hook` in `compliance.disabled` makes the hook exit 0 regardless of payload content. |

The hook is **stateless beyond a `git log` read** (used by violations 2 + 5 to detect the `Optimized-By: ai-engineer` trailer on commits in the current PR range). No external service, no MCP server, no daemon.

## Detection details (per-violation rationale)

**1. Hot-spec frontmatter.** Hot-spec paths — `core/process.md`, `core/process/*.md`, `core/protocols/*.md`, `core/roles/*.md`, `core/roles/*.details.md` — must carry the 5-key YAML block at file head per the D47 schema. The hook composes post-edit content from the payload + on-disk state and checks the leading `---\n...\n---\n` block exists. Edits that strip the block, or new files at a hot-spec path without one, are blocked.

**2. cap-bytes + trailer.** Frontmatter declares `cap-bytes:` per-file; post-edit UTF-8 byte count is compared. If exceeded, the hook scans `git log origin/main..HEAD` for `Optimized-By: ai-engineer`; absent → block. This mirrors the existing CI gate in `scripts/context-economy-check.ps1` but fires at edit-time instead of PR-time, so the violation surfaces before the commit.

**3. D-token introduction on core/**.** Pattern `(?<![\w-])D\d{1,3}(?![\w-])` — bare D-IDs, word-bounded. The hook computes `new − old` tokens (only newly-introduced are blocked; legacy D-references already present in the file survive). Targets the D42 invariant that the runtime surface stays D-free; D-IDs live in `PLAN.md` only.

**4. RFC 2119 modifier on added content.** Pattern `\b(always|never|binding|mandatory)\b` applied to the added-line set (or full content for new files), case-insensitive. Frontmatter is stripped first so `load: always` in YAML doesn't false-trigger. Targets the D48 switch from voluntarist English modifiers to RFC 2119 keywords (MUST / MUST NOT / SHOULD / SHALL).

**5. Always-loaded bloat.** Files with `load: always` in frontmatter get a line-delta check between pre- and post-edit. Delta > 50 lines without an `Optimized-By: ai-engineer` trailer on the branch → block. Sets the action-time floor below the existing PR-time threshold so the LLM gets feedback before composing the commit.

## Opt-out + bypass

**Per-tactic, repo-wide** — adopter edits `local/framework.config.yaml`:

```yaml
compliance:
  disabled:
    - pretooluse-edit-hook
```

The hook reads this file each invocation; listing the tactic exits 0 immediately. Opt-out is per-tactic — disabling T2 does not affect T1 / T3 / T4 / etc.

**Per-invocation, emergency-only** — set `SKIP_GINEE_COMPLIANCE=1` in the environment. Surfaces in stderr remediation messages so adopters can apply it intentionally; not for routine bypass.

## Verification

| Step | Expected |
|---|---|
| Pester — `tests/pre-tool-use-edit.Tests.ps1` | 12 / 12 pass: parse-clean · 4 pass-through · 2 frontmatter · 1 D-token · 1 RFC 2119 · 2 opt-out · 1 env-bypass |
| bats — `tests/pre-tool-use-edit.bats` | 11 / 11 pass: equivalent surface against the `.sh` port |
| PSScriptAnalyzer — `Invoke-ScriptAnalyzer adapters/claude/hooks/pre-tool-use-edit.ps1 -Settings ./PSScriptAnalyzerSettings.psd1` | clean |
| shellcheck — `shellcheck adapters/claude/hooks/pre-tool-use-edit.sh` | clean (per repo's existing shell-quality gate) |
| Manual smoke — `echo '{"tool_name":"Write","tool_input":{"file_path":"core/process.md","content":"no frontmatter"}}' \| pwsh -F adapters/claude/hooks/pre-tool-use-edit.ps1` | exit 2 + `[ginee:gate] hot-spec frontmatter required (D47)` on stderr |

## Decisions affected

- **#135 parent playbook** — second tactic shipped. Establishes the cross-platform `.ps1 + .sh` parity pattern for adapter-side hooks reused by T3 / future tactics.
- **`core/protocols/hot-spec-format.md` (D47)** — post-edit frontmatter requirement promoted from Class H (always-loaded) to Class A (action-time).
- **`core/protocols/doc-size-caps.md` (D44)** — cap-bytes enforcement now fires at edit-time, not only on CI. Adopters get faster feedback; the CI gate stays as the authoritative final check.
- **`core/protocols/rfc2119-keywords.md` (D48)** — voluntarist modifier ban promoted to Class A on added content.
- **`migrations/cardinal-tools-whitelist.md` (T1)** — establishes the binary tool gate; T2 fills in the path-conditional rules `tools:` cannot express.

## Forward-only

Purely additive — adds 2 hook scripts under `adapters/claude/hooks/`, 2 test files under `tests/`, one `PreToolUse` entry in `.claude/settings.json.example`, an install.md section. Adopters who already customise `.claude/settings.json` add the hook block manually per the install.md template; auto-merge into custom adopter settings is a follow-up (tracked separately).

## Out of scope

- **Auto-merge into adopter `.claude/settings.json`.** Today's installer copies the `.example` only when no settings.json exists; adopters with customisations follow the manual snippet in `adapters/claude/install.md § Compliance hooks`. Idempotent JSON-merge in `install.ps1` / `install.sh` is a follow-up.
- **Per-violation opt-out.** All five violations share the single tactic-id `pretooluse-edit-hook`. Splitting (e.g., disable D-token check only) is deferred; the typical scenario is "all or nothing" while the LLM gets accustomed to the gate.
- **Cross-adapter parity.** Cursor / Codex / generic adapters have no PreToolUse hook surface; the equivalent enforcement there is the existing CI gate at PR-time. Cross-adapter playbooks ship as their tooling matures.
- **Bash hook without `jq`.** Fails open (warning to stderr) when `jq` is absent on PATH. Adopters who rely on the bash hook should install jq; the pwsh hook avoids this dependency entirely.
