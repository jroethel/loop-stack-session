# Brief: /loop-improve - audit-driven front end to the brief pipeline

Source: brainstorm session.
Date: 2026-08-08.

## Outcome

A new loop-stack skill, /loop-improve, surveys a repo as a senior advisor, scans the Issues and Backlog lanes for overlap, and converges one selected finding into an approved brief for /loop-plan.
It keeps /improve's audit discipline but replaces its plans-directory output with the same single-brief handoff /loop-brainstorm produces.
/loop-improve and /loop-brainstorm are sibling entry points into one convergence pipeline: the user runs one or the other, never chained.
Presupposition verdict: "a version of the /improve skill" holds for the front half (audit categories, evidence-backed findings, vetting) and is rejected for the back half (per-finding plan files), which the brief pipeline replaces.

## End artifact

First deliverable: a /loop-improve run on loop-stack itself producing an approved brief that /loop-plan consumes unmodified.

## Done looks like

- Run `/loop-improve` in a loop-set-up repo; an optional focus argument (`/loop-improve security`) narrows the audit, and an effort keyword (`quick` / `deep`, default standard) sets its depth.
- The audit is read-only on source code, exactly as /improve mandates.
- The run scans the Issues and Backlog lanes through the tracker (backend-agnostic, both `github` and `local` modes) and presents a vetted findings table where every row carries evidence, impact, effort, confidence, and any `covered by #N` or `related: #N` annotation.
- Covered findings stay selectable; choosing one means the brief supersedes the matching issue.
- The user selects one finding, and the run converges through the shared brief pipeline to `docs/briefs/YYYY-MM-DD-<topic>-brief.md` with the standard approval gates.
- At brief commit, unselected findings are offered for graduation to backlog as `idea` issues (previewed, assented, each announced with number and title), and a superseded issue's close is offered via `scripts/tracker.sh close <num>`.
- /loop-brainstorm still runs end-to-end with unchanged behavior after the shared-half refactor.

## Assets and options

| Asset                                          | Implied option                                 | Verdict                                        |
| ---                                            | ---                                            | ---                                            |
| /improve audit playbook (MIT)                  | Vendor a trimmed copy into loop-improve        | Chosen (self-contained on fresh hosts)         |
| /improve installed at runtime                  | Read its references from ~/.claude/skills      | Declined (host dependency, unreviewed drift)   |
| /improve plan-template + closing-the-loop      | Carry over the plans machinery                 | Declined (the brief replaces plans)            |
| /improve knobs                                 | Focus argument + quick/standard/deep           | Chosen; all other variants declined            |
| loop-brainstorm back half                      | Factor into a shared convergence reference     | Chosen                                         |
| scripts/tracker.sh + the lanes                 | The scan surface, backend-agnostic             | Chosen                                         |
| graduate-parking.sh pattern                    | Reuse for unselected-finding graduation        | Chosen; reuse-vs-parallel is a planning question |

## Approach

Chosen: shared convergence half.
loop-improve owns its divergence half (vendored trimmed audit playbook, tracker scan, findings table, selection); loop-brainstorm keeps its own (scope probes, question rounds).
From approach-proposal onward both skills run one shared brief-pipeline reference: brief sections, checkability tagging, self-review, user review gate with parking-lot graduation, and the pinned terminal state.
One source of truth means a brief-format or gate fix lands in both skills at once.

Considered and declined:

- Self-contained duplicate: copying the brief pipeline into loop-improve avoids touching working loop-brainstorm, but leaves two copies that drift - the redundancy failure mode.
- Thin front end over brainstorm: handing the selected finding to /loop-brainstorm internally has zero duplication, but drags an evidence-backed finding through scope probes and outcome rounds the audit already answered.

## Success criteria

1. End-to-end: a /loop-improve run on loop-stack yields a brief in `docs/briefs/` containing every pipeline section, and /loop-plan accepts it without edits. `[executed-check]`
2. Findings hygiene: every findings-table row carries file:line evidence, impact, effort (S/M/L), and confidence; no vibes-only rows. `[executed-check]`
3. Coverage annotation: with a seeded open issue matching a finding the row shows `covered by #N`, and with a seeded related issue it shows `related: #N`. `[executed-check]`
4. Graduation: after assent, the tracker lists one new open `idea` issue per unselected finding, each announced with number and title. `[executed-check]`
5. Supersede: committing a brief for a covered finding offers `scripts/tracker.sh close <num>` and the brief records the supersede link; nothing closes without acceptance. `[executed-check]`
6. Brainstorm regression: a /loop-brainstorm run after the refactor produces a brief with all sections and the same gates as before. `[executed-check]`
7. Read-only audit: the audit phase leaves the working tree clean apart from the brief and journal artifacts. `[executed-check]`
8. Findings quality: the table's top findings are ones worth briefing in the user's judgment. `[judgment]` - reformulation attempted; the checkable part became criterion 2, and whether they are the right findings genuinely stays judgment.

## Seams

Blast-radius order; each independently checkable.

1. Extract the shared convergence reference from loop-brainstorm and repoint loop-brainstorm at it - checked by the brainstorm regression run (criterion 6).
2. loop-improve front half: vendored trimmed playbook, audit, findings table - checked by criteria 2 and 7 on a loop-stack run.
3. Tracker scan with covered/related annotation - checked by criterion 3 with seeded issues.
4. Convergence handoff: selection into the shared pipeline through brief commit - checked by criterion 1.
5. Leftover graduation and supersede-close offers - checked by criteria 4 and 5.

## Known vs guessed

- Verified this session: skills live in `skills/` and symlink individually via install.sh, so a shared file must live inside some skill's directory (every subdirectory of an installed skills tree loads as a skill); /improve is MIT-licensed; the lanes and the `idea` label convention are as `config/repo-state.md` declares; loop-brainstorm today is a single SKILL.md with no references directory; graduate-parking.sh parses a brief's Parking lot section and titles items by first sentence.
- Believed-unchecked: tracker.sh's subcommands cover the scan's listing needs in both backends - read about in repo-state.md, not read as code; if wrong, the scan needs a tracker.sh extension.
- Believed-unchecked: unselected findings can ride graduate-parking.sh's existing parse unchanged (they would need to be written in parking-lot bullet shape); if wrong, graduation needs a script extension or its own path.
- Guessed: a cross-skill file reference (loop-improve reading a file under the installed loop-brainstorm directory) resolves under both install styles; if wrong, the shared reference needs a different home - a planning question either way.

## Parking lot

- Add the issues/backlog scan to /loop-brainstorm so a fresh idea is checked against existing backlog items before briefing.
  Restart context: deferred from the loop-improve brainstorm to keep that scope improve-only; the scan mechanism will exist in loop-improve to borrow.

## Out of scope

- Any plans/ directory output.
- /improve's other variants: `branch`, `next`, `plan <description>`, `review-plan`, `execute`, `reconcile`, `--issues`.
- Changes to /loop-plan, /loop-which, or /loop-drive.
- Creating or closing issues without assent.
- Replacing the installed /improve, which remains for non-loop repos.

## Open questions for planning

- Where the shared convergence reference lives and how both SKILL.mds point at it under both install styles (agents and claude).
- Whether unselected-finding graduation reuses, extends, or parallels graduate-parking.sh.
- The trimming line for the vendored playbook and its upstream attribution note.
- Exact findings-table columns and how covered/related annotations render.
- The scan matching mechanism: tracker listing plus model judgment vs keyword search.
- Whether audit fan-out mirrors /improve's Explore-subagent effort table or is simplified.
- Gate tags for the new steps (which are ASK vs DEFAULT) and their entries in the gate registry.
