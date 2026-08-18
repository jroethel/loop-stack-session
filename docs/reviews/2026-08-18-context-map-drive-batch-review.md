# Batch review - context-map #34 drive

Run: /loop-drive `docs/plans/2026-08-18-context-map-plan.md`, autonomy auto (session), orchestrator Fable, ticket #34 claimed as `fable-drive-20260818`.

## Gate journal (chronological)

1. ASK (record-only) - autonomy set to auto and engine pinned by the user live: claude-zai first, ANY 529 re-routes to claude engine model sonnet (Sonnet-5).
   Rationale: user instruction in the launch message; the ringer engine-ask is thereby answered.
   Reversal: n/a - resolved live.
2. BATCH - Step 0 route verdict: ONE AGENT, one-task ringer manifest (plan tasks T1+T3+T4 in one worker, worktrees on); wave machinery and drive-compile dispatch skipped.
   Rationale: the three repo tasks are strictly serialized (T3 needs T1, T4 needs T3), fully specified with verbatim content, and every acceptance criterion is a cheap executed check - no parallelism for waves to exploit.
   Reversal: recompile as a multi-wave `_loop.md` via the drive-compile dispatch and rerun.
3. DEFAULT - Step 7 "see execution details?" auto-taken as launch-immediately.
   Rationale: gate class DEFAULT under auto; details are logged here (routing, topology, watch points) and live on Ringside at http://127.0.0.1:8700.
   Reversal: n/a - cheap; the dashboard and this journal carry the same content on demand.
4. BATCH - terminal advisory /loop-review skipped on the single-unit route.
   Rationale: the skill mandates it for the final wave of multi-wave runs; here the gate itself re-executes every acceptance check and diff-reads the one patch.
   Reversal: run `/loop-review d205a0c` after the gate lands if a two-axis report is wanted.

## Routing (condensed)

| Unit        | Wave | task_type    | Model   | Transport | Engine     | Impl. effort | Val. effort | Evidence  |
| ---         | ---  | ---          | ---     | ---       | ---        | ---          | ---         | ---       |
| ctx-map-134 | 1    | code-feature | glm-5.2 | ringer    | claude-zai | default lane | gate re-run | posterior |

Posterior: 59 tasks, 81% first-try, 88% pass on the claude-zai lane; 2026-08-17 MODEL-NOTES records a lane-level 529 outage (not model failure), hence the user's Sonnet-5 fallback pin.

## Gate record (run close)

- Run `context-map-34-20260818T045520Z`: ctx-map-134 PASS attempt 1 (161s), zero 529s, sonnet fallback unused.
- Gate evidence: map byte-identical to the plan block (diff), all T1/T3/T4 acceptance checks re-executed green on the real tree, full suite 46/46, patch scope exactly the five owned files.
- Commits: `6555cb3` (map), `a9b53e4` (pointers), `3be8e0a` (class-e lint), per the plan's three-commit structure; MODEL-NOTES receipt `bbc623b` committed in the ringer repo.
- Ticket #34: AGENT STATUS receipt written; status `agent:needs-input` pending Task 2.

## Run close (owner review, 2026-08-18)

5. ASK (record-only) - owner approved the map and both judgment checkpoints ("it's fine"), verified T2 on host (search hit re-derived by me against the live collection: `research` rooted at `~/create/research`, stale `pcs` removed), and requested the JSON-index idea.
   Rationale: live owner review; #39 filed for the idea; #34 closed via evidence-gated `tracker.sh done` (`--ran bash tests/run.sh` re-executed, exit 0).
   Reversal: n/a - resolved live.
6. DEFAULT - plan-set archived automatically per archive rule 1 (all items complete): `docs/archive/2026-08-18-context-map-plan.md`, `docs/archive/2026-08-17-context-map-brief.md` (commit `926cbf9`). Context-map write gate at archive: no map line added, moved, or deleted (the map does not index plans or briefs); class-e clean.
   Rationale: rule 1 is the declared automatic path; verbose announce satisfied here.
   Reversal: `git revert 926cbf9`, reopen #34.
7. BATCH - archiving surfaced a latent class-c false positive (fresh `idea` issue #39 flagged for citing the archived stem); fixed inline in one pass rather than routed as a manifest (deviation from ringer routing, named): `idea`-labeled issues exempt from class-c only, class-a keep-alive semantics untouched; covered by a new local-backend test case (commit `fa9814c`, suite 46/46, real-repo lint exit 0).
   Rationale: global rule to fix lint reds on sight; the backlog lane cites archived stems by design (graduation template's Source-brief pointer), so class-c matching it was a spec bug, not noise to suppress.
   Reversal: `git revert fa9814c` restores strict class-c.

## Pending STOP

- Plan Task 2 (qmd re-point) is a host mutation the plan reserves for the user; commands staged in the run report, awaiting the user's trigger.
- Human [judgment] checkpoints from the plan, for the user at review: (1) each why clause lets a prune keep or retire its line without opening the pointee; (2) the policy header covers all four lifecycle moments adequately.
