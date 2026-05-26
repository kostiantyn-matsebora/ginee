# Generic adapter — install

Fallback for any LLM client that lets you specify a system prompt manually.

Shared sections (skill cheat sheet · phase-file loading · model tier · updates): `adapters/_shared/install-common.md`.

## Prerequisites

- `.agents/ginee/` present at the project root.
- An LLM client with a custom-instructions / system-prompt surface.

## Steps

1. **Locate the client's instructions surface** — settings field · project-level config file · manual paste as the first message of each session.

2. **Provide `INSTRUCTIONS.md`'s content** to that surface:

   **Option A (recommended) — reference by path.** If the client can read repo files, point its instructions at `.agents/ginee/adapters/generic/INSTRUCTIONS.md`; configure to read at every session start.

   **Option B — paste.** If the client only accepts inline text:

   ```powershell
   Get-Content .agents\ginee\adapters\generic\INSTRUCTIONS.md | Set-Clipboard
   ```

   ```bash
   cat .agents/ginee/adapters/generic/INSTRUCTIONS.md | pbcopy   # macOS
   xclip -selection clipboard < .agents/ginee/adapters/generic/INSTRUCTIONS.md   # Linux
   ```

3. **(If client supports [AgentSkills](https://agentskills.io))** Bridge `.agents/ginee/core/skills/ginee-*/` to its skill-discovery path (typically `.<client>/skills/`). Non-AgentSkills clients still route via natural-language patterns in `INSTRUCTIONS.md`.

4. **Run discovery.** Prompt: `act as team-lead and run initial discovery`.

5. **Verify.** Prompt `act as solution-architect and report status` — should load the canonical charter + project bindings.

## How to invoke

No auto-routing on this adapter — every workflow runs via natural-language:

| Want to | Prompt |
|---|---|
| Run discovery | `act as team-lead and run initial discovery` |
| File a bug | `act as team-lead and file a bug titled "<title>"` |
| File a framework feature | `act as team-lead and file a framework feature request titled "<title>"` |
| Pick up a task | `act as team-lead and pick up issue #<N>` (or TODO line / freeform description) |
| Triage | `act as team-lead and triage / list ready work` |
| Promote discussion | `act as team-lead and promote discussion #<N>` |
| Reconcile the index | `act as ai-engineer and reindex` (whole) / `... reindex <file>` / `... reindex <class>` |
| Update the framework | `act as team-lead and update ginee` / `... to v<X>` / `... to ref <branch\|sha>` |
| Address review on a PR | `act as team-lead and address review on PR #<N>` |

AgentSkills-capable clients (step 3) — each phrasing also auto-activates the matching `ginee-*` skill.

## Limitations vs higher-tier adapters

- No native role isolation — context bleeds between cardinal personas in a session.
- No parallel dispatch — iterations run sequentially.
- LLM holds all role context simultaneously — costs tokens.

Upgrade to the matching adapter when the client matures to AGENTS.md / subagent / AgentSkills support.

## Model tier

No per-role model selection — host picks one model per session. Tier resolution + per-task `model:<tier>` prefix: `adapters/_shared/install-common.md § Model tier`.

## Phase-file loading

Per `adapters/_shared/install-common.md § Phase-file loading`. The rendered INSTRUCTIONS file cites phase files inline per role; the LLM honours the contract by reading only what is cited.

## Updates

Per `adapters/_shared/install-common.md § Updates`. Pasted content → re-paste with the updated file; path-reference clients → no action needed.

## Uninstall

1. Clear the client's instructions / system-prompt field.
2. Optionally delete `.agents/ginee/`.
