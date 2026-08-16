# Repo State Map

This file is the single schema source for where each repo-state lane lives and how to read or mirror it.
The tracker backend (github, gitlab, or local) is declared in the `tracker:` key below.

template-version: 2

Remote: https://github.com/jroethel/loop-stack-session.git
tracker: github

## Lanes

| Lane          | Home                      | How                                            |
| ---           | ---                       | ---                                            |
| Roadmap       | `ROADMAP.md`              | Living file; edit in place, no mirror.         |
| Issues        | GitHub (open, no `idea`)  | `ISSUES.md` via `scripts/gen-mirrors.sh .`.    |
| Backlog       | GitHub (label `idea`)     | `BACKLOG.md` via `scripts/gen-mirrors.sh .`.   |
| Handoffs      | `docs/handoffs/`          | Per session; git fallback below.               |
| Chain state   | `docs/chain-state.md`     | Runtime, gitignored.                           |
| Batch reviews | `docs/reviews/`           | Per review run.                                |
| Archive       | `docs/archive/`           | Moved work lands here.                         |

The committed per-repo autonomy default is a line-anchored `autonomy-default:` key in this same file (value `pause` or `auto`).
The runtime value in `docs/chain-state.md` overrides it; `skills/loop-auto/loop-auto.sh default get|set|clear` reads, writes, and removes it.

The committed tracker backend is a line-anchored `tracker:` key in this same file (value `github`, `gitlab`, or `local`).
Every loop-stack script reads it and obeys it; none infers the backend from `git remote`.
`scripts/tracker.sh mode get|set` reads and writes it; `skills/loop-setup/setup.sh` asks it once when the key is missing.

All root-level ALL-CAPS markdown files (`ROADMAP.md`, `ISSUES.md`, `BACKLOG.md`) belong to this convention; everything else it owns lives under `docs/` or `config/`, and this file is the definitive list.
The import sweep never offers the root project files `README.md`, `CLAUDE.md`, `AGENTS.md`, `PLAN.md`, `CHANGELOG.md`, `LICENSE.md`, `CONTRIBUTING.md`, nor anything under `docs/plans/`, `docs/briefs/`, `docs/issues/`, `docs/handoffs/`, `docs/reviews/`, or `docs/archive/`.
The `idea` label is the one load-bearing label.
Unlabeled issues (optionally `bug` or `refactor`) form the Issues lane; issues labeled `idea` form the Backlog lane.

Filename patterns: handoffs are `docs/handoffs/YYYY-MM-DD-<slug>.md`; batch reviews are `docs/reviews/YYYY-MM-DD-<slug>-batch-review.md`.

Backlog cross-repo view: `gh search issues --owner jroethel --label idea --state open`.
Per-repo fallback when private-repo search is unavailable: `gh issue list --label idea --state open`.

"Where I left off" is the most recent of two candidates: the newest `docs/handoffs/` file and the newest commit on the working branch - whichever is fresher wins.
A handoff older than the latest commits is context, not the frontier: read it, then let `git log --oneline -5` and `git status` say what happened since.
When several threads are plausibly open (multiple recent handoffs or active branches), name them and ask which to resume rather than silently picking one.
A crashed session degrades to git, never to nothing.

GitHub is the single source of truth.
Mirrors are read-only snapshots whose headers disclose staleness.
They regenerate at handoff time or on demand - no hooks, no daemons.

## Agent status vocabulary

The `agent:` label family is the single status schema for tracker issues; this file is its only home.
Semantics are fixed: `agent:todo` (queued, no active claim), `agent:working` (claimed by a session holding a claim receipt), `agent:needs-input` (blocked on a human answer), `agent:review` (work offered for review), `agent:done` (evidence-gated completion, reachable only through `scripts/tracker.sh done`, never `label add`).
Exactly one status is active at a time; `tracker.sh status` swaps them, and the `agent:` family is orthogonal to the `idea` lane label.

## Archive and graduation rules

1. A plan is done when all items are complete (archive automatically), or when the remaining items are cleanly rewritten into a surviving plan (archive offered).
1a. A plan-set is archivable when it is superseded (a strictly newer live plan-set exists by date) and no OPEN issue links its topic stem; `scripts/lifecycle-lint.sh .` flags these (class a) plus orphaned briefs (b), open issues over archived plans (c), and closed issues under live plans (d).
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

## Context map

- Molt evaluation source: `docs/memos/2026-08-15-pcs-consolidated-recommendations.md` - the pcs verdict and the second axis for molt constraint re-derivation; its protocol is vendored at `skills/loop-molt/references/protocol.md`, its drift ledger at `docs/molt-ledger.md`.
- Research corpus: `~/create/research/research/` (outside the repo; `~/create/pcs/` renamed 2026-08-16) - the 13 digests behind the 2026-08 evaluation; working docs archived in `~/create/research/archive/`.

## Scope rule

The top roadmap item is the active stream.
Backlog items are parked by decision; pulling one mid-stream is an explicit, announced choice, never a silent default.
A session orienting after a break names the active stream first, states these limits, and treats every other stream as out of scope until the user pulls it in.
