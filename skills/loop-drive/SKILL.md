---
name: loop-drive
description: Use when you have a multi-step plan, PRD, or hand-off run-book (steps or work packages, with or without copy-paste prompts) and want a single frontier-model session to orchestrate its execution instead of a human pasting prompts by hand (formerly named frontier-loop). Covers ringer-transported and Agent-tool-transported workers, mixed freely within a wave. Not for a one-off single-answer task.
---

# loop-drive: hand-off plan to orchestration plan

You are the compiler and driver that turns a plan written for a human operator (open a session, set the model, paste a prompt, review, repeat) into a plan one frontier-model session executes autonomously.
The input can be a full "Frontier Sandwich" run-book (a.k.a. Fable Sandwich), a step-by-step plan, or a flat PRD; you derive the wave structure the plan does not spell out.
You emit the orchestration plan and, once approved, drive it.

Workers reach execution through two transports: ringer (manifest tasks; see `references/ringer-substrate.md`) and the Agent tool (in-session subagents; see `references/native-orchestration.md`).
Transport is a per-unit attribute derived in Step 2.

A full worked skeleton of the emitted plan is `references/example-output-plan.md`.
The principle IDs cited below (P2, P6, P7, P10, P12, P14) are defined in the loop-stack `principles.md`; short glosses are inline so this skill stands alone.

## Step 0 - Route and scope

Before compiling anything, decide whether this plan should be a loop at all, and at what size.

Run the loop-which verdict (the One-Minute Test router; or reference it if the user already has one):

- **CHAT** or **DON'T BOTHER**: stop. Say so plainly and name why (answer it in-session, or it is not worth automating). Do not emit a plan.
- **ONE AGENT** or **single-wave TEAM**: skip the wave machinery entirely. Apply the Step 2 chain to the single unit (no table), and emit one artifact directly, naming the unit's model, transport, and evidence tier alongside it:
  - Agent-tool transport: one Agent-tool brief (the subagent prompt from Step 4), and name the exact launch.
  - ringer transport: one ringer manifest, and name the exact command: `./ringer.py lint <manifest> && ./ringer.py run <manifest>`.
- **Multi-wave dependent build**: proceed through Steps 1-6; Step 7 fires at launch on every route.

**Capability probe.**
Probe capabilities before routing: read the `[engines.*]` blocks of `~/.config/ringer/config.toml`.
If ringer is present, its scoreboard is the evidence source of record; resolve and record the ringer repo root (the directory holding `ringer.py`, normally `~/repos/ringer`) here, once - Step 2's evidence chain and the gate receipts use that recorded root, never bare relative paths.
If ringer is absent on this machine, every unit takes the Agent tool as degraded-mode transport, and the emitted plan says so in its pre-flight.

Apply the checkability gate here and per unit (P6: a unit belongs on a worker only if its output can be checked more cheaply than produced); anything that fails it stays in the orchestrator's own judgment lane, never dispatched.

Every Step 0 exit must name the concrete next command or launch, so the user never has to guess which skill or command comes next.
Ship every run-something exit with a topology diagram: a fast text sketch (ASCII or fenced mermaid, never a rendered export) of orchestrator, waves, workers, and validators.
If two shapes are close (roughly 60/40 or tighter), diagram both, name your lean and why, and let the user pick.

## Step 1 - Extract the plan's skeleton

Read the source plan and everything it points to, and extract:

- **Units of work**: the steps or work packages, each with scope, acceptance criteria, and named tests if present.
- **Dependency structure**: use explicit waves/ordering if given; otherwise derive the wave graph yourself from the depends-on relations (a wave = all currently unblocked units). You own wave derivation even when the source is a flat PRD with no ordering at all.
- **Per-unit model hints**: what the human plan assigned (often "Opus for everything"); you re-derive these in Step 2, not copy them.
- **Prompt templates**: the paste-blocks; these become subagent prompts (native) or manifest specs (ringer).
- **Human checkpoints**: places the plan says the human reviews or approves; these survive conversion, they do not disappear.
- **Shared state**: log files every session appends to, branches, checklists; these are the parallelism hazards.
- **Failure policy**: retry limits and escalation targets.

If a unit has no acceptance criteria you can turn into an executed check, stop and say so; orchestration without verifiable gates is just faster drift.

## Step 2 - Assign roles, models, and effort (transport-aware)

The loop is a three-tier structure regardless of transport:

| Tier | Who | Does |
|---|---|---|
| Orchestrator | the main session | The wave loop, gates, merges, spec edits, escalation. Never implements. Reads logs, verdicts, and core diffs only, to preserve context. |
| Validator | a fresh checker per unit (Opus subagent, or an executed check plus optional review task) | Adversarial re-check of the implementer's claim against actual artifacts. Never fixes. |
| Implementer | a worker per unit (subagent, or manifest task) | The unit's actual work, test-first against its criteria. |

Model choice is one chain for every unit, regardless of transport (P7: route by evidence, not vibes).
If the Step 0 probe reported ringer absent, skip tier 1 entirely and route every unit by benchmark prior, else orchestrator pin, among the Agent-tool roster.
1. Integrity-gated scoreboard posterior: from the ringer repo root recorded by the Step 0 probe, run `./ringer.py models --task-type <type>`; before trusting a posterior, read `<ringer-repo>/docs/MODEL-NOTES.md` and `<ringer-repo>/docs/AMENDMENTS-PENDING.md` for the models under consideration; if the ringer repo is missing, treat the posterior as unverified and fall to the prior tier.
   Known pending state while ringer #65 is unpatched: the seven excluded stm-nav rows are all glm-5.2 on site-build, docs, code-fix, and code-review - for those task_types treat glm-5.2's raw posterior as depressed by up to seven misattributed fails and defer to its benchmark prior or a pin; once amend lands, read the Amended column instead.
2. Else benchmark prior: a model with no trusted local evidence routes by its row in `model-benchmarks.md` (the fable-sandwich reference file).
3. Else orchestrator pin: design, math- or reasoning-heavy, risk concentration, or taste - pin `engine` and `model` and record the reason.
A pin outranks the chain at any tier when its trigger holds; the reason is never "seems hard".
Evidence cells carry the short tag only (`posterior`, `prior`, `pin:<reason-word>`); longer rationale goes in a footnote beneath the table.

Transport is derived per unit, never chosen per wave: a unit that needs in-session tools or mid-flight continuation takes the Agent tool; if ringer is absent, every unit takes the Agent tool (degraded mode); otherwise the unit takes ringer.
Within a wave, all ringer-transport units pack into one manifest; Agent-tool units launch as parallel background calls; both meet at the same gate.

Roster: Agent-tool workers are sonnet, opus, haiku; Fable is orchestrator-tier only and is never a worker; GLM and codex run only via ringer.
Quota preference: execution typing leans to the flat-rate `claude-zai` lane when evidence ties or is thin; the preference lives in the managed CLAUDE.md block and is cited as a tie-break, not a tier.
Taste flag: units with aesthetic acceptance criteria get flagged in the routing table and offered the per-unit engine ask despite any default (stm-nav lesson, 2026-07-17: the site map rode the default unflagged).

Give every unit a `task_type` from ringer's canonical vocabulary (code-feature, code-fix, code-review, research, persona-review, site-build, image-gen, docs, probe, bakeoff, ...).
The task_type drives scoreboard routing and must be set even for Agent-tool units so the choice is legible.

Effort: cap everything at **high**; exceeding high requires an explicit orchestrator decision recorded in the run log.
Use medium for units that are thin, well-referenced, or mechanical; high where numeric correctness, quirk preservation, or contract design is at stake.
Validators default to medium, high only for gate-critical units.

Runtime escalation: a unit that fails validation twice is re-routed at the gate by the same chain, usually a pin to a stronger model with the reason recorded; it is not an automatic ladder.

Produce a per-unit table with columns Unit, Wave, task_type, Model, Transport, Engine, Impl. effort, Val. effort, Evidence.
Every row needs the rationale; "seems hard" is not one.

## Step 3 - Neutralize the parallelism hazards (mark transport coverage)

Which hazards you must mitigate depends on the unit's transport.
On a mixed wave, both hazard sets are active at once.

**Ringer-transport units:** worktree isolation, per-task directories, and log separation are handled for you by run-level `"worktrees": true`; do not re-specify them.
What you MUST carry into the plan are ringer's own footguns:

- **Deliverables die with a passing worktree** (it is deleted on pass). Land them outside the task worktree, or have the check export them first (the patch-export pattern: `git add -A && git diff --cached > <path-outside-worktree>.patch`, applied on your branch after review).
- **Gitignored outputs vanish from patch exports.** `git add -A` cannot stage ignored paths (`dist/`, build dirs), so the check must `cp` those files to a path outside the worktree explicitly, and you verify the patch AND the copies.
- **Stagger opencode spawns.** Concurrent OpenCode workers contend on its shared sqlite state store (WAL); launch them with a small stagger rather than all at once, or cap parallelism, to avoid lock errors.

**Agent-tool units:** keep the full hazard set:

