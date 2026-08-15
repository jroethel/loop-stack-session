---
name: loop-molt
description: >
  Audit any instruction-prose artifact - a SKILL.md, a CLAUDE.md block, an operating manual, a
  run-book - against a dated snapshot of what the harness now does natively, so plumbing gets
  deleted and policy survives. Classifies each block into four bins - plumbing, policy, premise,
  choreography - emits deletions plus a drift ledger line, and converges structural findings into a brief.
  Triggers on "molt", "harness drift", "audit this skill against the harness", "re-evaluate this
  prose against what the harness now does", and /loop-molt.
---

# loop-molt: audit instruction prose against the live harness

Skills, manuals, and CLAUDE.md blocks rot silently: nothing fails when the harness absorbs a
mechanic, so the prose that describes it just becomes dead weight. Molt is the audit that catches
that drift - the third in the family next to /loop-improve (audits the product) and P10's evolve
move (audits the run logs). This skill runs on any prose-shaped artifact; loop-stack self-audit is
just the dogfood case.

The reference doc is `references/protocol.md` (vendored, canonical). Read it in full before
auditing - this SKILL.md is the thin wrapper, the protocol is the method.

## The one-line test

Per block of prose: **"would the harness or a current frontier model do this unprompted, today?"**
Not "is this correct?" - correct-but-native is still deletable. Prose describing HOW to do
mechanics is suspect; prose describing WHAT MUST BE TRUE is policy.

## The four bins

Every block sorts into one of four bins - **plumbing, policy, premise, choreography** - defined,
with their actions and the policy membership test, in `references/protocol.md` (step 3). This
SKILL.md never restates those definitions; the reference is their single home.

## Steps

Full procedure and rationale live in `references/protocol.md`; the pointers below are the running
order, not a second copy.

### Step 0 - Refresh ground truth

Never audit against remembered capability. Do a thin refresh (changelog scan + one live probe of
any load-bearing feature claim) for a single artifact, a deep refresh (full research pull) only for
a whole-stack recalibration. Date-stamp the snapshot; it is the evidence base and its expiry. See
protocol step 0.

### Step 1 - Constraint register FIRST`[gate:ASK]`

Before classifying anything, ask the owner which design choices are deliberate standing constraints
(portability, provider mix, cost, compliance) versus historical accident. This gate is mandatory
and ASK-class: never classify a premise as expired without it - a deliberate constraint misread as
stale is how the source session nearly flipped three recommendations. Deliberate constraints get
kept AND labeled so the next audit does not re-litigate them. See protocol step 1.

### Step 2 - Inventory

Break the artifact into blocks: each instruction, gate, enumerated step, or embedded claim is one
classifiable unit. For a skill family, inventory duplication too (a narrative in N places counts
once, then N-1 deletions). See protocol step 2.

### Step 3 - Classify

Sort every block into the four bins using the definitions and policy membership test in the
reference. Expired premise gets rewritten in place, never a bolted-on correction; a deliberate
constraint gets kept and labeled. See protocol step 3.

### Step 4 - Test by subtraction

Delete the block, run the artifact's existing checks plus one real task, keep the deletion only if
nothing degrades. An artifact with no checks gets a check before it gets an audit; the checkless
fallback (delete, run one real task, compare to a pre-deletion run) is weaker. See protocol step 4.

### Step 5 - Emit the drift ledger line

Append one entry to the repo drift ledger, `docs/molt-ledger.md`: date, harness snapshot, blocks
deleted by bin, blocks kept as policy, constraints re-confirmed. Per-entry shape:
`## YYYY-MM-DD - <artifact path>` then those fields. On a first audit of a principles-less
artifact, also emit the derived invariants as its starter principles sheet. See protocol step 5.

## Workflow: inline vs. brief

- **Small findings** (block deletions, single-file rewrites) apply inline via the subtraction test
  with a `docs/molt-ledger.md` line, same session.
- **Structural findings** (skill merges, gates-to-hooks, re-homing) converge through the shared
  pipeline at `~/.claude/skills/loop-brainstorm/references/brief-pipeline.md` into a brief and ride
  the normal chain: /loop-plan -> /loop-which -> /loop-drive -> /loop-review. No audit content is
  duplicated - loop-improve reaches this same audit via `--focus harness-drift`.

The artifact is harness-agnostic: this SKILL.md is the only Claude-Code-specific wrapper; the
protocol is portable prose that any agent can run.
