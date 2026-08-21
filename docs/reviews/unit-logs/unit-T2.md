# Unit T2 - aggregation exclusion (JSONL path)

Branch: `T2-work` (off `amend-command`), worktree `~/.worktrees/ringer-T2`, repo `~/repos/ringer`.

## What shipped

Voided check-bug tasks are now excluded from both JSONL aggregators, numerator and denominator, and the amendment
count/notes ride along on the finalized dicts for the display layer (Task 4) to render.

- `partition_amendments(rows) -> (attempts, voided, notes_by_task)` new shared helper, placed just before
  `aggregate_model_log_rows` (ringer.py ~6072). `attempts` = every row with `type != "amendment"`; `voided` =
  `{(run_id, task_key)}` for check_bug amendments; `notes_by_task` = per-task note list for those same rows.
- `aggregate_model_log_rows`: groups `attempts` (never raw rows, F4), skips tasks in `voided` after incrementing
  the group's `amended`/`amendments`, and drops any group whose final `tasks == 0` (F6). Adds `amended` (int, 0)
  and `amendments` (list, []) to the initial group dict AND the finalized output dict (F3).
- `aggregate_model_scoreboard_rows`: same partition/void applied in the dual-target loop
  (`for target in (model_entry, breakdown)`, note `first_try_passed` no underscore). `amended`/`amendments` exposed
  on BOTH finalized dicts (model dict and each per-task-type breakdown dict). Fully-voided models dropped, and
  fully-voided per-type breakdown rows dropped from the `task_types` list.
- `read_model_log_rows`: the plain and `--since` branches already retained amendment rows (the F7 `logged_at`
  stamp keeps them past `--since`). Added one explicit passthrough so the `--engine` filter also keeps amendment
  rows (they carry no `worker_engine`, so the filter would otherwise silently drop them and un-void the task on any
  engine-scoped read). One-line guard, no behavior change for non-amendment rows.

## Test

`tests/test_amend_aggregation.py` - the spec's verbatim RED test.

RED (before implementation): 3 fail as predicted -
`test_amendment_lifts_first_try_and_is_visible` (`1.0 != 0.5`), `test_scoreboard_aggregator_also_excludes`
(`0.5 not less than 0.5`), `test_all_voided_group_is_dropped` (`True is not false`); `test_pre_amend_first_try_is_half`
passed (baseline).

GREEN: all 4 pass. Full suite `python3 -m unittest discover -s tests`: 261 OK (257 baseline + 4 new), zero regressions.

## Deviations

- **Field-name adjustment (per spec field-name note).** `aggregate_model_scoreboard_rows` exposes the per-task-type
  breakdown as a LIST under `"task_types"` (the `breakdown_rows` list, ringer.py ~7588), not a dict keyed by
  task_type. The verbatim test's `post_g["task_types"]["code-fix"]["tasks"]` would have raised `TypeError` on the
  list. Adjusted ONLY those two lookups via a local `_breakdown_tasks(model_group, task_type)` helper that finds the
  breakdown row by `task_type` and returns its `tasks`. Assertion unchanged (`self.assertEqual(pre_cf - 1, post_cf)`).
  No other test line touched, no assertion weakened.
- **Engine-filter passthrough added.** The spec said "add an explicit passthrough only if a filter still drops them."
  The plain and `--since` branches keep amendment rows unaided, but the `--engine` filter drops them (amendment rows
  have no `worker_engine`). Added the one-line guard so an engine-scoped read still voids the task. Conservative:
  keeps amendments, never removes a non-amendment row that was previously kept.

## Open questions

None blocking. The engine-filter passthrough decision is noted above; it is the correct-and-minimal reading of the
spec's conditional passthrough instruction.

## Deferred

None. Display of `amended`/`amendments` is Task 4; the SQLite read-model path is Task 3 - both out of T2 scope and
already sequenced in the plan.
