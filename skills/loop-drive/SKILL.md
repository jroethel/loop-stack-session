---
name: loop-drive
description: Use when you have a multi-step plan, PRD, or hand-off run-book (steps or work packages, with or without copy-paste prompts) and want a single frontier-model session to orchestrate its execution instead of a human pasting prompts by hand (formerly named frontier-loop). Covers both Anthropic-only subagent swarms and mixed-provider ringer runs. Not for a one-off single-answer task.
---

# loop-drive: hand-off plan to orchestration plan

You are the compiler and driver that turns a plan written for a human operator (open a session, set the model, paste a prompt, review, repeat) into a plan one frontier-model session executes autonomously.
The input can be a full "Frontier Sandwich" run-book (a.k.a. Fable Sandwich), a step-by-step plan, or a flat PRD; you derive the wave structure the plan does not spell out.
You emit the orchestration plan and, once approved, drive it.

There are two execution substrates, chosen per wave:

- **Native (Anthropic-only)**: workers are Claude Code subagents launched in-session with the Agent tool; context-sharing and SendMessage are available. See `references/native-orchestration.md`.
- **Ringer (mixed-provider)**: workers are ringer manifest tasks on any engine (claude/haiku, claude-zai/GLM, opencode/OpenRouter); isolation and checks are ringer's. See `references/ringer-substrate.md`.

A full worked skeleton of the emitted plan is `references/example-output-plan.md`.
The principle IDs cited below (P2, P6, P7, P10, P13, P14) are defined in the loop-stack `principles.md`; short glosses are inline so this skill stands alone.

## Step 0 - Route and scope

Before compiling anything, decide whether this plan should be a loop at all, and at what size.

Run the loop-which verdict (the One-Minute Test router; or reference it if the user already has one):

- **CHAT** or **DON'T BOTHER**: stop. Say so plainly and name why (answer it in-session, or it is not worth automating). Do not emit a plan.
- **ONE AGENT** or **single-wave TEAM**: skip the wave machinery entirely. Emit one artifact directly:
  - native scope: one Agent-tool brief (the subagent prompt from Step 4), and name the exact launch.
  - mixed scope: one ringer manifest, and name the exact command: `./ringer.py lint <manifest> && ./ringer.py run <manifest>`.
- **Multi-wave dependent build**: proceed through Steps 1-6.

Apply the checkability gate here and keep applying it per unit (P6: a unit only belongs on a worker if its output can be checked more cheaply than it can be produced).
Units whose output cannot be cheaply checked never route to a worker; they stay in the orchestrator's own judgment lane (the session decides them directly, never dispatched).

Every Step 0 exit must name the concrete next command or launch, so the user never has to guess which skill or command comes next.

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

## Step 2 - Assign roles, models, and effort (substrate-aware)

The loop is a three-tier structure regardless of substrate:

| Tier | Who | Does |
|---|---|---|
| Orchestrator | the main session | The wave loop, gates, merges, spec edits, escalation. Never implements. Reads logs, verdicts, and core diffs only, to preserve context. |
| Validator | a fresh checker per unit (Opus subagent, or an executed check plus optional review task) | Adversarial re-check of the implementer's claim against actual artifacts. Never fixes. |
| Implementer | a worker per unit (subagent, or manifest task) | The unit's actual work, test-first against its criteria. |

Route each unit by substrate:

**Native (Anthropic-only):** keep the Sonnet-default / Opus-promotion ladder.
Promote an implementer to Opus only when the unit is architecture-defining (others plug into its interfaces), math- or reasoning-heavy, or a known risk concentration (touches live consumers, deletes legacy, is the integration point).
Expect a quarter to a third of units on Opus; if you flag more than half, your criteria are too loose.
Runtime escalation: a Sonnet implementer that fails validation twice retries once as Opus; an Opus implementer that fails twice stops and goes to the gate.

**Ringer (mixed-provider):** the model per unit comes from the scoreboard, not a ladder (P7: route by evidence, not vibes).
Run `./ringer.py models --task-type <type>` and read the posterior for that task_type; for a model with no local evidence yet, fall back to the benchmark file as the prior.
Record which evidence drove each row (a scoreboard posterior, or a benchmark prior, and which).

