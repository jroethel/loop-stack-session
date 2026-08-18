# Control Plane - agent-orchestrated execution plan

## 1. What this file is

This is the orchestration plan derived from `2026-08-15-control-plane-plan.md`, compiled at the drive-compile dispatch role pin.
One frontier-model orchestrator session drives it; workers never see this conversation.
The source plan `2026-08-15-control-plane-plan.md` remains the manual fallback and stays ground truth for acceptance criteria, interfaces, and scope.
Any spec edit made during the run is applied to the source plan (and to the affected manifest spec), not only here.

The source plan's Step-1 blocks embed each task's acceptance test verbatim.
Under parallel workers those test files are check-custody artifacts: the orchestrator places each one, the worker never owns `tests/`, and the manifest check diffs the placed test against an orchestrator-held golden copy before running it.
This is the one deliberate deviation from the source plan's "worker writes the failing test" step wording, noted once here and again in section 4.

## 2. Routing table

Every implementer unit routes to the flat-rate `claude-zai` lane on `glm-5.2`.
That is not the quota-lean tie-break firing on thin evidence: it is the evidence-backed posterior pick (see footnotes), and it also preserves Anthropic quota for orchestration and gates.
Task 7 is not a dispatched unit - it is the orchestrator's final integration gate plus three human checkpoints (see [^7]).

| Unit | W | type | Model | Transport | Engine | Impl | Val | Evidence |
|---|---|---|---|---|---|---|---|---|
| T1 labels+comment | 1 | code-feature | glm-5.2 | ringer | claude-zai | med  | check      | posterior[^1] |
| T2 claim/done-guard | 2 | code-feature | glm-5.2 | ringer | claude-zai | high | check+read | posterior[^2] |
| T3 next-eligible  | 3 | code-feature | glm-5.2 | ringer | claude-zai | high | check+read | posterior[^3] |
| T4 queue-runner   | 4 | docs         | glm-5.2 | ringer | claude-zai | med  | check      | posterior[^4] |
| T5 run-state+kill | 4 | docs         | glm-5.2 | ringer | claude-zai | med  | check      | posterior[^5] |
| T6 lifecycle-lint | 4 | code-feature | glm-5.2 | ringer | claude-zai | high | check+read | posterior[^6] |
| T7 integration    | 5 | -            | orchestrator | orchestrator | - | - | suite+demos | pin:gate[^7] |

`Val` legend: `check` = the executed, orchestrator-placed acceptance test is the non-negotiable gate; `check+read` = the same, plus a full orchestrator diff-read at the wave gate because the unit carries a security/correctness contract.

[^1]: T1 - glm-5.2/claude-zai is `proven` on code-feature (53 rows, 83% first-try) and MODEL-NOTES records 10/10 attempt-1 on loop-stack itself with the committed-RED-test GREEN-only + exact-ownership pattern, which is this unit's exact shape; mechanical subcommand arms reusing the `local_set_state` awk pattern -> impl medium.
[^2]: T2 - same posterior; impl high because the exit-code contract (4 race / 5 evidence-free / 7 failing-`--ran`), the receipt-before-flip ordering, and owner-by-timestamp are the P2 evidence guard - numeric-correctness and security-critical, so the gate also gets a full diff-read.
[^3]: T3 - same posterior; impl high for the no-jq JSON brace-scan (cf. gen-mirrors.sh) plus the stale-claim wall-clock math; gate gets a full diff-read.
[^4]: T4 - glm-5.2/claude-zai is `proven` on docs (11 rows, 91% first-try) with loop-stack receipts showing house-style held under a grep gate; thin, outcome-shaped prose with a canonical example -> impl medium.
[^5]: T5 - docs posterior; the SKILL.md + native-orchestration.md prose edits are the work, and the placed kill-test's tracker mechanics already pass from W1-W3 so the new greps isolate this task's doc text -> impl medium.
[^6]: T6 - code-feature posterior; impl high for the four-class superseded/orphan/open-issue/closed-issue detector with backend-optional gating and stem-matching; gate gets a full diff-read.
[^7]: T7 - orchestrator lane, no worker. Its "check" (`./install.sh && tests/run.sh`, registry drift, gen-mirrors lane check, lint on the integrated tree) is not more cheaply checked than produced (P6 fails), and `install.sh` writes absolute-path symlinks outside any worktree so a ringer worktree would symlink into a directory that is then deleted. Steps 4 (kill-demo verdict), 5 (real archive demo), 6 (staged issue-closes) are human/STOP checkpoints that survive from the source plan.

