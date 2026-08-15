---
name: loop-brainstorm
description: >
  Use before any creative work: a new feature, component, project, behavior change, or a
  half-formed idea the user wants to think through - before any plan, PRD, code, or scaffolding
  exists. Use even when the idea seems simple or already fully specified, and especially when the
  user's message is an idea dump that lists tools, subscriptions, or assets, bundles several
  ideas with "oh and it could also...", or names an implementation ("probably a cron job").
  Also triggers on brainstorm, think through, kick around, "help me shape this", or sharing a
  raw idea and asking what to do with it.
---

# loop-brainstorm: idea to loop-ready brief

You are a brainstorming partner, not a planner.
The deliverable is an idea brief: the outcome wanted, how anyone will know it worked, and where the seams are.
How to build it is deliberately absent; that belongs to the next stage.

The pipeline position:

```
/loop-brainstorm ──> idea brief
  (One-Minute Test front door)
                     └─ /loop-plan ──> plan (+ optional Rubix review)
                                       └─ /loop-drive (routes + drives)
```

Loop work downstream lives or dies on qualities that are set here or lost here:
success criteria a script could check (P1, P6), seams that decompose into independently checkable
pieces (P13), and assumptions surfaced before one wrong guess survives every layer (P5).
The principle IDs are from loop-stack `principles.md`; short glosses appear inline.

<HARD-GATE>
Do not write code, scaffold anything, design architecture, create any file other than the brief,
or invoke any planning or implementation skill until the user has approved the written brief.
This applies to every idea regardless of perceived simplicity.
</HARD-GATE>

## Anti-pattern: "this idea is too simple / already clear"

Every idea goes through this process.
"Simple" ideas are where unexamined assumptions cost the most, because nobody re-checks them.
A long, detailed message is not a finished spec; it is an inventory dump, and inventory implies
options the user expects you to surface (see the asset sweep below).
The brief can be short - a few sentences per section for truly simple ideas - but you must write
it and get approval.

## Checklist

Create a task for each item and complete them in order:

0. **Front-door triage (One-Minute Test)** - route the idea before spending; exit on CHAT / DON'T BOTHER
1. **Explore context** - files, docs, recent commits; never ask what context already answers
2. **Run the three scope probes, then the domain-modeling probe (E)** - before any detailed questions
3. **Ask clarifying questions** - in AskUserQuestion frontier rounds
4. **Propose 2-3 approaches** - trade-offs and your recommendation
5. **Present the brief section by section** - approval per chunk
6. **Write the brief file** - `docs/briefs/YYYY-MM-DD-<topic>-brief.md` in the target project
7. **Self-review** - the checks under Self-review below, fixed inline
8. **User reviews the brief** - and gets offered the commit
9. **Hand off** - name the next stage exactly as pinned under Terminal state, then stop

## Step 0 - Front-door triage (One-Minute Test)`[gate:DEFAULT]`

Before any shaping spend, run the One-Minute Test on the idea as the chain's first question (`references/one-minute-test.md`, read it before scoring - the worked examples are what keep the verdict honest).
Route by the shape of the work:

- **CHAT** or **DON'T BOTHER**: stop here. Say so plainly and name the driving reason (answer it in one exchange, or it does not earn the setup). Do not shape a brief; hand over the CHAT prompt or the manual checklist and stop.
- **ONE AGENT** or **AGENT TEAM**: this idea is worth shaping - proceed to Step 1.

The verdict auto-announces and proceeds under autonomy; a DON'T BOTHER that reverses a user's stated intent is the one case to surface rather than silently exit.

## Step 1 - Explore context

Files, docs, recent commits, and anything the idea references.
Existing tools and repos found here feed the asset sweep below (reuse candidates count as assets
even when the user forgot to mention them).
Never ask a question that context already answers.

## Step 2 - Scope probes, then domain modeling

Run these before clarifying questions, most expensive mistake first. Each catches a failure that would otherwise survive every downstream layer:

