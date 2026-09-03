# I52 Obsidian Board MVP - End-to-end integration runbook

Task 5 of docs/plans/2026-09-02.I52.obsidian-board-mvp-plan.md, executed in place on Jeremy's Mac against the real Cortex vault and scan roots.
This file records the commands run and their observed results for brief success criteria 1-7; criterion 8 (human glance) is deferred to the single end-of-run checkpoint.

## Environment of record

| Variable          | Value                                                             |
| ---               | ---                                                              |
| LOOP_BOARD_CORTEX | /Users/jjrdar/Documents/_CS_DOCUMENTS_/Obsidian/Cortex           |
| LOOP_BOARD_HOME   | <CORTEX>/00_System/Board                                          |
| LOOP_BOARD_ROOTS  | ~/create ~/projects ~/repos                                       |
| LOOP_BOARD_OWNER  | jroethel                                                         |
| LOOP_BOARD_CSS    | auto-set to 1 by board.sh (spike recorded CSS-needed: yes)        |

Host: Jeremy's Mac, Obsidian 1.13.7 running during the run.
Render date: 2026-09-03.
Seven full `scripts/board.sh` renders were executed (labelled R1-R7); each captured the git status of all discovered repos and a Cortex file manifest before and after.

## Result summary

| # | Criterion                                            | Result                                    |
| - | ---                                                  | ---                                       |
| - | tests/run.sh (four board suites)                     | pass (56 suites, 0 failed)                 |
| 1 | one command renders; every repo appears              | pass (28 repos, all carded)                |
| 2 | uncommitted/unpushed flagged, no network             | pass (clean -> flagged -> clean)           |
| 3 | tracker card moves column on label change            | pass (next-up -> in-session -> next-up)    |
| 4 | negative join, distinct cards                        | pass (number 7 -> 3 distinct cards)        |
| 5 | re-render replaces card notes only, git untouched    | pass (git identical, only home + snippet)  |
| 6 | broken source renders failed, never zero             | pass (exactly one failed card)             |
| 7 | resume prompt present, derived-only                  | pass (94/94 cards, repos untouched)        |
| 8 | glance test in Obsidian                              | DEFERRED to end-of-run human checkpoint    |

## Test suite

Command: `bash tests/run.sh`
Result: `ran 56 suites: 56 passed, 0 failed`.
The four board suites all passed: `tests/board/spike-artifacts.sh`, `tests/board/discovery.sh`, `tests/board/cards.sh`, `tests/board/render.sh`.

## Criterion 1 - one command renders, every repo appears

