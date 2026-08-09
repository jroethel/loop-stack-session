# Import triage: split and merge judgment

`setup.sh`'s sweep offers only the mechanical import: one file becomes one issue, verbatim.
A file that needs splitting or merging is **declined at the bash prompt** and handled here, by the agent.
The agent proposes the split, creates each issue through `scripts/tracker.sh create`, and then offers the archive move.
This keeps the flagship case - a `whats_next.md` holding many items - from being mangled into a single issue.

## The rule

One issue names one actionable item.
A proposal spanning two unrelated items is wrong and gets split before anything is created.

## When to split

Split when any of these holds:
- the candidate file is a list;
- its sections are independently actionable;
- its title needs an "and" to describe it.

## When to merge

Merge when two candidates restate the same work, or when one is strictly a subset of the other.
Merge into the one with the better restart context and decline the other.

## When to leave it in place

Decline the file and leave it where it is when it is reference material, a log, or a completed record.
It will be offered again on the next run, and that repeat is the design speaking up about a live loose end, not a bug.

## Titling

The title is the action, in the imperative, readable without the body.

## Labelling

Use the `idea` label for anything parked by decision.
Use no label for active work.
The `idea` label is the one load-bearing label.

## Disclosure requirement

Every proposed split is shown to the human with its proposed titles before any issue is created.
This is a judgment, not a check, so it stays with the agent, never in bash.
