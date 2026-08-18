# Brief: Slim, fold, dedup the skill stack

Source: pcs evaluation, `~/create/pcs/2026-08-15-consolidated-recommendations.md` Section 5; evidence record in `2026-08-14-loop-stack-vs-research-evaluation.md`.
Sequence: brief 3 of 4 in molt cycle 1; the big one.
Note: this brief stands in for what a /loop-molt run would produce - the audit already happened in the pcs session; future cycles generate this brief via /loop-molt.

## Outcome

The stack drops from 11 skills to ~7 and roughly half its prose, with every remaining block either policy (traceable to a P-principle) or a pointer to a single home; live skills behave identically on the chain's happy path.

## Tasks

1. **Fold frontier-sandwich into loop-drive** as a human-paced output mode (the README's own "two halves of one compile step"); install.sh retires the standalone name via its existing retire mechanism; the benchmark symlink moves accordingly.
2. **Shrink loop-which to the front door**: the One-Minute Test becomes the chain's first question (before brainstorm/plan spend), either as a small skill or absorbed into the brief front-end; C6 says front door, the shipped chain had it third.
3. **Dedup to one home + pointers** (closes backlog #18):
   - Routing-chain narrative: canonical home `config/routing/model-benchmarks.md` (or one named reference); loop-drive, loop-which, wayfinder, and the folded sandwich mode carry one pointer line each.
   - Ringer footguns: only `skills/loop-drive/references/ringer-substrate.md`.
   - Brief graduation logic: only `references/brief-pipeline.md` (loop-brainstorm and loop-improve point, do not restate).
4. **Test-by-subtraction on every SKILL.md**: delete a block, run the gate tests plus one real task, keep the deletion if nothing degrades; log each kept deletion as a drift ledger line.
   Priority targets: enumerated choreography in loop-brainstorm (named probes, question cadences), loop-plan step narration, loop-drive plumbing prose.
5. **Native lane of loop-drive becomes a policy sheet**: keep checks-or-stall, validator contract (never fixes, independent rerun, pass/fail/spec-problem), per-unit routing table, gate classes, run-state format; delete prose re-describing decomposition, fan-out, background execution, notifications (the harness does these unprompted - verified 2026-08-15).
6. Start `docs/drift-ledger.md`: date, harness snapshot (v2.1.204), blocks deleted by bin, blocks kept as policy, constraints re-confirmed.

## Checkable success criteria

- `ls skills/ | wc -l` is 7 +/- 1; frontier-sandwich absent, retired by install.sh without breaking existing installs.
- Routing-chain narrative greps to exactly one file; the other skills match only pointer lines.
- Total `skills/` line count reduced 40%+ from the tagged baseline (`git diff v1-pre-molt --stat -- skills/`).
- Every deletion has a drift ledger line; every surviving non-pointer block traces to a P-principle or a constraint (spot-check 10 random blocks).
- `tests/run.sh` passes; gate registry regenerated fresh (`gen-gate-registry.sh`); one full happy-path chain run (brief -> plan -> which-verdict -> drive on a toy task) behaves as before.

## Constraint register

Same as brief 1; additionally: brainstorm/improve keep their full shaping capability (question generation, checkable criteria, seams, parking lot) - only choreography goes; the shaping lane is where frontier judgment earns its price (P4/P6).

## Parking lot

- Session-hygiene reference file and context-map extension of repo-state.md (consolidated doc 6.2, 6.4) - small, can ride brief 4's wave or graduate to issues.
- /goal as a third loop-drive transport (6.5) - blocked on its cheap existence check in a scratch repo.
