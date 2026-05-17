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

   If you already have an `AGENTS.md` at the project root, merge the new content (don't overwrite existing project-specific rules — append the engineering-team section).

2. **(Gemini users only)** Copy the same content to `GEMINI.md`:

   ```bash
   cp AGENTS.md GEMINI.md
   ```

3. **Run discovery** — open the project in your client (Cursor / Codex / Windsurf / Copilot IDE / etc.) and prompt:

   ```
   @project-manager run initial discovery
   ```

   If the client doesn't support `@mention` routing, prompt: `act as project-manager and run initial discovery`.

4. **Verify** — prompt `@solution-architect status` (or "act as solution-architect and report status"). Confirm it loads the canonical charter from `.agents/engineering-team/core/roles/solution-architect.md` and the project bindings.

## Updates

When the framework releases a new version:

1. Re-fetch `.agents/engineering-team/core/` + `.agents/engineering-team/adapters/` + `.agents/engineering-team/extras/` (your `local/` survives).
2. Re-copy `.agents/engineering-team/adapters/agents-md/AGENTS.md` to project root (merge if you added project-specific content).
3. Read `.agents/engineering-team/core/MIGRATIONS/` for any breaking-change notes.

## Uninstall

1. Remove the engineering-team section from `AGENTS.md` (or delete the file if it was framework-only).
2. (Gemini users) Same for `GEMINI.md`.
3. Optionally delete the `.agents/engineering-team/` directory.

## Cross-tool layering

This adapter is a **baseline** for all AGENTS.md-supporting clients. For clients with native subagent support, layer the dedicated adapter on top:

- Claude Code → also install `.agents/engineering-team/adapters/claude/`
- Copilot CLI → also install `.agents/engineering-team/adapters/copilot-cli/`

Layered installs do not conflict — the AGENTS.md provides cross-tool context; the per-client adapter provides native subagent routing.
