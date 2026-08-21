# Unit T3 - models default path applies the void (SQLite read-model)

Branch: `T3-work` (off `amend-command`), worktree `~/.worktrees/ringer-T3`, repo `~/repos/ringer`.
Commit: `f0d7d57` - "amend: apply the void on the default models read-model path"

## What shipped

A plain `./ringer.py models` (no `--log`) serves the SQLite read-model, which had no amendment
awareness; this task closes that gap so the void holds on the exact command HC-1 verifies.

- `log_has_amendments(path) -> bool` - new helper placed just before `should_use_read_model_db`
  (ringer.py ~6263). Line-scans the raw log text for the substring `'"type": "amendment"'` (the
  literal text `append_amendment`'s `json.dumps(..., sort_keys=True)` already produces - no JSON
  parse needed). Carries the spec's verbatim `ponytail:` comment naming the ceiling (whole-log line
  scan; fine at hundreds of rows; revisit if the log grows huge).
- `should_use_read_model_db(...)` - added one early-return: `if log_has_amendments(log_path): return
  False`, ahead of the existing `explicit_db` and path-equality checks, so an amended log is forced
  onto the JSONL path regardless of `--db` or path equality (per spec: "regardless of path
  equality"). Both call sites (`build_models_api_payload` and `run_models_command`) already resolve
  `log_path` before calling this function, so no extra resolution was needed here.
- `insert_attempt_rows(conn, rows)` - added a one-line skip (`if row.get("type") == "amendment":
  continue`) before building the insert payload, so amendment rows never become phantom
  empty-model FAIL rows in the `attempts` table (belt-and-suspenders per the spec; the
  `should_use_read_model_db` fix alone is the load-bearing change since the DB path is now bypassed
  whenever amendments exist, but this keeps the table clean if a caller inserts directly).

## Test

`tests/test_amend_models_db.py` - one test, `test_default_path_applies_the_void`, built by mirroring
`tests/test_model_db.py`'s temp-`HOME`/`RINGER_HOME` fixture pattern (read that file first, per the
spec) and reusing the `_base()`/`_amendment()` row shapes from `tests/test_amend_aggregation.py`
(Task 2's fixture). Drives `build_models_api_payload(log_path=..., default_log_path=..., db_path=None,
...)` with `log_path == default_log_path` and no explicit `db_path`, which is the exact condition
`run_models_command` produces when `--log` is omitted - so `should_use_read_model_db` is genuinely
consulted, not bypassed. Includes the spec's verbatim assertion block (control `clean_log_path` /
`amended_log_path`, `log_has_amendments` True/False, `g["amended"] == 1`,
`g["first_try_pass_rate"] == 1.0`).

RED (before implementation): `ImportError: cannot import name 'log_has_amendments' from 'ringer'` -
matches the spec's predicted first failure exactly.

GREEN: `python3 -m unittest tests.test_amend_models_db -v` - `Ran 1 test ... OK`.

Full suite: `python3 -m unittest discover -s tests -v` - `Ran 262 tests ... OK` (261 baseline + 1 new
test method, zero regressions). `tests/test_model_db.py` specifically re-run standalone: `Ran 11
tests ... OK`.

## Additional verification (beyond the acceptance check)

Ran the real CLI end to end in an isolated `HOME`/`RINGER_HOME` temp sandbox (not the unit test, the
actual `./ringer.py models --json` binary) against a default-resolved log
(`$HOME/.ringer/runs.jsonl`) containing `_base() + [_amendment()]`. Output confirmed
`"tasks": 1, "amended": 1, "first_try_pass_rate": 1.0` for the glm-5.2 code-fix group - the void
reaches the literal `./ringer.py models` command with no `--log` flag, which is what HC-1 depends on.
Temp sandbox removed after the check; no state written outside `/tmp`.

## Deviations

- The spec's Step 1 example call was written as `build_models_api_payload(config, ...)`; the real
  signature (ringer.py:8540) takes `log_path`, `default_log_path`, `db_path`, `catalog_path`,
  `registry_path`, `notes_path` directly - no `config` object. Called it with the real signature;
  no behavior or assertion changed, this is the same "no explicit `--log` override" condition the
  spec describes (`log_path == default_log_path`, `db_path=None`).
- Wrote a minimal self-contained registry/catalog fixture (`glm-5.2` under `engines.opencode`,
  matching the `_base()` fixture's `model` field) rather than importing helpers from
  `tests/test_model_db.py`, since ownership for this unit is `tests/test_amend_models_db.py` only
  and the spec says "mirror the pattern," not share the module.

## Open questions

None blocking.

## Deferred

None. Display of the `Amended` column (Task 4) and triage (Task 5) are out of T3 scope and already
sequenced next in the plan.
