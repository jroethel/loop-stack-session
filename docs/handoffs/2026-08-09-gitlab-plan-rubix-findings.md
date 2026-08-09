# Handoff: Rubix re-review of the GitLab plan - 23 findings, none applied yet

Date: 2026-08-09
Session: /loop-plan Rubix review (re-run) of `docs/plans/2026-08-09-gitlab-glab-support-plan.md`
State: findings recorded and verified; superseded 2026-08-09 (same day, later session) - all 23 findings were applied to the plan with findings 8 and 17 narrowed as recorded below, the prior handoff's blessing was corrected, and the brief's criteria 8-10 were restated; the plan's Review record carries the third entry

## Where things stand

The plan is unchanged on disk.
Two fresh-context lenses reviewed it, produced 25 raw findings, and those dedupe to 23.
I added 3 of my own and verified every load-bearing claim from both lenses against the repo before recording it here.
Nothing has been edited, so the next session can apply any subset without reconciling partial work.

| Artifact | Path |
| --- | --- |
| Plan under review | `docs/plans/2026-08-09-gitlab-glab-support-plan.md` (1,689 lines) |
| Source brief | `docs/briefs/2026-08-09-gitlab-glab-support-brief.md` |
| Prior handoff | `docs/handoffs/2026-08-09-gitlab-plan-ready.md` |
| This review | recorded here only; no plan revision, no commit |

This is the plan's **second** Rubix review.
The first ran before the bloat review cut the decision ledger, the `cksum` fingerprints, the version constants, and the setup-side migration offer.
That cut removed roughly 240 lines and changed Task 4's whole idempotence story, so re-reviewing the current text was worth doing rather than trusting the earlier round.
Both lenses were blind to this conversation and to the prior review record beyond what the plan itself states.

## How the review ran

Two read-only subagents, dispatched in parallel, each holding only the plan, the brief, and read access to the repo.

- **Lens A, the turned cube.** Told to enumerate the professionals downstream of the artifact, take the single most affected seat, and review what living with the plan would be like from it. It chose *the person re-running `loop-setup` in an already-settled repo he did not intend to change*, with runners-up being the teammate whose shared GitLab project receives the Task 7 smoke issues, and the agent running forge's vendored `gen-mirrors.sh` after a declined drift refresh.
- **Lens B, the scrambled start.** No seat and no sympathy: best practice for Bash CLI tooling, shell test harnesses, and idempotent setup scripts. Told to trace the plan's verbatim test scripts as code and to test the plan's on-disk claims rather than accept them.

Both ran on Opus.
Lens B would normally be a candidate for Fable given that this plan writes to a live shared corporate instance, but the global instructions bar Fable from ever being a worker, so Opus took both seats.

**Verification method.** I did not accept either lens on its word.
I re-derived the candidate count by extracting the shipped `is_excluded` and `is_candidate` predicates and running them over the real tree, confirmed the `find` empty-array behavior by running it, and read every cited line on disk.
Every claim recorded below survived that pass.
Where a lens was wrong, it is marked as part-declined with the reason.

## The blocking finding

With Task 4 ungating the import sweep, **every candidate the existing scan roots produce in this repo is a permanent design document.**

Re-derived rather than recalled:

```
current roots (docs .planning .ralph .scratch/*/issues) = 7 candidates
  docs/plans/2026-08-04-tracker-mode-plan.md
  docs/plans/2026-08-04-tracker-mode-plan_loop.md
  docs/plans/2026-08-07-loop-setup-reconcile-plan.md
  docs/plans/2026-08-08-audit-sweep-plan.md
  docs/plans/2026-08-08-audit-sweep-plan_loop.md
  docs/plans/2026-08-08-loop-improve-plan.md
  docs/plans/2026-08-09-gitlab-glab-support-plan.md    <- the plan itself
new root pass (Task 4)                                = 2 candidates
  PLAN.md
  fixing-agent-errors.md
TOTAL = 9
```

