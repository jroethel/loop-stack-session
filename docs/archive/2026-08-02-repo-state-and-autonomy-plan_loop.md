# Orchestration plan: repo-state convention + autonomy knob

## 1. What this file is

This is the compiled loop plan for `docs/plans/2026-08-02-repo-state-and-autonomy-plan.md` (the source plan, commit 5bec1e4).
The source plan remains the manual fallback and the spec ground truth; every worker spec embeds its task section verbatim from it.
One frontier session (this one) orchestrates; ringer workers implement; the plan's embedded tests are the per-unit executed validators.

Route verdict (Step 0): multi-wave dependent build - 8 units, 3 waves, explicit depends-on, executed check per unit - AGENT TEAM shape.
Checkability gate: 7 of 8 units pass (check is one bash script, far cheaper than producing).
B5 fails the dispatch gate on purpose: it creates real gh issues and moves files to archive with human checkpoints mid-unit, so it runs in the orchestrator's own lane with Jeremy present, never on a worker.

Capability probe result (2026-08-02): ringer PRESENT.
Ringer repo root: `/Users/jjrdar/repos/ringer`.
Wired engines: codex, claude, claude-zai, opencode.
Scoreboard: `~/.ringer/runs.jsonl`, 37 rows, 0 skipped.
`docs/AMENDMENTS-PENDING.md` is empty; MODEL-NOTES read (glm spec-size ceiling, worktree-path lesson - both folded into the templates below).

## 2. Routing table

| Unit | Wave | task_type    | Model   | Transport    | Engine     | Impl. effort | Val. effort | Evidence |
|------|------|--------------|---------|--------------|------------|--------------|-------------|----------|
| B1   | 1    | code-feature | glm-5.2 | ringer       | claude-zai | medium       | check-only  | posterior|
| B2   | 1    | code-feature | glm-5.2 | ringer       | claude-zai | high         | check-only  | posterior|
| C1   | 1    | code-fix     | glm-5.2 | ringer       | claude-zai | medium       | check-only  | prior    |
| B3   | 2    | code-feature | glm-5.2 | ringer       | claude-zai | high         | check-only  | posterior|
| B4   | 2    | code-feature | glm-5.2 | ringer       | claude-zai | medium       | check-only  | posterior|
| C2   | 2    | code-feature | glm-5.2 | ringer       | claude-zai | high         | check-only  | posterior|
| C3   | 2    | code-feature | glm-5.2 | ringer       | claude-zai | medium       | check-only  | posterior|
| B5   | 3    | docs         | session | orchestrator | n/a        | n/a          | human+check | pin:outward |

Footnotes:

- `posterior`: glm-5.2 on code-feature is proven, 6 tasks 100% first-try (2026-07-20 through 2026-07-27); code-feature is NOT in the stm-nav-affected task_type set, so the posterior is trusted as-is.
- `prior` (C1): code-fix IS in the stm-nav-affected set, so its posterior is set aside per the #65 rule; the benchmark prior row (glm-5.2, Strong, "execution typing at zero Anthropic quota") covers it, and C1 is mechanical tag insertion with a machine-checked invariant - squarely inside that row's "best for".
- `pin:outward` (B5): outward-facing unit (real gh issues, archive moves) with mid-unit human checkpoints; stays in the orchestrator's judgment lane per P6/P12.
- Quota lean: everything routes to the flat-rate claude-zai lane, consistent with the managed-block preference; zero Anthropic worker quota is spent on this run.
- No taste-flagged units: every acceptance criterion is a bash exit code; no aesthetic judgment anywhere.
- Effort: high where the bash is failure-prone (B2 JSON parse + sort, B3 idempotent dual-branch setup, C2 scanner + freshness diff); medium for the thinner markdown-and-glue units.
- Val. effort is `check-only` because the source plan embeds a rubix-hardened test per task; ringer runs it as the check, and the gate adds an orchestrator diff skim (no separate validator model is spent).

## 3. Shape and validation layers

```
                     Fable session (orchestrator - gates, merges, B5, human checkpoints)
                                          |
        +----------------- wave 1 manifest (ringer, claude-zai) -----------------+
        |  B1 config+template      B2 mirror generator      C1 gate tags         |
        +------------------------------------------------------------------------+
                                          |  gate 1: apply patches -> integration branch -> full suite
        +----------------- wave 2 manifest (ringer, claude-zai) -----------------+
        |  B3 loop-setup    B4 handoff    C2 registry+check    C3 loop-auto      |
        +------------------------------------------------------------------------+
                                          |  gate 2: same ritual + ./install.sh doctor
                          wave 3: B5 in-session (Jeremy present)
                                          |  gate 3: live.sh + judgment checkpoints
                        advisory /loop-review <pre-run-base>
```

Three validation layers per unit:

1. Implementer self-check: the worker runs its task's test to green inside the worktree before finishing.
2. Executed check (the validator): ringer re-runs the same test as the task check; its output is the verdict, and the worker's narrative is ignored (P2).
3. Orchestrator gate: patches applied to the integration branch, the FULL suite re-run there, diffs skimmed - a unit test passing in isolation does not advance a red integration branch.

## 4. Hazard mitigations (deviations marked)

- **Patch-export (deviation from the source plan's per-task Step 5 commits).** Ringer deletes a passing worktree, so workers do NOT run their task's commit step; each check exports `git add -A && git diff --cached > /tmp/loop-patches/<unit>.patch` before exiting, and the orchestrator applies and commits at the gate using the source plan's exact commit messages. The plan's Step 5 lines are otherwise honored verbatim.
- **C1 baseline correctness.** `tags.sh` diffs against `TAGS_BASE_REF` (default HEAD); the worker's worktree HEAD is the pre-edit commit by construction, so the tags-only invariant checks against the right baseline with no override needed. At gate 1 the orchestrator re-runs it on the integration branch with `TAGS_BASE_REF=<pre-run-base>`.
- **B4 out-of-repo input.** The current `~/.claude/skills/handoff/SKILL.md` (16 lines) is embedded verbatim in B4's spec, so the worker never depends on a home-directory path existing.
- **Gitignored outputs.** None: workers create no gitignored files in the repo (`docs/chain-state.md` is only ever written inside test temp dirs), so patch exports lose nothing.
- **GLM footguns (MODEL-NOTES).** Specs stay far under the ~40k-token stall ceiling (largest here ~7k chars); every spec states "your cwd is the worktree; every repo path is relative to it" and gives an absolute path ONLY for the patch-export destination (the 2026-07-20 main-repo-edit lesson).
- **Shared files.** Within-wave ownership is disjoint by the source plan's construction (verified in its self-review); a merge conflict at a gate is a scope violation and stops the unit, never a quiet resolve.
- **Opencode stagger.** N/A - no opencode units.
- **Live gh.** Only B5 touches the network-facing gh state, and it is orchestrator-lane with checkpoints; workers touch no remote.

## 5. Pre-flight checklist

1. Tree state: `git status --porcelain` - the tree currently carries two untracked files (`docs/2026-07-20-mattpocock-comparison-dump.md`, `loop-skills-model-routing.xlsx`); surface to Jeremy: commit, stash, or accept-and-proceed (worktrees branch from commits, so untracked files are safe but stay out of the run).
2. Record `<pre-run-base>`: `git rev-parse HEAD` after any pre-flight commits (currently 5bec1e4).
3. Integration branch: `git checkout -b loop/repo-state-autonomy` (mainline is never touched mid-run).
4. Patch landing dir: `mkdir -p /tmp/loop-patches`.
5. Ringer assumptions: `~/.config/ringer/config.toml` has the claude-zai engine block (verified); `~/.config/ringer/zai-token` present; `cd ~/repos/ringer && ./ringer.py lint <manifest>` green before each wave.
6. Environment: `gh auth status` green (verified 2026-08-02); `bash`, `awk`, `sed`, `diff` are the only tool dependencies the tests assume.
7. Run-state artifact created: `docs/plans/repo-state-autonomy-loop-state.md` (untracked during the run; follows the `model-routing-loop-state.md` precedent).

## 6. Wave loop and gates

Per wave:

1. **Launch.** Write the wave manifest (template in section 8, one task per unit, specs embedding the task sections verbatim), then from `~/repos/ringer`: `./ringer.py lint <manifest> && ./ringer.py run <manifest>`, with `run_name: repo-state-autonomy` on every wave and `"worktrees": true`.
   Ringer's built-in single retry is the repair pass; no second retry layer is added.
2. **Gate.** Read the run JSON in `~/.ringer/runs/` (the JSON is truth; the shell exit status is transport).
   Read every retried or failed worker log in `<workdir>/logs/`; spot-check at least one passing artifact.
   On a FAIL, attribute before relaunching: re-run the check's steps by hand against the worktree evidence - a wrong CHECK gets fixed and the audited work committed, with a MODEL-NOTES annotation, instead of burning a worker round.
   Apply each unit's patch to `loop/repo-state-autonomy`, commit with the source plan's Step 5 message, then run the FULL suite accumulated so far (section "Post-build verification" of the source plan, restricted to tests that exist yet).
   Wave 2 additionally runs `./install.sh` end-to-end and confirms the two new doctor lines print without aborting.
3. **Distill.** Any repeated failure pattern becomes a spec/template fix before the next wave (P10).
   Scoreboard receipts are automatic (ringer feeds it); MODEL-NOTES gets a dated line only for signal events (a pin, a re-route, a check-bug attribution), committed in the ringer repo before the wave advances.
4. **Advance only on a green integration branch.**

Slip rules: a twice-failed unit with a small spec issue gets the spec edited (clarification-sized only) and one relaunch; a design issue stops the unit and is recorded for the final checkpoint.

**Ask-the-human list (P12), in full:**

- Pre-flight dirty-tree decision (checklist item 1).
- Any request to exceed the high effort cap.
- Any spec edit larger than a clarification.
- All of B5 (outward-facing): the graduation review (exact `gh issue create` commands shown before any run) and the archive offer (each candidate listed with its rule).
- Source-plan judgment checkpoints 3 and 4: the fresh-session three-questions read and the batch-review sufficiency read against C3's worked sample.
- The final commit/push offer (main is ahead of origin; push only on acceptance).

**Terminal advisory review.** After gate 3 advances, run `/loop-review <pre-run-base>` from the integration branch; findings are recorded at the final human checkpoint, advisory and non-blocking, with Spec-axis findings slipped per the slip rules.
Merge `loop/repo-state-autonomy` to main only at that final checkpoint, alongside the push offer.

## 7. Quota and resume

Durable-state rules: the orchestrator updates `docs/plans/repo-state-autonomy-loop-state.md` at every launch and every gate (wave, units launched, run JSON path, patches applied, commits made); workers are stateless beyond their exported patches.

Reconciliation on resume: trust git over the state file.
`git log --oneline <pre-run-base>..loop/repo-state-autonomy` names every landed unit; a unit with an exported patch in `/tmp/loop-patches/` but no commit is re-gated, not trusted; a unit with neither patch nor commit relaunches from scratch (never resumed half-done).
Check `~/repos/ringer` for an uncommitted MODEL-NOTES receipt owed by the last gate.

Verbatim resume prompt:

> Resume the loop in docs/plans/2026-08-02-repo-state-and-autonomy-plan_loop.md.
> Read docs/plans/repo-state-autonomy-loop-state.md, then reconcile against git: trust commits on loop/repo-state-autonomy over the state file, re-gate any exported-but-uncommitted patch in /tmp/loop-patches/, relaunch (never resume) any unit with neither, and check ~/repos/ringer for an uncommitted MODEL-NOTES receipt.
> Continue the wave loop from the first incomplete wave.

## 8. Manifest task template (ringer transport)

One manifest per wave, `run_name: repo-state-autonomy`, `"worktrees": true`, one task per unit.
Per task:

- `spec`: the following skeleton with the unit's full task section pasted verbatim from the source plan.

```
You are implementing one task from a committed implementation plan, inside a git worktree of the
loop-stack-session repo. Your cwd IS the worktree; every repo path below is relative to it. Do not
use absolute paths into any other checkout of this repo.

Rules of engagement:
- Test-first, exactly as the task's steps order it: write the embedded test verbatim, run it, see
  the expected FAIL, implement against the Interfaces contract, run to PASS.
- Do NOT run the task's commit step; the orchestrator commits at the gate.
- Touch only the files in the task's exclusive-ownership list.
- Global constraints (from the plan header): one sentence per line in markdown, plain dashes never
  the em dash, no section symbol, aligned table pipes <= 110 chars; bash uses set -uo pipefail with
  a fail() helper that prints WHY, exit 0 only on full pass; generated files carry a DO NOT EDIT
  disclosure; no new tool dependencies beyond bash/awk/sed/diff/gh.
- If anything is ambiguous, take the most conservative reading, record the question in a file
  NOTES-<unit>.md in the repo root, and proceed.

<task section pasted verbatim, including Interfaces, the embedded test code, and steps 1-4>
```

- `check`: runs the unit's test and exports the patch (prints why on failure, verifies substance per ringer's check rules - the embedded tests already fail loudly via fail()):

```
bash tests/<unit-test-path> && git add -A && git diff --cached > /tmp/loop-patches/<unit>.patch \
  && [ -s /tmp/loop-patches/<unit>.patch ]
```

- `expect_files`: the unit's created files (floor, not the check).
- B4's spec additionally embeds the current 16-line `~/.claude/skills/handoff/SKILL.md` verbatim as its source material.
- C2's spec includes the note that `tests/gates/tags.sh` (from C1, present in its base commit) must stay green after its install.sh edit.

Wave 3 (B5) has no manifest: the orchestrator executes the task section directly in this session, pausing at its two embedded human checkpoints.

## 9. Kicking it off

Say "launch" (or "launch wave 1") and the run starts: pre-flight first (expect the dirty-tree question), then the wave-1 manifest lints and runs.
Per-wave summaries land in this session and in `docs/plans/repo-state-autonomy-loop-state.md`; watch a live wave with `tail -f` on the workdir logs ringer prints at launch, and read gate verdicts from `~/.ringer/runs/`.
B5 will need you at the keyboard for the graduation and archive checkpoints; everything else runs unattended between gates.
If the session dies, the resume prompt is in section 7.
