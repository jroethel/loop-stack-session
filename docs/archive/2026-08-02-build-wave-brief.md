# Build-wave brief

Date: 2026-08-02.
Origin: /loop-brainstorm over roadmap item 1, consuming the settled ledger (`docs/2026-08-02-settled-decisions-and-sequence.md`) and the 2026-08-02 handoff.

## Outcome

The chain skills absorb every settled ledger decision in one pass, and the autonomy knob goes from recorded intent to live behavior.
The result: a start-and-stop, multi-SME project can move through brainstorm -> plan -> drive with gates, handoffs, and a batch-review journal carrying state across the stops.
Presupposition verdict: the ledger's one-pass topology was tested in prior sessions and holds; this brief applies it rather than reopening it.

## End artifact

Two-layered.
The wave's own drive run under the knob is the demonstration, closing the autonomy brief's end artifact (`docs/briefs/2026-08-02-autonomy-knob-brief.md`).
The first production run is a real project - moneygoddess / lkt / pokemine / Laura's site class - beginning with brainstorm or wayfinder within a week or two of the wave landing.
The "how" of those projects is unclear and SME-dependent; the upgraded chain is what makes that tractable.

## Done looks like

You can:

- Set the knob (`scripts/loop-auto.sh` / `/loop-auto`) and see it actually change gate behavior, with current mode visible in its output, including the inherit-default vs this-repo answer.
- Approve the wave plan live, walk away, and return to a finished wave plus a chronological batch-review journal in `docs/reviews/`.
- Start a real project with the upgraded `/loop-brainstorm` (domain modeling, auto parking-lot graduation) or wayfinder.
- Run `frontier-sandwich` under its new name.

Exact run commands for each land in the wave's closing handoff.

## Assets and options

| Asset                                     | Option implied                           | Verdict           |
| ---                                       | ---                                      | ---               |
| Settled ledger                            | Spec input for the whole wave            | Chosen            |
| Gate-journal spec (CLAUDE.md + sample)    | Implement journal as spec'd              | Chosen            |
| Backlog #4 (per-repo knob default)        | Rider: ask inherit vs this-repo; display | Chosen            |
| Backlog #5 (gate #15 STOP -> BATCH)       | Rider, with stated size limit            | Chosen            |
| Backlog #2 (triage-state labels)          | Pull with wayfinder (its trigger lands)  | Chosen, explicit  |
| Debt: dup STOP rows in gate-registry      | Fix while regenerating registry          | Chosen            |
| Debt: awk pipe-escape divergence          | Align the two scripts                    | Chosen            |
| Debt: shared disclosed-header emitter     | Extract shared helper                    | Declined: no pain |
| HC2 fresh-session routing check           | Fold into wave verification              | Chosen            |
| glm-5.2 via claude-zai (7/7 code-feature) | Routes wave execution units              | Chosen            |
| Matt's wayfinder skill                    | Copy source for J                        | Chosen            |
| Matt's triage / tdd / prototype skills    | Install alongside wayfinder              | Declined: backlog |
| fable-sandwich + model-benchmarks.md      | Rename -> frontier-sandwich              | Chosen            |
| Fable session + Opus dispatch roles       | Orchestration per role pins              | Chosen            |

Declined-verdict detail lives in Parking lot and Out of scope.

## Approach

Chosen: one wave - brief -> `/loop-plan` -> `/loop-drive` - applying the whole ledger in one pass, run under the autonomy knob as seam C's demonstration.
Considered and rejected, with rationale recorded in the ledger and the 2026-08-02 sessions:

- Per-skill sequential waves: every skill gets edited twice, because the gate-typing convention must exist before skill bodies are rewritten.
- Hand-editing outside the chain: forfeits the demonstration run and the batch-review journal the knob needs to prove itself.

## Success criteria

