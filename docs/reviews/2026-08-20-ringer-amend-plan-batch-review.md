# Batch review - ringer amend plan (autonomy gate journal + Rubix)

Run: /loop-plan on `docs/briefs/2026-08-20-ringer-amend-brief.md`, autonomy = auto (session, per `docs/chain-state.md`).
Plan under review: `docs/plans/2026-08-20-ringer-amend-plan.md`.
Standing directive (from the launching session): resolve every open question with my own best recommendation, take it, log it here; run the Rubix review and apply its recommended changes; do not stop to ask.
Under the four gate classes, the brief's open questions are DEFAULT-class design decisions (auto-take + log verbosely) - none is a scope narrowing, so none is ASK-class.

## Gate journal (chronological)

| #  | Gate    | Decision (short)                                              | Reversal          |
| -- | ---     | ---                                                          | ---               |
| 1  | DEFAULT | Q1 identity: reuse `resolve_identity()`, expose `--identity`  | edit call, cheap  |
| 2  | DEFAULT | Q2 triage: new top-level `triage` subcommand                 | fold to a flag    |
| 3  | DEFAULT | Q2b: per-run view = the triage subcommand (one surface)      | split later       |
| 4  | DEFAULT | Q3 HTML: `Amended` count column + notes in triage/tooltip    | re-place render   |
| 5  | DEFAULT | Q4 path: runbook resolves `state_dir/runs.jsonl` live        | doc edit          |
| 6  | DEFAULT | Q5: attempt-filter key not shipped; whole-task void only     | add field later   |
| 7  | DEFAULT | Premise fix: real-data acceptance moves to RIT-UADV2223      | user may redirect |
| 8  | DEFAULT | Scope flag REVERSED: `models` read-model void now in scope   | revert Task 3     |
| 9  | BATCH   | Ran Rubix (both Opus lenses); accept all findings, revise    | revert; re-run    |

Entries 1-7 are DEFAULT auto-takes; each is reversible as noted.
Entry 7 is a factual premise correction surfaced to the user in the handoff for veto.
Entry 8 was reversed by Rubix finding F1 - the void is now in scope as plan Task 3.
Entry 9 is the BATCH gate for the Rubix pass (parent pre-accepted all findings).

### Gate rationale (full)

1. Q1 identity source: identity already exists and is stamped on every row as `orchestrator`; reusing `resolve_identity()` (ringer.py:9454) with an added `--identity` flag beats inventing an env or git-config path.
2. Q2 triage home: triage is independent of amend (brief seam 4), and a per-run FAIL listing is conceptually distinct from the per-model scoreboard, so a dedicated subcommand is cleaner than a `--triage` flag on `models`.
3. Q2b: there is no existing per-run-over-log view, and two read-one-run surfaces would be redundant, so the brief's "per-run view" and its "triage report" are one subcommand.
4. Q3 HTML placement: the scoreboard is per-model, so an aggregate `Amended` count is the right column there; the per-attempt note text belongs in the per-run triage view, and the design note's ask (amendment reasons next to MODEL-NOTES excerpts) is met by folding notes into the scoreboard Notes tooltip.
5. Q4 other-host path: the log path is `state_dir/runs.jsonl`, the other host may differ, so the runbook resolves it live (config `state_dir`, else `~/.ringer/runs.jsonl`) and every command can override with `--log`.
6. Q5 attempt-filter key: YAGNI - whole-task void is the brief default, and an append-only JSONL adds an optional attempt selector later with no migration, so nothing dormant ships now.
7. Premise correction: a disk check on the build host (RIT-UADV2213) returns 0/7 for the seven `stm-nav-restructure` run_ids; they and the 60%-rate cleanup both live on RIT-UADV2223 (the transcript header confirms). The brief verified the commands exist in the transcript but never checked the target rows exist here, so real-data acceptance runs on RIT-UADV2223, carried by the runbook, while the feature verifies with synthetic data on the build host.
8. Scope flag reversed: the original deferral treated the SQLite read model as out of scope, but the `models` command itself serves rows from that read model by default (`should_use_read_model_db`, ringer.py:6224), so the void must reach it or the brief's `models` success criteria fail on the default path - now plan Task 3.
9. Rubix pass: the parent directed running the review and applying its recommendations, so the Step 6 BATCH triage was pre-resolved to accept-all; every finding below is incorporated.

## Rubix triage (all findings, most-severe first)

Lens A = Opus (operator-maintainer seat); Lens B = Opus (cold craft read).
Both fresh-context, plan + brief only; both independently found the blocker.
Every finding accepted (parent directive "apply"), none dismissed.

| ID | Lens | Sev     | Finding (short)                                                    | Verdict |
| -- | ---  | ---     | ---                                                               | ---     |
| F1 | A+B  | blocker | `models` default path serves the SQLite read-model; void skipped  | revise  |
| F2 | A+B  | high    | scoreboard aggregator void is untested; snippet fits the log one  | revise  |
| F3 | B    | high    | finalized dicts drop `amended`/`amendments` unless keyed in        | revise  |
| F4 | A+B  | high    | grouping raw rows makes a phantom empty-model group               | revise  |
| F5 | A+B  | medium  | `print_model_log_table` sig is `(path, rows_read, skipped, groups)` | revise |
| F6 | B    | medium  | an all-voided group `tasks==0` yields a bogus 0% tier row         | revise  |
| F7 | B    | medium  | `--since` drops amendment rows (no `logged_at` stamp)             | revise  |
| F8 | A+B  | low     | `amend` has no existence check; a typo silently voids nothing     | revise  |
| F9 | B    | low     | idempotency is note-immutable; a re-amend drops a new note         | revise  |

