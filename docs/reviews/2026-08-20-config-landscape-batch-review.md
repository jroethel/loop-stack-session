# Batch review - config landscape refactor (#38) - 2026-08-20

Gate journal for the autonomous chain: loop-auto set auto -> loop-plan -> loop-drive.
Chronological; BATCH and DEFAULT entries are the review obligation, ASK/STOP are record-only.

## Gates

1. ASK (loop-auto set auto, consolidated pre-autonomy ask)
   - Decision: no offers or choices were pending at the moment auto was set; nothing to resolve.
   - Rationale: fresh session, first action of the chain.
   - Reversal: n/a - resolved live.

2. ASK (loop-plan Step 2, open questions round)
   - Decision: user pre-authorized in the kickoff message: "if any questions arise, go w/ your
     recommendation and make a note". Five open questions resolved by orchestrator recommendation:
     (1) convention doc is config/conventions.md + config/conventions.template.md;
     (2) host.env, ringer/, routing/ get declared homes only, no physical moves;
     (3) single template-version: key stays in repo-state.md, v4 = two-file shape, one reconcile
     offer for both files;
     (4) pointer updates confined to brief-pipeline.md, import-triage.md, loop-setup/SKILL.md;
     (5) graduate-parking.sh needs comment-only changes (verified: body hardcoded, never parses
     the template).
   - Rationale: each answer grounded in codebase facts gathered this session (greps and file
     reads); recorded in the plan header as "Decisions".
   - Reversal: n/a - resolved live (pre-authorized); any single decision can be reversed by
     editing the plan header and the affected task before execution.

3. DEFAULT (loop-plan Step 6, Rubix review offer)
   - Decision: run the Rubix review - user pre-accepted in the kickoff message ("yes to rubix,
     apply recommended changes"). Two fresh-context Opus reviewers dispatched in parallel.
   - Rationale: explicit user instruction; lens A impacted-professional, lens B cold craft.
   - Reversal: n/a - resolved live (pre-accepted).

4. BATCH (loop-plan Step 6, Rubix triage)
   - Decision: all 14 findings incorporated into the plan (A1-A7, B1-B7; B7 taken in its cheap
     repoint variant rather than the "accept the weakened test" alternative). None dismissed.
     Full triage table in the session transcript; revision summary in the plan's "Rubix
     revisions" section.
   - Rationale: user pre-approved "apply recommended changes"; every finding was verified by the
     reviewers against the live tree (line numbers re-checked), and each fix is small and concrete.
     The three load-bearing ones (A1, A2, B1) were execution-breakers: two acceptance checks that
     fail on correctly-done work and one silent render break invisible to this repo's tests.
   - Reversal: cheap - each revision is a named plan edit; revert any single one by editing the
     plan section the "Rubix revisions" note names, before execution starts.

5. DEFAULT (loop-plan Step 7, user review gate + commit offer)
   - Decision: auto-took the commit of the plan and this journal (chain continues into
     loop-drive per the kickoff message; "only stop if necessary").
   - Rationale: the plan is the input artifact loop-drive consumes; committing gives the run a
     rollback point. The user's kickoff pre-chose the onward route, so the review gate's live
     pause was already answered.
   - Reversal: cheap - `git revert` the plan commit; plan content remains editable at any point
     before its task is dispatched.
