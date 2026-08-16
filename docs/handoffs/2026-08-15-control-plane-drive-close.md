# Handoff: brief 4 (control plane) drive complete - owner checkpoints pending

## State

Branch `molt-cycle-1` == `integration/control-plane-loop` at `52a2c48`; suite 43/43; pre-run base `6fc858d`, rollback tag `v1-pre-molt` on main.
All four molt-cycle-1 briefs are now executed; brief 4 ran as a 5-wave ringer drive (glm-5.2 all units, 6/6 green, 5/6 attempt-1, zero custody flags).

## What landed (brief 4)

- `scripts/tracker.sh`: `label ensure/add/remove` (agent:done blocked, exit 6), `comment`, `status` (one active agent:* label), `claim <n> <sid> [--reclaim]` (receipt-before-flip, race exit 4), `done <n> --receipt [--ran]` (evidence-gated, exit 5/7; regex tightened post-review), `next-eligible [<sid>]` (stale-working sweep first, then lowest unblocked todo, one per run).
- `skills/loop-drive/references/queue-runner.md`: pasteable prompt, boundary-first STOP list, canonical cycle.
- Run-state onto tickets: `AGENT STATUS` receipts via tracker.sh comment; git stays reconciliation truth (P11); relaunch never resume.
- `scripts/lifecycle-lint.sh`: classes a-d, superseded+unlinked signal (owner decision); wired into handoff skill.
- Archive demo: 19 files (6 criterion sets + 08-12 seam pair + travelling briefs) moved to docs/archive/; lint exits 0 after.
- Vocabulary single-home: config/repo-state.md "Agent status vocabulary".

## Owner checkpoints open (STOP)

1. Kill-demo verdict: blind sonnet session, queue-runner prompt only - selected stale ticket, reclaimed, relaunched, evidenced done (--ran exit 0), stopped after one. Evidence in the session log; verdict is the owner's.
2. Staged issue-closes: NONE - zero class-c/d findings on live github.
3. Merge gate (owner fires, from the main checkout - see below).

## Live-state deviation (resolved by admission)

~/.agents/skills/loop-* links were re-pointed at THIS molt worktree at 2026-08-16T01:37:39Z by the spec-axis reviewer, which executed `./install.sh; tests/run.sh` per the spec's own Task 7 How-to-run line despite its read-only instruction (confirmed by the agent itself; install.sh's non-interactive default is the agents style).
Content risk low (links point at the fully-validated cycle-1 tree); containment: the owner's merge-gate ./install.sh from the canonical checkout restores intended targets - do not double-flip before then.
Lesson filed as an idea issue: reviewer prompts must blacklist mutating repo scripts, and install.sh could refuse non-interactive runs without an explicit LOOP_STACK_SKILL_STYLE.

## Merge gate (exact commands, owner fires)

From the main checkout (the repo that owns this worktree; `git -C <main-checkout> worktree list` shows it):
  git merge molt-cycle-1
  ./install.sh
  tests/run.sh
Then the post-merge queue from the cycle kickoff: shakedown /loop-molt against the post-change stack; BATCH-gated pcs disposition pass; packaging /loop-brainstorm.

## Resume

If this session dies: docs/plans/2026-08-15-control-plane-plan_loop.md section 7 resume prompt; logs/loop/run-state.json; git is truth.
