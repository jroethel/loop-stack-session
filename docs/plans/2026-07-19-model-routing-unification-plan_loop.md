# Orchestration plan: model routing unification loop

## 1. What this file is

This is the agent-orchestrated execution plan derived from `2026-07-19-model-routing-unification-plan.md`.
The source plan remains the manual fallback and stays ground truth for content contracts and acceptance checks; spec edits made during the run are applied to the source plan, not just here.
Note the recursion: this loop rewrites loop-drive itself; the loop runs under the CURRENT skill rules, and the rewritten rules take effect only for future runs.

## 2. Substrate declaration and routing table

All three waves run on the ringer substrate; no unit needs in-session context sharing or SendMessage continuation, and the standing default routes execution typing to the flat-rate `claude-zai` lane.

| Unit                  | Wave | Substrate | Engine/model         | Impl. effort | Val. effort         | task_type | Evidence for the choice                                                                                     |
|-----------------------|------|-----------|----------------------|--------------|---------------------|-----------|--------------------------------------------------------------------------------------------------------------|
| T1 SKILL.md rewrite   | 1    | ringer    | claude-zai / glm-5.2 | high         | check + HC1 human   | docs      | posterior: proven, 78% first-try (9 docs tasks); TASTE FLAG: architecture-defining prose, HC1 gates it; per-unit engine ask offered at launch |
| T3 benchmark file     | 1    | ringer    | claude-zai / glm-5.2 | medium       | check-only          | docs      | posterior: proven, 78% first-try on docs                                                                       |
| T6 PR-65 framing note | 1    | ringer    | claude-zai / glm-5.2 | medium       | check + gate place  | docs      | posterior: proven on docs; cross-repo placement stays with the orchestrator                                    |
| T2 references update  | 2    | ringer    | claude-zai / glm-5.2 | medium       | check-only          | docs      | posterior: proven on docs; consumes T1 vocabulary landed at gate 1                                             |
| T5 alignment touch-ups| 2    | ringer    | claude-zai / glm-5.2 | medium       | check-only          | docs      | posterior: proven on docs; two-line edits, mechanical                                                          |
| T4 install.sh changes | 3    | ringer    | claude-zai / glm-5.2 | medium       | static check + live install at gate (HC3) | code-fix | posterior: probation, 29% first-try (7 tasks) - DEPRESSED by the pending stm-nav amendments (check bugs, work audited correct); spec embeds verbatim code blocks, so residual risk is transcription, not design |

Effort cap: high; nothing exceeds it.
The T1 taste flag means the launch step asks once whether T1 stays on glm-5.2 (HC1 remains the quality gate either way) or pins `engine: claude, model: opus` for design-stronger prose.

## 3. Orchestration shape and validation layers

Three validation layers: implementer self-check, the manifest task's executed check (with patch export), and the orchestrator gate (patch review, apply, commit; plus the human checkpoints).

```
orchestrator (this session)
├── wave 1  ringer manifest: T1 (docs, taste-flagged), T3 (docs), T6 (docs)
│     gate 1: review patches -> apply to integration branch -> run T1/T3 acceptance batteries
│             -> HC1: human reviews T1 prose -> place + guard + commit T6 in ~/repos/ringer
├── wave 2  ringer manifest: T2 (docs), T5 (docs)
│     gate 2: review patches -> apply -> run acceptance batteries -> commit
├── wave 3  ringer manifest: T4 (code-fix, static check only)
│     gate 3: review patch -> apply -> HC3: confirm install run -> LIVE bash install.sh (the real acceptance)
└── final: HC2 fresh-session compile test -> merge integration branch -> done
```

## 4. Hazard mitigations (deviations from the source plan marked)

- Worktree deletion on pass: every task's check ends with the patch-export pattern (`git add -A && git diff --cached > $RINGER_EXPORT_DIR/<unit>.patch`); the orchestrator applies reviewed patches on the integration branch at the gate. DEVIATION: the source plan's per-task `git commit` steps are performed by the orchestrator at gates, not by workers (worker commits die with the worktree).
- T4 live-install hazard: running install.sh inside a worktree would symlink the live `~/.claude/skills/` into a doomed worktree path. DEVIATION: T4's worker check is static (`bash -n` plus content greps); the source plan's full acceptance check (live `LOOP_STACK_SKILL_STYLE=agents bash install.sh`) runs at gate 3 from the real repo after HC3.
- T6 cross-repo write: the worker never touches `~/repos/ringer`; it writes `PR-65-FRAMING.md` at its worktree root and the check exports it. The orchestrator places it in `~/repos/ringer/docs/`, runs the porcelain + branch guard from the source plan, and commits. DEVIATION: placement and commit move from worker steps to gate steps.
- Wave-2-needs-wave-1 content: ringer worktrees snapshot the repo at launch, so gate 1 MUST apply and commit T1's patch on the integration branch before the wave 2 manifest runs.
- No opencode workers in this run, so no spawn stagger needed; `max_parallel: 3` covers wave 1.
- Disjoint ownership holds by construction (source plan Wave 1/2/3 file lists); a patch touching an unowned file is a scope violation surfaced at the gate, never quietly merged.