## 3. Orchestration shape and the three validation layers

One orchestrator session drives five waves.
W1-W3 are single-unit sequential waves (all three mutate `scripts/tracker.sh`, exclusive ownership forbids packing them).
W4 is a 3-wide parallel wave over disjoint files.
W5 is the orchestrator's integration gate plus the human checkpoints.

Three validation layers per implementer unit:

1. Implementer self-check - the worker runs its own acceptance test to green before returning.
2. Per-unit validator - the ringer `check`: it diffs the placed test against the golden copy (tamper guard), asserts the worker touched no `tests/` path (custody), then executes the test (exit 0 is the only PASS).
3. Orchestrator gate - reads the ringer run JSON and raw logs, applies the reviewed patch, reruns the full suite on the integration branch; for `check+read` units it reads the whole diff, not a skim.

No separate validator model is spawned: the verbatim tests already exercise the side doors and exit-code contracts exhaustively, so a second review model would be ceremony.
If a `check+read` gate diff-read raises doubt the check cannot express, the escalation is a one-task ringer review manifest, not an automatic layer.

```
Orchestrator (driving session - gates, merges, never implements)
  W1: [T1] -> W2: [T2] -> W3: [T3]        (sequential: all mutate scripts/tracker.sh)
                              |
  W4: [T4] [T5] [T6]                      (parallel, disjoint files)
        each unit: ringer glm-5.2 worker -> placed-test check -> orchestrator gate
                              |
  W5: [T7 integration]  + STOP checkpoints (kill-demo verdict, staged issue-closes, merge gate)
```

## 4. Hazard mitigations

All units share one transport (ringer, worktrees mode), so the ringer footgun set is active and the Agent-tool set is not - except the dirty-tree preflight, which applies to any transport.

- **Check custody (deviation from source plan).** The source plan's Step-1 says the worker "writes the failing test verbatim". Here the orchestrator writes each test verbatim from the source plan and commits it to the integration branch BEFORE launching the unit; the worker's ownership list EXCLUDES `tests/`; the manifest check (a) diffs the worktree's copy of the test against `<workdir>/golden/<unit>.sh` and FAILs on any difference, (b) asserts no `tests/` path appears in the worker's changes, then (c) runs the test. A worker diff touching `tests/` is an automatic scope violation, resolved by discarding the run, never patched at the gate.
- **Deliverables survive a passing worktree.** A passing ringer worktree is deleted with the worker's commits. The check exports the worker's edits with `git add -A && git diff --cached > <workdir>/patches/<unit>.patch`; the orchestrator applies and commits that patch on the integration branch after review. No unit produces a gitignored path, so the `cp`-the-ignored-output mitigation is not needed here (verified: deliverables are tracked source and markdown).
- **Sequential-wave state threading.** T2 needs T1's `tracker.sh` and T3 needs both. Because W1-W3 are separate waves, the orchestrator applies and commits each wave's reviewed patch to the integration branch, then commits the next wave's placed test, then snapshots that state into the next wave's worktree - each worker sees all prior tasks' work.
- **W4 disjointness.** T4 owns `skills/loop-drive/references/queue-runner.md`; T5 owns `skills/loop-drive/SKILL.md` + `skills/loop-drive/references/native-orchestration.md`; T6 owns `scripts/lifecycle-lint.sh` + `config/repo-state.md` + `skills/handoff/SKILL.md`. Disjoint by construction; a merge conflict at the W4 gate is a scope violation, not something to quietly resolve.
- **Parallelism / opencode stagger - N/A.** No unit runs on the `opencode` engine, so the sqlite-lock stagger does not apply; MODEL-NOTES shows glm-5.2/claude-zai runs at `max_parallel: 3` are clean, so W4 runs `max_parallel: 3` with no stagger.
- **Dirty-tree preflight (STOP).** Worktrees branch from committed state only. `docs/reviews/2026-08-15-control-plane-batch-review.md` is an expected uncommitted file and is NOT a blocker; any other uncommitted change stops and asks the human before wave 1.
- **bash 3.2 / macOS.** Every acceptance test and every produced script must run under the macOS default bash 3.2. The embedded tests are already written 3.2-safe (`set -uo pipefail`, `mktemp -d`, no associative arrays); the check runs them on the same shell.
- **Log separation.** Ringer writes per-task logs to `<workdir>/logs/`; the orchestrator keeps one run-state file and one per-wave summary under `logs/loop/`.

