# GitHub integration — issues + discussions

**Load-on-demand.** Fetched when:

- `project-manager` is dispatched to **file** an issue (`@project-manager file bug` / `file feature`).
- `project-manager` is dispatched to **pick up** an issue (`@project-manager pick up #<N>`).
- `project-manager` is dispatched to **triage** ready issues (`@project-manager triage`).
- `project-manager` is dispatched to **promote** a discussion to an issue (`@project-manager promote discussion #<N>`).
- A specialist needs to post phase-transition progress on a tracking issue mid-task.

Default short tasks (TODO / direct instruction sources) do not load this file.

## Why

Two-way bridge between an adopter's GitHub repo and the framework's task model:

- Adopters file work in the platform they already use (issues, discussions).
- Framework picks issues up, runs them through the standard Phase 1–8 lifecycle, and closes the loop with issue comments + PR linkage.
- TODO files remain a valid task source — both coexist.

## Tool surface

Framework spec is tool-agnostic. Roles use whichever GitHub access is available in the current session, in this priority:

1. **`gh` CLI** — baseline; expected on most adopter dev environments.
2. **GitHub MCP server** — when connected; better tool-use ergonomics in supporting clients.
3. **Generic HTTPS + token** — fallback for environments lacking either.

Commands referenced below use `gh` syntax. Substitute equivalents as needed; never invent a third mechanism.

## Repo discovery

Priority order:

1. **Override.** `local/framework.config.yaml § github.repo: <owner>/<repo>` wins when set.
2. **Inference.** `git remote get-url origin` → strip trailing `.git` → map to `<owner>/<repo>`.
3. **Multi-remote.** Use `origin` unless overridden.
4. **No remote / detached.** PM surfaces the gap; offers to add the override key.

## Label scheme (configurable)

Defaults declared under `local/framework.config.yaml § github`:

| Config key | Default | Meaning |
|---|---|---|
| `ready-label` | `engineering-team:ready` | Pickup candidate (`☐` equivalent). |
| `in-progress-label` | `engineering-team:in-progress` | PM has dispatched; phases 1–7 in flight. |
| `blocked-label` | `engineering-team:blocked` | Stoppable intermediate state; waiting on user / external. |

PM creates any missing label on first use via `gh label create <name>` (default color). "Done" is implicit — issue closed.

## State mapping

| GitHub state | Framework phase | TODO equivalent |
|---|---|---|
| Open, no framework labels | Unpicked-up — sits in adopter's idea/triage queue | n/a |
| Open + `ready-label` | Phase 1 pickup candidate | `☐` |
| Open + `in-progress-label` | Phase 1–7 in flight | mid-task |
| Open + `blocked-label` | Stoppable intermediate; awaiting user/external | mid-task, paused |
| Closed | Phase 8 accepted | `☒` |

## Outbound — file an issue

Trigger: `@project-manager file bug <title>` / `@project-manager file feature <title>` / explicit user ask to create an issue.

1. PM picks the template:
   - Bug → `core/templates/issues/bug-report.md`.
   - Feature → `core/templates/issues/feature-request.md`.
2. PM drafts the body — populates structured sections (`## Summary` / `## Steps to reproduce` / `## Affected area` / `## FR / NFR cited` / `## Acceptance criteria` / `## Out of scope`) from user input + project context.
3. **PM surfaces the draft to the user for approval.** Issue creation is externally visible — per `core/process.md § Executing actions with care`, always confirm before publishing.
4. On approval, PM runs:
   ```
   gh issue create --repo <repo> --title <T> --body <B> --label <ready-label>
   ```
   (or MCP equivalent).
5. PM reports the issue URL + number in the final response.

## Inbound — pick up an issue

Trigger: `@project-manager pick up #<N>`. **Never auto-picks.**

1. Fetch:
   ```
   gh issue view <N> --repo <repo> --json title,body,labels,state,comments
   ```
2. Validate:
   - State must be `OPEN`.
   - Labels include `ready-label` — if absent, PM offers to add it before pickup.
