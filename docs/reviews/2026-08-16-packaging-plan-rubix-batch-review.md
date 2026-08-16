# Batch review - packaging plan (Rubix + autonomy gate journal)

Run: /loop-plan on `docs/briefs/2026-08-16-packaging-brief.md`, autonomy = auto (session).
Plan under review: `docs/plans/2026-08-16-packaging-plan.md`.
Rubix lenses: A = Opus (impacted professional, operator-maintainer seat); B = Fable (cold craft read), per the user's "use fable for B role".
User directive: "accept all recommendations and log them" - the Step 6 triage BATCH gate was pre-resolved to accept-all; every finding below is incorporated and logged.

## Gate journal (chronological)

| # | Gate    | Decision                                                        | Rationale                                              | Reversal path                          |
| - | ---     | ---                                                             | ---                                                    | ---                                    |
| 1 | ASK     | Step 2 open questions: param home, version, clean room, render  | Human answered live; all four took my recommendation   | n/a - resolved live                    |
| 2 | DEFAULT | Ran the Rubix review (both lenses)                              | User asked for it explicitly                            | n/a - read-only review                 |
| 3 | BATCH   | Accept ALL Rubix findings and revise the plan                  | User pre-directed "accept all recommendations"          | Revert the plan edits; re-run Step 6   |

## Triage table (all findings, most-severe first)

| ID  | Lens | Sev     | Finding (condensed)                                                          | Verdict | Reason                                                        |
| --- | ---  | ---     | ---                                                                          | ---     | ---                                                           |
| B1  | B    | blocker | Sweep `REPO` ascends one level, resolves to `tests/`, scans only `tests/`    | revise  | Confirmed by run: 1 file from tests/ vs 22 from root         |
| A1  | A    | high    | Negative tests don't unset `LOOP_STACK_SKILL_STYLE`; exported var leaks in   | revise  | Operator exports the var; spurious guard failure             |
| A2  | A    | high    | `config.toml` renders only-if-absent; host.env root edit silently no-ops     | revise  | Param-home edit never reaches an existing render             |
| B2  | B    | high    | H2 ignores a pre-existing stale `config.toml` on host 2 (wrong bins kept)    | revise  | Never-clobber preserves old absolute bins; green but broken  |
| A3  | A    | medium  | host.env created only-if-absent; new template keys don't propagate           | revise  | Write-once dotfile drift across hosts and months             |
| A4  | A    | medium  | host.env sourced under `set -u`; a typo aborts cryptically                   | revise  | The one hand-edited file; opaque abort on human error        |
| A5  | A    | medium  | Floating-version default `main` warns on every healthy ahead/detached HEAD   | revise  | Noise trains the operator to ignore doctor output            |
| B3  | B    | medium  | Sweep pattern misses the `~/repos/ringer` literal named in brief criterion 5 | revise  | Accepted; pattern extended, allowlist broadened (see note 1) |
| B4  | B    | medium  | Sweep `PASS`es vacuously in a non-git tree (`git grep 2>/dev/null` swallows) | revise  | False-green generator; add work-tree guard                   |
| B5  | B    | medium  | Tests don't sanitize inherited `LOOP_STACK_*` env                            | revise  | Same class as A1; unset all three at test top                |
| B6  | B    | medium  | Task 1 commit leaves installer copying a literal `.template`; no run.sh gate | revise  | Every commit should be shippable (quota-death resume risk)   |
| A6  | A    | low     | Two-step new-host bootstrap (create then refuse) undocumented in README      | revise  | New-host operator hits a refusal with no local doc           |
| A7  | A    | low     | Allowlist pre-approves whole living-doc dirs (plans/briefs/memos)            | revise  | Documented as a deliberate limitation (see note 2)           |
| B7  | B    | low     | Clean-room bare `git commit` relies on git-ident auto-detect                 | revise  | Env-dependent false red on hosts without a global ident      |
| B8  | B    | low     | `sed` render corrupts on paths containing `|`, `&`, or `\`                   | revise  | Silent render defect; guard before the public phase          |
| B9  | B    | low     | Allowlist had four no-hit root-file entries                                  | revise  | Superseded by B3 - extended pattern gives them real hits     |
| B10 | B    | low     | `acceptance.sh` discards installer output; failures undebuggable            | revise  | A red on host 2 is undebuggable without editing the test     |

Every finding: verdict revise (user pre-accepted all). None dismissed.

## Notes on findings applied with an implementation adjustment (flagged for veto)

Note 1 - B3 (sweep pattern extension).
The finding's literal fix (`\$HOME/repos/ringer` in the pattern) would flag `install.sh`'s legitimate portable fallback default, which is not a hardcode.
Accepted intent instead: the pattern gains the tilde form `~/repos/ringer` (the brief's exact wording), and the allowlist broadens to the legitimate convention homes (`install.sh`, `README.md`, `skills/`, `diagrams/`, `config/host.env.template`) plus the historical records.
Verified against the tree: under the extended pattern the only hits outside the broadened allowlist are `config/ringer/config.toml` and `tests/loop-setup/gitlab-setup.sh`, both fixed by Task 1, so the sweep passes.
Cost: a broader allowlist, so the sweep's precision on those paths drops.
This supersedes B9 - under the extended pattern the previously "no-hit" root files now carry real `~/repos/ringer` hits, so their allowlist entries are load-bearing and stay.

Note 2 - A7 (living-doc allowlist breadth).
`docs/plans/`, `docs/briefs/`, `docs/memos/` are allowlisted as whole prefixes, so a host literal newly pasted into a future plan/brief/memo passes the sweep.
Accepted as a documented limitation: a comment on the ALLOW array names these as historical-record prefixes by design.
Left reversible - narrow to dated-file globs later if a literal ever creeps back through an authoring path.

## Post-revision

Plan revised incorporating all 17 findings; loop-plan Step 5 self-review re-run against the revised plan.