1. `[executed-check]` Every gate in the four chain skills carries a gate-class tag; `scripts/gen-gate-registry.sh` regenerates `docs/gate-registry.md` with zero duplicate rows.
2. `[executed-check]` The wave's own drive run completes under `auto` and leaves `docs/reviews/<date>-build-wave-batch-review.md` with one entry per fired gate, chronological, each entry carrying decision / rationale / reversal path per the journal spec.
3. `[executed-check]` `/loop-auto` output shows the current mode and records the inherit-default vs this-repo answer; setting it in `pause` leaves all gates firing live.
4. `[executed-check]` Committing a brief with a parking lot creates one `idea`-labeled gh issue per parked item (verify on the first brief committed after the wiring lands; this brief's own lot graduates manually, since the wiring is a wave deliverable).
5. `[executed-check]` loop-drive contains the explicit start-from-existing-`_loop.md` entry point and the in-skill Opus compile dispatch (steps 1-4 + 6 as one dispatch).
6. `[executed-check]` loop-plan carries H (Opus decompose dispatch + session dependency-graph review) and K (prefactor rule; expand-contract reference); loop-which frontmatter is trimmed.
7. `[executed-check]` Gate #15 is BATCH with a stated size limit; spec edits over the limit still STOP.
8. `[executed-check]` `frontier-sandwich` exists as a repo skill, benchmark-refresh writes to the generalized config path, and no live reference to the fable-sandwich name remains.
9. `[executed-check]` Wayfinder is installed with the routing hand-off, and its ticket-type labels layer on the lane scheme without disturbing the one load-bearing `idea` label.
10. `[executed-check]` HC2: a fresh session asked the routing question resolves model choice through the evidence chain (scoreboard -> prior -> pin) without hand-holding.
11. `[executed-check]` `gen-mirrors.sh` and `gen-gate-registry.sh` escape pipes identically (same awk treatment, spot-checked on a title containing `|`).
12. `[judgment]` The rewritten skill texts read as one voice and contradict neither the managed CLAUDE.md block nor each other.
    Reformulation attempted: "no contradictions" partially lands in criterion 1's registry regen, but voice and coherence genuinely need a human read.

## Seams

Blast-radius order; each independently checkable against the criteria above; only seam 1 is load-bearing for the others.

1. Gate typing + knob consumption across the four chain skills (criteria 1, 2, 3).
2. loop-drive: compile dispatch + `_loop.md` entry point (criterion 5).
3. loop-plan: H, K, lensing per routing doc (criterion 6).
4. loop-brainstorm: E (domain modeling, scenario stress-tests) + parking-lot graduation wiring (criterion 4).
5. loop-auto: #4 rider, ask + display (criterion 3).
6. Wayfinder copy + routing hand-off + #2 labels (criterion 9).
7. frontier-sandwich rename + loop-which trim (criteria 6, 8).
8. Script hygiene: dup STOP rows, awk parity (criteria 1, 11).

## Known vs guessed

- Verified: the ledger's settled decisions (read in full this session); gate-journal spec current in managed CLAUDE.md and `docs/reviews/2026-08-02-sample-batch-review.md`; the 19-gate inventory from the autonomy brief; glm-5.2 via claude-zai 7/7 on code-feature; repo layout (skills live in `skills/`, installed via `install.sh`); riders #4/#5 and backlog #2 exist as gh issues.
- Believed-unchecked: Matt's wayfinder source is on hand and its structure matches what the J decision assumed; the autonomy phrase list in the managed block is complete enough for the demonstration run.
- Guessed: batching judgment gates won't unacceptably degrade artifact quality (carried from the autonomy brief; the demonstration run is the test, and if wrong, the batch review catches it as reversals); the whole ledger fits one drive run within effort caps (if wrong, the wave splits at a seam boundary and the journal records where).

## Parking lot

- Status-bar surfacing: "would be great if it could somehow be surfaced so as to be visible in status bar (and perhaps status bar items are a backlog item)."
  Restart context: knob mode display shipped in `/loop-auto` output; this is the ambient-visibility upgrade.
- Case for Matt's triage / tdd / prototype skills: "I know I have uses for wayfinder, I'm less sure about the others unless/until a case can be made. If it can't be, backlog them."
  Restart context: seam F already deferred tdd/proto; a case must name the first real use.

## Out of scope

- Sprawl-repo migration (backlog #1) and quota-aware scheduling (backlog #3) stay parked per the scope rule.
- The Jeremy-maintained "Reading the user" section of loop-brainstorm is untouchable.
- The shared disclosed-header emitter is declined.
- No status-bar work.

## Open questions for planning

- Is the wave plan flagged high-stakes (Fable lens B in rubix) or standard (Opus both lenses + GLM third)?
- Where does knob display live: script output only, or also a repo-state line?
- Exact size limit for gate #15's BATCH relaxation.
- Whether parking-lot graduation lives in skill text, a script, or both.
- How wayfinder's ticket-type labels name-map onto the lane scheme.