- **Git**: parallel agents cannot share one checkout. Each implementer works in its own `git worktree` on its own branch; the orchestrator merges validated branches into a dedicated integration branch at each gate and reruns the full suite there; mainline is never touched.
- **Nested repos**: if the code lives in a repo nested inside the session's outer repo, built-in `isolation: worktree` snapshots the WRONG repo; the implementer must create the worktree itself with explicit `git -C <inner-repo> worktree add ...` commands you spell out.
- **Per-worktree environments**: in-project venvs do not travel; the template includes the install step (e.g. `poetry install`) inside the worktree.
- **Shared append-only files** (run logs, checklists): convert to one-file-per-unit (`<log>/unit-NN.md`); the orchestrator writes the combined summary at the gate. State this as an explicit, once-noted deviation from the source plan.
- **Dirty working tree**: worktrees branch from committed state only; pre-flight surfaces uncommitted changes to the human before wave 1.
- **Disjoint-files assumption**: within-wave units touch disjoint files by construction; a merge conflict at the gate is a scope violation, not something to quietly resolve.

## Step 4 - Convert the prompt templates (per transport)

**Agent-tool units:** rewrite each paste-block as a subagent prompt.

- Delete human mechanics ("open a fresh session", "/model", "paste below", "tell me in chat").
- Keep the reading list, scope boundary, rules of engagement, and test-first order verbatim in spirit; these are the plan's real content.
- Add the workspace rules from Step 3 (worktree creation command, install step, never touch main, never push).
- Change "ask me if ambiguous" to the autonomous form: record the question in the unit log, take the most conservative reading, flag it in structured output.
- End with a structured-output contract: `{unit, branch, commit, worktree_path, tests_passed, tests_failed, deviations, open_questions, deferred_items}`.

**Ringer-transport units:** emit a manifest task per unit instead of a prompt (spec-writing rules from the ringer skill):

- **Self-contained spec.** The worker gets no conversation; put everything it needs in the spec. No pointer specs ("do what the plan says").
- **Ownership list.** Name every file the worker may create or edit, especially in multi-worker runs over one repo.
- **Embedded how-to-run.** State exactly how to build/test so the worker and the check agree.
- **Output contract.** State the exact deliverable files (and set `expect_files`).
- **Check-writing rules (P14: checks are as important as specs).** The check prints WHY it fails (a silent exit 1 starves the retry prompt and the eval log). It verifies substance, not just presence. The FULL check-writing ruleset lives in the ringer skill's "Check-writing rules" section - read it before writing any check; do not work from this summary (it summarizes, ringer governs, and the stm-nav 2026-07-17 false FAILs all came from checks that would have passed this summary but broke ringer's rules: unsatisfiable under the spec's boundary, repo-wide negative greps, invariants missing their exceptions).

**Both transports:** the validator/review stance is adversarial and evidence-first (P2: worker self-reports are worthless).
Judge the raw evidence (the diff, the executed check output, the artifact), and ignore the implementer's own narrative of what it did.
Native validators also get: mandatory independent test rerun, criterion-by-criterion walk with evidence, scope-boundary diff audit, read-only, and a `{verdict: pass|fail|spec-problem, criteria: [...], notes}` contract (spec-problem routes spec bugs to the orchestrator instead of a futile fix loop).
Every validator prompt (both transports) states verdict discipline explicitly: if ANY criterion fails, the overall verdict is fail - without this line, first attempts write pass while their own notes contradict it (stm-nav lesson, 2026-07-17).

## Step 5 - Write the wave loop and gates

The output plan's core procedure, per wave, depends on transport for item 1 and shares the gate structure.

**1. Launch the wave.**

Launch the wave's packed manifest and its Agent-tool units concurrently.
Ringer-transport units: emit one manifest for the wave and run it (`./ringer.py lint <manifest> && ./ringer.py run <manifest>`), using the SAME `run_name` across all waves of the build; ringer's built-in single retry IS the repair pass for these units, you do not add one.
Agent-tool units: launch them as parallel background Agent calls at the same time; on each completion notification, launch that unit's validator; on a failed validation, one repair pass via SendMessage to the same implementer with the itemized verdict, then revalidate; a second failure stops that unit without blocking its siblings.

