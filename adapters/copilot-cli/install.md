# GitHub Copilot CLI adapter — install

Shared sections (skill cheat sheet · phase-file loading · model tier · updates): `adapters/_shared/install-common.md`.

## Prerequisites

- `.agents/ginee/` present at the project root.
- Copilot CLI installed and authenticated (`copilot --help`).
- `.github/agents/` directory (create if absent).

## Steps

1. **Copy + rename shared pointer subagents** — `.agents/ginee/adapters/_shared/agents/*.md` → `.github/agents/`, renaming to `.agent.md`:

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

2. **(Recommended)** Install the `agents-md` adapter alongside — Copilot CLI also reads `AGENTS.md` at the project root.

3. **Bridge framework skills** to `.agents/skills/` (Copilot reads `.github/skills/`, `.claude/skills/`, **`.agents/skills/`** — framework uses the explicit cross-tool path):

   ```powershell
   New-Item -ItemType Directory -Force .agents\skills | Out-Null
   Copy-Item -Recurse .agents\ginee\core\skills\ginee-* .agents\skills\
   ```

   ```bash
   mkdir -p .agents/skills
   cp -r .agents/ginee/core/skills/ginee-* .agents/skills/
   ```

   POSIX symlinks preferred for auto-update.

4. **Run discovery.** `copilot`. Prompt: `Run initial discovery.`
5. **Verify.** Ask Copilot to report status of `solution-architect` + `qa-engineer` — each should load its charter from `.agents/ginee/core/roles/<role>.md`.
6. **Try parallel orchestration.** Run `/fleet` — dispatches multiple cardinals per the iteration protocol.

## How to invoke

Skills auto-activate from prompt → description match. Cheat sheet: `adapters/_shared/install-common.md § Skill cheat sheet`. Subagent dispatch (`solution-architect`, etc.) — natural-language via Copilot's chat; `@mention` syntax also works.

## Model tier

Per `adapters/_shared/install-common.md § Model tier`. Copilot CLI has no programmatic per-role selection today — `model:` field in `.github/agents/<role>.agent.md` is ignored; ginee writes it for adapter parity. Wiring lands when Copilot ships a per-role / per-task model API.

## Phase-file loading

Per `adapters/_shared/install-common.md § Phase-file loading`. Pointer source = `.github/agents/<role>.agent.md`.

## Updates

Per `adapters/_shared/install-common.md § Updates`.

## Uninstall

1. Delete the 7 cardinal files from `.github/agents/` (and custom roles).
2. Delete `ginee-*` from `.agents/skills/`.
3. (If installed) Uninstall the `agents-md` adapter per its `install.md`.
4. Optionally delete `.agents/ginee/`.
