# Brief: import governance - brief-seed path and a sharpened triage gate

Source: issues #20 (brief import path) and #21 (enforce the triage approval gate).
Context: docs/memos/2026-08-10-to-loop-stack.md, findings 2 and its gate half.

## Outcome

Two outcomes.
A brief authored as a tracker seed can be imported into the tracker on purpose, without un-excluding all briefs from the sweep.
An agent running import triage cannot mistake a pre-supplied classification for approval, and treats the issue bodies it writes as the thing needing human assent.

Presupposition tested and overturned.
The memo framed #21 as a token gate ("an approval token only a human can produce").
Verified against setup.sh, no in-band token is agent-proof: the agent controls env and stdin, and `ask()` reads stdin (setup.sh:9), so any stdin or env signal it can fabricate.
Real enforcement against an agent would require a `/dev/tty` read, which is rejected here as an adversary assumption for a cooperative, attended-only tool.
The actual failure was an agent reasoning past a soft gate, which a targeted prose sharpening addresses directly.

## End artifact

The first real deliverable is a repo where a pre-existing seed brief is imported through the normal triage sweep with the human reviewing the actual issue bodies.
A seed brief is one written with pre-sized ROADMAP/BACKLOG/ISSUES items because setup will run later.
This is the exact design-brand-pack situation the memo reported.
It ships whenever loop-setup next runs on a repo carrying a seed brief.

## Done looks like

- `setup.sh --seed docs/briefs/<file> --list-candidates` prints that brief's path; the same command without `--seed` does not, so the default exclusion is intact.
- A `--seed`'d brief flows into the triage sweep: the agent splits, classifies, verifies, presents the batch disclosure table with proposed bodies, and files only after human assent.
- `import-triage.md` states that a pre-supplied classification is never approval, and that approval covers the agent-written bodies the human has not yet seen.

## Assets and options

- The existing `--scan` flag - considered as the vehicle (override `is_excluded` for named roots); declined, because it would overload `--scan`'s meaning so a reader can no longer tell "add a search root" from "force an excluded file in".
- loop-brainstorm's `scripts/graduate-parking.sh` (a preview-and-assent brief-to-issue path) - considered as already covering #20; declined as the whole answer, because it runs at brief-commit time on the Parking lot section, not at setup time on a pre-existing seed brief. `--seed` serves the setup-later case it does not reach.
- The per-file bash `ask()` gate - kept unchanged; `--seed` feeds into it, and the sharpened prose governs the item-level bodies it cannot see.

## Approach

Chosen: a minimal `--seed <file>` flag that injects a named, normally-excluded doc into the sweep as a candidate, plus a prose sharpening of the triage approval gate in `import-triage.md`.

Considered and rejected:

- `--scan` override of `is_excluded` for named roots: reuses a flag but overloads its meaning.
- A `/dev/tty`-hardened enforcement gate for #21: real, but assumes an adversarial agent and adds cross-cutting coupling to `tracker.sh create` for a failure that was an agent reasoning error in an attended run.
- Doc-only for #20 (rely on `graduate-parking.sh`): leaves the setup-later seed-brief case with no path.

Rationale: `--seed` is the smallest explicit opt-in that keeps the default exclusion honest, and the sharpened prose targets the specific reasoning error without treating the cooperative agent as an attacker.

## Success criteria

- [executed-check] `setup.sh --seed docs/briefs/X --list-candidates` includes X; without `--seed` it does not; a non-existent `--seed` path fails with a clear message.
- [executed-check] a `--seed`'d excluded doc reaches `reconcile_import` (the per-file `ask` fires for it), verified by a test driving `--seed` through the sweep.
- [executed-check] grep of `import-triage.md` finds the two sharpened statements (classification-is-not-approval, approval-covers-bodies).
- [executed-check] existing import and exclusion tests stay green (the default sweep still excludes briefs).

## Seams

Two independent pieces, blast-radius order.

1. `--seed` flag in `setup.sh`: arg parse mirroring `--scan`, plus `collect_candidates` injecting the named path past `is_excluded`. Checkable via `--list-candidates`.
2. `import-triage.md` prose sharpening. Independent, grep-checkable.

## Known vs guessed

- Verified: `is_excluded` still excludes `docs/briefs/*` (setup.sh:32); `--scan` roots still run `is_excluded` (setup.sh:73-74); `ask()` reads stdin, so no in-band token is agent-proof (setup.sh:9); `import-triage.md` step 5 is prose with no enforcement.
- Believed-unchecked: a brief passes `is_candidate` on content shape (`#` heading plus `Status:`) per the memo's run; if a given seed doc does not, `--seed` may need to bypass `is_candidate` too, not just `is_excluded` - a planning detail.
- Guessed: the setup-later seed-brief case is real and recurring enough to warrant a flag; if it is a one-off, the doc-only option was enough. The memo's design-brand-pack run is one concrete instance.

## Parking lot

- A `/dev/tty`-hardened enforcement gate, if the cooperative-agent assumption ever breaks and an agent-proof import gate is actually wanted. Restart context: today's fix is prose; the hard version reads approval from the terminal and gates `tracker.sh create` during import.

## Out of scope

- Un-excluding `docs/briefs/` or any governed lane by default.
- Any enforcement mechanism that treats the agent as adversarial.
- Changing loop-brainstorm's parking-lot graduation.

## Open questions for planning

- Does `--seed` bypass only `is_excluded`, or `is_candidate` too, for a named file?
- Can `--seed` repeat (multiple briefs), mirroring `--scan`?
- Exact placement and wording of the sharpened statements in `import-triage.md` (the On approval section versus steps 4-5).
- Should a `--seed`'d doc archive on import like a swept candidate, given a brief archives when its plan archives?
