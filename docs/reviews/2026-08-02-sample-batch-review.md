# Batch review - 2026-08-02 - sample build wave

Worked example of the autonomy batch-review list format.
The list is the run's gate journal: created when autonomy takes effect, appended at every gate in chronological order, so a run that dies mid-chain still leaves the record so far.
All four gate classes are logged; ASK and STOP entries are record-only (the human was present), BATCH and DEFAULT entries are the review obligation - accept or reverse each at the end-of-chain checkpoint.
Reversal cost is named honestly by gate type: a DEFAULT or commit reversal is cheap (`git revert`, or undoing the default); a BATCH taste reversal (topology, triage) is a scoped re-run, because the lean was a judgment call, not a fact.

| #   | Gate    | Obligation  | Decision                                                          | Rationale                                                                    | Reversal path                                                                         |
| --- | ---     | ---         | ---                                                               | ---                                                                          | ---                                                                                   |
| 1   | ASK     | record-only | Asked which repos the sprawl migration covers; answer: all three  | Only the human knows the intended migration scope                            | n/a - resolved live                                                                   |
| 2   | DEFAULT | review      | Auto-skipped the optional rubix review on the plan-draft unit     | The unit is internal and the plan was light; Step 6 rubix is optional        | Cheap: re-enable by running `/loop-review` on that diff; nothing committed to undo    |
| 3   | BATCH   | review      | Picked the worker-pool shape over per-task agents for wave 2      | Lower orchestration overhead; both shapes scored close (55/45)               | Scoped re-run: relaunch wave 2 with the per-task shape and compare the two outputs    |
| 4   | STOP    | record-only | Halted on a dirty pre-flight tree; human chose commit-and-go      | Dirty tree is a STOP invariant in every mode; only the human clears it       | n/a - resolved live                                                                   |
| 5   | DEFAULT | review      | Advanced unit `scripts/loop-auto.sh` after its validator exited 0 | Exit 0 is the only PASS; per-unit validator already gated correctness        | Cheap: `git revert <commit>` - the unit is self-contained and reverts cleanly        |
| 6   | BATCH   | review      | Slipped the spec-axis finding on the preflight exclusion          | The finding was advisory and non-blocking; slipping keeps advancement honest | Scoped re-run: promote that finding to blocking and re-run the affected unit's review |
| 7   | DEFAULT | review      | Auto-took the `high` effort cap for all units, no override asked  | `high` is the documented cap; exceeding it is a STOP, not the default        | Cheap: undo by lowering the cap for the next unit; no committed state to revert       |
| 8   | BATCH   | review      | Triaged the docs/handoffs stale-detection issue to the backlog    | Real but non-blocking; the wave's scope was the autonomy knob, not handoffs  | Scoped re-run: pull it off the backlog into this wave's plan and re-plan             |

## Notes on the format

- The journal starts at the moment autonomy takes effect and is appended per gate; a crashed run keeps every entry written so far.
- ASK and STOP rows are record-only chronology: they carry the context the neighboring auto-taken decisions were made in, and need no review.
- The review obligation is exactly the BATCH and DEFAULT rows: accept or reverse each one at the end-of-chain checkpoint.
- BATCH reversals are never a bare `git revert` - the lean was a judgment, so the honest reversal is to re-run the scoped step with the alternate lean and compare.
- DEFAULT and commit reversals are cheap and local: `git revert`, or simply undoing the default on the next pass.
- If a review row has no honest reversal path, that is a signal it should have been a STOP, not a BATCH or DEFAULT.
