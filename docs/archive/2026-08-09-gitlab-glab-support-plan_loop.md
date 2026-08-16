# GitLab (glab) Backend Support - Orchestration Plan

## 1. What this file is

This is the agent-orchestrated execution plan derived from `docs/plans/2026-08-09-gitlab-glab-support-plan.md`.
It converts a plan written for a human operator into one a single frontier-model orchestrator session executes with ringer-transported workers.

The source plan remains the manual fallback and stays ground truth.
Its task text, acceptance criteria, embedded test files, and scope boundaries are what the workers receive; this file adds transport, routing, isolation, checks, and gates, and nothing else.
Any spec edit made during the run is applied to the source plan, not only here, so the two never diverge.

Task 7 is not dispatched to any worker.
It writes to a live shared GitLab instance, and the source plan already declares every write in it human-fired; it stays in the orchestrator's judgment lane as the final human checkpoint.

## 2. Routing table

| Unit               | Wave | task_type    | Model   | Transport         | Engine     | Impl. effort | Val. effort                 | Evidence        |
| ---                | ---  | ---          | ---     | ---               | ---        | ---          | ---                         | ---             |
| task-1-tracker     | 1    | code-feature | glm-5.2 | ringer            | claude-zai | high         | check-only                  | posterior[^1]   |
| task-2-mirrors     | 1    | code-feature | glm-5.2 | ringer            | claude-zai | medium       | check-only                  | posterior[^2]   |
| task-3-setup       | 2    | code-feature | glm-5.2 | ringer            | claude-zai | high         | check-only                  | posterior[^3]   |
| task-4-sweep       | 3    | code-feature | opus    | ringer            | claude     | high         | check + opus review, high   | pin:risk[^4]    |
| task-5-migrate     | 4    | code-feature | glm-5.2 | ringer            | claude-zai | medium       | check-only                  | posterior[^5]   |
| task-6-docs        | 5    | docs         | glm-5.2 | ringer            | claude-zai | high         | check + opus review, medium | posterior[^6]   |
| task-7-forge-smoke | 6    | n/a          | none    | human, in-session | n/a        | n/a          | user-recorded results table | pin:outward[^7] |

[^1]: task-1-tracker: `./ringer.py models --task-type code-feature` gives glm-5.2 (claude-zai) 16 tasks at 62% first-try, 75% pass, probation tier. The raw first-try number is amendment-depressed: `docs/MODEL-NOTES.md` and `docs/AMENDMENTS-PENDING.md` annotate seven stm-nav rows, one loop-setup-reconcile row, one calcdate-stability pair and two ltv rows as orchestrator check bugs whose work was audited correct, and none of those have been amended into the aggregate yet. The judgment layer is unambiguous for this exact shape of work: the 2026-08-08 loop-improve receipt in this same repo records glm-5.2 first-try on skill-prose surgery with byte-exact contract compliance, and the 2026-07-19 through 2026-08-08 receipts repeatedly name "tightly-specced plus executed check" as its confirmed lane. Task 1 embeds a verbatim 215-line test file and near-verbatim implementation snippets, which is that lane exactly. Quota preference then confirms the flat-rate claude-zai engine.
[^2]: task-2-mirrors: same posterior and the same judgment layer as task-1-tracker; this unit is one `case` block, one header comment, and a verbatim test file, so effort drops to medium.
[^3]: task-3-setup: same posterior. The unit is large but literal, with each of its eleven sub-steps carrying the code to write; the 2026-08-08 loop-improve receipt covers exactly this transcription-heavy shape. It stays high effort because the sub-steps interact (g2's switch path calls g3's guarded `mode set`, and `render_gitlab` must agree with the template bump).
[^4]: task-4-sweep: pinned to opus on risk concentration, not difficulty. This unit is where the source plan's own second review round found its one blocking defect, and the revised task then needed a separate cold re-read that produced ten more repairs. It also carries the run's only genuinely destructive operation (a file move) and its only instruction to modify an existing green suite by judgment (`tests/loop-setup/import.sh`, "if any assertion expects ... retarget it"), which is judgment rather than transcription. The ringer posterior for opus on code-feature is 2 tasks at 100% first-try (probation), and the 2026-08-08 MODEL-NOTES receipt records a risk-concentration pin on the highest-risk unit of another run paying off first-try. Engine `claude` with `model` set explicitly to `opus`, because that engine's `model_default` is haiku.
[^5]: task-5-migrate: same posterior as task-1-tracker; the unit is six lettered steps each carrying its own code, which is the mechanical end of the confirmed lane, so effort is medium.
[^6]: task-6-docs: `./ringer.py models --task-type docs` gives glm-5.2 (claude-zai) 16 tasks at 81% first-try, 88% pass, proven tier - the strongest posterior in the run. Effort stays high because the unit carries many exact-sentence requirements across five files, and the 2026-07-20 receipt records glm-5.2 paraphrasing "exact sentence" requirements unless the sentence is set off as a quoted block; the spec therefore quotes them, and the check greps for them.
[^7]: task-7-forge-smoke: not routed to any model. It is outward-facing (a shared corporate GitLab instance, group `university-advancement`), and the source plan declares every write in it staged for the user to fire. It is the final human checkpoint, run by the orchestrator with the user firing each command.

Validator tasks: `task-4-review` and `task-6-review` are adversarial read-only ringer tasks pinned to opus on the `claude` engine, task_type `code-review`.
The pin has evidence behind it and is not a tier preference: `./ringer.py models --task-type code-review` gives glm-5.2 5 tasks at 0% first-try and 40% pass, the weakest row on the board, while the 2026-08-08 MODEL-NOTES receipt records opus code-review validators 6/6 with every verdict earned by independent rerun, including one that caught a precision error the implementer missed.

Effort disclosure: the `claude` and `claude-zai` engines expose no reasoning-effort argument.
Codex is the only wired engine with an effort knob (`engine_args` `["-c", "model_reasoning_effort=..."]`), and no unit is routed to it.
The Impl. effort column is therefore the orchestrator's declared depth, carried by spec depth and `timeout_s`, not by a CLI flag.
Nothing in this run is proposed above the `high` cap; any request to exceed it stops and asks the human `[gate:STOP]`.

Taste flag: no unit has aesthetic acceptance criteria, so no per-unit engine ask is offered.

## 3. Orchestration shape and validation layers

One orchestrator session drives six waves.
Waves 1 through 5 are ringer manifests over the same `run_name`; wave 6 is the human checkpoint.

```
orchestrator (this session, integration/gitlab-glab-loop checked out)
├── wave 1  manifest w1  max_parallel 2
│   ├── task-1-tracker   ringer / claude-zai / glm-5.2  ──> executed check
│   └── task-2-mirrors   ringer / claude-zai / glm-5.2  ──> executed check
│       gate: apply 2 patches, 2 commits, full suite on integration, distill, MODEL-NOTES
├── wave 2  task-3-setup    ringer / claude-zai / glm-5.2 ──> executed check
├── wave 3  task-4-sweep    ringer / claude / opus        ──> executed check + opus review task
├── wave 4  task-5-migrate  ringer / claude-zai / glm-5.2 ──> executed check
├── wave 5  task-6-docs     ringer / claude-zai / glm-5.2 ──> executed check + opus review task
│       gate: advisory /loop-review <pre-run-base> on the whole-run diff
└── wave 6  task-7-forge-smoke   HUMAN CHECKPOINT, every write user-fired
```

The wave graph is the source plan's own Dependency graph section, unchanged.
Tasks 3, 4 and 5 all modify `skills/loop-setup/setup.sh`, which the source plan names as a deliberate serialization; that is why waves 2 through 4 are single-unit waves rather than a mis-compiled fan-out.
Wave 1 is the only parallel-eligible wave, because tasks 1 and 2 touch disjoint files.