3. Parse the structured body per the template sections. Map `affected area` → routing per `local/bindings.md`.
4. Swap labels:
   ```
   gh issue edit <N> --remove-label <ready-label> --add-label <in-progress-label>
   ```
5. Run Phase 1 analysis treating the parsed issue body as the task description. Standard Phase 1–8 dispatch from here.
6. **Comment cadence** — PM posts a structured comment at each major transition:

   | Trigger | Comment shape |
   |---|---|
   | Phase 3 design review surfaced | Architecture-doc diff link + mockup link + work-breakdown + "awaiting approval" |
   | Phase 7 SA review outcome | APPROVE / RETURN-TO-engineer + findings list |
   | Phase 8 acceptance | Summary + PR/commit links + "closing on accept" |
   | Stoppable intermediate state (user paused) | Current phase + done/in-progress/not-started lists |

   Comments are structured summaries, not chatty. One per transition.
7. On Phase 8 acceptance, PM closes the issue:
   ```
   gh issue close <N> --repo <repo> --comment "<final summary + PR links>"
   ```

## Triage — list ready issues

Trigger: `@project-manager triage`.

1. List:
   ```
   gh issue list --repo <repo> --label <ready-label> --state open --json number,title,labels,createdAt
   ```
2. Surface as a table — number / title / age / labels.
3. Propose a pickup order based on:
   - Age (older first, modulo new urgent items).
   - Apparent scope (bug-fixes typically shorter than feature work).
   - Cross-references with active TODO work (avoid context-switch thrash).
4. User picks one (or several). PM runs the pickup flow for each.

Triage **never picks**. It only enumerates and proposes.

## Promote — discussion → issue

Trigger: `@project-manager promote discussion #<N>`.

1. Fetch the discussion:
   ```
   gh api repos/<owner>/<repo>/discussions/<N>
   ```
   (or MCP Discussions API equivalent).
2. Read body + top comments — extract:
   - The proposed change.
   - Open questions raised in comments.
   - Any rough acceptance criteria mentioned.
3. Draft an issue using the appropriate template. Title links to the discussion: `Promoted from discussion #<N>: <title>`. Body includes a `## Source` section: `Discussion: https://github.com/<owner>/<repo>/discussions/<N>`.
4. Surface the draft for user approval.
5. On approval, create the issue **and** comment on the discussion linking to the new issue:
   ```
   gh issue create ...                        # → issue #M
   gh api repos/<owner>/<repo>/discussions/<N>/comments \
      --field body="Promoted to issue #<M>"
   ```

## PR linkage

When a task is issue-sourced, every resulting PR description includes a `Closes #<N>` line (or `Fixes #<N>` for bug-report issues). GitHub auto-closes the issue on merge. PM verifies this line is present before approving Phase 8.

Template carries this: `core/templates/pr-description.md § Issue linkage`.

## Forbidden actions

- **Never silently create / close / re-open an issue.** Each requires explicit user approval per `core/process.md § Executing actions with care` — issues are externally visible.
- **Never bulk-close stale issues.** Stale-issue cleanup is an adopter-owned policy, not framework work.
- **Never assign issues to GitHub users.** Specialists aren't GitHub users; assignment stays manual.
- **Never edit another author's issue body.** PM may add comments and labels; the body is reporter-owned.
- **Never auto-pick up issues on session start.** Pickup is always explicit (`pick up #<N>` or `triage` → user selects).
- **Never federate across repos.** One repo per `github.repo` config; cross-repo coordination is out of scope.

## Out of scope

- Pull requests as a task source (PRs are work output, not work input).
- Webhook / event-driven pickup. Pickup is explicit on user invocation.
- Issue auto-labelling on body keywords. Adopters use GitHub's own automation for that.
- Auto-creating custom-coloured labels. Framework creates labels with default color when absent; recolouring is an adopter task.
- Cross-repo issue federation.
- Issue assignment to specialists (specialists aren't GitHub users).
- Discussions as a direct task source. They must be promoted to an issue first.
