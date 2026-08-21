# Multi-host Packaging - agent-orchestrated execution plan

## 1. What this file is

This is the orchestration plan derived from `2026-08-16-packaging-plan.md`, compiled at the drive-compile dispatch role pin.
One frontier-model orchestrator session drives it; workers never see this conversation.
The source plan `2026-08-16-packaging-plan.md` remains the manual fallback and stays ground truth for acceptance criteria, interfaces, and the verbatim content blocks.
Any spec edit made during the run is applied to the source plan (and to the affected manifest spec), not only here.

The source plan gives each check/test file's content verbatim (`tests/hardcodes/sweep.sh`, `tests/install/acceptance.sh`, `scripts/clean-room.sh`).
Under ringer workers those files are check-custody artifacts: the worker transcribes the verbatim file, and the manifest check byte-diffs the worker's copy against an orchestrator-held golden copy stored outside every worktree before it runs the acceptance.
A worker cannot weaken a check it must reproduce byte-for-byte, which is the tamper guard (METR found o3 reward-hacked past a loop's own criterion in 21 of 21 runs when it could edit it).
This custody model is noted once here and again in section 4; it is the compile's one structural addition to the source plan's "the worker creates the check file" step wording.

## 2. Routing table

Every implementer unit routes to the flat-rate `claude-zai` lane on `glm-5.2`.
This is the evidence-backed posterior pick, not the quota-lean tie-break firing on thin evidence (see footnotes); it also keeps Anthropic quota for orchestration and gates.
All four units take the ringer transport: none needs in-session tools or mid-flight continuation, and each has an executed acceptance check in the source plan.

| Unit          | W | type         | Model   | Transport | Engine     | Impl | Val        | Evidence         |
|---------------|---|--------------|---------|-----------|------------|------|------------|------------------|
| T1 param-home | 1 | code-feature | glm-5.2 | ringer    | claude-zai | med  | check      | posterior[^1]    |
| T2 install    | 2 | code-feature | glm-5.2 | ringer    | claude-zai | high | check+read | posterior[^2]    |
| T3 clean-room | 3 | code-feature | -       | gate      | -          | -    | check+read | pin:collapse[^3] |
| T4 readme     | 4 | docs         | glm-5.2 | ringer    | claude-zai | med  | check+read | posterior[^4]    |

`Val` legend: `check` = the executed manifest check (golden-diff custody + the source-plan acceptance) is the non-negotiable gate; `check+read` = the same, plus a full orchestrator diff-read of the applied patch at the wave gate because the unit carries a correctness contract or a weak-grep acceptance.
No separate review-model validator is spawned on any unit: the embedded acceptance scripts exercise the contracts exhaustively, so the "validators default medium" rule has nothing to attach to here; a `check+read` gate that raises a doubt the check cannot express escalates to a one-task ringer review manifest, not an automatic layer.

Integrity read of the posterior (applied per `config/routing/model-benchmarks.md`): `docs/AMENDMENTS-PENDING.md` does not exist in the ringer repo, so the prior-tier row's depression note for `glm-5.2` ("posterior depressed pending seven stm-nav amendments") is stale and cleared; the scoreboard posterior is trusted, corroborated by `docs/MODEL-NOTES.md`.

[^1]: T1 - `glm-5.2`/`claude-zai` is `proven` on code-feature (57 rows, 82% first-try, 88% pass) and MODEL-NOTES records 10/10 attempt-1 on loop-stack itself with the exact-ownership plus committed-verbatim pattern that is this unit's shape; the work is a `git mv`, verbatim config-surface files, two literal removals, and a one-line install.sh skip, all well-referenced and mechanical, so impl medium and the executed sweep-plus-suite is a sufficient gate.
[^2]: T2 - same posterior; impl high because the `#30` style guard (env > host.env > TTY > refuse), the sed render with metacharacter rejection, the floating-version doctor check, and never-clobber are numeric/contract-correctness at stake, so the gate also gets a full diff-read of the install.sh patch.
[^3]: T3 - collapsed into an orchestrator gate action at pin review: the sole deliverable IS the fully verbatim check file, so a dispatched worker would only transcribe bytes that must match a golden copy, adding no information; the orchestrator authors `scripts/clean-room.sh` verbatim from the source plan at the W3 gate, runs it for real (the executed proof of criteria 1-4), and commits on green; reversal is a scoped W3 re-run as a dispatched unit.
[^4]: T4 - `glm-5.2`/`claude-zai` is `proven` on docs (13 rows, 92% first-try, 100% pass) with loop-stack receipts showing house-style (no em-dash, one sentence per line, aligned tables) held under a grep gate; the acceptance is presence-greps over the worker-owned README, so the gate adds a full README diff-read to guard against a thin section that satisfies the greps without substance.

## 3. Orchestration shape and the three validation layers

One orchestrator session drives four strictly sequential single-unit waves.
The chain is linear by dependency, not by tidiness: T2 consumes T1's config surface, T3 clones a HEAD that must already hold T1-T2, and T4 documents the proven flow.
This is the source plan's recorded deviation from a wave-parallel shape (two parallel tasks would have to share `install.sh` or the config surface, which exclusive ownership forbids); it maps one-to-one onto four gated waves.

Three validation layers per implementer unit:

1. Implementer self-check - the worker runs its own acceptance command to green before returning.
2. Per-unit validator - the ringer `check`: it byte-diffs the worker's copy of the check file against the orchestrator's golden copy (custody), then executes the source-plan acceptance (exit 0 is the only PASS), then exports the patch.
3. Orchestrator gate - reads the ringer run JSON and raw logs, applies the reviewed patch to the integration branch, commits it, and reruns the full suite there; for `check+read` units it reads the whole applied patch, not a skim.

```
Orchestrator (driving session - gates, merges, commits to the integration branch, never implements)
  W1:[T1 config-surface] -> W2:[T2 install-render] -> W3:[T3 clean-room] -> W4:[T4 readme-multihost]
     each unit: ringer glm-5.2/claude-zai worker
                  -> golden-diff custody check + source-plan acceptance (the manifest check)
                  -> orchestrator gate: apply patch, full-suite green, COMMIT to integration branch
  the commit at each gate is what threads the sequence:
     W2's worktree branches from a HEAD holding T1; W3 clones a HEAD holding T1-T2
  Human checkpoints (never task steps): H2 host-2 rollout, H3 one real loop, H4 close backlog #16
```

## 4. Hazard mitigations

All units share one transport (ringer, worktrees mode), so the ringer footgun set is active and the Agent-tool set is not - except the dirty-tree preflight, which applies to any transport.

- **Check custody (compile addition to the source plan).** The source plan lists each check file among the task's created files. Here the worker still creates it (the verbatim content is embedded in the spec), but the orchestrator writes a golden copy of that verbatim file to `/tmp/packaging-loop/golden/<unit>.sh` BEFORE launch - a path no worker can write, outside every worktree. The manifest check byte-diffs the worktree copy against the golden and FAILs on any difference, then runs the acceptance. A worker that weakens its own success criterion fails the diff; the check command lives in the manifest (orchestrator-authored), never in the repo, so the worker cannot reach it. This is the one deliberate deviation from the source plan's "worker writes the check" wording.
- **T3 collapsed into an orchestrator gate action (taken at pin review, BATCH-journaled).** T3's sole deliverable IS its check (`scripts/clean-room.sh`, fully verbatim), so the orchestrator authors and runs it as the W3 gate action with no worker (as the control-plane plan did for its integration unit). The substantive install/suite/degraded proofs still execute for real; custody is trivially held because the orchestrator writes the file from the source plan's verbatim block itself. Reversal: a scoped W3 re-run as a dispatched ringer unit with golden-diff custody.
- **Sequential-wave commit threading.** Ringer worktrees detach at the repo's current HEAD, so each wave's output must be committed to the integration branch before the next wave launches. At each gate the orchestrator applies the exported patch, reviews it, runs the full suite, then commits with the source plan's exact plain message, then `git checkout integration/packaging-loop` so the branch tip (now holding this wave) is what the next wave's worktrees branch from. This is why T2 sees T1's config surface and T3's `git clone "$REPO"` of its worktree captures a HEAD holding T1-T2 (clone takes committed HEAD only; the worker's own uncommitted `clean-room.sh` is irrelevant to the proofs it runs).
- **Deliverables survive a passing worktree.** A passing ringer worktree is deleted with the worker's commits, so each manifest check exports the worker's edits with `git add -A && git diff --cached > /tmp/packaging-loop/patches/<unit>.patch`; the orchestrator applies and commits that patch after review. No unit produces a gitignored deliverable (verified: outputs are tracked source, tests, and markdown; `config/host.env` is created by `install.sh` at runtime inside throwaway HOMEs, never committed), so the `cp`-the-ignored-output mitigation is not needed.
- **Never commit `config/host.env` or secrets.** Carried into every spec from the source plan's Global constraints: the installer never writes secrets, `config/host.env` is gitignored by T1, and the z.ai token never enters git. The T1 acceptance asserts `git status` does not stage `config/host.env`.
- **Never-clobber a live config.** The T2 render preserves the installer's never-overwrite behavior on an existing `~/.config/ringer/config.toml`; the acceptance's SENTINEL case proves it. Carried into the T2 spec verbatim.
- **opencode stagger - N/A.** No unit runs on the `opencode` engine (all four are `claude-zai`), so the sqlite-lock stagger does not apply; `max_parallel: 1` on every wave (single-unit waves).
- **Dirty-tree preflight (STOP).** Worktrees branch from committed state only. `docs/reviews/2026-08-16-packaging-drive-batch-review.md` is this run's expected uncommitted batch journal and is NOT a blocker; any other uncommitted path stops and asks the human before wave 1.
- **bash 3.2 / macOS.** Every embedded check and every produced script must run under the macOS default bash 3.2; the source-plan scripts are already 3.2-safe (`set -uo pipefail`, `mktemp -d`, process substitution, no associative arrays), and the check runs them on the same shell.
- **Log separation.** Ringer writes per-task logs to `/tmp/packaging-loop/logs/`; the orchestrator keeps one run-state file and one per-wave summary under `logs/loop/`.

## 5. Pre-flight checklist

- [ ] Capability probe (recorded, not degraded mode): ringer present at `/Users/jjrdar/repos/ringer`; enabled engines `codex`, `claude` (haiku default), `claude-zai` (`glm-5.2`, flat-rate lane), `opencode` (`glm-5.2` via OpenRouter).
- [ ] Evidence caveat: `docs/AMENDMENTS-PENDING.md` is absent in the ringer repo, so the `glm-5.2` posteriors rest on `./ringer.py models` plus `docs/MODEL-NOTES.md`, both read this compile; the prior-tier depression note is stale.
- [ ] Repo clean except `docs/reviews/2026-08-16-packaging-drive-batch-review.md`; any other dirty path is a STOP.
- [ ] Integration branch `integration/packaging-loop` created off current `main` HEAD `87afdf6`; record `87afdf6` as `<pre-run-base>` for the final loop-review.
- [ ] Tracker run-ticket: if none exists for this run, create one via `scripts/tracker.sh create --label agent --title "packaging-loop run" --body "..."` and record its number as `<run-ticket>`; every claim and gate writes an `AGENT STATUS` receipt to it.
- [ ] Log dir `logs/loop/` created; run-state artifact `logs/loop/run-state.json` initialized.
- [ ] Golden dir `/tmp/packaging-loop/golden/` and patch dir `/tmp/packaging-loop/patches/` created.
- [ ] Ringer run identity: `run_name: packaging-loop` (the SAME across all four waves), `workdir: /tmp/packaging-loop`, `repo: /Users/jjrdar/create/loops/loop-stack-session`, `worktrees: true`, `max_parallel: 1`.
- [ ] Ringside on screen: `./ringer.py hud` from `/Users/jjrdar/repos/ringer` before the first run.

## 6. Wave-loop procedure and gates

Run ringer from `/Users/jjrdar/repos/ringer`; every manifest carries `run_name: packaging-loop`.

**Per wave:**

1. **Place the golden copy.** Write the wave's check file content verbatim from the source plan to `/tmp/packaging-loop/golden/<unit>.sh` (T1 `sweep.sh`, T2 `acceptance.sh`; T3 is an orchestrator gate action and T4 has no worker-created check file, so no golden for either). The golden lives outside every worktree; the worker never sees it.
2. **Launch.** Emit one manifest for the wave and run `./ringer.py lint <wave>.json && ./ringer.py run <wave>.json`. Ringer's single built-in retry IS the repair pass; do not add another.
3. **Gate (orchestrator).** Read the run JSON in `~/.ringer/runs/` (truth - a background shell exit status is not); read every retried or failed log in `/tmp/packaging-loop/logs/`; spot-check the passing artifact. On a FAIL, attribute before relaunching: re-run the check's steps against the worktree yourself - if the worker's output was correct and the CHECK was wrong (for example a golden-diff false positive from a whitespace transcription), fix the check, commit the audited work, and add a MODEL-NOTES line instead of burning a round. Apply the exported patch to `integration/packaging-loop` (staging only owned paths), audit the diff touches only the unit's owned files, and rerun `tests/run.sh` on the branch. For `check+read` units (T2, T3, T4) read the whole applied patch.
4. **Distill + receipt.** Turn any repeated failure into a fix in the source plan and this plan's templates before the next wave (P10). Add one dated line per (`glm-5.2`, `task_type`) for the wave to `/Users/jjrdar/repos/ringer/docs/MODEL-NOTES.md`, plus a separate line for any signal event (a check bug, a `spec-problem` verdict, an off-nominal result), supported only by validator verdicts and diffs. Commit the MODEL-NOTES receipt in the ringer repo before advancing - the run drives two repos and both are checkpointed.
5. **Commit + advance.** Commit the wave's reviewed patch to `integration/packaging-loop` with the source plan's exact plain message (no co-author line), `git checkout integration/packaging-loop`, write the wave summary to `logs/loop/wave-N-summary.md`, and write the `AGENT STATUS` gate receipt to the run-ticket. Advance only on a green integration branch.

Exact commit messages (plain, no co-author, from the source plan):

- T1: `param home: host.env template, config.toml template, hardcode sweep`
- T2: `install.sh: consume host.env, render config.toml, enforce style guard`
- T3: `clean-room harness: dotfile-free install, suite, style-guard, degraded probe`
- T4: `docs: multi-host section, parameter-home README updates`

**Wave map:** W1=T1, W2=T2, W3=T3, W4=T4 (each dispatched wave: one unit, `max_parallel: 1`).
**W3 exception (T3 collapsed):** no manifest and no golden; on the integration branch the orchestrator writes `scripts/clean-room.sh` verbatim from the source plan, `chmod +x` it, runs it (it must exit 0 and print the `CLEAN-ROOM PASS` line), then commits with T3's exact message on green. Steps 3-5 of the per-wave procedure apply unchanged (attribution on FAIL, distill, MODEL-NOTES receipt line for the gate if a signal event occurs, AGENT STATUS receipt, advance only on green).

**Slip rules and gate classes** (semantics live in loop-auto):

- A spec edit confined to one unit or criterion, leaving the produced contract unchanged, and touching 15 or fewer lines, auto-takes as `[gate:BATCH]` and is journaled to `docs/reviews/2026-08-16-packaging-drive-batch-review.md`.
- A larger edit, or one touching multiple units, a Global constraint, or a unit's produced contract, is a `[gate:STOP]`.
- A check FAIL whose verdict is `spec-problem` (the check is unsatisfiable under the spec's boundary) routes to the orchestrator to fix the spec artifact and relaunch that unit; a design issue is recorded for the downstream loop-review, never silently patched.

**Ask-the-human list (STOP):**

- Any dirty path at preflight other than the expected batch-review journal.
- Any request to exceed the effort cap (`high`); none is expected.
- Any spec edit past the BATCH threshold above.
- The three human checkpoints, which are never task steps and are the owner's to fire:
  - **H2 - Host-2 rollout (criterion 6).** On the WSL host the owner edits `config/host.env` so `LOOP_STACK_RINGER_ROOT` resolves there and sets `LOOP_STACK_SKILL_STYLE`, then runs `git pull && LOOP_STACK_SKILL_STYLE=<agents|claude> ./install.sh && tests/run.sh`; the WSL host runs live projects and is not an experiment surface, so the owner fires it. Stale-config recovery is in the source plan's H2 block.
  - **H3 - One real loop on host 2 (criterion 7, judgment).** Drive one real loop on the second host to a landed unit with tracker receipts; "a real loop on real work" is a judgment call, never a task acceptance.
  - **H4 - Close backlog #16 on ship (criterion 8).** Stage `scripts/tracker.sh close 16` with a note referencing the new Multi-host README section; `close` is human-only by the tracker's contract, so the owner fires it.
- **Merge gate:** nothing in `integration/packaging-loop` goes live until the owner fires the merge from the `main` checkout - not an orchestrator action.

**Final-wave advisory review:** after W4 is green and the run advances, run `/loop-review <pre-run-base>` (the recorded `87afdf6`) from `integration/packaging-loop`.
It is advisory and non-blocking - the per-unit checks already gated correctness.
Record its findings at the final human checkpoint; slip any Spec-axis finding to the downstream review under the same slip rule as a stopped unit's design issue.

## 7. Quota and resume

The orchestrator is the loop; if the session dies, the loop stops.
Design for interruption at any gate.

Durable state:

- Each ringer run commits nothing to the repo itself - the orchestrator applies patches - so git on `integration/packaging-loop` is the truth of what has landed.
- Run-state lives on the run-ticket, not only in a session-local file: on claiming a unit and at every wave gate the orchestrator writes `scripts/tracker.sh comment <run-ticket> "AGENT STATUS branch=integration/packaging-loop worktree=<path> verdict=<v> repairs=<n>"`. `logs/loop/run-state.json` is a session-local cache of the same, updated at each launch and gate.
- Half-done units are relaunched, never resumed: ringer workers are stateless and their worktrees die on pass.

Reconciliation procedure (trust git over any receipt):

1. Find the run-ticket via `scripts/tracker.sh next-eligible` (its stale-working sweep surfaces a dead session's ticket) or `scripts/tracker.sh claim <run-ticket> <session-id> --reclaim`; read its `AGENT STATUS` receipt.
2. Verify against git: `git -C /Users/jjrdar/create/loops/loop-stack-session log --oneline integration/packaging-loop`. A unit is done only if its reviewed patch is committed (matching its exact message above) AND `tests/run.sh` was green after it; anything less is relaunched from scratch.
3. Check the ringer repo for an uncommitted MODEL-NOTES receipt owed by the last gate: `git -C /Users/jjrdar/repos/ringer status --porcelain docs/MODEL-NOTES.md` - commit it if present.
4. Resume the wave loop (section 6) from the first wave not confirmed green.

Verbatim resume prompt:

> Resume the packaging loop from `docs/plans/2026-08-16-packaging-plan_loop.md`.
> Find the run-ticket via `scripts/tracker.sh next-eligible`, read its `AGENT STATUS` receipt, then read the real git state of `integration/packaging-loop` and the ringer repo's MODEL-NOTES.
> Trust git over the receipt.
> A unit counts as done only if its patch is committed with its exact message and `tests/run.sh` was green after it; relaunch any unit not confirmed done from scratch using its verbatim source-plan block.
> Commit any owed MODEL-NOTES receipt, then continue the wave loop (section 6) from the first wave not confirmed green.

## 8. Templates

Every unit's spec is self-contained (the worker sees no conversation and no source plan).
At launch the orchestrator pastes that task's full source-plan block - the Files (exclusive ownership) list, the Interfaces block, EVERY verbatim content block (including the verbatim check-file text the worker must transcribe), and the numbered Steps - into the `spec` string.
The golden copy of the check file is orchestrator-side only and is never mentioned in the spec.

### Spec scaffolding (every implementer unit)

```
You are the implementer for unit <UNIT>. Your current working directory IS a git worktree of the
loop-stack repo at /Users/jjrdar/create/loops/loop-stack-session - edit files here directly, every
repo path is relative to your cwd, never touch an absolute path into another checkout.

You OWN exactly these files (create or edit): <OWNERSHIP LIST from the source plan Files block>.
Do not create or edit anything outside that list; a diff touching an unowned path is a scope violation.

GLOBAL CONSTRAINTS (binding, from the source plan - you get no other context):
- No em-dash characters anywhere; plain "-" only. One full sentence per physical line in prose.
- Do not change skill content or loop behavior; touch only install machinery, config surface, tests, docs.
- Never commit config/host.env (it is gitignored) and never commit any secret; the installer writes no secrets.
- Preserve the installer's never-clobber behavior: an existing ~/.config/ringer/config.toml is kept, never overwritten.
- The installer stays $HOME-scoped and makes no network calls.
- Test/check code is verbatim - reproduce every provided file byte-for-byte; do not "improve" it.

<the task's full Interfaces block and every verbatim content block, pasted from the source plan>

HOW TO RUN (this is the exact acceptance; the check runs the same one):
  <the task's source-plan acceptance command>
It must exit 0.

If anything is ambiguous: take the most conservative reading, do the work, note the question in your
worker notes, and do not cross your ownership boundary to resolve it. Effort cap: high.

OUTPUT: leave your edits uncommitted in the worktree (the check exports them). Deliverable files:
<the exact owned files>.
```

### Ringer manifest task - T1 (worked example; T2, T3, T4 follow the same shape with their own block, ownership, check, and golden)

```json
{
  "run_name": "packaging-loop",
  "workdir": "/tmp/packaging-loop",
  "repo": "/Users/jjrdar/create/loops/loop-stack-session",
  "worktrees": true,
  "max_parallel": 1,
  "tasks": [
    {
      "key": "T1-config-surface",
      "task_type": "code-feature",
      "engine": "claude-zai",
      "model": "glm-5.2",
      "spec": "<spec scaffolding above, UNIT=T1, OWNERSHIP=config/host.env.template, config/ringer/config.toml(->.template), .gitignore, tests/loop-setup/gitlab-setup.sh, install.sh(one line), tests/hardcodes/sweep.sh; with Task 1's full Interfaces block, the verbatim host.env.template, the config.toml.template edits, the .gitignore/gitlab edits, the install.sh skip line, and the verbatim sweep.sh all pasted in>",
      "expect_files": ["config/host.env.template", "config/ringer/config.toml.template", "tests/hardcodes/sweep.sh"],
      "check": "set -e; GOLD=/tmp/packaging-loop/golden/sweep.sh; T=tests/hardcodes/sweep.sh; diff \"$GOLD\" \"$T\" || { echo 'FAIL: sweep.sh differs from golden verbatim (custody violation)'; exit 1; }; bash \"$T\" || { echo 'FAIL: hardcode sweep found literals outside the allowlist'; exit 1; }; test -f config/ringer/config.toml.template || { echo 'FAIL: config.toml.template missing'; exit 1; }; if test -f config/ringer/config.toml; then echo 'FAIL: config.toml not renamed'; exit 1; fi; test -f config/host.env.template || { echo 'FAIL: host.env.template missing'; exit 1; }; grep -q '__RINGER_ROOT__' config/ringer/config.toml.template || { echo 'FAIL: __RINGER_ROOT__ placeholder missing'; exit 1; }; grep -q '__RINGER_CONFIG_DIR__' config/ringer/config.toml.template || { echo 'FAIL: __RINGER_CONFIG_DIR__ placeholder missing'; exit 1; }; grep -qx 'config/host.env' .gitignore || { echo 'FAIL: config/host.env not gitignored'; exit 1; }; tests/run.sh || { echo 'FAIL: full suite not green'; exit 1; }; git add -A && git diff --cached > /tmp/packaging-loop/patches/T1.patch; echo OK",
      "verified": "sweep.sh matches the orchestrator golden byte-for-byte, the hardcode sweep passes, config.toml is renamed to a placeholdered template, host.env is gitignored, the full suite is green, and the diff is exported for the orchestrator to apply."
    }
  ]
}
```

The check prints WHY it fails at each stage, verifies substance by running the real sweep and full suite (never `true`/`exit 0`), is strict on substance while the embedded sweep is tolerant on format, and exports the patch because a passing worktree is deleted.
`max_attempts` stays at the default 2 (one try plus ringer's retry).

### Per-unit check bodies (each preceded by its golden-diff custody stage)

- **T2** golden `acceptance.sh`: `diff golden vs tests/install/acceptance.sh` (custody), then `bash tests/install/acceptance.sh` (the `#30` guard both directions, the render, never-clobber), then `tests/run.sh`, then export `T2.patch`. Ownership: `install.sh`, `tests/install/acceptance.sh`.
- **T3** (orchestrator gate action, no worker): write `scripts/clean-room.sh` verbatim from the source plan on the integration branch, `chmod +x`, then `bash scripts/clean-room.sh` (dotfile-free install, full suite, `#30` refusal, no-network degraded probe - it clones the checkout's HEAD, which holds T1-T2), commit on green. No patch export.
- **T4** no golden (no worker-created check file): `grep -q '## Multi-host' README.md` and the source-plan greps (`git (push/pull|pull)`, `host-local`, `config.toml.template`, `re-render`), then `tests/run.sh`, then export `T4.patch`. Ownership: `README.md` only. The gate adds a full README diff-read because the greps are presence-only.

### Gate review stance (the validator read at every gate)

The orchestrator is adversarial and evidence-first: judge the raw diff and the executed check output, ignore any worker narrative.
Verdict discipline: if the golden-diff differs, or the acceptance does not exit 0, or (T4) any grep fails, the unit fails - regardless of what the worker reported.
A `spec-problem` (the check is unsatisfiable under the spec's boundary) routes to the orchestrator to fix the spec artifact and relaunch, not to a repair loop.

## 9. Kicking it off

Human says: "Run the packaging loop, wave 1."
The orchestrator runs the pre-flight (section 5), writes T1's golden `sweep.sh`, then launches `./ringer.py lint w1.json && ./ringer.py run w1.json` from the ringer repo root.
Per-wave summaries land in `logs/loop/wave-N-summary.md`; the routing table is section 2 and the shape is section 3.
Watch live: `tail -f /tmp/packaging-loop/logs/*` during a wave, the run JSON in `~/.ringer/runs/`, `logs/loop/run-state.json` and the run-ticket's `AGENT STATUS` receipts at each gate, and Ringside at http://127.0.0.1:8700.
Watch points: the golden-diff custody stage on T1-T2, the commit-threading between waves (T2 must see T1, T3's clean-room must clone a HEAD holding T1-T2), the `check+read` gate diff-reads on T2/T4 and the T3 run output, and the three owner-fired human checkpoints (H2 host-2 rollout, H3 one real loop, H4 close #16) plus the merge gate.
If interrupted, use the resume prompt in section 7.
