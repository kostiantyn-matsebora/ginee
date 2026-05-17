# Generic adapter — install

## Prerequisites

- `.agents/engineering-team/` directory present at the project root.
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
     .agents/engineering-team/adapters/generic/INSTRUCTIONS.md
     ```

   - Configure the client to read this file at the start of every session.

   **Option B — paste the content.**

   If your client only accepts inline text:

   ```powershell
   Get-Content .agents\engineering-team\adapters\generic\INSTRUCTIONS.md | Set-Clipboard
   ```

   ```bash
   cat .agents/engineering-team/adapters/generic/INSTRUCTIONS.md | pbcopy  # macOS
   xclip -selection clipboard < .agents/engineering-team/adapters/generic/INSTRUCTIONS.md  # Linux
   ```

   Paste into your client's instructions / system-prompt field.

3. **Run discovery.**
   - Start a session.
   - Prompt:

     ```
     act as project-manager and run initial discovery
     ```

4. **Verify** — prompt `act as solution-architect and report status`. Confirm it loads:
   - The canonical charter.
   - Project bindings.

## Limitations vs higher-tier adapters

- No native role isolation — context bleeds between cardinal personas within a session.
- No parallel dispatch — iterations run sequentially.
- LLM must hold all role context simultaneously — costs tokens.

If your client matures to support `AGENTS.md` or a subagent directory, upgrade to the matching adapter for better isolation + parallelism.

## Updates

On new framework release:

1. Re-fetch `.agents/engineering-team/` (your `local/` survives).
2. Client reads `INSTRUCTIONS.md` by path → no further action.
3. Pasted content → re-paste with the updated file.
4. Read `.agents/engineering-team/core/MIGRATIONS/` for breaking-change notes.

## Uninstall

1. Clear the client's instructions / system-prompt field (or remove the path reference).
2. Optionally delete `.agents/engineering-team/`.
