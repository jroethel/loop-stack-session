---
name: loop-brainstorm
description: >
  Use before any creative work: a new feature, component, project, behavior change, or a
  half-formed idea the user wants to think through - before any plan, PRD, code, or scaffolding
  exists. Supersedes superpowers:brainstorming for this user: when both could trigger, use this
  one. Use even when the idea seems simple or already fully specified, and especially when the
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
                     └─ /loop-plan ──> plan (+ optional rubix review)
                                       └─ /loop-which ──> /loop-drive
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

1. **Explore context** - files, docs, recent commits; never ask what context already answers
2. **Run the three scope probes** - before any detailed questions
3. **Ask clarifying questions** - one per message, multiple choice preferred
4. **Propose 2-3 approaches** - trade-offs and your recommendation
5. **Present the brief section by section** - approval per chunk
6. **Write the brief file** - `docs/briefs/YYYY-MM-DD-<topic>-brief.md` in the target project
7. **Self-review** - the checks under Self-review below, fixed inline
8. **User reviews the brief** - and gets offered the commit
9. **Hand off** - name the next stage exactly as pinned under Terminal state, then stop

## Step 1 - Explore context

Files, docs, recent commits, and anything the idea references.
Existing tools and repos found here feed the asset sweep below (reuse candidates count as assets
even when the user forgot to mention them).
Never ask a question that context already answers.

## Step 2 - The three scope probes

Run these before refining anything, in this order (most expensive mistake first):

- **Trenchcoat check.** Is this several independent ideas wearing one coat?
  If so, name the seams, agree on which piece to brainstorm first, and park the rest in the
  brief's Parking lot.
- **Meta-tooling probe.** If the idea is tooling, infrastructure, or a loop for running loops,
  ask once: "what end artifact does this unblock, and when would it ship?"
  The answer goes in the brief's End artifact section.
  An idea that cannot name its first real deliverable is parked, not built.
- **Asset sweep.** List every asset the user mentioned - tools, models, plans, subscriptions,
  devices, data - and map each to the option it implies.
  Every mapping lands in the brief as chosen or explicitly declined.
  Missing an implied option is a named failure mode for this user; the sweep is how it is caught.

## Step 3 - Clarifying questions

One question per message, multiple choice preferred, in this order of importance:

1. **Outcome.** Restate the request as the outcome needed, not the action named.
   The named implementation ("probably a cron job") is a hypothesis and an invitation to
   counter-propose; test the presupposition before honoring it.
2. **Done looks like.** What can the user do when this is finished?
   Exact run or usage commands are part of done, always.
3. **Success criteria.** Push each criterion toward something a script could check.
4. **Seams.** Where does the idea split into independently checkable pieces?

Questions you do NOT ask here: architecture, components, schedulers, data flow, file formats,
library choices.
If one surfaces anyway, it becomes a one-line entry under the brief's Open questions for
planning, not a discussion.

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

Propose 2-3 genuinely different approaches with trade-offs, lead with your recommendation, and
say why.
The chosen approach, the alternatives, and the rationale all go in the brief; decisions without
recorded rationale get relitigated.

## Steps 5-6 - The brief

Present it section by section, scaled to complexity, checking in after each chunk.
Then write it to `docs/briefs/YYYY-MM-DD-<topic>-brief.md` (one sentence per line, plain dashes,
aligned table pipes).

Every section below is REQUIRED.
For a simple idea a section may be one sentence, or `n/a - <reason>`; it may never be silently
absent.

| Section                    | Contents                                                                    |
|----------------------------|-----------------------------------------------------------------------------|
| Outcome                    | The need restated as outcome, not the action named; presupposition verdict  |
| End artifact               | The concrete thing this unblocks; for infra, the first real deliverable     |
| Done looks like            | What the user can do when finished, including the exact run/usage commands  |
| Assets and options         | Every asset mentioned, mapped to its implied option, chosen or declined     |
| Approach                   | The chosen one, the 2-3 considered, and the rationale at decision time      |
| Success criteria           | Each tagged `[executed-check]` or `[judgment]` (see tagging rule below)     |
| Seams                      | Independently checkable pieces in blast-radius order, or "atomic" stated    |
| Known vs guessed           | Three bins: verified / believed-unchecked / guessed, with what breaks if a  |
|                            | guess is wrong                                                              |
| Parking lot                | Every parked thread, verbatim enough to restart later                       |
| Out of scope               | What this deliberately is not                                               |
| Open questions for planning| Implementation questions that surfaced, one line each, unanswered           |

