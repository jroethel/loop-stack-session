# Batch review: loop-improve drive (2026-08-08)

Run journal for the autonomous execution of docs/plans/2026-08-08-loop-improve-plan.md.
Autonomy knob: auto (runtime, docs/chain-state.md).
Invocation argument named the plan's batch-review journal; read as a slip for the plan itself (a journal is not drivable) and recorded here.
Entries append chronologically as gates fire; BATCH and DEFAULT entries are the review obligation at end of chain.

## 1. [BATCH] Step 0 route: single-unit ringer run, not a 3-wave serial loop

- Decision: compile the 3-task plan as ONE ringer task (one worker executes Tasks 1, 2, 3 sequentially in one worktree, committing per task) instead of three single-unit waves.
- Rationale: the chain is forced fully serial by exclusive file ownership (Task 2 needs Task 1's shared reference; Task 3 needs Task 2's gate tags), so waves add two gate cycles for zero parallel gain; the loop-setup-reconcile precedent ran the identical shape successfully. Not a 60/40 call - no second diagram owed.
- Reversal: scoped re-run as a 3-wave loop with per-task gates; the plan artifact is unchanged either way.

## 2. [BATCH] Step 2 routing: claude-zai / glm-5.2, task_type code-feature

- Decision: route the single unit to engine claude-zai, model glm-5.2, effort n/a (ringer lane), validation = executed check plus orchestrator gate audit.
- Rationale: integrity-gated posterior - glm-5.2 has the only deep local code-feature record (15 tasks; headline 60% first-try discounted upward because MODEL-NOTES and AMENDMENTS-PENDING attribute most recorded FAILs to audited orchestrator check bugs), and its named reliable zone (tightly-specced, contract-driven edits with executed checks) is this plan's exact shape. Opus's ringer posterior is probation n=2. Flat-rate quota tie-break also favors claude-zai. No pin trigger: the work is contract-following, not design or taste; Task 1's prose-extraction risk is covered by the gate audit reading that diff in full.
- Reversal: re-run the same manifest pinned to opus via claude - one command.

## 3. [record] Pre-flight: base state confirmed

- Decision: no STOP fired; `git status --porcelain` shows only untracked `.scratch/` (scratch byproducts, no uncommitted tracked changes) at base 33140d2; ringer present at ~/repos/ringer with engines codex, claude, claude-zai, opencode; vendoring source paths verified present on this host earlier this session.
- Rationale: worktrees branch from committed state; untracked scratch does not travel and does not block.
- Reversal: n/a - resolved by observation.

## 4. [record] Compile and pin review

- Decision: manifest compiled by one fresh-context dispatch at the drive-compile pin, written to .scratch/loop-improve/manifest.json; pin review passed.
- Rationale: pin review re-derived the compiler's claims by a second route - nine byte-probes of the plan's trickiest lines all present in the spec (verbatim test-file assertions, all three commit messages, the attribution header, the imperative pointer, the period-free title rule, the STOP escape hatch), task order 1-2-3 confirmed at real offsets, no pipefail in the check, base pinned to 33140d2, the format-patch export verified in the check tail, and the em-dash gate proven satisfiable (all three pre-existing owned files grep clean). Independent `./ringer.py lint` shows exactly one finding: the by-design worker-commit warning, mitigated by the check's patch export outside the worktree.
- Constraint recorded: HEAD must remain at 33140d2 until the gate (the check counts commits from that pinned base), so this journal stays uncommitted until the run resolves.
- Reversal: n/a - review record.

## 5. [DEFAULT] Step 7 launch: no execution-details ask, launch immediately

- Decision: the "See execution details before I launch?" ask was auto-taken as its default (nothing selected = launch immediately); dashboard equivalents recorded here.
- Rationale: gate class DEFAULT under auto. What runs: 1 task, glm-5.2 @ claude-zai, worktrees on, timeout 3600s, run_name loop-improve; launch is `~/repos/ringer/ringer.py lint <manifest> && ~/repos/ringer/ringer.py run <manifest>`. Watch points: raw worker log under .scratch/loop-improve/logs/, run JSON in ~/.ringer/runs/, patches land in .scratch/loop-improve/patches/.
- Reversal: cheap - stop the run; nothing lands on main until the gate applies patches.

