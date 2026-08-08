# Batch review: loop-improve brainstorm (2026-08-08)

Run journal for the /loop-brainstorm session that produced docs/briefs/2026-08-08-loop-improve-brief.md.
Autonomy knob: auto (runtime, pre-existing in docs/chain-state.md).
ASK entries are record-only; DEFAULT entries are the review obligation.

## 1. [record] ASK round 1: end artifact, outcome, leftovers, covered definition

- Decision: Jeremy chose - first deliverable is a run on loop-stack itself; one brief per run; unselected findings graduate to backlog as `idea` issues; covered findings are annotated but stay selectable.
- Rationale: outcome-level frontier; three recommendations taken, one overridden (covered findings selectable rather than excluded).
- Reversal: n/a - resolved live.

## 2. [record] ASK round 2: audit source, knobs, issue fate, scan scope

- Decision: Jeremy chose - vendor a trimmed copy of /improve's audit playbook (MIT); keep the focus argument plus quick/standard/deep; a superseding brief offers `tracker.sh close` of the matching issue at commit; the tracker scan stays improve-only with the brainstorm-scan idea parked.
- Rationale: unlocked by round 1; all four recommendations taken.
- Reversal: n/a - resolved live.

## 3. [record] ASK approach: shared convergence half

- Decision: Jeremy chose the shared convergence half - loop-improve and loop-brainstorm keep their own divergence halves and share one brief-pipeline reference from approach-proposal onward.
- Rationale: one source of truth for the brief format and gates; declined the self-contained duplicate (drift) and the thin front end over brainstorm (redundant question rounds).
- Reversal: n/a - resolved live.

## 4. [DEFAULT] Steps 5-7: brief presented as one written chunk, self-review inline

- Decision: the per-chunk approval gate was auto-taken; the brief was drafted in full, self-reviewed (placeholders, consistency, architecture scan, ambiguity, tag audit), and written to docs/briefs/2026-08-08-loop-improve-brief.md.
- Rationale: gate class DEFAULT under auto; single-skill idea of moderate complexity, all section content already settled by the three ASK rounds.
- Reversal: cheap - edit or delete the brief file before planning consumes it.

## 5. [DEFAULT] Step 8: review gate and commit auto-taken

- Decision: the brief was committed as a95c3f4 without a live review pause.
- Rationale: gate class DEFAULT under auto; every judgment in the brief traces to an ASK answer from entries 1-3.
- Reversal: `git revert a95c3f4`, or edit and re-commit after review.

## 6. [DEFAULT] Parking-lot graduation: issue #14 created

- Decision: the single parked item graduated as idea #14 ("Add the issues/backlog scan to /loop-brainstorm so a fresh idea is checked against existing backlog items before briefing") via scripts/graduate-parking.sh, after a dry-run preview verified the parse.
- Rationale: graduation is a DEFAULT step once the Step 8 commit lands; one item, title and body matched the template.
- Reversal: `scripts/tracker.sh close 14`.
