# GitHub Copilot CLI adapter — install

## Prerequisites

- `.agents/engineering-team/` directory present at the project root.
- Copilot CLI installed and authenticated (`copilot --help`).
- `.github/agents/` directory (create if absent).

## Steps

1. **Copy + rename the shared pointer subagents** — from `.agents/engineering-team/adapters/_shared/agents/*.md` into `.github/agents/`, renaming to `.agent.md`.

   ```powershell
   New-Item -ItemType Directory -Force .github\agents | Out-Null
   Get-ChildItem .agents\engineering-team\adapters\_shared\agents\*.md | ForEach-Object {
     Copy-Item $_.FullName ".github\agents\$($_.BaseName).agent.md"
   }
   ```

   ```bash
   mkdir -p .github/agents
   for f in .agents/engineering-team/adapters/_shared/agents/*.md; do
     name=$(basename "$f" .md)
     cp "$f" ".github/agents/${name}.agent.md"
   done
   ```

2. **(Recommended) Install the `agents-md` adapter alongside.**
   - Copilot CLI also reads `AGENTS.md` at the project root for cross-tool consistency.
   - See `.agents/engineering-team/adapters/agents-md/install.md`.

3. **Run discovery.**
   - Open Copilot CLI in the project:

     ```
     copilot
     ```

   - Prompt: `@project-manager run initial discovery`

4. **Verify** — mention each cardinal by name to confirm each loads its charter:
   - `@solution-architect status`
   - `@qa-engineer status`

5. **Try parallel orchestration.**
   - Run `/fleet`.
   - Dispatches multiple cardinals in parallel per the Iteration protocol.

## Updates

On new framework release:

1. Re-fetch `.agents/engineering-team/core/` + `.agents/engineering-team/adapters/` + `.agents/engineering-team/extras/` (your `local/` survives).
2. Re-run step 1 above — pointers may have been refined.
3. Read `.agents/engineering-team/core/MIGRATIONS/` for breaking-change notes.

## Uninstall

1. Delete the 7 cardinal files from `.github/agents/` (and any custom roles).
2. (If installed) Uninstall the `agents-md` adapter per its `install.md`.
3. Optionally delete `.agents/engineering-team/`.
