# AGENTS.md adapter (cross-tool standard)

For clients that read `AGENTS.md` at the project root.

Single-file adapter — one pointer file covers them all.

## Supported clients

| Client | AGENTS.md support | Notes |
|---|---|---|
| OpenAI Codex CLI | Native | Project-root `AGENTS.md` |
| GitHub Copilot (CLI + IDEs) | Native | Pairs with the `copilot-cli` adapter for subagents |
| Cursor | Native | Pairs with `.cursor/rules/*.mdc` if you use rules; AGENTS.md is the cross-tool baseline |
| Windsurf | Native | |
| Amp | Native | |
| Devin | Native | |
| Factory | Native | |
| Jules (Google) | Native | |
| Claude Code | Pending | Use the `claude` adapter as primary; AGENTS.md is a cross-tool backup |
| Gemini CLI | Uses `GEMINI.md` | Copy `AGENTS.md` content to `GEMINI.md` for parity |

- Verified 2026-05.
- AGENTS.md stewarded by the Agentic AI Foundation (Linux Foundation).
- Re-check per release.

## Capability tier — **2** (instructions-only, single-agent persona model)

- `AGENTS.md` — single instructions file.
- 7 cardinals — PERSONAS the single LLM impersonates when mentioned by name in chat.
- No native subagent isolation.
- Sequential execution.

For tier-1 (native subagents + parallel dispatch), use:
- `claude` adapter (Claude Code)
- `copilot-cli` adapter (Copilot CLI)

These install ON TOP OF this adapter, not instead of it.

## What this adapter ships

| Path | What it is |
|---|---|
| `AGENTS.md` | The single pointer file — drop at project root |
| `README.md` | This file |
| `install.md` | Step-by-step install |

**No subagent pointer files:**
- Clients in this tier don't load multiple agent files.
- `AGENTS.md` lists where each cardinal's canonical charter lives.

## Pointer line (for clients with separate instructions files)

If your client also reads its own instructions file (e.g. `.cursor/rules/_index.mdc`), append:

```
See AGENTS.md at the project root.
```

## Smoke test

1. Install per `install.md`.
2. Open the project in your client (Cursor / Codex / Windsurf / etc.).
3. Prompt: `read AGENTS.md and confirm the cardinal roles + process spec are loaded`.
4. Prompt:
   - `@team-lead run initial discovery`.
   - Clients without `@mention` routing — use `act as team-lead and run initial discovery` instead.

## Custom roles

- Location — `.agents/ginee/local/roles/<role>.md`.
- Discovery:
  - `team-lead` picks them up automatically.
  - Adds them to routing.
  - No AGENTS.md edit needed.
