# Batch review: slim-fold-dedup plan phase (2026-08-15)

Gate journal for the /loop-plan run on docs/briefs/2026-08-15-slim-fold-dedup-brief.md, under `auto` (session).
Brief 3 of molt cycle 1. Each entry: decision, rationale, reversal path.
Jeremy reviews this journal plus the drift ledger at the merge gate, not each deletion.

## 1. DEFAULT - plan-draft dispatch (auto-taken)

- Decision: dispatched a fresh-context Opus writer (plan-draft role pin) to decompose, draft, and self-review as one bundle; it holds only the brief, pcs Section 5/8, the constraint register, and the codebase, and writes `docs/plans/2026-08-15-slim-fold-dedup-plan.md`. The writer also tags every proposed deletion with its molt bin and surfaces any policy-deletion flags and spec problems.
- Rationale: the loop-plan skill pins Steps 3-5 to a fresh-context writer holding only the brief and the codebase; the molt-bin tagging drives the Lens B escalation rule for this brief.
- Reversal: cheap - discard the plan file and re-dispatch.

## 2. STOP - two brief criteria unreachable as written (resolved live by Jeremy)

- Decision: the plan surfaced two spec problems (skill count `7 +/- 1` unreachable, honest floor 10; line count 40%-off-3040 unreachable without cutting policy because 611 of the skills/ lines are fixed shell scripts). The driver re-verified both independently (script split re-counted: 2624 prose + 611 script; prose baseline re-derived from the tag = 2429) and halted rather than auto-soften a brief criterion. Jeremy resolved: (1) accept 10 as the skill floor; (2) re-anchor the line criterion to prose-only 40%+ (<= 1457 off the 2429 prose baseline, fixed scripts excluded). The plan's "Resolved criteria" section and Task 14's executed checks were updated to match.
- Rationale: relaxing a brief success criterion is ASK-class, never a BATCH/DEFAULT auto-take; the plan-acceptance rule makes an unmeetable criterion a spec-problem verdict on the plan, never a reason for the driver to soften it. STOP always halts under autonomy.
- Reversal: n/a - resolved live by the owner; the resolutions are recorded in the plan and re-checkable at Task 14.

## 3. DEFAULT - Rubix review ran, both lenses at Opus (auto-taken)

- Decision: ran the optional Rubix review, two parallel fresh-context Opus lenses (A: impacted professional; B: cold craft read). Lens B stayed at Opus, not Fable: the escalation trigger for this brief is a plan proposing to delete a POLICY-classified block, and the plan's policy-deletion flag list is empty (both retirements relocate policy).
- Rationale: the offer is DEFAULT-class under auto; the brief's Lens-B-to-Fable escalation is conditional on policy deletion, which did not occur.
- Reversal: n/a for the run itself (read-only); its consequences are the triage entry below.

## 4. BATCH - Rubix triage verdicts (auto-taken leans)

- Decision: 10 findings across both lenses, ALL verified against disk and ALL revised into the plan (none declined; A5 folded into A3). (A1) Task 2's retirement gate would red-fail at its own spine position - scoped to plumbing-only, repo-wide reference sweep moved to Task 14. (A2/B3) loop-which was never added to install.sh's retire list, leaving a dangling symlink on installed machines - Task 5 now appends it and asserts it, mirroring Task 2. (A3/A5) the frontier-sandwich fold and loop-which retirement lost their invocation triggers - loop-drive's frontmatter is extended to absorb them (project kickoff, model routing, human-paced run-book, "is this worth automating"), and brainstorm Step 9's stale frontier-sandwich handoff is repointed to loop-drive. (A4) three worktree hazards (nested-repo wrong-snapshot, per-worktree venv, shared-append) are correctness policy the harness does NOT do - added to Task 6's KEEP list, deleting only generic single-repo narration. (A6) the ringer-absent degraded-routing fallback is portability policy - preserved in the Task 3 canonical home, Task 6 asserts it survives. (B1) the graduation dedup was mis-justified ("ZERO graduation content" is false; the file deliberately disclaims graduation) - resized to move only the SHARED contract, rewrite the stale disclaimers, and keep improve's Supersedes-close improve-only; Task 14 sentinel replaced with a real uniqueness grep. (B2) Task 14's line-count command followed the benchmark symlink - fixed with -type f to match the git-derived 2429 baseline. (B4) test-by-subtraction probes were non-executable and behavioral risk piled onto one late checkpoint - Tasks 4/6/7 now record an executable probe per-commit. (B5) a dangling one-minute-test.md reference window - the git mv moved into Task 4. (B6) STOP/BATCH gate tags sit at the tags.sh floor in the two most-slimmed skills - explicit preserve-verbatim guards added to Tasks 6-7.
- Rationale: each finding was re-derived by a second route (grep/line-count/file-read) before acceptance; three were shipping-blockers at the retirement boundary. The two lenses independently converged on the loop-which dangling-symlink bug, raising confidence.
- Reversal: taste leans - re-run triage with the alternate verdict on any item; no finding was applied that a Task 14 executed check does not re-verify.
- NOTE for the merge gate: B1 corrects a documented on-disk design ("graduation is per-skill") to match the brief's Task 3 single-home mandate. The brief authorizes the dedup; the driver preserved the one real divergence (improve's supersede-close). Flagged here for Jeremy's merge-gate review rather than re-STOPped, since the brief he approved mandates it.

## 5. DEFAULT - self-review re-run and plan commit (auto-taken)

- Decision: re-ran loop-plan Step 5 on the revised plan (brief coverage re-mapped to the resolved criteria and the Rubix revisions; type consistency updated for the Task 4/5 mv change; the deliberate sequential share of skills/loop-which/ documented; style scan clean - zero em dashes, no placeholders), then committed the plan and this journal. Plan-acceptance rule holds: all five brief criteria (two owner-resolved) map to a Task 14 [executed-check].
- Rationale: the user review gate and commit offer are DEFAULT-class under auto; brief 3's protocol routes review to the merge gate, not a plan-approval stop.
- Reversal: cheap - `git revert` the plan commit or edit before execution consumes it.

## 6. DEFAULT - hand-off route (auto-taken)

- Decision: routed the approved plan to /loop-which for the run-shape verdict, then to /loop-drive.
- Rationale: /loop-which is the pinned recommended route in loop-plan Step 8; the autonomy continuation orchestrates the chain's next step.
- Reversal: cheap - stop after the verdict; the plan stands alone for any executor.
