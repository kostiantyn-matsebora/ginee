# GitHub Copilot CLI adapter — install

## Prerequisites

- `.agents/ginee/` directory present at the project root.
- Copilot CLI installed and authenticated (`copilot --help`).
- `.github/agents/` directory (create if absent).

## Steps

1. **Copy + rename the shared pointer subagents** — from `.agents/ginee/adapters/_shared/agents/*.md` into `.github/agents/`, renaming to `.agent.md`.

   ```powershell
   New-Item -ItemType Directory -Force .github\agents | Out-Null
   Get-ChildItem .agents\ginee\adapters\_shared\agents\*.md | ForEach-Object {
     Copy-Item $_.FullName ".github\agents\$($_.BaseName).agent.md"
   }
   ```

   ```bash
   mkdir -p .github/agents
   for f in .agents/ginee/adapters/_shared/agents/*.md; do
     name=$(basename "$f" .md)
     cp "$f" ".github/agents/${name}.agent.md"
   done
   ```

2. **(Recommended) Install the `agents-md` adapter alongside.**
   - Copilot CLI also reads `AGENTS.md` at the project root for cross-tool consistency.
   - See `.agents/ginee/adapters/agents-md/install.md`.

3. **Bridge the framework skills** to a path Copilot discovers. Skills follow the [AgentSkills standard](https://agentskills.io) and live at `.agents/ginee/core/skills/ginee-*/`. Per [GitHub Copilot agent skills docs](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills), Copilot reads three project-level paths: `.github/skills`, `.claude/skills`, **`.agents/skills`**. The framework uses **`.agents/skills/`** — explicit cross-tool path, sibling to `.agents/ginee/`, no per-client fingerprint.

   ```powershell
   New-Item -ItemType Directory -Force .agents\skills | Out-Null
   Copy-Item -Recurse .agents\ginee\core\skills\ginee-* .agents\skills\
   ```

   ```bash
   mkdir -p .agents/skills
   cp -r .agents/ginee/core/skills/ginee-* .agents/skills/
   ```

   Symlinks (POSIX): `ln -s ginee/core/skills/ginee-* .agents/skills/` — preferred over copies for auto-update.

4. **Run discovery.**
   - Open Copilot CLI in the project:

     ```
     copilot
     ```

   - Ask Copilot to run initial discovery (skill auto-activates from description match):

     ```
     Run initial discovery.
     ```

5. **Verify** — ask Copilot to report status of `solution-architect` and `qa-engineer`. Confirm each loads its charter from `.agents/ginee/core/roles/<role>.md`.

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
| "Reindex" / "Reindex `<file>`" / "Reindex `<class>`" / "Reconcile the index" | `ginee-reindex` |
| "Update ginee" / "Upgrade the framework" / "Bump ginee to `v<X>`" / "Pull the latest ginee" | `ginee-update` |

Subagent dispatch (`solution-architect`, `backend-engineer`, etc.) — natural-language via Copilot's chat. `@mention` syntax works in Copilot CLI's chat.

## Updates

**Recommended — re-run the installer**: `.\install.ps1 -UpdateOnly -Adapter copilot-cli` (or `./install.sh --update-only --adapter copilot-cli`). Automates steps 1–3.

Manual equivalent:

1. Re-fetch `.agents/ginee/core/` + `.agents/ginee/adapters/` + `.agents/ginee/extras/` (your `local/` survives).
2. Re-run step 1 above — pointers may have been refined.
3. Re-copy `.agents/ginee/core/skills/ginee-*` to `.github/skills/`. Skip if you used symlinks.
4. Read `.agents/ginee/core/MIGRATIONS/` for breaking-change notes.
5. **For pre-D11 (pre-2026-05-18) upgrades** — run the rename migration script once:
   - `.\.agents\ginee\core\scripts\migrate-engineering-team-to-ginee.ps1` (or `.sh`).
   - Rewrites legacy `engineering-team` references under `local/*`. Idempotent.
   - Full notes: `.agents/ginee/core/MIGRATIONS/engineering-team-renamed-ginee.md`.

## Uninstall

1. Delete the 7 cardinal files from `.github/agents/` (and any custom roles).
2. Delete `ginee-*` from `.github/skills/`.
3. (If installed) Uninstall the `agents-md` adapter per its `install.md`.
4. Optionally delete `.agents/ginee/`.
