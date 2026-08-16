# Batch review - control-plane drive (2026-08-15)

Gate journal for the brief 4 execution run.
Created at autonomy start; appended at every gate in chronological order.

## Entries

1. ASK (record-only) - Brief 4 plan approval.
   Decision: owner approved the rubix-revised plan by invoking /loop-drive on it; autonomy set to auto per the brief 4 protocol (pause during planning, auto after approval).
   Rationale: brief 4 sequence rule - execution only after owner approval.
   Reversal: n/a - resolved live.

2. BATCH - Step 0 route and topology lean.
   Decision: multi-wave dependent build; five waves - T1, T2, T3 sequential (all mutate scripts/tracker.sh, exclusive-ownership rule forbids packing them into one wave), T4/T5/T6 as the single 3-wide parallel wave (disjoint files), T7 integration last. Single topology diagrammed; no second shape within 60/40.
   Rationale: the wave graph is forced by the plan's own Files-ownership lists; any other shape violates the disjoint-files invariant.
   Reversal: re-derive waves from the plan's Depends-on lines and relaunch the compile dispatch; cheap, nothing executed yet.

3. DEFAULT - Compile pin review.
   Decision: compiled _loop.md accepted as emitted; verified nine-section order, custody conversion, roster/effort constraints, resume procedure, evidence chain.
   Rationale: pin review is the driving session's retained step; no rule violations found.
   Reversal: git revert the _loop.md commit and recompile; cheap.

4. DEFAULT - Step 7 dashboard question.
   Decision: auto-taken under auto - launch immediately, dashboard and watch points reported inline rather than asked.
   Rationale: gate is DEFAULT-class; the declared default is launch-with-no-selection; owner reviews the journal at the merge gate.
   Reversal: n/a - informational; the run can be interrupted at any gate and resumed via the section 7 prompt.

5. BATCH - T5 kill-test fixture check bug (orchestrator-owned).
   Decision: fixed the placed test + source plan (one added commit line): the fixture committed uncommitted tracker state onto the unit-1 branch, so checking out main deleted the issue file and claim failed rc=1 (no issue) instead of rc=4 (race). Caught at RED verification, before any worker launch.
   Rationale: spec/check edit confined to one unit's test, under 15 lines, contract unchanged - BATCH per the slip rule; attribution ran the failing step by hand first.
   Reversal: git revert the test commit; cheap.

6. BATCH - T7 Step 1 install isolation.
   Decision: ran ./install.sh against a scratch HOME (LOOP_STACK_SKILL_STYLE=claude) instead of the live one; a bare run would symlink live ~/.claude skills at this un-merged worktree, violating the cycle's nothing-goes-live rule. The executed check (install mechanics pick up the new files) is unchanged; the live install remains the owner's merge-gate step from the main checkout.
   Rationale: blast-radius containment; the source plan's intent is "install works", not "go live pre-merge".
   Reversal: n/a - the scratch HOME is deleted; the live install happens at the merge gate regardless.

7. BATCH - terminal loop-review Spec finding: evidence-regex substring hole.
   Decision: tightened the done verb's --receipt regex ('[0-9]+ passed|0 failed' -> '[1-9][0-9]* passed|(^| )0 failed') in scripts/tracker.sh and the source plan; proved both directions by executed check (10-failed and 0-passed now rc=5; 43-passed and exit-0 still rc=0); full suite green after.
   Rationale: spec-authored weakness in the P2 guard, one line, single criterion, --ran path already immune - BATCH per the slip rule, fixed at the terminal gate rather than parked.
   Reversal: git revert; cheap.

8. BATCH - live-install incident: spec-axis reviewer executed ./install.sh.
   Decision: identified by direct admission (reviewer followed the spec's Task 7 How-to-run line; non-interactive default re-linked ~/.agents/skills/* at this worktree at 01:37:39Z). Containment: leave links (they point at the validated cycle-1 tree); the owner's merge-gate install restores canonical targets; lesson graduated to an idea issue (install.sh non-interactive guard + reviewer-prompt blacklist).
   Rationale: re-pointing live symlinks twice in one evening is churn; the merge gate already contains the restoring command. The deviation is surfaced, not hidden.
   Reversal: run ./install.sh from the canonical checkout at any moment.