Three validation layers:

1. **Implementer self-check.** Each worker runs its own new suite and the full suite inside its worktree before returning, and records the commands and counts in `report.md`.
2. **Per-unit validator.** The primary, non-negotiable gate is the task's executed `check` (section 8), which reruns both suites independently of anything the worker claims, greps the implementation for substance, exports the patch, and audits the ownership boundary. Units 4 and 6 additionally get a read-only adversarial opus review task at their gate, because their executed checks cannot express what they need judged: for unit 4, whether an existing green suite was weakened rather than retargeted; for unit 6, whether prose the check only greps for keywords actually carries its substance.
3. **Orchestrator gate.** Run JSON, every retried or failed worker log, one spot-checked passing artifact, the patch diff, the full suite rerun on the integration branch in the main checkout.

Worker self-reports are never evidence.
Every verdict at every layer is judged against the raw diff, the executed check output, and an independent rerun.

## 4. Hazard mitigations

Every unit rides ringer transport, so run-level `"worktrees": true` handles isolation, per-task directories, and log separation; none of that is re-specified.
What follows is what ringer does not handle, plus the deviations from the source plan that transport forces.

**Deliverables die with a passing worktree - patch-export pattern.**
A passing task's worktree is deleted, and worker commits die with it.
Every unit's check therefore ends by staging its owned paths and exporting `git diff --cached` to `/home/jjrdar/.loop-work/gitlab-glab-loop/exports/<key>.patch`, a path outside every worktree.
The orchestrator reviews the patch, applies it to the integration branch in the main checkout, and commits there.

**Deviation from the source plan: workers do not commit.**
Each source task ends with a Step 5 that runs `git add` and `git commit`.
Under worktree isolation that commit lands on a detached HEAD inside a directory ringer deletes on pass, so the work would be destroyed by its own success.
Resolution, carried into every spec as an explicit instruction: the worker leaves its changes uncommitted, the check exports the patch outside the worktree, and the orchestrator applies and commits on the integration branch at the gate, using each task's own Step 5 commit message verbatim.
Only who commits and when changes; the message and the file set do not.

**Gitignored outputs vanish from patch exports.**
`git add -A` cannot stage ignored paths, so a gitignored deliverable would pass its check and then die with the worktree.
Verified in this repo: `.gitignore` ignores `ISSUES.md`, `BACKLOG.md`, `docs/chain-state.md`, `.loop-patches/`, `.loop-work/`, `.scratch/`, `.DS_Store`, and `skills/frontier-sandwich/references/model-benchmarks.md`.
No unit in this run produces a gitignored deliverable, so no `cp` rescue is needed; the caveat is recorded because it binds any re-scoped unit.

**The same gitignore bites in the other direction, and this one is live.**
`tests/run.sh` runs `tests/repo-state/live.sh` whenever `gh auth status` succeeds, and `live.sh` asserts that `ISSUES.md` and `BACKLOG.md` exist.
Both are gitignored and untracked, so they are absent from every fresh worktree, and `gh` is authenticated on this host.
Reproduced: a detached worktree of HEAD fails `live.sh` with `FAIL: ISSUES.md not stood up`, which would turn the full-suite gate of tasks 1 through 6 into an unwinnable check.
Mitigation, carried into every spec and every check: run the suite as `GH_CONFIG_DIR="$(mktemp -d)" bash tests/run.sh`, which makes `gh` report no auth and takes `run.sh`'s own documented skip path for `live.sh`.
Verified: with that variable set, a fresh worktree of HEAD runs 29 suites, 29 passed, 0 failed, in 3.7 seconds.
Workers are told explicitly not to edit `live.sh` or `run.sh` and not to create the mirrors.
`live.sh` is still gated once per wave, in the only place it can pass: the orchestrator's full-suite rerun on the integration branch in the main checkout, where the mirrors exist.
This is a deviation from the source plan's "How to run" section, which assumes the suite runs from the main checkout.

**Checks have a hard 60-second cap.**
`CHECK_TIMEOUT_S` is a module constant in `ringer.py`, not a per-task field; `timeout_s` tunes the worker, not the check.
The full suite is 3.7 seconds, so every check in section 8 fits with wide headroom, but no check may grow into a build or a network call.

**Worktrees branch from the main checkout's HEAD.**
Ringer runs `git -C <repo> worktree add <taskdir> HEAD`, so each wave's workers see whatever the main checkout has committed at launch.
The orchestrator therefore checks out `integration/gitlab-glab-loop` in `/home/jjrdar/repos/loop-stack-session` at pre-flight and keeps it checked out for the entire run; a wave launched with the wrong branch checked out gives its workers the wrong base.

**Dirty working tree.**
Worktrees branch from committed state only, so uncommitted work is invisible to every worker.
At the time of compilation the tree carries exactly one untracked file, `docs/reviews/2026-08-09-gitlab-glab-loop-drive-batch-review.md`, and nothing modified.
Pre-flight re-checks and surfaces whatever is there to the human before wave 1 `[gate:STOP]`.

**Ownership and the disjoint-files assumption.**
Wave 1's two units touch disjoint files by construction, so a conflict when applying their two patches is a scope violation, not something to resolve quietly.
Every check audits `git status --porcelain` against the unit's ownership list and fails with the stray paths named.
`report.md` at the worktree root is the one allowed exception, and it is named in every ownership assertion.

**Deviation: the full suite is part of every unit's check.**
The source plan makes `bash tests/run.sh` the acceptance check of tasks 3, 4 and 5 only; tasks 1, 2 and 6 name sibling suites instead.
Every check here runs the full suite, because a wave that lands a red suite blocks four downstream waves and the cost is 3.7 seconds.
The baseline is green, so this is a stricter gate, not an unsatisfiable one; `./ringer.py run <manifest> --baseline` at pre-flight proves that before any tokens are spent.

**Do not chain `lint && run`.**
`./ringer.py lint` exits non-zero on advisory findings, so `lint && run` silently never launches a manifest that carries a by-design finding (MODEL-NOTES, 2026-08-08, loop-improve run).
Lint separately, read the findings, then run alone.
This is a deviation from the loop-drive skill's default launch string, adopted on local evidence.

**Opencode spawn stagger: not applicable, carried conditionally.**
No unit is routed to the `opencode` engine, so its shared sqlite WAL contention cannot bite this run.
If a runtime escalation re-routes any unit to `opencode`, stagger the spawns or cap `max_parallel` at 1 for that manifest.

**`report.md` survives a deleted worktree.**
Ringer snapshots `report.md` and `report.html` out of the taskdir into `<workdir>/logs/<key>.reports/` before removing a passing worktree, so every worker's structured output is durable.
Each spec requires `report.md` at the worktree root and each task declares it in `expect_files`.

## 5. Pre-flight checklist

