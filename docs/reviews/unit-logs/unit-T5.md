# Unit T5 - triage report: per-run FAIL view with inline amendments

Branch: `T5-work` (worktree `~/.worktrees/ringer-T5`, based on `amend-command` at `cc491a8`)
Commit: `6ef3c17` "triage: read-only per-run FAIL view with inline amendments"

## What shipped

- `triage_run(rows, run_id) -> list[dict]` (ringer.py, before `class Verifier`)
  Partitions via `partition_amendments`, filters attempts to the given `run_id` with
  `verdict != "PASS"`, emits `{"task_key", "verdict", "check_excerpt", "amended", "amendment_note"}`.
  `check_excerpt` = `model_log_text(row.get("notes")).strip()`.
  `amendment_note` = `", ".join(notes_by_task.get((run_id, task_key), []))`, `""` when not amended.
  Read-only, no writes.
- `run_triage_command(config, args) -> int`
  Resolves log path exactly as `run_amend_command` does (`args.log` else
  `config.eval.jsonl_path.expanduser().resolve()`), reads via `read_model_log_rows`, calls
  `triage_run`, prints one line per FAIL attempt: `{task_key} {verdict} [amended|unresolved] {check_excerpt}`.
  Returns 0 always.
- `triage` subparser registered beside `amend_parser` (positional `run_id`, `--log` type=Path,
  help text verbatim from spec).
- Dispatch line added beside the `amend` dispatch in `main`.
- `tests/test_triage.py` - spec's verbatim RED test, unmodified.

## Test-first sequence

1. Wrote `tests/test_triage.py` verbatim from the spec.
2. `python3 -m unittest tests.test_triage -v` -> RED, confirmed
   `ImportError: cannot import name 'triage_run' from 'ringer'`.
3. Implemented `triage_run`, `run_triage_command`, subparser, dispatch.
4. `python3 -m unittest tests.test_triage -v` -> GREEN (1 test, ok).

## Smoke (spec Task 4 Step 4 fixture, recreated - was absent in this worktree)

Recreated `/tmp/amend-display.jsonl` via the spec's heredoc fixture, then ran:

```
./ringer.py triage r1 --log /tmp/amend-display.jsonl
```

Literal output:

```
[ringer] self-update: 38 commit(s) behind; current branch is T5-work, not main
t1 FAIL [amended]
```

The `t1 FAIL [amended]` line confirms the FAIL for `t1` prints with an amended marker as required.
The check_excerpt is empty because that fixture's FAIL row for `t1` carries no `notes` field (only
`task_type`, `verdict`, etc.) - this matches the fixture as given in the spec, not a bug in
`triage_run`.
The `[ringer] self-update` line is pre-existing unrelated ringer behavior on a non-main branch (git
history check), not something T5 touches.

## Full suite

Baseline stated: 264. Re-ran fresh in this worktree before any change: 264 passed, confirmed by
running `python3 -m unittest discover -s tests -v` before writing any code.
After T5: 265 passed (264 + 1 new `test_triage` test), 0 failures, 0 regressions.

## Deviations from spec

None. Interfaces, subparser, dispatch, and test file match the spec verbatim.

## Ambiguity resolved conservatively (flagged, not asked)

- **`amendment_note` join separator**: the spec says "the joined amendment notes" without naming a
  separator. The test only exercises a single-note case, so any separator passes. Used `", "` to
  match the multi-note display convention already used elsewhere in this codebase for note lists
  (matches Task 2/4's `amendments` list-of-notes pattern where notes are later joined for display,
  e.g. the display test's `" ".join(g["amendments"])` uses a space; `triage_run`'s `amendment_note`
  is a single string per entry so I chose comma-space for readability if a task ever accumulates
  multiple amendment notes). Low risk: single-note case (the only case in scope for this brief) is
  byte-identical either way.
- **CLI print format**: the spec says "prints one line per FAIL attempt with task_key, verdict, an
  amended marker, and the check excerpt" without specifying exact formatting. Chose
  `{task_key} {verdict} [amended|unresolved] {check_excerpt}` - space-delimited, consistent with
  `run_amend_command`'s plain-print style elsewhere in the file. No test pins this format (the RED
  test only exercises `triage_run`, not `run_triage_command`'s stdout), so this is free to adjust
  in Task 6's runbook if a different shape is wanted there.

## Open questions

None.

## Deferred items

None - Task 5 scope is fully shipped (T6/T7 are separate units, out of T5's ownership).
