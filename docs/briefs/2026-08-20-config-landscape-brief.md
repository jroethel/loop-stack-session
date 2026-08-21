# Config landscape refactor - brief (backlog #38)

Date: 2026-08-20
Source: backlog #38 - "Refactor the config landscape - repo-state.md has accreted schema keys, lane tables, archive rules, and prose; restructure config/ deliberately."
Pulled from the Backlog lane by explicit user decision per the scope rule.

## Outcome

Every addition to the loop-stack config landscape has a self-evident home, because the landscape is structured by audience instead of by accretion.
Co-benefits, in priority order behind that: machine-read schema is separated from agent-read doctrine, and a fresh agent orients faster.
Presupposition verdict: the issue's accretion diagnosis is verified - git history shows 13 changes to `config/repo-state.md` in 16 days (2026-08-02 to 2026-08-18), each a small (1-6 line) addition with no declared home.

## End artifact

Template v4: the two-file config shape staged in loop-stack, with this repo's own instance restructured to match.
Target repos pick up the v4 re-render offer on their next setup run; driving those re-renders is delivered as a close-out handoff doc, not part of this stream.

## Done looks like

- `scripts/lifecycle-lint.sh .` exits 0 in this repo on the restructured layout.
- The existing suites under `tests/repo-state/` and `tests/loop-setup/` pass.
- `scripts/tracker.sh mode get` and `skills/loop-auto/loop-auto.sh default get` return correct values from the restructured files.
- A v2-era repo fixture receives a v4 re-render offer whose accepted result preserves `tracker:`, `Remote:`, and any `autonomy-default:` / `tracker-remote-ack:` keys.
- The placement table exists and is the first thing an agent adding config prose encounters.
- `docs/handoffs/YYYY-MM-DD-config-v4-target-roll.md` exists at issue close, naming the 5 target repos and the exact per-repo re-render step, so any later session can run one repo's roll without re-deriving context.

## Assets and options

| Asset                                     | Option it implies                | Verdict                        |
| ---                                       | ---                              | ---                            |
| template-version re-render mechanism      | Migration rides a v3-to-v4 bump  | Chosen                         |
| lifecycle-lint                            | Home for mechanical enforcement  | Chosen                         |
| context-map.md precedent (#34)            | Same split move, applied once    | Chosen (content untouched)     |
| loop-molt bins (plumbing/policy/premise)  | Lens for classifying each block  | Chosen for the sorting pass    |
| 5 target repos (vaultwise, pokemine,      | Drive their re-renders now       | Declined - staged offer plus   |
| iamawriter, substack-scraper,             |                                  | close-out handoff doc          |
| ai-benchmark; all github, v2 or none)     |                                  |                                |

## Approach

Chosen: A - split by audience.
`repo-state.md` keeps the machine-read surface (line-anchored keys, Lanes table); all doctrine prose moves to one sibling convention doc, vendored alongside, each pointing at the other; the placement table lives in the convention doc and covers the full config/ landscape.
Enforcement decision: written placement rule plus mechanical lint only - lint guards parseable keys and resolving pointers, placement judgment stays prose.

Considered: B - one file, zoned (smallest migration, but re-solves the junk drawer with discipline instead of structure).
Considered: C - hub and spokes (strongest homes, but over-factored at a handful of additions per month).
Rationale at decision time: the two audiences have different change cadences - keys are near-frozen while doctrine evolves - so splitting them makes target-repo re-render diffs small and safe while prose evolves without touching what parsers grep; it repeats the proven #34 move exactly once, then stops.

## Success criteria

- `[executed-check]` `scripts/lifecycle-lint.sh .` exits 0 in this repo after the restructure.
- `[executed-check]` `tests/repo-state/` and `tests/loop-setup/` suites pass.
- `[executed-check]` all six machine keys (`template-version:`, `Remote:`, `backlog-group:`, `tracker:`, `autonomy-default:`, `tracker-remote-ack:`) parse from their declared file: `tracker.sh mode get` and `loop-auto.sh default get` cover the first two directly, and the setup.sh render/reconcile tests cover the remaining four.
- `[executed-check]` a v2-era fixture accepts a v4 re-render that preserves its keys (existing reconcile/idempotence tests reused or extended).
- `[executed-check]` a grep audit shows no script reads config prose from a file other than its declared schema source.
- `[executed-check]` the close-out handoff doc exists and names all 5 target repos with their roll step.
- `[judgment]` the placement table's homes are unambiguous - the next real addition lands without debate about where it goes.
  Reformulation attempted ("next addition edits only its declared home") is future-dependent, so the judgment tag stays.

## Seams

Blast-radius order:

1. Classification pass - every block of the current `repo-state.md` binned (machine / doctrine / dead) via the molt lens; checkable: every line accounted for.
2. Target shape + placement table agreed on paper.
3. This repo's instance restructured, consumers and pointers updated; lint and tests check it.
4. Template v4 and the setup.sh render/re-render path for the two-file shape; tests check it.
5. Close-out: handoff doc for the target roll.

## Known vs guessed

- Verified this session: the accretion history (git log run); the six machine keys and their parsing scripts (grepped); 5 target repos at v2/none, all github mode (each file read); the re-render mechanism in setup.sh (read).
- Believed, unchecked: the greps found all prose consumers of repo-state sections - a citation phrased without the filename would hide; if wrong, a dangling reference survives the move.
- Believed, unchecked: `graduate-parking.sh` reads the graduated-item issue template out of `repo-state.md` - a script consuming a prose block, and it must follow wherever that template lands.
- Guessed: steady-state addition rate is a handful per month; if the rate stays sprint-high, the chosen enforcement level may want revisiting toward a stronger lint.

## Parking lot

(empty - the target-repo roll moved into Done looks like as the close-out handoff deliverable)

## Out of scope

- context-map.md content - settled by #34; only pointer targets update if artifacts move.
- Driving the target-repo re-renders - delivered as a handoff doc, executed later.
- Aggressive structural lint (unknown-section flagging) - declined at the enforcement decision.
- Any tracker, mirror, or autonomy semantics change - this is a pure restructure.

## Open questions for planning

- Name and home of the convention doc (config/ vs docs/).
- Whether host.env, ringer/, routing/ physically move or only receive declared homes in the placement table.
- How setup.sh versions and renders two vendored files (single template-version vs per-file).
- Which skill prose references cite repo-state sections and need pointer updates.
- Where graduate-parking.sh sources the issue template after the split.
