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
| "Address review on PR #N" / "Respond to review on #N" / "Handle review feedback on #N" | `ginee-address-review` |

Subagent dispatch (`solution-architect`, `backend-engineer`, etc.) — natural-language via Copilot's chat. `@mention` syntax works in Copilot CLI's chat.

## Model tier (D31)

Copilot CLI does **not** expose programmatic per-role model selection today — model choice lives in the client's own UI. The `model:` field in `.github/agents/<role>.agent.md` frontmatter is ignored by Copilot CLI; ginee writes it for parity with other adapters but the runtime ignores it.

**Per-task prefix (user-side hint).** Prefix any dispatch with `model:<tier>` (`reasoning` / `standard` / `fast`) — Copilot does not act on it programmatically, but the prefix is a documented signal you can pair with manual model selection in the Copilot UI.

```
model:reasoning Add the new ASR utility-tree leaves for the latency NFR.
```

When Copilot CLI gains a per-role / per-task model API, this adapter's install step will wire it. Spec: `core/MIGRATIONS/D31-model-tier.md`.

## Phase-file loading (D35)

Per D35-process-md-load-topology, the 8 lifecycle phases + orchestration content live under `core/process/` and load per-cardinal via `phase-participation:` frontmatter.

| Step | Behaviour |
|---|---|
| Read each pointer file's frontmatter under `.github/copilot/agents/` | Lift `phase-participation: [N, M, …]` |
| For each `N` in the list | Cite `.agents/ginee/core/process/phase-<N>-<name>.md` in that pointer's load section |
| `team-lead` only (and skill-runner main thread on `ginee-*` skill entry) | Additionally cite `.agents/ginee/core/process/dispatch.md` |
| Cardinals with empty list (`ai-engineer`) | Load no phase files; common `.agents/ginee/core/process.md` only |

Non-participating phase files are not surfaced to that role. Full spec: `core/MIGRATIONS/D35-process-md-load-topology.md`.

## Updates

**Recommended — `/ginee-update`** (or "update ginee" / "upgrade the framework"). The skill fetches the installer from upstream at the target ref and drives `--update-only` for you — no local installer needed (D27). Automates steps 1–3.

**Manual fallback — bootstrap one-liner** (the installer is intentionally NOT inside `.agents/ginee/` per D27):

```powershell
$env:GINEE_UPDATE_ONLY='1'; $env:GINEE_ADAPTER='copilot-cli'; iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.ps1 | iex
```

```bash
GINEE_UPDATE_ONLY=1 GINEE_ADAPTER=copilot-cli bash -c "$(curl -fsSL https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh)"
```

**Step-by-step equivalent:**

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