- [ ] **Capability probe, recorded verbatim.** Ringer is PRESENT. Ringer repo root: `/home/jjrdar/repos/ringer`. Engines found in the `[engines.*]` blocks of `~/.config/ringer/config.toml`: `codex` (bin `codex`, no `model_default`), `claude` (bin `claude`, `model_default = "haiku"`), `claude-zai` (bin `/home/jjrdar/.config/ringer/claude-zai.sh`, `model_default = "glm-5.2"`), `opencode` (bin `/home/jjrdar/repos/ringer/engines/opencode-sandboxed.sh`, `model_default = "openrouter/z-ai/glm-5.2"`). This is not degraded mode.
- [ ] **Ringer assumptions.** `~/.config/ringer/` is present and configured; the run uses `"worktrees": true`; run JSON lands in `~/.ringer/runs/`; raw worker logs land in `<workdir>/logs/`; `report.md` snapshots land in `<workdir>/logs/<key>.reports/`.
- [ ] **Model evidence is fresh.** Re-read `/home/jjrdar/repos/ringer/docs/MODEL-NOTES.md` and `docs/AMENDMENTS-PENDING.md` if more than a few days have passed since compilation; the amendment backlog moves the posteriors this table rests on.
- [ ] **Repo state.** `git -C /home/jjrdar/repos/loop-stack-session status --short` is clean, or every dirty path is surfaced to the human before wave 1 `[gate:STOP]`. Known at compile time: one untracked file, `docs/reviews/2026-08-09-gitlab-glab-loop-drive-batch-review.md`.
- [ ] **Record the pre-run base.** `git rev-parse HEAD` on `main`; at compile time this is `a8c6680`. Write it into the run-state file; the final-wave `/loop-review` needs it.
- [ ] **Integration branch.** `git checkout -b integration/gitlab-glab-loop` off that base, and leave it checked out for the whole run.
- [ ] **Environment.** `bash --version` (specs require Bash 3.2 compatible output, not a modern-bash-only build), `git --version`, `glab --version` if present (only Task 7 needs it live; every offline suite stubs it), `gh auth status` (expected: authenticated as `jroethel`, which is why `GH_CONFIG_DIR` is used inside worktrees).
- [ ] **Baseline the suite once, in the main checkout.** `GH_CONFIG_DIR="$(mktemp -d)" bash tests/run.sh` - expected `29 suites: 29 passed, 0 failed`. A red baseline is a stop before anything launches.
- [ ] **Workdir and exports.** `mkdir -p /home/jjrdar/.loop-work/gitlab-glab-loop/exports`. `run_name` is `gitlab-glab-loop`, the same across every wave.
- [ ] **Run-state artifact.** Create `docs/handoffs/2026-08-09-gitlab-glab-loop-run-state.md` on the integration branch, with the wave table, the pre-run base, and an empty per-wave log.
- [ ] **Prove the checks before spending tokens.** For each wave manifest: `./ringer.py lint <manifest>` (read the findings, do not chain), then `./ringer.py run <manifest> --baseline`. Every baseline failure must be an assertion about NEW behavior; an assertion about UNCHANGED behavior that fails baseline is a check bug and is fixed before spawning.
- [ ] **Ringside is up.** `./ringer.py hud` from the ringer repo root, once, before the first run.

## 6. Wave-loop procedure and gates

### Per wave

**1. Launch.**
Assemble the wave's manifest (section 8), `./ringer.py lint <manifest>`, read the findings, then `./ringer.py run <manifest> --identity loop-drive-gitlab-glab`.
`run_name` is `gitlab-glab-loop` on every wave.
Ringer's built-in single retry is the repair pass; no second repair pass is added.
Update the run-state file at launch with the wave, the manifest path, and the units.

**2. Gate.**
- Read the run JSON in `~/.ringer/runs/`. The run JSON is truth; a detached or backgrounded shell's exit status is transport and can report failure for a run that passed.
- Read the raw worker log in `<workdir>/logs/` for every retried or failed task, before deciding anything. A task that passed on attempt 2 usually flags a spec ambiguity worth fixing before the next wave.
- Spot-check at least one passing task's artifact: read its `report.md` snapshot and the exported patch.
- **On a FAIL, attribute before relaunching.** Re-run the check's steps yourself against the worker's tree or the applied patch. If the worker's output was correct and the CHECK was wrong, fix the check, commit the audited work, and annotate `MODEL-NOTES.md` with the check-bug attribution instead of burning a round. This repo's own history is the reason: eleven recorded FAIL rows across four runs were orchestrator check bugs, and the model log still carries their depressed aggregates.
- Apply each unit's patch: `git apply --index --check <exports>/<key>.patch` first, then `git apply --index`, then commit with that source task's own Step 5 commit message verbatim.
- Rerun the full suite on the integration branch in the main checkout, unmodified: `bash tests/run.sh`. This is the one place `live.sh` can pass, and it must.
- For units 4 and 6, launch the review task now (a one-task manifest against the freshly committed integration tip, same `run_name`), read its `report.md`, and treat a `fail` verdict as a stopped unit.
- Resolve stopped units. A small spec issue means edit the source plan's task text and relaunch that unit. A design issue is recorded in the run-state file and slipped to the final human checkpoint under the slip rules below `[gate:STOP]`.
- Write the wave summary as a new section of the run-state file, and commit it.

**3. Distill before advancing.**
Turn any repeated failure pattern from this wave into a fix in the source plan's task text and in the spec preamble before the next wave launches, so the next wave does not re-earn the same failure.
Write the MODEL-NOTES receipts in `/home/jjrdar/repos/ringer/docs/MODEL-NOTES.md`, batched: one dated line per (model, task_type) per wave, plus a separate line only for a signal event - a pin, a runtime re-route, a check-bug attribution, or an off-nominal result.
Support every line only with the executed check output and the raw logs, never with a worker's narrative, and read them back later through the same integrity discipline as any posterior.
Committing that receipt in the ringer repo is part of closing the gate; commit it before advancing, so the git-is-truth reconciliation covers both repos.

**4. Advance only on a green integration branch.**

### Gate classes

- A spec edit confined to a single unit or criterion, leaving unchanged what that unit is asked to produce, and touching 15 or fewer lines, auto-takes `[gate:BATCH]` and is journaled.
- A larger edit, or one touching multiple units, a global constraint, or a unit's produced contract, stays a `[gate:STOP]`. The boundary is blast radius, not raw size; 15 lines is the agreed threshold.
- A check-bug attribution and its fix auto-takes `[gate:BATCH]`.
- Any request to exceed the `high` effort cap stops and asks the human `[gate:STOP]`.
- Any outward-facing unit stops and asks the human `[gate:STOP]`.
- The final-wave advisory `/loop-review` run auto-takes `[gate:BATCH]`.

### Slip rules

A unit that fails at its attempt limit is a stopped unit, not a retry loop.
If the cause is a small spec issue, edit the source plan's task text and relaunch the unit; if the cause is a design issue, it is recorded verbatim in the run-state file and raised at the final human checkpoint, never silently patched.
A Spec-axis finding from the final-wave `/loop-review` is slipped the same way, into the same place.
Runtime escalation is not an automatic ladder: a unit that fails validation twice is re-routed at the gate by the same evidence chain, usually a pin to opus with the reason recorded in the run-state file and in MODEL-NOTES.

### Ask the human

1. Pre-flight dirty tree: any uncommitted or untracked path, surfaced before wave 1 `[gate:STOP]`.
2. Any request to exceed the `high` effort cap `[gate:STOP]`.
3. Wave 6 in its entirety: Task 7 is outward-facing, writing to `gitlab.code.rit.edu`, group `university-advancement`. Every issue-creating, issue-updating, issue-closing and issue-deleting command is staged for the user to fire; the orchestrator never runs one `[gate:STOP]`.
4. Source plan human checkpoint 1: before Task 7 and throughout it, the blast radius is stated and the user fires each command `[gate:STOP]`.
5. Source plan human checkpoint 2: criterion 13, the `[judgment]` criterion. The proposed split of forge's `whats_next.md` is shown to the user as a title list before any issue is created; a proposal spanning two unrelated items is redone `[gate:STOP]`.
6. Source plan human checkpoint 3: any candidate file the sweep offers to archive in a repo that is not a scratch sandbox. The archive move is per-file and declinable, and it is never accepted on the user's behalf `[gate:STOP]`.
7. Any spec edit whose blast radius exceeds one unit or criterion, or 15 lines `[gate:STOP]`.
8. Any stopped unit whose cause is a design issue rather than a spec issue `[gate:STOP]`.
9. Task 7 Step 2b: if BOTH cleanup routes fail (`glab api --method DELETE` and `glab issue update --title`), stop before Step 4 and do not create anything that cannot be cleaned up or clearly marked `[gate:STOP]`.
10. The findings of the final-wave `/loop-review`, reported at the final human checkpoint `[gate:STOP]`.

