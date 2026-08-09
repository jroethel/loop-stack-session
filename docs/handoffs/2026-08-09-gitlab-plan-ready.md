# Handoff: GitLab (glab) backend plan approved and committed

Date: 2026-08-09
Session: /loop-brainstorm brief -> /loop-plan -> Rubix review -> revised -> committed -> bloat review against Matt Pocock's setup skill -> revised again -> re-committed
State: plan approved and committed, nothing implemented yet

## Where things stand

The implementation plan is written, reviewed, revised, and committed.
No code has been written.
The next session either routes the plan through `/loop-which` or drives it.

| Artifact | Path |
| --- | --- |
| Brief | `docs/briefs/2026-08-09-gitlab-glab-support-brief.md` |
| Plan | `docs/plans/2026-08-09-gitlab-glab-support-plan.md` |
| Plan commits | `30dd7f4` (first version), then the bloat-review revision in the commit that also carries this handoff (on `main`, atop the brief `b01c29d`) |

The plan is self-contained: 7 tasks, verbatim test code, exact acceptance checks, executor-agnostic.
Read it rather than this document for anything about what to build.
This handoff covers only what the plan does not record: why the scope grew, what was decided and by whom, and what to watch.

Nothing is pushed to the remote.

## Scope: what this does to loop-setup

The brief was framed as "add glab support", but the work is mostly a rewrite of `skills/loop-setup/setup.sh`.
Three of the seven tasks (3, 4, 5) all own that one file, which is why the plan's dependency graph is one parallel wave followed by a strict serial chain.
That serialization is deliberate and recorded in the plan, not an oversight to be optimized away.

`setup.sh` changes along four axes (a fifth, a committed decision ledger, was cut - see the revision note below):

1. **Remote detection.** Today it greps the remote list for `github.com` only, so any non-GitHub repo reports "No GitHub remote found" and records `Remote: none`.
   It now captures any remote, classifies it as github / gitlab / other / none, and phrases a suggestion without ever picking the mode.
2. **A third render and finalize.** `render_gitlab` plus a gitlab finalize with a host-scoped `glab` auth guard and `idea` label creation.
3. **The import sweep goes universal.** Previously gated to local mode, it now runs in all three, gains a repo-root scan, a single gate question before per-item offers, and a declinable archive move after each import.
4. **Migration reach.** `scripts/migrate-tracker.sh` gains `--to gitlab` and gets vendored into target repos; `SKILL.md` tells the agent when to suggest it, and `setup.sh` never runs it.

Idempotence is state of the world, not a state file: an imported candidate is archived (and `docs/archive/*` is excluded from the scan), so a settled repo offers nothing; a declined-and-left candidate re-offers next run behind the gate question, by design.

Blast radius worth knowing before driving: without exclusions, ungating the sweep would have surfaced **9** import candidates in this repo on the first run, including `PLAN.md` and this repo's own plan files.
**Correction (2026-08-09, second Rubix review):** this handoff originally called that count "expected"; two blind review lenses independently classified it as a defect - the count was measured but never classified.
The plan now excludes `docs/plans/*` (plan archival is owned by the Archive-and-graduation rules) and the depth-1 root project files, leaving a steady state of 1 candidate in this repo.
Do not re-close this from the original sentence; see `docs/handoffs/2026-08-09-gitlab-plan-rubix-findings.md`, finding 1.

## Decisions made this session, and who made them

Jeremy decided these; do not silently revisit them.
The rows marked *(revised)* were changed at Jeremy's explicit request in the bloat review - that was his call, not drift.

| Decision | Choice |
| --- | --- |
| Idempotence mechanism *(revised)* | No ledger, no state file. Archive-on-import is the mechanism; declines re-offer next run. The earlier ledger-plus-fingerprints design was cut against Matt Pocock's setup skill as baseline. A 10-line skip file (`path\|cksum`) is the named upgrade if decline re-offers prove annoying |
| After a successful import | Offer to move the file to `docs/archive/`, declinable per file |
| Sweep entry | One gate question, then per-item confirmation |
| Versioning shape *(revised)* | Only the already-shipped `template-version` key remains; the setup-logic stamp and repo-side version were cut with the ledger |
| Migration surfacing *(revised)* | `SKILL.md` prose suggests `scripts/migrate-tracker.sh --to <target>`; the setup-side interactive offer was cut |
| Decision durability | Durable where the world records it (archive); a live loose end left in place is worth re-asking about - Jeremy: "I do not want silence when speaking up is needed" |