Both substrates: give every unit a `task_type` from ringer's canonical vocabulary (code-feature, code-fix, code-review, research, persona-review, site-build, image-gen, docs, probe, bakeoff, ...).
The task_type drives scoreboard routing and must be set even in native mode so the choice is legible.

Effort: cap everything at **high**; exceeding high requires an explicit orchestrator decision recorded in the run log.
Use medium for units that are thin, well-referenced, or mechanical; high where numeric correctness, quirk preservation, or contract design is at stake.
Validators default to medium, high only for gate-critical units.

Produce a per-unit table: unit, wave, substrate, engine/model (or subagent model), implementer effort, validator effort, task_type, and the evidence for the choice.
Every row needs the rationale; "seems hard" is not one.

## Step 3 - Neutralize the parallelism hazards (mark substrate coverage)

Which hazards you must mitigate depends on the substrate.

**Ringer mode:** worktree isolation, per-task directories, and log separation are handled for you by run-level `"worktrees": true`; do not re-specify them.
What you MUST carry into the plan are ringer's own footguns:

- **Deliverables die with a passing worktree.** A passing task's worktree is deleted. Land deliverables outside the task worktree, or have the check export them first (the patch-export pattern: `git add -A && git diff --cached > <path-outside-worktree>.patch`, applied on your branch after review).
- **Gitignored outputs vanish from patch exports.** `git add -A` cannot stage ignored paths (`dist/`, build dirs), so the check must `cp` those files to a path outside the worktree explicitly, and you verify the patch AND the copies.
- **Stagger opencode spawns.** Concurrent OpenCode workers contend on its shared sqlite state store (WAL); launch them with a small stagger rather than all at once, or cap parallelism, to avoid lock errors.

**Native mode:** keep the full hazard set:

- **Git**: parallel agents cannot share one checkout. Each implementer works in its own `git worktree` on its own branch; the orchestrator merges validated branches into a dedicated integration branch at each gate and reruns the full suite there; mainline is never touched.
- **Nested repos**: if the code lives in a repo nested inside the session's outer repo, built-in `isolation: worktree` snapshots the WRONG repo; the implementer must create the worktree itself with explicit `git -C <inner-repo> worktree add ...` commands you spell out.
- **Per-worktree environments**: in-project venvs do not travel; the template includes the install step (e.g. `poetry install`) inside the worktree.
- **Shared append-only files** (run logs, checklists): convert to one-file-per-unit (`<log>/unit-NN.md`); the orchestrator writes the combined summary at the gate. State this as an explicit, once-noted deviation from the source plan.
- **Dirty working tree**: worktrees branch from committed state only; pre-flight surfaces uncommitted changes to the human before wave 1.
- **Disjoint-files assumption**: within-wave units touch disjoint files by construction; a merge conflict at the gate is a scope violation, not something to quietly resolve.

## Step 4 - Convert the prompt templates (per substrate)

**Native mode:** rewrite each paste-block as a subagent prompt.

- Delete human mechanics ("open a fresh session", "/model", "paste below", "tell me in chat").
- Keep the reading list, scope boundary, rules of engagement, and test-first order verbatim in spirit; these are the plan's real content.
- Add the workspace rules from Step 3 (worktree creation command, install step, never touch main, never push).
- Change "ask me if ambiguous" to the autonomous form: record the question in the unit log, take the most conservative reading, flag it in structured output.
- End with a structured-output contract: `{unit, branch, commit, worktree_path, tests_passed, tests_failed, deviations, open_questions, deferred_items}`.

**Ringer mode:** emit a manifest task per unit instead of a prompt (spec-writing rules from the ringer skill):

- **Self-contained spec.** The worker gets no conversation; put everything it needs in the spec. No pointer specs ("do what the plan says").
- **Ownership list.** Name every file the worker may create or edit, especially in multi-worker runs over one repo.
- **Embedded how-to-run.** State exactly how to build/test so the worker and the check agree.
- **Output contract.** State the exact deliverable files (and set `expect_files`).
- **Check-writing rules (P14: checks are as important as specs).** The check prints WHY it fails (a silent exit 1 starves the retry prompt and the eval log). It verifies substance, not just presence. Be strict on substance, tolerant on format.

