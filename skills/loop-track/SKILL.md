---
name: loop-track
description: >
  File one tracker issue (idea, plain issue, or a wayfinder-labeled item) into a loop-setup'd
  repo from a plain natural-language ask, no mechanism knowledge required. Triggers on "add as
  an idea/issue to <repo>", "file this as an idea in <repo>", "file this as an issue in <repo>",
  "add this to wayfinder for <repo>", and loop-track. Not for thinking an idea through (that's
  loop-brainstorm) and not for capturing a memo (no such destination exists here).
---

# loop-track: file one tracker issue, no mechanism knowledge required

A thin skill: resolve the repo, draft one title/body from the ask in hand, file it with the
right label, report back the number. Nothing else.

<HARD-GATE>
loop-track only ever creates exactly one tracker issue per invocation.
It never writes a memo file, never builds a wayfinder map's structured body (Destination /
Notes / Decisions so far / Not yet specified / Out of scope) or its tickets - a "wayfinder"
ask here just means attaching the `wayfinder:map` label to a plain issue, the same as idea or
issue. A real wayfinder map belongs to `/wayfinder`, not here.
It never invokes loop-brainstorm, loop-plan, or loop-drive.
</HARD-GATE>

## Step 1 - Resolve the label

Read the ask for which of the three flavors is wanted - they are the same GitHub/GitLab issue
object, just different labels:

- "idea" -> `idea`
- "issue" / "bug" / unspecified -> `` (empty; a plain issue)
- "wayfinder" -> `wayfinder:map`

## Step 2 - Resolve the repo

If the ask names a path, use it as-is.
If it names cwd (or names nothing and cwd looks right), use cwd.
Otherwise pass the bare name straight to `loop-track.sh` - it searches under `$HOME` for a
loop-setup'd repo (a directory with `config/repo-state.md`) matching that name and resolves it
itself.
Zero or multiple matches is not your job to disambiguate: `loop-track.sh` fails with the
candidates (or the absence of any), pass that back to the user and ask for an explicit path.

## Step 3 - Draft title and body

Draft a concise title and a body capturing the substance of the request or finding from the
surrounding conversation - the same judgment call `/loop-brainstorm`'s graduation step and
`graduate-parking.sh` already make, just for one item instead of a batch.
Never ask the user to write the title/body themselves; that defeats the point of a low-friction
trigger.

## Step 4 - File it

Run the runnable core, `loop-track.sh` next to this file:

```bash
skills/loop-track/loop-track.sh <repo-path-or-name> <label> "<title>" "<body>"
```

It resolves the repo (Step 2's fallback), calls that repo's own `scripts/tracker.sh create`
(respecting its declared `tracker:` backend), and prints one confirmation line with the new
issue's kind, number, and repo - `Filed idea #46 in loop-stack-session: <title>`.
Relay that line verbatim; this is the verbose-announce convention (`config/conventions.md`) and
the only report-back this skill offers - no separate lookup of the URL.
