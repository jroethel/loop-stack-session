# Ringer amend command - Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes.
> No specific tooling, harness, or skills are assumed - just the `~/repos/ringer` checkout and Python.

**Goal:** Give ringer an append-only `amend` command that voids audited check-bug FAILs so the promotion math (`first_try_pass_rate` vs `PROVEN_MIN_FIRST_TRY`) stops blaming models for orchestration and check failures.

**Approach:** Append a typed amendment row `{"type":"amendment", run_id, task_key, reclassify, note, amended_at, identity, logged_at}` to `runs.jsonl`; aggregation collects amendments before grouping and drops every voided `(run_id, task_key)` task from both numerator and denominator, across both the JSONL path and the default `models` SQLite read-model path.
Void, never flip - an amended task is evidence-void, neither credit nor blame.
Whole-task granularity only; existing rows are never edited or deleted.

**Tech stack:** Python 3, single-file `ringer.py` (~11,200 lines), `argparse` subcommands, `unittest` + `tempfile` tests, JSONL log at `~/.ringer/runs.jsonl` with an optional SQLite read-model cache.

**Source brief:** `docs/briefs/2026-08-20-ringer-amend-brief.md` (in the loop-stack-session repo; this plan and its batch review live there, the code lands in `~/repos/ringer`).

## Global constraints

- Implementation lands in `~/repos/ringer/ringer.py` and `~/repos/ringer/tests/`; the plan artifact and batch review stay in the loop-stack-session repo.
- Append-only: never edit or delete any existing `runs.jsonl` row, ever (brief out-of-scope, hard rule).
- `--reclassify` ships exactly one accepted value: `check_bug`; leave the schema open but build no other value.
- Reuse the existing `resolve_identity()` (ringer.py:9454) for the amendment `identity`; do not invent an env/git-config path.
- No new dependencies, no pytest; match `ringer.py`'s existing style and the `tests/` `unittest` pattern.
- Whole-task void only; do not ship or stub an attempt-level filter key (YAGNI - append-only JSONL adds it later with no migration).
- The void must hold on BOTH read paths: the raw-JSONL aggregation AND the default `models` SQLite read-model (a plain `./ringer.py models` uses the read-model, not the JSONL - see Task 3).
- House style in docs: plain `-` never the em dash, one sentence per line, aligned pipe tables under 110 chars.

## Dependency graph

`ringer.py` is one shared file, so every code task that edits it is serialized - no two code tasks run in parallel.

```
Task 1 (amend cmd) -> Task 2 (JSONL math) -> Task 3 (models read-model path) -> Task 4 (display) -> Task 5 (triage)
Task 7 (upstream draft)  runs any time - different file, no code dependency
Task 6 (runbook) -> after Task 5 (it documents the shipped amend + triage commands)
```

Derived waves: {Task 1, Task 7}, then {Task 2}, then {Task 3}, then {Task 4}, then {Task 5}, then {Task 6}.
Tasks 6 and 7 touch only new doc files and never `ringer.py`, so they carry no shared-file race.

## Human checkpoints

