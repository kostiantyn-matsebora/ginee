# Project-doc index protocol

**Load-on-demand.** Fetched when:

- `project-manager` enumerates doc classes during initial discovery or `rediscover`.
- `project-manager` detects SHA-256 drift pre-dispatch and needs to route to `ai-engineer` for re-extraction.
- `ai-engineer` is dispatched to extract or re-extract index entries.
- A role's "Source of truth" lookup pointed to `local/index/<file>` and the role needs the index-protocol contract (rare — most reads are direct).

Default short tasks do not load this file.

`.idx` grammar spec: `core/index-syntax.md` (load-on-demand on first `.idx` read or write).

## Why

Adopter projects accumulate substantial documentation: architecture doc (30–50K), mockup (30–100K), ADRs / CRs / scenarios (often 100K+ corpora). Pulling full source into LLM context on every dispatch burns tokens before any work has started. The index replaces full-source reads with lightweight per-doc-class summaries; roles read originals only when the index points to a section they need verbatim.

## Layout

```
local/index/
├── manifest.yaml            ← detected doc classes + SHA-256 + source paths + derived index files
├── <flat-record indexes>.idx       ← compact DSL per core/index-syntax.md
└── <nested indexes>.yaml           ← YAML for nested data
```

Format split — pick by data shape, not by class:

- **`.idx`** for flat record collections where every row shares the same schema (ADR rows, CR rows, scenario rows, glossary terms, mockup sections).
- **`.yaml`** for genuinely nested data (API endpoint with method/statuses/wire-shape sub-tree; UI state with example payload + visual + fixture sub-tree; manifest; constraints by category).

Framework-internal only — no adopter hand-authors index files; `ai-engineer` writes them per recipes.

Common index files (from built-in recipes):

| Class | Index file(s) | Source typical |
|---|---|---|
| architecture | `architecture.idx` + `architecture-fr.idx` + `api-matrix.yaml` + `ui-states.yaml` + `constraints.yaml` + `glossary.idx` | `docs/architecture.md`, `docs/sad.md` |
| api-matrix | `api-matrix.yaml` | architecture-doc §API or OpenAPI |
| ui-states | `ui-states.yaml` | architecture + mockup |
| adr | `adr-index.idx` (reusable for RFC, design-decision, any-decision-record class) | `docs/adr/`, `docs/rfcs/` |
| cr | `cr-index.idx` | `docs/cr/` |
| scenario | `scenario-index.idx` | `docs/scenarios/`, `tests/scenarios/` |
| mockup | `mockup-index.idx` | `docs/mockup.html`, mockup directory |
| constraints | `constraints.yaml` | architecture-doc §NFR + project-instruction file |
| glossary | `glossary.idx` | architecture-doc + READMEs |

**Adopter-specific classes** (not pre-covered) — e.g. RFC, design-spec, runbook, threat-model, data-dictionary, feature-spec, model-card, eval-report, incident-report, playbook, compliance-doc, prompt-library, skill-catalog, release-note. For these, `ai-engineer` follows the **novel-class recipe** (see `core/roles/ai-engineer.details.md § Project-doc extraction recipes`) and authors a new index file + records the inline recipe in `manifest.yaml`.

## Manifest shape

`local/index/manifest.yaml` records every detected doc class — built-in or novel — with sources, SHA-256, derived index files, and extraction recipe id.

```yaml
indexed:
  - class: architecture
    template: multi                       # multi-file output — see index-files
    recipe: builtin:architecture
    source: docs/architecture.md
    sha256: a3f5b8...c4d1
    indexed-on: 2026-05-17
    index-files: [architecture.idx, architecture-fr.idx, api-matrix.yaml, ui-states.yaml, constraints.yaml, glossary.idx]

  - class: scenario
    template: scenario-index.idx
    recipe: builtin:scenario
    source-glob: docs/scenarios/*.md
    file-count: 47
    sha256-by-file:
      docs/scenarios/login-happy.md: b7...
      docs/scenarios/login-fail.md: c9...
    indexed-on: 2026-05-17
    index-files: [scenario-index.idx]

  - class: rfc                           # adopter-declared, reuses ADR shape
    template: adr-index.idx
    recipe: builtin:adr
    source-glob: docs/rfcs/*.md
    file-count: 12
    sha256-by-file: { ... }
    indexed-on: 2026-05-17
    index-files: [rfc-index.idx]

  - class: runbook                       # novel; ai-engineer authored
    template: novel
    recipe: |
      Per file: extract title, alert id, severity, first-action step,
      escalation contact. Body NOT copied.
    source-glob: ops/runbooks/*.md
    file-count: 8
    sha256-by-file: { ... }
    indexed-on: 2026-05-17
    index-files: [runbook-index.idx]
```

