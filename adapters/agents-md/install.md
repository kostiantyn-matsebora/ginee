# AGENTS.md adapter — install

## Prerequisites

- `.agents/ginee/` directory present at the project root.

## Steps

1. **Copy `AGENTS.md` to the project root.**

   ```powershell
   Copy-Item .agents\ginee\adapters\agents-md\AGENTS.md .\AGENTS.md
   ```

   ```bash
   cp .agents/ginee/adapters/agents-md/AGENTS.md ./AGENTS.md
   ```

   If a project-root `AGENTS.md` already exists:
   - Merge (don't overwrite).
   - Append the ginee section to existing project-specific rules.

2. **(Gemini users only)** Copy the same content to `GEMINI.md`:

   ```bash
   cp AGENTS.md GEMINI.md
   ```

3. **Bridge the framework skills** to your client's skill-discovery path. Source: `.agents/ginee/core/skills/ginee-*/`. Each is a directory containing `SKILL.md` per the [AgentSkills standard](https://agentskills.io).

   | Client | Destination |
   |---|---|
   | Cursor | `.cursor/skills/` |
   | OpenAI Codex | `~/.codex/skills/` or per-project (see [Codex skills docs](https://developers.openai.com/codex/skills/)) |
   | Gemini CLI | per the [Gemini CLI skills docs](https://geminicli.com/docs/cli/skills/) |
   | Goose | `~/.config/goose/skills/` (per its docs) |
   | Other AgentSkills clients | per the client's docs |

   ```bash
   # Example — Cursor
   mkdir -p .cursor/skills
   cp -r .agents/ginee/core/skills/ginee-* .cursor/skills/
   ```

   Symlinks (POSIX) are preferred over copies — auto-pick up framework updates.

4. **Run discovery.**
   - Open the project in your client (Cursor / Codex / Gemini CLI / etc.).
   - Ask the client to run initial discovery — natural language matches the `ginee-discovery` skill, or the orchestrator routes to `team-lead` via subagent description match. Example phrasings:

     ```
     Run initial discovery.
     ```
     ```
     @team-lead run initial discovery     (Cursor: @ is literal)
     ```
     ```
     act as team-lead and run initial discovery     (clients without @-routing)
     ```

5. **Verify** — ask the client to report status of each cardinal. Each should:
   - Load its charter from `.agents/ginee/core/roles/<role>.md`.
   - Confirm project bindings.

## How to invoke

`@<role>` notation in framework docs is vendor-neutral shorthand. Per-client reality:

| Client | Invocation |
|---|---|
| Cursor | `@<agent>` is literal in chat. |
| OpenAI Codex | natural-language to the orchestrator (`AGENTS.md` routing). |
| Gemini CLI | natural-language; skills auto-activate on description match. |
| Generic AGENTS.md client | natural-language (`act as <role> and ...`). |

Framework workflows (file / pick-up / triage / promote / discovery / reindex) activate via AgentSkills description match. Cheat sheet:

| Phrasing | Activates |
|---|---|
| "Run initial discovery" | `ginee-discovery` |
| "Rediscover the project" | `ginee-rediscover` |
| "File a bug titled X" | `ginee-file-bug` |
| "File a feature request titled X" | `ginee-file-feature` |
| "File a framework bug titled X" | `ginee-file-framework-bug` |
| "File a framework feature titled X" | `ginee-file-framework-feature` |
| "Pick up #N" / "Work on the TODO about X" / "Start on Y" | `ginee-pick-up` (unified — issues, TODO lines, freeform) |
| "Triage" / "List ready work" / "Show the backlog" | `ginee-triage` (unified — issues + framework + TODOs) |
| "Promote discussion #N" | `ginee-promote-discussion` |
| "Reindex" / "Reindex `<file>`" / "Reindex `<class>`" / "Reconcile the index" | `ginee-reindex` |
| "Update ginee" / "Upgrade the framework" / "Bump ginee to `v<X>`" / "Pull the latest ginee" | `ginee-update` |
| "Address review on PR #N" / "Respond to review on #N" / "Handle review feedback on #N" | `ginee-address-review` |

## Model tier (D31)

The AGENTS.md surface does **not** expose programmatic per-role model selection — Cursor / Codex / Gemini CLI / Goose / etc. each pick model via their own UI / config. ginee writes vendor-neutral tier names in `local/framework.config.yaml § model-tier` but the runtime ignores them on this adapter.

**Per-task prefix (user-side hint).** Prefix any dispatch with `model:<tier>` (`reasoning` / `standard` / `fast`) — a documented signal you can pair with manual model selection in your client.

```
model:reasoning Add the new ASR utility-tree leaves for the latency NFR.
```

For clients layered on top of this adapter (Claude Code · Copilot CLI), the layered adapter's own programmatic wiring applies; this baseline adapter stays a no-op.

When AGENTS.md gains a per-role / per-task model field, this adapter's install step will wire it. Spec: `core/MIGRATIONS/D31-model-tier.md`.

## Phase-file loading (D35)

Per D35-process-md-load-topology, the 8 lifecycle phases + orchestration content live under `core/process/` and load per-cardinal via `phase-participation:` frontmatter.

| Step | Behaviour |
|---|---|
| Read each rendered `AGENTS.md` role section's frontmatter | Lift `phase-participation: [N, M, …]` |
| For each `N` in the list | Cite `.agents/ginee/core/process/phase-<N>-<name>.md` in that role's load section |
| `team-lead` only (and skill-runner main thread on `ginee-*` skill entry) | Additionally cite `.agents/ginee/core/process/dispatch.md` |
| Cardinals with empty list (`ai-engineer`) | Load no phase files; common `.agents/ginee/core/process.md` only |

The AGENTS.md render is responsible for surfacing the correct phase-file references per role; non-participating phase files are not surfaced to that role. Full spec: `core/MIGRATIONS/D35-process-md-load-topology.md`.

## Updates

**Recommended — `/ginee-update`** (or "update ginee" / "upgrade the framework"). The skill fetches the installer from upstream at the target ref and drives `--update-only` for you — no local installer needed (D27). Automates steps 1–2. **Warning** — the installer copies `AGENTS.md` wholesale; back up first if you merged project-specific content into it.

**Manual fallback — bootstrap one-liner** (the installer is intentionally NOT inside `.agents/ginee/` per D27):

```powershell
$env:GINEE_UPDATE_ONLY='1'; $env:GINEE_ADAPTER='agents-md'; iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.ps1 | iex
```

```bash
GINEE_UPDATE_ONLY=1 GINEE_ADAPTER=agents-md bash -c "$(curl -fsSL https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh)"
```

**Step-by-step equivalent:**

1. Re-fetch `.agents/ginee/core/` + `.agents/ginee/adapters/` + `.agents/ginee/extras/` (your `local/` survives).
2. Re-copy `.agents/ginee/adapters/agents-md/AGENTS.md` to project root (merge if project-specific content was added).
3. Re-copy `.agents/ginee/core/skills/ginee-*` to your client's skill directory (skill bodies / descriptions may have been refined). Skip if you used symlinks.
4. Read `.agents/ginee/core/MIGRATIONS/` for breaking-change notes.
5. **For pre-D11 (pre-2026-05-18) upgrades** — run the rename migration script once:
   - `.\.agents\ginee\core\scripts\migrate-engineering-team-to-ginee.ps1` (or `.sh`).
   - Rewrites legacy `engineering-team` references under `local/*`. Idempotent.
   - Full notes: `.agents/ginee/core/MIGRATIONS/engineering-team-renamed-ginee.md`.

## Uninstall

1. Remove the ginee section from `AGENTS.md` (or delete the file if framework-only).
2. (Gemini) Same for `GEMINI.md`.
3. Delete `ginee-*` skill directories from your client's skill path.
4. Optionally delete `.agents/ginee/`.

## Cross-tool layering

Baseline adapter for all AGENTS.md-supporting clients.

For clients with native subagent support, layer the dedicated adapter on top:

| Client | Layer also |
|---|---|
| Claude Code | `.agents/ginee/adapters/claude/` |
| Copilot CLI | `.agents/ginee/adapters/copilot-cli/` |

Layered installs do not conflict:
- AGENTS.md provides cross-tool context.
- The per-client adapter provides native subagent routing.