### Final wave: advisory terminal review

On wave 5 only, after the integration branch is green and the run advances, run `/loop-review <pre-run-base>` from the integration branch, so the two-axis Spec and Standards report judges the whole-run diff.
`<pre-run-base>` is the commit recorded at pre-flight (`a8c6680` at compile time; re-derive it, do not trust this line).
This review is advisory and non-blocking: the per-unit checks and review tasks already gated correctness, so it runs after advancement and does not hold it.
Its findings are recorded at the final human checkpoint, and a Spec-axis finding is slipped to Task 7 under the slip rules above.

## 7. Quota and resume

The orchestrator cannot see the user's remaining quota, so the loop must die safely at any moment.

**Durable-state rules.**
No important state lives only in the conversation.
Workers leave their changes uncommitted in a worktree and their receipt in `report.md`, which ringer snapshots out before deleting a passing worktree; the check leaves the patch in `<workdir>/exports/`; the orchestrator commits every applied patch and the run-state file on the integration branch at every gate, and commits the MODEL-NOTES receipt in the ringer repo at the same gate.
The run-state artifact is `docs/handoffs/2026-08-09-gitlab-glab-loop-run-state.md`, updated at every launch and every gate.
A half-done unit is designed to be relaunched, never resumed mid-flight.

**Reconciliation procedure, on resume.**
1. Read the run-state file for the intended shape, then stop trusting it.
2. Trust git: `git -C /home/jjrdar/repos/loop-stack-session log --oneline integration/gitlab-glab-loop` says which units actually landed. A unit is done only if its commit exists AND `GH_CONFIG_DIR="$(mktemp -d)" bash tests/run.sh` is green at that tip.
3. Check `~/.ringer/runs/` for a run under `run_name` `gitlab-glab-loop` that started but never gated, and read its `<workdir>/logs/`.
4. Check `<workdir>/exports/` for a patch with no matching commit; that is a unit that passed its check and died before the gate. Review and apply it rather than relaunching.
5. Check the ringer repo for an uncommitted MODEL-NOTES receipt owed by the last gate: `git -C /home/jjrdar/repos/ringer status --short docs/MODEL-NOTES.md`. The run drives two repos and both are checkpointed; an uncommitted receipt means the last gate did not close.
6. Prune any orphaned worktree: `git -C /home/jjrdar/repos/loop-stack-session worktree list`, then `worktree remove --force` anything under `/home/jjrdar/.loop-work/gitlab-glab-loop/`.
7. Relaunch, never resume, any unit not confirmed committed and green.

**Verbatim resume prompt.**

> Resume the GitLab (glab) backend loop from `docs/plans/2026-08-09-gitlab-glab-support-plan_loop.md` in `/home/jjrdar/repos/loop-stack-session`.
> Read `docs/handoffs/2026-08-09-gitlab-glab-loop-run-state.md` for the intended shape, then verify everything against git and disk rather than against that file: trust git over the state file.
> Check out `integration/gitlab-glab-loop`, run `GH_CONFIG_DIR="$(mktemp -d)" bash tests/run.sh`, and confirm which of task-1-tracker, task-2-mirrors, task-3-setup, task-4-sweep, task-5-migrate and task-6-docs are actually committed and green.
> Check `~/.ringer/runs/` for an ungated run named `gitlab-glab-loop`, `/home/jjrdar/.loop-work/gitlab-glab-loop/exports/` for a patch with no matching commit, `git -C /home/jjrdar/repos/ringer status --short docs/MODEL-NOTES.md` for a receipt the last gate owed, and `git worktree list` for orphaned worktrees to prune.
> Relaunch, never resume, any unit not confirmed committed and green, using that unit's manifest template from section 8 of the loop plan.
> Task 7 is a human checkpoint: stage its commands, never fire them.
> Continue the wave loop from the first unfinished wave.

## 8. Manifest task templates

### Run-level skeleton (same for every wave)

```json
{
  "run_name": "gitlab-glab-loop",
  "workdir": "/home/jjrdar/.loop-work/gitlab-glab-loop",
  "repo": "/home/jjrdar/repos/loop-stack-session",
  "worktrees": true,
  "max_parallel": 2,
  "tasks": [ ... ]
}
```

`max_parallel` is 2 for wave 1 and 1 for every other wave.

### Per-unit fields

| key            | wave | engine     | model   | task_type    | timeout_s | expect_files    | Ownership list (the ONLY paths the worker may create or edit) |
| ---            | ---  | ---        | ---     | ---          | ---       | ---             | --- |
| task-1-tracker | 1    | claude-zai | glm-5.2 | code-feature | 2400      | `["report.md"]` | `scripts/tracker.sh`, `tests/repo-state/tracker-gitlab.sh` |
| task-2-mirrors | 1    | claude-zai | glm-5.2 | code-feature | 1800      | `["report.md"]` | `scripts/gen-mirrors.sh`, `tests/repo-state/mirrors-gitlab.sh` |
| task-3-setup   | 2    | claude-zai | glm-5.2 | code-feature | 3600      | `["report.md"]` | `skills/loop-setup/setup.sh`, `config/repo-state.template.md`, `tests/loop-setup/acceptance.sh`, `skills/loop-setup/SKILL.md`, `tests/loop-setup/gitlab-setup.sh` |
| task-4-sweep   | 3    | claude     | opus    | code-feature | 3600      | `["report.md"]` | `skills/loop-setup/setup.sh`, `tests/loop-setup/import.sh`, `tests/loop-setup/idempotence.sh` |
| task-5-migrate | 4    | claude-zai | glm-5.2 | code-feature | 1800      | `["report.md"]` | `scripts/migrate-tracker.sh`, `skills/loop-setup/setup.sh`, `tests/repo-state/migrate-gitlab.sh` |
| task-6-docs    | 5    | claude-zai | glm-5.2 | docs         | 2400      | `["report.md"]` | `skills/loop-setup/SKILL.md`, `skills/loop-setup/references/import-triage.md`, `skills/wayfinder/SKILL.md`, `skills/loop-improve/SKILL.md`, `skills/loop-review/SKILL.md`, `config/repo-state.md`, `tests/loop-setup/docs-gitlab.sh` |

`model` must be set explicitly on `task-4-sweep`; the `claude` engine's `model_default` is haiku.

### How each `spec` is assembled

The spec that reaches the worker is self-contained: it contains the task's full text, not a path to it.
Assemble it once per unit, immediately before writing the manifest, by concatenating the preamble below with the source plan's own bytes:

```bash
P=/home/jjrdar/repos/loop-stack-session/docs/plans/2026-08-09-gitlab-glab-support-plan.md
# ranges: Global constraints 17-27, Verified facts 29-58, How to run 172-189, then the task
sed -n '17,27p;29,58p;172,189p;193,549p'   "$P"   # task-1-tracker
sed -n '17,27p;29,58p;172,189p;552,643p'   "$P"   # task-2-mirrors
sed -n '17,27p;29,58p;172,189p;646,1008p'  "$P"   # task-3-setup
sed -n '17,27p;29,58p;172,189p;1011,1364p' "$P"   # task-4-sweep
sed -n '17,27p;29,58p;172,189p;1367,1573p' "$P"   # task-5-migrate
sed -n '17,27p;29,58p;172,189p;1576,1749p' "$P"   # task-6-docs
```

