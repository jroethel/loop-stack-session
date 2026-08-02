# Session dump: loop-stack vs mattpocock/skills comparison (2026-07-20)

Self-contained record of the comparison session.
Written for a future session to pick up without re-exploring.
A draft change plan also exists at `~/.claude/plans/i-want-to-compare-flickering-biscuit.md`; its content is folded into the "Draft plan" section below so this file stands alone.

## What Jeremy asked

Compare loop-stack's chain to Matt Pocock's skills (`~/repos/mattpocock/skills/`).
His process: grill-with-docs or wayfinder → to-spec → to-tickets → implement → code-review.

Things he likes about Matt's system:

- setup skill establishes context and an issue tracker.
- wayfinder suits ambiguous large questions, which he often has.
- Brief skill frontmatter.
- code-review verifies on two axes after implement.
- handoff (productivity) is a graceful, repeatable "dump to file" replacement.

Issues he has with loop-stack today:

- Plan drafting seems like an Opus task, but rubix then finds the plan isn't very good; tempted to use a better model when maybe only the last 10% needs it.
- loop-drive breaks plans into tickets in the frontier session; unclear that is frontier-class work.
- Nothing at the end says "was the work good?".
- Backlog/ideas/open-items tracking differs per repo (whats_next.md, progress.md, files from brainstorms 3 sessions ago).
- Wants control over chain autonomy: run without intervention, pause per step, or queue around quota.
- For a few small fixes the chain feels like the wrong tool; something like /tdd fits better.
- Open to using Matt's skills as-is rather than remaking them.
- Asked about the quota-planning item from a prior session.

## Findings: Matt Pocock's skills (essentials)

- Layout: `skills/engineering/` and `skills/productivity/` are the promoted buckets; ships as copy-in (`skills.sh`) or a Claude Code plugin.
- Frontmatter: minimal - name, one dense description sentence, optional `disable-model-invocation`; bodies from 2 lines (grill-with-docs, implement) to ~130 (wayfinder); detail split into sibling .md files.
- State conventions: `CONTEXT.md` = glossary only; ADRs in `docs/adr/`; setup config in `docs/agents/` (issue-tracker.md, domain.md, triage-labels.md); local tracker = markdown under `.scratch/<feature>/issues/`.
- Context discipline: grill → to-spec → to-tickets kept in ONE unbroken context window (the ~120k "smart zone"); each implement starts fresh per ticket.
- setup: run once per repo; picks tracker (gh / glab / local .scratch / other), triage labels, domain doc layout; every downstream skill reads it.
- wayfinder: for ideas too big for one session; a map issue + decision-ticket children on the tracker using native blocking links; four ticket types (Research via /research subagent AFK, Prototype, Grilling, Task); one ticket per session; merges onto the main flow at to-spec.
- grill-with-docs: 2-line composition of /grilling + /domain-modeling; relentless interview that writes CONTEXT.md and ADRs as it goes.
- to-spec: NO interview, pure synthesis of the conversation into a PRD published to the tracker; no file paths or code (go stale); sketches test seams and confirms them with the user.
- to-tickets: tracer-bullet vertical slices, each fitting one fresh context window, with explicit blocking edges; expand-contract special case for wide refactors.
- implement: 9-line hub - use /tdd at pre-agreed seams, typecheck plus single test files regularly, full suite once, then /code-review, then commit.
- code-review: two parallel fresh-context subagents, one per axis - Standards (repo standards plus a fixed 12-smell Fowler baseline) and Spec (faithfulness to the originating issue/PRD, scope creep) - reported side by side, deliberately never merged into one verdict.
- tdd: red-green only at confirmed public seams; refactoring explicitly belongs to code-review, not the loop.
- domain-modeling: maintains glossary + ADRs; ADR offered only when hard-to-reverse AND surprising AND a real trade-off.
- prototype: throwaway code answering one design question (LOGIC or UI branch); decision folded back, prototype parked on a throwaway branch.
- handoff: compacts the conversation into a handoff doc in the OS temp dir; includes suggested-skills section; never duplicates what specs/ADRs/commits record; redacts secrets.
- There is no "hand" skill; it is handoff.

## Findings: loop-stack (essentials)

