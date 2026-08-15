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

## Task 5 - retire loop-which

- Decision: removed the loop-which dir (bin CHOREOGRAPHY - the scoring narration), added it to install.sh's retire list, dropped it from tags.sh's SKILLS list, and rewrote the gate as `loop-which-retired.sh`. Recorded the retired standalone-triage-trigger as a deliberate decision (Rubix A5).
- Rationale: the One-Minute Test policy already relocated in Task 4; the dir is now pure retirement plumbing. The retire-list entry is load-bearing (prevents a dangling stale symlink on an installed machine). Post-retire gate counts stay at/above every floor, so floors are unchanged.
- Scope note: converted no stale `loop-which` references - every skill-invocation ref lives in a later-task-owned file (loop-drive/plan/improve/molt/README), so each converts in its own task per the serial spine; the config attributions are descriptive, not invocations. Downstream watch: Task 7's loop-plan steps do not explicitly call out its three bare-word `loop-which` refs (frontmatter, diagram, terminal) - flagged for that task.
- Reversal: `git revert` the Task 5 commit.

## Task 6 - loop-drive policy sheet (highest blast radius)

- Decision: cut the harness-plumbing narration (generic worktree creation, parallel-background launches, completion notifications) and wave-derivation mechanics; single-homed routing (Task 3 pointer) and ringer footguns (ringer-substrate.md pointer); deleted `example-output-plan.md` wholesale (bin CHOREOGRAPHY - the SKILL's Step 6 emit-spec is self-sufficient); slimmed `native-orchestration.md` to two native-lane policies; folded frontier-sandwich in as a human-paced output mode; extended the frontmatter to absorb the retired triggers. Ran the executable compile probe.
- Rationale: v2.1.204 does decomposition/fan-out/background/notifications/single-repo-worktrees unprompted, so re-narrating them is deletable PLUMBING. The three nested-repo/venv/shared-append worktree hazards are kept as POLICY because the harness gets the nested case WRONG and test-by-subtraction can't catch their loss (Rubix A4). Every STOP/BATCH gate tag preserved verbatim (they sit at the tags.sh floor, Rubix B6). The probe confirmed the compile path still emits the full policy surface.
- Deletion I was deliberate about: `example-output-plan.md` deleted rather than slimmed - a worked skeleton is illustration a frontier model reproduces from the emit-spec, not policy. Kept only because the SKILL Step 6 nine-item emit-spec fully determines the output shape; verified by the compile probe emitting a correct routing table without it.
- Reversal: `git revert` the Task 6 commit restores the two references and the pre-slim SKILL.

## Checkpoint 1 - orchestrator verification of Tasks 1-6 (2026-08-15)

- Re-ran `tests/run.sh` independently: 37/37 green at `c17170b`. Roster = 10 skills; frontier-sandwich + loop-which absent; both in install.sh retire list (`:85`).
- Adjudicated the Task 4 check-file change (check-custody: a human, not the worker, accepts a check edit). The change to `tests/gates/loop-improve.sh:70` is a legitimate design-sync, NOT a reward-hack: it INVERTS the stale "graduation is per-skill" guard into the brief-mandated single-home guard AND adds a new guard that improve's `Supersedes:` must not leak into the shared reference. Verified the new guard BITES (fails on a shared ref missing the contract) and is satisfied by real content; verified improve's supersede-close is preserved (2 refs in loop-improve/SKILL.md) and absent from the shared ref. Accepted.
- Plan gap recorded for the merge gate: Task 4's ownership should have included `tests/gates/loop-improve.sh` (the check that guards the design it changes). The worker's minimal inversion is correct; the process point (a worker touched an unowned check file) is flagged for Jeremy, who adjudicates check changes.
- Spot-checked loop-drive (highest blast radius): frontmatter absorbed all folded/retired triggers (A3/A5); nested-repo hazard kept (A4); ringer-absent fallback survives in SKILL + config home (A6); `scoreboard posterior` = 0 in the SKILL; footguns single-homed. Prose 2624 -> 2012 after 6 tasks (target <=1457 reachable across the remaining 8 slims).

## Task 7 - loop-plan slim

- Decision: cut the AskUserQuestion tool mechanics + Other-handling to the frontier-rounds decision content (bin CHOREOGRAPHY), compressed the Rubix flavor + verbose lens A/B descriptions to one line each, tightened the Step 7 review-gate narration, and collapsed the pipeline-diagram routing. Converted the three bare-word `/loop-which` refs (frontmatter, diagram, Step 8 handoff) to /loop-drive's front-door triage per the carried-forward bare-reference cleanup.
- Rationale: the tool-call cadence and Other-response branching are ordering a frontier model runs unprompted; the Rubix lens paragraphs restated what the one-line description already conveys. All teeth kept verbatim - the header/task templates, the loop-drive contract bullets, the no-placeholder list, code policy, self-review checklist, plan-draft/Opus pin, prefactor/expand-contract, Rubix role pins, and every gate tag (incl. the `[gate:BATCH]` at the tags.sh floor).
- Budget: policy-preserving near-miss. Target 222 -> ~150; landed 223 -> 198. The ~70-line verbatim template block (explicit KEEP) plus KEEP decision content floors the file above ~150; reaching the number would cut POLICY, so per the plan's Human-checkpoint the shortfall is recorded, not cut. `bash tests/gates/loop-plan.sh` passes; `scoreboard posterior` = 0; 37/37 green.
- Reversal: `git revert` the Task 7 commit.

## Task 8 - loop-improve + audit-playbook slim

- Decision: compressed the audit-playbook's verbose prose (Security handling/by-design, Direction) to its checkable core while keeping every category's file:line criteria (bin CHOREOGRAPHY on the prose only); reduced the SKILL Step 6 graduation restatement to a pointer at `brief-pipeline.md`, removing the last "truncates the title"/"period-free" duplicate (single-home now exactly one file); rewrote the stale "shared reference contains NO graduation" sentence; dropped the terminal-step `/loop-which` ref.
- Rationale: the graduation narration was duplicated across the shared reference and improve Step 6 - the shared contract moved in Task 4, so improve keeps only a pointer plus its improve-only supersede-close (kept verbatim). The audit criteria are improve's shaping capability, constraint-register-protected, so only prose narration was cut, not criteria. The `/loop-which` ref named a route improve explicitly does not take, so it was dropped, not substituted.
- Probe: findings-table contract gate-verified by `tests/gates/loop-improve.sh` (eight columns, covered/related, tracker scan); no full audit run spent since the gate covers exactly the probe's checks.
- Budget: policy-preserving near-miss. audit-playbook 188 -> 178 (target ~120), SKILL 99 -> 95. Reaching ~120 would gut checkable audit criteria (POLICY per "improve keeps full shaping capability"), so kept and recorded per the Human-checkpoint. 37/37 green; single-home grep = 1 (brief-pipeline.md).
- Reversal: `git revert` the Task 8 commit.

## Task 9 - loop-molt + protocol slim

- Decision: collapsed the SKILL's Step 0-5 narration (a second copy of the protocol's running order) into a thin numbered pointer list; compressed the protocol's refresh/where-molt-sits/wiring narrative; dropped the stale `/loop-which` node from the downstream chain arrow in both files.
- Rationale: the SKILL explicitly bills itself as "the thin wrapper, the protocol is the method", yet the per-step paragraphs restated the protocol - pure CHOREOGRAPHY. Verified no UPPERCASE bin token leaked into SKILL.md (`molt.sh` fails if they do) - grep clean. The four-bin table, membership test, subtraction, constraint-register gate and steady-state definition all kept as the method's single home.
- Budget: policy-preserving near-miss. protocol 98 -> 90 (target ~78), SKILL 91 -> 56. Reaching ~78 would cut method POLICY, so kept and recorded per the Human-checkpoint. `bash tests/gates/molt.sh` passes; single-home bins hold; 37/37 green.
- Reversal: `git revert` the Task 9 commit.

