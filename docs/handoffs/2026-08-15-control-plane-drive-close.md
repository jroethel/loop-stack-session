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

1. Kill-demo verdict: owner rejected the sonnet run and directed glm-5.2; re-run PASSED attempt 1 (ringer probe, prompt-only, strengthened fixture with an untouched decoy todo). Evidence exported to /tmp/control-plane-loop/killdemo2-evidence/. Verdict pending on the glm run.
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

## Post-merge close-out (2026-08-16, appended after the merge gate fired)

Merge gate: fired by owner delegation. main fast-forwarded to eb8e2d8; ./install.sh restored live ~/.agents links to this checkout; suite 43/43 after removing a one-time untracked leftover (skills/frontier-sandwich/references/model-benchmarks.md, generated pre-brief-3, not regenerated - verified).
Kill-demo: glm-5.2 re-run passed attempt 1 (owner-directed after rejecting the sonnet run); evidence in /tmp/control-plane-loop/killdemo2-evidence/.
Pushed to origin (main + molt-cycle-1).

### Worktree cleanup (owner fires AFTER the molt session closes)

```
git -C ~/create/loops/loop-stack-session worktree remove ~/create/loops/loop-stack-molt
git -C ~/create/loops/loop-stack-session branch -d molt-cycle-1 integration/control-plane-loop
```

### Ready-to-paste kickoff for the next session (shakedown, fresh context)

> Molt cycle 1 is merged (main at eb8e2d8, 43/43, control plane live).
> Run the first real /loop-molt against the post-change stack as its shakedown - pick one artifact (suggest skills/loop-drive/SKILL.md, the biggest policy sheet) and let the skill run its full protocol: constraint register ASK first, four bins, drift ledger line, subtraction-tested deletions.
> Read docs/handoffs/2026-08-15-control-plane-drive-close.md for state; the constraint register of docs/archive/2026-08-15-defects-check-custody-brief.md still governs (note: brief docs now in docs/briefs/ for cycle briefs 1-2, check both).
> After the shakedown: the BATCH-gated pcs disposition pass (memo-ize ~/create/pcs/2026-08-15-consolidated-recommendations.md into docs/memos/, archive the evaluation doc and kickoff prompt, confirm the protocol vendored in skills/loop-molt/references/, add the pcs pointer to the context map, surface - do not decide - the ~/create/research/ rename); then open the packaging /loop-brainstorm against the clean stack.
> Known follow-ups on the backlog: idea #30 (install.sh non-interactive guard + reviewer-prompt blacklist); loop-review standards notes (brace-scan duplication tracker.sh/lifecycle-lint.sh; lint class-d inert on github - test coverage gap).
