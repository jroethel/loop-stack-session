---
name: loop-auto
description: Set or check the chain autonomy knob (/loop-auto), and the home of the four gate classes (ASK, STOP, BATCH, DEFAULT) and the batch-review journal format. Turns the chain from human-gated (pause) to autonomous (auto), persisted to docs/chain-state.md with an optional committed per-repo default. Triggers on "run the rest", "take it from here", "go autonomous", "auto mode", "full auto".
---

# loop-auto

The autonomy knob for the chain.
Two modes: `pause` (the unset default - every gate fires live, the human is asked at each ASK) and `auto` (after the last ASK gate passes, the session runs the rest of the chain without further prompts).

## What it does

Run the knob through the script, or via the `/loop-auto` command:

- `/loop-auto set auto` - turn autonomy on (runtime, this session).
- `/loop-auto set pause` - turn it back off (runtime, this session).
- `/loop-auto get` - print the effective mode as a bare word for script consumers.
- `/loop-auto status` - print the effective mode and its source for the human.
- `/loop-auto default get` - print the committed per-repo default.
- `/loop-auto default set <pause|auto>` - write the committed per-repo default.
- `/loop-auto default clear` - remove the committed per-repo default.

The runnable core is `loop-auto.sh` next to this file; this skill narrates and invokes it: `loop-auto.sh {set <pause|auto>|get|status|default <get|set <pause|auto>|clear>|preflight <mode>}`.
Invoke it from the target repo's root - it operates on the caller's cwd (writing `docs/chain-state.md`, reading `config/repo-state.md` there), never on the repo the script lives in.
Setting the mode always ends with a one-line confirmation of the new mode; it is never silent.

## Consumption is live

Consumption is live: the knob now governs gate behavior per the four gate classes below.
Setting the mode acts on this run, not on a future build wave.
This skill is the single home of the autonomy protocol; the managed CLAUDE.md block only points here.

### Knob off or unset

Fully human-gated: every gate fires live, nothing auto-taken - every ASK, STOP, BATCH, and DEFAULT surfaces to the human.

### When autonomy takes effect

Only after the last ASK gate passes. Up to and including that gate the human is in the loop; after it, the active session orchestrates the rest of the chain under the rules below.

A mode change never retroactively answers a question already asked.
When the knob flips to `auto` mid-session, any offer or choice already on the table - an unaccepted commit offer, a pending route choice - stays the human's to resolve; setting the mode does not convert it into a DEFAULT take.
On `set auto` the session first presents one consolidated ASK - `outstanding before autonomy commences: X, Y, Z - take all / pick / none` - resolves it, and only then does autonomy govern the rest of the chain.

### The four gate classes under autonomy

- ASK always blocks.
  It asks the human and waits; autonomy does not auto-answer an ASK.
  Offers and questions already pending at the moment `auto` is set are ASK-class too: setting the mode never converts them to DEFAULT takes (see "When autonomy takes effect").
- STOP always halts and states what it needs.
  A STOP names the missing input or the failing invariant (dirty tree, exceeded effort cap, outward-facing unit) and waits; autonomy never auto-resolves a STOP.
- BATCH auto-takes the named lean, proceeds, and collects the decision for the end review.
  The lean was already named in the gate's prose; autonomy takes it, records it, and moves on.
- DEFAULT auto-takes the default and logs verbosely.
  The default was already declared at the gate; autonomy takes it, logs the decision in full, and moves on.

Scope narrowing is ASK-class by definition: a decision that narrows the requested scope is never a BATCH lean or a DEFAULT take, wherever inside a step it arises.
Narrowing is sometimes right, but it is never silent and never auto-taken - it surfaces as its own explicit question.

### Batch-review list format

The batch-review list is the run's gate journal: it is created the moment autonomy takes effect and appended at every gate as it fires, in chronological order, so a run that dies mid-chain still leaves the record of every decision taken so far.
The list home is `docs/reviews/YYYY-MM-DD.<tokens>.<slug>-batch-review.md` (declared in `config/repo-state.md`).
When the work belongs to a logged tracker item, include its token segment(s) (e.g. .I6 for issue 6, .B4 for backlog item 4, .R1 for roadmap item 1, .W3 for wayfinder ticket 3); when the item is not yet logged, omit the token segments entirely and insert them when the item is created.
All four gate classes are logged, but they carry two different obligations.
ASK and STOP entries are record-only: the human was present for them, so they preserve the chronology and the context around neighboring decisions but need no review.
BATCH and DEFAULT entries are the review obligation: each is a decision auto-taken for the human, to accept or reverse at the end-of-chain checkpoint.
Each entry has three fields: the decision (for record-only entries, what was asked or halted and how the human resolved it), the rationale, and a reversal path (record-only entries mark it `n/a - resolved live`).
The reversal is named honestly by gate type: a DEFAULT or commit reversal is cheap (`git revert`, or undoing the default next pass); a BATCH taste reversal (topology, triage) is a scoped re-run with the alternate lean, since the lean was a judgment, not a fact.
An entry with no honest reversal path should have been a STOP, not auto-taken.

### Continuation rule

The session active when autonomy takes effect orchestrates the rest of the chain.
Delegation only goes down-tier - the orchestrator hands work to sonnet, opus, or haiku workers, or to ringer-transported GLM/codex.
Nobody ever spawns Fable.
Fable is orchestrator-tier only and never a worker, so the autonomy continuation never delegates to it, not even under full auto.

## Per-repo default

The committed per-repo default lives as a line-anchored `autonomy-default:` key in `config/repo-state.md`.
The runtime value in `docs/chain-state.md` overrides it; `get` returns the effective mode (runtime if present, else the committed default, else `pause`).
On the FIRST `set` in a repo, ask whether to persist the mode as the repo default (committed via `default set`, which reminds the human to stage and commit the tracked change) or keep it session-only (runtime `set`).
`status` shows the effective mode and its source, for example `mode: auto (repo default)` or `mode: pause (session)`.

## Recognized phrases

Any of these phrases sets the knob to `auto` with a one-line confirmation:

- "run the rest"
- "run the rest from here"
- "take it from here"
- "go autonomous"
- "auto mode"
- "full auto"

Recognizing a phrase does not skip the confirmation.
The human always sees the new mode in the same turn.

## Where it lives

The runtime mode is persisted in `docs/chain-state.md` (gitignored runtime state, declared in `config/repo-state.md`).
`get` reads the effective mode; an absent runtime file with no committed default means `pause`.
`docs/chain-state.md` is the runtime source of truth - do not shadow it in session memory or a plan artifact.
