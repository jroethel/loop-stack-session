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

6. BATCH (loop-drive Step 0, route verdict)
   - Decision: ONE AGENT, ringer transport - a single one-task manifest executes all five plan
     tasks serially in one worktree, instead of four waves of mostly one unit each.
   - Rationale: T1-T3 are strictly serial and only T4/T5 are parallel-eligible (both tiny), so
     wave machinery buys minutes at real orchestration cost; the plan's executed checks make one
     worker cheaply verifiable (P6). Alternate shape (4 waves) was the 40 side of a 60/40 lean.
   - Reversal: scoped re-run - re-launch as a per-wave manifest set if the single unit fails
     twice or the gate finds cross-task contamination.

7. BATCH (loop-drive Step 2, routing + engine)
   - Decision: glm-5.2 on the claude-zai lane, task_type code-feature, impl effort high;
     validation = executed manifest check + orchestrator gate (diff audit vs the plan's verbatim
     blocks, acceptance re-run on the integration branch); no separate native validator.
   - Rationale: scoreboard posterior - proven, 61 tasks, 89% pass, 82% first-try - with
     attribution-clean MODEL-NOTES receipts from this exact repo's packaging loop; quota
     tie-break also favors the flat-rate lane. Fable never a worker; opus reserved for gate
     judgment. Single-unit run, so no exploration lane (rule applies at 3+ tasks).
   - Reversal: re-route at the gate by the same chain (pin opus) if the unit fails validation
     twice or the lane zero-tokens (probe lane before burning retries, per 8/17 lesson).

8. BATCH (loop-drive, human-checkpoint consolidation)
   - Decision: the plan's two [judgment] checkpoints (placement-table unambiguity after T1;
     handoff-doc runnability after T5) are consolidated into the end-of-run human review instead
     of blocking mid-run.
   - Rationale: kickoff said "only stop if necessary"; all work lands as local commits on an
     integration branch, nothing publishes or rolls to target repos in this run, so the
     judgment review loses nothing by moving to the end.
   - Reversal: cheap - reject the table or handoff at the end review; edit + re-copy to the
     template is a two-file change before any push or target roll.

9. Pre-flight note (record-only): working tree clean at base 5de95ae except two untracked
   files from the #37 ringer-amend stream (docs/plans/2026-08-20-ringer-amend-plan.md and its
   batch review). Untracked files do not travel into worktrees and are disjoint from all 13
   owned files, so the dirty-tree STOP invariant (branch from committed state) holds; left
   untouched.

10. Gate attribution (record-only, attempt 1): run 024858Z failed 1/0-tokens, but the worktree
    autopsy showed early Task 1 work in flight - the background launch shell was reaped and
    ringer shut down mid-worker. Attribution: transport kill, not model; both GLM lanes then
    probed healthy (claude-zai 12s, opencode 8s). The scoreboard fail row for that run reads
    transport, not capability. Fixes applied before relaunch: check base made dynamic
    (merge-base with main, since a parallel session advanced main with the #37 plan commit -
    disjoint files, no conflict) and the relaunch runs detached via nohup so shell reaping
    cannot kill it again. Relaunched clean (relaunch-never-resume) as run 030012Z.

11. Gate attribution (record-only, attempt 2 / run 030012Z): run verdict FAIL, actual verdict
    CHECK BUG. The worker completed all five tasks in 7 clean commits (5 planned + 2 sound
    in-ownership adaptations: keeping the tracker-backend disclosure on the render-anchor line,
    and octal-escaping the em-dash sweep pattern so the detector file carries no literal byte),
    ownership exact, tree clean. The check's lifecycle-lint stage failed on two class-a
    findings that exist at the clean base commit - committing the 2026-08-20 plans superseded
    the 2026-08-16 packaging plan-set - so the invariant was false before the worker started.
    Scoreboard fail rows for this run read check-bug, not model failure.

12. BATCH (gate remediation, archive action)
    - Decision: archived the superseded packaging plan-set + brief (2026-08-16-packaging-plan.md,
      -plan_loop.md, -brief.md -> docs/archive/), commit dcbb4d4; lifecycle-lint exits 0 after.
    - Rationale: rule 1a (superseded, no open issue links the stem) and rule 2 (brief travels
      with plan); ROADMAP records packaging phase 1 closed 2026-08-18, so this is completed
      work, and the lint header itself classes the archive action as BATCH.
    - Reversal: cheap - `git revert dcbb4d4` restores the files to their lanes.

13. Gate close (record-only): all 7 patches applied clean to integration/config-v4 off dcbb4d4;
    hand-run of every check stage green (structure, anchors, key reads, pointers, handoff,
    em-dash sweep, lifecycle-lint, the three named suites, full tests/run.sh 46/46);
    fast-forward merged to main at 2671f4c; worker worktree pruned. The two [judgment]
    checkpoints (placement table, handoff runnability) remain open for the human end review
    per entry 8.

14. BATCH (final-wave advisory terminal review, /loop-review 80fe090)
    - Decision: ran the two-axis advisory review post-advancement; both axes converged on one
      finding (placement-table pipe misalignment, traced to the plan's own table, copied
      faithfully by the executor). Fixed in all three files (both conventions files + the plan
      source), affected suites re-run green, committed as cefb970. Standards axis also noted
      the conventions.md / conventions.template.md byte-identical pair as judgment-call
      Duplicated Code; recorded, no change - the pair is the repo's deliberate template
      convention and reconcile.sh asserts the verbatim copy.
    - Rationale: advisory gate is BATCH per loop-drive; the fix was a two-space edit on the
      exact artifact the human checkpoint reviews.
    - Reversal: cheap - `git revert cefb970`.
