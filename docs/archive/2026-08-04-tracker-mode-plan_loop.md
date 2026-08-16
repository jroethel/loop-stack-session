# Tracker Mode - orchestration plan (loop-drive compiled)

## 1. What this file is

This is the agent-orchestrated execution plan derived from `docs/plans/2026-08-04-tracker-mode-plan.md`.
One frontier-model driving session executes it end to end; no human pastes prompts by hand.
The source plan remains the manual fallback and stays ground truth for acceptance criteria, scope, and the verbatim test and code blocks.
Spec edits made during the run are applied to the source plan, not only here.
Every unit rides the ringer transport; there are no Agent-tool units in this run.

## 2. Routing table

Every unit routes to `glm-5.2` on the flat-rate `claude-zai` lane.
The choice is quota-preserving and evidence-backed: the source plan is TDD with embedded verbatim test files and implementation code, which is the exact "committed-RED-test, GREEN-only, embedded-verbatim-spec" shape this lane went 10/10 attempt-1 on in this very repo (loop-stack build-wave).
No unit is taste-flagged (all acceptance criteria are executed bash tests), so no per-unit engine ask is offered.

| Unit   | Wave | task_type    | Model   | Transport | Engine     | Impl. effort | Val. effort | Evidence |
|--------|------|--------------|---------|-----------|------------|--------------|-------------|----------|
| Task 1 | 1    | code-feature | glm-5.2 | ringer    | claude-zai | medium       | check-only  | post[^1] |
| Task 2 | 1    | code-feature | glm-5.2 | ringer    | claude-zai | high         | check-only  | post[^1] |
| Task 8 | 1    | docs         | glm-5.2 | ringer    | claude-zai | medium       | check-only  | post[^3] |
| Task 3 | 2    | code-fix     | glm-5.2 | ringer    | claude-zai | medium       | check-only  | post[^2] |
| Task 4 | 2    | code-fix     | glm-5.2 | ringer    | claude-zai | medium       | check-only  | post[^2] |
| Task 6 | 2    | code-feature | glm-5.2 | ringer    | claude-zai | high         | check-only  | post[^1] |
| Task 5 | 3    | code-feature | glm-5.2 | ringer    | claude-zai | high         | check-only  | post[^1] |
| Task 7 | 4    | code-feature | glm-5.2 | ringer    | claude-zai | medium       | check-only  | post[^1] |

`Impl. effort` is advisory for the `claude-zai` lane (it exposes no reasoning-effort knob); it is recorded for gate attention, not passed as `engine_args`.
`Val. effort` is `check-only` because validation is the task's own executed acceptance test (strong, plan-supplied) run inside the worktree plus a non-empty-patch guard; no separate review task is added.

[^1]: glm-5.2 code-feature posterior 84% first-try over 25 tasks (proven tier); on THIS repo the loop-stack build-wave logged 10/10 attempt-1 across code-feature/code-fix/docs with the exact committed-RED-test, GREEN-only, embedded-verbatim-spec shape this plan uses. Flat-rate lane preserves Anthropic quota; no unit is taste-flagged.
[^2]: glm-5.2 code-fix raw posterior 100% first-try over 9 tasks. Per ringer #65 the code-fix and docs posteriors are DEPRESSED by up to seven misattributed stm-nav fails, so the true rate reads at least as high, not lower; the benchmark prior independently lands glm-5.2 (claude-zai) at Strong tier for quota-free execution. Routing holds on posterior, prior, and this-repo evidence alike.
[^3]: glm-5.2 docs raw posterior 100% first-try over 7 tasks, same #65 depression caveat and same Strong-tier prior corroboration as code-fix. Task 8 is mechanical prose with verbatim edits supplied in the source plan.

## 3. Orchestration shape and validation layers

One orchestrator session drives four dependency-ordered waves.
Each unit flows implement then validate independently inside its own ringer worktree.

```
orchestrator (this session)
├── wave 1  (integration base = 069d36f)
│   ├── Task 1  ringer/glm-5.2  config schema        ──> check: bash tests/repo-state/config.sh
│   ├── Task 2  ringer/glm-5.2  scripts/tracker.sh   ──> check: bash tests/repo-state/tracker.sh
│   └── Task 8  ringer/glm-5.2  prose fixes          ──> check: check.sh + wayfinder.sh + loop-brainstorm.sh
│       gate: apply patches -> integration, real commits, full suite, MODEL-NOTES on signal
├── wave 2  (integration base = wave-1 result)
│   ├── Task 3  ringer/glm-5.2  gen-mirrors seam     ──> check: bash tests/repo-state/mirrors.sh
│   ├── Task 4  ringer/glm-5.2  graduate-parking     ──> check: bash tests/gates/loop-brainstorm.sh
│   └── Task 6  ringer/glm-5.2  migrate-tracker.sh   ──> check: bash tests/repo-state/migrate.sh
│       gate: apply patches -> integration, real commits, full suite, MODEL-NOTES on signal
├── wave 3  (integration base = wave-2 result)
│   └── Task 5  ringer/glm-5.2  setup declares mode  ──> check: bash tests/loop-setup/acceptance.sh
│       gate: apply patch -> integration, real commit, full suite, MODEL-NOTES on signal
└── wave 4  (integration base = wave-3 result)
    └── Task 7  ringer/glm-5.2  local-workflow gate  ──> check: bash tests/repo-state/local-workflow.sh
        gate: apply patch -> integration, real commit, FULL 9-test sweep, MODEL-NOTES on signal
        then advisory: /loop-review 069d36f from the integration branch
```