`is_excluded` at `skills/loop-setup/setup.sh:160` covers `docs/issues/*`, `docs/handoffs/*`, `docs/reviews/*`, `docs/briefs/*`, and `docs/archive/*`, and never `docs/plans/*`.
Task 4 then adds a `git mv` to `docs/archive/` behind the same confirmation as the import.
Under `LOOP_ASSUME_YES=1` that whole sequence is silent.

Two things make this worse than a nuisance.
`config/repo-state.md:64-65` makes plan archival a governed action with its own rules ("A brief archives when its plan archives; they travel together"), so the sweep would be reaching into a lane it does not own.
And `docs/briefs/*` is already excluded while `docs/plans/*` is not, which means the omission is an accident of when the sweep could not reach a github repo, not a decision.

**This was recorded and blessed in the prior handoff.**
Lines 41-42 of `docs/handoffs/2026-08-09-gitlab-plan-ready.md` state that ungating the sweep surfaces 9 candidates "including `PLAN.md` and this repo's own plan files" and call that "expected".
Two independent lenses, given no knowledge of that sentence, both flagged it as a defect.
That disagreement is the single most important thing in this document: the count was measured but never classified.

Two side effects of the same measurement.
The plan's pre-root-scan count of `6` at lines 49 and 1093 is wrong; the true figure is 7.
And Task 4's test fixture at plan line 974 uses `docs/some-plan.md` as a *wanted* candidate, which encodes the wrong intent into the suite that is supposed to gate the behavior.

## All 23 findings

Severity is the reviewing lens's, kept as given.
"Verdict" is mine.

| #  | Finding                                                                          | Lens | Sev  | Verdict               |
| -- | ---                                                                              | ---  | ---  | ---                   |
| 1  | `docs/plans/*` unexcluded; sweep offers and archives 7 live plan docs             | A+B  | crit | Revise                |
| 2  | Archive move has no repo-boundary and no destination-collision guard              | A+B  | high | Revise                |
| 3  | Root `find` pass collides with the empty-`roots` guard; degrades to full-tree scan | B    | high | Revise                |
| 4  | `LOOP_IMPORT_REMOTE` gate is unexpressible as specified; `ask()` cannot signal it | B    | high | Revise                |
| 5  | `--dry-run-remote` loses its no-remote-calls guarantee                            | A+B  | high | Revise                |
| 8  | Mode-switch offer has no acknowledgment path; reverses a documented contract      | A    | high | Revise (narrowed)     |
| 14 | `backlog-group` check is exit-0 only; a too-wide group passes identically          | A    | high | Revise                |
| 15 | Declined `gen-mirrors.sh` drift refresh leaves forge disclosing GitHub falsely    | A    | high | Revise                |
| 6  | `{{BACKLOG_GROUP}}` renders a broken `glab` line into every github/local config    | B    | med  | Revise                |
| 7  | `render_github`'s hardcoded "(github or local)" sentence never widened             | B    | med  | Revise                |
| 9  | Sweep runs after the mirror render, so a run that files N issues leaves them stale | A    | med  | Revise                |
| 10 | "nothing to do" counter covers 2 of 4 offer sources                               | A    | med  | Revise                |
| 11 | Tasks 3/4/5 gate on one new suite each while all three edit `setup.sh`            | B    | med  | Revise                |
| 12 | `template-version: 2` stamped on a config that is not a v2 render                 | A+B  | med  | Revise                |
| 13 | Task 7 Step 4's fallback reopens a committed Task 1 and breaks its assertion      | B    | med  | Revise                |
| 16 | Step 7b cleanup rests on two never-verified `glab` commands                       | A    | med  | Revise                |
| 18 | Task 3 scenario B's title contradicts its own fixture                            | B    | med  | Revise (comment only) |
| 21 | A second github-only assertion is untouched by any task and ungrepped by any test | mine | med  | Revise                |
| 17 | New `is_excluded` names are called "root basenames" but match at any depth        | A+B  | low  | Revise (part-decline) |
| 19 | Task 5's "default is still github" assertion passes vacuously                     | B    | low  | Revise                |
| 20 | `SKILL.md:29` stale across Tasks 3-5 until Task 6 fixes it                        | B    | low  | Revise                |
| 22 | Task 6's line references for `config/repo-state.md` are off by one                | mine | low  | Revise                |
| 23 | Plan lines 49 and 1093 carry a stale candidate count of 6                        | mine | low  | Revise                |