The resulting text - preamble plus those bytes - is what goes in the manifest's `spec` field, JSON-escaped.
A manifest whose `spec` names a path instead is a pointer spec and is wrong: the watcher on Ringside sees no brief, and ringer's retry prompt loses the context it needs.
Re-derive the line ranges with the `sed` above before each wave, since a `[gate:BATCH]` spec edit to the source plan shifts them.

### Implementer spec preamble (verbatim, per unit)

> You are the implementer for unit `<key>` of the GitLab (glab) backend build in the `loop-stack-session` repo.
>
> YOUR CURRENT WORKING DIRECTORY IS A GIT WORKTREE of `/home/jjrdar/repos/loop-stack-session`, detached at the integration branch tip. Edit files here directly. Do not `cd` elsewhere to do your work.
>
> OWNERSHIP - you may create or edit ONLY these paths: `<ownership list>`. Everything else in the tree is read-only source material. You may also create `./report.md` at the worktree root, and nothing else.
>
> NEVER `git commit`, `git push`, `git checkout`, `git branch`, `git stash`, `git worktree`, or `git add -A`. Leave your changes uncommitted in the working tree. This is a deliberate deviation from the task text below, whose "Step 5: Commit" you must SKIP: your worktree is deleted when your check passes, so a commit made here would be destroyed by your own success. The orchestrator exports your changes as a patch and commits them on the integration branch. Do everything else in the task text exactly as written.
>
> HOW TO RUN, exactly:
> - your own new suite: `bash <the suite this task creates>`
> - the full suite: `GH_CONFIG_DIR="$(mktemp -d)" bash tests/run.sh` - expect the final line to end in `0 failed`.
> - Why `GH_CONFIG_DIR`: `tests/run.sh` runs `tests/repo-state/live.sh` whenever `gh auth status` succeeds, and `live.sh` asserts that `ISSUES.md` and `BACKLOG.md` exist. Both are gitignored, so they are absent from this worktree and `live.sh` would fail for an environmental reason that has nothing to do with your work. Pointing `GH_CONFIG_DIR` at an empty directory makes `gh` report no auth, which is `run.sh`'s own documented skip path for `live.sh`. Do NOT edit `live.sh` or `run.sh`, and do NOT create `ISSUES.md` or `BACKLOG.md`.
> - lint a script before running it: `bash -n <script>`.
>
> TEST FIRST. Write the task's test file exactly as given, run it, watch it fail for the stated reason, then implement until it passes. Do not implement first and retrofit the test.
>
> NEVER weaken, delete, skip, or loosen an existing test assertion to make a suite green. The only test edits you may make are the ones this task's text explicitly authorizes, and those are retargets, not removals. If an existing suite fails for a reason your task did not cause, stop and write what you found in `report.md` rather than editing it.
>
> IF SOMETHING IS AMBIGUOUS: do not guess wide and do not ask. Take the most conservative reading, implement that, and record both the question and the reading you took in `report.md`.
>
> HOUSE STYLE, binding on every file you touch: never the em dash character, plain `-` only. One full sentence per line in long Markdown prose. Bash 3.2 compatible - no associative arrays, no `${var,,}`, guard iteration over possibly-empty arrays. No `jq` dependency is introduced anywhere.
>
> OUTPUT CONTRACT: write `./report.md` at the worktree root before you finish. It must contain: the unit key; every file you changed and what changed in it; the exact commands you ran with their results, including the full suite's final `ran N suites: P passed, F failed` line; deviations from the task text and why; open questions with the conservative reading you took; deferred items. Your narrative is not evidence and will not be trusted - the report exists so the orchestrator knows where to look.
>
> THE TASK FOLLOWS, verbatim from the source plan. Its "Global constraints", "Verified facts this plan is built on", and "How to run" sections are binding context; the numbered Task section is your work.
>
> ---

### Checks

Each check below is written as bash for readability and is JSON-escaped into the manifest's single-line `check` string.
They run under `/bin/bash` (confirmed: `ringer.py` passes `executable="/bin/bash"` since commit `587f422`, so `set -o pipefail` is safe), with the task's worktree as the working directory, under a hard 60-second cap.
Every one prints why it fails, verifies substance rather than presence, exports the patch outside the worktree, and audits the ownership boundary.

**task-1-tracker**

```bash
set -uo pipefail
EX=/home/jjrdar/.loop-work/gitlab-glab-loop/exports; mkdir -p "$EX"
fail(){ echo "FAIL: $1"; exit 1; }
[ -f tests/repo-state/tracker-gitlab.sh ] || fail "tests/repo-state/tracker-gitlab.sh was never created; the task's own acceptance suite is missing"
for s in 'guard ran a BARE glab auth status' 'raw glab shape leaked through' 'list requested page 3 after a short page' 'github create passed --label with an empty value' 'fell through to the LOCAL backend'; do
  grep -qF "$s" tests/repo-state/tracker-gitlab.sh || fail "the new suite is missing a load-bearing assertion from the plan: $s"
done
bash tests/repo-state/tracker-gitlab.sh || fail "tests/repo-state/tracker-gitlab.sh is RED (its own output is above)"
GH_CONFIG_DIR="$(mktemp -d)" bash tests/run.sh || fail "the full suite is RED in this worktree (output above); no unit may land red"
grep -qF -- '--per-page 100' scripts/tracker.sh || fail "scripts/tracker.sh never requests 100 items per page: the page loop was not implemented"
grep -qF 'auth status --hostname' scripts/tracker.sh || fail "scripts/tracker.sh has no host-scoped glab auth guard; a bare 'glab auth status' is the regression this task exists to prevent"
grep -qF 'labels:[.labels[]|{name:.}]' scripts/tracker.sh || fail "scripts/tracker.sh does not carry the --jq translation expression; the gh-shaped output is not being produced by glab's own filter"
grep -qF 'gitlab_group' scripts/tracker.sh || fail "scripts/tracker.sh has no gitlab_group derivation, so Task 3 cannot consume it"
git add -- scripts/tracker.sh tests/repo-state/tracker-gitlab.sh || fail "git add of the owned paths failed"
git diff --cached -- scripts/tracker.sh tests/repo-state/tracker-gitlab.sh > "$EX/task-1-tracker.patch" || fail "patch export failed"
[ -s "$EX/task-1-tracker.patch" ] || fail "the exported patch is EMPTY: no owned file was actually changed"
stray="$(git status --porcelain | sed 's/^...//' | grep -vxF -e scripts/tracker.sh -e tests/repo-state/tracker-gitlab.sh -e report.md || true)"
[ -z "$stray" ] || fail "paths outside the ownership list were touched: $stray"
echo "OK: tracker-gitlab suite green, full suite green, patch at $EX/task-1-tracker.patch"
```

`verified`: "The new gitlab tracker suite and the full 29-suite offline suite both pass in a fresh worktree, `scripts/tracker.sh` carries the paginated list, the host-scoped auth guard and the `--jq` translation, only the two owned files changed, and the diff is exported outside the worktree."

**task-2-mirrors**

