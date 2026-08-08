# Brief: loop-stack plumbing hardening (audit sweep, 2026-08-08)

Source: the 2026-08-08 /loop-improve audit; all eight findings selected.
Supersedes: #11 (finding 8 below is the same work as that issue's ask).

## Outcome

The loop-stack's plumbing keeps its own documented promises everywhere it is installed: parking-lot graduation, lane listing, migration, autonomy reads, and handoffs behave as the docs say in every target repo, and one command verifies the whole repo.
Presupposition verdict: no user hypothesis was embedded - this brief originates from an audit, and every load-bearing finding was re-derived by a second route (gh --help output, greped call sites, traced code paths, the fetched #11 body) before selection.

## End artifact

A green one-command test run over a suite that exercises all eight fixed behaviors.
The runner itself is the first deliverable, because every later fix lands with its check plugged into it.

## Done looks like

- One command runs every suite under `tests/` and exits 0 only when all pass.
- In a fresh target repo after loop-setup, parking-lot graduation works (the script the skills invoke exists there).
- `scripts/tracker.sh list` returns every open issue in a repo with more than 30.
- `scripts/migrate-tracker.sh` migrates unlabeled local issues (the Issues lane's defined shape).
- Re-running loop-setup in a target repo whose vendored scripts have drifted from loop-stack's offers a refresh.
- `loop-auto.sh get` and `loop-auto.sh status` agree on every chain-state shape, including a keyless file.
- A handoff in a repo without `config/repo-state.md` lands in the project, not `/tmp`.
- README describes loop-improve's selection as multi-finding.

## Assets and options

- The 2026-08-08 audit findings table: this brief's source; all eight rows selected.
- Open issue #11: superseded by finding 8; closed at brief time per the loop-improve supersede rule.
- The existing `tests/` suites (25 scripts in 5 dirs): extended, never replaced.
- The documented ponytail ceilings (`tracker.sh:35`, `gen-mirrors.sh:50`): declined - by-design simplifications, not findings.

## Approach

Chosen: fix-in-place per finding - each finding fixed at its named location, runner first as the shared verification baseline.
Considered: resolve-from-skill redesign (stop vendoring scripts into target repos, which dissolves findings 1 and 5 structurally) - rejected because it reverses a deliberate recorded decision (`setup.sh:50-52`: the regen command the config declares must be true locally, not a dangling pointer to loop-stack) and its blast radius spans every SKILL.md naming `scripts/`.
Considered: bugs-only minimal pass (findings 1, 2, 7) - rejected because the selection gate already chose all eight, and narrowing after an ASK is silent scope narrowing.

## Success criteria

1. `[executed-check]` After loop-setup runs in a fresh target repo, the graduation script the skills invoke exists there and is executable, and a dry-run graduation of a parking-lot fixture succeeds (evidence: `skills/loop-setup/setup.sh:53-64` installs only gen-mirrors and tracker today; call sites `skills/loop-brainstorm/SKILL.md:185`, `skills/loop-improve/SKILL.md:83`).
2. `[executed-check]` The github branch of `tracker.sh list` fetches beyond gh's default 30-issue page, proven by a check that fails on the current code (evidence: `scripts/tracker.sh:142`; `gh issue list --help`: default 30).
3. `[executed-check]` One command discovers and runs every `tests/*/*.sh`, exits non-zero when any fails (proven by a deliberately failing probe), and exits 0 on the current suite (evidence: 25 scripts, no runner; only `tests/gates/check.sh` is wired, `install.sh:159`).
4. `[executed-check]` First verify gh's behavior on an empty `--label` argument, then: a dry-run migration of an unlabeled local issue emits a create command with no empty label, and a real-path test covers it (evidence: `scripts/migrate-tracker.sh:60`; unlabeled is the Issues lane's defined shape, `config/repo-state.md:30`; `tests/repo-state/migrate.sh` covers labeled fixtures only).
5. `[executed-check]` Re-running loop-setup in a target repo whose vendored scripts differ from loop-stack's current ones detects the drift and offers an assented refresh; declining leaves the files untouched (evidence: `setup.sh:53,61` skip-if-exists; config gets a staleness reconcile at `setup.sh:110`, scripts get none).
6. `[executed-check]` No line of `README.md` describes loop-improve's selection as a single finding (evidence: `README.md:35,75` vs the multi-finding Step 4 shipped in commit 0e80f18).
7. `[executed-check]` With `docs/chain-state.md` present but missing the `autonomy:` key and a committed repo default of `auto`, `get` and `status` report the same effective mode (evidence: `skills/loop-auto/loop-auto.sh:37` vs `:48-58`).
8. `[executed-check]` A handoff in a repo with no `config/repo-state.md` writes inside the project, and `tests/handoff/location.sh` proves the non-conforming path (evidence: `skills/handoff/SKILL.md:11` covers only the conforming path; issue #11 states the /tmp behavior).

## Seams (blast-radius order)

1. The test runner (criterion 3) - the baseline every other seam's check plugs into.
2. loop-setup distribution (criteria 1 and 5) - one file (`setup.sh`), two findings; fixing 5 is also the propagation path for every other script fix.
3. tracker list completeness (criterion 2) - `scripts/tracker.sh`.
4. Migration of unlabeled issues (criterion 4) - `scripts/migrate-tracker.sh`, investigation first.
5. loop-auto fallback agreement (criterion 7) - `skills/loop-auto/loop-auto.sh`.
6. Handoff non-conforming fallback (criterion 8) - `skills/handoff/SKILL.md`.
7. README selection wording (criterion 6) - prose only, zero blast radius.

## Known vs guessed

- Verified this session: gh's 30-issue default (`gh --help` output); setup.sh installs exactly two scripts (read); the README lines (greped); the get/status divergence (both branches traced); 25 test scripts and no runner (counted and greped); #11's body (fetched).
- Believed, not checked: gh rejects an empty `--label` argument (criterion 4 verifies this first; if gh tolerates it, the fix degrades to a harmless guard and the criterion still holds).
- Guessed: target repos already exist with stale vendored scripts (finding 5's present-day impact); if none exist yet the fix is still cheap insurance, so nothing in this brief breaks if the guess is wrong.

## Parking lot

(empty - all eight audit findings converged into this brief, and no unselected uncovered findings remain)

## Out of scope

- No redesign of the vendoring convention (approach B was considered and rejected above).
- No deep audit of the wayfinder, loop-drive, loop-review, or loop-which prose - out of this audit's standard-effort coverage.
- No new features from the open backlog ideas (#13, #14, #6, and peers stay parked by decision).

## Open questions for planning

- Runner name and home under `tests/`, and whether it reuses the existing per-dir script shapes as-is.
- Drift-detection mechanism for vendored scripts: content compare versus a stamped version key.
- The handoff fallback location for non-conforming repos (#11 asks for the project home; exact spot is planning's call).
- Whether the tracker list fetch bound is a fixed high constant or reads pagination - a constant is acceptable.
