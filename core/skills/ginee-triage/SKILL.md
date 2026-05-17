---
name: ginee-triage
description: List engineering-team-ready GitHub issues in the primary repo (or framework upstream with optional 'framework' arg) and propose a pickup order. Use when the user asks to 'triage', 'triage issues', 'list ready issues', 'what should I work on', 'show the backlog'. Returns a table of open issues with the ready-label; never picks on its own.
---

# Triage — list ready issues

Run the triage workflow per `.agents/engineering-team/core/github-integration.md § Triage — list ready issues`. Lists candidates; **never picks**.

## Activation

- User asks "triage" / "triage issues" / "list ready issues" / "what should I work on" / "show the backlog".
- Optional 'framework' positional arg → target framework upstream instead of primary.

## Procedure

1. Load `.agents/engineering-team/core/github-integration.md § Triage`.
2. Resolve target repo:
   - Default: primary repo (`github.repo` override or origin inference).
   - With 'framework' arg: `github.framework-repo` — fail fast if unset.
3. List ready issues: `gh issue list --repo <target> --label <ready-label> --state open --json number,title,labels,createdAt` (or MCP).
4. Surface as a table — `#N | Title | Age | Labels`.
5. Propose pickup order based on:
   - Age (older first, modulo new urgent items).
   - Apparent scope (bug-fix issues typically shorter than feature requests).
   - Cross-references with active TODO work (avoid context-switch thrash).
6. End with explicit "Pick one with `pick up #<N>`" — never auto-invoke `ginee-pick-up`.

## Forbidden

- Never auto-pick an issue. Triage only enumerates and proposes.
- Never fall back to primary when the user asked for 'framework' triage and `github.framework-repo` is unset.
- Never modify labels — read-only operation.
