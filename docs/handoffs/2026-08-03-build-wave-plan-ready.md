# Handoff: build-wave plan committed, ready to run

Date: 2026-08-03.
Session: Opus 4.8 (planning) + Jeremy; /loop-brainstorm -> /loop-plan -> rubix over the build wave.

## Where things stand

The build wave (roadmap item 1, the single active stream) now has both a committed brief and a committed, rubix-hardened plan on `main`.
Nothing is executed yet; the next session runs the plan.

- Brief: `docs/briefs/2026-08-02-build-wave-brief.md` (commit `0a2fa04`).
- Plan: `docs/plans/2026-08-02-build-wave-plan.md` (commit `44baef8`).
- Both trace to the settled ledger `docs/2026-08-02-settled-decisions-and-sequence.md`; detail lives in those artifacts, not here.

## What this session produced

- Brief via /loop-brainstorm: parked threads graduated to labeled issues #6 (status-bar surfacing) and #7 (Matt's triage/tdd/prototype - make the case or stay backlogged).
- Plan via /loop-plan: 10 tasks in 3 waves, executor-agnostic, each RED-GREEN on a bash test under `tests/`.
- Rubix review ran high-stakes at Jeremy's call: lens A = Opus (impacted-professional seat), lens B = Fable (cold craft read). All 18 findings triaged and applied; two more issues caught during verification (a missing `LOOP_SETUP_SKIP_BEHAVIOR` flag, and loop-drive carrying the space-form "Fable Sandwich" alias rather than the hyphenated id).

## What the next session must know going in

- Wave shape: W1 = tasks 1,3,4,5,6,7,9 (file-disjoint, parallel); W2 = task 2 (dep 1), task 8 (dep 1,3,5,6); W3 = task 10 (dep all). Ownership is exclusive so /loop-drive can parallelize safely.
- The gate tags already exist (seam C); "consumption" is flipping the "records intent only" disclaimers in `claude-md/fable.md` and `skills/loop-auto/SKILL.md`, proven by the wave's own drive run - not re-tagging.
- Demonstration is bootstrapped: the running session's loaded managed block still says staged, so under `auto` the orchestrator runs the new four-gate protocol by direction from Task 1's not-yet-installed prose; the clean-start proof is the post-install HC2 fresh session. See the plan's "Demonstration semantics" section.
- Two mutations are Post-wave orchestrator steps, never worker steps (they touch state outside the repo worktree): running `install.sh` and editing `~/.agents/skills/benchmark-refresh/SKILL.md`. See the plan's "Post-wave orchestrator steps" section.
- Human checkpoints, not tasks: Criterion 12 (one-voice coherence read), Criterion 2 (journal completeness: BATCH+DEFAULT entry count must equal fired-gate count), Criterion 10/HC2 (fresh-session routing check).
- Task 10 sets tags.sh per-type gate-count floors from the regenerated registry counts - a real value to fill at execution, not a placeholder.

## How to run (next session)

- Set the run shape first: `/loop-which` (recommended) for the verdict, or `/loop-drive docs/plans/2026-08-02-build-wave-plan.md` directly if it's already known to be a loop.
- Set the autonomy knob when ready: `/loop-auto set auto` (or say "run the rest"); the wave under the knob is seam C's demonstration.
- Per-task acceptance: `bash tests/gates/<name>.sh`.
- Full suite (Task 10): `LOOP_REVIEW_SKIP_BEHAVIOR=1 LOOP_SETUP_SKIP_BEHAVIOR=1 bash -c 'for t in $(find tests -name "*.sh" -not -name "build-fixtures.sh"); do echo "== $t"; bash "$t" || exit 1; done' && bash tests/gates/check.sh`

## Suggested skills

- `/loop-which` to confirm the run shape, then `/loop-drive` to compile and drive the waves - or `/loop-drive` directly.
- `/loop-auto` to set the knob once the run shape is chosen.
- `/loop-review <pre-run-base>` fires automatically as loop-drive's final-wave advisory review; no manual invocation needed.
- `/handoff` at the next session boundary.
