# Triage-Default Import Sweep - orchestration plan (_loop)

## 1. What this file is

This is the agent-orchestrated execution plan derived from `2026-08-10-triage-default-import-sweep-plan.md`.
The source plan remains the manual fallback: a human can still open sessions and paste its task blocks by hand.
The source plan stays ground truth for scope and acceptance criteria; any spec edit made during the run is applied there, not only here.
One frontier-model session drives this end to end; workers reach execution through the ringer transport.

## 2. Routing table

All three units ride ringer on the flat-rate `claude-zai` lane, keeping Anthropic quota for orchestration and gates.

| Unit         | Wave | task_type    | Model   | Transport | Engine     | Impl   | Val   | Evidence      |
|--------------|------|--------------|---------|-----------|------------|--------|-------|---------------|
| task1-setup  | 1    | code-feature | glm-5.2 | ringer    | claude-zai | high   | check | posterior[^1] |
| task2-triage | 2    | docs         | glm-5.2 | ringer    | claude-zai | medium | check | posterior[^2] |
| task3-skill  | 2    | docs         | glm-5.2 | ringer    | claude-zai | medium | check | posterior[^3] |

`Val = check` means the executed ringer `check` is the non-negotiable gate; there is no separate validator subagent.
For task2 and task3 the human prose review (Section 6) is the voice/accuracy gate the greps cannot express.

[^1]: task1-setup - glm-5.2 proven on code-feature (43 tasks, 81% first-try, 84% pass) on the claude-zai lane.
      MODEL-NOTES judgment: glm is reliable on "tightly-specced work" with "tight behavior contracts", and this task is verbatim-specced with the full 36-suite `tests/run.sh` as the executed gate.
      Flat-rate lane chosen per the quota preference; codex is the runtime-escalation target if the unit fails validation twice (pin, reason recorded).
[^2]: task2-triage - glm-5.2 proven on docs (8 tasks, 88% first-try, 100% pass) on the claude-zai lane.
      MODEL-NOTES judgment: "doc sections against a grep-able content contract remain a safe glm lane."
      Taste-flagged (prose voice); the human prose review is the voice gate, and the per-unit engine ask is offered at launch.
[^3]: task3-skill - same docs posterior and claude-zai lane as task2-triage; taste-flagged on the same terms.

## 3. Orchestration shape and validation layers