## 5. Pre-flight checklist

- [ ] Capability probe: ringer present at `/Users/jjrdar/repos/ringer`; engines `codex`, `claude` (haiku), `claude-zai` (glm-5.2, flat lane, `/Users/jjrdar/.config/ringer/claude-zai.sh`), `opencode`. Not degraded mode.
- [ ] Evidence caveat: `docs/AMENDMENTS-PENDING.md` does not exist in the ringer repo, so posteriors rest on `./ringer.py models` plus `docs/MODEL-NOTES.md` only - both read this compile.
- [ ] Repo clean except `docs/reviews/2026-08-15-control-plane-batch-review.md`; any other dirty path is a STOP.
- [ ] Integration branch `integration/control-plane-loop` created off the current `molt-cycle-1` HEAD; record that HEAD sha as `<pre-run-base>` for the final loop-review.
- [ ] Log dir `logs/loop/` created; run-state artifact `logs/loop/run-state.json` initialized.
- [ ] Ringer run: `run_name: control-plane-loop` (SAME across all waves), `workdir: /tmp/control-plane-loop`, `repo: /Users/jjrdar/create/loops/loop-stack-molt`, `worktrees: true`. Golden-test dir `/tmp/control-plane-loop/golden/`, patch dir `/tmp/control-plane-loop/patches/` created.
- [ ] Ringside on screen: `./ringer.py hud` from the ringer repo root before the first run.

## 6. Wave-loop procedure and gates

Run from the ringer repo root `/Users/jjrdar/repos/ringer`; every manifest carries `run_name: control-plane-loop`.

**Per wave:**

1. **Place the checks.** For each unit in the wave, write its acceptance test verbatim from the source plan to its `tests/...` path, copy it to `/tmp/control-plane-loop/golden/<unit>.sh`, and commit the test(s) to the integration branch (RED - they fail now). Verify RED by running one before launch.
2. **Launch.** Emit one manifest for the wave and run `./ringer.py lint <wave>.json && ./ringer.py run <wave>.json`. Ringer's single built-in retry IS the repair pass; do not add another.
3. **Gate (orchestrator).** Read the run JSON in `~/.ringer/runs/` (truth - a background shell exit status is not); read every retried/failed log in `/tmp/control-plane-loop/logs/`; spot-check one passing artifact. On a FAIL, attribute before relaunching: re-run the check's steps against the tree yourself - if the worker was right and the CHECK was wrong, fix the check, commit the audited work, and add a MODEL-NOTES line instead of burning a round. Apply each reviewed patch to the integration branch (staging only owned paths), audit the diff touches no `tests/` path and only owned files, and rerun `tests/run.sh` on the integration branch. For `check+read` units (T2, T3, T6) read the whole diff.
4. **Distill + receipt.** Turn any repeated failure into a fix in the spec artifact and this plan's templates before the next wave (P10). Add one dated MODEL-NOTES line per (glm-5.2, task_type) for the wave, plus a separate line for any signal event (a check bug, a spec-problem verdict, an off-nominal result). Commit the MODEL-NOTES receipt in the ringer repo before advancing - the run drives two repos and both are checkpointed.
5. **Advance only on a green integration branch**, then write the wave summary to `logs/loop/wave-N-summary.md`.

**Wave map:** W1=T1, W2=T2, W3=T3 (each: one unit, `max_parallel: 1`); W4=T4+T5+T6 (`max_parallel: 3`); W5=T7 orchestrator gate + checkpoints.

**W5 (T7) - orchestrator runs, no worker:**

- Step 1: `./install.sh && tests/run.sh` on the integration branch -> `0 failed`.
- Step 2: `scripts/gen-gate-registry.sh .` then `git diff --exit-code docs/gate-registry.md`; commit the regenerated registry only if it changed (never hand-edit it).
- Step 3: gen-mirrors lane check on a scratch local-mode repo - an `agent:working` non-idea issue lands in `ISSUES.md` not `BACKLOG.md`; note that status transitions refresh `updated:` and churn the mirrors (expected).
- Step 4 `[gate:STOP]`: kill/resume demo - seed a claimed-then-dead ticket per the `tracker-killtest.sh` fixture, hand a fresh session ONLY `skills/loop-drive/references/queue-runner.md`, and record the human verdict that it selected the stale-working ticket, reclaimed it, and relaunched from tracker + git.
- Step 5: archive demo (real, in-worktree, git-revertible) - run `scripts/lifecycle-lint.sh .`, confirm it flags the superseded+unlinked plan-sets (the six 2026-08-04 -> 2026-08-10 sets at minimum; a superset is fine), archive each flagged set with its `_loop` twin and travelling brief, announcing each moved file.
- Step 6 `[gate:STOP]`: for lint classes (c)/(d) that would CLOSE a real GitHub issue, do not fire - print the exact `scripts/tracker.sh done <num> --receipt "..."` (or human `close`) per issue and hand it to the owner, who fires them.
- Step 7: `git add -A && git commit -m "control-plane: integration green, plan-sets archived, issue-closes staged for owner"`.

