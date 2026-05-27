---
name: ginee-iterate
description: Relay a review-cycle user reply to the warm cardinal that owns the in-flight task, verbatim, instead of editing from the main thread. Use when the warm registry holds an active cardinal AND the reply targets in-flight files, OR when the user says 'iterate on @<role>', 'forward to the warm cardinal', 'pass this to <role>', or invokes `/ginee-iterate`.
---

# Iterate — relay review-cycle reply to warm cardinal

Thin wrapper. Skill-runner detects the live warm cardinal, `SendMessage`s the user reply unchanged, surfaces the return unsynthesized, hands back to `@team-lead` on stop-state. Main thread = relay only — skill-runner MUST NOT `Edit` / `Write` / `Bash(build|test)` when a warm cardinal owns the affected file domain.

## Activation

| Phrasing | |
|---|---|
| Auto-engage — warm registry non-empty AND reply targets in-flight files | |
| "Iterate on @<role>" / "forward this to @<role>" / "pass this to the warm cardinal" | |
| `/ginee-iterate` | |
| Stop — cardinal returns `Status: Done` AND acceptance criteria met (skill exits; team-lead resumes) | |

Warm registry source: `adapters/claude/install.md § Warm specialist reuse` (skill-runner-held on Claude; team-lead-held on adapters where team-lead has the resume tool). No-resume adapters → fall through to fresh-spawn per `migrations/warm-specialist-reuse.md § Forced-fresh triggers`.

## Procedure

1. **Detect live cardinal.** Read warm registry; identify cardinal whose `phase-participation:` window covers the in-flight phase AND whose owned file domain (per `local/bindings.md § Source-of-truth ownership`) covers the surface the reply targets. Multiple matches → hand back to `@team-lead` (routing decision); zero matches → hand back to `@team-lead` (no warm cardinal — fresh dispatch needed).
2. **Forward verbatim.** `SendMessage` the user reply unchanged to the named `agent-id` (raw id only per `adapters/claude/install.md § Warm specialist reuse § Known caveats`). Carry-forward anchor required per `adapters/claude/hooks/carry-forward-rules.yaml`; payload otherwise byte-identical to user text. Skill-runner MUST NOT paraphrase · summarise · add context · synthesize.
3. **Pass return through.** Surface the cardinal's response to the user unsynthesized. Schema-bound advisory per `core/templates/phase-report.md § Orchestrator behaviour` when the return misses self-lint; skill-runner MUST NOT restructure.
4. **Hand back.** Dispatch `@team-lead` per `core/process/dispatch.md § Skill-runner — surface boundary` when return carries any re-entry trigger:

   | Trigger | Source |
   |---|---|
   | `## Open issues` non-empty | cross-cardinal synthesis needed |
   | `## Hand-off` set | routing change — re-plan |
   | `Status: In-progress` / `Status: Blocked` | stop-state re-decision |
   | Cross-domain bug surfaced | `core/protocols/cross-domain-bugs.md` |
   | User reply targets surface outside warm cardinal's domain | routing change |

## Worked example — 5-reply frontend cycle

Warm registry: `{role: frontend-engineer, agent-id: fe-7a3, task: T#42, last-phase: 4}`. User reviewing a live mockup-cycle dispatch.

| # | User reply | Skill action | Cardinal return | Hand-back? |
|---|---|---|---|---|
| 1 | "fix the button colour" | `SendMessage fe-7a3` verbatim | `Status: Done` · patch landed | No — continue |
| 2 | "modal flashes on open" | `SendMessage fe-7a3` verbatim | `Status: Done` · patch landed | No — continue |
| 3 | "padding wrong on the form" | `SendMessage fe-7a3` verbatim | `Status: Done` · patch landed | No — continue |
| 4 | "header copy stale" | `SendMessage fe-7a3` verbatim | `Status: Done` · patch landed | No — continue |
| 5 | "ship it" | recognise acceptance signal — skill exits | n/a — Phase 8 close routes via `@team-lead` | Yes — `@team-lead` for delivery |

Outcome — 5 user replies · 5 `SendMessage`s · 0 main-thread `Edit` / `Write` / `Bash` ops. Context unchanged on the main thread; warm-reuse savings per `migrations/warm-specialist-reuse.md § Why` preserved.

## Forbidden

- Skill-runner MUST NOT `Edit` · `Write` · `MultiEdit` · `Bash(build|test runner|formatter)` from the main thread while a warm cardinal owns the affected file domain — full surface intent of T11 (`migrations/warm-cardinal-default.md`) + companion PreToolUse hook (deferred T11 sibling) per `core/process/dispatch.md § Skill-runner — surface boundary`.
- Skill-runner MUST NOT paraphrase · summarise · re-interpret · add context to the user reply before `SendMessage` — Step 2 is byte-verbatim forward; synthesis crosses the surface boundary.
- Skill-runner MUST NOT paraphrase · summarise · trim the cardinal return — pass through unchanged; format-only advisory per `core/templates/phase-report.md § Orchestrator behaviour`. MUST NOT re-dispatch for format.
- Skill-runner MUST NOT pick a default cardinal on multi-match / zero-match — hand back to `@team-lead` (routing is team-lead's surface per `core/process/dispatch.md § Skill-runner — surface boundary`).
- Skill-runner MUST NOT invent or re-use a stale `agent-id` — registry is read-only input; team-lead writes `agent-id`. Stale id → `SendMessage` fails → forced-fresh per `migrations/warm-specialist-reuse.md § Forced-fresh triggers § Adapter cannot deliver SendMessage`.
- Skill MUST NOT auto-engage when the reply belongs to a fresh task — pickup routes through `ginee-pick-up` per `core/skills/ginee-pick-up/SKILL.md`; this skill activates on **continuation** of a live cardinal task.
- Skill MUST NOT run on no-resume adapters as a no-op blocker — degrades transparently to fresh-spawn per `migrations/warm-specialist-reuse.md § Forced-fresh triggers § Adapter cannot deliver SendMessage`; user sees no behavioural change vs pre-iterate baseline.
- Skill MUST NOT extend across tasks — task close (Phase 8 accept / abandonment) clears the registry per `migrations/warm-specialist-reuse.md § Reuse contract`; next task is a fresh pickup.

Opt-out — `local/framework.config.yaml § compliance.disabled: [ginee-iterate-skill]`. Bypass per call — `SKIP_GINEE_COMPLIANCE=1`.
