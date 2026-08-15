# Gate journal - slim/fold/dedup drive (brief 3, structural chunk, Tasks 1-6)

Gate journal for the /loop-drive execution of brief 3, structural chunk (Tasks 1-6), under auto (session).
Each entry: decision, rationale, reversal path.

## Task 1 - open the drift ledger

- Decision: appended the cycle-3 opening block to `docs/molt-ledger.md` (harness snapshot v2.1.204) and created this batch journal.
- Rationale: the plan mandates a single append-only ledger home and a batch journal under autonomy; both are opened at Task 1 so later tasks append, never re-create.
- Reversal: `git revert` the Task 1 commit.

## Task 2 - retire frontier-sandwich

- Decision: deleted the frontier-sandwich SKILL body wholesale (bin CHOREOGRAPHY); git-moved `fable-guidelines.md` into loop-drive and slimmed it to tier table + effort dial + prompt pitfalls (cut the interview-cadence and orchestration/environment-hygiene choreography); retargeted the install-generated benchmark symlink and the retire list to loop-drive; rewrote the gate as a scoped retirement contract.
- Rationale: the SKILL's phase narration and interview loop are judgment a frontier model applies unprompted; the only durable content is the tier/effort policy, which relocates. Gate scoped to retirement facts (dir absent, retire-list entry, leaf moved+uncommitted) because the cross-skill reference conversions land in Tasks 4/5/6 - a repo-wide sweep here would fail RED at its own task position (Rubix A1).
- Reversal: `git revert` the Task 2 commit restores the dir, the old gate, and the frontier-sandwich benchmark leaf path.

## Task 3 - routing-chain canonical home

- Decision: added a `## Routing chain` section to `config/routing/model-benchmarks.md` as the single home of the three-tier narrative, the distilled `scoreboard posterior, else benchmark prior, else orchestrator pin` phrase, the ringer-absent fallback, the claude-zai tie-break, the promotion ladder, and the roster.
- Rationale: the same narrative was restated in 5 sites (dedup, bin PLUMBING-style duplication); the content is POLICY (P7) so it is consolidated, not deleted. `config/` is not registry-scanned, so no gate impact this task; the other sites convert to the pointer in Tasks 5/6/10.
- Reversal: `git revert` the Task 3 commit.

## Task 4 - brainstorm front door + choreography/graduation slim

- Decision: added the Step 0 One-Minute Test front-door triage (bin POLICY relocation), git-moved and slimmed `one-minute-test.md` into brainstorm, compressed the scope-probe/domain-modeling cadence to decision content (bin CHOREOGRAPHY), single-homed the shared graduation contract into `brief-pipeline.md`, repointed the retired-skill handoffs, and ran the executable probe (recorded in `docs/reviews/2026-08-15-slim-fold-dedup-probes.md`).
- Rationale: the cadence prose is ordering a frontier model applies unprompted; the graduation narration was duplicated across two skills. The probe confirmed the shaping lane still emits a verdict then an Outcome/Done/Criteria/Seams skeleton, so the slim did not degrade it.
- PLAN-DEFECT RESOLVED (flag for owner): the plan mandates moving the `graduate-parking.sh` contract into `brief-pipeline.md` and explicitly calls the on-disk "graduation is per-skill" invariant stale, but `tests/gates/loop-improve.sh:70` still enforced that stale invariant, and Task 4's acceptance requires `tests/run.sh` green. The two cannot both hold. Resolution (unambiguous from the plan's intent, not a guess): inverted that one assertion to the new single-home guard - the shared contract MUST be in `brief-pipeline.md`, while the improve-only supersede-close and per-skill terminal routing must NOT leak in. The test file was not in Task 4's listed ownership; this is a scoped, reversible fix of a guard on a Task-4-owned artifact (brief-pipeline.md), forward-compatible with Task 8. Reversal: `git revert` the Task 4 commit.