## 5. Pre-flight checklist

- [ ] `git -C ~/repos/loop-stack-session status --porcelain` reviewed; surface untracked strays (known: `session-skill-diffs.md`) to the human if anything else appears.
- [ ] Integration branch `integration/model-routing-unification` created from `main` and checked out (ringer snapshots the checked-out state).
- [ ] Engines present: `[engines.claude-zai]` in `~/.config/ringer/config.toml` (verified 2026-07-19); `~/repos/ringer/ringer.py` runnable.
- [ ] `~/repos/ringer` clean and on its default branch (T6 gate placement depends on it).
- [ ] Workdir `/tmp/model-routing-unification/` free; `run_name: model-routing-unification` for ALL waves.
- [ ] Run-state artifact `docs/plans/model-routing-loop-state.md` created.

## 6. Wave-loop procedure and gates

Per wave:

1. Emit the wave manifest from section 8, `cd ~/repos/ringer && ./ringer.py lint <manifest> && ./ringer.py run <manifest>`.
2. Gate: read the run JSON in `~/.ringer/runs/` (the JSON is truth; a background shell's exit status is transport); read every retried or failed worker log in `/tmp/model-routing-unification/logs/`; spot-check one passing artifact.
3. On any FAIL, attribute before relaunching: re-run the check's steps against the exported patch; if the work was correct and the check wrong, fix the check here and in the source plan, apply the audited work, and note it for MODEL-NOTES plus a pending amendment.
4. Apply reviewed patches to the integration branch; run the task's acceptance battery from the source plan there; commit with the source plan's commit message.
5. Wave-specific gate items: gate 1 runs HC1 (human reads the rewritten SKILL.md before wave 2) and the T6 placement guard + commit; gate 3 runs HC3 then the live install.sh as T4's real acceptance.
6. Distill: any repeated failure pattern becomes a spec fix before the next wave; model lessons go to `~/repos/ringer/docs/MODEL-NOTES.md`, dated, evidence-backed only.
7. Advance only on a green integration branch.

Ask-the-human list: dirty tree at pre-flight; HC1 (T1 prose); HC3 (install run); anything the T6 guard trips; any spec edit larger than a clarification; any request to exceed effort high.
Slip rule: a design issue found at a gate is recorded in the run-state artifact for the source plan's owner, not silently patched.

## 7. Quota and resume

Durable state: exported patches persist in `/tmp/model-routing-unification/` and applied work is committed per gate, so the loop dies safely at any point.
The run-state artifact records, per unit: launched / exported / applied / committed / gate-passed.
Reconciliation trusts git over the state file: any unit not confirmed applied-and-committed on the integration branch is relaunched, never resumed.
Resume prompt (verbatim):

> "Resume the model-routing unification loop from `docs/plans/2026-07-19-model-routing-unification-plan_loop.md`. Read `docs/plans/model-routing-loop-state.md` and the real git state of `integration/model-routing-unification`. Trust git over the state file. Relaunch any unit not confirmed applied and committed. Continue the wave loop from there, honoring HC1 and HC3."

## 8. Manifest templates

Shared run-level fields for every wave (only `tasks` differs):

```json
{
  "run_name": "model-routing-unification",
  "workdir": "/tmp/model-routing-unification",
  "repo": "/home/jjrdar/repos/loop-stack-session",
  "worktrees": true,
  "max_parallel": 3
}
```

Every spec carries the shared rules block (prepended verbatim to each spec below):

> Markdown rules: one full sentence per line; plain dashes, never the em dash character; aligned table pipes.
> The file `docs/plans/2026-07-19-model-routing-unification-plan.md` in this repo is the authoritative content contract for your unit; this spec restates your unit's contract - where wording differs, the plan file governs.
> You own ONLY the files named in your ownership list.
> Do not commit; your check exports a patch.

### Wave 1 tasks

- `task-1-skill-rewrite` - task_type `docs`, engine `claude-zai`, model `glm-5.2`.
  Spec: rewrite `skills/loop-drive/SKILL.md` per the plan's Task 1 content contract (frontmatter description swap; transport-framed intro; Step 0 capability probe block with ringer-repo-root resolution, single-artifact exits naming model/transport/evidence, shape-only closeness sentence; Step 2 unified chain block and transport rule VERBATIM from the plan, plus quota tie-break, taste flag, roster facts, table columns, transport-neutral re-route escalation; Step 3/4 per-transport headings; Step 5 concurrent launch wording, both-transports gate line, batched MUST MODEL-NOTES receipts block and two-repo resume sentence; Step 6 items 2 and 5; Step 7 dashboard line).
  Ownership: `skills/loop-drive/SKILL.md`.
  Check: the plan's Task 1 acceptance battery (the grep/awk block, verbatim), each failed assertion printing which phrase was missing, then patch export.
- `task-3-benchmark-file` - task_type `docs`, engine `claude-zai`, model `glm-5.2`.
  Spec: create `config/fable-sandwich/model-benchmarks.md` per the plan's Task 3 content contract (prior-semantics header; `Model | Tier | Best for | Avoid for | Prior source (dated) | Notes` table; the six required rows with the substance listed in the plan, including fable never-a-worker and the glm-5.2 pending-amendment note).
  Ownership: `config/fable-sandwich/model-benchmarks.md`.
  Check: the plan's Task 3 acceptance battery, verbose on failure, then patch export.
- `task-6-pr-framing` - task_type `docs`, engine `claude-zai`, model `glm-5.2`.
  Spec: write `PR-65-FRAMING.md` at the WORKTREE ROOT (the orchestrator relocates it; do not touch any path outside the worktree) per the plan's Task 6 content contract (what the file is; the integrity-layer reframing; the 7-of-8 stm-nav evidence with pointers to `AMENDMENT-ROWS.md` and `AMENDMENTS-PENDING.md`; Nate's appeals-process quote verbatim with attribution; the closing acceptance-test line).
  Ownership: `PR-65-FRAMING.md` (worktree root).
  Check: the plan's Task 6 content greps run against `PR-65-FRAMING.md`, verbose on failure, then `cp PR-65-FRAMING.md "$RINGER_EXPORT_DIR/"` (file export, not only a patch - the file's destination is another repo).