- Four skills in `skills/`: loop-brainstorm (237 lines), loop-plan (245), loop-which (132), loop-drive (199); symlinked via install.sh; managed CLAUDE.md block from `claude-md/fable.md`.
- Chain: brainstorm → brief (`docs/briefs/`) → plan (`docs/plans/`) (+ optional rubix: two fresh-context Opus lenses, session triages, user picks) → loop-which verdict → loop-drive compile + drive.
- Checkability tagging (`[executed-check]`/`[judgment]`) is load-bearing across the whole chain; Matt's system has no equivalent.
- loop-drive: three tiers (orchestrator/validator/implementer), two transports (ringer manifests, Agent tool), evidence chain for model choice (scoreboard posterior → benchmark prior → pin), GLM flat-rate lean on ties, deliberate absence of a whole-run final review.
- Backlog: no cross-repo convention; parked ideas live per-brief in Parking lot sections.
- Quota question answered: "Quota-aware pause/resume scheduling" is explicitly PARKED (model-routing-brainstorm-prompt.md line 59 and the 2026-07-18 brief's parking lot); nothing was built; what exists is the interruption-safe resume design and the claude-zai tie-break.
- Staged `brainstorm-prompt.md` in repo root is a 10-line resume breadcrumb pointing at `model-routing-brainstorm-prompt.md`, not a spec.

## Skill mapping

| Matt Pocock       | loop-stack                      | Note                                            |
|-------------------|---------------------------------|-------------------------------------------------|
| setup             | (none)                          | Establishes issue tracker + domain docs         |
| wayfinder         | (none)                          | Multi-session decision map with fog-of-war      |
| grill-with-docs   | loop-brainstorm                 | See Venn below                                  |
| to-spec           | loop-plan (header/synthesis)    | Rubix has no equivalent on his side             |
| to-tickets        | loop-plan tasks + drive Step 1  | loop-plan tasks already carry depends-on edges  |
| (none)            | loop-which                      | loop-stack advantage; he has no triage step     |
| implement         | loop-drive Steps 2-5            | His is a 9-line hub; loop-drive orchestrates    |
| code-review       | (none - deliberate)             | The "was the work good?" gap                    |
| tdd               | (partial: plan embeds tests)    | His refuses tests off pre-agreed seams          |
| handoff           | ad hoc breadcrumb files         | The staged brainstorm-prompt.md is this pain    |

## Venn: grill-with-docs vs loop-brainstorm

Shared: adversarial interview to sharpen a fuzzy idea, challenge assumptions, refuse implementation, durable written output feeding a spec stage.

Only grill-with-docs:

- Cumulative repo-level knowledge (CONTEXT.md glossary + ADRs) that compounds across efforts.
- Domain modeling as the interview's spine (terms, entities, invariants).
- ADR discipline for decisions that get relitigated otherwise.
- Low ceremony (2-line body); designed to stay in-context and feed to-spec in the same sitting.

Only loop-brainstorm:

- Cold-start externalization: one brief file any later model/stage can consume with zero shared context.
- Checkability tagging, consumed by loop-plan checkpoints, loop-which Q4, loop-drive Step 1.
- Scope machinery targeting Jeremy's failure modes: cascade rule, trenchcoat check, meta-tooling probe, asset sweep.
- Known-vs-guessed ledger, parking lot, explicit out-of-scope.

grill is better when: domain-heavy problems, long-lived repos where glossary/ADRs compound, or you continue to spec in the same session.
loop-brainstorm is better when: idea dumps, output must survive session death, downstream runs on different models, or the work will be driven autonomously.

Neither covers:

- Too-big-for-one-session ambiguity (wayfinder's territory).
- Answering a design question with throwaway code (prototype).
- Systematic ingestion of an external corpus (the NotebookLM-pointing habit is manual compensation).
- A durable home for parked items across briefs (the backlog-sprawl complaint).

Takeaway: not competitors for one slot; a routing rule can hold both.

## Core design insight: multi-model skills

Models never share context; they share documents.
Dispatch = a subagent receives written artifacts, works in a throwaway context, returns one artifact; the session judges the artifact, never sees the reasoning.
loop-stack already runs this pattern twice: rubix lenses (plan + brief only, "that blindness is the point") and every ringer worker ("no pointer specs").
loop-plan drafting is dispatchable precisely because the skill already forces everything the drafter needs into writing; if a fresh-context drafter cannot write the plan from the documents, a fresh-context executor could not run it either.
Jeremy's rubix symptom explained: today the session model drafts WITH conversation context and fresh-context Opus reviews; fresh eyes always beat the builder, so findings indicate builder-blindness, not drafter weakness.
Flipping it (fresh-context Opus drafts, session Fable judges the draft against the conversation) puts each model where its blindness isn't.

## Full step breakdown with model assignments

Notation: session = runs in the chat's model, cannot be delegated; dispatch = self-contained input, any model.

/loop-brainstorm:

1. Explore context - Sonnet dispatch (mechanical grubbing, summary returns).
2. Three scope probes - Fable session (the asset sweep is the "catch the browser idea" class).
3. Clarifying questions - Fable session (highest-judgment step in the chain).
4. Propose approaches - Fable session (arbitration with live context).
5-9. Present/write/self-review/gate/handoff - session (transcription and trivia).
Net: brainstorm is where a Fable session earns its cost; only step 1 dispatches.

/loop-plan:

1. Ingest - Sonnet dispatch.
2. Resolve open questions - Fable session; produces the decisions note that makes step 4 dispatchable.
3. Decompose - Opus (architecture; Fable arbitrates only deviations from the brief's seams).
4. Write plan file - Opus dispatch (bulk token spend, synthesis against locked inputs).
5. Self-review - Opus, same dispatch.
6a. Rubix lenses - Opus dispatch (unchanged); 6b. Triage - Fable session (arbitration).
7-8. Gate/handoff - session.

/loop-which: all session, one short pass, Opus-grade sufficient; usually embedded in drive Step 0; nothing worth dispatching.

/loop-drive:

- Step 0 Route/probe/checkability gate - Fable session (arbitration; talks to the user).
- Step 1 Extract skeleton (units, wave graph from depends-on, templates, checkpoints, hazards) - Opus dispatch (input is entirely the plan file).
- Step 2 Assign models/effort - split: evidence-chain lookups in the dispatch, tagged per row; pins/taste flags/overrides are Fable judgment at review. Opus proposes, Fable disposes.
- Step 3 Hazard pass - Opus, same dispatch (rule application from reference files).
- Step 4 Prompts + checks - Opus, same dispatch (check-writing has the stm-nav false-FAIL record; highest-care compile step; why the bundle is Opus not Sonnet).
- Step 5 Wave loop + gates - Fable session (FAIL attribution, spec-problem calls, merges). Implementers: evidence chain, GLM lean. Validators: Opus or executed check.
- Step 6 Emit _loop.md - Opus, same dispatch (transcription of the pipeline's own outputs).
- Step 7 Dashboard/launch - session.

Steps 1-4 and 6 bundle into ONE Opus dispatch: a pipeline over the same documents, each step consuming the previous one's output, none needing the conversation.
Caveat: Steps 1 and 3 alone are probably Sonnet-capable; the bundle rides on Step 4.
Lazy verification: give the compile dispatch its own ringer task_type and let the scoreboard settle Opus-vs-Sonnet.

Resulting pattern: Fable = reading the user, arbitration, gates (brainstorm probes/interview, rubix triage, pins, drive Steps 0+5).
Opus = document synthesis/compilation (plan decompose+draft+self-review, drive compile, lenses, validators).
Sonnet/Haiku = exploration and lookups.
Implementers = evidence chain with GLM lean.
No skill splits required: model granularity without skill granularity.

## Decisions made this session

- Absorb domain-modeling behavior (CONTEXT.md glossary + ADR side effects) into loop-brainstorm.
- Add a wayfinder route for too-big-for-one-session work.

## Open decisions (NOT settled)

1. Adopt the dispatch seams in loop-plan and/or loop-drive, split skills instead, or keep as-is.
2. Gap sourcing for tdd / handoff / setup: use Matt's as-is, cherry-pick + port, or port everything.
3. Add a two-axis final review gate to loop-drive (his code-review pattern) or keep per-unit validators only.
4. Backlog home: his setup + local tracker convention, gh issues, or keep per-repo files.
5. Minor: trim loop-which's 144-word frontmatter.
6. Still parked (untouched this session): quota-aware pause/resume scheduling; chain-level autonomy modes (run-through vs pause-per-stage).

## Draft plan (from ~/.claude/plans/i-want-to-compare-flickering-biscuit.md)

1. loop-plan dispatch seams: Sonnet ingest; Opus decompose+draft+self-review as one fresh-context dispatch fed by a written decisions note; session reviews the draft against the conversation before presenting; rubix triage stays in-session.
2. loop-drive compile/drive split: Steps 1-4+6 as one Opus dispatch with its own task_type; Fable keeps Step 0, routing-table pin review, Steps 5+7.
3. loop-brainstorm: absorb domain-modeling side effects; Sonnet explore dispatch; wayfinder overflow route; DO NOT touch the Jeremy-maintained "Reading the user" section.
4. Gap adoption (default, strikeable): install mattpocock/skills; route handoff, tdd, setup via the managed CLAUDE.md block.
5. Final review gate (default, strikeable): two parallel Opus dispatches over the whole run diff, Standards + Spec axes, side by side, before integration merge.
6. Backlog home (default, strikeable): one declared issues home per repo; brief parking-lot items graduate there at brief-commit time.
7. Trim loop-which frontmatter.
Verification: RED-GREEN one-shot artifact testing per the skill-testing memory; test loop-plan against the 2026-07-18 model-routing brief; dry-run drive compile against the 2026-07-19 plan and diff the emitted _loop.md against the committed one.

## Process note for next session

Jeremy explicitly does not want AskUserQuestion-style Q&A mode in this work; answer questions inline in prose and let him respond freely.
The repeated question prompts this session came from plan-mode workflow pressure and derailed the conversation; do not repeat that.

## Resume

```
cd ~/create/loops/loop-stack-session && claude --model claude-fable-5
```

Then: "Read docs/2026-07-20-mattpocock-comparison-dump.md and let's continue from the open decisions."