**Slip rules and gate classes** (semantics live in loop-auto):

- A spec edit confined to one unit or criterion, leaving the produced contract unchanged, and touching 15 or fewer lines, auto-takes as `[gate:BATCH]` and is journaled to `docs/reviews/2026-08-15-control-plane-batch-review.md`.
- A larger edit, or one touching multiple units, a global constraint, or a unit's produced contract, is a `[gate:STOP]`.
- A check FAIL whose verdict is `spec-problem` routes to the orchestrator (fix the spec artifact and relaunch that unit); a design issue is recorded for the downstream loop-review, never silently patched.

**Ask-the-human list (STOP):**

- Any dirty path at preflight other than the expected batch-review journal.
- Any request to exceed the effort cap (`high`); none is expected.
- Any spec edit past the BATCH threshold above.
- T7 Step 4 kill-demo verdict; T7 Step 6 staged issue-closes (outward-facing); the cycle-end merge gate.
- **Merge gate:** nothing in this branch goes live until the owner fires the cycle-end merge from the `main` checkout - not an orchestrator action.

**Final-wave advisory review:** after W5 is green and the run advances, run `/loop-review <pre-run-base>` from the integration branch (the recorded `molt-cycle-1` start sha).
It is advisory and non-blocking - the per-unit checks already gated correctness.
Record its findings at the final human checkpoint; slip any Spec-axis finding to the downstream review under the same slip rule as a stopped unit's design issue.

## 7. Quota and resume

The orchestrator is the loop; if the session dies, the loop stops.
Design for interruption at any gate.

Durable state:

- Each ringer run commits nothing to the repo itself - the orchestrator applies patches - so git on the integration branch is the truth of what has landed.
- The orchestrator updates `logs/loop/run-state.json` at every launch and gate (which wave, which units placed/run/gated/merged, the integration-branch sha, any owed MODEL-NOTES receipt).
- Half-done units are relaunched, never resumed: ringer workers are stateless and their worktrees die on pass.

Reconciliation procedure (trust git over the state file):

1. Read `logs/loop/run-state.json`, then verify it against the integration branch: `git -C /Users/jjrdar/create/loops/loop-stack-molt log --oneline integration/control-plane-loop`.
2. A unit is done only if its reviewed patch is committed AND `tests/run.sh` was green after it; anything less is relaunched from its placed test.
3. Check the ringer repo for an uncommitted MODEL-NOTES receipt owed by the last gate: `git -C /Users/jjrdar/repos/ringer status --porcelain docs/MODEL-NOTES.md` - commit it if present.
4. Resume the wave loop from the first wave not confirmed green.

Verbatim resume prompt:

> Resume the control-plane loop from `docs/plans/2026-08-15-control-plane-plan_loop.md`.
> Read `logs/loop/run-state.json`, then the real git state of `integration/control-plane-loop` and the ringer repo's MODEL-NOTES.
> Trust git over the state file.
> A unit counts as done only if its patch is committed and `tests/run.sh` was green after it; relaunch any unit not confirmed done from its verbatim placed test.
> Commit any owed MODEL-NOTES receipt, then continue the wave loop (section 6) from the first wave not confirmed green.

## 8. Templates

Every unit's spec is self-contained (the worker sees no conversation and no source plan).
At launch the orchestrator pastes that task's full **Interfaces** block from the source plan into the `spec` string; the sections below give the fixed scaffolding around it.
The verbatim test code never goes in the spec - the spec only states the test's path, that it is read-only and orchestrator-placed, and that the worker's code must make it pass.

### Spec scaffolding (every implementer unit)

