---
name: frontier-sandwich
description: >
  Turn a project idea or large task into a model-routed kickoff plan (the "Frontier Sandwich"):
  a step-by-step .md plan where each step names the right model tier (Frontier/Fable for judgment,
  Strong/Opus/GLM for implementation, Fast/Sonnet for mechanical work), an effort level, and a
  ready-to-paste prompt. Use this skill whenever the user wants to kick off a new project, break a
  big task into prompts, plan multi-model or multi-session work, optimize token/usage spend across
  Fable/Opus/Sonnet, or mentions "Frontier Sandwich", model routing, or "which model should do this".
---

# Frontier Sandwich Planner

Turn a project or large task into a kickoff plan that routes each step to the cheapest model tier that can do it well, reserving the frontier tier for high-judgment work.

The output is a plan the user can follow across sessions: each step has a goal, a model tier, an effort level, a copy-paste prompt, and a verification check.
Simple plans live in a single file; complex ones split each step's prompt into its own numbered file, indexed by an Order table.

Read `references/fable-guidelines.md` before drafting the plan.
It contains the routing rules, effort-dial data, prompt patterns, and pitfalls this skill is built on.
If `references/model-benchmarks.md` exists, read it too: it's kept current by the `benchmark-refresh`
skill and gives evidence-based signal (all-rounder / specialist / generalist-mid / partial evidence)
for whichever models are actually on the leaderboard right now. If it's missing or looks stale for
this plan's purposes, suggest running `benchmark-refresh` before finalizing the Order table.

## Why this exists

Frontier models (Fable 5) cost roughly 2x the strong tier and are usage-capped.
Using them for mechanical edits wastes budget without improving results.
But strong-tier models produce meaningfully worse architecture, risk analysis, and reviews.
The fix is routing: sandwich cheap execution between frontier planning and frontier review.

## Model tiers

Always describe steps in tiers, with concrete examples, so the plan works in any harness (Claude Code, GLM, API):

| Tier | Examples | Use for |
|---|---|---|
| Frontier | Claude Fable 5 | Architecture, migration plans, complex debugging, ambiguity resolution, final review, ship/no-ship calls |
| Strong | Claude Opus 4.8, GLM 5.2 | Repo exploration, research, implementation of a written plan, solid general coding |
| Fast | Claude Sonnet 5, Haiku | Mechanical edits, boilerplate, renames, simple test updates, scan/extract subagents |

## Workflow

### 1. Interview first

Do not draft the plan from the initial description alone.
Interview the user in batches of 3-5 questions until you understand the project, then confirm before writing.
Cover, as relevant: goal and success criteria, users and the "why", existing code or greenfield, tech constraints, data, riskiest unknowns, timeline, and how the user wants to verify each phase.
Stop interviewing once new answers stop changing the plan.
If the user gave a detailed brief, keep the interview to one short batch of only the questions that would change the routing or the phases.

### 2. Decompose into phases

Map the work onto the sandwich.
Merge or drop phases when the project is small; only add granularity where a model switch or a verification gate earns its keep.
A typical shape:

1. **Explore / research** (Strong): map the repo or research the domain, produce a brief.
2. **Plan / architect** (Frontier, plan mode or read-only): consume the brief, produce the implementation plan with risks and verification steps.
3. **Execute** (Strong or Fast): implement the written plan, step by step.
4. **Review** (Frontier): review the diff against the plan; ship/no-ship recommendation.
5. **Ship** (Human): the user approves.

Not every project needs all five, and big projects may repeat the Execute+Review pair per milestone.
Fan-out execution phases (see step 6) additionally get per-unit validation on the Strong tier, so the final Frontier review reads verdicts and core-abstraction diffs, not every raw diff.
The invariant worth keeping: frontier judgment before and after cheap execution, never frontier keystrokes in the middle.

### 3. Write one prompt per step

Each step's prompt must be self-contained, because it will be pasted into a fresh session with a different model that has none of this conversation's context.
That means each prompt:

- States the role and the "why" (what the output feeds into, who it is for).
- Names its input artifact (e.g. "read `docs/plan/01-brief.md`") and its output artifact (a file path).
- For Frontier planning steps: asks for conclusions, key evidence, tradeoffs, risks, and next actions. Never ask for hidden chain-of-thought or "show your reasoning step by step"; on Fable this triggers safety fallbacks to a weaker model.
- For execution steps: instructs the model to follow the plan, not redesign it, and to ground progress claims in actual tool results (test output, diffs), not summaries.
- For review steps: asks for a ship/no-ship call with specific findings, not a rewrite.
- Gives execution steps a failure policy: what to do on spec ambiguity (record the question in the output artifact, take the most conservative reading, flag it), and a retry limit with an escalation target, so no session wrestles a broken step indefinitely and spec bugs route back to the plan instead of being guessed around.
- Ends execution prompts with a reporting contract: the output artifact records what was done, test results verbatim, deviations from the plan, and open questions. Deviations and open questions are what the Frontier review actually needs.

Handoffs between steps go through files (briefs, plans, diffs), not conversation memory.
A step's result exists only once it is committed or written to its artifact, never only in a session; this is what makes interruption (quota, crash) recoverable by re-running the unfinished step.

### 4. Check the project's supporting files

Before writing the plan, decide whether the project needs scaffolding the steps will depend on:

