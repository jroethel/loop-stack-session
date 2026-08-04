# Brief: tracker mode - 100% github or 100% local, never a mix

Date: 2026-08-03
Source: issue #8 (loop-setup tracker mode), brainstormed 2026-08-03.

## Outcome

A repo's issue tracker is an explicit, declared choice - `tracker: github` or `tracker: local` - and every loop-stack script obeys the declaration instead of guessing from remote detection.
Presupposition verdict: the issue's named mechanism (line-anchored key, mode-specific script behavior) survived the probes; the driver is killing the mixed-assumption bug class, and a declared key is the minimal mechanism that does it.
Both modes carry the same workflow (issues, backlog, mirrors, graduation, parking-lot flow); local mode's inherent gaps are disclosed, not papered over.

## End artifact

No specific deliverable is waiting on this; the driver is engineering soundness (stated honestly per the meta-tooling probe).
First real consumer: the next project deliberately kept off GitHub - these cases do happen - which gets the full loop-stack workflow instead of a degraded half-fallback.

## Done looks like

In any repo, `skills/loop-setup/setup.sh` (or the installed skill) asks the tracker mode once on first run or when the key is missing.
It reports whether a GitHub remote was found, suggests `tracker: github` when one exists, never assumes local, and never re-asks once the key is rendered.
A keyless legacy config is a legitimate re-ask, not a silent inference.
Same commands in both modes, backend decided by the key: `scripts/gen-mirrors.sh .` regenerates ISSUES.md/BACKLOG.md; `scripts/graduate-parking.sh <brief>` graduates parked items.
`tracker: github` with no gh auth fails fast with a clear message; with no remote, it offers `gh repo create --private`.
`tracker: local` makes zero gh invocations anywhere, verifiable by running the whole workflow in a sandbox with gh absent.
`tests/loop-setup/acceptance.sh` and `tests/repo-state/*` pass, extended to cover both modes.

## Assets and options

| Asset                                 | Implied option                                       | Verdict                     |
| ---                                   | ---                                                  | ---                         |
| gh CLI, installed + authed            | Hard prerequisite of github mode, checked fail-fast  | Chosen                      |
| `gh repo create --private`            | Offered when github mode chosen but no remote        | Chosen                      |
| `autonomy-default:` key convention    | `tracker:` copies the same line-anchored pattern     | Chosen                      |
| `gen-mirrors.sh` fixture hook         | Renderer is source-agnostic; local source slots in   | Chosen                      |
| `graduate-parking.sh`                 | Grows a local write path in local mode               | Chosen                      |
| `.scratch/<feature>/issues/` fallback | Keep as the local tracker root                       | Declined - see note         |
| wayfinder                             | Local-mode variant                                   | Declined - disclosed limit  |
| Cross-repo `gh search issues` view    | Local repos participate somehow                      | Declined - disclosed limit  |
| Existing bash test harness            | Success criteria as executed-checks in that style    | Chosen                      |

Declined-scratch note: scratch implies disposable; a declared tracker is durable and committed.
Declined cross-repo note: a shared index inherently needs a remote; local mode discloses the limitation instead.
Declined wayfinder note (2026-08-03): wayfinder's data model is issue-shaped end to end; a map-as-file variant carries most of this brief's skill-prose cost for an unlikely consumer, so wayfinder requires `tracker: github` as a disclosed limitation, promotable later if a local repo needs a map.

## Approach

Chosen: two declared modes, one key; each script does a one-line mode read; github mode sheds fallback code, local mode becomes a real tracker.
Considered: github-only hard fail - declined because gh-excluded projects deserve the full workflow.
Considered: local-as-truth with github as a sync layer - declined because it inverts source-of-truth, breaks gh-native workflows, and forces migration of every existing repo.
Rationale recorded at decision time: the bug class dies by construction when no script can guess, and existing seams make the local lane cheap.
Parity bar (user decision): disclosed limitations, not true parity - cross-repo idea search skips local repos, wayfinder requires `tracker: github`.

## Success criteria

1. Fresh-repo setup in each mode renders a config containing the line-anchored `tracker:` key; a second run exits 0 without re-asking or duplicating content. `[executed-check]`
2. Re-run against a keyless legacy config asks the mode, and its output reports remote-found or no-remote, suggesting `tracker: github` only when found. `[executed-check]`
3. `tracker: github` with gh unauthenticated or absent exits non-zero fail-fast with a message naming the prerequisite. `[executed-check]`
4. The full local-mode workflow - setup, create issues, regenerate mirrors, graduate a brief's parking lot - runs to exit 0 in a sandbox where gh is not on PATH, and ISSUES.md/BACKLOG.md render from the local files with labels intact. `[executed-check]`
5. Rendered local-mode config discloses both limitations (invisible to cross-repo idea search; wayfinder requires `tracker: github`), grep-verifiable. `[executed-check]`
6. Migration local -> github is lossless: every local issue file becomes a GitHub issue with title, body, and labels preserved, dry-run comparable. `[executed-check]`

No `[judgment]` criteria survived reformulation; "wayfinder works locally" was declined (2026-08-03) and became criterion 5's disclosure.

## Terminology

"Graduation" means parking-lot to backlog only.
Local tracker to GitHub is "migration"; the two words stay distinct downstream.

## Seams

Blast-radius order:

1. The `tracker:` key: setup asks/reports/renders it; legacy keyless configs re-ask; scripts read it.
2. Github-mode hardening: fail-fast auth, `gh repo create --private` offer, fallback code path deleted.
3. Local tracker core: frontmatter-labeled issue files, mirrors rendered from them, graduation writing them.
4. Migration local -> github.

## Known vs guessed

Verified:

- `gen-mirrors.sh` is already source-agnostic via the `MIRRORS_JSON_FILE` fixture hook.
- `graduate-parking.sh` and wayfinder are gh-native today, so the mixed-assumption bug class is real.
- The `autonomy-default:` line-anchored key convention exists with a working read/write pattern (`loop-auto.sh`).
- The bash acceptance-test style exists under `tests/`.

Believed-unchecked:

- The gh-touching surface is exactly loop-setup, gen-mirrors, graduate-parking, wayfinder, plus gh commands quoted in prose (repo-state.md, loop-brainstorm's `gh issue close`).
- Planning must audit; a missed script keeps the bug class alive.

Guessed:

- No existing repo currently lives on the `.scratch` fallback, so no one-time rescue is needed.
- If wrong, those repos need a migration step added to the plan.

## Parking lot

None - no new threads surfaced during this brainstorm.

## Out of scope

Cross-repo search participation for local repos.
A local-mode wayfinder (map-as-file); wayfinder requires `tracker: github`.
Any hybrid or sync mode.
Github to local demotion.
Auto-switching an existing repo's mode without the user answering the question.
Hooks or daemons.

## Open questions for planning

- Does `gen-mirrors.sh` grow a local reader or gain a sibling script?
- Local issue file location, naming, and number-assignment scheme (durable and committed, per the declined-scratch verdict).
- How setup asks the mode question interactively while staying testable (answer hook).
- Local equivalents of issue lifecycle verbs (close, reopen) and of the `gh issue close <num>` graduation-reversal.
- Does `tracker:` get a read/write helper like `loop-auto.sh default`?
- Full audit pass for stray gh assumptions in scripts and skill prose.
