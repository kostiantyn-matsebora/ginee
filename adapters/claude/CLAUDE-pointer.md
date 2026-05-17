# CLAUDE-pointer

Append this block to the project's `CLAUDE.md` (or paste at the top if no existing file).

---

## Engineering team framework

Project uses the [`engineering-team`](.agents/engineering-team/) framework. **Read before any work:**

- `.agents/engineering-team/core/process.md` — vendor-neutral process spec (lifecycle, dispatch, iteration protocol, doc co-ownership, task model).
- `.agents/engineering-team/local/bindings.md` — project routing, role boundaries, source-of-truth, stack.
- `.agents/engineering-team/local/project-profile.md` — discovered project context (filled by `@project-manager` on first run).

**Dispatch.** Via cardinal roles in `.claude/agents/` (installed from `.agents/engineering-team/adapters/_shared/agents/` per `.agents/engineering-team/adapters/claude/install.md`).

**Orchestrator.** `project-manager`.

**Custom roles.** `.agents/engineering-team/local/roles/`.

**First install.** Prompt `@project-manager run initial discovery`.

---
