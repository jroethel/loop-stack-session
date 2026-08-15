# Brief: Known defects + check custody rule

Source: pcs evaluation, `~/create/pcs/2026-08-15-consolidated-recommendations.md` Sections 6.3 and 6.6.
Sequence: brief 1 of 4 in molt cycle 1; smallest, do first.

## Outcome

The two recorded defect sets are fixed, and the check custody rule exists in loop-drive so workers can never own or touch acceptance-check files.

## Tasks

1. Actually gitignore `docs/chain-state.md` (declared gitignored in loop-auto and repo-state but never added to .gitignore; found in `docs/memos/2026-08-10-to-loop-stack.md`).
2. Apply the 2026-08-10 memo's remaining gitlab-mode findings: GitHub-first template leaking into gitlab render; governed-lane briefs unreachable by the import sweep with only a soft approval gate; tracker-mode question needs `none` and combinations; missing gitlab remote-create hint.
3. Add the check custody rule to loop-drive (one sentence class): acceptance-check scripts live outside every worker's file ownership; a worker diff touching a check file is an automatic scope violation, not something to resolve.
   Rationale: METR o3 gamed a loop's success criterion 21/21 runs; the check is the attack surface (consolidated doc 6.3).
4. Optional if cheap: a lint in the compile step that flags any manifest where a task's file ownership overlaps its own or any sibling's check path.

## Checkable success criteria

- `git check-ignore docs/chain-state.md` exits 0.
- Each memo finding has a matching change and a test where the tests/ suites cover that area (loop-setup and repo-state suites).
- `grep -l "custody\|check file" skills/loop-drive/` returns the SKILL.md or a reference; the rule states the scope-violation consequence.
- `tests/run.sh` passes clean.

## Constraint register (applies to all molt cycle 1 briefs)

- /workflows stays off (verified 2026-08-15); do not design around it.
- Portability is standing: the stack must run outside Claude Code; ringer is the spine, native primitives the optional lane.
- Do not worsen: the `~/repos/ringer` hardcode, absolute-path symlinks, `claude-zai.sh` env specifics, the /dev/tty question (#28), macOS/Linux/WSL differences.
- Packaging comes later; single-home-plus-pointers structure is mandatory in anything touched now.
- Fable is never spawned as a worker; effort capped at high.

## Parking lot

- The compile-step ownership lint if it turns out non-trivial (graduate to an issue instead).
