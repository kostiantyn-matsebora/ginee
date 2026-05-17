# AGENTS.md adapter — install

## Prerequisites

- `.agents/engineering-team/` directory present at the project root.

## Steps

1. **Copy `AGENTS.md` to the project root.**

   ```powershell
   Copy-Item .agents\engineering-team\adapters\agents-md\AGENTS.md .\AGENTS.md
   ```

   ```bash
   cp .agents/engineering-team/adapters/agents-md/AGENTS.md ./AGENTS.md
   ```

   If a project-root `AGENTS.md` already exists — merge (don't overwrite); append the engineering-team section to existing project-specific rules.

2. **(Gemini users only)** Copy the same content to `GEMINI.md`:

   ```bash
   cp AGENTS.md GEMINI.md
   ```

3. **Run discovery** — open the project in your client (Cursor / Codex / Windsurf / Copilot IDE / etc.) and prompt:

   ```
   @project-manager run initial discovery
   ```

   Clients without `@mention` routing — prompt `act as project-manager and run initial discovery`.

4. **Verify** — prompt `@solution-architect status` (or `act as solution-architect and report status`). Confirm:
   - Canonical charter loaded from `.agents/engineering-team/core/roles/solution-architect.md`.
   - Project bindings loaded.

## Updates

On new framework release:

1. Re-fetch `.agents/engineering-team/core/` + `.agents/engineering-team/adapters/` + `.agents/engineering-team/extras/` (your `local/` survives).
2. Re-copy `.agents/engineering-team/adapters/agents-md/AGENTS.md` to project root (merge if project-specific content was added).
3. Read `.agents/engineering-team/core/MIGRATIONS/` for breaking-change notes.

## Uninstall

1. Remove the engineering-team section from `AGENTS.md` (or delete the file if framework-only).
2. (Gemini) Same for `GEMINI.md`.
3. Optionally delete `.agents/engineering-team/`.

## Cross-tool layering

Baseline adapter for all AGENTS.md-supporting clients. For clients with native subagent support, layer the dedicated adapter on top:

| Client | Layer also |
|---|---|
| Claude Code | `.agents/engineering-team/adapters/claude/` |
| Copilot CLI | `.agents/engineering-team/adapters/copilot-cli/` |

Layered installs do not conflict — AGENTS.md provides cross-tool context; the per-client adapter provides native subagent routing.
