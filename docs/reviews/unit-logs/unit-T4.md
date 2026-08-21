# Unit T4 - display surfacing: Amended count and notes

Branch: `T4-work` (off `amend-command`), worktree `~/.worktrees/ringer-T4`, repo `~/repos/ringer`.
Commit: `02b944b` - "amend: surface Amended count and notes in scoreboard table and HTML"

## What shipped

An `Amended` column, always present (renders `0` on unamended groups), added to every scoreboard
surface, plus amendment reasons folded into the existing Notes tooltip next to the MODEL-NOTES
excerpts. Verified each spec line anchor against the actual tree by symbol name first (T2/T3 had
already shifted line numbers) - all five target symbols were found and matched the spec's
description of their role.

- `MODEL_SCOREBOARD_COLUMNS` - inserted `"Amended"` between `"Pass"` and `"Tokens (median)"`.
- `print_model_log_table` - `widths` tuple gained one entry (`8`) at the matching position; the
  `values` tuple gained `fmt_int(group.get("amended", 0))` at the matching position.
- HUD embedded JS `renderModels` - header cells gained `<th class="numeric">Amended</th>`; body
  cells gained `<td class="numeric">${numberOrZeroLocal(row.amended).toLocaleString()}</td>`
  (reuses the existing `numberOrZeroLocal` helper, which already treats `undefined` as `0`, so
  the always-present-0 contract holds for pre-amendment rows too). The breakdown row's
  `colspan="12"` became `colspan="13"` to match the new column count.
- Standalone `models --html` render (`render_model_scoreboard_html` thead,
  `render_model_table_pair` row cells) - gained the `<th class="num">Amended</th>` header and a
  `<td class="num">{fmt_int(row.get("amended", 0))}</td>` cell. Both `colspan="12"` occurrences in
  this render path (`detail-row` and the empty-state row) became `colspan="13"`.
- `enrich_model_groups_with_notes` - after building the existing MODEL-NOTES `notes` list, appends
  `[f"amended: {note}" for note in group.get("amendments") or []]` to it before assigning
  `item["notes"]`. Both HTML surfaces' tooltips (`title="..."` on the standalone table and the HUD
  JS `title="${html(notes)}"`) read `item["notes"]` generically, so amendment reasons now appear
  in both tooltips automatically, ordered after the MODEL-NOTES excerpts. `latest_note` (the
  visible one-line cell text) is intentionally left derived from the pre-amendment `notes` list
  only - the spec asks for the tooltip, not a change to the visible summary line.
- Confirmed no stray `colspan="12"` remained anywhere in the file after the edits
  (`grep -n 'colspan="12"' ringer.py` - no output).

## Test

`tests/test_amend_display.py` - the spec's verbatim RED test, unmodified: `test_amended_column_declared`
and `test_cli_table_has_header_and_group_carries_count`. `print_model_log_table`'s real signature
matched the spec's assumed `(path, rows_read, skipped, groups)` exactly, so no test-line correction
was needed (checked by symbol name before writing the test, not assumed from the line-number anchor).

RED (before implementation):
```
AssertionError: 'Amended' not found in ('Model', 'Lab', 'Harness', 'API/Plan', 'Tier', 'Tasks',
'First try', 'Pass', 'Tokens (median)', 'Speed (median)', 'Last used', 'Notes')
...
AssertionError: 'Amended' not found in 'Model log: ... Notes \n---...\nglm-5.2 ...'
```
Both failures matched the spec's prediction (`"Amended" not in MODEL_SCOREBOARD_COLUMNS`, no
`Amended` header in the rendered table).

GREEN: `python3 -m unittest tests.test_amend_display -v` - `Ran 2 tests ... OK`.

## Step 4 HTML smoke check (verbatim, executed)

Wrote `/tmp/amend-display.jsonl` via the spec's heredoc, then:
```
./ringer.py models --log /tmp/amend-display.jsonl --html /tmp/amend-display.html
grep -q "Amended" /tmp/amend-display.html && grep -q "check was wrong" /tmp/amend-display.html && echo "HTML Amended OK"
```
Literal output:
```
[ringer] self-update: 38 commit(s) behind; current branch is T4-work, not main
/private/tmp/amend-display.html
HTML Amended OK
```
The self-update line is pre-existing `ringer.py` startup behavior unrelated to this change (it
fires because the worktree branch trails `main`); the required `HTML Amended OK` printed.
Manually inspected the grep hits rather than trusting a match alone: the `Amended` header cell
(`<th class="num">Amended</th>`) and the `check was wrong` hit sit inside the notes-cell `title`
attribute, appended after the real MODEL-NOTES excerpt history for `glm-5.2`
(`...amended: check was wrong">2026-07-06 — adversarial pre-merge review...`), confirming the
amendment note is folded into the tooltip next to the MODEL-NOTES excerpts as specified, not a
coincidental substring match elsewhere in the page.

## Additional verification (beyond the acceptance check)

Ran the plain (non-HTML) CLI table against the same fixture:
`./ringer.py models --log /tmp/amend-display.jsonl` - the `Amended` column renders `1` for the
`glm-5.2` / `code-fix` group, and `Tasks` correctly shows `1` (only the un-voided `t2` task counts,
per Task 2's void), confirming the CLI surface and the aggregation-layer void agree end to end.

Full suite: `python3 -m unittest discover -s tests -v` - `Ran 264 tests ... OK` (262 baseline + 2
new test methods, zero regressions).

## Deviations

None. `print_model_log_table`'s real signature matched the spec's assumed signature exactly, so
the conditional test-line correction in the spec's Step 2 did not apply.

## Open questions

None blocking.

## Deferred

None. Task 5 (triage report) is out of T4 scope and already sequenced next in the plan.