## Specifics and rationale

### High severity

**1. `docs/plans/*` unexcluded.**
Covered in full above.
Suggested change: add `docs/plans/*` to the `is_excluded` prefix case in Task 4 step a, rename the test fixture off a plan filename, restate the steady-state count, and record that plan and brief archival stays owned by the Archive-and-graduation rules.

**2. The archive move has no guards.**
Task 4 step a (plan line 1113) specifies only `mkdir -p docs/archive`, then `git mv` when the file is tracked else `mv`.
There is no `-n`, no existence check, and no check that the candidate path is inside the repo.
`skills/loop-setup/setup.sh:33` accepts `--scan <dir>` with no in-tree requirement, and `tests/loop-setup/import.sh:68` already runs `setup.sh --scan "$EXTRA"` where `EXTRA="$(mktemp -d)"`, under `LOOP_ASSUME_YES=1`, with `$EXTRA/extra-plan.md` matching the `plan` keyword.
So the first run of the existing suite after Task 4 lands would `mv` a file out of an unrelated directory into the sandbox repo, and the suite would stay green because it never asserts that `$EXTRA/extra-plan.md` survives.
Separately, two candidates sharing a basename collapse onto one `docs/archive/<name>.md` and the first is destroyed with no message.
Suggested change: skip the move when the destination exists and say so, and skip the archive offer entirely for any candidate whose normalized path is absolute or starts with `../`.

**3. The root `find` pass collides with the empty-`roots` guard.**
`setup.sh:178` is `[ "${#roots[@]}" -gt 0 ] || return 0`, which exists because `find "${roots[@]}"` with an empty array is unsafe.
I confirmed the failure mode by running it: `bash -c 'set -uo pipefail; a=(); find "${a[@]}" -maxdepth 0'` prints `.`, so GNU find silently defaults to the entire tree.
Task 4 step a says only "merged with the existing recursive `find`" and never mentions the guard, so the obvious implementation of a repo with no `docs/` directory is a recursive scan of everything.
Note that `setup.sh:177` already uses the `${SCAN_ROOTS[@]+"${SCAN_ROOTS[@]}"}` idiom for exactly this hazard, which is the in-repo pattern to follow.
Suggested change: run the root pass unconditionally, keep the recursive pass behind the existing guard, and replace the function-level early return with an empty-candidate-list return.

**4. The `LOOP_IMPORT_REMOTE` gate is unexpressible as specified.**
Plan lines 1101-1104 say the per-item confirmation "is not satisfied by `LOOP_ASSUME_YES` alone when `MODE` is `github` or `gitlab`" while "local mode and interactive per-item answers are unaffected".
`ask()` at `setup.sh:8-13` returns 0 for `LOOP_ASSUME_YES=1` and for an interactive `y` with no signal distinguishing them.
An implementer with zero context has two readings, and the wrong one (gate on `MODE` being remote) breaks the interactive path the plan promises to leave alone, including Task 7 Steps 2 and 3 in forge.
Task 4's test only exercises the non-interactive path, so the wrong reading passes.
Suggested change: state the condition literally, `[ "${LOOP_ASSUME_YES:-0}" = 1 ] && [ "${LOOP_IMPORT_REMOTE:-0}" != 1 ]`.

