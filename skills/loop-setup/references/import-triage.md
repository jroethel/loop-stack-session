# Import triage

## This is the default import workflow

Triage is the import workflow, not an exception to it.
After the mechanical config and mirror steps finish, the agent scans the repo for pre-existing work files, classifies what it finds, verifies it, and files the outstanding items into the tracker.
The hard cases - a file that mixes many items, work that is already built, reference prose that is not actionable - are handled here by judgment instead of being mangled by the mechanical sweep.

The bash per-item prompt is unchanged.
It still offers the two fallbacks verbatim: import this one file as one issue, or skip it.
Triage is what the agent does instead of accepting either fallback when neither fits.

## The workflow

Run the steps in order; blast radius grows down the list, and each step narrows what reaches the next.

1. Scan candidates with `setup.sh --list-candidates`, which prints one normalized path per line, honoring `--scan`, with no side effects.
2. Classify each discrete item in each candidate: active work is an issue with no label, and a parked backlog item takes the `idea` label.
3. Verify every item as outstanding or already-built against the codebase and git history; a dropped item, already-built or noise, carries disclosed evidence, a `file:line` or a commit.
4. Present one batch disclosure table, then offer a per-candidate walkthrough for any item the human picks.
5. On approval, file each outstanding item, archive each source doc, write the record doc, and regenerate mirrors.

## The batch disclosure table

One table, shown once, holds the whole run's decisions.
Its columns are source-doc, item, classification, verdict plus evidence, and proposed-action.
Keep the raw table under 110 characters wide.
Put long evidence or prose outside the table when a cell would exceed it.

Example shape, short cells with the long evidence carried below:

| source-doc        | item           | class | verdict       | action        |
| ----------------- | -------------- | ----- | ------------- | ------------- |
| docs/notes.md     | fix export job | issue | outstanding   | file, archive |
| .planning/next.md | retry on 504   | idea  | already-built | drop (E1)     |
| docs/notes.md     | glossary move  | -     | noise         | drop (E2)     |

Dropped evidence, outside the table:

- E1: the retry shipped in `scripts/pull.sh:42`, commit a1b2c3d.
- E2: the glossary move is reference prose, not an actionable item.

## On approval

In this order:

1. File each outstanding item with `scripts/tracker.sh create --label <label> --title <title> --body <body>`.
   The command prints the new issue number; capture it for the record doc.
   Pass `--label idea` for a parked backlog item and omit `--label` for active work.
2. Archive each source doc to `docs/archive/`.
   Use `git mv` when the file is tracked and plain `mv` otherwise.
3. Write the D1 triage record doc described below.
4. Regenerate the mirrors with `scripts/gen-mirrors.sh .`.

## Issue body pointer-back footer

Every filed issue body ends with the graduated-item template shape from `config/repo-state.md`, adapted for import.
The footer is the verbatim item prose, then a `---` rule, then three metadata lines.

```
<verbatim item prose from the source doc>
---
Source doc: docs/archive/<original-path>
Imported: YYYY-MM-DD
Restart context: <one line>
```

The verbatim prose lets the issue stand on its own after the source doc is archived.
`Source doc:` points at the archived copy, `Imported:` is today's date, and `Restart context:` is the one line a future session needs to pick the work back up.

## The triage record doc (D1)

Path: `docs/archive/YYYY-MM-DD-import-triage.md`.

Write one record doc per run that had candidates.
A run with zero candidates writes none.
The agent writes it, never bash.

The record holds a triage table with columns source-doc, item, classification, verdict, evidence, and action, followed by the filed issue numbers.
Classification is `issue` or `idea`; verdict is `outstanding`, `already-built`, or `noise`.
Every dropped row carries its evidence, so the record contains no drop without evidence.

Example record:

| source-doc        | item           | class | verdict       | evidence          | action  |
| ----------------- | -------------- | ----- | ------------- | ----------------- | ------- |
| docs/notes.md     | fix export job | issue | outstanding   | -                 | #12     |
| .planning/next.md | retry on 504   | idea  | already-built | pull.sh:42 a1b2c3 | dropped |
| docs/notes.md     | glossary move  | -     | noise         | reference prose   | dropped |

Filed: #12.

## Judgment rules

These carry over unchanged in intent from the exception-only reference this file replaced.

### Split

One issue names one actionable item.
Split a candidate when it is a list, when its sections are independently actionable, or when its title needs an "and" to describe it.
A doc holding N discrete items yields N issues, never one.

### Merge

Merge when two candidates restate the same work, or when one is strictly a subset of the other.
Merge into the one with the better restart context and drop the other.

### Leave in place

Decline the file and leave it where it is when it is reference material, a log, or a completed record.
It will be offered again on the next run, and that repeat is the design speaking up about a live loose end, not a bug.

### Titling

The title is the action, in the imperative, readable without the body.

### Labelling

The `idea` label is the one load-bearing label.
Use `idea` for anything parked by decision and no label for active work.

### Disclosure

Every proposed split is shown to the human with its proposed titles before any issue is created.
This is a judgment, not a check, so it stays with the agent, never in bash.
