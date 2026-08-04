# Batch review - tracker mode run (2026-08-04)

Gate journal for the autonomous drive of `docs/plans/2026-08-04-tracker-mode-plan.md`.
Autonomy mode: auto (session), set via `/loop-auto set auto` before launch.
No ASK gates exist in this chain, so autonomy took effect at launch.
BATCH and DEFAULT entries are the review obligation; ASK and STOP entries (if any) are record-only.

## Entries

### 1. [BATCH] Step 0 topology lean

- Decision: single 4-wave topology - W1 {T1, T2, T8}, W2 {T3, T4, T6}, W3 {T5}, W4 {T7}; T8 folded into wave 1 as an independent leaf; all units ringer transport.
- Rationale: the source plan's dependency graph forces this shape (T2 is the single seam, T5 needs T1+T2+T3, T7 needs T2-T5); no alternate shape was within 60/40 of it. Ringer is present, every unit is a self-contained bash/test task needing no in-session tools.
- Reversal path: scoped re-run with an alternate wave packing (cheap - waves are just manifest groupings; no work is lost by regrouping unfinished tasks).

### 2. [BATCH] Pin-review corrections to the compiled plan

- Decision: accepted the compiled `_loop.md` with three dispositions - (a) fixed the worker-commit contradiction (workers must NOT commit; the checks diff index vs HEAD); (b) reduced the per-wave MODEL-NOTES receipt obligation to signal-events-only; (c) accepted `Val. effort: check-only` in place of the skill's medium default.
- Rationale: (a) a committed worktree would export an empty patch and fail a correct worker; (b) the skill batches receipts for Agent-tool units only - all 8 units ride ringer, which feeds the scoreboard directly; (c) on ringer transport the executed check IS the validator, and the plan-supplied tests (verbatim assertions incl. the zero-gh stub proof) are stronger evidence than a model reviewer.
- Reversal path: (a)(b) `git revert` of the plan edit; (c) add a review subtask per gate-critical unit (Task 2, Task 5) on a scoped re-run if the gate audit finds the checks insufficient.

### 3. [DEFAULT] Pre-flight dirty-tree gate

- Decision: the only non-clean state at pre-flight was this journal file itself (untracked, created by the autonomy protocol at launch); committed it on the integration branch per repo-state's committed `docs/reviews/` lane, restoring a clean tree. No human-owned uncommitted work existed, so the STOP's protective trigger was absent.
- Rationale: the dirty-tree STOP protects uncommitted human work from loss or worktree exclusion; a run artifact whose provenance is this session, landing in its declared committed home, is bookkeeping, not a decision to escalate.
- Reversal path: `git revert` of the pre-flight commit.

### 4. [DEFAULT] Step 7 execution-details ask

- Decision: auto-took the default (no dashboard/dry-run/watch-points selection; launch immediately). The dry-run's substance still ran: pre-flight checklist executed for real, `ringer.py lint` on each manifest before its wave.
- Rationale: the Step 7 ask is a DEFAULT gate; autonomy takes the declared default and logs. Watch points remain in the plan's Section 9 for live tailing.
- Reversal path: n/a - informational gate; the same details are in `_loop.md` Sections 2, 3, and 9.

### 5. [BATCH] Wave-1 gate: accepted Task 8's out-of-ownership gate-registry refresh

- Decision: Task 8 attempt 1 failed its check because `tests/gates/check.sh` was pre-existing red - `docs/gate-registry.md` went stale at commit `57df13d` (rubix -> Rubix rename, generator never re-run). Attempt 2 regenerated the registry (outside its 3-file ownership) to satisfy the gate. Accepted the fix, re-verified by running `scripts/gen-gate-registry.sh .` on the integration branch (working tree matched generator output), and landed it as its own commit `2a9f89b`, separate from the Task 8 prose commit `182754a`.
- Rationale: the standing engineering rule is that pre-existing test failures get fixed when found; the file is auto-generated, so regeneration via its script is the only legitimate edit; splitting the commit keeps attribution honest (the staleness predates this run).
- Reversal path: `git revert 2a9f89b` (restores the stale registry; check.sh returns to red).

### 6. [record] Wave-1 gate: Task 1 ambiguity resolved conservatively by the worker

- Decision: the source plan told Task 1 to place the tracker prose "immediately after the autonomy-default: prose paragraph" in the template, but only `config/repo-state.md` carries that paragraph (pre-existing template/config drift). The worker placed the paragraph in the analogous structural slot near line 20 and did NOT add the missing autonomy-default paragraph (out of scope). Accepted at the gate; `tests/repo-state/config.sh` passes.
- Rationale: the conservative reading preserved existing drift rather than widening scope; the acceptance test constrains position by content, not line number.
- Reversal path: n/a - accepted as-is; the template/config autonomy-default drift is pre-existing and untouched.