**5. `--dry-run-remote` stops meaning what it says.**
`setup.sh:224-234` scopes the entire remote finalize on `DRY_REMOTE=1`, and `skills/loop-setup/SKILL.md:50` documents the flag as skipping remote calls "instead of calling gh".
The new sweep gate keys on `MODE` and `LOOP_IMPORT_REMOTE` with no `DRY_REMOTE` term, so `--dry-run-remote LOOP_ASSUME_YES=1 LOOP_IMPORT_REMOTE=1` files real issues.
Existing dry-run tests do not set `LOOP_ASSUME_YES`, so nothing catches it and the next test author walks into it.
The plan's own review record cut a `DRY_REMOTE` interaction from the migration offer and never applied the same thought to the sweep.
Suggested change: add `[ "$DRY_REMOTE" -eq 0 ]` to the remote-creation condition, print the skip, and correct `SKILL.md:50` in Task 6.

**8. The mode-switch offer has no acknowledgment path.**
Plan line 883 makes a declined switch deliberately non-durable, justified at line 70 by "declines are the rare case once accepts self-archive".
That reasoning is sound for imports and false here: a declined mode switch has no archiving equivalent, so it is the one offer with unbounded repeat and no off switch.
It also reverses a shipped contract: `skills/loop-setup/SKILL.md:16` says setup "skips the question entirely (idempotent, never re-asks)" and `:39` says "a declared mode is never re-asked", while `config/repo-state.md:58` actively tells users to choose local deliberately for branched work.
Task 3's own test asserts only the easy half, that an agreeing repo is never nagged (plan line 800).
See the narrowing note below for what I would and would not take here.

**14. The `backlog-group` check cannot fail informatively.**
Plan line 103 declined a reviewer's premise that a top-level group may be unusable on a university-wide instance, and adopted an exit-0 check instead.
The brief records at line 121 that the live group query returns `[]`.
An empty result set makes exit 0 pass identically for a correctly scoped group and for a university-wide one that will later pull other teams' `idea` issues into this repo's declared backlog view.
Plan lines 1592-1593 treat non-zero as the only failure signal, so the wrong-but-working case is unobservable, and the brief itself bins top-level grouping as **Guessed** at lines 143-145.
Suggested change: assert that every returned project path begins with `university-advancement/crm`, and name the fallback derivation as the action on any foreign project.

**15. A declined drift refresh leaves forge lying about its own provenance.**
The drift refresh is per file and declinable at `setup.sh:75-87`, and Task 7 Step 2 presents those refreshes as offers without marking any required.
Task 2's fix lives only in loop-stack's copy of `gen-mirrors.sh`; the vendored copy defaults `SRC_LABEL="GitHub issues"` for every non-local mode at `scripts/gen-mirrors.sh:84-87`.
So accepting the gitlab mode switch while declining the `gen-mirrors.sh` refresh produces mirrors that disclose GitHub as the source of truth on a GitLab repo, in a file whose entire purpose is disclosure, in the exact repo the plan ships to.
Suggested change: have the gitlab finalize fail with a named fix when the target repo's `gen-mirrors.sh` does not contain `GitLab issues`, and mark the `tracker.sh` and `gen-mirrors.sh` refreshes as required for gitlab mode in Task 7 Step 2.

### Medium severity

**6. `{{BACKLOG_GROUP}}` leaks into github and local configs.**
The "Backlog cross-repo view" lines sit at `config/repo-state.template.md:33`, well before `## Local tracker` at line 45, so they survive `render_github`'s heading strip at `setup.sh:96-102`.
Task 3 step e then has `render_local` substitute `n/a (local tracker)` and `render_github` substitute the derived group with "empty is acceptable", producing `glab issue list --group n/a (local tracker) --label idea` in every local config and `glab issue list --group  --label idea` plus a bare `backlog-group:` line in every github config.
`tests/loop-setup/reconcile.sh` diffs two identical renders, so nothing catches it.
Suggested change: have `render_github` and `render_local` drop the gitlab backlog-view lines and the `backlog-group:` line outright, using the same `index($0, ...)`/`next` mechanism already used for "Render it into".

