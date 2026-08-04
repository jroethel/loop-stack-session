# Autonomy Knob Brief (seam C)

Date: 2026-08-02.
Source: seam C of `docs/2026-08-02-settled-decisions-and-sequence.md`, open decision 6 of the 2026-07-20 dump, and this session's brainstorm.
Companion: `docs/briefs/2026-08-02-repo-state-convention-brief.md` (seam B), which provides the state conventions this seam's artifacts follow.

## Outcome

From any committed artifact in the chain, Jeremy controls how much of the rest runs without him: pause-per-stage (today's behavior, the unchanged default) or autonomous, with a hard STOP class active in every mode.
The knob is an explicit setting - a `/loop-auto` command, or recognized phrases like "run the rest" that confirm what the knob is being set to - persisted in chain state so it survives session boundaries.
His irreplaceable input is front-loaded by the chain's own design: ASK gates cluster before plan approval, so autonomy from an approved plan is naturally safe.
Presupposition verdict: "autonomy modes" turned out not to be three modes - stop-on-circumstances is a gate class active everywhere, not a mode.

## End artifact

The build wave itself, run under the knob: plan approved in the planning session, knob set, return to a finished wave plus one batch-review list.
Ships with the build wave.

## Done looks like

- `/loop-auto` sets the knob explicitly at any point; "run the rest" (and kin) sets it with a one-line confirmation of the mode being set.
- Knob on before brainstorm: the interview still happens (ASK gates always fire); autonomy takes effect after the last ASK gate passes.
- Knob on from an approved plan or `_loop.md`: STOP gates still stop and say exactly what they need; BATCH and DEFAULT gates resolve themselves verbosely.
- End of an autonomous run: one review list of every batched judgment and auto-default taken, each entry naming what was decided, why, and its reversal path.
- Knob off or unset: every gate fires live, byte-for-byte today's behavior.
- The generated gate registry sits in `docs/` with generation time and regen command in its header.

## The gate taxonomy (the decided core)

Four gate types, classifying all 19 gates inventoried from the four skill texts this session:

| Type    | Meaning                                       | Members                                          |
|---------|-----------------------------------------------|--------------------------------------------------|
| ASK     | Only Jeremy holds the information; blocking   | Brainstorm interview; plan open questions;       |
|         | in every mode                                 | loop-which availability probe                    |
| STOP    | Hard stop in every mode: irreversibility      | Dirty tree; outward-facing units; effort-cap     |
|         | boundary, quota-as-money, scope authority     | exceed; spec edits beyond clarification;         |
|         |                                               | twice-failed unit with design issue              |
| BATCH   | Taste on an artifact; auto mode takes the     | Rubix triage; topology pick; `[judgment]`        |
|         | named lean, proceeds, collects for end review | criteria; terminal loop-review findings          |
| DEFAULT | Offers with a sane default; auto mode takes   | Rubix offer; stage handoffs; verdict confirm;    |
|         | it and logs verbosely                         | dashboard ask; commit offers; artifact approvals |
|         |                                               | (committed and flagged for review)               |

Trust posture recorded: effort-cap (#14) and spec edits (#15) sit in STOP now; #15 may relax to BATCH with a size limit after autonomous runs build trust (parked).

## Orchestration continuation model

Two rules resolve who runs what when the knob is on:

1. Nobody ever spawns Fable; delegation only goes down-tier (roster pin, managed routing block).
2. The session active when autonomy takes effect becomes the orchestrator for the rest of the chain; it keeps its own model and dispatches heavy lifting to fresh-context subagents at the role-pinned models (plan-draft dispatch, drive-compile dispatch, workers by evidence chain).

A Fable brainstorm session with the knob on therefore carries the chain itself: Opus dispatch drafts the plan, the Fable session reviews the dependency graph, and the same session orchestrates the drive.
Spawning a new differently-modeled orchestrator session unattended is the parked auto-resume machinery, not part of this seam.

## Assets and options

| Asset                                  | Option implied                                  | Verdict                       |
|----------------------------------------|-------------------------------------------------|-------------------------------|
| The 19-gate inventory (this session)   | The four-type taxonomy                          | Chosen                        |
| loop-drive's resume machinery          | Pattern lifted chain-wide, not reinvented       | Chosen                        |
| Role pins in the managed routing block | The continuation model's dispatch targets       | Chosen                        |
| B's disclosed-mirror pattern           | Reused for the gate registry                    | Chosen                        |
| B's state conventions                  | Home for chain state and the batch-review list  | Chosen                        |
| Wayfinder HITL/AFK ticket typing       | Per-item autonomy granularity                   | Declined - wrong granularity  |
| Quota-aware scheduling / auto-resume   | Unattended new-session spawning                 | Parked (third parking)        |

## Approach

Chosen: inline gate-type tags at the gate sites in the skill texts are the single source of truth; a generated registry mirrors them; the knob is an explicit persisted setting.

- Truth at the gate site: each gate carries its type tag on the line where it fires, so declaration and behavior cannot disagree.
- The registry is a generated, disclosed mirror (B's rule): header states generation time and regen command; it is never hand-edited.
- An executed check fails when any gate-shaped moment lacks a tag or the registry is stale; drift is a red build, not a risk.
- The knob: `/loop-auto` plus recognized phrases with confirmation; persisted in chain state per B's conventions; never skips ASK or STOP.

Alternatives considered: hand-maintained registry (drifts - the exact failure mode B fixed for backlogs); spoken-per-entry mode with no persistence (dies with the session, defeating run-from-any-step); per-repo mode default (parked as the graduation path, not rejected).

## Success criteria

- Every gate in the four skill texts carries an inline type tag; the freshness check exits 0, and fails when a tag is missing or the registry is stale `[executed-check]`
- The generated registry exists with generation header and regen command `[executed-check]`
- An autonomous run from an approved plan reaches completion with zero ASK gates fired and produces the batch-review list `[executed-check]`
- STOP gates fire even in autonomous mode, provable with a seeded dirty tree at pre-flight `[executed-check]`
- `/loop-auto` and a recognized phrase both set the knob, confirm the mode, and the setting survives a session boundary via chain state `[executed-check]`
- With the knob off or unset, no behavior changes beyond tag annotations - the diff to skill texts shows tags only `[executed-check]`
- The batch-review list is a sufficient basis to accept or reverse each batched decision without replaying the run `[judgment]` - reformulation attempted (each entry names decision, rationale, reversal path - checkable structurally); the tag survives for sufficiency itself

## Seams

Blast-radius order:

1. Gate taxonomy plus inline tags in the four skill texts.
2. Knob mechanism: command, phrases, confirmation, chain-state persistence.
3. Batch-review list artifact.
4. Registry generation plus freshness check.
5. The build-wave demonstration run (the end artifact).

## Known vs guessed

- Verified: the 19-gate inventory (all four skill texts read in full this session); ASK gates cluster before plan approval; the role pins exist in the managed routing block (shipped today as seam D).
- Believed-unchecked: phrase recognition plus confirmation is sufficient UX without a formal flag syntax.
- Guessed: batching judgment gates will not degrade artifact quality unacceptably.
  If wrong, individual gates re-tighten to STOP - degraded, not broken.

## Parking lot

- Quota-aware scheduling and unattended auto-resume (launchd, headless claude); third parking - if it returns a fourth time, it gets its own brainstorm on why it keeps coming back.
- Per-repo knob default in repo config, overridable per invocation.
- Relaxing spec-edit gates (#15) from STOP to BATCH with a size limit, after trust builds.

## Out of scope

- Removing or adding any gate; the knob classifies, never deletes.
- Autonomy for non-loop skills.
- Daemons, hooks, schedulers, or any always-running process.
- Spawning new orchestrator sessions unattended.

## Open questions for planning

- Exact command name (`/loop-auto` vs a longer form) and the recognized phrase list.
- Tag syntax at gate sites.
- Registry filename and location in `docs/`.
- Freshness-check mechanics: `tests/` script vs install.sh doctor vs both.
- Chain-state artifact name and location (the existing `*-loop-state.md` pattern is precedent).
- Batch-review list location per the seam B convention.
- Whether `_loop.md` records the active mode explicitly.