```
You are the implementer for unit <UNIT>. Your current working directory IS a git worktree of the
loop-stack repo - edit files here directly, every repo path is relative to your cwd, never touch an
absolute path into another checkout.

You OWN exactly these files (create or edit): <OWNERSHIP LIST - tests/ is NOT here>.
You may NOT create or edit anything under tests/. The acceptance test at <TEST PATH> is placed by the
orchestrator, is READ-ONLY to you, and already exists; your job is to make your owned files pass it.

<the task's full Interfaces contract, pasted verbatim from the source plan>

HOW TO RUN (this is the exact acceptance command; the check runs the same one):
  bash <TEST PATH>
It must exit 0.

If anything is ambiguous: take the most conservative reading, do the work, and note the question in
your worker notes - do not cross your ownership boundary to resolve it. Effort cap: high.

OUTPUT: leave your edits uncommitted in the worktree (the check exports them). Deliverable files:
<the exact owned files>.
```

### Ringer manifest task - T1 (worked example; T2, T3, T6 follow the same shape with their own Interfaces block and ownership; T4, T5 set `task_type: docs`)

```json
{
  "run_name": "control-plane-loop",
  "workdir": "/tmp/control-plane-loop",
  "repo": "/Users/jjrdar/create/loops/loop-stack-molt",
  "worktrees": true,
  "max_parallel": 1,
  "tasks": [
    {
      "key": "T1-labels",
      "task_type": "code-feature",
      "engine": "claude-zai",
      "model": "glm-5.2",
      "spec": "<spec scaffolding above, with UNIT=T1, OWNERSHIP=scripts/tracker.sh, TEST PATH=tests/repo-state/tracker-labels.sh, and Task 1's full Interfaces block pasted in>",
      "expect_files": ["scripts/tracker.sh"],
      "check": "set -e; GOLD=/tmp/control-plane-loop/golden/T1-labels.sh; TEST=tests/repo-state/tracker-labels.sh; diff \"$GOLD\" \"$TEST\" || { echo 'FAIL: acceptance test was modified (custody violation)'; exit 1; }; if git status --porcelain -- tests/ | grep -q .; then echo 'FAIL: worker touched tests/ (scope violation)'; git status --porcelain -- tests/; exit 1; fi; bash \"$TEST\" || { echo 'FAIL: tracker-labels.sh did not pass'; exit 1; }; git add -A && git diff --cached > /tmp/control-plane-loop/patches/T1-labels.patch; echo OK",
      "verified": "The orchestrator-placed tracker-labels.sh is unmodified, the worker touched no tests/ file, the test passes on the worker's tracker.sh, and the diff is exported for the orchestrator to apply."
    }
  ]
}
```

The check prints WHY it fails at each stage (custody diff, scope grep, test run), verifies substance by executing the real acceptance test (never `true`/`exit 0`), and is strict on substance while the embedded test itself is tolerant on format.
`max_attempts` stays at the default 2 (one try + ringer's retry).

### W4 manifest

One manifest, three tasks (`T4-queue-runner` docs, `T5-run-state` docs, `T6-lint` code-feature), `max_parallel: 3`, each with its own custody check against its golden copy and its own ownership list.
The docs units set `task_type: docs`; T6 sets `code-feature`.

### Orchestrator gate review (the validator stance, both the check and the human-in-the-loop read)

At each gate the orchestrator is adversarial and evidence-first: judge the raw diff and the executed check output, ignore any worker narrative.
Verdict discipline: if the custody diff differs, or any `tests/` path was touched, or the acceptance test does not exit 0, the unit fails - regardless of what the worker reported.
A `spec-problem` (the check is unsatisfiable under the spec's boundary) routes to the orchestrator to fix the spec artifact and relaunch, not to a repair loop.

## 9. Kicking it off

Human says: "Run the control-plane loop, wave 1."
The orchestrator runs the pre-flight (section 5), places and commits T1's test RED, then launches `./ringer.py lint w1.json && ./ringer.py run w1.json`.
Per-wave summaries land in `logs/loop/wave-N-summary.md`; the routing table and topology are section 2 and section 3.
Watch live: `tail -f /tmp/control-plane-loop/logs/*` during a wave, the run JSON in `~/.ringer/runs/` and `logs/loop/run-state.json` at each gate, and Ringside at http://127.0.0.1:8700.
Watch points: the custody check on every unit, the sequential state-threading between W1-W3, the W4 disjointness audit, and the three W5 STOP checkpoints (kill-demo verdict, staged issue-closes, merge gate) that the owner fires.
If interrupted, use the resume prompt in section 7.
