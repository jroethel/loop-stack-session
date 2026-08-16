# Brief: make scan/classify/verify/add-if-outstanding the default import-sweep workflow

Date: 2026-08-10
Source: backlog issue #17 (real vaultwise loop-setup run, 2026-08-09)
Next stage: /loop-plan

## Outcome

When loop-setup runs on a repo holding pre-existing work files (notes, plans, brainstorms, captures), the default import path yields a clean tracker: only outstanding items filed, each classified issue vs idea, multi-item docs split, already-done work and noise never filed.
Presupposition verdict: the issue's hypothesis (agent-run workflow, bash offers it as the lead path) was checked against the code and confirmed - the split/merge half already lives in `references/import-triage.md` as agent work; this promotes and extends that path rather than inventing a new mechanism.

## End artifact

Clean triaged setup runs on existing repos holding pre-existing files - first concrete subjects: the remaining backlog-#1 repos (pokemine, substack-scraper) - plus every future new-repo setup that lands on a directory of accumulated notes.

## Done looks like

- User runs `/loop-setup` in the target repo - attended, always; loop-setup ignores the loop-auto knob.
- After the mechanical config/mirror steps, the agent runs the triage default: scan candidates, classify each discrete item (issue vs `idea`), verify outstanding vs already-built, then present one batch disclosure table (item, classification, verdict + evidence, proposed action).
- After the table, the agent offers a per-candidate walkthrough; the user picks which candidates (if any) get one.
- On approval: outstanding items filed via `scripts/tracker.sh create`, source docs archived with a pointer-back in each issue body, mirrors regenerated.
- A triage record doc (categories, actions, what was done) is always written and preserved in `docs/archive/` when candidates were found, even when nothing was filed; a zero-candidate run writes no record.
- Verbatim one-file-one-issue import and skip remain available as explicitly offered fallbacks; the bash per-item prompt is unchanged.

## Assets and options

| Asset                                   | Implied option                               | Verdict                 |
| ---                                     | ---                                          | ---                     |
| `reconcile_import` scan (`setup.sh`)    | Reuse as candidate collector + keep verbatim | Chosen (both)           |
| `references/import-triage.md`           | Extend to default workflow vs new doc        | Chosen: extend          |
| `scripts/tracker.sh create`             | Filing mechanism for triaged items           | Chosen                  |
| Graduated-item template (repo-state.md) | Pointer-back body shape for filed issues     | Chosen                  |
| vaultwise run 2026-08-09                | Spec source, or replayable test fixture      | Spec source only        |
| loop-auto knob                          | Gate an unattended triage mode               | Declined: attended-only |

## Approach

Chosen: A - agent-led default, bash stays mechanical.
The agent runs scan -> classify -> verify -> add-if-outstanding as the skill's default path, reusing the bash scan for collection and `tracker.sh create` for filing.
`references/import-triage.md` is promoted from exception reference to the default workflow and gains the classify and verify steps it lacks.
Bash's verbatim import survives unchanged as fallback.

Considered and declined:

- B - triage in bash: bash cannot grep-and-judge "already built", so every judgment becomes a prompt and verify degrades to keyword heuristics.
- C - a dedicated `/loop-import` skill: skill sprawl for a workflow with exactly one caller.

Rationale at decision time: judgment stays with the agent, mechanics stay in bash, one skill.

## Success criteria

1. `[judgment]` Field run: the next loop-setup run on a real repo with pre-existing work files produces a tracker in which the user finds zero already-done or noise issues filed.
   (Reformulation toward checkable was attempted - a fixture corpus replay - and declined by decision; field-run-only keeps the intent.)
2. `[executed-check]` Every dropped item carries disclosed evidence (file:line or commit) - the triage record contains no drop without an evidence line.
3. `[executed-check]` The triage record doc exists in `docs/archive/` after any run that had candidates.
4. `[executed-check]` Filed issues match the approved disclosure table one-to-one - a doc holding N discrete items yields N issues, never one.
5. `[executed-check]` An unattended run (`LOOP_ASSUME_YES`) files nothing, regardless of the loop-auto setting.
6. `[executed-check]` Declining triage still lands in the working verbatim per-item import (existing behavior, existing tests).

## Seams

In blast-radius order:

1. The workflow definition - classify/verify steps, disclosure-table shape, record-doc content, promoted `import-triage.md`.
   Wrong here invalidates everything downstream.
2. The skill narration - SKILL.md leads with triage as the default, verbatim and skip as offered fallbacks.
3. The bash seam - whatever minimal change `setup.sh` needs to defer to the agent path (possibly none beyond wording).
4. The record-doc-plus-archive step.

## Known vs guessed

- Verified this session: `reconcile_import` behavior (read at `setup.sh:290-346`); `import-triage.md` has no classify or verify step; the graduated-item template location in `config/repo-state.md`.
- Believed-unchecked: the bash scan surfaces the same candidate set the triage needs - if its keyword matching misses docs, triage inherits the blind spot.
  Breaks: silent under-import.
- Guessed: pokemine and substack-scraper hold import-worthy pre-existing files.
  Breaks: the field-run criterion has no subject and another repo must stand in.

## Parking lot

None - the unattended staged-pickup idea was killed by decision, not parked, and no new threads surfaced.

## Out of scope

- Changing the scan's candidate-matching heuristics.
- Any unattended import path.
- Tracker migration.
- New skills.

## Open questions for planning

- Exact name and section shape of the triage record doc.
- How `setup.sh` defers to the agent path: flag, wording change, or nothing.
- Whether the agent invokes the bash scan or reads its output.
- Where the attended-only / ignore-loop-auto rule is expressed: skill prose, code guard, or both.
