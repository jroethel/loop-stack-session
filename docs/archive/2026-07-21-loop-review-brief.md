# loop-review Brief

Date: 2026-07-21.
Source sessions: the loop-skills vs mattpocock routing comparison (this session) and the 2026-07-20 comparison dump (`docs/2026-07-20-mattpocock-comparison-dump.md`).
Decision inputs include Jeremy's annotations in `loop-skills-model-routing.xlsx` (Thoughts column, sheet 1; ACTION column, sheet 2).

## Outcome

Any completed work, loop-driven or hand-made, can be judged "was this good?" by a fresh-context, two-axis review that discloses its basis before its findings.
This closes the named gap: nothing at the end of the loop-* chain currently says whether the work was good.
Presupposition verdict: the user named Matt Pocock's code-review skill as the template; tested and confirmed - a fork of it is the right base.

## End artifact

`skills/loop-review/SKILL.md` in the loop-stack repo, symlinked by install.sh like the other loop skills.
First real deliverable: a review of the next real diff Jeremy finishes, run the day the skill lands.

## Done looks like

In any repo, `/loop-review main` (or any ref: a SHA, tag, or `HEAD~3`) produces a report that opens with the resolved spec source and standards sources, then Spec and Standards findings side by side, never merged.
loop-drive's gate can invoke the same skill as its terminal step.
The skill works in repos with zero loop-stack conventions.
Exact usage: `/loop-review <fixed-point>`, for example `/loop-review main`.

## Assets and options

| Asset                          | Option implied                                  | Verdict                       |
|--------------------------------|-------------------------------------------------|-------------------------------|
| Matt's code-review skill       | Fork as the skeleton                            | Chosen                        |
| Fowler 12-smell baseline       | Keep verbatim inside the fork                   | Chosen                        |
| docs/plans + docs/briefs       | Top of the spec discovery chain                 | Chosen                        |
| Matt's docs/agents/ config     | Depend on per-repo setup files                  | Declined for v1 (seam B)      |
| Managed CLAUDE.md routing block| Resolve reviewer model by role, not by name     | Chosen (honors seam D early)  |
| ringer                         | Transport for the review subagents              | Declined (fresh Agent-tool)   |
| gh CLI                         | Fetch specs referenced from commit messages     | Chosen                        |

## Approach

Chosen: fork-and-adapt Matt's code-review.
Alternatives considered: write loop-native from scratch (re-derives a debugged 89-line structure for little gain), and use Matt's as-is (adopts its gaps: no plan/brief discovery, a hard docs/agents/issue-tracker.md dependency, no basis disclosure).
Deltas from Matt's version: a spec discovery chain (user-passed path, else plan, else brief, else commit-message refs, else ask, else "no spec available"); a disclosure opener naming the resolved spec and standards sources before any finding; reviewer model referenced by role via the routing block instead of unnamed; the user's markdown rules.
Rationale recorded at decision time: the skill is proven, the deltas are exactly the decided scope, and the fork removes the setup dependency loop repos will not have until seam B ships.

## Success criteria

- Run against a diff with a plan present: the report names the plan path as spec source before any finding `[executed-check]`
- Run with no spec anywhere: the spec axis reports "no spec available" and the standards axis still delivers findings `[executed-check]`
- A seeded spec violation and a seeded code smell in a test diff are both caught and cited `[executed-check]`
- Every finding cites its spec line or its standard `[executed-check]`
- Usable standalone in a repo with no loop-stack conventions `[executed-check]`

No `[judgment]` criteria survive.
"The review feels useful" was reformulated into the seeded-defect and citation checks above.

## Seams

Near-atomic.
Blast-radius order: the skill file; the install.sh symlink; a one-line loop-drive gate hookup.

## Known vs guessed

- Verified: Matt's skill structure (read in full this session); the managed CLAUDE.md block resolves reviewer roles today; the fork removes the setup-config dependency.
- Believed-unchecked: loop-drive step 5 has a clean single insertion point for the terminal invocation.
- Guessed: branch-name matching suffices for plan discovery.
  If this guess is wrong, discovery falls through to asking the user - degraded, not broken.

## Parking lot

- G: split loop-drive into /loop-preflight (compile, steps 0-6) and /loop-drive (launch + execution), including the model needs of each half. **Flagged: next discussion.**
- B: per-repo state convention - setup skill, docs/agents/ config, tracker as the single backlog home.
- C: autonomy knob - HITL/AFK gate typing across the chain (run through, pause per step, stop on circumstances).
- D: model unpinning - extract the three model-naming sentences (loop-plan rubix, loop-drive validator and roster) into the routing doc.
- E: glossary + CONTEXT.md inline updates + ADR discipline (YES'd in the xlsx); scenario stress-tests (discuss).
- F: install-as-is set from Matt's repo - prototype, handoff, tdd, grilling.
- H: Fable as plan-decompose reviewer over an Opus drafting session (xlsx sheet-1 thought).
- I: brainstorm write/self-review separation from the judgment session (xlsx sheet-1 thought).
- J: keep wayfinder as a /matt-wayfinder copy with a routing handoff into the loop chain (xlsx ACTION note).
- K: prefactors and expand-contract adoption into loop-plan (discuss; xlsx ACTION notes).
- L: `model-routing-brainstorm-prompt.md` - existing brainstorm prompt; intersects D (model unpinning) and I (brainstorm session separation). **Flagged: discussion list.** No impact on loop-review.

## Out of scope

- Run- or process-quality review; loop-drive's gate and distill steps own that.
- Tracker and triage integration (seam B).
- Any edits to loop-plan or the rubix review (seam H is parked).
- The routing-doc extraction itself (seam D is parked; this skill merely references roles).

## Open questions for planning

- Plan-discovery matching heuristic: branch name, most recent plan, or both.
- Exact insertion point in loop-drive step 5 for the terminal invocation.
- Effort level for the two review subagents.
- RED-GREEN fixture shape for testing the skill against the seeded-defect criteria.
