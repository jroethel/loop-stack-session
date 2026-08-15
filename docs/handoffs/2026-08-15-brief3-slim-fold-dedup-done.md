# Handoff: molt cycle 1 brief 3 (slim/fold/dedup) - DONE

Date: 2026-08-15. Branch: `molt-cycle-1` (15 commits ahead of `main`, which is at brief 2 `59a2006`). Rollback tag: `v1-pre-molt`.

## What brief 3 produced (the repo state brief 4 plans against)

- **Stack is 10 skills** (was 12): `frontier-sandwich` retired -> loop-drive's human-paced output mode; `loop-which` retired -> loop-brainstorm's Step 0 One-Minute Test front door. Both retirements relocate policy; none deleted. Both are in `install.sh`'s retire list (`:85`).
- **loop-drive is a policy sheet**: native-lane plumbing cut; KEEP list intact (checks-or-stall, validator contract, per-unit routing table, gate classes, run-state, check custody, the three Agent-tool worktree hazards, ringer-absent degraded-routing fallback). Frontmatter absorbed the retired skills' triggers.
- **Single-homed** (each greps to exactly one file): routing-chain narrative -> `config/routing/model-benchmarks.md`; ringer footguns -> `skills/loop-drive/references/ringer-substrate.md`; shared brief-graduation contract -> `skills/loop-brainstorm/references/brief-pipeline.md` (loop-improve's `Supersedes:` supersede-close kept improve-only).
- **Prose**: 2429 -> 1833 (skills/ `.md`, scripts excluded) = 24% cut, owner-accepted as the policy-preserving floor.
- Gate state: `tests/run.sh` 37/37; registry content-fresh; tree clean.

## Open flags for the MERGE GATE (Jeremy fires it)

1. **Line-count floor**: 24% accepted (vs the 40% target, which was an optimistic estimate). Recorded in the ledger closing summary.
2. **Check-custody note**: the structural driver inverted one assertion in `tests/gates/loop-improve.sh` (a check file the plan failed to assign to Task 4) so the brief's graduation single-home mandate and a green tree could both hold. Independently verified as a legitimate design-sync that STRENGTHENS the guard (not a reward-hack). Drive journal, Checkpoint-1 entry.
3. **handoff choreography lines**: two lines removed under an "owner-review-before-removal" ledger flag; subtraction test green. Restore the "reference-by-path, don't duplicate" line if that discipline should stay explicit. Drive journal, Task 13.

## Artifacts

- Plan: `docs/plans/2026-08-15-slim-fold-dedup-plan.md` (rubix-revised; Resolved criteria section holds the two owner decisions).
- Journals: `docs/reviews/2026-08-15-slim-fold-dedup-plan-batch-review.md` (plan phase), `...-drive-batch-review.md` (drive phase, Tasks 1-14 + Checkpoint-1).
- Drift ledger: `docs/molt-ledger.md` (13 per-artifact entries + closing summary).

## Merge gate (staged - Jeremy fires; run from the MAIN checkout, not this worktree)

```
cd <main checkout: ~/create/loops/loop-stack-session>
git merge molt-cycle-1
./install.sh
tests/run.sh
```

Timing is Jeremy's call: merge brief 3 now, or continue to brief 4 (control-plane) on `molt-cycle-1` and merge the cycle together. Brief 1+2 merged together (main is at brief 2), which suggests batching is fine.

## Next

- **Brief 4 (control-plane)**, fresh session, Opus: autonomy pause; `/loop-plan` WITH rubix, Lens B at Fable, BEFORE Jeremy's review; STOP for approval; execute only after he approves, then autonomy auto. Plans against THIS repo state.
- **After brief 4 merges**: first real `/loop-molt` shakedown, then the BATCH-gated pcs disposition pass, then the packaging `/loop-brainstorm`.
