# Ringer amend command - brief (backlog #37)

Date: 2026-08-20
Source: backlog #37 - "amend command: reclassify check-bug FAILs so models are not penalized for orchestration errors."
Implementation lands in `~/repos/ringer`; tracked and briefed here per the #29 precedent.
Pulled from the Backlog lane by explicit user decision per the scope rule.

## Outcome

Model eval records stop carrying blame for orchestrator and check failures: an audited misattribution can be voided after the fact, and the promotion math (`first_try_pass_rate` against `PROVEN_MIN_FIRST_TRY`) hears about it.
Presupposition verdict: verified - `amend` has zero presence in ringer.py, the only correction channel is prose in MODEL-NOTES.md which aggregation never reads, and seven audited misattributions sit paste-ready with nowhere to land.

## End artifact

A corrected glm-5.2 scoreboard on this host - seven check-bug FAILs voided, rates recomputed.
Plus: the amend capability on every ringer host via git pull, a triage-assist report for finding the next misattributions, and a runbook handoff for the other host's 60%-rate cleanup.

## Done looks like

- `./ringer.py amend <run_id> <task_key> --reclassify check_bug --note "why"` appends an amendment row; a second identical call is a no-op with a message.
- The seven Section D commands executed, and all three post-conditions verified: amended count 7 against glm-5.2's groups; the four task-type denominators shrink; `runs.jsonl` grew by exactly seven appended rows with no existing row changed.
- `./ringer.py models` and the HTML page show an Amended count; the per-run view shows each amendment inline next to its recorded FAIL.
- A read-only triage report lists a run's FAIL attempts with their check context, for human audit - judgment stays in the loop, no auto-detection.
- A runbook at `docs/handoffs/` captures the audit procedure (triage FAILs into check-bug vs real, build amend commands, verify post-conditions) so the other host's cleanup runs as its own session.
- An upstream comment for `NateBJones-Projects/ringer#65` is drafted crediting barthballard's generalization; the user approves and fires the post (outbound send - user's trigger).

## Assets and options

| Asset                                      | Option it implies                     | Verdict                      |
| ---                                        | ---                                   | ---                          |
| Section D commands + 3 post-conditions     | Real-data acceptance test             | Chosen                       |
| barthballard generalization (ringer#65)    | Open reclassify set, one audit model  | Chosen - schema-general,     |
|                                            |                                       | check_bug only value shipped |
| #29 check-custody lint (shipped)           | Sibling, tampering-prevention half    | No dependency; noted         |
| MODEL-NOTES.md prose annotations           | Keep as human channel, cross-surface  | Chosen - amendments become   |
|                                            | in HTML next to excerpts              | the machine channel          |
| Ringside models table + HTML + per-run     | Display surfacing                     | Chosen                       |
| Other host (RIT-UADV2223) ringer + log     | Feature via git pull + runbook        | Chosen - audit deferred to   |
|                                            |                                       | its own session there        |

## Approach

Chosen: A - append-only amendment rows in `runs.jsonl`, typed `{"type":"amendment", run_id, task_key, reclassify, note, amended_at, identity}`; aggregation collects amendments before grouping and drops voided `(run_id, task_key)` attempts from both numerators and denominators.
Void, never flip: an amended attempt is evidence-void, neither credit nor blame.
Whole-task granularity default; the key shape leaves room for an attempt filter later.

Considered: B - sidecar amendments file (homogeneous runs log, but two files that must travel together - a copied log silently loses its corrections, the exact failure an audit trail exists to prevent).
Considered: C - annotate rows in place (destroys append-only; rejected outright).
Rationale at decision time: the log and its corrections are one evidence story; append-only in one file keeps the audit trail intact and mechanically checkable, and matches the upstream design one audit model can extend.

## Success criteria

- `[executed-check]` `amend` appends a valid amendment row; a repeated identical call exits as a no-op (test).
- `[executed-check]` aggregation excludes amended `(run_id, task_key)` attempts from `pass_rate` and `first_try_pass_rate` (synthetic-data test).
- `[executed-check]` the three Section D post-conditions hold on the real log: amended count 7 on glm-5.2; the site-build, docs, code-fix, and code-review denominators shrink; exactly seven appended rows with prior lines byte-identical (before/after line count + checksum).
- `[executed-check]` `models` table and HTML page render the Amended count; the per-run view shows the amendment next to its FAIL.
- `[executed-check]` the triage report, run against the stm-nav-restructure run, lists all its FAIL attempts with check context - including the known check-bug rows.
- `[executed-check]` the runbook handoff file exists and names the other host's steps end to end.
- `[judgment]` the upstream comment reads right in the user's voice and credits correctly - user approves before it posts.
  Reformulation attempted ("comment posted") - posting is the check, but the approval is irreducibly the user's, so the tag stays.

## Seams

Blast-radius order:

1. Amendment schema + append + idempotency - the row format everything else consumes; checkable alone.
2. Aggregation exclusion - the math change; synthetic-data test proves it without display or real data.
3. Display surfacing - models table, HTML, per-run view.
4. Triage-assist report - read-only, independent of 1-3.
5. Apply the seven + verify post-conditions - real-data acceptance.
6. Close-out - runbook handoff + upstream comment draft.

## Known vs guessed

- Verified this session: `amend` absent from ringer.py (grep, zero hits); `aggregate_model_log_rows` at line 6072 (the issue's ~5357 is stale); `PROVEN_MIN_FIRST_TRY = 2/3` at line 3073; no `AMENDMENT-*.md` in local ringer docs; Section D commands and post-conditions present in the `fixing-agent-errors.md` transcript.
- Believed, unchecked: the other host's ringer is the same git repo and pulls this cleanly; its `runs.jsonl` schema matches this host's; if wrong, the runbook needs a sync step first.
- Believed, unchecked: the 60% glm-5.2 pass rate on the other host is user-reported from that host - not observable from here; the runbook treats it as motivation, not input.
- Guessed: nothing load-bearing.

## Parking lot

- Second amendment direction - human rejection of a bad PASS as a reclassify value, the mirror image barthballard named, schema-ready but unshipped
  Restart context: the general schema lands with #37; adding the value is validation + display work, and needs its first real case to design against

## Out of scope

- Auto-detecting check bugs - attribution needs judgment; the command trusts its caller (issue non-goal).
- Shipping any reclassify value beyond `check_bug`.
- Performing the other host's per-row audit - runbook'd, run there as its own session.
- Editing or deleting any existing `runs.jsonl` row, ever.

## Open questions for planning

- Source of the `identity` field (env, git config, flag).
- Where the triage report lives (subcommand vs flag on an existing view).
- Exact placement of amendment notes in the HTML next to MODEL-NOTES excerpts.
- How the runbook resolves the state-dir `runs.jsonl` path on the other host.
- Whether the attempt-level filter key ships dormant in the schema or is left undocumented.
