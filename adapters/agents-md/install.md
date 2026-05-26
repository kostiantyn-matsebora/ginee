# AGENTS.md adapter — install

Cross-tool baseline for any client honouring `AGENTS.md` (Cursor · OpenAI Codex · Gemini CLI · Goose · etc.). Layer the per-client adapter (`claude` · `copilot-cli`) on top when one exists.

Shared sections (skill cheat sheet · phase-file loading · model tier · updates): `adapters/_shared/install-common.md`.

## Prerequisites

- `.agents/ginee/` present at the project root.

## Steps

1. **Copy `AGENTS.md` to the project root.**

   ```powershell
   Copy-Item .agents\ginee\adapters\agents-md\AGENTS.md .\AGENTS.md
   ```

   ```bash
   cp .agents/ginee/adapters/agents-md/AGENTS.md ./AGENTS.md
   ```

   Existing project-root `AGENTS.md` → merge (don't overwrite); append the ginee section.

2. **(Gemini users only)** mirror to `GEMINI.md`:

   ```bash
   cp AGENTS.md GEMINI.md
   ```

3. **Bridge framework skills** to your client's skill-discovery path. Source: `.agents/ginee/core/skills/ginee-*/` (per [AgentSkills](https://agentskills.io)).

   | Client | Destination |
   |---|---|
   | Cursor | `.cursor/skills/` |
   | OpenAI Codex | `~/.codex/skills/` or per-project ([Codex skills docs](https://developers.openai.com/codex/skills/)) |
   | Gemini CLI | per [Gemini CLI skills docs](https://geminicli.com/docs/cli/skills/) |
   | Goose | `~/.config/goose/skills/` |
   | Other AgentSkills clients | per the client's docs |

   ```bash
   mkdir -p .cursor/skills
   cp -r .agents/ginee/core/skills/ginee-* .cursor/skills/
   ```

   POSIX symlinks preferred over copies — auto-pick up framework updates.

4. **Run discovery.** Open the project in your client. Prompt: `Run initial discovery.` (or `@team-lead run initial discovery` on Cursor; `act as team-lead and run initial discovery` on clients without `@`-routing).

5. **Verify.** Ask the client to report each cardinal's status — each should load its charter from `.agents/ginee/core/roles/<role>.md` + confirm project bindings.

## How to invoke

`@<role>` is vendor-neutral shorthand. Per-client reality:

| Client | Invocation |
|---|---|
| Cursor | `@<agent>` literal in chat. |
| OpenAI Codex | Natural-language to the orchestrator (`AGENTS.md` routing). |
| Gemini CLI | Natural-language; skills auto-activate on description match. |
| Generic AGENTS.md client | Natural-language (`act as <role> and ...`). |

Skill cheat sheet: `adapters/_shared/install-common.md § Skill cheat sheet`.

## Model tier

Per `adapters/_shared/install-common.md § Model tier` — this baseline adapter has no programmatic per-role selection. Layered adapters (Claude Code · Copilot CLI) override.

## Phase-file loading

Per `adapters/_shared/install-common.md § Phase-file loading`. The AGENTS.md render surfaces correct phase-file references per role section.

## Updates

Per `adapters/_shared/install-common.md § Updates`. **Warning** — the installer copies `AGENTS.md` wholesale; back up first if you merged project-specific content into it.

## Uninstall

1. Remove the ginee section from `AGENTS.md` (or delete the file if framework-only).
2. (Gemini) Same for `GEMINI.md`.
3. Delete `ginee-*` skill directories from your client's skill path.
4. Optionally delete `.agents/ginee/`.

## Cross-tool layering

Layered installs do not conflict — AGENTS.md provides cross-tool context; the per-client adapter provides native subagent routing:

| Client | Layer also |
|---|---|
| Claude Code | `adapters/claude/` |
| Copilot CLI | `adapters/copilot-cli/` |