## Task 10 - wayfinder slim + routing pointer

- Decision: converted the per-ticket routing line to the Task 3 pointer (`scoreboard posterior` now 0), then compressed the procedural narration across every prose section to its decision content, keeping the map/ticket schema code blocks, all labels, the four ticket types, fog/out-of-scope rules, one-ticket-per-session, and the /loop-plan + /loop-brainstorm hand-offs verbatim-in-spirit.
- Rationale: the section prose repeatedly re-explained rules a frontier model applies from one statement - CHOREOGRAPHY. The schema blocks and the rule set are POLICY (wayfinder.sh asserts schema, labels, hand-offs, mirror exclusion) and were preserved.
- Budget: small policy-preserving near-miss. 183 -> 142 (target ~125); the schema code blocks + decision content floor it, so kept per the Human-checkpoint. `bash tests/gates/wayfinder.sh` passes; `scoreboard posterior` = 0; 37/37 green.
- Reversal: `git revert` the Task 10 commit.

## Task 11 - loop-setup + import-triage slim

- Decision: folded the per-mode setup.sh narration to one tighter block, compressed the import-sweep walkthrough and the import-triage framing/on-approval prose, and dropped the redundant second example table in the D1 record section. `setup.sh` untouched.
- Rationale: the per-mode step-by-step re-describes what setup.sh does - CHOREOGRAPHY. All test-required strings kept (three modes, four remote-report strings, LOOP_IMPORT_REMOTE, LOOP_TRACKER_ANSWER=gitlab, "but the remote is", migrate-tracker, tracker-remote-ack, "declin"; "one actionable item"/"split"/"merge" in the reference). The import-sweep triage judgment is loop-setup's shaping capability (constraint-register-protected) and was preserved.
- Budget: policy-preserving near-miss. SKILL 100 -> 87 (target ~85, met), import-triage 130 -> 114 (target ~95). The judgment rules + record-doc/footer contracts are POLICY; kept and recorded per the Human-checkpoint. 37/37 green; em-dash check clean.
- Reversal: `git revert` the Task 11 commit.

## Task 12 - loop-review slim

- Decision: compressed the process narration (fixed-point pinning, discovery tail, disclosure, spawn framing, aggregate) to decision content, and removed the illustrative second `Mysterious Name` inside the Standards subagent prompt so the baseline token appears exactly once.
- Rationale: the plan's Task 12 acceptance is `grep -c 'Mysterious Name'` = 1, but the file carried two (baseline + a prompt example) - the example was redundant choreography, dropped by rephrasing to "its exact baseline label". The Fowler 12-smell baseline is kept VERBATIM (the Standards axis has no other access to it); the two subagent prompts, discovery ladder, disclosure contract, and empty-diff trap message all kept.
- Budget: policy-preserving near-miss. 128 -> 112 (target ~105). The 12-smell baseline + two verbatim prompts + discovery ladder are POLICY, so kept per the Human-checkpoint. `grep -c 'Mysterious Name'` = 1; 37/37 green (`tests/loop-review/` suites pass).
- Reversal: `git revert` the Task 12 commit.
