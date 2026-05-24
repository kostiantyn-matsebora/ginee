# Security Policy

## Reporting a Vulnerability

If you discover a security issue in ginee, please **do not open a public issue**. Instead:

- Use GitHub's private vulnerability reporting: https://github.com/kostiantyn-matsebora/ginee/security/advisories/new
- Or email: **kmatsebora@gmail.com** with `[ginee-security]` in the subject line

Please include:

- A clear description of the issue and its impact
- Reproduction steps or a proof-of-concept
- The affected version(s) (`core/VERSION` or git ref)
- Whether you've disclosed the issue elsewhere

You can expect:

- An acknowledgement within **3 business days**
- A first assessment within **7 business days**
- A coordinated disclosure timeline once the impact is clear

## Supported Versions

Only the latest minor version on `main` is actively supported. Older minor versions receive security fixes only when the upgrade path is non-trivial.

| Version | Supported |
|---|---|
| 0.1.x | ✅ |
| < 0.1 | ❌ |

## Release Integrity

Each tagged release at `https://github.com/kostiantyn-matsebora/ginee/releases` is the authoritative install artefact for `install.sh` / `install.ps1`.

- **Tags are GPG/SSH-signed** by the maintainer. Verify with `git tag -v vX.Y.Z`.
- **CI** runs `.github/workflows/release.yml` on every tag push — verifies `core/VERSION` matches tag, framework structure invariants hold (7 cardinal roles present, shared pointers cite `core/roles/`, required files exist), and SHA-256 sums are recorded in the release artefacts.
- **No transitive code execution at install time.** `install.sh` / `install.ps1` only clone the framework, copy adapter files into the adopter's project, and append a pointer line to `CLAUDE.md` (idempotent via a sentinel header). Review the install scripts before running them.

## What ginee Skills + Roles Execute

ginee ships **markdown-only** process knowledge — role kernels, lifecycle specs, dispatch rules, index protocol. Concrete actions (file edits, shell commands, git operations) run through the host LLM client's tool surface (Claude Code, Copilot CLI, Cursor, Codex, etc.) under whatever permission model the host enforces. **ginee itself does not bypass or relax the host's permission prompts.**

Role kernels prompt the host LLM to invoke its built-in tools (Read, Edit, Bash, Grep, etc.). Every tool call is subject to the host's auto-mode classifier + user approval rules. Adopters review the host's permission prompts before approving.

## Scope

In-scope for security reports:

- Bypass of role-domain boundaries that lets a non-owning specialist write to forbidden surfaces (per `local/bindings.md § Project role boundaries` + cardinal kernel forbidden-actions blocks)
- Path-traversal or injection in install scripts (`install.sh`, `install.ps1`)
- `builtin:runtime-facts` recipe leaking real secret values from `.env` or production appsettings (per safeguard in `core/protocols/index-protocol.md § Source types § Code`)
- Privilege issues in the GitHub Actions workflows (`.github/workflows/*.yml`)
- Marker / sentinel writers producing content that escapes intended bounds (`CLAUDE.md` pointer-append step)

Out of scope:

- Misuse of role agents to produce arbitrary content (roles act under host LLM control + adopter approval — that's the framework's purpose)
- Vulnerabilities in third-party agent hosts (Claude Code, Copilot, Cursor, ...) — report those upstream
- Adopter-authored custom roles under `local/roles/` — those are the adopter's responsibility

## Public Disclosure

After a fix lands, the vulnerability is recorded in the patching release's notes with a CVE if assigned and credit to the reporter (unless they prefer anonymity).