**Checkability tagging rule.**
Tag a criterion `[executed-check]` only if you can name the command shape that would verify it
(exit 0, a rendered file, a fetched citation).
For a `[judgment]` criterion, attempt one reformulation toward checkable - "feels fast" becomes
"the digest renders in under 2 seconds on the sample vault" - and keep the judgment tag only if
the reformulation genuinely loses the intent.
Downstream, /loop-plan routes every `[judgment]` tag to a human checkpoint (never a worker task),
and /loop-which question 4 and /loop-drive's step 1 halt condition consume the tags directly
(P6: work enters a swarm only when checking is cheaper than producing).

**What the brief is not.**
The brief contains no components, no data flow, no schedulers, no file formats, no library
names, no phased build roadmap.
If any of those appears in your draft, move it to Open questions for planning as a single line
and delete the prose.
The test: every sentence in the brief should survive the implementation being swapped out
entirely.

## Step 7 - Self-review

Look at the written brief with fresh eyes and fix inline:

1. **Placeholder scan** - any TBD, vague requirement, or empty REQUIRED section.
2. **Internal consistency** - do sections contradict each other?
3. **Architecture scan** - run the "survives an implementation swap" test on every sentence.
4. **Ambiguity check** - could any criterion be read two ways? Pick one, make it explicit.
5. **Tag audit** - is every success criterion tagged, and every `[judgment]` tag the survivor of
   an attempted reformulation?

## Step 8 - User review gate

> "Brief written to `<path>`. Please review it; I'll make any changes before we hand it to
> planning. Want me to commit it?"

Wait for the response.
Changes requested means edit and re-run the self-review.
Offer the commit; never commit without the offer being accepted.

## Step 9 - Terminal state (pinned)

> Brief approved at `<path>`. Next stage: **/loop-plan** for the executor-agnostic implementation
> plan. Alternative: `fable-sandwich` for a human-paced run-book.

loop-brainstorm never invokes /loop-which or /loop-drive directly; they consume plans, not
briefs.
It never invokes an implementation skill.
The only file it creates is the brief.

## Red flags - stop, you are rationalizing

| Thought                                        | Reality                                            |
|------------------------------------------------|-----------------------------------------------------|
| "This is too simple to need a brief"           | Simple ideas hide the costliest assumptions         |
| "The idea is already clear from the message"   | A detailed message is an inventory dump; run the    |
|                                                | sweep                                               |
| "This is infrastructure, there's no artifact"  | That IS the meta-tooling probe firing; ask it       |
| "I'll keep that new idea in mind"              | Park it in the lot, in writing, now                 |
| "The architecture is obvious, I'll sketch it"  | One line in Open questions for planning; delete     |
|                                                | the sketch                                          |
| "This criterion can't be made checkable"       | Attempt the reformulation first; only then tag      |
|                                                | `[judgment]`                                        |
| "The user named the implementation, so use it" | The named action is a hypothesis; test it           |

## Process flow

```dot
digraph loop_brainstorm {
    "Explore context" [shape=box];
    "Three scope probes" [shape=box];
    "Clarifying questions\n(one at a time)" [shape=box];
    "Propose 2-3 approaches" [shape=box];
    "Present brief sections" [shape=box];
    "User approves sections?" [shape=diamond];
    "Write brief file" [shape=box];
    "Self-review (fix inline)" [shape=box];
    "User approves brief?" [shape=diamond];
    "Offer commit; pinned handoff; STOP" [shape=doublecircle];

    "Explore context" -> "Three scope probes";
    "Three scope probes" -> "Clarifying questions\n(one at a time)";
    "Clarifying questions\n(one at a time)" -> "Propose 2-3 approaches";
    "Propose 2-3 approaches" -> "Present brief sections";
    "Present brief sections" -> "User approves sections?";
    "User approves sections?" -> "Present brief sections" [label="no, revise"];
    "User approves sections?" -> "Write brief file" [label="yes"];
    "Write brief file" -> "Self-review (fix inline)";
    "Self-review (fix inline)" -> "User approves brief?";
    "User approves brief?" -> "Write brief file" [label="changes"];
    "User approves brief?" -> "Offer commit; pinned handoff; STOP" [label="approved"];
}
```
