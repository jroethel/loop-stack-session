# GitLab (glab) backend support, and loop-setup as a universal normalizer

Date: 2026-08-09
Status: approved brief, ready for /loop-plan

## Outcome

Run loop-stack chains in RIT GitLab repos with the full issue, backlog, mirror, graduation, and wayfinder mechanics intact.
Get consistent project normalization from `loop-setup` regardless of which backend a repo uses.

Presupposition verdict.
The request was framed as "add glab support when the remote url is gitlab".
That was tested against `config/repo-state.md`, which states the backend is declared in the `tracker:` key and that no script infers it from `git remote`.
Resolution: `setup.sh` sniffs the remote and *suggests* `gitlab`, the key is written, and every script obeys the key.
No script sniffs at runtime.
Confirmed by the user.

## End artifact

`/home/jjrdar/claude/forge` running `tracker: gitlab` against `gitlab.code.rit.edu`, with its `whats_next.md` consolidated into real GitLab issues.

forge is currently on `tracker: local` with `Remote: none (local tracker)` recorded in its config, which is false - it has a GitLab remote.
The cause is `setup.sh:46`, which greps the remote list only for `github.com`, so `remote_url` came back empty and `report_remote` printed "No GitHub remote found".
That misconfiguration is the existence proof for this work.

## Done looks like

In `/home/jjrdar/claude/forge`:

```
scripts/tracker.sh mode set gitlab
scripts/tracker.sh list                    # returns forge's GitLab issues
scripts/gen-mirrors.sh .                   # renders ISSUES.md and BACKLOG.md from GitLab
scripts/graduate-parking.sh <brief-path>   # opens real GitLab issues
```

And `loop-setup`, run in forge, walks the user through `whats_next.md` into issues rather than leaving it an orphan file.