**7. `render_github`'s hardcoded sentence is never widened.**
`setup.sh:99` emits the literal `The tracker backend (github or local) is declared in the \`tracker:\` key below.`
Task 3 step a widens template lines 5 and 23, and step e widens only `render_gitlab`'s replacement.
So every github-rendered config would say "(github or local)" while the template it came from says "(github, gitlab, or local)", in the same file Task 6 exists to de-github-ify, and no suite greps a rendered github config for that sentence.
Suggested change: add the one-line update to `setup.sh:99` in Task 3 step e.

**9. The sweep files issues after the mirrors are rendered.**
`setup.sh:235` and `:238` run `gen-mirrors.sh`, and `:240` runs `reconcile_import` afterwards.
In local mode the staleness at least announces itself, because `scripts/tracker.sh:73` emits "note: ISSUES.md/BACKLOG.md now stale" from `local_create`; the github and gitlab create paths emit nothing.
Task 4 makes the sweep backend-agnostic without moving or repeating the mirror render, so a run that just filed 8 issues ends by printing completion over mirrors that do not contain them.
Suggested change: re-run `gen-mirrors.sh .` once at the end of the sweep when at least one candidate was imported, and assert a newly created issue appears in a mirror.

**10. The "nothing to do" line can be false.**
Plan line 1121 increments the counter in `reconcile_config` and the sweep only.
The drift-refresh loop at `setup.sh:75-87` prints a diff and asks per file, and `$TIDY` at `setup.sh:241` prints `byproduct:` and asks per item (confirmed at `scripts/tidy.sh:17-24`).
The brief bought exactly one line here, "finds nothing to do and **says so**" at line 39, so that line is the one that must not be wrong; a run that asked four questions and then claimed nothing to do is worse than the current silence.
Suggested change: increment the counter in the drift-refresh loop and after `$TIDY`, or narrow the wording to "no config or import work to do".

**11. The acceptance checks do not gate what the tasks can break.**
Plan lines 660, 952, and 1167 name one new suite each as the `[executed-check]`, while all three tasks edit the shared `skills/loop-setup/setup.sh`.
The regression runs live only in each task's Step 4 prose, which is not the gate, and Task 3 step j edits `tests/loop-setup/acceptance.sh`, a suite absent from Task 3's own acceptance check.
A driver honoring the acceptance check alone can mark all three done with existing suites red.
Suggested change: make the acceptance check for Tasks 3, 4, and 5 read `bash tests/loop-setup/<new-suite>.sh && bash tests/run.sh` exits 0.

**12. `template-version: 2` would be stamped onto a file that is not a version-2 render.**
`config/repo-state.md:21` carries an `autonomy-default:` paragraph that is absent from `config/repo-state.template.md` (I confirmed the absence), and the file retains a full `## Local tracker` section at lines 46-60 that `render_github` strips.
The file is a hand-maintained superset, not a render.
Task 6 step b adds four newly worded sentences inside exactly the section that a render strips.
Once `cv = tv = 2`, `reconcile_config` returns at `setup.sh:138` and the divergence is never surfaced again; when the template moves to 3, the offered re-render is `render_github` output and the note at `setup.sh:149` warns that accepting replaces the whole file, so the `autonomy-default` prose disappears on a keystroke.
Suggested change: add the `autonomy-default:` paragraph to the template so the render round-trips, and assert in Task 6's test that the config still contains it.

**13. Task 7's fallback would reopen a committed task.**
Plan line 1593 says a non-zero exit on the rendered group query means "change Task 1's `gitlab_group` to keep all path segments except the last and re-render".
Task 1's test asserts the opposite at plan lines 417-418, and Task 1 declared `scripts/tracker.sh` under exclusive ownership.
Following the instruction turns a green suite red inside the human-checkpoint task whose acceptance check is `tests/run.sh` reporting `0 failed`.
Suggested change: rewrite the fallback as "stop and file a follow-up; changing the derivation reopens Task 1 and its assertion", or set `backlog-group:` by hand, which the plan already documents as overridable.