```bash
set -uo pipefail
EX=/home/jjrdar/.loop-work/gitlab-glab-loop/exports; mkdir -p "$EX"
fail(){ echo "FAIL: $1"; exit 1; }
[ -f tests/repo-state/mirrors-gitlab.sh ] || fail "tests/repo-state/mirrors-gitlab.sh was never created"
for s in 'gitlab-mode mirror still claims GitHub' 'local disclosure regressed' 'github disclosure regressed'; do
  grep -qF "$s" tests/repo-state/mirrors-gitlab.sh || fail "the new suite is missing a load-bearing assertion from the plan: $s"
done
bash tests/repo-state/mirrors-gitlab.sh || fail "tests/repo-state/mirrors-gitlab.sh is RED (output above)"
bash tests/repo-state/mirrors.sh || fail "the existing tests/repo-state/mirrors.sh regressed"
GH_CONFIG_DIR="$(mktemp -d)" bash tests/run.sh || fail "the full suite is RED in this worktree (output above)"
grep -qF 'GitLab issues' scripts/gen-mirrors.sh || fail "scripts/gen-mirrors.sh never emits the literal 'GitLab issues'; Task 3's finalize greps this file for that exact string, so the string is a cross-task contract"
grep -qF 'docs/issues/ local tracker' scripts/gen-mirrors.sh || fail "the local disclosure string was lost while adding the gitlab one"
git add -- scripts/gen-mirrors.sh tests/repo-state/mirrors-gitlab.sh || fail "git add of the owned paths failed"
git diff --cached -- scripts/gen-mirrors.sh tests/repo-state/mirrors-gitlab.sh > "$EX/task-2-mirrors.patch" || fail "patch export failed"
[ -s "$EX/task-2-mirrors.patch" ] || fail "the exported patch is EMPTY: no owned file was actually changed"
stray="$(git status --porcelain | sed 's/^...//' | grep -vxF -e scripts/gen-mirrors.sh -e tests/repo-state/mirrors-gitlab.sh -e report.md || true)"
[ -z "$stray" ] || fail "paths outside the ownership list were touched: $stray"
echo "OK: mirrors-gitlab green, mirrors.sh green, full suite green, patch at $EX/task-2-mirrors.patch"
```

`verified`: "The new gitlab mirror-disclosure suite, the existing mirrors suite and the full offline suite all pass, `gen-mirrors.sh` emits the exact `GitLab issues` string Task 3's finalize greps for while keeping the local disclosure, and only the two owned files changed."

**task-3-setup**

```bash
set -uo pipefail
EX=/home/jjrdar/.loop-work/gitlab-glab-loop/exports; mkdir -p "$EX"
fail(){ echo "FAIL: $1"; exit 1; }
OWNED="skills/loop-setup/setup.sh config/repo-state.template.md tests/loop-setup/acceptance.sh skills/loop-setup/SKILL.md tests/loop-setup/gitlab-setup.sh"
[ -f tests/loop-setup/gitlab-setup.sh ] || fail "tests/loop-setup/gitlab-setup.sh was never created"
for s in 'THE FORGE CASE' 'tracker-remote-ack' 'a DECLINED switch changed the tracker mode anyway' 'the gitlab finalize exited 0 with a gen-mirrors.sh that would disclose GitHub'; do
  grep -qF "$s" tests/loop-setup/gitlab-setup.sh || fail "the new suite is missing a load-bearing scenario from the plan: $s"
done
bash tests/loop-setup/gitlab-setup.sh || fail "tests/loop-setup/gitlab-setup.sh is RED (output above)"
GH_CONFIG_DIR="$(mktemp -d)" bash tests/run.sh || fail "the full suite is RED in this worktree (output above); this task edits the shared setup.sh and acceptance.sh, so the full suite is the gate, not a courtesy"
for s in 'GitHub remote found' 'GitLab remote found' 'Remote found' 'No remote found'; do
  grep -qF "$s" skills/loop-setup/setup.sh || fail "setup.sh does not print the report_remote line '$s'"
  grep -qF "$s" skills/loop-setup/SKILL.md || fail "SKILL.md does not document the report_remote line '$s' that setup.sh prints"
done
grep -qF 'tracker-remote-ack' skills/loop-setup/setup.sh || fail "setup.sh has no tracker-remote-ack acknowledgment path, so a deliberate mode-versus-remote disagreement has no off switch"
grep -qF 'tracker-remote-ack' skills/loop-setup/SKILL.md || fail "SKILL.md does not name the tracker-remote-ack off switch"
grep -qF 'accept the drift refresh' skills/loop-setup/setup.sh || fail "setup.sh does not name the fix when a vendored tracker.sh rejects the mode (step g3)"
grep -qF 'render_gitlab' skills/loop-setup/setup.sh || fail "setup.sh has no render_gitlab"
grep -qx 'template-version: 2' config/repo-state.template.md || fail "config/repo-state.template.md was not bumped to template-version 2"
grep -qF 'autonomy-default' config/repo-state.template.md || fail "the template lacks the autonomy-default paragraph, so a v2 re-render would silently destroy it in every shipped config"
grep -qF 'CONTRIBUTING.md' config/repo-state.template.md || fail "the template does not declare the sweep's root exclusions where it claims to be the definitive list"
grep -qF '(github, gitlab, or local)' skills/loop-setup/setup.sh || fail "setup.sh's hardcoded render_github sentence still says (github or local)"
EMD="$(printf '\xe2\x80\x94')"; grep -qF "$EMD" config/repo-state.template.md && fail "em dash found in config/repo-state.template.md; house style forbids it"
git add -- $OWNED || fail "git add of the owned paths failed"
git diff --cached -- $OWNED > "$EX/task-3-setup.patch" || fail "patch export failed"
[ -s "$EX/task-3-setup.patch" ] || fail "the exported patch is EMPTY: no owned file was actually changed"
stray="$(git status --porcelain | sed 's/^...//' | grep -vxF -e skills/loop-setup/setup.sh -e config/repo-state.template.md -e tests/loop-setup/acceptance.sh -e skills/loop-setup/SKILL.md -e tests/loop-setup/gitlab-setup.sh -e report.md || true)"
[ -z "$stray" ] || fail "paths outside the ownership list were touched: $stray"
echo "OK: gitlab-setup suite green, full suite green, report_remote strings agree between setup.sh and SKILL.md, patch at $EX/task-3-setup.patch"
```

`verified`: "The new gitlab-setup suite and the full offline suite both pass, `setup.sh` prints all four `report_remote` lines and `SKILL.md` documents the same four, the `tracker-remote-ack` off switch and the drift-refresh failure message exist, the template is at version 2 and still carries the autonomy-default paragraph and the sweep exclusions, and only the five owned files changed."

**task-4-sweep**