Resolved by running commands rather than asking, and recorded in the plan's "Verified facts" section: the glab JSON field names, `iid` versus `id`, pagination, the `--jq` translation, host resolution, and the absence of a `--state` flag.

**On criterion 8 specifically.** The plan originally implemented "declined means permanently quiet."
That was an over-reading.
Brief lines 39-41 already scope it to "with the same answers and nothing else changed", and Jeremy confirmed the intent: durable unless something changes which impacts durability, and no silence where speaking up is needed.
Criteria 8, 9, and 10 are revised in the plan's Brief coverage table accordingly, with Jeremy's pre-authorization ("if that means criterion 8 needs revising, so be it").
`tests/loop-setup/reconcile.sh` and `tests/repo-state/config.sh` end up untouched by the plan.

## Review record

The plan was reviewed twice; both records live in the plan's own "Review record" section.

1. **Rubix review** (two fresh-context lenses): twenty-one findings applied, three narrowed.
2. **Bloat review against Matt Pocock's setup skill** (`~/repos/mattpocock/skills/skills/engineering/setup-matt-pocock-skills/`), requested by Jeremy: the script seam stays (loop-stack has deterministic consumers Matt's prose-only design does not), but the ledger, fingerprints, version constants, and setup-side migration offer were cut.
   Several Rubix findings resolved by deletion.
   The plan shrank from 1,933 to about 1,690 lines, and two existing test suites went back to untouched.

The single worst Rubix defect is worth carrying forward as a caution: `setup.sh:203-206` short-circuits whenever a `tracker:` key already exists, which made every new gitlab path unreachable in the one repo the work exists for.
The lesson generalizes.
When adding behavior to `setup.sh`, check whether the early-return at the mode-resolution block skips it.

A second lesson from the bloat review: the bash sweep imports one file as one issue, mechanically; anything needing split/merge judgment is **declined at the bash prompt** and handled by the agent per `skills/loop-setup/references/import-triage.md`.
That division of labor is what keeps forge's `whats_next.md` from being mangled into a single issue.

## Task 7 is not like the other six

Read this before driving anything.

Task 7 is the live smoke against `/home/jjrdar/claude/forge`, whose remote is a **shared corporate GitLab instance** (`gitlab.code.rit.edu`, group `university-advancement`).
It is the only task that touches anything outside this repo.

- **Every write in Task 7 is Jeremy's to fire.** An agent stages the commands and waits. It never runs them unattended, and never on his behalf.
- **Its acceptance check is not just the test suite.** `bash tests/run.sh` verifies none of Steps 2 through 8. Task 7 carries a results table and is not done until every row has an observed value. If a driver reports Task 7 complete off a green offline suite alone, that report is wrong.
- **Criterion 13 is a human judgment**, not a command: the proposed split of forge's 7433-byte `whats_next.md` into issues must be shown to Jeremy and approved before a single issue is created.
  The bash sweep will offer `whats_next.md` as ONE mechanical import - decline that offer; the split happens through the agent per `import-triage.md`, then the file is archived.
- **Take the branch in Step 2 first.** `setup.sh`'s drift refresh offers to replace forge's vendored scripts, and forge has a large unrelated `scripts/` tree.
- **Clean up.** Step 7b removes the smoke artifacts. Closed "Delete me" tickets left in a shared project are not an acceptable end state.

If the mode-switch offer does not appear when `setup.sh` runs in forge, stop.
That means Task 3's g2 did not land, and everything downstream of it in forge is unreachable.

## Suggested skills

1. **`/loop-which`** - recommended first. Feed it `docs/plans/2026-08-09-gitlab-glab-support-plan.md`. The run-shape question is genuinely open here because only one of six waves is parallel; a routing verdict is worth more than an assertion.
2. **`/loop-drive`** - once the route is settled, if it is a loop. Waves 1 through 5 are offline and safe to drive. Wave 6 (Task 7) is the human-gated live smoke described above.
3. **`/loop-review`** - after execution, reviewing since `30dd7f4`.
4. **`/loop-setup`** - not for this work, but note it is the subject under change; do not run it in this repo mid-implementation, because Task 4 alters what it does.

## Restart context

If resuming cold: read the plan, not this file, for the work.
The chain state is that planning is complete and execution has not begun.
Nothing is half-done, so there is no partial state to reconcile; the next session starts clean at whichever route it picks.