**16. The cleanup step rests on unverified CLI surface.**
The plan's "Verified facts" block verifies `issue list`, `issue create`, `issue close`, `issue reopen`, `label create`, and `label list` flag by flag, precisely because it treats unverified `glab` surface as its top risk.
Step 7b then relies on `glab api --method DELETE "projects/:id/issues/<iid>"` at plan line 1666 and `glab issue update <iid> --title` at line 1672, neither of which appears in that block, including the `:id` placeholder substitution.
If both are wrong, the plan's own standard at line 1676 ("Leaving closed 'Delete me' tickets in `university-advancement/crm/forge` is not an acceptable end state") is unreachable, and the failure lands on a colleague-visible project.
Suggested change: verify the delete path against one throwaway issue before Steps 4 and 7 create anything, and record both commands as verified facts or as named risks.

**18. Task 3 scenario B's title contradicts its fixture.**
The header at plan line 730 reads "an existing local config with a FALSE 'Remote: none' line", but the heredoc at lines 735-745 ends with `tracker: gitlab`.
Tracing it, `existing_mode` resolves to `gitlab`, `report_remote` finds agreement, and only `reconcile_config`'s new `none`-prefix fallback is exercised.
The actual local-declared-plus-GitLab-remote case is scenario E, so an implementer reading B's comment could believe the forge repair is covered twice and drop E.
Suggested change: retitle scenario B and note in-line that the declared-mode disagreement is scenario E's job.

**21. A second github-only assertion survives untouched (mine).**
`config/repo-state.md:58` and `config/repo-state.template.md:57` both say "shared or branched work should use `tracker: github`", which is now false in the same way the wayfinder line is.
No task in the plan mentions it, and Task 6's test greps only for `wayfinder requires \`tracker: github\`` and `Migration to GitHub`, so the stale line ships while `docs-gitlab.sh` passes green.
Suggested change: widen both lines in Task 3 step a and Task 6 step b, and add the grep to Task 6's test.

### Low severity

**17. The new exclusion names are depth-agnostic, not root-scoped.**
`setup.sh:162` matches on `basename "$1"` with no depth constraint, so the names added at plan line 1092 also hide `docs/notes/README.md` and any nested `PLAN.md`, which is wider than "root basenames" states.
Lens A adds that the exclusion set is undeclared anywhere a user can find it, while `config/repo-state.md:28` claims to be "the definitive list" of root markdown files the convention owns.
Suggested change: match the new names against the normalized path so only depth-1 files are excluded, and declare the set in `config/repo-state.md`.
See the narrowing note below for the half I decline.

**19. Task 5's default-target assertion is vacuous.**
Plan lines 1257-1258 guard the invocation with `|| true`, then assert only that `glab issue create` is absent.
If an implementer makes `--to` mandatory, the output becomes a usage error, the grep finds nothing, and the assertion reports success while proving nothing.
Every other invocation in that file uses `|| fail`.
Suggested change: replace `|| true` with `|| fail`, and add a positive assertion that the default still emits `gh issue create`.

**20. `SKILL.md:29` goes stale for three commits.**
The literal `No GitHub remote found` lives in exactly two shipped places, `skills/loop-setup/setup.sh:121` and `skills/loop-setup/SKILL.md:29`.
Task 3 step j updates `tests/loop-setup/acceptance.sh:66` but not the skill, and the consistency check only arrives in Task 6's test.
Tasks 3, 4, and 5 therefore each ship a skill naming a string the script no longer prints.
Suggested change: move the four-string `report_remote` documentation edit into Task 3 step i, leaving Task 6 to assert it.

**22. Task 6's line references are off by one (mine).**
Task 6 step b cites "lines 56 and 58-60" of `config/repo-state.md`.
On disk the wayfinder line is 57 and "Migration to GitHub" is 59.
An executor with zero context edits by line number.
Suggested change: correct the references, or cite the strings instead of the line numbers.

