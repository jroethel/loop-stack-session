# Unit T7 - upstream comment draft for ringer#65

Date: 2026-08-20
Spec: docs/plans/2026-08-20-ringer-amend-plan.md, "Task 7"
Type: docs-only, one file.

## What shipped

- Created `docs/ringer-65-comment-draft.md` in the T7 worktree (branch `T7-work`, off `amend-command`).
- A GitHub-comment-sized draft in Jeremy's voice, replying to barthballard on issue #65.

## Content decisions

- Read the live issue #65 and its one comment (barthballard's) for grounding rather than working from the brief's paraphrase alone.
- Credited barthballard by name for the generalization the shipped design adopts: a wrong FAIL and a human rejection of a bad PASS as mirror images that want one primitive - append-only, caller-trusted, note-required, audit-logged - so one open reclassify field carries both directions and leaves one audit model instead of two.
- Also credited his two build-shaping notes (skip-before-group placement to avoid the `tasks == 0` 0.00 row, and void-do-not-flip) and his run-view note, since the shipped design acted on them - this reads truer in Jeremy's people-first, named-credit voice than a bare generalization credit.
- Stated what shipped: append-only `amend` command, whole-task void (evidence-void, neither credit nor blame), `check_bug` as the only reclassify value, schema left open for future kinds. Closed on impact (promotion math hears about it) per the action-then-mechanism-then-impact pattern.

## Checks run

- Spec acceptance check (in worktree): `draft OK` (file exists, contains "barthballard" and "check_bug").
- Em-dash count: `grep -c $'—'` = 0.
- Committed on branch `T7-work`: `da6334a` "docs: draft upstream comment for ringer#65" (plain message, no co-author line). Working tree clean.

## Deviations / open questions / deferred

- Deviations: none.
- Open questions: none.
- Deferred: HC-2 - the post itself is the user's trigger (outbound send in his name); draft only, nothing posted to GitHub.