## 6. [record] Launch-transport attribution: first launch shell exited 1 with zero worker output

- Decision: the first background launch's failure was attributed to the launch chain, not the work - `ringer.py lint` exits non-zero whenever it has ANY finding, including the reviewed by-design one, so `lint && run` never reached `run` and no run JSON was created; relaunched with `run` alone.
- Rationale: the output file held only the lint line and no loop-improve run JSON existed; the skill's own reference command uses `lint && run`, which silently cannot launch any manifest carrying a by-design finding - an orchestrator lesson recorded in the ringer MODEL-NOTES receipt.
- Reversal: n/a - resolved by attribution and relaunch.

## 7. [record] Gate: PASS verified by re-derivation; merged to main as 1b4d5ad, ad8dfdb, 83cab38

- Decision: run verdict PASS (1 attempt, 19.8m, check returncode 0) was accepted after independent re-derivation, and the three exported patches were applied on an integration branch and fast-forward merged to main (head 83cab38).
- Rationale: second-route audit - patches applied clean with the plan's exact three commit messages; footprint exactly the 7 owned files; all four gate suites re-run green in the real repo at the gate; the Task 1 prose-extraction diff was read in full (the routing risk recorded in entry 2) and found faithful - tagged headings byte-preserved, imperative pointers present, graduation retained per the Rubix rescope; substance spot-checks of what greps cannot judge (the shared reference's return line, all five rephrased playbook machinery lines, the verbatim frontmatter) all correct; zero em dashes in the owned files.
- Pre-existing failure flagged, not chargeable to this run: tests/loop-review/acceptance.sh fails identically on the pre-run base 33140d2 ("SKILL.md never defines the no-spec wording"); slipped to the final human checkpoint as a candidate fix or backlog item.
- Reversal: `git revert 83cab38~2..83cab38` (or reset to 33140d2 while unpushed).

## 8. [BATCH] Terminal advisory loop-review run; findings recorded, non-blocking

- Decision: /loop-review 33140d2 ran after advancement (two fresh-context Opus axes); advisory findings recorded here, none blocking.
- Rationale and findings:
  - Spec axis: zero findings - every mandated literal and contract landed, the recorded brief-to-plan deviation was honored as recorded, footprint exact, all four acceptance suites re-run green; one non-finding noted (README trailing-pipe raggedness pre-exists and the plan directed matching the existing table).
  - Standards axis: zero hard violations; three judgment calls slipped to the human checkpoint - (MED) the vendored playbook carries a one-line attribution where proper MIT vendoring wants the upstream copyright line and permission notice, and the upstream license claim is asserted, not verified; (LOW) a non-ASCII division glyph in the vendored rubric where SKILL.md writes "impact / effort"; (LOW) pipeline-diagram glyph style differs between loop-improve (ASCII) and loop-brainstorm (box-drawing).
- Reversal: n/a - advisory record; the slips are Jeremy's to accept into the backlog or drop.

## 9. [record] End-of-chain checkpoint reversal: selection widened from single-finding to multi-finding

- Decision: at the review checkpoint Jeremy reversed one encoded decision - "single brief" was an artifact-count constraint (one brief file replacing /improve's plans directory), never a scope constraint (one improvement); Step 4 now selects findings via multiSelect (default suggestion: top 3-5 by leverage, /improve's own Phase-3 default), all converging into the one brief as its seams, with per-issue supersede-close offers. Committed as 0e80f18; all four gate suites re-run green.
- Rationale: the narrowing entered at the brainstorm's Round-1 option wording ("you pick one"), which bundled an unasked scope decision inside the artifact-count question Jeremy was actually answering; the misread is the orchestrator's, recorded here so the pattern (bundled decisions inside an option label) is visible to future rounds.
- Reversal: `git revert 0e80f18` restores single-finding selection.
