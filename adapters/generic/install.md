# Generic adapter — install

## Prerequisites

- `.agents/ginee/` directory present at the project root.
- An LLM client that lets you specify instructions / system prompt manually.

## Steps

1. **Locate your client's instructions surface.** Possibilities:
   - A "Custom Instructions" / "System Prompt" field in the client's settings.
   - A project-level config file the client reads (varies by tool).
   - A manual paste into the chat as the first message of each session.

2. **Provide `INSTRUCTIONS.md`'s content** to that surface. Two options:

   **Option A (recommended) — reference the file by path.**

   If your client can read repo files:
   - Point its instructions at:

     ```
     .agents/ginee/adapters/generic/INSTRUCTIONS.md
     ```

   - Configure the client to read this file at the start of every session.

   **Option B — paste the content.**

   If your client only accepts inline text:

   ```powershell
   Get-Content .agents\ginee\adapters\generic\INSTRUCTIONS.md | Set-Clipboard
   ```

   ```bash
   cat .agents/ginee/adapters/generic/INSTRUCTIONS.md | pbcopy  # macOS
   xclip -selection clipboard < .agents/ginee/adapters/generic/INSTRUCTIONS.md  # Linux
   ```

   Paste into your client's instructions / system-prompt field.

3. **(If your client supports the [AgentSkills standard](https://agentskills.io))** Bridge the framework skills to its skill-discovery path. Source: `.agents/ginee/core/skills/ginee-*/`. Check your client's docs for the expected destination. Most clients use `.<client>/skills/`.

   Skips for non-AgentSkills clients — framework workflows still work via natural-language routing in `INSTRUCTIONS.md`, just without per-workflow skill activation.

4. **Run discovery.**
   - Start a session.
   - Prompt:

     ```
     act as team-lead and run initial discovery
     ```

5. **Verify** — prompt `act as solution-architect and report status`. Confirm it loads:
   - The canonical charter.
   - Project bindings.

## How to invoke

Generic adapter has no auto-routing — every framework workflow runs via natural-language to the orchestrator. Patterns:

| Want to | Prompt |
|---|---|
| Run discovery | `act as team-lead and run initial discovery` |
| File a bug | `act as team-lead and file a bug titled "<title>"` |
| File a framework feature | `act as team-lead and file a framework feature request titled "<title>"` |
| Pick up a task | `act as team-lead and pick up issue #<N>` (or TODO line or freeform description) |
| Triage | `act as team-lead and triage / list ready work` |
| Promote discussion | `act as team-lead and promote discussion #<N>` |
| Reconcile the index | `act as ai-engineer and reindex` (whole repo) / `... reindex <file>` / `... reindex <class>` |
| Update the framework | `act as team-lead and update ginee` (latest release) / `... update ginee to v<X>` / `... update ginee to ref <branch\|sha>` |
| Address review on a PR | `act as team-lead and address review on PR #<N>` (or "respond to review on #N" / "handle review feedback on #N") |

If your client supports AgentSkills (step 3 above), each of these phrasings also auto-activates the matching `ginee-*` skill — same behaviour, fewer keystrokes.

## Limitations vs higher-tier adapters

- No native role isolation — context bleeds between cardinal personas within a session (unless the client supports AgentSkills + subagents).
- No parallel dispatch — iterations run sequentially.
- LLM must hold all role context simultaneously — costs tokens.

If your client matures to support `AGENTS.md`, a subagent directory, or AgentSkills, upgrade to the matching adapter for better isolation + parallelism.

## Model tier (D31)

Generic adapter has no per-role model selection — the host client picks one model for the whole session. ginee writes vendor-neutral tier names in `local/framework.config.yaml § model-tier` but the runtime ignores them at this tier.

**Per-task prefix (user-side hint).** Prefix any dispatch with `model:<tier>` (`reasoning` / `standard` / `fast`) — a documented signal you can pair with manual model selection in your client.

```
model:reasoning act as solution-architect and add the new ASR utility-tree leaves for the latency NFR
```

When the host client matures to support per-role model selection (Claude Code / Copilot CLI level), upgrade to the matching adapter. Spec: `core/MIGRATIONS/D31-model-tier.md`.

## Updates

**Recommended — `/ginee-update`** (or "update ginee" / "upgrade the framework") when the host client supports AgentSkills. Falls back to "act as `team-lead` and update ginee" for tier-3 clients. The skill fetches the installer from upstream at the target ref and drives `--update-only` for you — no local installer needed (D27).

**Manual fallback — bootstrap one-liner** (the installer is intentionally NOT inside `.agents/ginee/` per D27):

```powershell
$env:GINEE_UPDATE_ONLY='1'; $env:GINEE_ADAPTER='generic'; iwr -useb https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.ps1 | iex
```

```bash
GINEE_UPDATE_ONLY=1 GINEE_ADAPTER=generic bash -c "$(curl -fsSL https://raw.githubusercontent.com/kostiantyn-matsebora/ginee/main/install.sh)"
```

**Step-by-step equivalent:**

1. Re-fetch `.agents/ginee/` (your `local/` survives).
2. Client reads `INSTRUCTIONS.md` by path → no further action.
3. Pasted content → re-paste with the updated file.
4. Read `.agents/ginee/core/MIGRATIONS/` for breaking-change notes.
5. **For pre-D11 (pre-2026-05-18) upgrades** — run the rename migration script once:
   - `.\.agents\ginee\core\scripts\migrate-engineering-team-to-ginee.ps1` (or `.sh`).
   - Rewrites legacy `engineering-team` references under `local/*`. Idempotent.
   - Full notes: `.agents/ginee/core/MIGRATIONS/engineering-team-renamed-ginee.md`.

## Uninstall

1. Clear the client's instructions / system-prompt field (or remove the path reference).
2. Optionally delete `.agents/ginee/`.