### Wave 2 tasks

- `task-2-references` - task_type `docs`, engine `claude-zai`, model `glm-5.2`.
  Spec: update the three files under `skills/loop-drive/references/` per the plan's Task 2 content contract (example plan: new column set, `pin:continuation` and `posterior` evidence cells with footnotes, "mixes transports" intro, transport labels, probe line in pre-flight; ringer-substrate: transport reframe, chain pointer with the untested/probation/proven ladder citing `model-benchmarks.md`, no chain paraphrase; native-orchestration: Agent-tool transport reframe plus the one chain-pointer sentence).
  Ownership: the three files under `skills/loop-drive/references/`.
  Check: the plan's Task 2 acceptance battery, verbose on failure, then patch export.
- `task-5-touchups` - task_type `docs`, engine `claude-zai`, model `glm-5.2`.
  Spec: apply the plan's Task 5 content contract - the one-sentence loop-which addition after its ground-truth-config paragraph, and the three replacement bullets in `claude-md/fable.md`'s Model routing section, both verbatim from the plan.
  Ownership: `skills/loop-which/SKILL.md`, `claude-md/fable.md`.
  Check: the plan's Task 5 acceptance battery, verbose on failure, then patch export.

### Wave 3 task

- `task-4-install-doctor` - task_type `code-fix`, engine `claude-zai`, model `glm-5.2`.
  Spec: apply the plan's Task 4 content contract to `install.sh` - insert section 2b and the four doctor checks as VERBATIM code blocks from the plan (the exact code is the decision; adjust only surrounding blank lines).
  Ownership: `install.sh`.
  Check: `bash -n install.sh` plus greps for the section-2b symlink line and each doctor line, verbose on failure, then patch export.
  The live `LOOP_STACK_SKILL_STYLE=agents bash install.sh` acceptance runs at gate 3 ONLY, after HC3.

## 9. Kicking it off

Human says: "Run the model-routing loop, wave 1."
Per-wave summaries land in `docs/plans/model-routing-loop-state.md`; watch live with `tail -f /tmp/model-routing-unification/logs/*.log` during a wave and the run JSON in `~/.ringer/runs/` at gates.
The launch step first asks the T1 taste question (keep glm-5.2 or pin opus) and shows the Step 7 dashboard options once.
If interrupted, use the resume prompt in section 7.