Re-running `loop-setup` immediately afterward, with the same answers and nothing else changed, finds nothing to do and says so.
It acts again only when something it depends on has moved: a changed config answer, a bumped config `template-version`, or new candidate content.
(Revised at the bloat review, with the user's pre-authorization: the original sentence also named "a bumped stamp on the setup logic itself", but the setup-logic stamp was cut with the decision ledger - archive-on-import is the idempotence mechanism, and declined-and-left content re-offers by design.)

## Assets and options

Every asset raised in the session, mapped to the option it implies, chosen or declined.

| Asset                            | Implied option                                        | Verdict                                                            |
| ---                              | ---                                                   | ---                                                                |
| `glab` 1.112.0 on PATH           | glab is the gitlab transport                          | Chosen                                                             |
| Auth to `gitlab.code.rit.edu`    | Live end-to-end testing is possible today             | Chosen - live smoke, fired by the user                             |
| Dead `gitlab.com` token          | Bare `glab auth status` exits 1; guard must be scoped | Chosen as a regression test                                        |
| `jq` on PATH                     | Could parse glab JSON with it                         | Declined - the repo is deliberately jq-free, and glab embeds `--jq` |
| `forge` repo                     | The live test target and first consumer               | Chosen                                                             |
| `whats_next.md` (7433 bytes)     | The sweep's first real subject                        | Chosen                                                             |
| Group `university-advancement`   | Cross-repo backlog view via `glab issue list --group` | Chosen - derived from the remote, overridable                      |
| `gh-axi`                         | Alternate GitHub transport                            | Declined - the user's rule now prefers plain `gh`                  |
| `tests/repo-state/` fixtures     | Offline regression coverage for gitlab mode           | Chosen                                                             |
| `migrate-tracker.sh`             | local-to-gitlab migration path                        | Chosen - optional, explained, re-runnable                          |

## Approach

**Chosen: third peer backend.**
`gitlab` becomes a first-class third value everywhere the mode is consulted, exactly as `github` and `local` are today.
It fits the design already committed here, where the backend is declared and never sniffed at runtime.
It is the only option that stays honest for a self-hosted host, whose URL alone cannot be trusted to identify the forge.
The sweep and the migration then become mode-agnostic rather than backend-specific, which is what was asked for.

Inside this approach, one sub-decision: the split-and-merge judgment lives in `loop-setup`'s SKILL.md prose, with the script keeping only the mechanical create calls.
Alternative considered and declined: all-bash triage, fully deterministic and testable, but unable to read a 7.4KB `whats_next.md` and propose sensible issue boundaries.

**Considered: provider abstraction.**
Collapse github and gitlab into one "remote forge" concept, with local as the outlier.
Cheaper to add a fourth forge later, but it refactors working code to introduce an abstraction over exactly two implementations, and it risks the currently-green github path for a benefit with no evidence behind it.
Declined.

**Considered: minimal shim.**
gitlab exists only where it must (issue CRUD), everything else keeps its GitHub assumptions with documented limitations.
Smallest and safest, and it directly contradicts the decision that glab should be an option everywhere `gh` is used.
Declined.

## Success criteria

| #  | Criterion                                                                                                                                                        | Tag                |
| -- | ---                                                                                                                                                              | ---                |
| 1  | `scripts/tracker.sh mode set gitlab` then `mode get` prints `gitlab`; `setup.sh` accepts it as a third answer                                                     | `[executed-check]` |
| 2  | In forge, `scripts/tracker.sh list` exits 0 and emits gh-shaped JSON (`number`, `title`, `labels[].name`, `updatedAt`) translated from glab output                | `[executed-check]` |
| 3  | Live round trip in forge, fired by the user: create an `idea` issue, see it in `list`, see it in BACKLOG.md after `gen-mirrors.sh .`, close it, see it gone       | `[executed-check]` |
| 4  | With the `gitlab.com` token still dead, `tracker.sh list` in forge exits 0 - the guard resolves the host from the remote and never runs bare `glab auth status`   | `[executed-check]` |
| 5  | `setup.sh` in forge reports a GitLab remote and suggests `tracker: gitlab`, where today it prints "No GitHub remote found"                                        | `[executed-check]` |
| 6  | `setup.sh` parses `ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git` and derives backlog group `university-advancement`                     | `[executed-check]` |
| 7  | The import sweep runs in all three modes, offers every candidate, and creates nothing without a per-item confirmation                                             | `[executed-check]` |
| 8  | (revised at the bloat review) A re-run offers nothing for content already imported and archived, and says so; declined-and-left content may re-offer              | `[executed-check]` |
| 9  | (revised at the bloat review) The shipped config `template-version` mechanism re-offers the render when the template moves; the setup-logic stamp was cut         | `[executed-check]` |
| 10 | (revised at the bloat review) Migration is documented and suggested during setup; `scripts/migrate-tracker.sh --to <target>` is the operation, and re-runs safely | `[executed-check]` |
| 11 | wayfinder creates its map issue and a decision ticket in a gitlab repo; its SKILL.md no longer states a github-only requirement                                   | `[executed-check]` |
| 12 | Offline fixture tests cover gitlab mode, and `tests/run.sh` passes                                                                                               | `[executed-check]` |
| 13 | The sweep's proposed split of `whats_next.md` yields issues that each name one actionable item, with no proposal spanning two unrelated items                     | `[judgment]`       |

Criterion 13 stays a judgment after one reformulation attempt.
"One actionable item per issue" is checkable by eye but not by command, and tightening it into a line count or item count would encode a number nobody can justify.

## Seams

Independently checkable pieces, in blast-radius order - wrong at the top invalidates everything below.

1. Mode plumbing and host-scoped auth resolution.
2. glab-to-gh JSON shape translation, independently checkable against one real response; wrong here fails silently rather than loudly.
3. `setup.sh` remote detection, gitlab config render, and gitlab finalize.
4. Sweep ungating plus triage and split/merge guidance; backend-independent, checkable entirely in local mode.
5. Re-run idempotence: a settled repo offers nothing, a version bump offers again.
   Checkable on its own by running `loop-setup` twice with no other change.
6. Migration: optional, standalone re-runnable, gitlab as a target.
7. Doc and skill sweep: wayfinder, loop-improve, loop-review, `config/repo-state.md`.

## Known vs guessed

**Verified this session, by running the command.**
glab 1.112.0 and gh 2.96.0 are on PATH.
Bare `glab auth status` exits 1 on this host while `glab auth status --hostname gitlab.code.rit.edu` exits 0.
glab is authenticated to `gitlab.code.rit.edu` as `jjrdar`; the `gitlab.com` token returns 401.
forge lives at `/home/jjrdar/claude/forge` with remote `ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git`, runs `tracker: local`, records `Remote: none`, has zero files in `docs/issues/`, and has a 7433-byte `whats_next.md`.
`glab issue list --group university-advancement/crm -O json` exits 0 and returns `[]`.
`setup.sh:46` greps the remote list only for `github.com`; `setup.sh:240` gates `reconcile_import` to local mode.
Config-staleness versioning already exists and was designed in `docs/plans/2026-08-07-loop-setup-reconcile-plan.md`: a `template-version: 1` key in `config/repo-state.template.md`, read by `version_of()`, compared by `reconcile_config()` at `setup.sh:133`, which offers a re-render on a mismatch.
That mechanism covers config staleness only; there is no stamp covering the setup logic itself, and `reconcile_import` keeps no record of prior decisions, so it re-offers every candidate on every run.
`is_excluded` at `setup.sh:158` already skips `docs/archive/*`, so a candidate triaged to archive or deleted is invisible on the next run; a candidate left in place is not.
This repo's own `config/repo-state.md` carries no `template-version` line at all - only the template does.
`gen-mirrors.sh` and `graduate-parking.sh` both route through `tracker.sh`; the only other direct `gh` callers are `setup.sh` and `migrate-tracker.sh`.
No prior gitlab or glab reference exists anywhere in the repo outside one unrelated archive dump.
glab provides `issue list`, `issue create`, `issue close`, `issue reopen`, and `label create` with the flags this work needs.

**Believed but unchecked**, each with what breaks if it is wrong.

- glab's `-O json` field names: `iid`, `updated_at`, labels as plain strings, state `opened`.
  This is the single claim that breaks the most - get it wrong and `gen-mirrors.sh` renders empty rows with no error at all.
  Criterion 3 exists specifically to kill this guess.
- `--per-page` caps at 100, where `gh issue list` accepted `--limit 1000`.
  If true and unhandled, mirrors silently truncate past 100 open issues.
- `glab issue create` prints a URL whose last path segment is the iid, which is what `tracker.sh:162` assumes with `${url##*/}`.
  If not, `create` returns a garbage issue number.
- `glab label create` behavior when the label already exists.
- GitLab label syntax for wayfinder's `wayfinder:map`, given GitLab's scoped-label `::` convention.

**Guessed.**
That RIT projects generally sit under one top-level group.
The user named `university-advancement` as their particular case, so deriving the first remote path segment is a convention, not a fact.

## Parking lot

- github-to-gitlab data migration.
  Restart context: the other direction of the migration matrix, deliberately not built in this pass; local-to-gitlab is in scope, github-to-gitlab is not, because it means reading source issues via `gh`, remapping numbers, and breaking every `#N` reference in commits and ROADMAP.

- Explicit multi-host support beyond the single RIT instance.
  Restart context: anything past what host resolution from the remote gives for free; at brief time the `gitlab.com` token on this host was dead and `gitlab.code.rit.edu` was the only live target, so multi-host was never exercised.

## Out of scope

Runtime sniffing of `git remote` to pick the backend; the key is declared and obeyed.
`gh-axi` as a transport.
Any forge beyond github and gitlab.
Migrating issues off GitHub.

## Open questions for planning

- Does the JSON translation live in `tracker.sh`, or lean on glab's built-in `--jq`, which adds no dependency.
- Which number is the issue number: `iid` or `id`.
- Pagination strategy past 100 open issues.
- Does the backlog group become a line-anchored key in `config/repo-state.md`, or is it derived on every call.
- Does the split/merge guidance live in `loop-setup/SKILL.md` or in a reference file.
- How the standalone migration re-run is surfaced: a script invocation, or a `loop-setup` step.
- Whether forge's incorrect `Remote: none` line is fixed by the mode flip or needs its own correction.
- Whether a "leave in place" triage decision needs a recorded marker to stay quiet on re-run, or whether leaving means re-offering by design.
- Whether the setup-logic stamp is a second version key or an extension of `template-version`.
- Whether this repo's own missing `template-version` line is backfilled as part of this work or left to the next `loop-setup` run here.