**23. The plan carries a stale count of 6 (mine).**
Plan line 49 says "An earlier count of 6 was measured before the root scan existed and is superseded", and line 1093 says the exclusions take the count "from 6 to 9".
Re-derived, the pre-root-scan count is 7 and the post-root-scan count is 9.
Suggested change: correct both to 7, and once finding 1 lands, restate the steady-state count for this repo as 1.

## The two narrowings, and why

**Finding 8, narrowed.**
Lens A proposed swapping the offer's trigger from mode-versus-remote disagreement to "the recorded `Remote:` line is absent or starts with `none`".
I decline that half.
The disagreement is what produces criterion 5's observable in forge, and Task 7 Step 2 explicitly says to stop the run if the switch offer never appears, so replacing the trigger would remove the plan's own tripwire for whether g2 landed.
What I would take is the defect rather than the fix: add a way to record a deliberate `tracker: local` behind a remote so it stops being nagged, and correct `SKILL.md:16` and `:39`, which currently promise the opposite of what g2 does.

**Finding 17, part-declined.**
The depth-matching point is right and worth fixing.
Lens B's second half, trimming the list to the three names that exist in this repo, I decline.
`setup.sh` is vendored into other repos where `AGENTS.md`, `CHANGELOG.md`, `LICENSE.md`, and `CONTRIBUTING.md` do exist, so the defensive names earn their place; this repo's `ls` is not the population the script runs against.

## Recommendations

1. **Do not drive the plan until findings 1 through 5 land.**
   Those five are the ones that lose user data, scan the wrong tree, or fire real remote writes under a flag that promises not to.
   Findings 1 and 2 together are the plan's whole idempotence mechanism, and finding 2 will be exercised by the existing suite on its first run.

2. **Apply all 23, with findings 8 and 17 narrowed as above.**
   None of the remaining 18 is expensive, most are one or two lines, and several (7, 20, 22) are pure consistency fixes whose only cost is finding them again later.
   The three I contributed (21, 22, 23) are cheap and remove wrong numbers and wrong line references from a document an executor follows literally.

3. **Treat findings 1 through 5 as a design change to Task 4, not a wording pass.**
   They change what the sweep does, which means Task 4's verbatim test at plan lines 957-1078 needs corresponding assertions: a plan-lane file that must not be offered, an out-of-tree `--scan` candidate that must survive, a basename collision that must not overwrite, and a `--dry-run-remote` run that must not create.
   Re-running the plan's Step 5 self-review afterwards is not optional.

4. **Correct the prior handoff's blessing.**
   `docs/handoffs/2026-08-09-gitlab-plan-ready.md:41-42` records the 9-candidate blast radius as "expected".
   Leaving that sentence in place means the next session can read it as settled and re-close finding 1 without noticing that two blind reviewers both rejected it.

5. **Consider whether criteria 9 and 10 should be restated in the brief, not just the plan.**
   The bloat review cut the setup-logic stamp and the setup-side migration offer, and the plan's coverage table marks criteria 9 and 10 as "(revised)".
   The brief at lines 92-93 still states both in their original form, so the brief and the plan now disagree about what done means.
   Neither lens raised this, and it is not a defect in the plan; it is a divergence worth closing deliberately rather than by drift.

## Restart context

**Superseded 2026-08-09:** everything below described the state before the findings were applied; it is kept for the record.
All 23 findings are now applied to `docs/plans/2026-08-09-gitlab-glab-support-plan.md` (findings 8 and 17 narrowed per "The two narrowings" above), the plan's Review record carries the third entry, recommendation 4's handoff correction and recommendation 5's brief restatement are done.
This document is now a record, not a work queue.

Original restart context: nothing was edited and nothing was committed, so there is no partial state.
To resume: read this document's findings table, pick a subset, apply it to `docs/plans/2026-08-09-gitlab-glab-support-plan.md`, then re-run the plan's Step 5 self-review before any routing decision.
The plan's own "Review record" section has not been updated for this second review; whoever applies findings should add a third entry there recording which ones were taken and which were declined, matching the format already used for the first Rubix round.