```bash
set -uo pipefail
EX=/home/jjrdar/.loop-work/gitlab-glab-loop/exports; mkdir -p "$EX"
fail(){ echo "FAIL: $1"; exit 1; }
OWNED="skills/loop-setup/setup.sh tests/loop-setup/import.sh tests/loop-setup/idempotence.sh"
[ -f tests/loop-setup/idempotence.sh ] || fail "tests/loop-setup/idempotence.sh was never created"
for s in 'the sweep offered a plan-lane file' 'BOTH same-basename candidates were moved onto one archive path' 'no archive offer may reach outside the repo' 'LOOP_ASSUME_YES alone created remote issues without LOOP_IMPORT_REMOTE' 'the gate must key on LOOP_ASSUME_YES, not MODE' 'a failed create still produced an archive move'; do
  grep -qF "$s" tests/loop-setup/idempotence.sh || fail "the new suite is missing a load-bearing scenario from the plan: $s"
done
bash tests/loop-setup/idempotence.sh || fail "tests/loop-setup/idempotence.sh is RED (output above)"
bash tests/loop-setup/import.sh || fail "tests/loop-setup/import.sh is RED (output above); it is retargeted by this task, not exempted from it"
GH_CONFIG_DIR="$(mktemp -d)" bash tests/run.sh || fail "the full suite is RED in this worktree (output above); this task edits the shared setup.sh and import.sh, so the full suite is the gate, not a courtesy"
git diff --quiet -- tests/loop-setup/reconcile.sh || fail "tests/loop-setup/reconcile.sh was modified; the plan requires it stay byte-identical to its shipped state, including its decline-then-accept contract"
git diff --quiet -- tests/repo-state/config.sh || fail "tests/repo-state/config.sh was modified; the plan requires it stay byte-identical to its shipped state"
grep -qF 'LOOP_IMPORT_REMOTE' skills/loop-setup/setup.sh || fail "setup.sh has no LOOP_IMPORT_REMOTE gate: an unattended blanket yes could file an issue per candidate on a shared instance"
grep -qF 'import candidate(s)' skills/loop-setup/setup.sh || fail "setup.sh never prints the 'found N import candidate(s)' count line, which is the only trace of the gate that survives a non-interactive run"
grep -qF 'nothing to do' skills/loop-setup/setup.sh || fail "setup.sh has no end-of-run summary, so quiet is still an absence rather than a statement"
grep -qF 'docs/archive' skills/loop-setup/setup.sh || fail "setup.sh never offers the archive move, which is the whole idempotence mechanism"
grep -qF 'docs/plans' skills/loop-setup/setup.sh || fail "setup.sh does not exclude the docs/plans lane; the first ungated run would offer every plan file in this repo for archival"
grep -qF 'skipping remote import of' skills/loop-setup/setup.sh || fail "setup.sh never prints the sweep-specific remote-import skip line"
grep -qF 'skipping archive move' skills/loop-setup/setup.sh || fail "setup.sh has no never-overwrite guard message on the archive move"
git add -- $OWNED || fail "git add of the owned paths failed"
git diff --cached -- $OWNED > "$EX/task-4-sweep.patch" || fail "patch export failed"
[ -s "$EX/task-4-sweep.patch" ] || fail "the exported patch is EMPTY: no owned file was actually changed"
stray="$(git status --porcelain | sed 's/^...//' | grep -vxF -e skills/loop-setup/setup.sh -e tests/loop-setup/import.sh -e tests/loop-setup/idempotence.sh -e report.md || true)"
[ -z "$stray" ] || fail "paths outside the ownership list were touched: $stray"
echo "OK: idempotence and import suites green, full suite green, reconcile.sh and config.sh untouched, patch at $EX/task-4-sweep.patch"
```

`verified`: "The new idempotence suite, the retargeted import suite and the full offline suite all pass, `setup.sh` carries the `LOOP_IMPORT_REMOTE` gate, the candidate count line, the summary line, the archive move with its never-overwrite guard, and the `docs/plans` exclusion, `reconcile.sh` and `config.sh` are byte-identical to their shipped state, and only the three owned files changed."

**task-5-migrate**

```bash
set -uo pipefail
EX=/home/jjrdar/.loop-work/gitlab-glab-loop/exports; mkdir -p "$EX"
fail(){ echo "FAIL: $1"; exit 1; }
OWNED="scripts/migrate-tracker.sh skills/loop-setup/setup.sh tests/repo-state/migrate-gitlab.sh"
[ -f tests/repo-state/migrate-gitlab.sh ] || fail "tests/repo-state/migrate-gitlab.sh was never created"
for s in 'the default target became gitlab' 'migration ran a BARE glab auth status' 'git rm --cached hit untracked files' 'the documented command would be a dangling path'; do
  grep -qF "$s" tests/repo-state/migrate-gitlab.sh || fail "the new suite is missing a load-bearing assertion from the plan: $s"
done
bash tests/repo-state/migrate-gitlab.sh || fail "tests/repo-state/migrate-gitlab.sh is RED (output above)"
bash tests/repo-state/migrate.sh || fail "the existing github migration suite regressed"
GH_CONFIG_DIR="$(mktemp -d)" bash tests/run.sh || fail "the full suite is RED in this worktree (output above); this task edits the shared setup.sh, so the full suite is the gate"
grep -qF -- '--to' scripts/migrate-tracker.sh || fail "scripts/migrate-tracker.sh does not parse a --to flag"
grep -qF 'glab' scripts/migrate-tracker.sh || fail "scripts/migrate-tracker.sh has no glab call sites"
grep -qF 'auth status --hostname' scripts/migrate-tracker.sh || fail "the gitlab migration path has no host-scoped auth guard"
grep -qF 'migrate-tracker.sh' skills/loop-setup/setup.sh || fail "setup.sh does not vendor migrate-tracker.sh, so the command Task 6 documents resolves to a path that exists in no repo loop-setup has set up"
git add -- $OWNED || fail "git add of the owned paths failed"
git diff --cached -- $OWNED > "$EX/task-5-migrate.patch" || fail "patch export failed"
[ -s "$EX/task-5-migrate.patch" ] || fail "the exported patch is EMPTY: no owned file was actually changed"
stray="$(git status --porcelain | sed 's/^...//' | grep -vxF -e scripts/migrate-tracker.sh -e skills/loop-setup/setup.sh -e tests/repo-state/migrate-gitlab.sh -e report.md || true)"
[ -z "$stray" ] || fail "paths outside the ownership list were touched: $stray"
echo "OK: migrate-gitlab green, migrate.sh green, full suite green, vendoring present, patch at $EX/task-5-migrate.patch"
```

`verified`: "The new gitlab migration suite, the existing github migration suite and the full offline suite all pass, `migrate-tracker.sh` parses `--to` and drives glab behind a host-scoped auth guard, `setup.sh` vendors the script so the documented command resolves, and only the three owned files changed."

**task-6-docs**

```bash
set -uo pipefail
EX=/home/jjrdar/.loop-work/gitlab-glab-loop/exports; mkdir -p "$EX"
fail(){ echo "FAIL: $1"; exit 1; }
OWNED="skills/loop-setup/SKILL.md skills/loop-setup/references/import-triage.md skills/wayfinder/SKILL.md skills/loop-improve/SKILL.md skills/loop-review/SKILL.md config/repo-state.md tests/loop-setup/docs-gitlab.sh"
[ -f tests/loop-setup/docs-gitlab.sh ] || fail "tests/loop-setup/docs-gitlab.sh was never created"
for s in 'wayfinder still states a github-only tracker requirement' 'config/repo-state.md is not at template-version 2' 'the triage reference does not state the one-item-per-issue rule'; do
  grep -qF "$s" tests/loop-setup/docs-gitlab.sh || fail "the new suite is missing a load-bearing assertion from the plan: $s"
done
bash tests/loop-setup/docs-gitlab.sh || fail "tests/loop-setup/docs-gitlab.sh is RED (output above)"
bash tests/repo-state/config.sh || fail "tests/repo-state/config.sh is RED: the template and this repo's config no longer declare the same lane set"
GH_CONFIG_DIR="$(mktemp -d)" bash tests/run.sh || fail "the full suite is RED in this worktree (output above)"
R=skills/loop-setup/references/import-triage.md
[ -s "$R" ] || fail "$R is missing or empty"
[ "$(grep -c . "$R")" -ge 15 ] || fail "$R has fewer than 15 non-blank lines; it is the only home for the split-and-merge judgment and cannot be a stub"
for t in split merg leav titl label disclos; do
  grep -qi "$t" "$R" || fail "$R never covers the '$t' judgment topic the plan assigns to it"
done
grep -qi 'idea' "$R" || fail "$R does not name the one load-bearing label"
EMD="$(printf '\xe2\x80\x94')"
for f in $OWNED; do
  case "$f" in *.md) grep -qF "$EMD" "$f" && fail "em dash found in $f; house style forbids it" ;; esac
done
git add -- $OWNED || fail "git add of the owned paths failed"
git diff --cached -- $OWNED > "$EX/task-6-docs.patch" || fail "patch export failed"
[ -s "$EX/task-6-docs.patch" ] || fail "the exported patch is EMPTY: no owned file was actually changed"
stray="$(git status --porcelain | sed 's/^...//' | grep -vxF -e skills/loop-setup/SKILL.md -e skills/loop-setup/references/import-triage.md -e skills/wayfinder/SKILL.md -e skills/loop-improve/SKILL.md -e skills/loop-review/SKILL.md -e config/repo-state.md -e tests/loop-setup/docs-gitlab.sh -e report.md || true)"
[ -z "$stray" ] || fail "paths outside the ownership list were touched: $stray"
echo "OK: docs-gitlab green, config.sh green, full suite green, triage reference has substance, no em dashes, patch at $EX/task-6-docs.patch"
```

