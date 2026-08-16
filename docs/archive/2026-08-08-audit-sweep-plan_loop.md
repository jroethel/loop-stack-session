# Orchestration: audit-sweep single-unit run

This file is the orchestration plan compiled from `docs/plans/2026-08-08-audit-sweep-plan.md` under a ONE AGENT verdict.
The source plan remains the manual fallback and stays ground truth for every task's spec; this file only says how one worker executes it.
Pre-run base commit: `18b289a` (all findings and reversals measure from there).

## Routing (single unit, no table)

- Unit: execute the source plan end to end, tasks in dependency order 1, 3, 2, 4, 5, 6, 7.
- Wave: single.
- task_type: code-fix.
- Model: sonnet-5. Evidence: prior (`model-benchmarks.md`: default execution worker on the Agent-tool roster; Opus row warns against quota-thin routine execution; the code-fix scoreboard posterior covers only the ringer-only glm-5.2 lane, so no posterior applies to this roster).
- Transport: Agent tool. Pin reason: the deliverable is a seven-commit series the plan mandates per task, which ringer's patch-export flattens, and the repair pass rides SendMessage.
- Impl. effort: medium (mechanical, fully referenced - the plan embeds verbatim tests and exact line edits).
- Val. effort: high (single unit means the whole run is gate-critical); validator model per the native-validator role pin.

## Topology

```
orchestrator (this session)
 └─ wave 1
     ├─ implementer: sonnet-5, worktree /tmp/audit-sweep-wt, branch audit-sweep
     └─ validator:   opus (native-validator pin), read-only, after implementer returns
 └─ gate: merge audit-sweep -> integration branch -> full runner -> fast-forward main
 └─ receipts: MODEL-NOTES line in ~/repos/ringer/docs/MODEL-NOTES.md (committed there)
 └─ advisory: /loop-review 18b289a after advancement (non-blocking)
```

Three validation layers: the plan's own RED-then-GREEN checks per task (implementer self-check), the fresh validator's independent rerun and diff audit, and the orchestrator gate's merged-suite run.

## Hazard mitigations

- The implementer works in its own `git worktree` (`git worktree add /tmp/audit-sweep-wt -b audit-sweep`) branched from committed HEAD; it never touches main and never pushes.
- Mainline lands only at the orchestrator gate: merge the validated branch into `audit-sweep-integration`, rerun `bash tests/run.sh` there, then fast-forward main.
- `ISSUES.md`/`BACKLOG.md` are gitignored, so a fresh worktree lacks them; the implementer runs `scripts/gen-mirrors.sh .` once before the final full-suite run (this is the source plan's own fresh-clone instruction).
- Shared-file hazards do not apply: one worker, exclusive ownership of everything.
- Pre-flight tree state: tracked content is fully committed; the only untracked entry is `docs/briefs/.2026-08-08-audit-sweep-brief.md.swp`, an editor swap artifact that does not travel into a worktree and holds no committed work at risk (noted, not deleted - it is not ours).

## Pre-flight checklist

- [x] Tracked tree clean at `18b289a` (verified via `git status --porcelain`; only the untracked `.swp` noted above).
- [x] gh CLI authenticated on this host (verified during the audit phase).
- [x] Ringer present at `~/repos/ringer` (probe ran `./ringer.py models --task-type code-fix`); transport is Agent tool by pin, not degraded mode.
- [x] Worktree-able: repo is a normal single git repo, no nested-repo hazard.

## Gate procedure

1. Implementer returns its structured report; ignore the narrative, read the branch.
2. Launch the validator on the worktree; on a fail verdict, one repair pass via SendMessage to the implementer with the itemized verdict, then revalidate; a second failure stops the run and reports.
3. On pass: create `audit-sweep-integration` from main, merge `audit-sweep`, run `bash tests/run.sh`; green means fast-forward main and prune the worktree.
4. Receipt: append one dated line for (sonnet-5, code-fix) to `~/repos/ringer/docs/MODEL-NOTES.md`, plus a separate line only if a signal event occurred (pin, re-route, check-bug attribution); commit it in the ringer repo before closing the gate.
5. Advisory terminal review: `/loop-review 18b289a` from the advanced branch; findings are recorded at the final checkpoint and never block advancement.

Ask-the-human list (STOP class, even under auto): exceeding the high effort cap, any outward-facing action (push, publish, delete outside the repo), or a second validation failure.

## Quota and resume

Durable state: the worktree branch `audit-sweep` holds per-task commits, so a dead session loses at most the in-flight task; relaunch (never resume) a half-done task by resetting to the last green task commit.
Reconciliation trusts git over any narrative: `git -C /tmp/audit-sweep-wt log --oneline` says which tasks landed; a task is done only if its commit exists AND its acceptance command passes when rerun.
Also check `~/repos/ringer` for an uncommitted MODEL-NOTES receipt owed by a closed gate.

Resume prompt (verbatim):

```
Resume the audit-sweep run in ~/repos/loop-stack-session.
Read docs/plans/2026-08-08-audit-sweep-plan_loop.md, then reconcile: git -C /tmp/audit-sweep-wt log --oneline
against the source plan's task commits (recreate the worktree from branch audit-sweep if /tmp was cleared).
Rerun the acceptance command of the last claimed task; relaunch that task if it fails.
Continue the gate procedure from wherever git says the run actually is.
```

## Kicking it off

The orchestrator launches the implementer as one Agent call (prompt below), validates, gates, and reports; per-wave summary appears in the session and in the drive-phase batch review journal.
Watch points: the worktree branch `audit-sweep` (per-task commits appear as they land) and `docs/reviews/2026-08-08-audit-sweep-drive-batch-review.md`.

## Implementer prompt (sonnet-5, Agent tool)

The prompt hands the worker the source plan path, the worktree commands, the task order 1, 3, 2, 4, 5, 6, 7, the RED-then-GREEN discipline with the plan's exact commands and commit messages, the mirrors regeneration step before the final full run, the no-main no-push rule, the autonomous-ambiguity rule (record, take the conservative reading, flag), and the structured output contract `{unit, branch, commit, worktree_path, tests_passed, tests_failed, deviations, open_questions, deferred_items}`.

## Validator prompt (native-validator pin, read-only)

The validator gets the worktree path, branch, and source plan; independently reruns all seven acceptance commands and the full runner, walks the plan criterion by criterion with evidence, audits each commit's diff against its task's exclusive file list, and returns `{verdict: pass|fail|spec-problem, criteria: [...], notes}` under explicit verdict discipline: if ANY criterion fails, the overall verdict is fail.