- **Project brief / resource directory:** if the user's inputs (specs, designs, sample data, credentials notes, prior research) have no home, create one (e.g. `project_brief/` or `docs/brief/`) with a `README.md` explaining what belongs there and a checklist of what is still missing.
  Gaps in the checklist often become the plan's Step 0 (a Strong-tier "close the brief gaps" step).
- **CLAUDE.md:** if the repo lacks one (or the plan introduces tooling it does not cover), add a step or produce it directly: lean, covering only package manager, how to run one test / full suite / lint / typecheck, and non-obvious traps.
  See the reference file for what belongs and what does not.

Skip both when they already exist or the task is small enough not to need them.
Record the decision either way in the plan's Overview (not just in conversation), so a reader of the plan file knows why there is or is not a Step 0.

### 5. Save the plan

**Simple plans** (roughly 5 steps or fewer): one file, `PLAN-<project-slug>.md`, in the project directory (or where the user asks).

**Complex plans**: a plan directory (e.g. `docs/plan/`) with an index file plus one numbered prompt file per step (`00_step0_brief_prep.md`, `01_fable_architecture.md`, ...), so each file can be handed whole to a fresh session.
Each prompt file carries its own step header (the Model/Goal/Input/Output/Verify block below) above the prompt.
For multi-milestone projects, spec the first milestone build-ready and only outline later ones; the Fable review of milestone N feeds the detailed spec of milestone N+1.

Both layouts share this structure (in one file, or split across index + prompt files):

```markdown
# <Project> - Frontier Sandwich Plan

## Overview
<2-4 sentences: goal, success criteria, key constraints from the interview. Note brief-directory and CLAUDE.md decisions here.
Also list the pre-flight facts the plan assumes, stated precisely enough to be falsified: repo and branch state, environment versions (Python/node/etc. and how they are pinned), absolute paths of inputs living outside the repo, and whether the repo is public-by-design, which decides what may never enter git history at all.>

## Order

| # | File | Model · Effort · Mode | What happens |
|---|---|---|---|
| 0 | `00_step0_brief_prep.md` | Opus 4.8 · high · normal | Close the `project_brief/` gaps. |
| 1 | `01_fable_architecture.md` | **Fable 5 · xhigh · /plan** | Design the system; spec Phase 1 build-ready. |
| ... | | | |

<Bold the Frontier rows so the expensive steps stand out at a glance.
In a single-file plan, rename the File column to "Step" and link to step anchors instead of files.
Use the same short mode notation everywhere (e.g. `/plan`, `normal`, `review`, `subagents`).
Number from 0 only when a Step 0 brief-prep step exists; otherwise start at 1.>

## Artifacts
<Table of handoff files each step reads/writes.>

## Step N: <name>
- **Model:** <tier> (e.g. Frontier - Fable 5) | **Effort:** <level; "harness default" is fine for Strong/Fast steps> | **Mode:** <same notation as the Order table>
- **Goal:** <one sentence>
- **Input:** <artifact or "user brief">
- **Output:** <artifact path>
- **Verify:** <objective check before moving on>

### Prompt
<fenced block with the full copy-paste prompt>
```

Effort levels matter most on Frontier steps; for Strong/Fast steps use the harness default (or `medium`/`high` if the harness has a dial).
For the human Ship step, write `Model: Human` with no effort, and replace the Prompt block with a short approval checklist.

### 6. Fan-out steps: plan them loop-ready

Some execution phases decompose into many similar units (work packages, per-module migrations, per-table pipelines).
Write these so they can be run either by a human pasting prompts sequentially or by a frontier session orchestrating parallel subagents; the companion `loop-drive` skill (formerly `frontier-loop`) converts a plan into that orchestration mechanically, and stalls on exactly the omissions below.
Loop-readiness costs little and pays even in manual runs:

- **Per-unit acceptance criteria and named tests.** A unit without verifiable criteria can only be validated by its author; criteria are what let a separate validator (agent or human skim) check the work.
- **Explicit dependency structure.** Declare depends-on per unit, or group units into waves; "do them in order" hides parallelism that is free to exploit.
- **Hard scope boundaries.** Each unit lists its files and forbids out-of-scope edits, so parallel units stay disjoint, diffs stay auditable, and a merge conflict means a scope violation rather than a judgment call.
- **Git strategy up front.** Branch naming, the base branch, who merges and when, and what "done" means in git. Sequential humans can improvise this; parallel agents cannot.
- **No shared append-only files.** One log/report file per unit in a directory, never one file every unit appends to; a gate or summary step combines them.
- **External inputs by absolute path.** Anything outside the repo (spreadsheets, reference repos, sample data) is named by full path, because isolated workspaces (worktrees) will not contain it.
- **Effort cap.** Cap fan-out units at `high`; per-unit cost multiplies by unit count, and anything above high should be a recorded exception, not a default.

## Effort levels

Recommend an effort level per Frontier step; this is often higher leverage than the model choice itself.
Defaults: `medium` for interactive help, `high` for serious engineering steps, `xhigh` only for architecture, migrations, deep debugging, and final reviews.
Benchmark data in the reference file shows Fable on low/medium beating Opus on max, so do not reflexively recommend xhigh.

## Notes on who runs this skill

This skill may itself be invoked from Fable, Opus, or GLM; it does not need to detect which.
Generating the plan is a judgment task, so if the user asks, suggest running the planning step (this skill) on the Frontier or Strong tier.
The plan's routing applies to the steps it produces, not to the session that produced it.
