# Build-wave orchestration plan (compiled by /loop-drive, 2026-08-03)

This file is the machine-run form of `docs/plans/2026-08-02-build-wave-plan.md`.
The source plan remains the manual fallback and stays ground truth for every task's scope, steps, and acceptance.
This file only adds the orchestration shape: routing, transport, hazards, gates, and resume.

## Routing table

| Unit    | Wave | task_type    | Model   | Transport | Engine     | Impl. effort | Val. effort     | Evidence  |
| ---     | ---  | ---          | ---     | ---       | ---        | ---          | ---             | ---       |
| Task 1  | 1    | docs         | glm-5.2 | ringer    | claude-zai | medium       | check+gate      | posterior |
| Task 3  | 1    | docs         | glm-5.2 | ringer    | claude-zai | medium       | check+gate      | posterior |
| Task 4  | 1    | docs         | glm-5.2 | ringer    | claude-zai | medium       | check+gate      | posterior |
| Task 5  | 1    | code-feature | glm-5.2 | ringer    | claude-zai | high         | check+gate      | posterior |
| Task 6  | 1    | docs         | glm-5.2 | ringer    | claude-zai | medium       | check+gate      | posterior |
| Task 7  | 1    | code-feature | glm-5.2 | ringer    | claude-zai | high         | check+gate-read | posterior |
| Task 9  | 1    | code-fix     | glm-5.2 | ringer    | claude-zai | medium       | check+gate      | posterior |
| Task 2  | 2    | code-feature | glm-5.2 | ringer    | claude-zai | high         | check+gate      | posterior |
| Task 8  | 2    | code-fix     | glm-5.2 | ringer    | claude-zai | medium       | check+gate-read | posterior |
| Task 10 | 3    | code-fix     | glm-5.2 | ringer    | claude-zai | high         | check+gate      | posterior |

