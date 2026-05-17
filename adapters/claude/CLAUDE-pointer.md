# CLAUDE-pointer

Append this block to your project's `CLAUDE.md` (or paste at the top if no existing file).

---

## Engineering team framework

This project uses the [`engineering-team`](.agents/engineering-team/) framework. **Read before any work:**

- `.agents/engineering-team/core/process.md` — vendor-neutral team process spec (lifecycle, dispatch, iteration protocol, doc co-ownership, task model)
- `.agents/engineering-team/local/bindings.md` — project-specific routing, role boundaries, source-of-truth, stack
- `.agents/engineering-team/local/project-profile.md` — discovered project context (filled by `@project-manager` on first run)

Dispatch via the cardinal roles in `.claude/agents/` (installed from `.agents/engineering-team/adapters/_shared/agents/` per `.agents/engineering-team/adapters/claude/install.md`). The orchestrator is `project-manager`. Custom roles live in `.agents/engineering-team/local/roles/`.

On first install, prompt: `@project-manager run initial discovery`.

---
