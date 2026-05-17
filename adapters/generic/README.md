# Generic adapter (instructions-only fallback)

For LLM clients without dedicated framework support — no `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, or subagent directory recognition.

## When to use this adapter

| Scenario | Use this adapter? |
|---|---|
| Claude Code | No — use `claude` adapter (tier-1) |
| Copilot CLI | No — use `copilot-cli` adapter (tier-1) |
| Codex / Cursor / Windsurf / Amp / Devin / Factory / Jules / Copilot IDE | No — use `agents-md` adapter (tier-2) |
| Gemini CLI | No — use `agents-md` adapter (tier-2; copy AGENTS.md → GEMINI.md) |
| Any other LLM client or web chat where you paste instructions manually | **Yes** — this adapter (tier-3) |
| Custom in-house tool with its own instructions format | **Yes** — paste contents of `INSTRUCTIONS.md` into the tool's prompt context |

## Capability tier — **3** (instructions-only, no native routing)

The LLM impersonates each cardinal role as a persona when mentioned. No multi-agent isolation, no parallel dispatch, sequential execution only.

## What this adapter ships

| Path | What it is |
|---|---|
| `INSTRUCTIONS.md` | The fallback instructions file — paste / point at as your client's instructions context |
| `README.md` | This file |
| `install.md` | Manual integration procedure |

## How it works

The `INSTRUCTIONS.md` file is a single document that:
- Points at `engineering-team/core/process.md` for the process spec
- Lists the 7 cardinal roles with paths to their canonical charters
- Includes the always-apply coordination rules in summary form

The client reads `INSTRUCTIONS.md` as system-prompt context; when the user mentions a role (e.g. "act as backend-engineer"), the LLM reads the corresponding `core/roles/<role>.md` and acts per that charter.

## Smoke test

1. Install per `install.md`.
2. Prompt: `read INSTRUCTIONS.md and confirm the cardinal roles + process spec are loaded`.
3. Prompt: `act as project-manager and run initial discovery`.

## Custom roles

Same as other adapters — author at `engineering-team/local/roles/<role>.md`; `project-manager` discovers them on next prompt.
