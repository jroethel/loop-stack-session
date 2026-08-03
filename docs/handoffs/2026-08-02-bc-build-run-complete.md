# Handoff: seams B + C shipped; next session runs the build wave

Date: 2026-08-02.
Session: Fable 5 + Jeremy; /loop-plan -> rubix -> /loop-drive over both seam briefs, merged and pushed as `9bfc6c4`.

## Where things stand

Seams D, B, and C are all on `main` and pushed; the integration branch is deleted.
This repo now conforms to its own state convention: orient from `config/repo-state.md`, `docs/roadmap.md`, `ISSUES.md`, `BACKLOG.md`, and this directory.
The run's full record is `docs/plans/repo-state-autonomy-loop-state.md`; the plan and its orchestration compile sit beside it in `docs/plans/`.
Detail lives in those artifacts and in `learning_guide.html` section 18; this doc does not repeat them.

## Active stream (scope rule applies)

The build wave is roadmap item 1 and the single active stream; see the Scope rule in `config/repo-state.md`.
Shape: one brief, then /loop-plan, then /loop-drive, applying the settled ledger (`docs/2026-08-02-settled-decisions-and-sequence.md`) in one pass across the chain skills.
It runs under the autonomy knob as seam C's demonstration; until it wires gate-tag consumption, `/loop-auto` records intent only.
Backlog issues #4 and #5 are natural riders on this wave; pulling any other backlog item is an explicit, announced choice.

## What the next session should know going in

- The gate journal format (batch-review list) and the scope rule were refined at the judgment checkpoints on 2026-08-02; the managed CLAUDE.md block and `docs/reviews/2026-08-02-sample-batch-review.md` are current - implement the journal as spec'd there, not the older end-of-run-only shape.
- Recorded debt from the advisory review (candidates for the wave, not obligations): duplicate STOP rows in `docs/gate-registry.md` (two gates tagged on one loop-drive line), awk pipe-escape divergence between `scripts/gen-mirrors.sh` and `scripts/gen-gate-registry.sh`, and a shared disclosed-header emitter.
- HC2 (fresh-session routing check) folds into build-wave verification.
- Worker routing evidence: glm-5.2 via claude-zai went 7/7 first-try on code-feature this run; the scoreboard posterior is current.

## Suggested skills

- `/loop-brainstorm` for the build-wave brief (its parking-lot auto-graduation is itself a build-wave deliverable, so graduation is still manual this once).
- `/loop-plan`, then `/loop-drive` per the chain.
- `/loop-auto` to set the knob once the plan is approved.
- `/handoff` at the session boundary (writes here and refreshes the mirrors).