Command: `scripts/board.sh` (render R1), preceded by `scripts/board.sh discover`.
Find-based expected count: `find <root> -maxdepth 3 -name .git -type d` over the three roots returned 51 git repos (create 19, projects 8, repos 24).
Repos seen (his-work filter admitted): 28 (8 conforming, 20 non-conforming).
The 23-repo gap is entirely clean, non-jroethel-owned, non-conforming third-party clones, each correctly excluded by the his-work filter; no jroethel-owned repo was dropped (verified by classifying every excluded repo's owner, uncommitted count, and conformance).
Every one of the 28 included repos has at least one card note (checked by matching each `repo_key` against `^repo:` in the board home): zero repos with no card.
Card notes written: 94 (67 tracker source, 27 git source).
Conforming repos carry tracker cards; non-conforming repos carry a `health: degraded` git card.
`_health.md` recorded tracker `ok` for all 8 conforming repos, git `ok: 7, degraded: 20`, and the discovery skip counts (96 create, 24 projects, 210 repos).
Git card total 27 = 20 non-conforming + 8 conforming minus 1 suppressed (create/skills/rubix-review, a clean conforming repo with tracker cards, git card correctly suppressed).

## Criterion 2 - uncommitted flagged, no network

Probe repo: `create/arscontexta` (clean, non-conforming, jroethel-owned; always gets a degraded git card).
The plan suggested the T5 worktree itself, but a linked worktree's `.git` is a file, not a directory, so board.sh's `find -name .git -type d` never discovers it; a discovered jroethel-owned repo was used instead per the granted "repo of your own choosing" (see Deviations).
Before: git card `position: "clean"`, `git status --porcelain` line count 0.
Action: `echo scratch > create/arscontexta/SCRATCH_I52_PROBE`, then re-render (R4).
After: git card `position: "1 uncommitted"`.
Action: `rm create/arscontexta/SCRATCH_I52_PROBE`, then re-render (R5).
After: git card `position: "clean"`; repo fully restored (porcelain line count 0).
No network for the git flag: `grep 'git fetch'` across all three board scripts returns only the comment "this script never runs git fetch"; the git signals use local plumbing only (`git ... status`, `rev-list`, `rev-parse`, `log`).
The tracker (`gh`) call is the only network in the pipeline and is unrelated to the git flag.

## Criterion 3 - tracker card moves column on label change (decision 24 live round-trip)

Subject: issue #52 in create/loops/loop-stack-session, card `create/loops/loop-stack-session#I52`.
Prior state: no `agent:` label, card `column: next-up`.
Action: `scripts/tracker.sh status 52 working`, re-render (R2) -> card `column: in-session`.
Action: `gh issue edit 52 --remove-label agent:working` (restore to the exact prior no-label state), re-render (R3) -> card `column: next-up`.
Live label verified empty after restore; issue #52 returned to its prior state.
This exercises plan decision 24's live `agent:working` round-trip on #52.
`tracker.sh status` has no "clear to no label" verb, so the restore removes the label directly with `gh issue edit`; this is the only tracker mutation and it is fully reversed.

## Criterion 4 - negative join, distinct cards

Two similarly numbered items from different repos render as distinct cards because `card_id` embeds `repo_key`.
Concrete example: number 7 (token `B7`) renders as three distinct card notes:
`create-loops-loop-stack-session-B7.md`, `create-substack-scraper-B7.md`, `create-vaultwise-B7.md`.
No merge occurs; each card is owned by its own repo.

## Criterion 5 - re-render replaces card notes only, git untouched

Every render (R1-R7) captured `git status --porcelain` (hashed) for all 28 discovered repos before and after.
Result: byte-identical across all 28 repos on every render; the render mutates no scanned repo.
Cortex changes outside the board home were captured as a file manifest (path, size, mtime) before and after each render.
On R1 the only board.sh write outside the board home was the sanctioned one-time CSS snippet `<CORTEX>/.obsidian/snippets/loop-board.css`.
The only other outside-home diff observed on R1 was `<CORTEX>/.obsidian/workspace.json`, which is Obsidian's own file rewritten by the running app, not by board.sh (it did not recur on the later renders).
On R2-R7 there were no changes outside the board home at all.
Snippet created once: hash `6b716d0a60d6e493e3f65bb618c52ce4e623defe` on R1, byte-identical on R2-R7 (create-if-absent, never refreshed).
Atomic re-render verified live: R6's failed-tracker card was pruned by R7 and the board returned to 94 cards, confirming old notes are pruned only after replacements exist and `.staging` is cleaned up (no `.staging` left behind).

## Criterion 6 - broken source renders failed, never zero

Command: `TRACKER_CMD=/tmp/i52-failstub.sh scripts/board.sh` (render R6).
Stub scope: exits non-zero only for the `*/loop-stack-session` PWD and returns a valid empty array for every other repo, so exactly one repo scope's tracker source fails.
Result: create/loops/loop-stack-session contributed exactly one card `create/loops/loop-stack-session#tracker` with `health: failed`, `column: next-up`, `title: "create/loops/loop-stack-session tracker unavailable"`.
Exactly one card for that scope, never zero and never many.
`_health.md` recorded `create/loops/loop-stack-session: failed`.
R7 (clean re-render) restored the real tracker cards and `_health.md` returned that repo to `ok`.

## Criterion 7 - resume prompt present, derived-only

All 94 card notes carry a `Resume:` block (checked: zero card notes without one).
Sample (tracker card #52):

```
Resume: create/loops/loop-stack-session  I52
State: next-up | clean | last work 2026-09-03 (band 1)
Entry: /loop-drive
Next: cd /Users/jjrdar/create/loops/loop-stack-session && git log --oneline -5 && git status ; read config/context-map.md
```

Generating the resume prompt changed nothing in any repo: per criterion 5's capture, `git status` was byte-identical before and after every render.
The prompt is derived text; its `Next:` line is a suggested command, not executed by the render.

## Criterion 8 - human glance (DEFERRED, not blocking)

Deferred to the single end-of-run human checkpoint: Jeremy opens the board in Obsidian and confirms the glance test (8 kanban-style columns, distinguishable colors, "what needs me" legible without opening a repo), and confirms the emoji-band cue.
The spike (docs/spikes/2026-09-02.I52.board-bases-spike-findings.md) recorded a programmatic PASS on the kanban geometry but marked the human visual glance unverified-by-human because screenshot capture was unavailable on this host.
The three MVP-empty columns (`done`, `blocked-on-fact`, `handed-off`) are expected to render empty and are not a defect: `done` has no reachable open-issue source, and the other two are deferred session-card sources (seam 1).

## Deviations

- Scratch probe target: the plan parenthetical suggested the T5 worktree itself, but a linked worktree's `.git` is a file (not a `.git` directory), so board.sh's `find -name .git -type d` never discovers it and it cannot render a card. The granted "repo of your own choosing under the scan roots" was exercised with create/arscontexta (clean, non-conforming, jroethel-owned) using a throwaway file created and deleted. Blast radius is one reversible untracked file, fully removed.
- board.sh EXIT-trap warning: every render printed `scripts/board.sh: line 105: skips: unbound variable` to stderr. This is cosmetic - the render exits 0, the skip counts reach `_health.md` correctly, and the only effect is that the temporary skip-count file is not cleaned up on exit. The cause is the `trap 'rm -f "$skips"' EXIT` in `cmd_pipeline` referencing a function-local `$skips` from global scope under `set -u`. The fix belongs to scripts/board.sh (Task 2), which is outside this task's ownership, so it is recorded here and not edited.

## Open questions

- The board.sh `skips` unbound-variable trap warning should be handed to the Task 2 owner for a one-line fix (declare `skips` at script scope, or guard the trap with `${skips:-}`). Not blocking any criterion.
