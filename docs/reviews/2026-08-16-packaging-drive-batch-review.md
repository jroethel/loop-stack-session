# Batch review - packaging drive, 2026-08-16

Run: /loop-drive docs/plans/2026-08-16-packaging-plan.md, autonomy `auto` (session), journal opened at first gate.
Entries are chronological; BATCH and DEFAULT entries are the review obligation, ASK and STOP entries are record-only.

## 1. [BATCH] Step 0 topology lean

- Decision: linear four-wave chain (one ringer unit per wave, per-unit validator, orchestrator gate), no parallel shape diagrammed.
- Rationale: the source plan records the strict dependency chain as a deliberate deviation from wave-parallel; no alternate shape is within 60/40.
- Reversal path: scoped re-run of the compile with a parallel lean if a genuinely independent unit pair is later identified (taste reversal, re-run with alternate lean).

## 2. [BATCH] Pin review: T3 collapsed into an orchestrator gate action

- Decision: T3 (clean-room harness) is not dispatched to a worker; the orchestrator writes `scripts/clean-room.sh` verbatim from the source plan at the W3 gate, runs it for real, and commits on green.
- Rationale: T3's sole deliverable is its own fully verbatim check file; a worker could only transcribe bytes that must match a golden copy, adding no information while adding a custody surface. All four criteria proofs (install, suite, #30 refusal, degraded probe) still execute unchanged, so no scope narrows.
- Reversal path: scoped W3 re-run as a dispatched ringer unit with golden-diff custody (taste reversal).

## 3. [DEFAULT] Step 7 execution-details question auto-taken

- Decision: the "See execution details before I launch?" question was not asked; the default (nothing selected, launch immediately) was taken.
- Rationale: autonomy is `auto` and this gate is DEFAULT-class; the dry-run substance still happens because section 5's pre-flight executes for real before wave 1, and the dashboard substance (condensed routing + topology) was shown in the driving session before compile.
- Reversal path: cheap - stop the run and present the dashboard/dry-run menu live at any point on request.

## 4. [BATCH] Wave-1 distill: mirror-regen line added to wave 2+ specs

- Decision: wave 2+ implementer specs gain one line - if `ISSUES.md`/`BACKLOG.md` are absent in the worktree, run `scripts/gen-mirrors.sh .` before `tests/run.sh`.
- Rationale: T1 attempt 1 failed only because the gitignored generated mirrors do not exist in a fresh worktree; this is the P10 distill of that failure, confined to spec scaffolding, well under the 15-line threshold, and it changes no unit's produced contract.
- Reversal path: cheap - drop the line from the next spec (git revert of nothing; the spec templates are launch-time artifacts).

## 5. [BATCH] Spec-problem fix: sandbox guard in tests/repo-state/live.sh

- Decision: `live.sh` gains an 8-line guard - SKIP (exit 0) when the checkout's origin is not a GitHub remote; the source plan's Task 3 section records the amendment.
- Rationale: Task 3's clean-room harness was unsatisfiable as specified - `live.sh` hard-gates on mirrors plus a live `gh issue list`, but a clean-room clone's origin is a local path with no gh auth, and proof 3 is offline by design; the wave-1 worker independently flagged the same defect. The edit is confined to one criterion's satisfiability, leaves T3's produced contract (verbatim `clean-room.sh`) unchanged, is under 15 lines, and has zero blast radius on the primary checkout, where the origin is a GitHub remote and the guard never fires.
- Reversal path: `git revert` of the guard commit on `integration/packaging-loop`.