### How each finding was applied

- F1: new plan Task 3 forces the JSONL path when the log has amendments and skips amendment rows in the DB insert, with a DB-branch test; gate entry 8 reversed.
- F2: Task 2's test now covers `aggregate_model_scoreboard_rows` (model first-try and tier lift plus the code-fix per-type denominator shrink), and the plan notes its different dual-target-loop shape.
- F3: Task 2 adds `amended` and `amendments` to both finalized output-dict key lists explicitly, not just the accumulator.
- F4: both aggregators now group `partition_amendments(...)`'s `attempts`, not raw rows, and a test asserts no empty-model group appears.
- F5: the Task 4 verbatim test calls `print_model_log_table(path, len(read_rows), skipped, groups)` so it fails on the missing header, not an argument error.
- F6: Task 2 drops any `tasks==0 and amended>0` group from the scoreboard, with a test; the count stays reachable through the triage view.
- F7: `append_amendment` stamps `logged_at = amended_at`, so the `--since` filter retains the amendment row.
- F8: `run_amend_command` warns (non-fatal, still appends) when no attempt matches the target, and the runbook runs `triage` before each amend.
- F9: Task 1 documents that amendment notes are immutable by design (get the note right the first time).

## Post-revision

Plan revised incorporating all nine findings; loop-plan Step 5 self-review re-run against the revised plan.
The blocker (F1) reshaped the task list: seam-2 aggregation now spans Task 2 (JSONL math) and Task 3 (the `models` read-model path); display, triage, runbook, and upstream renumber to Tasks 4-7.

### Wave 2 gate - passed
- T2 (opus, code-feature, pin:risk): validator pass 7/7 at high effort with an independent /tmp synthetic probe; suite 261 OK.
- Two spec-sanctioned deviations verified honest: list-shaped breakdown lookup helper; --engine amendment passthrough.
- Merged 2228bc7 (fast-forward) into amend-command; receipt 3113e8f; worktree pruned.

### Wave 3 gate - passed
- T3 (sonnet, code-feature): validator pass 10/10; live sandbox re-derived; stale-DB probe green; suite 262 OK.
- Real-log 147->149 growth attributed to the concurrent config-v4-split run (external); read-only invariant holds.
- Merged f0d7d57 into amend-command; receipt committed; worktree pruned.

### Wave 4 gate - passed
- T4 (sonnet, code-feature): validator pass 8/8; HTML placement verified beyond greps; suite 264 OK.
- Merged 02b944b into amend-command; receipt committed; worktree pruned.

### Wave 5 gate - passed
- T5 (sonnet, code-feature): validator pass 7/7; adversarial CLI probe green; suite 265 OK.
- Merged 6ef3c17 into amend-command; receipt committed; worktree pruned.

### Wave 6 gate - passed (pass-after-attribution)
- T6 (glm-5.2 opencode, docs): two run-verdict FAILs, both attributed at the gate as orchestration/check bugs, not model failures.
  Run p92887: bare model slug (orchestrator manifest bug). Run p93713: check bug (missing repo key broke git patch-export) + JSON-to-shell quote escaping in the transcribed commands.
- Orchestrator repaired mechanically (de-escape), re-ran every check stage by hand, seven commands byte-diffed identical to the plan; Opus reviewer pass 5/5; committed 9ca35fa; suite 265 OK on integration.
- MODEL-NOTES receipts 03ad498 flag both runs' scoreboard rows as amend candidates on this host post-merge.

### Gate 13 - T6 spec made self-contained `[gate:BATCH]`
- Decision: replaced the compiled template's pointer spec ("per section Task 6 of the source plan") with the full embedded content before launch.
- Rationale: ringer's spec-writing rule - the worker gets no conversation; pointer specs are barred. Single-unit, produced contract unchanged.
- Reversal: n/a - the emitted artifact was validated against the same canonical content either way.

### Gate 14 - advisory loop-review, Spec finding applied `[gate:BATCH]`
- Decision: applied the Spec-axis one-liner (triage verdict compare normalized via model_log_text(...).upper(), matching ringer.py's own convention at the aggregators); suite re-run green.
- The Spec reviewer's "fabricated attribution" flag on T7 was arbitrated against the live upstream thread and overruled - barthballard's comment literally carries the referenced mark --check-fault fork note; sizing stays the user's HC-2 taste call.
- Standards axis: zero hard violations; four judgement-call smells recorded (duplicated void bookkeeping, (run_id, task_key) clump, scattered amendment type-test, display shotgun surgery) - slipped as follow-up material, not fixed in the loop.
- Reversal: git revert of the one-liner; smell refactors are future scoped work.
