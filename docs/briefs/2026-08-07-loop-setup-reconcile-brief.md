# Brief: loop-setup reconciles pre-existing state and cleans up after mode transitions

Source: backlog issue #10.
Date: 2026-08-07.

## Outcome

loop-setup and its mode-transition tooling reconcile a repo that already carries state instead of assuming greenfield.
Stale or keyless config is detected and re-rendered with a shown diff.
Pre-existing issue-shaped files are offered for import into the tracker.
Migration residue is neutralized and offered for removal.
Untracked `.scratch/` byproducts are inventoried with per-item deletion offers.
Every action is offered with a preview, never silent, and never fired without acceptance.
Presupposition verdict: the issue's five-gap diagnosis was verified against code this session - all five gaps exist as described (setup.sh legacy branch, missing import path, live-looking migrated ledger, no tidy notion, dangling Local-tracker reference in the github render).

## End artifact

Recurring: the next loop-setup run on any repo with pre-existing state needs zero manual reconciliation steps.
First deliverable: the improved setup and migrate scripts passing per-gap checks in the existing tests/ harness.

## Done looks like

Same entry points as today.

- Re-running `skills/loop-setup/setup.sh` in a repo with an older-template or keyless config reports it, shows the diff, and offers the re-render; declining leaves the file byte-identical.
- The same run scans for pre-existing issue-shaped markdown in standard roots - prior local-tracker roots (`.scratch/*/issues/`), `docs/`, `.planning/`, `.ralph/`, all recursive - plus any user-supplied paths, and offers per-file import via the tracker with labels inferred from the old `Label:` lines.
- The live tracker home and loop-stack's own files (handoffs, reviews, briefs, mirrors) are never import candidates.
- The same run inventories untracked `.scratch/` byproducts with per-item context and per-item deletion offers; the tool never judges "merged" - the human does.
- `scripts/migrate-tracker.sh` always neutralizes each migrated file's `state:` line, then offers the `git rm` of the migrated ledger; the user fires it.
- Every offer is answerable non-interactively so the test harness can drive it.

## Assets and options

| Asset                               | Implied option                            | Verdict                                    |
| ---                                 | ---                                       | ---                                        |
| tests/loop-setup + tests/repo-state | Extend for per-gap checks                 | Chosen                                     |
| substack-scraper session            | Combined replay fixture                   | Declined (per-gap checks only)             |
| repo-state.template.md              | Anchor for staleness detection            | Chosen; mechanism is a planning question   |
| tracker.sh create                   | The import mechanism for converted issues | Chosen (proven by this session's hand-run) |

## Approach

Chosen: extend the existing surfaces.
`setup.sh` gains the detect-and-offer reconcile steps (stale-config diff and re-render, issue import, tidy inventory); `migrate-tracker.sh` gains freeze-plus-removal-offer.
One entry point, which is the chosen posture; every gap lands in the existing tests/ harness; no new concept for target repos to carry.

Considered and declined:

- Dedicated reconcile companion invoked by setup: cleaner separation of scaffold from reconcile, but adds a seam that buys nothing once setup invokes it unconditionally anyway.
- Agent-narrated reconcile with dumb scripts: most flexible on fuzzy matching, but not unit-checkable - it conflicts directly with the per-gap executed-check done-test.

## Success criteria

1. Stale/keyless config: setup on a fixture with an older-template config detects it; an accepted offer yields a config matching the current render; a declined offer leaves it byte-identical. `[executed-check]`
2. Import: setup on a fixture with prose issues in each standard root lists all of them; an accepted file becomes a tracker issue with inferred labels; a declined file is skipped; the live tracker home and loop-stack's own docs are never listed. `[executed-check]`
3. Ledger: after migration, no migrated file carries a live `state:` line; an accepted removal stages `git rm` of exactly the migrated files. `[executed-check]`
4. Tidy: fixture byproducts are all inventoried; an accepted item is deleted, everything else untouched; nothing deletes without acceptance. `[executed-check]`
5. Render: a github-mode config contains no reference to the stripped Local tracker section. `[executed-check]`
6. Idempotency: re-running setup after all offers are resolved reports nothing to reconcile. `[executed-check]`

## Seams

Blast-radius order; each independently checkable.

1. Stale/keyless config detection and re-render - the map everything else reads.
2. Issue import.
3. Post-migration ledger freeze and removal offer.
4. Dangling render line - rides seam 1's render path.
5. Tidy inventory - fully independent.

## Known vs guessed

- Verified this session: all five gaps in code; the tests/ harness exists; the template has no version stamp today.
- Believed-unchecked: cheap heuristics detect "issue-shaped" markdown with tolerable false positives even under recursive `docs/` scanning; if wrong, import offers get spammy and the definition needs tightening, but nothing corrupts because a human confirms each file.
- Guessed: staleness detection can distinguish an older-template render from deliberate hand edits; if wrong, re-render offers threaten intentional local edits - the shown diff is the guardrail.

## Parking lot

- github -> local reverse-migration cleanup: the issue title says "mode transitions" plural, but only local -> github has a script today; defining and cleaning up the reverse direction is parked for its own backlog issue.

## Out of scope

- A combined replay fixture of the substack-scraper session (declined in favor of per-gap checks).
- Reverse migration (parked).
- Tracker schema changes.
- Auto-judging whether work "looks merged".
- Any behavior change for clean greenfield repos beyond the new checks reporting nothing.

## Open questions for planning

- Staleness-detection mechanism: template version stamp vs diff against the current template's stable sections.
- Precise issue-shaped detection heuristic and the exclusion-list mechanics.
- Where the tidy code lives and its invocation flag.
- How user-supplied extra scan roots are passed.
- The non-interactive answer mechanism for offers (env-var pattern precedent exists).
- Whether the migration freeze rewrites the `state:` line to a frozen marker or strips it.
