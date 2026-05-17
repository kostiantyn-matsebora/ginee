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

3. **Bridge the framework skills** to Copilot's skill-discovery path. Skills follow the [AgentSkills standard](https://agentskills.io) and live at `.agents/engineering-team/core/skills/ginee-*/`. Per [GitHub Copilot agent skills docs](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills), the expected destination is `.github/skills/`.

   ```powershell
   New-Item -ItemType Directory -Force .github\skills | Out-Null
   Copy-Item -Recurse .agents\engineering-team\core\skills\ginee-* .github\skills\
   ```

   ```bash
   mkdir -p .github/skills
   cp -r .agents/engineering-team/core/skills/ginee-* .github/skills/
   ```

   Symlinks (POSIX): `ln -s ../../.agents/engineering-team/core/skills/ginee-* .github/skills/` — preferred over copies for auto-update.

4. **Run discovery.**
   - Open Copilot CLI in the project:

     ```
     copilot
     ```

   - Ask Copilot to run initial discovery (skill auto-activates from description match):

     ```
     Run initial discovery.
     ```

5. **Verify** — ask Copilot to report status of `solution-architect` and `qa-engineer`. Confirm each loads its charter from `.agents/engineering-team/core/roles/<role>.md`.

6. **Try parallel orchestration.**
   - Run `/fleet`.
   - Dispatches multiple cardinals in parallel per the Iteration protocol.

## How to invoke

Copilot CLI / VS Code Copilot reads framework skills from `.github/skills/` (per Copilot's agent-skills docs). Each `ginee-*` skill auto-activates when the user's prompt matches its description.

Cheat sheet:

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
| "Reindex `<source>`" | `ginee-reindex` |

Subagent dispatch (`solution-architect`, `backend-engineer`, etc.) — natural-language via Copilot's chat. `@mention` syntax works in Copilot CLI's chat.

## Updates

On new framework release:

1. Re-fetch `.agents/engineering-team/core/` + `.agents/engineering-team/adapters/` + `.agents/engineering-team/extras/` (your `local/` survives).
2. Re-run step 1 above — pointers may have been refined.
3. Re-copy `.agents/engineering-team/core/skills/ginee-*` to `.github/skills/`. Skip if you used symlinks.
4. Read `.agents/engineering-team/core/MIGRATIONS/` for breaking-change notes.

## Uninstall

1. Delete the 7 cardinal files from `.github/agents/` (and any custom roles).
2. Delete `ginee-*` from `.github/skills/`.
3. (If installed) Uninstall the `agents-md` adapter per its `install.md`.
4. Optionally delete `.agents/engineering-team/`.