Evidence footnote: integrity-gated scoreboard posterior, read 2026-08-03 from `~/repos/ringer` (`./ringer.py models`): glm-5.2 via claude-zai is proven tier on docs (3 tasks, 100%), code-fix (6 tasks, 100%), and code-feature (22 tasks, 86% pass, 82% first-try).
`docs/AMENDMENTS-PENDING.md` is empty (the ringer #65 stm-nav misattribution is resolved), so the posterior is trusted as read.
The claude-zai flat-rate lean concurs; no unit carries an aesthetic criterion, so no taste flag.
No pin was needed; effort is capped at high everywhere.

## Orchestration shape

```
Fable (orchestrator, this session)
  |
  |  Wave 1 ── ringer manifest: tasks 1,3,4,5,6,7,9 (glm-5.2, parallel, worktrees)
  |            each task: executed check -> patch export -> orchestrator gate
  |  GATE 1: apply patches to `build-wave`, per-task commits, rerun tests, MODEL-NOTES receipt
  |
  |  Wave 2 ── ringer manifest: tasks 2,8 (after orchestrator pre-applies task 2's test edit)
  |  GATE 2: same ritual
  |
  |  Wave 3 ── ringer manifest: task 10 (regenerate registry, retire tags-only guard, full suite)
  |  GATE 3: same ritual + full suite on `build-wave`
  |
  |  advance: merge `build-wave` -> main, advisory /loop-review <pre-run-base>
  |  STOP: post-wave orchestrator steps (install.sh, benchmark-refresh edit) - never auto-taken
```

Three validation layers: the worker's own test run inside the worktree, the executed ringer check (test rerun + test-file-untouched guard + ownership audit + patch export), and the orchestrator gate (run JSON + logs + diff read + integration-branch test rerun).
No native validator subagents: every unit's acceptance is a deterministic executed check, so a second model adds cost, not evidence; the orchestrator's gate diff read covers judgment, with a close read on tasks 7 and 8 (port quality, sweep completeness).

## Hazard mitigations (deviations marked)

- Worktree isolation, per-task dirs, and log separation come from run-level `worktrees: true`; not re-specified.
- Patch export: workers leave changes uncommitted; each check runs `git add -A && git diff --cached > <workdir>/<key>.patch`; the orchestrator applies and commits on `build-wave`. Deviation from the source plan's per-task worker commits: the orchestrator makes each plan-named commit at the gate, preserving commit-per-task as resume ground truth.
- RED pre-commit: the orchestrator commits the plan's verbatim test files and RED-verifies them before each wave; workers are GREEN-only and their checks assert the test file is untouched. Deviation from the source plan's worker-written Step 1s; it removes the test-weakening hazard.
- No gitignored deliverables exist in any task, so no copy-out step is needed.
- claude-zai workers do not touch opencode's sqlite store; no stagger needed. `max_parallel: 4`.
- Shared files: none within any wave (ownership is exclusive by construction); a merge conflict at a gate is a scope violation, not something to quietly resolve.

## Pre-flight

- [x] ringer present at `~/repos/ringer` (capability probe); engines `claude`, `claude-zai`, `opencode` configured; no degraded mode.
- [x] Tree clean at `3b32fc8`; knob is `auto` in `docs/chain-state.md`.
- [x] `gh` authed (jroethel); wayfinder source exists at `~/repos/mattpocock/skills/skills/engineering/wayfinder/SKILL.md`; `~/.agents/skills/fable-sandwich/` exists.
- [ ] Integration branch `build-wave` created from main and checked out (worktrees detach from its HEAD).
- [ ] Workdir `~/.ringer/work/build-wave-2026-08-03/` created; logs land in `<workdir>/logs/`.
- [ ] Per-wave manifest linted before run.

## Wave loop and gates

Per wave: orchestrator pre-commits that wave's verbatim test edits and RED-verifies them, emits the wave manifest, lints, runs `./ringer.py run` with `run_name: build-wave` (same across all waves).
At the gate: read the run JSON in `~/.ringer/runs/`, read every retried or failed task's raw log, spot-check one passing artifact, apply patches in task order with `git apply --index`, make the plan-named commit per task, rerun that wave's tests on `build-wave`, write the wave summary to the run-state file, and append a dated MODEL-NOTES receipt in `~/repos/ringer` (one line per model+task_type per wave, committed before advancing).
On a FAIL, attribute before relaunching: rerun the check's steps by hand; a check bug means fix the check, commit the audited work, and annotate MODEL-NOTES, not a burned retry.
Ringer's built-in single retry is the repair pass; a task that fails twice is a stopped unit and does not block its siblings.
A stopped unit's small spec fix (single unit, contract unchanged, 15 lines or fewer) auto-takes as BATCH and is journaled; anything larger is STOP.
Advance only when the wave's tests are green on `build-wave`.

Ask-the-human list (STOP, never auto-taken): dirty-tree surprises at pre-flight, any request to exceed the high effort cap, spec edits above the BATCH threshold, any outward-facing unit, and the two post-wave global mutations (`LOOP_STACK_SKILL_STYLE=agents ./install.sh` from merged main, and the `~/.agents/skills/benchmark-refresh/SKILL.md` edit).
No unit in this plan is outward-facing; task 5 and 7 tests are fixture/dry-run only, and the sole live-`gh` leg (`tests/repo-state/live.sh`) is read-only.
After wave 3 is green and the run advances: merge `build-wave` to main (DEFAULT, journaled, revert is the reversal), then run the advisory `/loop-review <pre-run-base>` (BATCH, non-blocking, findings recorded at the final checkpoint), then STOP for the post-wave steps and the human checkpoints (Criterion 12 one-voice read, Criterion 2 journal completeness, Criterion 10 / HC2 fresh session).

## Quota and resume

Durable state: every gate ends in commits on `build-wave`; the run-state artifact `docs/plans/2026-08-02-build-wave-run-state.md` is updated at every launch and gate; the journal is `docs/reviews/2026-08-03-build-wave-batch-review.md`.
Reconciliation trusts git over the state file: a task whose plan-named commit exists on `build-wave` is done; any other task relaunches fresh (never resumes); check `~/repos/ringer` for an uncommitted MODEL-NOTES receipt owed by the last gate.
Resume prompt (verbatim):

> Resume the build-wave drive run.
> Read `docs/plans/2026-08-02-build-wave-plan_loop.md`, then reconcile: `git -C /Users/jjrdar/create/loops/loop-stack-session log --oneline main..build-wave` against the source plan's task commits, and `git -C ~/repos/ringer status` for an owed MODEL-NOTES receipt.
> Relaunch (never resume) every task without a commit, continuing the wave loop from the first incomplete wave, journaling gates in `docs/reviews/2026-08-03-build-wave-batch-review.md` under knob `auto`.

## Task specs and checks

Specs are generated from the source plan at manifest-write time, one per task, self-contained: role and worktree boundary, exclusive ownership list, the task's Step 3 implementation instructions verbatim in spirit, the how-to-run (`bash tests/gates/<name>.sh`), the markdown style rules (one sentence per line, plain dashes, aligned pipes), the gate-tag no-touch rule (with task 3's two sanctioned exceptions), task 5's "Reading the user" no-touch rule, and the output contract (leave changes uncommitted, no git commit/branch/push).
Checks are inline bash: assert the task's committed test file is untouched (`git diff --quiet HEAD -- <test>`), run the acceptance test (its own output is the failure reason), audit `git add -A && git diff --cached --name-only` against the ownership list, and export the non-empty patch to the workdir.
Task 7's check additionally runs `bash tests/repo-state/mirrors.sh`; task 10's check runs the plan's full-suite command plus `tests/gates/check.sh` and the duplicate-row grep.
The manifests themselves are kept in the workdir (`wave1.json`, `wave2.json`, `wave3.json`) as the run's record.

## Kicking it off

Jeremy already said go ("loop-drive the plan, only pause if required"), so the run starts immediately after this file is written; per-wave summaries land in the run-state file and the final report in chat.
Watch points if wanted: `tail -f ~/.ringer/work/build-wave-2026-08-03/logs/` during a wave, run JSON in `~/.ringer/runs/`, Ringside at the dashboard port, and the journal for every auto-taken gate.
If the session dies, use the resume prompt above.