- **Single-file sources** record one `sha256`.
- **Glob sources** record `sha256-by-file` so a single new/changed file flags only that subset.
- **`recipe`** is either a built-in id (`builtin:<class>`) or an inline recipe block (for novel classes).

## Lifecycle

### Initial extraction (discovery)

`project-manager` extends Step 8 of the discovery flow:

1. **Enumerate doc classes** to index in this priority order:
   1. Adopter-declared classes from `local/framework.config.yaml § index.classes`.
   2. Built-in classes matched by glob heuristics (architecture / adr / cr / scenario / mockup / constraints / glossary).
   3. Novel classes — any unmatched doc directory or doc-class hint.
2. **Dispatch `ai-engineer`** with the enumerated class list.
3. `ai-engineer`:
   - For built-in classes → applies the built-in recipe.
   - For novel classes → authors a new template at `core/templates/index/<class>-index.<ext>` (or directly populates `local/index/<class>-index.<ext>` without a sibling template if it's a one-off) AND records the inline recipe in `manifest.yaml`.
   - Computes SHA-256 per source.
   - Writes `local/index/manifest.yaml`.
4. `ai-engineer` runs the **lossless self-check** (see below).

### Pre-dispatch staleness check

`project-manager` extends `§ Auto-flag staleness`:

1. Identify which source docs the dispatched task may consume (based on role + task context).
2. For each, compute current SHA-256:
   - Bash: `sha256sum <file>` or `find <glob> -type f -exec sha256sum {} +`
   - PowerShell: `Get-FileHash -Algorithm SHA256 <file>`
3. Compare with `manifest.yaml` entry.
4. On any mismatch:
   - Flag staleness in PM's first response.
   - Offer:
     - **`@ai-engineer reindex <source>`** — targeted re-extraction for the changed source.
     - **`@project-manager rediscover`** — full re-discovery + re-extraction.
   - **Never auto-reindex.** User decides.

### Re-extraction

`ai-engineer` dispatched (by PM or explicit user invocation):

1. Read the changed source(s).
2. Re-extract per the recorded recipe (built-in id or inline novel recipe) → overwrite affected `local/index/*` files.
3. Update `manifest.yaml`:
   - New SHA-256.
   - New `indexed-on` date.
   - Same `index-files` (or add new ones if extraction surfaced a new index file).
4. Run lossless self-check on the affected entries.

## Lossless rule for index

- Every FR / NFR / endpoint / state / ADR / CR / scenario / record named in the source MUST have an entry in the index.
- Index entries MAY summarize but MUST cite source path + section anchor (or `file:line` ref for non-section sources).
- After extraction or re-extraction, `ai-engineer` runs **sample-and-check**:
  - Pick 5 random items per affected index file.
  - Verify the source still has them at the cited anchor.
  - If any cannot be verified → revert and re-plan.

## Role consumption pattern

Every role's "Source of truth" reads the index first; originals only on demand.

- `local/index/<file>` provides:
  - The signals the role needs (FR list, endpoint matrix, state set, ADR titles, etc.).
  - A `source` path + section anchor per entry.
- Role reads the source-doc section ONLY when:
  - The index entry says "see source for full statement" AND the role needs the verbatim wording.
  - The role is authoring new content (e.g. `qa-engineer` writing a new scenario file).

## Extension — adopter-declared classes

Adopters may pre-declare doc classes in `local/framework.config.yaml`:

```yaml
index:
  dir: local/index
  classes:
    - name: rfc
      source-glob: docs/rfcs/*.md
      template: adr-index.idx             # reuse ADR template shape
    - name: runbook
      source-glob: ops/runbooks/*.md
      template: novel                     # ai-engineer authors a new template
```

`project-manager` reads this block first during class enumeration. Takes precedence over auto-detection heuristics.

## Out of scope

- Automated checksum tooling beyond `sha256sum` / `Get-FileHash` invocations.
- True vector-store RAG (markdown-only baseline per D1 / D4).
- Cross-project index sharing.
- Auto-promotion of novel classes to built-in templates. May happen in future framework releases based on observed adopter patterns.
- Index pre-cooking on framework install. Adopters run `@project-manager rediscover` to build their first index.
