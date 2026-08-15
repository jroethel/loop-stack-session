# Brief: Build the /loop-molt skill

Source: pcs evaluation, `~/create/pcs/2026-08-15-consolidated-recommendations.md` Section 8; full spec is `~/create/pcs/harness-drift-audit-protocol.md`.
Sequence: brief 2 of 4 in molt cycle 1.

## Outcome

A thin standalone skill, `skills/loop-molt/`, that audits any instruction-prose artifact (SKILL.md, CLAUDE.md block, manual, run-book) against a dated snapshot of current harness capability, classifying blocks as PLUMBING / POLICY / PREMISE / CHOREOGRAPHY and emitting deletions, a drift ledger line, and (structural findings) a brief via the shared pipeline.

## Shape

- The protocol file is vendored into the skill as its reference doc (`skills/loop-molt/references/protocol.md`); once installed, the skill's copy is canonical and the pcs copy is the historical draft.
- SKILL.md stays thin (target under 100 lines): trigger, the one-line test, the four bins, pointers into the reference for steps 0-5.
  Practice what the protocol preaches: outcomes, not choreography.
- One implementation, two entry points: `/loop-improve` gains a one-line `--focus harness-drift` delegation to /loop-molt; no audit content is duplicated into loop-improve.
- Structural findings converge through the existing `brief-pipeline.md` machinery into a brief for /loop-plan; small findings apply inline via the subtraction test.
- Constraint register step is mandatory and ASK-class: deliberate constraints are asked before any premise is classified expired.
- install.sh picks the skill up automatically (it symlinks every `skills/*`); confirm the doctor check needs no change.

## Checkable success criteria

- `./install.sh` installs /loop-molt; skill loads (metadata visible to a fresh session).
- `tests/gates/` gains a molt suite: trigger phrases present, gate tags well-formed (constraint register ASK gate present), reference file exists.
- `grep -c "PLUMBING\|POLICY\|PREMISE\|CHOREOGRAPHY"` finds the bins defined in exactly one file (the reference), pointed to by SKILL.md.
- loop-improve contains the delegation line and zero duplicated audit procedure.
- Smoke run: /loop-molt against one small artifact (suggest `skills/handoff/SKILL.md`, 21 lines) produces a classification, a drift ledger line, and no unprompted edits.
- `tests/run.sh` passes clean.

## Constraint register

Same as brief 1 (see `2026-08-15-defects-check-custody-brief.md`); additionally: molt itself must not require Claude Code to run conceptually - the protocol is harness-agnostic prose, only the skill wrapper is Claude-Code-specific.

## Parking lot

- A molt run-cadence reminder mechanism (hook or calendar) - idea issue, not now.
- Molt applied to the fable-manual and self-manual - after the skill exists.