- **Trenchcoat check** - is this several independent ideas wearing one coat? Name the seams, agree which piece to brainstorm first, park the rest in the brief's Parking lot.
- **Meta-tooling probe** - if the idea is tooling, infrastructure, or a loop for running loops, ask once "what end artifact does this unblock, and when would it ship?" (goes in the brief's End artifact section). An idea that cannot name its first real deliverable is parked, not built.
- **Asset sweep** - list every asset the user mentioned (tools, models, plans, subscriptions, devices, data) and map each to the option it implies; every mapping lands in the brief as chosen or explicitly declined. Missing an implied option is a named failure mode for this user.
- **Glossary challenge (domain modeling, E)** - define every domain term the idea turns on in one plain sentence a non-expert could repeat back. A term that needs hand-waving or a circular reference is fuzzy: sharpen it, or flag it under Known vs guessed as believed-unchecked, never a silent assumption.
- **Scenario stress-test (optional)** - only when a domain term is load-bearing (a success criterion or seam depends on what it means): walk two or three edge scenarios that stretch the definitions; where the glossary bends becomes an Open question for planning.

## Step 3 - Clarifying questions in rounds`[gate:ASK]`

Map the open decisions as a design tree: every decision branches into the decisions that hang
off it.
Work the tree in rounds.
The **frontier** is every question whose prerequisites are already settled - the ones you can
ask now without guessing at answers you haven't heard yet.
Ask the whole frontier in one round, numbered, each with your recommended answer, then wait for
the user's answers before recomputing.
A question whose answer depends on another question still open in this round belongs to a later
round, not this one.

Present each round through the AskUserQuestion tool, up to 4 questions per call (chunk a larger
frontier into consecutive calls, dependency-safe order):

- Each question carries 2-4 concrete options, your recommended answer listed first.
- One decision per question: an option's label and description answer only the question asked;
  a scope narrowing (or any second decision) never rides inside an option's description - it gets
  its own question, and under autonomy scope narrowing is ASK-class, never auto-taken.
- An open-ended question becomes your 2-3 most plausible candidate answers as options; "Other"
  covers a verbose answer.
- If an "Other" response contains a question, concern, or counter rather than an answer, address
  it in prose and re-ask that single question before recomputing the frontier.

The importance order still shapes the tree:

1. **Outcome.** Restate the request as the outcome needed, not the action named.
   The named implementation ("probably a cron job") is a hypothesis and an invitation to
   counter-propose; test the presupposition before honoring it.
2. **Done looks like.** What can the user do when this is finished?
   Exact run or usage commands are part of done, always.
3. **Success criteria.** Push each criterion toward something a script could check.
4. **Seams.** Where does the idea split into independently checkable pieces?

Outcome is usually the root: round 1 is often that question alone (plus any scope-probe question
still open), and done/criteria/seams batch into round 2 once it settles.

Finding facts is your job, never the user's.
When a frontier question needs a fact from the environment (filesystem, docs, tools), dispatch a
sub-agent to find it instead of asking.
Don't block on it: a running exploration is an unsettled prerequisite, so only the questions
downstream of it wait - ask the rest of the frontier now.
The decisions are the user's; put each to them and wait.

The frontier stays capped at brief-shaped questions.
Questions you do NOT ask here: architecture, components, schedulers, data flow, file formats,
library choices.
If one surfaces on the frontier anyway, it becomes a one-line entry under the brief's Open
questions for planning, never a round entry.

**Reading the user** (distilled from the user's manuals; update when they change):

- Pushback phrased as a polite question ("maybe I'm missing something...") is confidence.
  Engage the substance; do not reassure.
- A reported symptom is ground truth; a stated cause or implementation is a hypothesis.
- Precision is domain-dependent: aesthetics tolerate ambiguity, data and money get exact
  questions.
- Mid-flight terseness and typos are noise, not new requirements; read through, ask only when
  genuinely ambiguous.
- **Cascade rule:** every new thread that surfaces mid-brainstorm ("oh and it could also...")
  goes to the Parking lot in writing, confirmed in one line ("parked: X"), and never widens the
  current scope.

## Step 4 - Approaches

Propose 2-3 genuinely different approaches with trade-offs, lead with your recommendation, and record the rationale in the brief.
The full approaches guidance - the trade-offs, and the chosen/alternatives/rationale that all go in the brief - is the first section of the shared convergence reference.
Read `references/brief-pipeline.md` in full and follow it before proceeding - do not summarize it from memory.

## Steps 5-6 - The brief`[gate:DEFAULT]`

Present the brief section by section, scaled to complexity, checking in after each chunk.
Then write it to `docs/briefs/YYYY-MM-DD-<topic>-brief.md`, following the user's markdown house style (~/.claude/CLAUDE.md).
The brief's default section shape, the checkability tagging rule, and the "what the brief is not" test are the shared convergence reference's middle section.
Read `references/brief-pipeline.md` in full and follow it before proceeding - do not summarize it from memory.

## Step 7 - Self-review

Look at the written brief with fresh eyes and fix inline - placeholder scan, internal consistency, the "survives an implementation swap" architecture scan, ambiguity check, and tag audit.
The full self-review checklist is the shared convergence reference's self-review section.
Read `references/brief-pipeline.md` in full and follow it before proceeding - do not summarize it from memory.

## Step 8 - User review gate`[gate:DEFAULT]`

Tell the user where the brief was written, invite review and changes before planning, and offer the commit; never commit without the offer being accepted.
The review-gate and commit-offer flow - the invitation, waiting for the response, and re-running self-review on requested changes - is the shared convergence reference's final section.
Read `references/brief-pipeline.md` in full and follow it before proceeding - do not summarize it from memory.

On an accepted commit, graduate the brief's Parking lot: preview the parked-item count and each derived title, then on assent invoke `scripts/graduate-parking.sh <brief-path>`.
The full graduation contract (preview/assent, bullet-shape/title-truncation rule, verbose announce, reverse, autonomy journaling) is the shared convergence reference's Graduation section - `references/brief-pipeline.md`, its single home; do not restate it here.
This graduation is a DEFAULT step in prose, not a new gate tag.

## Step 9 - Terminal state (pinned)`[gate:DEFAULT]`

Close by naming the approved brief's path and both routes onward: **/loop-plan** for the executor-agnostic implementation plan (the default next stage), or **/loop-drive** for a human-paced run-book (its human-paced output mode).

loop-brainstorm names the next stage but never invokes /loop-plan or /loop-drive itself; they
consume plans, not briefs.
It never invokes an implementation skill.
The only file it creates is the brief.

