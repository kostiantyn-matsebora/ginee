---
title: Contributing
description: "How to file issues, propose features, contribute role definitions, and submit PRs."
permalink: /CONTRIBUTING.html
---

# Contributing

ginee is open source under [MIT](https://github.com/kostiantyn-matsebora/ginee/blob/main/LICENSE). Contributions welcome — issues, PRs, custom-role authoring, adapter improvements, doc fixes.

## Filing issues

Use the [issue templates](https://github.com/kostiantyn-matsebora/ginee/issues/new/choose):

| Template | When |
|---|---|
| **Bug report** | Framework behaviour doesn't match spec — role-domain leakage, install-script issue, doc-vs-code mismatch, recipe failure, gate elision in non-auto mode, etc. |
| **Feature request** | New role, new spec, new template, new adapter, new locked-decision proposal |
| **Security issue** | **Do not file publicly.** Use [private vulnerability reporting](https://github.com/kostiantyn-matsebora/ginee/security/advisories/new) per [SECURITY.md](https://github.com/kostiantyn-matsebora/ginee/blob/main/SECURITY.md) |

Each template surfaces the fields ginee's team-lead workflow consumes — area, reproduction, expected vs actual, version, adapter, locked-decision impact, acceptance criteria. Keep those filled in for a fast turn-around.

## PR conventions

Use the [PR template](https://github.com/kostiantyn-matsebora/ginee/blob/main/.github/PULL_REQUEST_TEMPLATE.md):

- **One concern per PR.** Bundling unrelated changes makes review slower and rollbacks harder.
- **Cite the source.** Every PR cites at least one of: requirement / NFR / mockup section / CR / ADR / issue. No source → no PR (write the doc update first or flag the gap).
- **`Fixes #N` / `Closes #N`** for issue-sourced PRs — GitHub auto-closes on merge into the default branch.
- **Acceptance criteria mirrored** from the issue, ticked or explicitly deferred with rationale.
- **Out-of-scope alternatives** documented for any design call where you took one path and rejected another. Reviewers can redirect.
- **Migration note** under `migrations/` for any change adopters must apply manually (rename, re-extract, edit `local/bindings.md`, etc.).
- **Lossless rule.** Doc edits preserve every existing rule / invariant / record. Verify by grep after the change.
- **Context-economy mandate.** Framework files are always-loaded LLM context. Structure beats prose; every byte earns its keep. See [`CLAUDE.md § Framework authoring`](https://github.com/kostiantyn-matsebora/ginee/blob/main/CLAUDE.md#framework-authoring--context-economy).

## Authoring a custom role

Add a new role under `local/roles/<role-name>.md` using [`core/templates/role-authoring-template.md`](https://github.com/kostiantyn-matsebora/ginee/blob/main/core/templates/role-authoring-template.md). Shape:

1. **Front-matter** — `name`, `description` (when to dispatch + what NOT to do), `aliases`.
2. **`## Source of truth`** — two-tier load table with `always` + scope-loaded triggers (see the template).
3. **`## What you own`** — paths + concerns.
4. **`## What you do NOT own`** — strict-domain forbidden table.
5. **`## Forbidden actions (strict-domain)`** — role-specific negations.

`team-lead` discovers `local/roles/*.md` on next dispatch — no registration needed.

To **promote** a custom role into the framework (`extras/roles/<name>.md` or `core/roles/`), file a feature-request issue with the role's draft + a case for why it's useful across multiple adopters.

## Proposing a new locked decision (D-record)

Locked decisions live in `PLAN.md § Locked decisions (D1–DN)`. A new D-record is appropriate when:

- A framework-wide concern needs a single canonical answer.
- The answer affects multiple files and the alternatives are real trade-offs (not just style).
- An adopter would need to know the decision to use the framework.

Process:

1. File a **feature-request** issue with the proposal. Include the design space, alternatives considered, and recommended call.
2. PM picks it up, runs Phase 1–8 if scope warrants, opens a PR adding the D-record.
3. Migration note under `migrations/D<N>-<topic>.md` if existing adopters need to migrate.

## Improving an adapter

Adapters under `adapters/<client>/` are thin pointer layers between ginee's generic specs and a specific LLM client. To improve:

- **Update install steps** in `adapters/<client>/install.md` — match the client's current skill / subagent / instruction-file conventions.
- **Update the README** — capability tier, supported features, dispatch surface.
- **Pointer files** under `adapters/<client>/` should cite `core/` files via path, not duplicate content.

## Adding a new adapter

ginee currently ships 4 adapters. To add a fifth (e.g. a new IDE or platform):

1. Create `adapters/<client>/` with `install.md`, `README.md`, and any client-specific pointer files.
2. Add the adapter to `install.ps1` / `install.sh` (`switch` / `case` branch + adapter prompt menu).
3. Add to the `release.yml` workflow's adapter checks.
4. Document in `docs/index.md` adapter badges + `adapters/README.md`.

## Local dev — testing your changes

ginee is markdown-only. To test changes against a real adopter:

```bash
# Local checkout
cd /path/to/ginee

# Run against a test project, fetching from local instead of GitHub
cd /path/to/test-project
/path/to/ginee/install.sh --repo /path/to/ginee --adapter claude --update-only
```

The installer accepts a local path as `--repo`, so you can test the full install flow without pushing.

## Code of conduct

Be kind, be specific, be useful. We don't ship a separate `CODE_OF_CONDUCT.md`; standard open-source decency applies. If something feels off, flag it via the security-issue or email channel in `SECURITY.md`.