One orchestrator session drives two waves; wave 2 depends on wave 1's committed result.
Three validation layers: implementer self-check, the per-unit executed `check` (ringer's primary gate), and the orchestrator gate (patch review plus full-suite rerun on the integration branch).

```
orchestrator (this session)
├── wave 1
│   └── task1-setup   ringer / glm-5.2 (claude-zai)  ──> check: tests/run.sh green (36 suites, 0 failed)
│        gate: review + apply patch to integration branch, rerun full suite, commit, distill
└── wave 2  (both parallel; depend on wave-1 commit)
    ├── task2-triage  ringer / glm-5.2 (claude-zai)  ──> check: grep battery + import.sh
    └── task3-skill   ringer / glm-5.2 (claude-zai)  ──> check: grep battery + import.sh
         gate: review + apply both patches, rerun full suite, commit, distill
         then: human prose review of both docs, then field run of /loop-setup (human checkpoints)
         then: /loop-review <pre-run-base> (advisory, non-blocking)
```

Wave 2 worktrees branch off the integration-branch HEAD that already carries task1-setup, so `--list-candidates`, the widened gate, and the Task-1-modified `import.sh` are present when task2 and task3 run their checks.

## 4. Hazard mitigations

All units ride ringer, so run-level `"worktrees": true` handles isolation, per-task dirs, and log separation; only ringer's own footguns are carried here.

- Patch-export (deviation from the source plan, which assumed a persistent checkout and direct in-repo edits).
  Every unit edits tracked files, and a passing task's worktree is deleted with its commits.
  Each check therefore leaves changes uncommitted and exports them: `git add -A && git diff --cached > <workdir>/exports/<key>.patch`.
  The orchestrator reviews each patch and applies it on the integration branch, staging specific paths (never `git add -A` in the real checkout).
- Gitignored outputs: none - `setup.sh`, the two test scripts, and both `.md` docs are all tracked, so `git add -A` stages every deliverable and no separate `cp` is needed.
- Stagger opencode spawns: not applicable - the engine is `claude-zai`, not `opencode`, so there is no shared-sqlite WAL contention.
- Nested repos: not applicable - `loop-stack-session` is the outer git repo itself, so ringer worktrees the right repo.
- Disjoint files in wave 2: task2-triage owns `references/import-triage.md` and task3-skill owns `SKILL.md`; a merge conflict at the gate would be a scope violation, not something to quietly resolve.
- Cross-wave ordering: wave 2's dependency on wave 1 is satisfied only by committing task1-setup to the integration branch before wave 2's manifest runs (Section 6 gate).

## 5. Pre-flight checklist

- [ ] Capability probe: ringer present; engines `claude`, `claude-zai`, `opencode`, `codex` read from `[engines.*]` in `~/.config/ringer/config.toml` - not degraded mode.
- [ ] Ringer repo root recorded: `/Users/jjrdar/repos/ringer` (evidence source of record; gate receipts use this path).
- [ ] Repo clean; surface any dirty tree to the human before wave 1. `[gate:STOP]`
- [ ] Baseline captured: `tests/run.sh` = `ran 36 suites: 36 passed, 0 failed` (confirmed at compile time).
- [ ] Integration branch `integration/triage-default-import-loop` created off `main` HEAD and checked out; record that HEAD SHA as `<pre-run-base>` for the final loop-review.
- [ ] Ringer run: `run_name` = `triage-default-import-loop` (SAME across both waves); `workdir` = `/tmp/triage-default-import-loop`; `mkdir -p <workdir>/exports`.
- [ ] run-state artifact `docs/triage-loop-run-state.md` created; batch-review journal `docs/reviews/2026-08-10-triage-default-import-sweep-batch-review.md` opened when autonomy takes effect.

## 6. Wave-loop procedure and gates

Gate-class semantics (ASK, STOP, BATCH, DEFAULT) and the batch-review journal format live in the loop-auto skill; this plan tags each gate.

### Wave 1 - task1-setup

1. Launch: `cd /Users/jjrdar/repos/ringer && ./ringer.py lint <plan-dir>/wave1.json && ./ringer.py run <plan-dir>/wave1.json`.
   Ringer's built-in single retry IS the repair pass; do not add another.
2. Gate (orchestrator):
   - Read the run JSON in `~/.ringer/runs/` and the raw worker log in `/tmp/triage-default-import-loop/logs/`; the run JSON is truth, a background shell's exit status is not.
   - On FAIL, attribute before relaunching: re-run `tests/run.sh` against the worktree yourself; if the worker's output was correct and the CHECK was wrong, fix the check, commit the audited work, and annotate MODEL-NOTES instead of burning a round.
   - On PASS, review `<workdir>/exports/task1-setup.patch`, apply it on the integration branch staging only the three owned paths, and rerun `tests/run.sh` there; advance only on `0 failed`. `[gate:STOP]` if the suite is red.
   - Commit the applied patch on the integration branch; update run-state.
3. Distill (P10): turn any repeated failure into a spec/template fix before wave 2.
   Ringer runs feed the scoreboard automatically; add a MODEL-NOTES line in the ringer repo only on a signal event (a pin, a runtime re-route, a check-bug attribution, an off-nominal result), and commit that receipt before advancing.
4. Advance only on a green, committed integration branch.

### Wave 2 - task2-triage and task3-skill (parallel)

1. Launch one manifest for both units: `./ringer.py lint <plan-dir>/wave2.json && ./ringer.py run <plan-dir>/wave2.json` with the same `run_name`.
   Both worktrees branch off the integration-branch HEAD that now carries task1-setup.
2. Gate (orchestrator):
   - Read the run JSON and both worker logs; spot-check at least one passing artifact.
   - Review each patch, confirm task2 touched only `references/import-triage.md` and task3 touched only `SKILL.md` (a conflict is a scope violation), apply both on the integration branch staging specific paths, and rerun `tests/run.sh`; advance only on `0 failed`. `[gate:STOP]` if red.
   - Commit; update run-state.
3. Distill; commit any owed MODEL-NOTES receipt.
4. Human checkpoints (both ASK-class, both block): `[gate:ASK]`
   - User reviews the two rewritten prose docs (`references/import-triage.md` and `SKILL.md`) for voice, accuracy, and completeness before they are final.
   - Field run: the user runs `/loop-setup` on a real repo holding pre-existing work files and confirms the tracker contains zero already-done or noise issues filed (source-plan criterion 1, a live judgment, not an automated check).
5. Final-wave advisory review: from the integration branch run `/loop-review <pre-run-base>`, so the two-axis Spec and Standards report judges the whole-run diff. `[gate:BATCH]`
   It is advisory and non-blocking; record its findings at the human checkpoint above, and slip any Spec-axis finding to the plan's downstream review under the same slip rule as a stopped-unit design issue.

### Slip rules and the ask-the-human list

- Pre-flight dirty tree. `[gate:STOP]`
- Any request to exceed the effort cap (high). `[gate:STOP]`
- A spec edit confined to a single unit or criterion, leaving that unit's produced contract unchanged, touching 15 or fewer lines: auto-takes. `[gate:BATCH]`
- A larger edit, or one touching multiple units, a global constraint, or a unit's produced contract. `[gate:STOP]`
- Any outward-facing unit (touches live consumers, publishes, or deletes user-owned things): none of these three units qualify, but the rule stands. `[gate:STOP]`
- A design-issue stop is recorded for downstream review, never silently patched.
- Scope narrowing is ASK-class wherever it arises; never a BATCH lean or DEFAULT take.

## 7. Quota and resume

The orchestrator cannot see remaining quota, so the loop must die safely at any moment.
Ringer commits nothing itself, but its run JSON in `~/.ringer/runs/` and logs in `<workdir>/logs/` survive; the orchestrator commits each applied patch to the integration branch, so git is the durable record.
The run-state artifact `docs/triage-loop-run-state.md` is updated at every launch and gate.

Reconciliation trusts git over run-state.
A unit counts as done ONLY if its patch is applied and committed on `integration/triage-default-import-loop` and `tests/run.sh` is green there; any unit not confirmed applied-committed-tested is relaunched (never resumed) under the same `run_name`.
Also check the ringer repo (`/Users/jjrdar/repos/ringer`) for an uncommitted MODEL-NOTES receipt owed by the last gate and commit it if present (the run drives two repos; both are checkpointed).

Verbatim resume prompt:

> Resume the triage-default import sweep loop from `docs/plans/2026-08-10-triage-default-import-sweep-plan_loop.md`.
> Read `docs/triage-loop-run-state.md` and the real git state of the integration branch `integration/triage-default-import-loop`.
> Trust git over the state file: a unit is done only if its patch is committed there and `tests/run.sh` is green; relaunch (never resume) any unit not confirmed applied-committed-tested, reusing `run_name` `triage-default-import-loop`.
> Also check `/Users/jjrdar/repos/ringer` for an uncommitted MODEL-NOTES receipt owed by the last gate and commit it if present.
> Continue the wave loop: wave 1 = task1-setup, then wave 2 = task2-triage and task3-skill in parallel.

## 8. Templates (ringer manifests)

Both manifests share `run_name`, `workdir`, `worktrees`, and `repo`.
Each `spec` is a self-contained brief; it cites the matching task section of the source plan (present in every worktree at `docs/plans/2026-08-10-triage-default-import-sweep-plan.md`) as the location of the verbatim code blocks, which are source material, not a pointer spec.
Each `check` prints WHY it fails and exports a reviewable patch before the worktree is deleted.
Each `check` defines `WD=/tmp/triage-default-import-loop` itself, so the manifests run verbatim.
`expect_files` names the exported patch (the deliverable that survives the worktree), never in-worktree paths, which ringer's lint rejects under `worktrees: true`.

### wave1.json

```json
{
  "run_name": "triage-default-import-loop",
  "workdir": "/tmp/triage-default-import-loop",
  "worktrees": true,
  "repo": "/Users/jjrdar/create/loops/loop-stack-session",
  "max_parallel": 1,
  "tasks": [
    {
      "key": "task1-setup",
      "task_type": "code-feature",
      "engine": "claude-zai",
      "model": "glm-5.2",
      "spec": "You are a code implementer. Your cwd IS a git worktree of loop-stack-session; edit files here directly and do NOT git commit (the check exports your changes as a patch). You own ONLY these three files: skills/loop-setup/setup.sh, tests/loop-setup/import.sh, tests/loop-setup/idempotence.sh. Touch nothing else. Your detailed step spec is Task 1 (Steps 1-9) of docs/plans/2026-08-10-triage-default-import-sweep-plan.md, present in this worktree; use its VERBATIM code blocks as the exact strings to insert or replace, and honor its exact line references. Summary of the nine steps: (1) initialize LIST_ONLY=0 by DRY_REMOTE=0 and add a `--list-candidates) LIST_ONLY=1; shift ;;` case to the arg-parse while-loop, still honoring --scan. (2) Move is_excluded, is_candidate, and collect_candidates above the arg-parse loop with no behavior change. (3) Immediately after arg-parse, before any remote detection/mkdir/install/report, add an early exit: if LIST_ONLY is 1, run collect_candidates and exit 0, printing nothing else to stdout. (4) Widen the unattended gate so LOOP_ASSUME_YES without LOOP_IMPORT_REMOTE skips issue creation in ALL modes; keep the DRY_REMOTE skip inside the `MODE != local` wrapper and keep that wrapper ahead of the moved-out gate; keep the `import candidate:` line printing; generalize the note wording off the word remote but keep the literal substring `set LOOP_IMPORT_REMOTE=1`; add a one-line comment that the variable now gates unattended creation in all modes. (5) import.sh scenario A (line 71): add LOOP_IMPORT_REMOTE=1, replacing the line verbatim per the plan. (6) idempotence.sh lines 32, 93, 108: add LOOP_IMPORT_REMOTE=1, replacing each verbatim per the plan; no other line changes. (7) Add import.sh scenario C (--list-candidates) verbatim. (8) Add import.sh scenario D (unattended files nothing) verbatim. (9) Replace the final import.sh PASS line verbatim. HOW TO RUN: bash tests/run.sh (must end `ran N suites: N passed, 0 failed`). Output contract: the three owned files edited so the full suite passes; leave all changes uncommitted.",
      "expect_files": ["/tmp/triage-default-import-loop/exports/task1-setup.patch"],
      "check": "WD=/tmp/triage-default-import-loop; out=\"$(bash tests/run.sh 2>&1)\"; printf '%s\\n' \"$out\" | tail -3; printf '%s\\n' \"$out\" | grep -qE 'ran [0-9]+ suites: [0-9]+ passed, 0 failed' || { echo 'FAIL: tests/run.sh did not report 0 failed'; exit 1; }; mkdir -p $WD/exports && git add -A && git diff --cached > $WD/exports/task1-setup.patch; [ -s $WD/exports/task1-setup.patch ] || { echo 'FAIL: empty patch export - no changes staged'; exit 1; }; echo OK",
      "verified": "The full suite reports 0 failed with the three owned files edited, and the changes are exported to a non-empty patch outside the worktree before deletion."
    }
  ]
}
```