`verified`: "The new docs suite, the lane-parity config suite and the full offline suite all pass, the import-triage reference exists with at least fifteen lines covering all six judgment topics the plan assigns it, no touched markdown file carries an em dash, and only the seven owned files changed."

### Review task template (task-4-review, task-6-review)

Run these as a one-task manifest at the unit's gate, AFTER the patch is applied and committed on the integration branch, with the same `run_name` `gitlab-glab-loop`, `"worktrees": true`, `max_parallel` 1, `engine` `claude`, `model` `opus`, `task_type` `code-review`, `timeout_s` 1800, `expect_files` `["report.md"]`.

Spec, verbatim (substitute the unit's name, its commit, its ownership list, and the unit's section of the source plan appended in full, exactly as for an implementer):

> You are an adversarial, read-only reviewer of unit `<key>`, already implemented and committed as `<commit>` on branch `integration/gitlab-glab-loop`. Your working directory is a fresh git worktree at that commit.
>
> You are READ-ONLY on the repository. Do not edit, create, delete, stage, or commit any repository file. Do not fix anything you find. The only file you write is `./report.md` at the worktree root.
>
> Your job is to REFUTE the claim that this unit is done. Judge the raw evidence only: the diff (`git show <commit>`), the test files as they now stand, and your own independent reruns. The implementer's narrative is not evidence and you will not be shown it.
>
> Do all of this:
> 1. Rerun the suites yourself: the unit's own new suite, and `GH_CONFIG_DIR="$(mktemp -d)" bash tests/run.sh`. Record the exact final `ran N suites: P passed, F failed` line.
> 2. Walk EVERY acceptance criterion in the task text below, one at a time, and cite the concrete evidence for your verdict on each as `path:line`.
> 3. Audit the scope boundary: `git show --stat <commit>` against the ownership list `<ownership list>`. Any file outside it is a finding.
> 4. Audit the test edits specifically. This unit was authorized to modify existing suites. For each changed assertion, decide whether it was RETARGETED (the same property, now asserted where the new design puts it) or WEAKENED (the property is no longer asserted at all). A weakened assertion is a fail, and an executed check cannot catch it because the check runs the suite the implementer just edited. `git diff <commit>^ <commit> -- <the existing suites this unit touched>` is where you look.
> 5. Name the cheapest observation that would falsify your own conclusion, and if it costs under a minute, run it before you write the report.
>
> VERDICT DISCIPLINE: if ANY criterion fails, the overall verdict is `fail`. Do not write `pass` while your own notes contradict it. Use `spec-problem` when the task text itself is wrong or unsatisfiable, so the orchestrator fixes the spec instead of running a futile repair loop.
>
> OUTPUT CONTRACT: write `./report.md` containing, in this order:
> - a line `verdict: pass` or `verdict: fail` or `verdict: spec-problem`, at the left margin, exactly once;
> - one line per criterion, in the format `- criterion <n>: PASS - <evidence with path:line>` or `- criterion <n>: FAIL - <evidence with path:line>`;
> - a `## Scope audit` section listing every changed path and whether it is owned;
> - a `## Test-edit audit` section classifying each changed assertion as retargeted or weakened, with the diff hunk cited;
> - a `## Reruns` section with the exact suite output lines;
> - a `## What would change my verdict` section.
>
> THE UNIT'S TASK TEXT FOLLOWS, verbatim from the source plan.
>
> ---

Review check:

```bash
set -uo pipefail
fail(){ echo "FAIL: $1"; exit 1; }
[ -s report.md ] || fail "no report.md was written; the review produced nothing to read"
grep -qE '^verdict:[[:space:]]*(pass|fail|spec-problem)[[:space:]]*$' report.md || fail "report.md has no single machine-readable 'verdict: pass|fail|spec-problem' line at the left margin"
[ "$(grep -cE '^verdict:' report.md)" -eq 1 ] || fail "report.md carries more than one verdict line; exactly one verdict is the contract"
c="$(grep -ciE '^- criterion ' report.md)"
[ "$c" -ge 3 ] || fail "report.md walks only $c criteria; an evidence-first review walks every acceptance criterion of the task"
n="$(grep -oE '[A-Za-z0-9_./-]+\.(sh|md|toml|json):[0-9]+' report.md | wc -l)"
[ "$n" -ge 6 ] || fail "report.md carries only $n path:line citations; a review that cannot point at the artifact is an opinion, not evidence"
grep -qE 'ran [0-9]+ suites: [0-9]+ passed, [0-9]+ failed' report.md || fail "report.md does not record the full suite's own output line, so the mandatory independent rerun cannot be confirmed"
for s in '## Scope audit' '## Test-edit audit' '## Reruns' '## What would change my verdict'; do
  grep -qF "$s" report.md || fail "report.md is missing its required section: $s"
done
if grep -qiE '^- criterion .*:[[:space:]]*FAIL' report.md && ! grep -qE '^verdict:[[:space:]]*(fail|spec-problem)[[:space:]]*$' report.md; then
  fail "verdict discipline broken: at least one criterion is marked FAIL while the overall verdict is not fail"
fi
[ -z "$(git status --porcelain | sed 's/^...//' | grep -vxF report.md || true)" ] || fail "a READ-ONLY reviewer modified the repository: $(git status --porcelain)"
echo "OK: report.md carries one verdict, $c criteria, $n citations, all four required sections, an independent suite rerun, and verdict discipline holds; the tree is untouched"
```

`verified`: "The review wrote exactly one machine-readable verdict, walked at least three criteria with at least six `path:line` citations, recorded its own independent full-suite rerun, produced the scope, test-edit, rerun and falsification sections, kept verdict discipline (no FAIL criterion under a non-fail verdict), and modified nothing in the repository."

### Wave 6: Task 7 has no template

Task 7 is not dispatched.
The orchestrator works through the source plan's Steps 1 through 8 in-session, staging every command for the user and recording each observed value in the source plan's own results table.
The task is not done until every row of that table has an observed value.

## 9. Kicking it off

The human says: "Run the gitlab loop, wave 1."
The orchestrator runs the pre-flight checklist for real, reports the capability probe and the dirty-tree state, creates `integration/gitlab-glab-loop`, lints and baselines the wave-1 manifest, then launches it.
Per-wave summaries land as sections of `docs/handoffs/2026-08-09-gitlab-glab-loop-run-state.md`, committed on the integration branch at every gate.
Watch the run live on Ringside at `http://127.0.0.1:8700`, or with `tail -f /home/jjrdar/.loop-work/gitlab-glab-loop/logs/*.log` during a wave; at each gate read the run JSON in `~/.ringer/runs/`, the exported patch in `/home/jjrdar/.loop-work/gitlab-glab-loop/exports/`, and the worker's `report.md` snapshot in `/home/jjrdar/.loop-work/gitlab-glab-loop/logs/<key>.reports/`.
The watch points that matter most: a task that passed only on attempt 2 (read its log for the spec ambiguity), a check failure with a useless message (that is a check bug, not a worker failure), and any patch that touches a file outside its ownership list.
Wave 6 is the human checkpoint and every write in it is the user's to fire.
If the session dies at any point, use the verbatim resume prompt in section 7.