- **HC-1 - real-data acceptance on RIT-UADV2223 (user's trigger).**
  The seven Section D amendments target `stm-nav-restructure` rows that live on host **RIT-UADV2223**, not on the build host RIT-UADV2213 (a disk check on the build host returns 0/7 for those run_ids; see the batch-review gate journal entry 7).
  So the seam-5 real-data proof cannot execute on the build host - it runs on RIT-UADV2223 after the feature ships there by `git pull`, guided by the Task 6 runbook.
  It mutates the source-of-truth eval log (append-only, reversible by deleting the appended lines), so per the owner safety rule the user fires it; this plan stages the exact seven commands and the three post-conditions in Task 6.

- **HC-2 - approve and post the upstream comment (user's trigger).**
  The `NateBJones-Projects/ringer#65` comment (Task 7) is an outbound send in the user's name and voice; the user approves the draft and fires the post.
  This is the brief's one `[judgment]` success criterion - it never lands on an executed-check task.

## How to run

```
cd ~/repos/ringer

# run a single test module (unittest, no pytest in this repo):
python -m unittest tests.test_amend -v
python -m unittest tests.test_amend_aggregation -v
python -m unittest tests.test_amend_models_db -v
python -m unittest tests.test_amend_display -v
python -m unittest tests.test_triage -v

# run the whole suite:
python -m unittest discover -s tests -v

# exercise the CLI against a scratch log (non-default path forces the JSONL branch):
./ringer.py amend <run_id> <task_key> --reclassify check_bug --note "why" --log /tmp/x.jsonl
./ringer.py triage <run_id> --log /tmp/x.jsonl
./ringer.py models --log /tmp/x.jsonl
./ringer.py models --log /tmp/x.jsonl --html /tmp/x.html
```

Tests import directly from the top-level module: `from ringer import ...` (matches `tests/test_model_log.py:14-28`).
The existing DB-path test fixture pattern to mirror in Task 3 lives in `tests/test_model_db.py`.

---

### Task 1: amend command - schema, append, idempotency

Depends on: none

**Files (exclusive ownership):**
- Modify: `~/repos/ringer/ringer.py` - add `append_amendment(...)` helper and `run_amend_command(config, args)`; register the `amend` subparser in `build_parser` (near ringer.py:11008, beside `models_parser`); add the dispatch line in `main` (near ringer.py:11114-11118).
- Create: `~/repos/ringer/tests/test_amend.py`

**Interfaces:**
- Produces `append_amendment(path, run_id, task_key, reclassify, note, identity, *, now=None) -> bool`
  - Reads existing lines from `path`; if any parsed row has `type == "amendment"` with a matching `(run_id, task_key, reclassify)`, returns `False` and appends nothing (idempotent no-op).
  - Otherwise appends exactly one line `json.dumps({...}, sort_keys=True) + "\n"` and returns `True`.
  - The row is `{"type":"amendment","run_id":run_id,"task_key":task_key,"reclassify":reclassify,"note":note,"amended_at":ts,"identity":identity,"logged_at":ts}` where `ts = now or <ISO8601 UTC now>`.
  - `logged_at` is stamped equal to `amended_at` so the `--since` filter in `read_model_log_rows` (ringer.py:6055-6068) never silently drops the amendment (finding F7).
  - Never rewrites or reorders existing lines (append with mode `"a"`, mirroring `_write_jsonl` at ringer.py:5884-5891).
- Produces `run_amend_command(config, args) -> int`
  - Resolves the log path from `args.log` if given, else `config.eval.jsonl_path.expanduser().resolve()` (mirror `run_models_command`, ringer.py:8563-8571).
  - Resolves identity via `resolve_identity(args.identity, config, [])` (mirror the `run` command's call; `--identity` already exists at ringer.py:10857).
  - Before appending, scans existing attempt rows; if no row has `(run_id, task_key)` matching the target, prints a non-fatal warning `warning: no recorded attempt matches <run_id> <task_key> - amending anyway (append-only)`, then still appends per the append-only rule (finding F8; the command trusts its caller but flags a likely typo).
  - Calls `append_amendment(...)`; prints `amended <run_id> <task_key> as <reclassify>` on `True`, or `no-op: <run_id> <task_key> already amended as <reclassify>` on `False`; returns 0.
  - Note (finding F9): idempotency is keyed on `(run_id, task_key, reclassify)`, so a re-amend with a corrected `--note` is a no-op that keeps the original note - amendment notes are immutable by design (get the note right the first time; a note-correcting amendment kind is a future addition, not this ship).
- Consumes: `resolve_identity` (ringer.py:9454), `config.eval.jsonl_path`, `AppConfig.load` (already wired in `main`).

**Subparser (register beside `models_parser`, ringer.py:11008):**
```
amend_parser = subparsers.add_parser("amend", help="append a check-bug reclassification to the eval log")
amend_parser.add_argument("run_id")
amend_parser.add_argument("task_key")
amend_parser.add_argument("--reclassify", choices=["check_bug"], required=True)
amend_parser.add_argument("--note", required=True, help="why the check was wrong (mandatory audit trail)")
amend_parser.add_argument("--identity", help="who is amending; falls through resolve_identity() if omitted")
amend_parser.add_argument("--log", type=Path, help="path to the eval JSONL log (overrides config)")
```
Dispatch (beside ringer.py:11117-11118): `if args.command == "amend": return run_amend_command(config, args)`.

**Acceptance check:** `cd ~/repos/ringer && python -m unittest tests.test_amend -v` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test (verbatim):
```python
import json
import tempfile
import unittest
from pathlib import Path

from ringer import append_amendment


class TestAmendAppend(unittest.TestCase):
    def test_append_then_idempotent(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "runs.jsonl"
            path.write_text(
                json.dumps({"run_id": "r1", "task_key": "t1", "model": "glm-5.2",
                            "verdict": "FAIL", "logged_at": "2026-07-01T10:00:00+00:00"}) + "\n",
                encoding="utf-8")
            before = path.read_text(encoding="utf-8")

            appended = append_amendment(path, "r1", "t1", "check_bug", "why", "tester",
                                        now="2026-07-02T00:00:00+00:00")
            self.assertTrue(appended)
            lines = path.read_text(encoding="utf-8").splitlines()
            self.assertEqual(2, len(lines))
            row = json.loads(lines[-1])
            self.assertEqual("amendment", row["type"])
            self.assertEqual("r1", row["run_id"])
            self.assertEqual("t1", row["task_key"])
            self.assertEqual("check_bug", row["reclassify"])
            self.assertEqual("why", row["note"])
            self.assertEqual("tester", row["identity"])
            self.assertEqual("2026-07-02T00:00:00+00:00", row["amended_at"])
            self.assertEqual("2026-07-02T00:00:00+00:00", row["logged_at"])  # survives --since
            self.assertEqual(before, lines[0] + "\n")  # original row byte-identical

            appended2 = append_amendment(path, "r1", "t1", "check_bug", "why", "tester",
                                         now="2026-07-03T00:00:00+00:00")
            self.assertFalse(appended2)  # same (run_id, task_key, reclassify) -> no-op
            self.assertEqual(2, len(path.read_text(encoding="utf-8").splitlines()))


if __name__ == "__main__":
    unittest.main()
```
- [ ] Step 2: Run `python -m unittest tests.test_amend -v` - expect FAIL with `ImportError: cannot import name 'append_amendment'`.
- [ ] Step 3: Implement `append_amendment`, `run_amend_command`, the subparser, and the dispatch line against the Interfaces block.
- [ ] Step 4: Run `python -m unittest tests.test_amend -v` - expect PASS. Then smoke: `./ringer.py amend r1 t1 --reclassify check_bug --note "why" --log /tmp/x.jsonl` twice and confirm the second call prints `no-op:`; run once with a bogus run_id against an empty `/tmp/y.jsonl` and confirm the `warning: no recorded attempt matches` line prints.
- [ ] Step 5: Commit - `cd ~/repos/ringer && git add ringer.py tests/test_amend.py && git commit -m "amend: append-only check-bug reclassification command"`

---

### Task 2: aggregation exclusion (JSONL path)

Depends on: Task 1

**Files (exclusive ownership):**
- Modify: `~/repos/ringer/ringer.py`
  - `read_model_log_rows` (ringer.py:6030) - confirm it retains `type == "amendment"` rows on both the plain and the `--since` branch (with the F7 `logged_at` stamp the since-branch keeps them; add an explicit passthrough if any filter still drops them).
  - `aggregate_model_log_rows` (ringer.py:6072) - apply the exclusion and expose the new group fields on the FINALIZED output dict (ringer.py:6161-6178).
  - `aggregate_model_scoreboard_rows` (ringer.py:7501) - apply the same exclusion in its dual-target loop (`for target in (model_entry, breakdown)`, ringer.py ~7567-7572; note it uses `first_try_passed` without the leading underscore) and expose the fields on BOTH finalized dicts (the model dict ~7610 and the per-task-type breakdown dict ~7591), so the tier math (`model_scoreboard_tier`, ringer.py:7489-7492, `PROVEN_MIN_FIRST_TRY` at ringer.py:3073) and the four task-type denominators shrink.
- Create: `~/repos/ringer/tests/test_amend_aggregation.py`

**Interfaces:**
- Produces a shared helper `partition_amendments(rows) -> tuple[list[dict], set[tuple[str, str]], dict[tuple[str, str], list[str]]]`
  - `attempts` = rows with `type != "amendment"`.
  - `voided` = `{(r["run_id"], r["task_key"]) for r in rows if r.get("type") == "amendment" and r.get("reclassify") == "check_bug"}`.
  - `notes_by_task` = `(run_id, task_key) -> [note, ...]` from those amendment rows.
- Both aggregators MUST group `attempts` (the partitioned list), never raw `rows` - an amendment row left in the grouping input self-groups into a phantom empty-`model` `(untyped)` FAIL task (finding F4).
- For each grouped task, compute `(run_id, task_key)` from its rows; if in `voided`, increment the group's `amended` count, extend its `amendments` note list, and skip the `tasks`/`passed`/first-try increments; otherwise count as today.
- Both finalized output dicts gain two keys: `amended` (int, default 0) and `amendments` (list of note strings, default `[]`) - add them to the explicit key list each aggregator builds, or they are dropped at finalization (finding F3). The enrichment layer copies the group dict (`dict(group)`, ringer.py ~6541), so once emitted the keys survive to display.
- A `(model, task_type)` group whose every task is voided ends with `tasks == 0`; such a group is DROPPED from the aggregator output (do not emit a `tasks==0, amended>0` row - it would feed `model_scoreboard_tier(0, 0.0)` a misleading 0% row, finding F6). Its amendment count stays reachable through the Task 5 triage view.
- Consumes: `read_model_log_rows` output rows (including amendment rows), the existing grouping helpers `group_model_log_tasks` / `model_log_task_base_key` (ringer.py:6000-6016).

**Illustrative insertion (the exact placement IS the decision; write against it, do not copy blindly):**
```python
# both aggregators: partition first, then group the ATTEMPTS (not raw rows).
attempts, voided, notes_by_task = partition_amendments(rows)
for task_rows in group_model_log_tasks(attempts):
    ordered = ...  # existing per-task ordering
    task_run_id, task_key = ordered[0].get("run_id"), ordered[0].get("task_key")
    if (task_run_id, task_key) in voided:
        group["amended"] = group.get("amended", 0) + 1
        group.setdefault("amendments", []).extend(notes_by_task.get((task_run_id, task_key), []))
        continue  # voided: evidence-void, drop from tasks / passed / first-try
    ...  # existing counting
# at finalization, add to the explicit output-dict key list:
#   "amended": group.get("amended", 0), "amendments": group.get("amendments", []),
# and drop any group whose final tasks == 0 (voided-only).
```

**Acceptance check:** `cd ~/repos/ringer && python -m unittest tests.test_amend_aggregation -v` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test (verbatim):
```python
import json
import tempfile
import unittest
from pathlib import Path

from ringer import (read_model_log_rows, aggregate_model_log_rows,
                    aggregate_model_scoreboard_rows)


def _base():
    # glm-5.2 code-fix: task t1 = first-try FAIL then retry PASS (the check-bug task);
    #                    task t2 = clean first-try PASS.
    return [
        {"run_id": "r1", "task_key": "t1", "worker_engine": "opencode", "model": "glm-5.2",
         "task_type": "code-fix", "verdict": "FAIL", "duration_ms": 100, "worker_tokens": 10,
         "retry": False, "logged_at": "2026-07-01T10:00:00+00:00"},
        {"run_id": "r1", "task_key": "t1", "worker_engine": "opencode", "model": "glm-5.2",
         "task_type": "code-fix", "verdict": "PASS", "duration_ms": 100, "worker_tokens": 10,
         "retry": True, "logged_at": "2026-07-01T10:05:00+00:00"},
        {"run_id": "r2", "task_key": "t2", "worker_engine": "opencode", "model": "glm-5.2",
         "task_type": "code-fix", "verdict": "PASS", "duration_ms": 100, "worker_tokens": 10,
         "retry": False, "logged_at": "2026-07-01T11:00:00+00:00"},
    ]


def _amendment():
    return {"type": "amendment", "run_id": "r1", "task_key": "t1", "reclassify": "check_bug",
            "note": "check was wrong", "amended_at": "2026-07-02T00:00:00+00:00",
            "logged_at": "2026-07-02T00:00:00+00:00", "identity": "tester"}


def _read(rows):
    with tempfile.TemporaryDirectory() as temp:
        path = Path(temp) / "eval.jsonl"
        path.write_text("\n".join(json.dumps(r) for r in rows) + "\n", encoding="utf-8")
        read_rows, _ = read_model_log_rows(path)
    return read_rows


class TestAmendmentExclusion(unittest.TestCase):
    def test_pre_amend_first_try_is_half(self):
        groups = aggregate_model_log_rows(_read(_base()))
        g = {(x["model"], x["task_type"]): x for x in groups}[("glm-5.2", "code-fix")]
        self.assertEqual(0.5, g["first_try_pass_rate"])  # t1 first FAIL, t2 first PASS
        self.assertEqual(0, g.get("amended", 0))

    def test_amendment_lifts_first_try_and_is_visible(self):
        groups = aggregate_model_log_rows(_read(_base() + [_amendment()]))
        by = {(x["model"], x["task_type"]): x for x in groups}
        g = by[("glm-5.2", "code-fix")]
        self.assertEqual(1.0, g["first_try_pass_rate"])  # t1 dropped; only t2 (first PASS) counts
        self.assertEqual(1, g["amended"])                # correction visible
        self.assertIn("check was wrong", " ".join(g["amendments"]))
        # the amendment row must NOT self-group into a phantom empty-model group (F4):
        self.assertFalse(any(x.get("model", "") == "" for x in groups))

    def test_scoreboard_aggregator_also_excludes(self):
        # the tier/HTML/per-type surface uses aggregate_model_scoreboard_rows (F2):
        pre = aggregate_model_scoreboard_rows(_read(_base()))
        post = aggregate_model_scoreboard_rows(_read(_base() + [_amendment()]))
        pre_g = {x["model"]: x for x in pre}["glm-5.2"]
        post_g = {x["model"]: x for x in post}["glm-5.2"]
        self.assertLess(pre_g["first_try_pass_rate"], post_g["first_try_pass_rate"])
        # the code-fix per-type denominator shrank by the one voided task:
        pre_cf = pre_g["task_types"]["code-fix"]["tasks"]
        post_cf = post_g["task_types"]["code-fix"]["tasks"]
        self.assertEqual(pre_cf - 1, post_cf)

    def test_all_voided_group_is_dropped(self):
        # a model whose only task is voided leaves no misleading 0% row (F6):
        rows = [
            {"run_id": "r9", "task_key": "t9", "worker_engine": "opencode", "model": "solo",
             "task_type": "docs", "verdict": "FAIL", "duration_ms": 1, "worker_tokens": 1,
             "retry": False, "logged_at": "2026-07-01T10:00:00+00:00"},
            {"type": "amendment", "run_id": "r9", "task_key": "t9", "reclassify": "check_bug",
             "note": "bad check", "amended_at": "2026-07-02T00:00:00+00:00",
             "logged_at": "2026-07-02T00:00:00+00:00", "identity": "tester"},
        ]
        groups = aggregate_model_log_rows(_read(rows))
        self.assertFalse(any(x["model"] == "solo" for x in groups))


if __name__ == "__main__":
    unittest.main()
```
> Field-name note: this test reads `post_g["task_types"]["code-fix"]["tasks"]` for the per-type breakdown.
> Confirm the real key names in `aggregate_model_scoreboard_rows` (the breakdown sub-dict, ringer.py ~7553-7603) and adjust only these two lookups if they differ - do not weaken the assertion.
- [ ] Step 2: Run `python -m unittest tests.test_amend_aggregation -v` - expect FAIL: `test_amendment_lifts_first_try_and_is_visible` reports `0.5 != 1.0` (or `KeyError: 'amended'`), and `test_scoreboard_aggregator_also_excludes` / `test_all_voided_group_is_dropped` fail because no exclusion is applied yet.
- [ ] Step 3: Add `partition_amendments`, group `attempts`, apply the void, add `amended`/`amendments` to both finalized dicts, and drop voided-only groups - in `aggregate_model_log_rows` AND `aggregate_model_scoreboard_rows`. Confirm/adjust `read_model_log_rows` keeps amendment rows on both branches.
- [ ] Step 4: Run `python -m unittest tests.test_amend_aggregation -v` - expect PASS. Then run the full suite `python -m unittest discover -s tests -v` and confirm no existing aggregation/scoreboard test regressed.
- [ ] Step 5: Commit - `cd ~/repos/ringer && git add ringer.py tests/test_amend_aggregation.py && git commit -m "amend: exclude voided tasks from JSONL scoreboard and tier math"`

---

### Task 3: models default path applies the void (SQLite read-model)

Depends on: Task 2

**Why this task exists:** a plain `./ringer.py models` (no `--log`) does NOT read the JSONL - `should_use_read_model_db` (ringer.py:6224-6232) returns `True` for the default log path, so `run_models_command` (ringer.py:8563-8572) serves rows from the SQLite read-model via `build_models_api_payload` -> `sync_read_model_db` -> `db_attempt_rows`.
That read-model has no amendment awareness (`insert_attempt_rows` ingests every JSONL line but the table has no `type` column; `db_attempt_rows` never returns `type`), so without this task the void is invisible on the exact command HC-1 verifies, and the amendment rows pollute the DB as phantom empty-model FAIL tasks (finding F1).

**Files (exclusive ownership):**
- Modify: `~/repos/ringer/ringer.py`
  - `should_use_read_model_db` (ringer.py:6224) OR `run_models_command` (ringer.py:8563) - force the JSONL path when the resolved log contains any amendment row (see mechanism below).
  - `insert_attempt_rows` / `sync_read_model_db` (ringer.py ~6805 / ~7092) - skip rows with `type == "amendment"` so the read-model never stores phantom attempt rows.
- Create: `~/repos/ringer/tests/test_amend_models_db.py`

**Interfaces / mechanism (chosen: force JSONL when amendments exist - the minimal correct fix):**
- Add `log_has_amendments(path) -> bool` - a cheap scan that returns `True` if any line of `path` contains an amendment row (substring test `'"type": "amendment"'` on `sort_keys=True` output is sufficient; no full JSON parse needed).
  - `# ponytail: line-scan the whole log; when amendments exist, models skips the DB fast-path and`
    `# reads the full JSONL. Fine at current log sizes (hundreds of rows); revisit if the log grows huge.`
- `should_use_read_model_db(...)` returns `False` (use JSONL) when `log_has_amendments(log_path)` is `True`, regardless of path equality - so the Task 2 JSONL exclusion runs and produces the correct `Amended` count and denominators.
- `insert_attempt_rows` skips `type == "amendment"` rows on ingest, keeping the read-model clean even if a later log has no amendments (belt and suspenders).
- Produces no new display contract; the `Amended` count and shrunk denominators now appear on the default `./ringer.py models` too.

**Acceptance check:** `cd ~/repos/ringer && python -m unittest tests.test_amend_models_db -v` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test. Mirror the temp-config / default-path fixture from `tests/test_model_db.py` (read that file first for its setup helper that makes a temp log resolve as the config default so the DB branch is taken). The test must:
  - build a default-resolved log containing the `_base()` glm-5.2 rows plus the `_amendment()` from Task 2's fixture;
  - drive the same code path `run_models_command` uses (e.g. `build_models_api_payload(config, ...)` with no explicit `--log` override, so `should_use_read_model_db` is consulted);
  - assert the glm-5.2 `code-fix` group in the payload shows `amended == 1` and `first_try_pass_rate == 1.0` (proving the void reached the default/DB-eligible path);
  - assert `log_has_amendments(<that log>) is True` and, for a control log with no amendment row, `is False`.
  Verbatim assertions to include once the fixture is wired:
```python
from ringer import log_has_amendments

# control: no amendments -> DB fast-path stays available
self.assertFalse(log_has_amendments(clean_log_path))
# with amendments -> forced JSONL, void applied on the default path
self.assertTrue(log_has_amendments(amended_log_path))
g = {(x["model"], x["task_type"]): x for x in payload_groups}[("glm-5.2", "code-fix")]
self.assertEqual(1, g["amended"])
self.assertEqual(1.0, g["first_try_pass_rate"])
```
- [ ] Step 2: Run `python -m unittest tests.test_amend_models_db -v` - expect FAIL: `ImportError` on `log_has_amendments`, and (once stubbed) the default-path group shows `amended == 0` / `first_try_pass_rate == 0.5` because the DB read-model ignores the amendment.
- [ ] Step 3: Implement `log_has_amendments`, wire it into `should_use_read_model_db`, and skip amendment rows in `insert_attempt_rows`.
- [ ] Step 4: Run `python -m unittest tests.test_amend_models_db -v` - expect PASS. Then the full suite `python -m unittest discover -s tests -v` - confirm no `test_model_db` regression.
- [ ] Step 5: Commit - `cd ~/repos/ringer && git add ringer.py tests/test_amend_models_db.py && git commit -m "amend: apply the void on the default models read-model path"`

---

### Task 4: display surfacing - Amended count and notes

Depends on: Task 3

**Files (exclusive ownership):**
- Modify: `~/repos/ringer/ringer.py`
  - `MODEL_SCOREBOARD_COLUMNS` (ringer.py:6196-6209) - add an `Amended` column.
  - `print_model_log_table` (ringer.py:8431) - widths tuple (ringer.py:8433) and values tuple (ringer.py:8457-8470) render `group["amended"]`.
  - HUD embedded JS `renderModels` (ringer.py:5276-5324, header cells ringer.py:5316-5320, body cells ringer.py:5294-5310) and the standalone `models --html` render (ringer.py:8200-8257) - add the `Amended` cell.
  - `enrich_model_groups_with_notes` (ringer.py:7351-7368) - fold `group["amendments"]` note text into the Notes tooltip so amendment reasons sit next to the MODEL-NOTES excerpts already shown there (ringer.py:5309 title tooltip).
- Create: `~/repos/ringer/tests/test_amend_display.py`

**Interfaces:**
- Consumes `group["amended"]` (int) and `group["amendments"]` (list[str]) produced by Task 2.
- Produces no new callable contract; the visible output gains an `Amended` column in the CLI table and both HTML tables, and the amendment reasons appear in the Notes tooltip.
- The `Amended` column is always present (renders `0` when a group has no amendments), so a header grep is stable.

**Acceptance check:** `cd ~/repos/ringer && python -m unittest tests.test_amend_display -v` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test (verbatim):
```python
import io
import json
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

import ringer
from ringer import MODEL_SCOREBOARD_COLUMNS


def _amended_log(path):
    rows = [
        {"run_id": "r1", "task_key": "t1", "worker_engine": "opencode", "model": "glm-5.2",
         "task_type": "code-fix", "verdict": "FAIL", "duration_ms": 100, "worker_tokens": 10,
         "retry": False, "logged_at": "2026-07-01T10:00:00+00:00"},
        {"run_id": "r1", "task_key": "t1", "worker_engine": "opencode", "model": "glm-5.2",
         "task_type": "code-fix", "verdict": "PASS", "duration_ms": 100, "worker_tokens": 10,
         "retry": True, "logged_at": "2026-07-01T10:05:00+00:00"},
        {"run_id": "r2", "task_key": "t2", "worker_engine": "opencode", "model": "glm-5.2",
         "task_type": "code-fix", "verdict": "PASS", "duration_ms": 100, "worker_tokens": 10,
         "retry": False, "logged_at": "2026-07-01T11:00:00+00:00"},
        {"type": "amendment", "run_id": "r1", "task_key": "t1", "reclassify": "check_bug",
         "note": "check was wrong", "amended_at": "2026-07-02T00:00:00+00:00",
         "logged_at": "2026-07-02T00:00:00+00:00", "identity": "tester"},
    ]
    Path(path).write_text("\n".join(json.dumps(r) for r in rows) + "\n", encoding="utf-8")


class TestAmendDisplay(unittest.TestCase):
    def test_amended_column_declared(self):
        self.assertIn("Amended", MODEL_SCOREBOARD_COLUMNS)

    def test_cli_table_has_header_and_group_carries_count(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "eval.jsonl"
            _amended_log(path)
            read_rows, skipped = ringer.read_model_log_rows(path)
            groups = ringer.aggregate_model_log_rows(read_rows)
            g = {(x["model"], x["task_type"]): x for x in groups}[("glm-5.2", "code-fix")]
            self.assertEqual(1, g["amended"])       # the value the column will render
            buf = io.StringIO()
            with redirect_stdout(buf):
                # real signature is (path, rows_read, skipped, groups) -- ringer.py:8431
                ringer.print_model_log_table(path, len(read_rows), skipped, groups)
            self.assertIn("Amended", buf.getvalue())  # header renders (the column exists)


if __name__ == "__main__":
    unittest.main()
```
- [ ] Step 2: Run `python -m unittest tests.test_amend_display -v` - expect FAIL: `"Amended" not in MODEL_SCOREBOARD_COLUMNS` (and no `Amended` header in the rendered table). If `print_model_log_table`'s real signature differs from `(path, rows_read, skipped, groups)`, correct only the test's call line to match ringer.py:8431.
- [ ] Step 3: Add the `Amended` column to `MODEL_SCOREBOARD_COLUMNS`, `print_model_log_table`, `renderModels`, the standalone HTML render, and fold amendment notes into `enrich_model_groups_with_notes`.
- [ ] Step 4: Run `python -m unittest tests.test_amend_display -v` - expect PASS. Then the HTML smoke check `[executed-check]`:
```
cd ~/repos/ringer
python - <<'PY'
import json, pathlib
rows = [
 {"run_id":"r1","task_key":"t1","worker_engine":"opencode","model":"glm-5.2","task_type":"code-fix","verdict":"FAIL","duration_ms":100,"worker_tokens":10,"retry":False,"logged_at":"2026-07-01T10:00:00+00:00"},
 {"run_id":"r1","task_key":"t1","worker_engine":"opencode","model":"glm-5.2","task_type":"code-fix","verdict":"PASS","duration_ms":100,"worker_tokens":10,"retry":True,"logged_at":"2026-07-01T10:05:00+00:00"},
 {"run_id":"r2","task_key":"t2","worker_engine":"opencode","model":"glm-5.2","task_type":"code-fix","verdict":"PASS","duration_ms":100,"worker_tokens":10,"retry":False,"logged_at":"2026-07-01T11:00:00+00:00"},
 {"type":"amendment","run_id":"r1","task_key":"t1","reclassify":"check_bug","note":"check was wrong","amended_at":"2026-07-02T00:00:00+00:00","logged_at":"2026-07-02T00:00:00+00:00","identity":"tester"},
]
pathlib.Path("/tmp/amend-display.jsonl").write_text("\n".join(json.dumps(r) for r in rows)+"\n")
PY
./ringer.py models --log /tmp/amend-display.jsonl --html /tmp/amend-display.html
grep -q "Amended" /tmp/amend-display.html \
 && grep -q "check was wrong" /tmp/amend-display.html \
 && echo "HTML Amended OK"
```
  Expect `HTML Amended OK` printed (the column header renders and the amendment note surfaces next to the MODEL-NOTES excerpts).
- [ ] Step 5: Commit - `cd ~/repos/ringer && git add ringer.py tests/test_amend_display.py && git commit -m "amend: surface Amended count and notes in scoreboard table and HTML"`

---

### Task 5: triage report - per-run FAIL view with inline amendments

Depends on: Task 4 (shared `ringer.py`; logical dependency is only Task 2's `partition_amendments`)

**Files (exclusive ownership):**
- Modify: `~/repos/ringer/ringer.py` - add `triage_run(rows, run_id)` and `run_triage_command(config, args)`; register the `triage` subparser (beside `amend`, near ringer.py:11008); add the dispatch line (near ringer.py:11114-11118).
- Create: `~/repos/ringer/tests/test_triage.py`

**Interfaces:**
- Produces `triage_run(rows, run_id) -> list[dict]`
  - Partitions amendments via `partition_amendments` (from Task 2).
  - For each attempt row whose `run_id` matches and whose `verdict` is not `PASS` (that is `FAIL`/`ERROR`/`TIMEOUT`), emits `{"task_key", "verdict", "check_excerpt", "amended": bool, "amendment_note": str}`.
  - `check_excerpt` = the row's `notes` field (which carries `raw_check_output_first_2000_chars: ...`, ringer.py:9251-9262), trimmed for display.
  - `amended` = `(run_id, task_key)` is in the voided set; `amendment_note` = the joined amendment notes for that task, else `""`.
  - Read-only: never writes; this is the brief's "per-run view shows each amendment inline next to its recorded FAIL" and the "read-only triage report" in one subcommand.
- Produces `run_triage_command(config, args) -> int` - resolves the log path (as in Task 1), reads rows via `read_model_log_rows`, calls `triage_run`, prints one line per FAIL attempt with task_key, verdict, an amended marker, and the check excerpt; returns 0.
- Consumes: `partition_amendments` (Task 2), `config.eval.jsonl_path`, `read_model_log_rows`.

**Subparser (beside `amend_parser`):**
```
triage_parser = subparsers.add_parser("triage", help="list a run's FAIL attempts with check context, for audit")
triage_parser.add_argument("run_id")
triage_parser.add_argument("--log", type=Path, help="path to the eval JSONL log (overrides config)")
```
Dispatch: `if args.command == "triage": return run_triage_command(config, args)`.

**Acceptance check:** `cd ~/repos/ringer && python -m unittest tests.test_triage -v` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test (verbatim):
```python
import unittest

from ringer import triage_run


class TestTriageRun(unittest.TestCase):
    def _rows(self):
        return [
            {"run_id": "r1", "task_key": "t1", "model": "glm-5.2", "verdict": "FAIL",
             "notes": "raw_check_output_first_2000_chars: grep failed",
             "retry": False, "logged_at": "2026-07-01T10:00:00+00:00"},
            {"run_id": "r1", "task_key": "t2", "model": "glm-5.2", "verdict": "PASS",
             "notes": "", "retry": False, "logged_at": "2026-07-01T10:05:00+00:00"},
            {"run_id": "rX", "task_key": "tZ", "model": "glm-5.2", "verdict": "FAIL",
             "notes": "other run", "retry": False, "logged_at": "2026-07-01T10:06:00+00:00"},
            {"type": "amendment", "run_id": "r1", "task_key": "t1", "reclassify": "check_bug",
             "note": "check was wrong", "amended_at": "2026-07-02T00:00:00+00:00",
             "logged_at": "2026-07-02T00:00:00+00:00", "identity": "tester"},
        ]

    def test_lists_only_this_run_fails_with_amendment_inline(self):
        report = triage_run(self._rows(), "r1")
        self.assertEqual(1, len(report))          # only r1's FAIL, not the PASS, not run rX
        entry = report[0]
        self.assertEqual("t1", entry["task_key"])
        self.assertEqual("FAIL", entry["verdict"])
        self.assertTrue(entry["amended"])
        self.assertEqual("check was wrong", entry["amendment_note"])
        self.assertIn("grep failed", entry["check_excerpt"])


if __name__ == "__main__":
    unittest.main()
```
- [ ] Step 2: Run `python -m unittest tests.test_triage -v` - expect FAIL with `ImportError: cannot import name 'triage_run'`.
- [ ] Step 3: Implement `triage_run`, `run_triage_command`, the subparser, and the dispatch line.
- [ ] Step 4: Run `python -m unittest tests.test_triage -v` - expect PASS. Then smoke against the display scratch log: `./ringer.py triage r1 --log /tmp/amend-display.jsonl` and confirm the FAIL for `t1` prints with an amended marker.
- [ ] Step 5: Commit - `cd ~/repos/ringer && git add ringer.py tests/test_triage.py && git commit -m "triage: read-only per-run FAIL view with inline amendments"`

---

### Task 6: runbook for the RIT-UADV2223 glm-5.2 cleanup

Depends on: Task 5

**Files (exclusive ownership):**
- Create: `~/repos/ringer/docs/handoffs/2026-08-20-glm-5.2-check-bug-cleanup-RIT-UADV2223.md`

**Interfaces:**
- Consumes: the shipped `amend` (Task 1), `triage` (Task 5), and `models` surfaces; no code contract.
- Produces: a standalone runbook, committed to the ringer repo so RIT-UADV2223 receives it by `git pull`.

**Content the runbook must contain (verbatim where noted):**
1. Resolve the log path on RIT-UADV2223 live - do not hardcode: read `state_dir` from that host's config, else default `~/.ringer/runs.jsonl`; every command below can override with `--log <path>`.
2. Record the before-state: `wc -l <log>` and `sha256sum <log>` (or `shasum -a 256`), and `./ringer.py models` for glm-5.2's current first-try and pass rates.
3. For each of the seven, first confirm the target FAIL exists with `./ringer.py triage <run_id> --log <log>` (guards against a mistyped run_id, finding F8), then apply the amendment. Apply exactly the seven below, and do NOT amend the Section B row `task-03-stm-guide-validate`:
```bash
cd ~/repos/ringer
./ringer.py amend stm-nav-restructure-20260718T032612Z-p359280 task-05-pipeline-trim-admin --reclassify check_bug --note "negative phrase-grep matched the requested link-out stub; allowlist grep matched a comment; work audited correct, committed 0c29bc7"
./ringer.py amend stm-nav-restructure-20260718T120157Z-p461404 task-09-condense-tableau --reclassify check_bug --note "repo-wide negative grep demanded a state the spec forbade; work audited correct, committed d72ca3c"
./ringer.py amend stm-nav-restructure-20260718T143419Z-p525993 task-17-dash-font-cleanup --reclassify check_bug --note "hybrid schema.html shell was outside every worker boundary; work correct, one-line gate fix, committed 5d7c2ba"
./ringer.py amend stm-nav-restructure-20260718T162712Z-p566096 task-18-schema-guide --reclassify check_bug --note "check transport bug (JSON-to-shell quoting); all steps green on gate re-run, committed 414979d"
./ringer.py amend stm-nav-restructure-20260718T180947Z-p600985 task-20-prose-list-measure --reclassify check_bug --note "whole-tree only-X-changed assertion hit the orchestrator's own uncommitted plan edit; rule correct, committed c7ae3a1"
./ringer.py amend stm-nav-restructure-20260718T131829Z-p489410 task-12-validate --reclassify check_bug --note "validator rubric encoded a stale orchestrator premise; artifact correct (spec-problem verdict), committed ce7c027"
./ringer.py amend stm-nav-restructure-20260718T174614Z-p595222 task-18-19-guide-validate --reclassify check_bug --note "accurate verdict rejected on output shape by the check; attempt-2 audit agreed with attempt-1's pass"
```
4. Verify the three post-conditions:
   - `./ringer.py models` shows an `Amended` count of 7 against glm-5.2's groups (this reads the default path; Task 3 makes the void apply there).
   - glm-5.2's first-try and pass rates for `site-build`, `docs`, `code-fix`, and `code-review` no longer count those seven tasks in their denominators (compare against the step-2 before-state).
   - `wc -l <log>` grew by exactly 7, and the sha256 of the original lines is unchanged (`head -n <before_count> <log> | sha256sum` equals the step-2 checksum) - proof no existing row was edited.
5. Confirm idempotency: re-run one of the seven `amend` commands and confirm it prints a `no-op:` message and the line count does not change.
6. Report the before/after glm-5.2 rates.
7. The broader 60%-rate cleanup (fresh per-row audit of other FAILs) is a separate session on RIT-UADV2223 and is out of scope for this runbook; use `./ringer.py triage <run_id>` to list a run's FAIL attempts with check context as the audit-assist entry point.

**Acceptance check:** the runbook exists and carries the seven commands, three post-conditions, and the live-path step `[executed-check]`:
```
f=~/repos/ringer/docs/handoffs/2026-08-20-glm-5.2-check-bug-cleanup-RIT-UADV2223.md
test -f "$f" \
 && [ "$(grep -c '^\./ringer\.py amend ' "$f")" -eq 7 ] \
 && grep -q "Amended" "$f" \
 && grep -q "sha256" "$f" \
 && grep -q "state_dir" "$f" \
 && grep -q "triage" "$f" \
 && echo "runbook OK"
```
Expect `runbook OK`.

- [ ] Step 1: Write the runbook file with the content above.
- [ ] Step 2: Run the acceptance check - expect `runbook OK`.
- [ ] Step 3: Commit - `cd ~/repos/ringer && git add docs/handoffs/2026-08-20-glm-5.2-check-bug-cleanup-RIT-UADV2223.md && git commit -m "handoff: glm-5.2 check-bug cleanup runbook for RIT-UADV2223"`
- [ ] Step 4: Hand to HC-1 - the user pulls on RIT-UADV2223 and fires the seven (user's trigger; see Human checkpoints).

---

### Task 7: upstream comment draft for ringer#65

Depends on: none

**Files (exclusive ownership):**
- Create: `~/repos/ringer/docs/ringer-65-comment-draft.md`

**Interfaces:**
- Consumes: nothing code-side.
- Produces: a draft comment for `NateBJones-Projects/ringer#65`, in the user's voice, crediting barthballard's generalization (the open-reclassify-set, one-audit-model schema), and noting that the shipped implementation lands `check_bug` as the single value with the schema left open.

**Draft must:**
- Credit barthballard by name for the generalization the shipped design adopts.
- State what shipped: an append-only `amend` command, whole-task void, `check_bug` as the only reclassify value, schema left open for future kinds.
- Read in the user's voice (action then mechanism then impact); no em dashes.

**Acceptance check:** the draft exists and credits barthballard `[executed-check]`:
```
f=~/repos/ringer/docs/ringer-65-comment-draft.md
test -f "$f" && grep -qi "barthballard" "$f" && grep -qi "check_bug" "$f" && echo "draft OK"
```
Expect `draft OK`.

- [ ] Step 1: Write the draft file.
- [ ] Step 2: Run the acceptance check - expect `draft OK`.
- [ ] Step 3: Commit - `cd ~/repos/ringer && git add docs/ringer-65-comment-draft.md && git commit -m "docs: draft upstream comment for ringer#65"`
- [ ] Step 4: Hand to HC-2 - the user approves and posts the comment (user's trigger; outbound send).

---

## Deferred and flagged (not silently dropped)

- **The standalone `db` subcommand's own views are out of scope.**
  Task 3 makes the void apply to the `models` command (which uses a SQLite read-model by default).
  The separate `db` subcommand's own report surfaces are a different consumer; the brief's success criteria cover `models`/HTML/triage, not the `db` subcommand, so its views are not touched here.
  If a `db`-subcommand scoreboard is later found to aggregate pass rates, it needs the same exclusion as a follow-up - flagged, not built.

- **Attempt-level amendment is not shipped.**
  Whole-task void only; no dormant attempt-filter key in the schema (parking-lot item, brief).

- **The broader RIT-UADV2223 60%-rate audit is out of scope** - runbook'd (Task 6, step 7), run there as its own session.