**Both modes:** the validator/review stance is adversarial and evidence-first (P2: worker self-reports are worthless).
Judge the raw evidence (the diff, the executed check output, the artifact), and ignore the implementer's own narrative of what it did.
Native validators also get: mandatory independent test rerun, criterion-by-criterion walk with evidence, scope-boundary diff audit, read-only, and a `{verdict: pass|fail|spec-problem, criteria: [...], notes}` contract (spec-problem routes spec bugs to the orchestrator instead of a futile fix loop).

## Step 5 - Write the wave loop and gates

The output plan's core procedure, per wave, depends on substrate for item 1 and shares the gate structure.

**1. Launch the wave.**

- Native: launch the wave's implementers as parallel background Agent calls. On each completion notification, launch that unit's validator. On a failed validation, one repair pass via SendMessage to the same implementer with the itemized verdict, then revalidate; a second failure stops that unit without blocking its siblings.
- Ringer: emit one manifest for the wave and run it (`./ringer.py lint <manifest> && ./ringer.py run <manifest>`), using the SAME `run_name` across all waves of the build. Ringer's built-in single retry IS the repair pass; you do not add one.

**2. Gate (orchestrator).**
Read all results and verdicts.
Ringer: consume the run JSON in `~/.ringer/runs/` and the raw worker logs in `<workdir>/logs/` per ringer's post-run ritual (read every retried/failed log, spot-check at least one passing artifact).
Native: skim diffs of Opus-tier units and test files of Sonnet-tier units.
Merge passing branches (or apply reviewed patches) into the integration branch; run the full suite there.
Resolve stopped units: a small spec issue means edit the spec artifact and relaunch that unit; a design issue is recorded for the plan's downstream review step under the source plan's slip rules.
Write the wave summary; prune worktrees (native) or let ringer's have been pruned (ringer).

**3. Distill before advancing (both modes, P10: distill or repeat forever).**
Turn any repeated failure pattern from this wave's verdicts into a fix in the spec artifact and the templates before the next wave, so the next wave does not re-earn the same failures.
When a run taught you something about a model, add a dated line to `docs/MODEL-NOTES.md` in the ringer repo (task type, what happened, what you would do differently) - only what the executed checks and raw logs support.

**4. Advance only on a green integration branch.**

Preserve the source plan's checkpoint culture: list exactly when the orchestrator stops and asks the human (P12: gates scale with risk, not size).
The minimum set: pre-flight dirty-tree decisions, any request to exceed the effort cap, spec edits larger than a clarification, and any outward-facing unit (touches live consumers, publishes, or deletes things the human owns).

Design for interruption: the orchestrator cannot see the user's remaining quota, so the loop must die safely at any moment.
Implementers commit their results and log before returning; the orchestrator maintains a run-state artifact updated at every launch and gate; the plan contains a verbatim resume prompt plus a reconciliation procedure that trusts git over the state file and relaunches (never resumes) half-done units.

## Step 6 - Emit the plan

Write `<source-plan-name>_loop.md` next to the source plan, containing, in order:

1. What this file is, that the source plan remains the manual fallback, and that the spec artifact stays ground truth.
2. **Substrate declaration and routing table**: which substrate each wave uses, and the per-unit routing table (unit, wave, substrate, engine/model or subagent model, implementer effort, validator effort, task_type, evidence for the choice).
3. The orchestration shape and the three validation layers (implementer self-check, per-unit validator, orchestrator gate).
4. The hazard mitigations from Step 3, each marked as a deviation from the source plan where it is one.
5. Pre-flight checklist (repo state, environment versions, integration branch creation, log directory; for ringer waves, the engines and `~/.config/ringer/` assumptions).
6. The wave-loop procedure and gate checklist from Step 5, including slip rules and the ask-the-human list.
7. A quota/resume section: durable-state rules, the reconciliation procedure, and the verbatim resume prompt.
8. The implementer/validator prompt templates (native) and/or the manifest task templates (ringer) from Step 4.
9. A one-paragraph "kicking it off" section: the sentence the human says to start, where the per-wave summaries appear, and a pointer to the resume prompt.

Follow the user's markdown rules (one sentence per line, no em dashes).
Do not start executing the loop; drafting the plan and executing it are separate approvals unless the user said otherwise.