### wave2.json

```json
{
  "run_name": "triage-default-import-loop",
  "workdir": "/tmp/triage-default-import-loop",
  "worktrees": true,
  "repo": "/Users/jjrdar/create/loops/loop-stack-session",
  "max_parallel": 2,
  "tasks": [
    {
      "key": "task2-triage",
      "task_type": "docs",
      "engine": "claude-zai",
      "model": "glm-5.2",
      "spec": "You are a docs implementer. Your cwd IS a git worktree of loop-stack-session; edit files here directly and do NOT git commit. You own ONLY skills/loop-setup/references/import-triage.md (full rewrite). Touch nothing else. Your detailed spec is Task 2 of docs/plans/2026-08-10-triage-default-import-sweep-plan.md, present in this worktree; write the PROSE, do not restate its bullets. Promote this file from an exception reference to the DEFAULT import workflow, with these sections: intro framing (this IS the default, run after the mechanical config and mirror steps; verbatim one-file-one-issue import and skip remain fallbacks offered at the bash per-item prompt); the workflow steps as an ordered list in blast-radius order (scan via setup.sh --list-candidates honoring --scan; classify each discrete item as issue (no label) or backlog idea; verify outstanding vs already-built against codebase and git history, every dropped item carrying disclosed file:line or commit evidence; present ONE batch disclosure table then a per-candidate walkthrough; on approval file each outstanding item, archive each source doc, write the record doc, regenerate mirrors); the batch disclosure table shape (columns source-doc, item, classification, verdict-plus-evidence, proposed-action; raw table under 110 chars, long evidence outside the table); on-approval actions in order (scripts/tracker.sh create --label <label> --title <title> --body <body>; archive to docs/archive/ via git mv when tracked else mv; write the D1 record doc; scripts/gen-mirrors.sh .); the issue-body pointer-back footer (verbatim item prose, then a --- rule, then Source doc: <archived path>, Imported: <date>, Restart context: <one line>); the triage record doc D1 (docs/archive/YYYY-MM-DD-import-triage.md, one per candidate-bearing run, zero-candidate runs write none, agent-written never bash, a table with columns source-doc/item/classification/verdict/evidence/action plus the filed issue numbers, an evidence line on every dropped row); retained judgment rules (split, merge, leave-in-place, titling, labelling verbatim in intent; a doc of N discrete items yields N issues; idea is the one load-bearing label, no label for active work). HOUSE STYLE: plain dashes only never the em-dash character, one sentence per physical line, aligned pipe tables under 110 chars. HOW TO RUN / output contract: Task 2's grep battery must pass and bash tests/loop-setup/import.sh must exit 0. Leave changes uncommitted.",
      "expect_files": ["/tmp/triage-default-import-loop/exports/task2-triage.patch"],
      "check": "WD=/tmp/triage-default-import-loop; F=skills/loop-setup/references/import-triage.md; for p in '--list-candidates' 'scripts/tracker.sh create' 'scripts/gen-mirrors.sh' 'docs/archive/' 'import-triage.md' 'Source doc:' 'Imported:' 'Restart context:'; do grep -q -- \"$p\" \"$F\" || { echo \"FAIL: missing '$p' in $F\"; exit 1; }; done; for p in 'file:line' 'already-built' 'split' 'merge'; do grep -qi -- \"$p\" \"$F\" || { echo \"FAIL: missing (ci) '$p' in $F\"; exit 1; }; done; bash tests/loop-setup/import.sh >/dev/null 2>&1 || { echo 'FAIL: import.sh regressed'; exit 1; }; mkdir -p $WD/exports && git add -A && git diff --cached > $WD/exports/task2-triage.patch; [ -s $WD/exports/task2-triage.patch ] || { echo 'FAIL: empty patch export'; exit 1; }; echo OK",
      "verified": "import-triage.md documents the scan/classify/verify/file-archive-record workflow (every required token present), import.sh still passes, and the rewrite is exported to a non-empty patch."
    },
    {
      "key": "task3-skill",
      "task_type": "docs",
      "engine": "claude-zai",
      "model": "glm-5.2",
      "spec": "You are a docs implementer. Your cwd IS a git worktree of loop-stack-session; edit files here directly and do NOT git commit. You own ONLY skills/loop-setup/SKILL.md (the 'The import sweep' section and the 'Non-interactive hooks' section). Touch nothing else. Your detailed spec is Task 3 of docs/plans/2026-08-10-triage-default-import-sweep-plan.md, present in this worktree. Rewrite the import-sweep section to LEAD with the triage workflow as the recommended default: after the mechanical config and mirror steps the agent scans via setup.sh --list-candidates, classifies each discrete item (issue vs idea), verifies outstanding vs already-built with disclosed evidence, presents one batch disclosure table, offers a per-candidate walkthrough, and on approval files, archives, writes the record doc, and regenerates mirrors per references/import-triage.md; state that verbatim one-file-one-issue import and skip remain explicitly offered fallbacks and the bash per-item prompt is unchanged. Add a plain statement that loop-setup is attended-only and ignores the loop-auto autonomy knob, with no unattended triage mode. In Non-interactive hooks, update the LOOP_IMPORT_REMOTE description for the new semantics (required alongside LOOP_ASSUME_YES before an unattended run creates issues in ALL modes, local included; without it candidates are skipped with a note in every mode) and document --list-candidates (prints candidate paths one normalized path per line honoring --scan, exits 0, no side effects, serving as the triage scan entry point). HOUSE STYLE: plain dashes only never the em-dash character, one sentence per physical line, aligned tables under 110 chars. HOW TO RUN / output contract: Task 3's grep battery must pass and bash tests/loop-setup/import.sh must exit 0. Leave changes uncommitted.",
      "expect_files": ["/tmp/triage-default-import-loop/exports/task3-skill.patch"],
      "check": "WD=/tmp/triage-default-import-loop; F=skills/loop-setup/SKILL.md; for p in '--list-candidates' 'import-triage.md' 'LOOP_IMPORT_REMOTE'; do grep -q -- \"$p\" \"$F\" || { echo \"FAIL: missing '$p' in $F\"; exit 1; }; done; for p in 'attended-only' 'loop-auto' 'fallback'; do grep -qi -- \"$p\" \"$F\" || { echo \"FAIL: missing (ci) '$p' in $F\"; exit 1; }; done; bash tests/loop-setup/import.sh >/dev/null 2>&1 || { echo 'FAIL: import.sh regressed'; exit 1; }; mkdir -p $WD/exports && git add -A && git diff --cached > $WD/exports/task3-skill.patch; [ -s $WD/exports/task3-skill.patch ] || { echo 'FAIL: empty patch export'; exit 1; }; echo OK",
      "verified": "SKILL.md leads with the triage default, documents --list-candidates and the widened LOOP_IMPORT_REMOTE, states attended-only/ignores loop-auto, names the fallbacks, import.sh still passes, and the edit is exported to a non-empty patch."
    }
  ]
}
```

## 9. Kicking it off

Human says: "Run the triage-default import sweep loop, wave 1."
Per-wave summaries and decisions land in `docs/triage-loop-run-state.md` and the batch-review journal `docs/reviews/2026-08-10-triage-default-import-sweep-batch-review.md`.
Watch live: `tail -f /tmp/triage-default-import-loop/logs/*` during a wave, and the run JSON in `~/.ringer/runs/` at each gate.
Watch points from Step 7: confirm the patch exports are non-empty before applying, confirm wave 2 worktrees off the task1-committed HEAD, and keep task2/task3 file ownership disjoint.
If interrupted, use the resume prompt in Section 7.
Before launching, the driving session runs Step 7 once (dashboard / dry run / watch points) via AskUserQuestion. `[gate:DEFAULT]`
