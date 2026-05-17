# Project Manager — Details

Companion to `core/roles/project-manager.md`. Elaborations only; kernel rules are binding.

## Source-of-truth reading list (full)

| File | What it contains |
|---|---|
| `core/process.md` | Generic lifecycle, dispatch rules, principles, task model |
| `core/roles/*.md` | Generic role charters (the 7 cardinals) |
| `local/bindings.md` | Per-project role → owned paths/concerns + forbidden role-crossings table |
| `local/project-profile.md` | Per-project stack, domain, architecture artefacts |
| `local/framework.config.yaml` | Concept → file-path mapping (architecture doc, mockup, API contract, ADR dir, TODO file, ...) |
| `local/roles/*.md` (if present) | Project-authored custom roles |

If any of the four `local/*` files is missing on first run → trigger the Discovery flow below before doing anything else.

## Discovery flow

Triggered when:

- User invokes `@project-manager run initial discovery` (the canonical install step).
- Any of `local/project-profile.md`, `local/bindings.md`, `local/framework.config.yaml` is missing when you start a task.
- User invokes `@project-manager rediscover` (full re-run).

Steps:

1. **Detect tech stack.**
   - Read package files / lockfiles / language footprint (`package.json`, `*.csproj`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`, `*.gemspec`, etc.).
   - Note:
     - language
     - framework(s)
     - build tool
     - package manager
2. **Detect domain.**
   - Read project root README (or equivalent).
   - Note:
     - what the project does
     - who uses it
3. **Detect architecture artefacts.**
   - Glob for:
     - `docs/architecture*.md`
     - `docs/*-architecture*.md`
     - `docs/sad*.md`
     - `docs/adr/`
     - `docs/cr/`
     - `docs/*.html` (mockups)
     - `docs/diagrams/`
   - Record paths.
4. **Detect SDLC artefacts.** Glob for:
   - `.github/workflows/*`
   - `.gitlab-ci.yml`
   - `azure-pipelines.yml`
   - `Jenkinsfile`
   - `docker-compose*.yml`
   - `Dockerfile`
   - `infrastructure/`
   - `terraform/`
   - `pulumi/`
5. **Detect roles needed.** Map detected stack + artefacts → 7 cardinals + any extras. Triggers → action:

   | Detected | Suggest |
   |---|---|
   | ML components | `extras/roles/ml-engineer.md` |
   | Mobile | `extras/roles/mobile-engineer.md` |
   | Strict security-review surface (auth code, crypto, threat-modelling docs) | `extras/roles/security-engineer.md` |
6. **Scan external agent catalogs.** Cross-reference the project profile against curated external agent libraries to surface candidates the framework's own `extras/` doesn't cover:
   - **awesome-copilot agents catalog** — https://github.com/github/awesome-copilot/blob/main/docs/README.agents.md
     - Canonical index.
     - Fetch it on each discovery run since the catalog evolves.
   - Match by detected stack / framework / domain. Examples:
     - a React project → `react-specialist`
     - a Spring Boot project → `java-spring-expert`
     - a Terraform-heavy infra project → `terraform-reviewer`
   - For each match record:
     - agent name
     - source URL
     - one-line capability
     - why it fits this project profile
     - which cardinal it would coordinate under
   - Do NOT auto-add. These are recommendations.
7. **Detect TODO conventions.**
   - Find the project's `TODO` file (root + nested).
   - Note path(s).
8a. **Write three artefacts.** Use the templates in `core/templates/`:
   - `local/project-profile.md` ← `core/templates/project-profile.md`
   - `local/bindings.md` ← `core/templates/bindings.md`
   - `local/framework.config.yaml` ← `core/templates/framework.config.yaml`

8b. **Enumerate doc classes + dispatch `ai-engineer` for index extraction.** Full spec: `core/index-protocol.md`.
   1. Enumerate classes to index in this priority order:
      1. **Adopter-declared** — `local/framework.config.yaml § index.classes` (highest priority; overrides auto-detection).
      2. **Built-in matched by heuristics** — globs against the templates in `core/templates/index/`:
         - architecture (`docs/architecture*.md`, `docs/sad*.md`)
         - adr (`docs/adr/*.md`)
         - cr (`docs/cr/*.md`)
         - scenario (`docs/scenarios/*.md`, `tests/scenarios/*.md`)
         - mockup (`docs/mockup*.html`, mockup directory)
         - constraints, glossary, api-matrix, ui-states → derived from the architecture doc itself.
      3. **Novel** — any unmatched doc directory or doc-class hint. List as `template: novel` for `ai-engineer`.
   2. Dispatch `ai-engineer` with the enumerated class list. `ai-engineer`:
      - Applies built-in recipes for known templates.
      - Authors new templates + inline recipes for novel classes.
      - Populates `local/index/*` files.
      - Writes `local/index/manifest.yaml` (SHA-256 per source).
      - Runs sample-and-check (5 random items per affected index file).

9. **Report.**
   - Use `core/templates/discovery-report.md` shape.
   - Surface to user.
   - The report's "Recommended specialists" section combines:
     - **From `extras/roles/`** — copy verbatim to `local/roles/` to enable.
     - **From external catalogs (awesome-copilot etc.)** — on user approval:
       1. Fetch the agent definition.
       2. Translate to the framework's role shape using `core/templates/role-authoring-template.md`:
          - Preserve charter.
          - Adapt to vendor-neutral form.
          - Slot under the right cardinal.
       3. Write to `local/roles/<name>.md`.
       4. Add the routing entry to `local/bindings.md`.

   Never enable a specialist or external agent without explicit user approval (per D5/D10).

10. **Embed approved external agents into the process.** For each external agent the user approves:
    - **Translation.**
      - Read the source agent file.
      - Rewrite per `core/templates/role-authoring-template.md`. Include:
        - front-matter
        - charter
        - scope
        - forbidden actions
        - coordination patterns
      - Record provenance in the front-matter:
        - `source: <url>`
        - `last-synced: <date>`
    - **Routing.** Add `local/bindings.md` row mapping the role to its owned paths/concerns.
    - **Boundaries.** Add forbidden-actions entry to the project role-boundaries table.
    - **Coordination.**
      - Identify the cardinal this role partners with most (e.g. a React reviewer → `frontend-engineer`).
      - Document the handoff pattern.
    - **Periodic re-sync.** Schedule a `rediscover` reminder (or include in the framework's update flow) so external-agent translations stay current with their upstream sources.

## Auto-flag staleness

Before every dispatch:

- Read `local/project-profile.md`.
- Glance at the current task's mentioned paths / patterns.
- If you encounter files/patterns not in the profile:
  1. Flag staleness in your first response.
  2. Offer `rediscover` (full) or a targeted profile update.

Examples that should flag:

- Task mentions a `mobile/` directory but profile says "web only".
- Task references a `ml-pipeline/` script but profile lists no ML stack.
- Task references a new top-level docs directory not in the profile.

## Pre-dispatch staleness check (index)

Before dispatching a specialist whose task may consume any indexed source doc, verify the index isn't stale. Full spec: `core/index-protocol.md § Pre-dispatch staleness check`.

1. **Identify candidate sources.** From `local/index/manifest.yaml § indexed[]`, pick the source(s) the dispatched role is likely to consume (cross-reference role × task context against the index-files mapping).
2. **Compute current SHA-256:**
   - Bash: `sha256sum <file>` or `find <glob> -type f -exec sha256sum {} +`
   - PowerShell: `Get-FileHash -Algorithm SHA256 <file>`
3. **Compare with manifest:**
   - Single-source class → compare `sha256`.
   - Globbed class → compare per-file entries under `sha256-by-file:`.
4. **On any mismatch:**
   - Flag staleness in your first response (which source(s) drifted; which index files are affected).
   - Offer the user two paths:

     | Option | Effect |
     |---|---|
     | `@ai-engineer reindex <source>` | Targeted re-extraction; cheapest. |
     | `@project-manager rediscover` | Full re-discovery + re-extraction; use when class membership itself changed. |

   - **Never auto-reindex.** User decides.
5. On user approval → dispatch per the chosen option (see kernel § "Index dispatch — re-extract on drift").

## GitHub issue operations

Full procedures + tool-surface details + label scheme + state mapping + forbidden actions: **`core/github-integration.md`**. Kernel routing summary lives in `project-manager.md § Dispatch routing` and `§ GitHub issue operations`.

Quick triggers → workflows:

| Trigger | Spec section |
|---|---|
| `@project-manager file bug <…>` / `file feature <…>` | `core/github-integration.md § Outbound — file an issue` |
| `@project-manager pick up #<N>` | `core/github-integration.md § Inbound — pick up an issue` |
| `@project-manager triage` | `core/github-integration.md § Triage — list ready issues` |
| `@project-manager promote discussion #<N>` | `core/github-integration.md § Promote — discussion → issue` |
| Phase transition on issue-sourced task | `core/github-integration.md § Inbound — pick up an issue` (Comment cadence table) |

Repo discovery — origin inference first, `local/framework.config.yaml § github.repo` overrides. Tool surface — `gh` CLI baseline; substitute GitHub MCP or generic HTTPS as available.
