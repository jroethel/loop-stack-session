# Batch review - 2026-08-02 - sample build wave

Worked example of the autonomy batch-review list format.
Each entry is one auto-taken decision from a chain run under `auto` mode: the decision, the rationale, and its reversal path.
Reversal cost is named honestly by gate type: a DEFAULT or commit reversal is cheap (`git revert`, or undoing the default); a BATCH taste reversal (topology, triage) is a scoped re-run, because the lean was a judgment call, not a fact.

| #   | Gate    | Decision                                                            | Rationale                                                                     | Reversal path                                                                          |
| --- | ---     | ---                                                                 | ---                                                                           | ---                                                                                    |
| 1   | DEFAULT | Auto-skipped the optional rubix review on the plan-draft unit       | The unit is internal and the plan was light; Step 6 rubix is optional         | Cheap: re-enable by running `/loop-review` on that diff; nothing committed to undo     |
| 2   | BATCH   | Picked the worker-pool shape over per-task agents for wave 2        | Lower orchestration overhead; both shapes scored close (55/45)                | Scoped re-run: relaunch wave 2 with the per-task shape and compare the two outputs     |
| 3   | DEFAULT | Advanced unit `scripts/loop-auto.sh` after its validator exited 0   | Exit 0 is the only PASS; per-unit validator already gated correctness         | Cheap: `git revert <commit>` - the unit is self-contained and reverts cleanly         |
| 4   | BATCH   | Slipped the spec-axis finding on the preflight exclusion to review  | The finding was advisory and non-blocking; slipping keeps advancement honest  | Scoped re-run: promote that finding to blocking and re-run the affected unit's review  |
| 5   | DEFAULT | Auto-took the `high` effort cap for all units, no override asked    | `high` is the documented cap; exceeding it is a STOP, not the default         | Cheap: undo by lowering the cap for the next unit; no committed state to revert        |
| 6   | BATCH   | Triaged the docs/handoffs stale-detection issue to the backlog      | Real but non-blocking; the wave's scope was the autonomy knob, not handoffs   | Scoped re-run: pull it off the backlog into this wave's plan and re-plan              |

## Notes on the format

- An entry exists only for a decision the chain auto-took under `auto` mode; gates that fired live under `pause` are not listed here.
- BATCH reversals are never a bare `git revert` - the lean was a judgment, so the honest reversal is to re-run the scoped step with the alternate lean and compare.
- DEFAULT and commit reversals are cheap and local: `git revert`, or simply undoing the default on the next pass.
- If an entry has no honest reversal path, that is a signal it should have been a STOP, not a BATCH or DEFAULT.
