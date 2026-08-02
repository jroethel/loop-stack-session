# Repo State Map

This file is the single schema source for where each repo-state lane lives and how to read or mirror it.
For a repo with no remote, replace it with the no-remote note and follow the Fallback section.

Remote: https://github.com/jroethel/loop-stack-session.git

## Lanes

| Lane          | Home                      | How                                            |
| ---           | ---                       | ---                                            |
| Roadmap       | `docs/roadmap.md`         | Living file; edit in place, no mirror.         |
| Issues        | GitHub (open, no `idea`)  | `ISSUES.md` via `scripts/gen-mirrors.sh .`.    |
| Backlog       | GitHub (label `idea`)     | `BACKLOG.md` via `scripts/gen-mirrors.sh .`.   |
| Handoffs      | `docs/handoffs/`          | Per session; git fallback below.               |
| Chain state   | `docs/chain-state.md`     | Runtime, gitignored.                           |
| Batch reviews | `docs/reviews/`           | Per review run.                                |
| Archive       | `docs/archive/`           | Moved work lands here.                         |

The `idea` label is the one load-bearing label.
Unlabeled issues (optionally `bug` or `refactor`) form the Issues lane; issues labeled `idea` form the Backlog lane.

Filename patterns: handoffs are `docs/handoffs/YYYY-MM-DD-<slug>.md`; batch reviews are `docs/reviews/YYYY-MM-DD-<slug>-batch-review.md`.

Backlog cross-repo view: `gh search issues --owner jroethel --label idea --state open`.
Per-repo fallback when private-repo search is unavailable: `gh issue list --label idea --state open`.

"Where I left off" is the newest `docs/handoffs/` file if one exists.
Otherwise it is the newest commit on the working branch plus `git log --oneline -5` and `git status`.
A crashed session degrades to git, never to nothing.

GitHub is the single source of truth.
Mirrors are read-only snapshots whose headers disclose staleness.
They regenerate at handoff time or on demand - no hooks, no daemons.

## Fallback (no remote)

When a repo has no GitHub remote, the Issues and Backlog lanes fall back to a local-markdown tracker.
Tracker root: `.scratch/<feature>/issues/`.
Use one file per issue, named by the issue title slug.
Graduate these into GitHub issues when the repo gains a remote.

## Archive and graduation rules

1. A plan is done when all items are complete (archive automatically), or when the remaining items are cleanly rewritten into a surviving plan (archive offered).
2. A brief archives when its plan archives; they travel together.
3. Abandoned work archives only when offered and accepted.
4. Parking-lot graduation is automatic at brief-commit time.
5. Every archive or graduation action is verbose: announce each moved file and each created issue with its number.

Graduated-item issue body template (label the issue `idea`):

```
<verbatim parking-lot prose from the brief>
---
Source brief:
Graduated: <date>
Restart context: <one line>
```
