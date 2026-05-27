---
description: Insert the phase-report.md schema skeleton (ready to fill). Use at the end of a cardinal dispatch to compose the return.
argument-hint: [optional context]
---

Compose your return per `core/templates/phase-report.md` — fill every required section (use `(none)` for empty), run the 7 mandatory checks, end with `<!-- self-lint: pass -->`.

$ARGUMENTS

Skeleton:

```
Status: Done | In-progress | Blocked | Hand-off

## Files touched                                     (table or (none))
| Path | Δ lines | Purpose |
|---|---|---|
| `<path>` | `+N / -M` | `<one-line why>` |

## Decisions made                                    (bullets or (none))
- `<short imperative>` — `<FR-NN-slug | NFR-NN-slug | ADR-NNNN-slug | mockup §X>`

## Verification log                                  (table; required)
| Command / check | Outcome |
|---|---|
| `<command>` | `<exit code / pass-fail / count>` |

## Open issues                                       (bullets or (none))
- `<issue>` — `<owner / blocker>`

## Next dispatch needed                              (one-line or (none))
- `<role> · <surface> · <reason>`

## Source reads (this dispatch)                      (table or (none))
| Path | Justification | Index entry consulted |
|---|---|---|

## Hand-off                                          (when Status: Hand-off — per core/templates/hand-off-note.md)
## Stop-state                                        (when Status: In-progress — Done/In-progress/Not-started)
## Time spent                                        (when sub-issue mode — <H>h <M>m perceived; <N> progress comments on #<M>)
## Notes                                             (optional · ≤ 200 words)

<!-- self-lint: pass -->
```

Run the 7 mandatory checks per `core/templates/phase-report.md § Mandatory checks before report-as-done` before writing the marker.

## Engineer self-verify (frontend / backend / devops at Phase 4)

Strict gate per `core/protocols/engineer-self-verify.md`. `## Verification log` MUST carry exactly one row per available-matrix suite (form: `PASS` · `n/a — <reason>` · `stale — <contract change>; QA oracle update needed`). Per-role row skeleton — fill or skip-cite for every row your change exercises:

```
## Verification log
| Command / check | Outcome |
|---|---|
# frontend-engineer
| Component unit (<runner>) | PASS / n/a — <reason> / stale — <reason> |
| E2E hitting changed surface (<runner>) | PASS / n/a — <reason> / stale — <reason> |
| Pixel-check (when qa.pixel-check.enabled) | PASS / n/a — <reason> / stale — <reason> |

# backend-engineer
| Unit per § Coverage obligation (<runner>) | PASS / n/a — <reason> / stale — <reason> |
| API / functional vs real local stack (<runner>) | PASS / n/a — <reason> / stale — <reason> |
| Integration covering touched endpoints / migrations | PASS / n/a — <reason> / stale — <reason> |

# devops-engineer
| Script lint + Pester / bats per § Script-quality obligation | PASS / n/a — <reason> / stale — <reason> |
| Local-orchestration post-step health per § Post-step health verification | PASS / n/a — <reason> / stale — <reason> |
| Deploy smoke against reachable environments | PASS / n/a — <reason> / stale — <reason> |
```

Stale-oracle row MUST surface `qa-engineer · <suite>` under `## Next dispatch needed`. Engineer MUST NOT edit the test to make it pass — QA owns the oracle update per `core/roles/qa-engineer.md § Independent re-execution`.
