# AGENTS.md adapter (cross-tool standard)

For clients that read `AGENTS.md` at the project root. Single-file adapter — one pointer file covers them all.

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

Verified as of 2026-05. AGENTS.md is stewarded by the Agentic AI Foundation under the Linux Foundation. Re-check per release.

## Capability tier — **2** (instructions-only, single-agent persona model)

`AGENTS.md` is a single instructions file. The 7 cardinal roles are PERSONAS the single LLM impersonates when mentioned by name in chat. No native subagent isolation; sequential execution.

For tier-1 (native subagents + parallel dispatch), use the `claude` adapter (Claude Code) or `copilot-cli` adapter (Copilot CLI) — they install ON TOP OF this adapter, not instead of it.

## What this adapter ships

| Path | What it is |
|---|---|
| `AGENTS.md` | The single pointer file — drop at project root |
| `README.md` | This file |
| `install.md` | Step-by-step install |

**No subagent pointer files** — clients in this tier don't load multiple agent files; the `AGENTS.md` lists where each cardinal's canonical charter lives.

## Pointer line (for clients with separate instructions files)

If your client also reads its own instructions file (e.g. `.cursor/rules/_index.mdc`), append:

```
See AGENTS.md at the project root.
```

## Smoke test

1. Install per `install.md`.
2. Open the project in your client (Cursor / Codex / Windsurf / etc.).
3. Prompt: `read AGENTS.md and confirm the cardinal roles + process spec are loaded`.
4. Prompt: `@project-manager run initial discovery` (or "act as project-manager and run initial discovery" if the client doesn't support `@mention` routing).

## Custom roles

Custom roles go in `engineering-team/local/roles/<role>.md`. They're discovered automatically by `project-manager` and added to routing — no AGENTS.md edit needed.
