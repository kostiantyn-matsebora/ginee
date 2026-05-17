# GitHub Copilot CLI adapter — install

## Prerequisites

- `engineering-team/` directory present at the project root.
- Copilot CLI installed and authenticated (`copilot --help`).
- `.github/agents/` directory (create if absent).

## Steps

1. **Copy + rename the shared pointer subagents** — from `engineering-team/adapters/_shared/agents/*.md` into `.github/agents/`, renaming to `.agent.md`.

   ```powershell
   New-Item -ItemType Directory -Force .github\agents | Out-Null
   Get-ChildItem engineering-team\adapters\_shared\agents\*.md | ForEach-Object {
     Copy-Item $_.FullName ".github\agents\$($_.BaseName).agent.md"
   }
   ```

   ```bash
   mkdir -p .github/agents
   for f in engineering-team/adapters/_shared/agents/*.md; do
     name=$(basename "$f" .md)
     cp "$f" ".github/agents/${name}.agent.md"
   done
   ```

2. **(Recommended) Install the `agents-md` adapter alongside** — Copilot CLI also reads `AGENTS.md` at the project root for cross-tool consistency. See `engineering-team/adapters/agents-md/install.md`.

3. **Run discovery** — open Copilot CLI in the project:

   ```
   copilot
   ```

   Then prompt: `@project-manager run initial discovery`

4. **Verify** — mention each cardinal by name (`@solution-architect status`, `@qa-engineer status`) to confirm each loads its charter.

5. **Try parallel orchestration** — `/fleet` dispatches multiple cardinals in parallel per the Iteration protocol.

## Updates

When the framework releases a new version:

1. Re-fetch `engineering-team/core/` + `engineering-team/adapters/` + `engineering-team/extras/` (your `local/` survives).
2. Re-run step 1 above — pointers may have been refined.
3. Read `engineering-team/core/MIGRATIONS/` for any breaking-change notes.

## Uninstall

1. Delete the 7 cardinal files from `.github/agents/` (and any custom roles).
2. (If installed) Uninstall the `agents-md` adapter per its `install.md`.
3. Optionally delete the `engineering-team/` directory.