**2. Gate (orchestrator).**
Read all results and verdicts from both transports.
Ringer: consume the run JSON in `~/.ringer/runs/` and the raw worker logs in `<workdir>/logs/` per ringer's post-run ritual (read every retried/failed log, spot-check at least one passing artifact).
The run JSON is truth; a detached/background shell's exit status is transport and can report failure for a run that passed (stm-nav lesson).
On a FAIL, attribute before relaunching: re-run the check's steps yourself against the tree - if the worker's output was correct and the CHECK was wrong, fix the check, commit the audited work, and annotate the model log (MODEL-NOTES + amendment when available) instead of burning a round.
Native: skim diffs of Opus-tier units and test files of Sonnet-tier units.
Merge passing branches (or apply reviewed patches) into the integration branch; run the full suite there.
Resolve stopped units: a small spec issue means edit the spec artifact and relaunch that unit; a design issue is recorded for the plan's downstream review step under the source plan's slip rules.
Write the wave summary; prune native worktrees (ringer prunes its own).

**3. Distill before advancing (both transports, P10: distill or repeat forever).**
Turn any repeated failure pattern from this wave's verdicts into a fix in the spec artifact and the templates before the next wave, so the next wave does not re-earn the same failures.
Agent-tool units MUST leave dated MODEL-NOTES receipts at the gate - their only durable receipt, since only ringer runs feed the scoreboard.
Batch them: one dated line per (model, task_type) per wave in `<ringer-repo>/docs/MODEL-NOTES.md`, plus a separate line only for signal events (a pin, a runtime re-route, a check-bug attribution, an off-nominal result); support them only with validator verdicts and diffs, and read them back through the same integrity discipline as any posterior.
Committing the ringer-repo receipt is part of closing the gate: commit it before advancing the wave, so the git-is-truth reconciliation covers both repos.

**4. Advance only on a green integration branch.**

Preserve the source plan's checkpoint culture: list exactly when the orchestrator stops and asks the human (P12: gates scale with risk, not size).
The minimum set: pre-flight dirty-tree decisions, any request to exceed the effort cap, spec edits larger than a clarification, and any outward-facing unit (touches live consumers, publishes, or deletes things the human owns).

Design for interruption: the orchestrator cannot see the user's remaining quota, so the loop must die safely at any moment.
Implementers commit their results and log before returning; the orchestrator maintains a run-state artifact updated at every launch and gate; the plan contains a verbatim resume prompt plus a reconciliation procedure that trusts git over the state file and relaunches (never resumes) half-done units.
The reconciliation procedure also checks the ringer repo for an uncommitted MODEL-NOTES receipt owed by the last gate (the run drives two repos; both are checkpointed).

## Step 6 - Emit the plan

Write `<source-plan-name>_loop.md` next to the source plan, containing, in order:

1. What this file is, that the source plan remains the manual fallback, and that the spec artifact stays ground truth.
2. **Routing table**: the per-unit table with the columns Unit, Wave, task_type, Model, Transport, Engine, Impl. effort, Val. effort, Evidence.
3. The orchestration shape and the three validation layers (implementer self-check, per-unit validator, orchestrator gate), plus the topology diagram (updated from Step 0 if compilation changed the shape).
4. The hazard mitigations from Step 3, each marked as a deviation from the source plan where it is one.
5. Pre-flight checklist (repo state, environment versions, integration branch creation, log directory; for ringer waves, the engines and `~/.config/ringer/` assumptions; the capability-probe result - which engines were found, or degraded mode).
6. The wave-loop procedure and gate checklist from Step 5, including slip rules and the ask-the-human list.
7. A quota/resume section: durable-state rules, the reconciliation procedure, and the verbatim resume prompt.
8. The implementer/validator prompt templates (native) and/or the manifest task templates (ringer) from Step 4.
9. A one-paragraph "kicking it off" section: the sentence the human says to start, where the per-wave summaries appear, the watch points from Step 7, and a pointer to the resume prompt.

Follow the user's markdown rules (one sentence per line, no em dashes).
Do not start executing the loop; drafting the plan and executing it are separate approvals unless the user said otherwise.
When the user does approve execution, go through Step 7 before launching anything.

## Step 7 - Drive dashboard, then launch

When the user approves execution (including the single-artifact exits from Step 0), ask once via AskUserQuestion, multiSelect: "See execution details before I launch?"

- **Dashboard**: what will run - the routing table condensed (unit, wave, model, transport, effort) plus the topology diagram.
- **Dry run**: prove the "go" before firing it - execute the pre-flight checklist for real (ringer: `./ringer.py lint <manifest>`, engines present; native: clean tree, worktree-able state) and print the exact wave-1 launches (commands and Agent briefs) without starting any worker.
- **Watch points**: where to follow the run live - native: per-unit logs (`<log>/unit-NN.md`), the run-state artifact, background-task notifications; ringer: `tail -f <workdir>/logs/` during a wave, run JSON in `~/.ringer/runs/` at gates.

Show what they picked, fix anything the dry run flags, then launch; nothing selected means launch immediately.
Once per run, never per wave.
