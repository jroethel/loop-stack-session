# Unit T1 - amend command: schema, append, idempotency

Branch: `T1-work` (worktree `~/.worktrees/ringer-T1`, based on `amend-command` at `cae12f7`)
Commit: `8d00995` - "amend: append-only check-bug reclassification command"

## What was done

Added to `ringer.py`:
- `append_amendment(path, run_id, task_key, reclassify, note, identity, *, now=None) -> bool`
  Inserted right after `run_models_command` (before `class Verifier`, ~line 8667).
  Reads existing rows via `read_model_log_rows(path)`, checks for a prior amendment row with
  matching `(run_id, task_key, reclassify)` and returns `False` (no-op) if found.
  Otherwise appends one `json.dumps(..., sort_keys=True) + "\n"` line in append (`"a"`) mode,
  mirroring `_write_jsonl` (ringer.py:5884). `logged_at` is stamped equal to `amended_at`
  (both `now` or `utc_now_iso()`), per finding F7 in the spec so `--since` never drops it.
- `run_amend_command(config, args) -> int`
  Resolves `log_path` from `args.log` or `config.eval.jsonl_path`, resolves identity via
  `resolve_identity(args.identity, config, [])` (empty identity_start_paths per the spec's
  Interfaces block - amend has no manifest/workdir context to seed repo-identity lookup, unlike
  `run`). Scans existing non-amendment rows for a `(run_id, task_key)` match; prints the
  `warning: no recorded attempt matches ...` line if none found, then always appends (append-only
  rule, finding F8). Prints `amended ...` or `no-op: ...` per `append_amendment`'s return value.
- `amend` subparser registered beside `models_parser` (ringer.py ~11008-11016), verbatim from the
  spec's Interfaces block.
- Dispatch line `if args.command == "amend": return run_amend_command(config, args)` added
  immediately after the `"models"` dispatch line (ringer.py ~11117-11119).

Created `tests/test_amend.py` with the spec's verbatim RED test (`TestAmendAppend.test_append_then_idempotent`).

## Checks run (this session, real output)

1. RED: `python3 -m unittest tests.test_amend -v` before implementation -
   `ImportError: cannot import name 'append_amendment' from 'ringer'` - matches spec prediction exactly.
2. GREEN: `python3 -m unittest tests.test_amend -v` after implementation - `Ran 1 test ... OK`.
3. Full suite: `python3 -m unittest discover -s tests -v` - `Ran 257 tests ... OK` (0 failures, no
   regressions in any pre-existing test).
4. CLI smoke (spec Step 4), against `/tmp/t1-smoke.jsonl` and `/tmp/t1-warn.jsonl`:
   - `./ringer.py amend r1 t1 --reclassify check_bug --note "why" --log /tmp/t1-smoke.jsonl` (1st call)
     -> printed `amended r1 t1 as check_bug`.
   - Same command again -> printed `no-op: r1 t1 already amended as check_bug`.
   - Bogus run/task against an empty `/tmp/t1-warn.jsonl` -> printed
     `warning: no recorded attempt matches bogus-run bogus-task - amending anyway (append-only)`,
     then still appended (append-only rule honored).
   - Resulting JSONL rows inspected directly: both contain `type":"amendment"`, correct
     `run_id`/`task_key`/`reclassify`/`note`/`identity`/`amended_at`/`logged_at` fields.

## Deviations from spec

None. Anchors were verified against the live tree before editing (`resolve_identity` at
ringer.py:9454 matched exactly; `models_parser` block at ringer.py:11008-11022 matched; the
`"models"` dispatch line was at ringer.py:11117-11118, matching the spec's stated anchor). The
`append_amendment`/`run_amend_command` insertion point (end of `run_models_command`, before
`class Verifier`) was chosen by me since the spec only said "add" without a precise line - this
groups the new command logic next to the sibling `models` command, consistent with existing file
organization (command handlers are defined in sequence, followed by their supporting classes).

## Open questions / ambiguities

None encountered that required a conservative-reading call beyond the insertion-point choice
above, which is a straightforward, low-risk placement decision (matches the pattern of related
command functions living near each other) and does not affect behavior or the public interface.

## Deferred items

Out of scope for T1 per the plan's dependency graph: aggregation exclusion (Task 2), the SQLite
read-model void (Task 3), display surfacing (Task 4), and triage (Task 5) all depend on this task
and are not implemented here.