Three validation layers hold for every unit: the implementer's own test-first self-check, the per-unit executed ringer `check` (the primary, non-negotiable gate), and the orchestrator gate (patch audit, integration-branch full suite).
Waves 3 and 4 each snapshot a tree that already contains all prior waves' merged work: each wave's manifest runs only after the previous gate has merged into the integration branch, and the main repo is left on that branch so ringer's worktrees snapshot the updated tree.

## 4. Hazard mitigations

All units ride ringer, so only the ringer hazard set applies; the Agent-tool hazard set does not.

- Worktree isolation, per-task directories, and log separation are handled by run-level `"worktrees": true`; not re-specified per task.
- Deliverables die with a passing worktree, so each check exports the task's changes as a patch to a path OUTSIDE the worktree before ringer deletes it: `git add -A && git diff --cached > /Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave<N>-task<M>.patch`, guarded by `test -s` so a no-op worker fails. The orchestrator applies the reviewed patch to the integration branch at the gate. Deviation from the source plan, which assumed one persistent checkout that each task commits into directly.
- Authoritative landing is the orchestrator's commit, not the worker's. Workers must NOT commit inside their worktree: every check exports `git add -A && git diff --cached` (index vs HEAD), so a worker commit would empty the patch and fail a correct worker; the specs state this rule. The real, authoritative commit is made by the orchestrator on the integration branch from the exported patch, using the source plan's exact Step 5 commit messages (mapped in Section 6). At a gate, an empty-patch FAIL paired with worker commits in the log is attributed as a rule slip, not missing work. Deviation from the source plan, which has each task self-commit at its Step 5.
- No task delivers a gitignored path (every deliverable is a tracked script, test, config, or doc), so the `cp`-outside mitigation for gitignored outputs is not needed here; `git add -A` captures all owned edits.
- No unit uses the `opencode` engine (all are `claude-zai`), so the OpenCode sqlite/WAL stagger hazard does not apply; `max_parallel` runs the wave at full width.
- Disjoint-files invariant: within every wave, units touch disjoint files by construction, and ownership is disjoint across waves too (later tasks only CALL earlier tasks' files, never edit them). A merge conflict at any gate is therefore a scope violation to surface, not something to quietly resolve.

## 5. Pre-flight checklist

- [ ] Capability probe result: ringer present. Engines wired in `~/.config/ringer/config.toml`: `codex`, `claude` (haiku default), `claude-zai` (glm-5.2, flat-rate), `opencode` (glm-5.2 via OpenRouter). Not degraded mode. Ringer repo root: `/Users/jjrdar/repos/ringer`.
- [ ] Working repo `/Users/jjrdar/create/loops/loop-stack-session` at commit `069d36f`, branch `main`. NOTE: one untracked file is present, `docs/reviews/2026-08-04-tracker-mode-batch-review.md`; it is outside every task's ownership and (being untracked) never enters a worktree, so it does not block the run. Surface it to the human as the pre-flight dirty-tree decision before wave 1.`[gate:STOP]`
- [ ] Create the integration branch off the pre-run base: `git -C /Users/jjrdar/create/loops/loop-stack-session checkout -b tracker-mode-integration 069d36f`.
- [ ] Add `.loop-patches/` and `.loop-work/` to `.gitignore` (one commit) so exported patches, wave manifests, and the run-state artifact never pollute `git status` or get committed with the real work. Deviation: two new ignore lines the source plan did not have.
- [ ] Create the orchestrator work dirs: `mkdir -p /Users/jjrdar/create/loops/loop-stack-session/.loop-patches /Users/jjrdar/create/loops/loop-stack-session/.loop-work /tmp/tracker-mode`.
- [ ] Write the four wave manifests to `.loop-work/wave1.json` .. `.loop-work/wave4.json` (Section 8), each with `run_name: "tracker-mode"`, `workdir: "/tmp/tracker-mode"`, `worktrees: true`, `repo` pointing at the working repo.
- [ ] Lint each manifest before its wave: `cd /Users/jjrdar/repos/ringer && ./ringer.py lint /Users/jjrdar/create/loops/loop-stack-session/.loop-work/wave1.json`.
- [ ] Create the run-state artifact `.loop-work/run-state.json` (Section 7), updated at every launch and gate.
- [ ] Confirm `tests/repo-state/fixtures/issues.json` exists (Task 5 acceptance consumes it as `$FIX`); it ships with the repo. If absent, that is a spec problem to raise, not a unit to relaunch.

## 6. Wave-loop procedure and gates

Per wave, in order:

1. Put the main repo on the integration branch so worktrees snapshot the current work: `git -C /Users/jjrdar/create/loops/loop-stack-session checkout tracker-mode-integration`.
2. Launch the wave's packed manifest: `cd /Users/jjrdar/repos/ringer && ./ringer.py lint <wave>.json && ./ringer.py run <wave>.json --identity drive-tracker-mode`. The SAME `run_name` (`tracker-mode`) is used across all four waves. Ringer's built-in single retry IS the repair pass; do not add another.
3. Gate (orchestrator reads truth, never the summary line alone):
   - Read the run JSON in `~/.ringer/runs/` (statuses, retries, durations). The run JSON is truth; a detached shell's exit status is transport and can lie.
   - For every retried or failed task, read the raw worker log in `/tmp/tracker-mode/logs/` before deciding anything. Spot-check at least one passing task's exported patch.
   - On a FAIL, attribute before relaunching: re-run the check's steps yourself against the worktree tree. If the worker's output was correct and the CHECK was wrong, fix the check, commit the audited work, and annotate MODEL-NOTES (with an amendment when available) instead of burning a round.
   - Apply each passing unit's reviewed patch to the integration branch and make the AUTHORITATIVE commit with the source plan's exact Step 5 message:
     - Task 1: `git apply .loop-patches/wave1-task1.patch` then commit `tracker mode: declared tracker: key + Local tracker section in repo-state schema`.
     - Task 2: `wave1-task2.patch` then commit `tracker mode: scripts/tracker.sh backend seam (github|local) with unit test`.
     - Task 8: `wave1-task8.patch` then commit `tracker mode: prose fixes - backend-agnostic close verb, wayfinder github requirement, roadmap mirror refs`.
     - Task 3: `wave2-task3.patch` then commit `tracker mode: gen-mirrors sources issues via tracker.sh list, mode-aware header`.
     - Task 4: `wave2-task4.patch` then commit `tracker mode: graduate-parking creates via tracker.sh create (backend-agnostic)`.
     - Task 6: `wave2-task6.patch` then commit `tracker mode: migrate-tracker.sh local->github migration with dry-run`.
     - Task 5: `wave3-task5.patch` then commit `tracker mode: setup declares tracker mode (asks once, never guesses), installs tracker.sh`.
     - Task 7: `wave4-task7.patch` then commit `tracker mode: end-to-end local-mode workflow gate (criterion 4, gh-absent)`.
     - Stage only the owned paths when committing (never a bare `git add -A` in the integration checkout).
   - Re-run the acceptance tests of every task merged so far on the integration branch; on the FINAL wave run the full 9-test sweep (the source plan's one-line for-loop over all nine test files). Advance only when green.
4. Distill before advancing (P10): fold any repeated failure pattern from this wave into the source plan's specs and this file's manifests before the next wave, so the next wave does not re-earn the failure.
5. MODEL-NOTES on signal only (pin-review correction): every unit rides ringer, whose runs feed the scoreboard directly, so no per-wave batched receipt is owed - that obligation applies to Agent-tool units, which have no other durable record. Append a dated line to `/Users/jjrdar/repos/ringer/docs/MODEL-NOTES.md` only for a signal event (a pin, a runtime re-route, a check-bug attribution, an off-nominal result), supported only by executed checks and diffs, and commit it in the ringer repo BEFORE advancing the wave.
6. Write the wave summary to `.loop-work/wave-<N>-summary.md`; ringer prunes its own worktrees.

Ask-the-human list (the orchestrator stops and asks):

- Pre-flight dirty-tree decision (the untracked review doc noted in Section 5).`[gate:STOP]`
- Any request to exceed the `high` effort cap.`[gate:STOP]`
- A spec edit that touches multiple units, a global constraint, or a unit's produced contract, or that exceeds 15 changed lines.`[gate:STOP]` A spec edit confined to a single unit or criterion, leaving unchanged what that unit produces, and touching 15 or fewer lines, auto-takes as BATCH.`[gate:BATCH]` The boundary is blast radius, not raw size; 15 lines is the agreed threshold.
- Any outward-facing unit (touches live consumers, publishes, or deletes things the human owns).`[gate:STOP]` NOTE: Task 6's REAL local-to-github migration IS outward-facing (it creates GitHub issues), but the run executes ONLY Task 6's DRY-RUN plus stubbed-gh acceptance (`tests/repo-state/migrate.sh` drives `MIGRATE_DRY_RUN=1` and, for the resume leg, a recording gh stub). No outward-facing action fires during this run. The un-dry migration against a throwaway or real repo is the human's advisory real-data eyeball from the source plan's Human checkpoints, deferred to after the run.

Slip rules: a stopped unit whose root cause is a design issue (not a small spec fix) is recorded for the source plan's downstream review step, not silently patched. A small spec issue means edit the spec artifact and relaunch that one unit.

Final-wave advisory review: after wave 4's integration branch is green and the run advances, run `/loop-review 069d36f` from the integration branch so the two-axis Spec and Standards report judges the whole-run diff.`[gate:BATCH]` This review is advisory and non-blocking (the per-unit checks already gated correctness); its findings are recorded at the final human checkpoint, and any Spec-axis finding is slipped to the source plan's downstream review step under the same slip rule as a stopped unit's design issue.

## 7. Quota and resume

Design for interruption: the orchestrator cannot see the human's remaining quota, so the loop must die safely at any moment.

Durable-state rules:

- Ringer commits each worker's work to its worktree and writes raw logs to `/tmp/tracker-mode/logs/` before returning; the run JSON in `~/.ringer/runs/` records every attempt.
- The orchestrator maintains `.loop-work/run-state.json`, updated at every launch and every gate, recording per unit: wave, launched, check verdict, patch-exported, patch-applied, integration-committed.
- Exported patches persist in `.loop-patches/`; applied-and-committed work persists on the `tracker-mode-integration` branch. Git is the durable record; the state file is a convenience.

Reconciliation procedure (on resume):

1. Trust git over the state file. Read the real state of the `tracker-mode-integration` branch (`git -C <repo> log --oneline`) and cross-reference against the eight authoritative commit messages in Section 6.
2. Any unit NOT confirmed as merged-and-committed on the integration branch AND green under its acceptance test is relaunched from scratch (never resumed mid-flight). Ringer worktrees are ephemeral; a half-done unit is re-run as a fresh one-task-in-its-wave manifest.
3. Check the ringer repo for an uncommitted MODEL-NOTES receipt owed by the last gate: `git -C /Users/jjrdar/repos/ringer status --short docs/MODEL-NOTES.md`. If the last completed wave has no committed receipt, write and commit it before advancing (the run drives two repos; both are checkpointed).
4. Resume the wave loop from the first wave with any unmerged unit.

Verbatim resume prompt:

> Resume the tracker-mode loop from `docs/plans/2026-08-04-tracker-mode-plan_loop.md`. Read `.loop-work/run-state.json` and the real git state of the `tracker-mode-integration` branch and any worktrees. Trust git over the state file. Cross-reference the branch against the eight authoritative commit messages in Section 6; relaunch any unit not confirmed merged, committed, and green under its acceptance test (never resume a half-done unit). Check `/Users/jjrdar/repos/ringer` for an uncommitted MODEL-NOTES receipt owed by the last gate and commit it before advancing. Continue the wave loop from the first wave that still has an unmerged unit.

## 8. Manifests (Step 4 conversions, ready to lint and run)

Each spec is self-contained (role, boundary, scope, ownership, how-to-run, output contract) and points the worker at the exact source-plan line ranges for the verbatim test files and implementation code, which live on disk at `/Users/jjrdar/create/loops/loop-stack-session/docs/plans/2026-08-04-tracker-mode-plan.md` (readable by the worker inside its worktree).
Every check runs the task's own acceptance test(s), prints WHY on failure (the test files self-print `FAIL:` lines), then exports the patch and guards it non-empty.
`expect_files` declares the persisted deliverable - the exported `.patch` (absolute path, outside the worktree) - not the worktree-relative source files, which ringer deletes on pass; ringer runs the check before the expect_files existence gate, so the patch is present when it is checked.

### Wave 1 manifest (`.loop-work/wave1.json`)

```json
{
  "run_name": "tracker-mode",
  "workdir": "/tmp/tracker-mode",
  "worktrees": true,
  "repo": "/Users/jjrdar/create/loops/loop-stack-session",
  "max_parallel": 3,
  "tasks": [
    {
      "key": "task1-config-schema",
      "task_type": "code-feature",
      "engine": "claude-zai",
      "model": "glm-5.2",
      "timeout_s": 900,
      "spec": "You are the implementer for unit Task 1 (config schema: the declared tracker: key + the Local tracker section). Your current working directory IS an isolated git worktree of the loop-stack-session repo, detached at the integration branch HEAD - edit files here directly. NEVER touch any file outside your ownership list, never touch main, never push. You OWN exactly three files: config/repo-state.template.md, config/repo-state.md, tests/repo-state/config.sh. Scope: add a line-anchored tracker: key parallel to the existing autonomy-default: key; replace the template's `## Fallback (no remote)` section with a `## Local tracker` section carrying the disclosures; mirror the same edits into config/repo-state.md and add a literal `tracker: github` line beneath its Remote: line; and rewrite the affected assertions in tests/repo-state/config.sh. The verbatim template paragraphs (source-plan lines 103-125), the verbatim test-assertion block (lines 128-136), and the exact Steps 1-3 are in the source plan at /Users/jjrdar/create/loops/loop-stack-session/docs/plans/2026-08-04-tracker-mode-plan.md lines 83-143 - read that range and apply Steps 1-3 exactly; reproduce the marked verbatim blocks character for character. Work test-first: after your edits the acceptance must pass. HOW TO RUN: from the worktree root, `bash tests/repo-state/config.sh` must exit 0 and print `PASS: config/repo-state.md and CLAUDE.md pointer complete`. Do NOT rely on committing; leave your changes in the working tree (the orchestrator lands the authoritative commit from an exported patch). If anything is ambiguous, take the most conservative reading that satisfies the plan's verbatim blocks and note it in your final summary. Output contract: the three owned files edited as specified.",
      "expect_files": ["/Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave1-task1.patch"],
      "check": "bash tests/repo-state/config.sh || { echo 'FAIL: tests/repo-state/config.sh did not pass (see assertions above)'; exit 1; }; mkdir -p /Users/jjrdar/create/loops/loop-stack-session/.loop-patches; git add -A; git diff --cached > /Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave1-task1.patch; test -s /Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave1-task1.patch || { echo 'FAIL: empty patch - worker exported no changes'; exit 1; }; echo 'OK: Task 1 acceptance passed; patch exported to .loop-patches/wave1-task1.patch'",
      "verified": "tests/repo-state/config.sh passes (tracker: key present, Local tracker section and both disclosures in the template) and a non-empty patch is exported outside the worktree."
    },
    {
      "key": "task2-tracker-seam",
      "task_type": "code-feature",
      "engine": "claude-zai",
      "model": "glm-5.2",
      "timeout_s": 1800,
      "spec": "You are the implementer for unit Task 2 (scripts/tracker.sh - the single backend seam). Your current working directory IS an isolated git worktree of the loop-stack-session repo - edit files here directly. NEVER touch any file outside your ownership, never touch main, never push. You OWN exactly two files: scripts/tracker.sh (create, executable) and tests/repo-state/tracker.sh (create, the unit test). Scope: implement a tracker.sh that reads config/repo-state.md's ^tracker: key and dispatches every issue op (mode get|set, list, create, close, reopen) to the github (gh) or local (docs/issues/*.md) backend, operating on the caller's cwd repo. Work test-first: FIRST write the failing unit test VERBATIM from the source plan at /Users/jjrdar/create/loops/loop-stack-session/docs/plans/2026-08-04-tracker-mode-plan.md lines 170-269 into tests/repo-state/tracker.sh; run it and confirm it FAILs with `scripts/tracker.sh missing or not executable`. THEN implement scripts/tracker.sh: the load-bearing pieces (key read/write, gh_guard, slugify/fm/json_escape, next_number/find_issue_file, local_create, local_set_state, local_list) are VERBATIM in the source plan lines 272-382 - reproduce them exactly, and wrap them in a loop-auto.sh-style `set -uo pipefail` / `fail()` / subcommand-dispatch skeleton per the dispatch guidance at line 383 (bind the mode in the PARENT scope via `mode=\"$(tracker_mode_get)\" || fail ...`, never a require_mode subshell; gh path calls gh_guard first; usage lists all subcommands; unknown subcommand exits 1). `chmod +x scripts/tracker.sh`. HOW TO RUN: from the worktree root, `bash tests/repo-state/tracker.sh` must exit 0 and print `PASS: tracker.sh mode r/w, local create/close/reopen/list JSON shape, and zero-gh guarantee verified`. Do NOT rely on committing; leave changes in the working tree. If ambiguous, take the conservative reading that satisfies the verbatim blocks and note it. Output contract: scripts/tracker.sh (executable) and tests/repo-state/tracker.sh.",
      "expect_files": ["/Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave1-task2.patch"],
      "check": "test -x scripts/tracker.sh || { echo 'FAIL: scripts/tracker.sh missing or not executable'; exit 1; }; bash tests/repo-state/tracker.sh || { echo 'FAIL: tests/repo-state/tracker.sh did not pass (see FAIL line above)'; exit 1; }; mkdir -p /Users/jjrdar/create/loops/loop-stack-session/.loop-patches; git add -A; git diff --cached > /Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave1-task2.patch; test -s /Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave1-task2.patch || { echo 'FAIL: empty patch - worker exported no changes'; exit 1; }; echo 'OK: Task 2 acceptance passed; patch exported to .loop-patches/wave1-task2.patch'",
      "verified": "scripts/tracker.sh is executable and its unit test passes (mode r/w, local create/close/reopen, gh-shaped list JSON, and the zero-gh-in-local guarantee); a non-empty patch is exported outside the worktree."
    },
    {
      "key": "task8-prose-fixes",
      "task_type": "docs",
      "engine": "claude-zai",
      "model": "glm-5.2",
      "timeout_s": 900,
      "spec": "You are the implementer for unit Task 8 (prose fixes: stray gh assumptions in skills and roadmap). Your current working directory IS an isolated git worktree of the loop-stack-session repo - edit files here directly. NEVER touch any file outside your ownership, never touch main, never push. You OWN exactly three files: skills/loop-brainstorm/SKILL.md, skills/wayfinder/SKILL.md, ROADMAP.md. Scope: three surgical prose edits so no prose hard-codes a github-only tracker verb where the backend is now declared. The exact before/after text for each edit is VERBATIM in the source plan at /Users/jjrdar/create/loops/loop-stack-session/docs/plans/2026-08-04-tracker-mode-plan.md lines 982-984 - apply exactly those three edits (loop-brainstorm line 201 close verb -> scripts/tracker.sh close; a wayfinder `requires tracker: github` disclosure line; and the two ROADMAP backlog references -> the BACKLOG.md mirror). This is pure prose; there is no failing-test-first. The guard is that the existing gate tests still pass. HOW TO RUN: from the worktree root, `bash tests/gates/check.sh && bash tests/gates/wayfinder.sh && bash tests/gates/loop-brainstorm.sh` must all exit 0. Do NOT rely on committing; leave changes in the working tree. If ambiguous, take the conservative reading that satisfies the verbatim edits and note it. Output contract: the three owned files edited as specified.",
      "expect_files": ["/Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave1-task8.patch"],
      "check": "bash tests/gates/check.sh && bash tests/gates/wayfinder.sh && bash tests/gates/loop-brainstorm.sh || { echo 'FAIL: a Task 8 regression gate did not pass (see output above)'; exit 1; }; mkdir -p /Users/jjrdar/create/loops/loop-stack-session/.loop-patches; git add -A; git diff --cached > /Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave1-task8.patch; test -s /Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave1-task8.patch || { echo 'FAIL: empty patch - worker exported no changes'; exit 1; }; echo 'OK: Task 8 acceptance passed; patch exported to .loop-patches/wave1-task8.patch'",
      "verified": "the three prose edits are in place and the gate tests (check.sh, wayfinder.sh, loop-brainstorm.sh) still pass; a non-empty patch is exported outside the worktree."
    }
  ]
}
```

### Wave 2 manifest (`.loop-work/wave2.json`)

Runs from the integration branch after the wave-1 gate merged Tasks 1, 2, and 8, so each worktree already contains `scripts/tracker.sh`.

```json
{
  "run_name": "tracker-mode",
  "workdir": "/tmp/tracker-mode",
  "worktrees": true,
  "repo": "/Users/jjrdar/create/loops/loop-stack-session",
  "max_parallel": 3,
  "tasks": [
    {
      "key": "task3-gen-mirrors-seam",
      "task_type": "code-fix",
      "engine": "claude-zai",
      "model": "glm-5.2",
      "timeout_s": 900,
      "spec": "You are the implementer for unit Task 3 (gen-mirrors sources issues via tracker.sh list). Your current working directory IS an isolated git worktree of the loop-stack-session repo (it already contains scripts/tracker.sh from prior work) - edit files here directly. NEVER touch any file outside your ownership, never touch main, never push. You OWN exactly two files: scripts/gen-mirrors.sh and tests/repo-state/mirrors.sh. Scope: make gen-mirrors read its issue JSON from `scripts/tracker.sh list` (keeping the MIRRORS_JSON_FILE fixture hook FIRST and unchanged) and make the `source of truth:` header label mode-appropriate. Work test-first: FIRST append the VERBATIM local-source subtest from the source plan at /Users/jjrdar/create/loops/loop-stack-session/docs/plans/2026-08-04-tracker-mode-plan.md lines 409-445 into tests/repo-state/mirrors.sh, before its final `echo \"PASS...\"`; run it and confirm it FAILs at `local idea issue #2 did not render into BACKLOG.md`. THEN implement the two gen-mirrors edits VERBATIM from the source plan lines 449-458 (the seam-sourcing else-branch and the SRC_LABEL block, plus changing the header line 91 to `echo \"source of truth: $SRC_LABEL\"`). HOW TO RUN: from the worktree root, `bash tests/repo-state/mirrors.sh` must exit 0 and print `PASS: mirror split, disclosure, table-row anchoring, and descending sort all verified`. Do NOT rely on committing; leave changes in the working tree. If ambiguous, take the conservative reading and note it. Output contract: scripts/gen-mirrors.sh and tests/repo-state/mirrors.sh edited as specified.",
      "expect_files": ["/Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave2-task3.patch"],
      "check": "bash tests/repo-state/mirrors.sh || { echo 'FAIL: tests/repo-state/mirrors.sh did not pass (see FAIL line above)'; exit 1; }; mkdir -p /Users/jjrdar/create/loops/loop-stack-session/.loop-patches; git add -A; git diff --cached > /Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave2-task3.patch; test -s /Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave2-task3.patch || { echo 'FAIL: empty patch - worker exported no changes'; exit 1; }; echo 'OK: Task 3 acceptance passed; patch exported to .loop-patches/wave2-task3.patch'",
      "verified": "mirrors.sh passes including the local-source subtest (gen-mirrors renders from docs/issues/ via tracker.sh list with labels intact and a mode-appropriate header, zero gh); a non-empty patch is exported outside the worktree."
    },
    {
      "key": "task4-graduate-parking-seam",
      "task_type": "code-fix",
      "engine": "claude-zai",
      "model": "glm-5.2",
      "timeout_s": 900,
      "spec": "You are the implementer for unit Task 4 (graduate-parking creates via tracker.sh create). Your current working directory IS an isolated git worktree of the loop-stack-session repo (it already contains scripts/tracker.sh) - edit files here directly. NEVER touch any file outside your ownership, never touch main, never push. You OWN exactly two files: scripts/graduate-parking.sh and tests/gates/loop-brainstorm.sh. Scope: route graduation issue-creation through `scripts/tracker.sh create --label idea --title <t> --body <b>` (backend-agnostic), so the new number comes from tracker.sh stdout instead of a parsed gh URL, and the dry-run prints a tracker.sh create line per parked item. Work test-first: FIRST update the dry-run assertion in tests/gates/loop-brainstorm.sh VERBATIM per the source plan at /Users/jjrdar/create/loops/loop-stack-session/docs/plans/2026-08-04-tracker-mode-plan.md lines 486-489 (count `tracker.sh create` calls, expect 2); leave lines 44-47 unchanged; run it and confirm it FAILs with `expected 2 tracker.sh create calls, got 0`. THEN implement the graduate-parking edits VERBATIM from the source plan lines 493-500 (dry-run printf change on line 74, and the real-branch tracker.sh create + Graduated line replacing the gh call and URL parse). HOW TO RUN: from the worktree root, `bash tests/gates/loop-brainstorm.sh` must exit 0 and print `PASS: loop-brainstorm E absorbed, Reading-the-user intact, graduation previews + dry-runs 2 items with template`. Do NOT rely on committing; leave changes in the working tree. If ambiguous, take the conservative reading and note it. Output contract: scripts/graduate-parking.sh and tests/gates/loop-brainstorm.sh edited as specified.",
      "expect_files": ["/Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave2-task4.patch"],
      "check": "bash tests/gates/loop-brainstorm.sh || { echo 'FAIL: tests/gates/loop-brainstorm.sh did not pass (see FAIL line above)'; exit 1; }; mkdir -p /Users/jjrdar/create/loops/loop-stack-session/.loop-patches; git add -A; git diff --cached > /Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave2-task4.patch; test -s /Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave2-task4.patch || { echo 'FAIL: empty patch - worker exported no changes'; exit 1; }; echo 'OK: Task 4 acceptance passed; patch exported to .loop-patches/wave2-task4.patch'",
      "verified": "loop-brainstorm.sh passes with the seam-based dry-run assertion (2 tracker.sh create calls, label/body preserved); a non-empty patch is exported outside the worktree."
    },
    {
      "key": "task6-migrate-tracker",
      "task_type": "code-feature",
      "engine": "claude-zai",
      "model": "glm-5.2",
      "timeout_s": 1800,
      "spec": "You are the implementer for unit Task 6 (migrate-tracker.sh - lossless local-to-github migration). Your current working directory IS an isolated git worktree of the loop-stack-session repo (it already contains scripts/tracker.sh) - edit files here directly. NEVER touch any file outside your ownership, never touch main, never push. You OWN exactly two files: scripts/migrate-tracker.sh (create, executable) and tests/repo-state/migrate.sh (create). Scope: implement a migrate-tracker.sh that recreates every local docs/issues/*.md file as a GitHub issue (ensuring labels first, preserving title/body/labels, re-closing locally-closed issues, resume-safe via a `migrated:` frontmatter stamp), with MIGRATE_DRY_RUN=1 printing the gh commands without executing and without flipping the key, and a gh-auth fail-fast on real runs only. IMPORTANT: this run executes ONLY the dry-run and a stubbed-gh resume path (the test provides both); no real GitHub issue is created during the run. Work test-first: FIRST write the failing test VERBATIM from the source plan at /Users/jjrdar/create/loops/loop-stack-session/docs/plans/2026-08-04-tracker-mode-plan.md lines 719-812 into tests/repo-state/migrate.sh; run it and confirm it FAILs with `scripts/migrate-tracker.sh missing or not executable`. THEN implement scripts/migrate-tracker.sh: the load-bearing loop (dry-run output shape, label pre-ensure, resume skip, stamp_migrated, body_of) is VERBATIM in the source plan lines 815-870 - reproduce it exactly and wrap in `set -uo pipefail` / `fail()`. `chmod +x scripts/migrate-tracker.sh`. HOW TO RUN: from the worktree root, `bash tests/repo-state/migrate.sh` must exit 0 and print `PASS: migrate-tracker dry-run emits one create per local issue with title/labels preserved, closes closed ones; resume skips stamped files`. Do NOT rely on committing; leave changes in the working tree. If ambiguous, take the conservative reading that satisfies the verbatim blocks and note it. Output contract: scripts/migrate-tracker.sh (executable) and tests/repo-state/migrate.sh.",
      "expect_files": ["/Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave2-task6.patch"],
      "check": "test -x scripts/migrate-tracker.sh || { echo 'FAIL: scripts/migrate-tracker.sh missing or not executable'; exit 1; }; bash tests/repo-state/migrate.sh || { echo 'FAIL: tests/repo-state/migrate.sh did not pass (see FAIL line above)'; exit 1; }; mkdir -p /Users/jjrdar/create/loops/loop-stack-session/.loop-patches; git add -A; git diff --cached > /Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave2-task6.patch; test -s /Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave2-task6.patch || { echo 'FAIL: empty patch - worker exported no changes'; exit 1; }; echo 'OK: Task 6 acceptance passed; patch exported to .loop-patches/wave2-task6.patch'",
      "verified": "scripts/migrate-tracker.sh is executable and migrate.sh passes (dry-run emits one create per local issue with title/labels preserved and closes closed ones; the stubbed-gh resume leg skips stamped files and stamps new ones); a non-empty patch is exported outside the worktree."
    }
  ]
}
```

### Wave 3 manifest (`.loop-work/wave3.json`)

Runs from the integration branch after the wave-2 gate, so each worktree already contains `scripts/tracker.sh`, the seam-sourcing `scripts/gen-mirrors.sh`, and `tests/repo-state/fixtures/issues.json`.

```json
{
  "run_name": "tracker-mode",
  "workdir": "/tmp/tracker-mode",
  "worktrees": true,
  "repo": "/Users/jjrdar/create/loops/loop-stack-session",
  "max_parallel": 1,
  "tasks": [
    {
      "key": "task5-setup-declares-mode",
      "task_type": "code-feature",
      "engine": "claude-zai",
      "model": "glm-5.2",
      "timeout_s": 1800,
      "spec": "You are the implementer for unit Task 5 (setup.sh declares the tracker mode, never detects it). Your current working directory IS an isolated git worktree of the loop-stack-session repo (it already contains scripts/tracker.sh and the seam-sourcing scripts/gen-mirrors.sh) - edit files here directly. NEVER touch any file outside your ownership, never touch main, never push. You OWN exactly three files: skills/loop-setup/setup.sh, skills/loop-setup/SKILL.md, tests/loop-setup/acceptance.sh. Scope: make setup ask the tracker mode once when the key is missing, report remote status to STDOUT, suggest `tracker: github` only when a remote exists, write the key via `tracker.sh mode set`, never re-ask, install scripts/tracker.sh alongside gen-mirrors, and run the mode-appropriate finalize (github: gh-auth fail-fast, idea label, mirrors; local: docs/issues, mirrors, zero gh). Work test-first: FIRST rewrite tests/loop-setup/acceptance.sh VERBATIM from the source plan at /Users/jjrdar/create/loops/loop-stack-session/docs/plans/2026-08-04-tracker-mode-plan.md lines 536-623 (this one file carries criteria 1,2,3,5); run it and confirm it FAILs at the structural `tracker` grep or the first `tracker: local` assertion. THEN implement per the Behavior contract and the VERBATIM snippets in the source plan lines 625-689 (the tracker.sh install block lines 627-633; the report_remote/determine_mode/declared-mode flow and finalize lines 638-687; and the SKILL.md rewrite instructions). Keep the existing pwd -P resolution, the --dry-run-remote flag, and the LOOP_TRACKER_ANSWER hook. HOW TO RUN: from the worktree root, `bash tests/loop-setup/acceptance.sh` must exit 0 and print `PASS: loop-setup declared-mode - criteria 1 (both modes idempotent), 2 (legacy re-ask), 3 (fail-fast), 5 (disclosures)`. Do NOT rely on committing; leave changes in the working tree. If ambiguous, take the conservative reading that satisfies the verbatim blocks and note it. Output contract: skills/loop-setup/setup.sh, skills/loop-setup/SKILL.md, tests/loop-setup/acceptance.sh edited as specified.",
      "expect_files": ["/Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave3-task5.patch"],
      "check": "test -x skills/loop-setup/setup.sh || { echo 'FAIL: skills/loop-setup/setup.sh missing or not executable'; exit 1; }; bash tests/loop-setup/acceptance.sh || { echo 'FAIL: tests/loop-setup/acceptance.sh did not pass (see FAIL line above)'; exit 1; }; mkdir -p /Users/jjrdar/create/loops/loop-stack-session/.loop-patches; git add -A; git diff --cached > /Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave3-task5.patch; test -s /Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave3-task5.patch || { echo 'FAIL: empty patch - worker exported no changes'; exit 1; }; echo 'OK: Task 5 acceptance passed; patch exported to .loop-patches/wave3-task5.patch'",
      "verified": "acceptance.sh passes all four folded criteria (both modes render the tracker: key idempotently, legacy re-ask reports remote status on stdout and suggests github only when found, github+unauth gh fails fast naming the prerequisite, local config discloses both limitations); a non-empty patch is exported outside the worktree."
    }
  ]
}
```

### Wave 4 manifest (`.loop-work/wave4.json`)

Runs from the integration branch after the wave-3 gate, so each worktree already contains the assembled local lane (setup, tracker.sh, gen-mirrors, graduate-parking). This task adds no production code; it is the end-to-end integration gate.

```json
{
  "run_name": "tracker-mode",
  "workdir": "/tmp/tracker-mode",
  "worktrees": true,
  "repo": "/Users/jjrdar/create/loops/loop-stack-session",
  "max_parallel": 1,
  "tasks": [
    {
      "key": "task7-local-workflow-gate",
      "task_type": "code-feature",
      "engine": "claude-zai",
      "model": "glm-5.2",
      "timeout_s": 900,
      "spec": "You are the implementer for unit Task 7 (full local-mode workflow, gh absent - criterion 4). Your current working directory IS an isolated git worktree of the loop-stack-session repo, which already contains the assembled local lane (skills/loop-setup/setup.sh, scripts/tracker.sh, scripts/gen-mirrors.sh, scripts/graduate-parking.sh) - edit files here directly. NEVER touch any file outside your ownership, never touch main, never push. You OWN exactly one file: tests/repo-state/local-workflow.sh (create). This task adds NO production code; it proves the assembled local lane runs gh-free end to end. Work: write the integration test VERBATIM from the source plan at /Users/jjrdar/create/loops/loop-stack-session/docs/plans/2026-08-04-tracker-mode-plan.md lines 895-953 into tests/repo-state/local-workflow.sh. HOW TO RUN: from the worktree root, `bash tests/repo-state/local-workflow.sh` must exit 0 and print `PASS: full local-mode workflow (setup->create->mirrors->graduate) ran to exit 0 with zero gh calls and labels intact`. If it fails, the defect is in the task it exercises (Tasks 2-5); record the failure in your final summary as an open question rather than editing anything outside your ownership - do NOT patch other tasks' files. Do NOT rely on committing; leave changes in the working tree. Output contract: tests/repo-state/local-workflow.sh.",
      "expect_files": ["/Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave4-task7.patch"],
      "check": "bash tests/repo-state/local-workflow.sh || { echo 'FAIL: tests/repo-state/local-workflow.sh did not pass (see FAIL line above)'; exit 1; }; mkdir -p /Users/jjrdar/create/loops/loop-stack-session/.loop-patches; git add -A; git diff --cached > /Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave4-task7.patch; test -s /Users/jjrdar/create/loops/loop-stack-session/.loop-patches/wave4-task7.patch || { echo 'FAIL: empty patch - worker exported no changes'; exit 1; }; echo 'OK: Task 7 acceptance passed; patch exported to .loop-patches/wave4-task7.patch'",
      "verified": "local-workflow.sh passes: the assembled local lane (setup -> create -> mirrors -> graduate) runs to exit 0 with zero gh invocations and labels intact; a non-empty patch is exported outside the worktree."
    }
  ]
}
```

## 9. Kicking it off

The human says: "Run the tracker-mode loop, wave 1."
The orchestrator runs the pre-flight (Section 5), surfaces the untracked review doc for the dirty-tree decision, then launches wave 1's manifest with `./ringer.py lint .loop-work/wave1.json && ./ringer.py run .loop-work/wave1.json --identity drive-tracker-mode` from the ringer repo root.
Per-wave summaries land in `.loop-work/wave-<N>-summary.md`; the run-state is `.loop-work/run-state.json`.
Watch live: `tail -f /tmp/tracker-mode/logs/*` during a wave, and the run JSON in `~/.ringer/runs/` at each gate.
Watch points: the two-repo record (a ringer MODEL-NOTES commit owed only on a signal event), the patch-apply/commit step (stage owned paths only), and the wave-3/wave-4 integration-base checkout (worktrees must snapshot the prior wave's merged tree).
If interrupted, use the verbatim resume prompt in Section 7.
