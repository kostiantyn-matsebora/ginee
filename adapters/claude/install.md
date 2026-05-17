# Claude Code adapter — install

## Prerequisites

- `.agents/engineering-team/` directory present at the project root.
- `.claude/agents/` directory (Claude Code creates it; create manually if absent).

## Steps

1. **Copy the shared pointer subagents** — from `.agents/engineering-team/adapters/_shared/agents/*.md` into `.claude/agents/`.

   ```powershell
   New-Item -ItemType Directory -Force .claude\agents | Out-Null
   Copy-Item .agents\engineering-team\adapters\_shared\agents\*.md .claude\agents\
   ```

   ```bash
   mkdir -p .claude/agents
   cp .agents/engineering-team/adapters/_shared/agents/*.md .claude/agents/
   ```

2. **Update `CLAUDE.md`** — append the block from `.agents/engineering-team/adapters/claude/CLAUDE-pointer.md` to your project's `CLAUDE.md`. If your project has no `CLAUDE.md`, create one with that block as the content.

3. **Run discovery** — open the project in Claude Code and prompt:

   ```
   @project-manager run initial discovery
   ```

4. **Verify** — `@solution-architect status` and `@qa-engineer status` should each report their charter (read from `.agents/engineering-team/core/roles/<role>.md`) and confirm the project's bindings.

## Updates

When the framework releases a new version:

1. Re-fetch `.agents/engineering-team/core/` + `.agents/engineering-team/adapters/` + `.agents/engineering-team/extras/` (your `local/` survives).
2. Re-copy `.agents/engineering-team/adapters/_shared/agents/*.md` to `.claude/agents/` (the pointers may have been refined).
3. Read `.agents/engineering-team/core/MIGRATIONS/` for any breaking-change notes.

## Uninstall

1. Delete the 7 cardinal files from `.claude/agents/` (and any custom roles you copied).
2. Remove the pointer block from `CLAUDE.md`.
3. Optionally delete the `.agents/engineering-team/` directory.
