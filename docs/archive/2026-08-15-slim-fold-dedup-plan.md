# Slim, Fold, Dedup the Skill Stack Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes. No specific tooling, harness, or skills are assumed.

**Goal:** Retire two skills, fold their kept content to a single home each, dedup the routing/ringer/graduation narratives to one home plus pointers, and slim every SKILL.md by test-by-subtraction so the surviving stack is a policy sheet, not plumbing prose - while every gate test still passes and the chain behaves identically on the happy path.

**Approach:** Fold frontier-sandwich into loop-drive as a human-paced output mode and loop-which's One-Minute Test into the loop-brainstorm front door; retire both via install.sh's existing retire mechanism.
Dedup the routing-chain narrative to `config/routing/model-benchmarks.md`, ringer footguns to `ringer-substrate.md`, brief-graduation to `brief-pipeline.md`, each other site carrying one pointer line.
Slim by subtraction (delete a block, run gate tests + one real task, keep the deletion only if nothing degrades), classifying every deletion by molt bin and logging it to the drift ledger; policy blocks (checks-or-stall, validator contract, per-unit routing table, gate classes, run-state, check custody, the shaping lanes) are kept, never cut.

**Tech stack:** Markdown instruction prose; bash gate-test suites (`tests/`); `install.sh` symlink/retire mechanism; `scripts/gen-gate-registry.sh`; git tags for the line-count baseline.

**Source brief:** `docs/briefs/2026-08-15-slim-fold-dedup-brief.md` (brief 3 of molt cycle 1). Bin taxonomy and structural mandate: `~/create/pcs/2026-08-15-consolidated-recommendations.md` Sections 5 and 8.

## Policy-deletion flags

**None.** No block classified POLICY is deleted by this plan.
The two retirements RELOCATE policy, they do not cut it: frontier-sandwich's kept content (model-tier vocabulary, effort dial, the sandwich invariant, fan-out loop-readiness) folds into loop-drive; loop-which's One-Minute Test discipline (P6/C6 checkability-as-routing-gate, DON'T BOTHER) folds into the loop-brainstorm front door and stays referenced from loop-drive Step 0.
The native-lane slim (Task 6) deletes only PLUMBING/CHOREOGRAPHY (decomposition, fan-out, background-execution, notification prose) against an explicit KEEP list; ringer footguns and check custody stay as POLICY in their single homes.

## Resolved criteria (Jeremy, 2026-08-15)

Two brief criteria over-reached reality and were resolved by the owner at the plan-review STOP; the evidence was verified independently (script-line split re-counted, prose baseline re-derived from the tag). Neither was softened by the driver - each was adjudicated by Jeremy and re-anchored to what is achievable without cutting policy.

1. **Skill count `7 +/- 1` (<= 8) -> accepted floor of 10.**
   Only two removals are defensible without breaking a distinct skill's command/job or cutting policy: retire frontier-sandwich (fold -> loop-drive) and retire loop-which (fold -> loop-brainstorm front door). That lands 12 -> 10.
   Each further removal needed to reach 8 breaks a distinct job: loop-auto owns the `/loop-auto` command AND the chain-wide gate-class taxonomy that `gen-gate-registry.sh`, `knob-consumption.sh`, `loop-auto.sh`, and `tags.sh` all depend on; handoff is a distinct general-session `/handoff` compaction command (POLICY, flagged "near done molting" in the existing ledger); loop-setup is the run-once bootstrap carrying import-triage judgment; folding loop-improve into loop-brainstorm trips the constraint register's explicit guard ("brainstorm/improve keep their full shaping capability").
   Corroboration from the source of record: pcs Section 5's own target table enumerates ~10-11 surviving skill roles, so the "~7" in Section 5.6 over-reaches its own decomposition.
   Resolution: the accepted criterion is exactly 10 with both retired dirs absent - the maximal defensible reduction. Task 14 asserts it.

2. **Line count `40%+ off the 3040 tag` (<= 1824) -> re-anchored to prose-only 40%+.**
   `skills/` contains **611 lines of fixed shell scripts** that are code, not the instruction-prose a molt slims: `loop-setup/setup.sh` (492), `loop-auto/loop-auto.sh` (114), `handoff/agents/openai.yaml` (5). Measuring 40% off the full 3040 tree forces prose to <= 1213, cutting ~290 lines of retained policy - refused (also a metric reward-hack if scripts were relocated to move the number).
   Resolution: the accepted criterion excludes the fixed scripts and measures the prose a molt actually touches. Baseline prose at `v1-pre-molt` (`.md` under `skills/`) is **2429 lines** (re-derived from the tag); the target is 40%+ reduction, i.e. **<= 1457** prose lines. Current prose is 2624 (includes brief 2's +195 loop-molt, which Task 9 also slims). Task 14 measures prose-only reduction against 2429 and asserts <= 1457; a policy-preserving near-miss (1457-1500) routes to the Task 14 human checkpoint for acceptance rather than cutting policy to hit the number.

## Resolved conflicts

- **Drift ledger filename.** The brief (Task 6, criteria) names `docs/drift-ledger.md`; the shipped loop-molt skill, its `molt.sh` gate test, and the existing on-disk file all name `docs/molt-ledger.md` (H1: "Molt drift ledger"). Single-home-plus-pointers is a mandatory constraint; a second ledger file would violate it and break `molt.sh`. **Resolution:** this cycle's deletions append to the existing `docs/molt-ledger.md` (the established single home). "drift-ledger.md" is treated as a prose alias for the same artifact. Every deletion still gets one ledger line, satisfying the criterion's substance.

## Global constraints

- `/workflows` stays off; do not design around it.
- Portability is standing: the stack runs outside Claude Code; ringer is the spine, native primitives the optional lane. Ringer-lane policy (footguns, check custody) is never deleted as if native were the only lane.
- Do not worsen: the `~/repos/ringer` hardcode, absolute-path symlinks, `claude-zai.sh` env specifics, the `/dev/tty` question (#28), macOS/Linux/WSL differences.
- Single-home-plus-pointers is mandatory in everything touched: routing-chain narrative -> `config/routing/model-benchmarks.md`; ringer footguns -> `skills/loop-drive/references/ringer-substrate.md`; brief graduation -> `skills/loop-brainstorm/references/brief-pipeline.md`.
- brainstorm/improve keep FULL shaping capability (question generation, checkable criteria, seams, parking lot); only choreography goes. Do not slim their shaping to bin-plumbing.
- Fable is never a worker; effort capped at high.
- Do NOT scope the parking-lot items: session-hygiene reference file, context-map extension of repo-state.md, `/goal` as a third transport.
- Every deletion carries a molt bin (PLUMBING / CHOREOGRAPHY / POLICY-keep / PREMISE) and a `docs/molt-ledger.md` line. POLICY is kept, never deleted.

## Dependency graph

The prose-editing tasks form a **serial spine**, by deliberate design, because two artifacts are shared across nearly every task and cannot be raced:
- `docs/gate-registry.md` is generated from every `skills/loop-*/SKILL.md`; any prose edit near a gate tag changes its excerpt, so each SKILL-editing task must regenerate it, and two tasks regenerating it in parallel would collide.
- `docs/molt-ledger.md` is a single append-only ledger the brief requires; parallel appends race.

```
Task 1  (ledger open)
   |
Task 2  (retire frontier-sandwich: infra + reference move)        [registry-neutral, but sequenced for ledger]
   |
Task 3  (routing canonical home: config/routing/model-benchmarks.md)
   |
Task 4  (loop-brainstorm: absorb One-Minute Test front door + slim choreography)
   |
Task 5  (retire loop-which dir + rehome one-minute-test.md + tags.sh/loop-which.sh)
   |
Task 6  (loop-drive: policy-sheet slim - absorb sandwich mode, routing pointer, native-lane cut, +its 3 references)
   |
Task 7  (loop-plan slim)
   |
Task 8  (loop-improve SKILL + audit-playbook slim)
   |
Task 9  (loop-molt SKILL + protocol slim)
   |
Task 10 (wayfinder slim + routing pointer)
   |
Task 11 (loop-setup SKILL + import-triage slim)
   |
Task 12 (loop-review slim)
   |
Task 13 (loop-auto SKILL + handoff slim)
   |
Task 14 (regenerate registry, full tests/run.sh, toy happy-path chain, verify all criteria, close ledger)
```

Rationale for low parallelism is recorded so a driver does not "fix" it into a race: the shared generated registry and single ledger make the spine correct-by-construction. A driver MAY parallelize only reference-only edits that touch neither a `loop-*/SKILL.md` nor the ledger in the same unit; none are split out here because each reference is grouped with its owning skill for ledger-append safety.

## Human checkpoints

- **After Task 14, before merge:** the "chain behaves as before" confirmation is irreducibly behavioral. The executed smoke (Task 14) proves the artifacts load, lint, and pass gates; a human confirms the toy happy-path run's *judgment* output (a brief, a plan, a One-Minute-Test verdict, a loop-drive Step 0 routing) reads as equivalent to pre-molt. Record the confirmation in the batch-review journal.
- **Any task whose subtraction cannot reach its line budget without removing a block the executor judges POLICY:** stop, keep the block, record the shortfall as a ledger note and a finding for the driving session - do not cut policy to hit a number.
- **Spec-problem criteria (skill count, line count):** Task 14 records the achieved numbers; a human accepts the documented shortfall or escalates.

## How to run

```bash
# from repo root: /Users/jjrdar/create/loops/loop-stack-molt  (worktree branch molt-cycle-1)
tests/run.sh                                   # full gate suite; must exit 0
scripts/gen-gate-registry.sh .                 # regenerate docs/gate-registry.md (deterministic)
bash tests/gates/check.sh                      # registry fresh + scanner catch alive
git diff v1-pre-molt --stat -- skills/         # line-count criterion
ls skills/ | wc -l                             # skill-count criterion
```

Each SKILL-editing task ends by running `scripts/gen-gate-registry.sh .` then `tests/run.sh`, and committing the regenerated `docs/gate-registry.md` alongside the edit.

---

### Task 1: Open the drift ledger for cycle 3

Depends on: none

**Files (exclusive ownership):**
- Modify: `docs/molt-ledger.md` (append the cycle-3 opening entry; later tasks append their per-artifact deletion blocks)

**Interfaces:**
- Produces: the ledger entry header `## 2026-08-15 - molt cycle 1 brief 3 (slim/fold/dedup)` and the per-entry field shape (`Harness snapshot`, `Deleted: <bin> N (...)`, `Kept as policy`, `Premises`, `Constraints re-confirmed`) that every later task appends one block under, per artifact.
- Consumes: nothing.

**Acceptance check:** `grep -q '2026-08-15 - molt cycle 1 brief 3' docs/molt-ledger.md && grep -q 'v2.1.204' docs/molt-ledger.md` exits 0 `[executed-check]`

- [ ] Step 1: Append an opening block to `docs/molt-ledger.md`: date `2026-08-15`; `Harness snapshot: v2.1.204 (native parallel background fan-out with notifications verified unprompted 2026-08-15; /workflows off)`; `Constraints re-confirmed:` portability/ringer-spine, Fable-never-worker, single-home-plus-pointers, /workflows-off (from both briefs' registers).
- [ ] Step 2: State in the block that per-artifact deletion sub-blocks follow, newest last, one per slimmed/retired artifact.
- [ ] Step 3: Run the acceptance check; expect exit 0.
- [ ] Step 4: Commit - `git add docs/molt-ledger.md && git commit -m "molt cycle 1 brief 3: open drift ledger entry (harness v2.1.204)"`

---

### Task 2: Retire frontier-sandwich (infra + reference move)

Depends on: Task 1

Molt bin: the frontier-sandwich SKILL body is CHOREOGRAPHY (interview cadence, phase-by-phase narration the harness/frontier model runs unprompted) + POLICY-keep (tier vocabulary, effort dial, sandwich invariant, fan-out loop-readiness) which relocates to loop-drive in Task 6. This task does the retirement plumbing; no policy is lost (it moves).

**Files (exclusive ownership):**
- Delete: `skills/frontier-sandwich/SKILL.md`, `skills/frontier-sandwich/references/fable-guidelines.md` (git-moved, see below), `skills/frontier-sandwich/` (whole dir, including the untracked `references/model-benchmarks.md` symlink)
- Create (git mv): `skills/loop-drive/references/fable-guidelines.md` (moved from frontier-sandwich, slimmed to the kept-policy essentials: tier table, effort defaults, prompt/pitfall patterns; delete the interview and save-the-plan choreography)
- Modify: `install.sh`, `.gitignore`, `tests/gates/frontier-sandwich.sh`
- Modify: `docs/molt-ledger.md` (append the frontier-sandwich deletion block)

**Interfaces:**
- Consumes: the ledger entry shape from Task 1.
- Produces: the moved benchmark leaf path `skills/loop-drive/references/model-benchmarks.md` (install-generated symlink to `config/routing/model-benchmarks.md`) that Task 6 names in loop-drive Step 2; the moved reference path `skills/loop-drive/references/fable-guidelines.md` that Task 6's human-paced-mode section points to.

**Acceptance check:** `tests/run.sh` exits 0 (with the rewritten `frontier-sandwich.sh`) AND `test ! -e skills/frontier-sandwich` AND `grep -Eq 'for old in .*frontier-sandwich' install.sh` `[executed-check]`

- [ ] Step 1: In `install.sh`, add `frontier-sandwich` to the retire list: change `for old in frontier-loop one-minute-test fable-sandwich; do` to include `frontier-sandwich`. (This drives `retire_skill` on the installed symlink/dir without breaking existing installs - the mechanism already backs up real dirs once and removes symlinks.)
- [ ] Step 2: In `install.sh`, retarget the benchmark-prior symlink block (currently `FS_REFS="$SKILLS_DIR/frontier-sandwich/references"` and the `if [ -d "$SKILLS_DIR/frontier-sandwich" ]` guard, ~lines 105-113) to `LD_REFS="$SKILLS_DIR/loop-drive/references"` guarded on `[ -d "$SKILLS_DIR/loop-drive" ]`, linking `$LD_REFS/model-benchmarks.md -> $REPO/config/routing/model-benchmarks.md`. Update the self-check (~lines 156-158) to test `[ -L "$SKILLS_DIR/loop-drive/references/model-benchmarks.md" ]`.
- [ ] Step 3: `git mv skills/frontier-sandwich/references/fable-guidelines.md skills/loop-drive/references/fable-guidelines.md`, then slim it to the kept policy (tier table, effort defaults, prompt patterns, pitfalls); delete the interview-cadence and save-the-plan choreography. Record the CLAUDE.md-guidance content only if loop-drive's mode section will cite it; otherwise cut.
- [ ] Step 4: `git rm -r` the rest of `skills/frontier-sandwich/`. In `.gitignore`, change line `skills/frontier-sandwich/references/model-benchmarks.md` to `skills/loop-drive/references/model-benchmarks.md`.
- [ ] Step 5: Rewrite `tests/gates/frontier-sandwich.sh` as a retirement-PLUMBING contract (scoped to what is true at THIS task's position, so `tests/run.sh` is green here - the cross-skill reference conversions land in Tasks 4/5/6, so the repo-wide "no live reference" grep is Task 14's, not this task's; Rubix A1). It asserts only: `skills/frontier-sandwich/SKILL.md` is ABSENT; `install.sh` names `frontier-sandwich` in the retire list (`grep -Eq 'for old in .*frontier-sandwich' install.sh`); the benchmark leaf is now `skills/loop-drive/references/model-benchmarks.md`, is NOT git-tracked (`git ls-files --error-unmatch` fails) and IS gitignored (`git check-ignore -q`). Rename the file to `tests/gates/frontier-sandwich-retired.sh` OR keep the name; keep it a standalone suite `tests/run.sh` discovers.
- [ ] Step 6: Append the frontier-sandwich block to `docs/molt-ledger.md`: `Deleted: CHOREOGRAPHY (interview cadence, phase narration), duplication (fan-out loop-readiness now single-homed in loop-drive Step 3)`; `Kept as policy (relocated to loop-drive): tier vocabulary, effort dial, sandwich invariant`.
- [ ] Step 7: Run `scripts/gen-gate-registry.sh .` (frontier-sandwich has no `loop-*` prefix, so the registry is unchanged - regenerate to confirm no drift), then `tests/run.sh`; expect exit 0.
- [ ] Step 8: Commit - `git add -A && git commit -m "molt: retire frontier-sandwich, move benchmark leaf + fable-guidelines to loop-drive"`

---

### Task 3: Establish the routing-chain canonical home

Depends on: Task 2

Molt bin: dedup (the same routing-chain narrative currently restated in 5 sites; PLUMBING-style duplication). The narrative content itself is POLICY (P7 route-by-evidence) and is KEPT - consolidated to one home.

**Files (exclusive ownership):**
- Modify: `config/routing/model-benchmarks.md` (add a `## Routing chain` section holding the canonical three-tier narrative)
- Modify: `docs/molt-ledger.md` (append the dedup block)

**Interfaces:**
- Consumes: nothing (this is the home other tasks point at).
- Produces: the canonical section and the exact pointer sentence other skills adopt: `Per-unit model choice follows the routing chain (config/routing/model-benchmarks.md).` The distinctive narrative phrase `scoreboard posterior, else benchmark prior, else orchestrator pin` must appear ONLY in this file after Tasks 5/6/10 convert the other sites.

**Acceptance check:** `grep -q 'scoreboard posterior' config/routing/model-benchmarks.md && grep -q 'Routing chain' config/routing/model-benchmarks.md` exits 0 `[executed-check]`

- [ ] Step 1: Append a `## Routing chain` section to `config/routing/model-benchmarks.md` holding the canonical narrative verbatim-in-spirit from loop-drive Step 2: the three tiers (1. integrity-gated scoreboard posterior via `./ringer.py models --task-type`, read MODEL-NOTES/AMENDMENTS-PENDING first; 2. else benchmark prior = this file's rows; 3. else orchestrator pin with recorded reason), the `claude-zai` tie-break, the promotion ladder (untested/probation/proven at 3+), the Fable-never-a-worker roster note, AND the ringer-absent degraded-routing fallback (Rubix A6): "if the Step 0 probe reported ringer absent, skip tier 1 entirely and route every unit by benchmark prior" - this is operative portability policy for a ringer-less machine, not narrative, and must survive the dedup, not be swept into it.
- [ ] Step 2: State at the top of the section that this is the single home; skills carry one pointer line, never a restatement.
- [ ] Step 3: Append the ledger dedup block: `Deleted: routing-chain narrative restated in 5 sites -> 1 home + pointers (loop-drive, wayfinder, ringer-substrate, loop-which[retired], frontier-sandwich[retired])`.
- [ ] Step 4: Run the acceptance check; expect exit 0. (No registry impact; `config/` is not scanned.)
- [ ] Step 5: Commit - `git add config/routing/model-benchmarks.md docs/molt-ledger.md && git commit -m "molt: single-home the routing-chain narrative in config/routing/model-benchmarks.md"`

---

### Task 4: loop-brainstorm - absorb the One-Minute Test front door + slim choreography

Depends on: Task 3

Molt bin: added Step 0 relocates POLICY (One-Minute Test triage, P6/C6) to the chain's front door; the slim deletes CHOREOGRAPHY (enumerated probe cadences the frontier model runs unprompted) and dedup (brief-graduation narration currently restated in loop-brainstorm Step 8 AND loop-improve Step 6 -> single-homed in `brief-pipeline.md`). Shaping capability (scope probes, domain modeling, question generation, seams, parking lot) is KEPT per the constraint register.

**Files (exclusive ownership):**
- Modify: `skills/loop-brainstorm/SKILL.md` (add Step 0 One-Minute Test front-door triage; slim the probe-cadence choreography; reduce Step 8 graduation to a pointer + the required invocation line; repoint the Step 9 `frontier-sandwich` handoff to loop-drive's human-paced mode - Rubix A3)
- Create (git mv from loop-which): `skills/loop-brainstorm/references/one-minute-test.md` (moved from `skills/loop-which/references/one-minute-test.md` and slimmed here in THIS task, so no committed tree ever points at a file that does not exist yet - Rubix B5)
- Modify: `skills/loop-brainstorm/references/brief-pipeline.md` (receive the SHARED graduation contract as its single home - the `graduate-parking.sh` invocation contract plus the parking-lot bullet-shape/title-truncation rule, both currently duplicated across brainstorm Step 8 and improve Step 6; rewrite the two "graduation is NOT here" disclaimers at `:7` and `:64` to say the shared contract now lives here while each skill keeps its own terminal step - Rubix B1)
- Modify: `docs/molt-ledger.md` (append the brainstorm slim block)

Graduation-dedup scope (Rubix B1): only the SHARED contract moves. loop-improve's `Supersedes: #N` supersede-close (close-covered-issues-at-brief-time) is improve-ONLY policy and stays in loop-improve (Task 8) - it is NOT moved here. This corrects the stale on-disk "graduation is per-skill" comment to match the brief's Task 3 single-home mandate, preserving the one real divergence.

**Interfaces:**
- Consumes: the canonical routing home path from Task 3 (brainstorm does not restate routing; it carries no routing narrative today, so no pointer edit needed - confirm by grep).
- Produces: the front-door Step 0 contract: a One-Minute Test triage that exits CHAT / DON'T BOTHER before shaping spend, else proceeds; its gate tag (`[gate:DEFAULT]` for the verdict, or `[gate:ASK]` if it asks the availability question). Later loop-drive Step 0 (Task 6) points here for the reference, not to a loop-which skill.

**Acceptance check:** `scripts/gen-gate-registry.sh . && tests/run.sh` exits 0 AND `test -f skills/loop-brainstorm/references/one-minute-test.md` AND `grep -qi 'One-Minute Test' skills/loop-brainstorm/SKILL.md` AND `grep -q 'graduate-parking\|bullet' skills/loop-brainstorm/references/brief-pipeline.md` (shared graduation contract landed) AND `bash tests/gates/loop-brainstorm.sh` passes (domain-modeling probe + Reading-the-user block + graduation wiring still present) `[executed-check]`

- [ ] Step 1: `git mv skills/loop-which/references/one-minute-test.md skills/loop-brainstorm/references/one-minute-test.md`; slim it (keep the seven questions and the tax-folder/product-naming/dishwasher worked examples that keep verdicts honest; cut re-stated framing). Doing the move in THIS task (not Task 5) means no committed tree ever references a nonexistent file (Rubix B5).
- [ ] Step 2: Add `## Step 0 - Front-door triage (One-Minute Test)` before Step 1 in `skills/loop-brainstorm/SKILL.md`: run the One-Minute Test (`references/one-minute-test.md`) as the chain's first question; a CHAT or DON'T BOTHER verdict exits before any shaping spend; otherwise proceed to Step 1. Tag the verdict gate.
- [ ] Step 3: Slim the choreography: compress the enumerated three-scope-probes + domain-modeling narration to their decision content (keep the probes' NAMES and what each catches; delete step-by-step "run these in this order" cadence prose). Keep the "Reading the user" block untouched (Jeremy-maintained; `loop-brainstorm.sh` asserts it survives). Keep the HARD-GATE, the frontier-rounds rule, and all shaping structure.
- [ ] Step 4: Brief-graduation single-home (Rubix B1, scoped): move the SHARED contract into `skills/loop-brainstorm/references/brief-pipeline.md` as its single home - the `graduate-parking.sh` invocation contract (preview count + derived title, assent, one `idea`-issue per item, announce number+title, reverse with `scripts/tracker.sh close`) AND the parking-lot bullet-shape/title-truncation rule (period-free/filename-free first sentence, `Restart context:` continuation). Rewrite `brief-pipeline.md:7` and `:64` from "graduation is NOT here" to "the shared graduation contract lives here; each skill keeps only its own terminal step and any skill-specific close." Leave in brainstorm Step 8 only: the required `graduate-parking.sh` invocation line and a `[gate:DEFAULT]` gate with a one-line pointer to the reference (keeps `loop-brainstorm.sh`'s greps for `graduate-parking.sh` and `preview|confirm|assent|DEFAULT` satisfied). Do NOT move any supersede logic - improve-only (Task 8).
- [ ] Step 5: Repoint the retired-skill handoff (Rubix A3): in brainstorm Step 9, rewrite the terminal-state route "`frontier-sandwich` for a human-paced run-book" to "**/loop-drive** for a human-paced run-book (its human-paced output mode)". loop-drive already exists as a skill, so the pointer is live even before Task 6 adds the explicit mode section.
- [ ] Step 6: Confirm brainstorm restates no routing narrative (`grep -c 'scoreboard posterior' skills/loop-brainstorm/SKILL.md` is 0); if any appears, replace with the Task 3 pointer line.
- [ ] Step 7: Probe (executable, recorded - Rubix B4): dispatch the brainstorm front door on a one-line toy idea ("add a --dry-run flag to tracker.sh"); confirm it returns a triage verdict then a shaped brief skeleton (Outcome/Done/Criteria/Seams). Paste the probe's actual output into the commit body (or a scratch note referenced by it) so a later bisect can see this slim did not degrade the shaping lane at its own commit, not only at Task 14.
- [ ] Step 8: Append the ledger block for the brainstorm slim (CHOREOGRAPHY deleted, shaping kept), the One-Minute-Test relocation, and the graduation dedup (note: PREMISE re-evaluated - the on-disk "graduation is per-skill" comment predated and contradicted the brief's single-home mandate; shared contract single-homed, improve supersede kept divergent).
- [ ] Step 9: Run `scripts/gen-gate-registry.sh .` then `tests/run.sh`; expect exit 0. Commit - `git add -A && git commit -m "molt: brainstorm gains One-Minute Test front door, choreography + graduation slimmed"`

---

### Task 5: Retire loop-which + rehome the One-Minute Test reference

Depends on: Task 4

Molt bin: the loop-which SKILL body is CHOREOGRAPHY (step-by-step scoring narration) wrapping POLICY (the One-Minute Test); the policy relocated to the front door and its reference moved in Task 4. This task removes the dir and retires the installed skill cleanly. No policy deleted.

**Files (exclusive ownership):**
- Delete: `skills/loop-which/SKILL.md`, `skills/loop-which/` (whole dir; `one-minute-test.md` already git-moved out in Task 4)
- Modify: `install.sh` (add `loop-which` to the `for old in ...` retire list so an already-installed machine's stale symlink is retired, not left dangling - Rubix A2/B3, mirroring Task 2's frontier-sandwich handling)
- Modify: `tests/gates/tags.sh` (drop `loop-which` from the `SKILLS=` list), `tests/gates/loop-which.sh` (rewrite as a retirement contract, or delete and let `loop-brainstorm.sh` cover the front door)
- Modify: `docs/molt-ledger.md` (append the loop-which retirement block)

**Interfaces:**
- Consumes: the front-door Step 0 and the rehomed `one-minute-test.md` from Task 4.
- Produces: the retirement (dir absent, `loop-which` in install.sh's retire list) that Task 6's loop-drive Step 0 pointer and Task 14's repo-wide reference sweep rely on.
- Post-retire gate counts (verified pre-plan): ASK 4, STOP 6, BATCH 4, DEFAULT 10 - all at/above the existing `tags.sh` floors (3/6/4/8), so floors do NOT change; only the `SKILLS=` list loses `loop-which`.

**Acceptance check:** `scripts/gen-gate-registry.sh . && tests/run.sh` exits 0 AND `test ! -e skills/loop-which` AND `grep -Eq 'for old in .*loop-which' install.sh` (retire list names it) `[executed-check]`

- [ ] Step 1: `git rm -r skills/loop-which/` (the `one-minute-test.md` reference is already at its brainstorm home from Task 4).
- [ ] Step 2: In `install.sh`, add `loop-which` to the retire list (`for old in frontier-loop one-minute-test fable-sandwich frontier-sandwich loop-which; do`, where `frontier-sandwich` was added in Task 2). This drives `retire_skill` on the installed `~/.claude/skills/loop-which` (and the `~/.agents/skills` copy in agents style) so no stale symlink loads side by side with the survivors - the exact failure the retire list at `install.sh:82` exists to prevent.
- [ ] Step 3: In `tests/gates/tags.sh`, change `SKILLS="loop-brainstorm loop-plan loop-drive loop-which"` to `SKILLS="loop-brainstorm loop-plan loop-drive"`. Leave the per-type floors (ASK:3 STOP:6 BATCH:4 DEFAULT:8) unchanged - post-retire counts stay at/above them.
- [ ] Step 4: Rewrite `tests/gates/loop-which.sh` -> `tests/gates/loop-which-retired.sh`: assert `skills/loop-which/SKILL.md` ABSENT; `install.sh` names `loop-which` in the retire list (`grep -Eq 'for old in .*loop-which' install.sh`); `skills/loop-brainstorm/references/one-minute-test.md` present with the One-Minute Test body; `skills/loop-brainstorm/SKILL.md` names the One-Minute Test front door. Keep it a standalone suite `tests/run.sh` discovers.
- [ ] Step 5: Grep the repo for stale `loop-which` skill-invocation references (other SKILLs) and convert them to "the One-Minute Test front door" - EXCEPT files owned by later tasks (loop-drive in Task 6). README rows are updated in Task 14's doc pass; note them, do not edit README here (Task 14 owns README to avoid split ownership). Confirm no owned-file dangling pointer.
- [ ] Step 6: Append the ledger block (loop-which retired, One-Minute Test relocated, no policy lost; NOTE the deliberate decision - the standalone "is this worth automating / DON'T BOTHER" invocation trigger is retired, its routing question now caught by loop-drive's extended frontmatter in Task 6 - Rubix A5, recorded so a future cycle sees a decision, not drift).
- [ ] Step 7: Run `scripts/gen-gate-registry.sh .` then `tests/run.sh`; expect exit 0. Commit - `git add -A && git commit -m "molt: retire loop-which, rehome One-Minute Test to the brainstorm front door"`

---

### Task 6: loop-drive becomes the compile+drive policy sheet

Depends on: Task 5

Molt bin: DELETE PLUMBING/CHOREOGRAPHY (prose re-describing decomposition, fan-out, background execution, notifications, and GENERIC single-repo worktree-creation the harness does unprompted - verified v2.1.204). KEEP POLICY: checks-or-stall, validator contract (never fixes / independent rerun / pass-fail-spec-problem), per-unit routing TABLE, gate classes (pointer to loop-auto), run-state format, check custody, ringer footguns (in `ringer-substrate.md`), AND the three Agent-tool worktree HAZARDS the harness does NOT handle (Rubix A4): nested-repo `isolation: worktree` snapshots the WRONG repo (needs explicit `git -C <inner-repo> worktree add`), per-worktree in-project venvs do not travel (install step inside the worktree), and shared append-only files must convert to one-file-per-unit. These read like plumbing but are correctness policy - the SKILL itself documents the harness gets the nested-repo case wrong, and test-by-subtraction won't catch their loss (the toy chain exercises no nested repo or venv). Absorb frontier-sandwich's human-paced mode. This is the highest-blast-radius task.

**Files (exclusive ownership):**
- Modify: `skills/loop-drive/SKILL.md` (the policy-sheet slim; extend the frontmatter `description` to absorb the retired skills' trigger phrases - project kickoff, "break a task into prompts", model routing / "which model should do this", human-paced run-book, and "is this worth automating / how should I run this plan" - so the folded capabilities and the standalone triage question still have a firing skill, Rubix A3/A5; add human-paced-mode section; routing narrative -> one pointer; repoint loop-which -> One-Minute Test reference; update benchmark leaf path to loop-drive's own)
- Modify: `skills/loop-drive/references/native-orchestration.md` (delete plumbing prose; keep only native-lane policy not covered in SKILL)
- Modify: `skills/loop-drive/references/ringer-substrate.md` (keep footguns as the single home; convert its routing line to the Task 3 pointer; slim)
- Modify: `skills/loop-drive/references/example-output-plan.md` (slim hard, or delete if the SKILL's emitted-plan spec is self-sufficient - decide by subtraction)
- Modify: `docs/molt-ledger.md` (append the loop-drive block)

**Interfaces:**
- Consumes: the canonical routing home (Task 3), the moved `fable-guidelines.md` + benchmark leaf path (Task 2), the rehomed `one-minute-test.md` (Task 5).
- Produces: loop-drive's kept policy surface (routing table columns Unit/Wave/task_type/Model/Transport/Engine/effort/Evidence; validator contract; gate classes; run-state; check custody) that downstream loop-review/loop-auto rely on unchanged.

**Acceptance check:** `scripts/gen-gate-registry.sh . && tests/run.sh` exits 0 AND `bash tests/gates/loop-drive.sh` passes (compile dispatch, existing-`_loop.md` entry, STOP split, sized-BATCH spec-edit rule all still present) AND `grep -c 'scoreboard posterior' skills/loop-drive/SKILL.md` is 0 (routing narrative now a pointer) AND `grep -qi 'nested' skills/loop-drive/SKILL.md` (nested-repo hazard kept as policy, Rubix A4) AND `grep -riq 'ringer absent\|ringer-absent' skills/loop-drive/SKILL.md config/routing/model-benchmarks.md` (degraded-routing fallback survives, Rubix A6) `[executed-check]`

- [ ] Step 1: Native-lane policy sheet: in `skills/loop-drive/SKILL.md`, keep the KEEP list verbatim-in-spirit (checks-or-stall gate P6; the three-tier validation layers and the `{verdict: pass|fail|spec-problem}` contract; the per-unit routing table; the gate-class pointer to loop-auto; the run-state/resume format; check custody). KEEP AS POLICY (Rubix A4) the three worktree hazards - nested-repo wrong-snapshot (`git -C <inner-repo> worktree add`), per-worktree venv install, shared-append-to-per-unit conversion. DELETE prose re-describing: wave derivation mechanics, parallel background Agent launches, completion notifications, and GENERIC single-repo worktree creation - the harness does these unprompted. Replace each deleted mechanic with at most a one-line policy statement if a policy rides on it. GATE-TAG GUARD (Rubix B6): this file holds all 6 STOP and 3 BATCH gate tags that sit exactly at the `tags.sh` floor - preserve every `[gate:STOP]` and `[gate:BATCH]` tag verbatim; a slim that drops any one fails `tests/run.sh`.
- [ ] Step 2: Routing narrative -> pointer: replace loop-drive Step 2's three-tier restatement (lines ~74-80) with the Task 3 pointer, KEEPING the per-unit routing TABLE, task_type vocabulary, effort caps, transport-derivation rule, and roster (these are policy, not the narrative). The ringer-absent degraded-routing line (`:75`) is operative policy, not narrative (Rubix A6): it now lives in the Task 3 canonical home - either leave a one-line ringer-absent policy in the SKILL or rely on the pointer, but do NOT drop it (the Task 6 acceptance greps that it survives in the SKILL or the config home). After the edit, `scoreboard posterior` must not appear in this SKILL.
- [ ] Step 3: Human-paced mode: add a compact `## Human-paced output mode (absorbs frontier-sandwich)` section - the sandwich invariant (frontier judgment before/after cheap execution, never frontier keystrokes in the middle), tier vocabulary + effort defaults by pointer to `references/fable-guidelines.md`, and the one-file-vs-numbered-files output shape. This is the fold, not a re-paste of frontier-sandwich's choreography.
- [ ] Step 4: Repoint loop-which: Step 0 currently says "Run the loop-which verdict"; change to "Run the One-Minute Test verdict (`skills/loop-brainstorm/references/one-minute-test.md`; the front-door triage)". Update the benchmark-leaf path reference in Step 2 from `frontier-sandwich skill's references/model-benchmarks.md` to `references/model-benchmarks.md` (loop-drive's own leaf). Extend the frontmatter `description` (Rubix A3/A5) so loop-drive fires on the folded/retired triggers: project kickoff, "break a task into prompts", model routing ("which model should do this"), human-paced run-book, and "is this worth automating / how should I run this plan"; keep the existing autonomous-orchestration triggers.
- [ ] Step 5: Ringer footgun single-home: the three footguns (worktree-deleted-on-pass/patch-export, gitignored-outputs, opencode stagger) are currently in BOTH loop-drive Step 3 AND `ringer-substrate.md`. Delete them from loop-drive/SKILL.md Step 3, leaving one pointer line to `references/ringer-substrate.md`; keep them in `ringer-substrate.md` as the single home. (Check custody stays in the SKILL - it is a both-transports POLICY invariant, not a ringer footgun.)
- [ ] Step 6: References: in `native-orchestration.md` delete decomposition/fan-out/background/notification prose, keeping only native-lane policy the SKILL does not already state (likely near-empty; delete the file if nothing policy-bearing survives, and drop the SKILL's pointer to it). In `ringer-substrate.md` convert its routing line to the Task 3 pointer and slim narrative around the retained footguns. In `example-output-plan.md` cut to a minimal skeleton or delete if the SKILL's Step 6 emit-spec stands alone.
- [ ] Step 7: Probe (executable, recorded - Rubix B4): actually compile a two-unit toy plan through loop-drive Step 0-2 (dispatch it, do not walk it "mentally"); confirm it emits a routing table, the validator contract, check-custody enforcement, the ringer-absent fallback when the Step 0 probe reports ringer absent, and a Step 0 verdict + next command. Paste the probe's actual emitted compile artifact into the commit body (or a scratch note it references) so a later bisect can localize any degradation to THIS commit, not only to Task 14's human checkpoint.
- [ ] Step 8: Append the ledger block (bin-tagged deletions: PLUMBING - fan-out/background/notifications/worktree; CHOREOGRAPHY - wave-derivation narration; dedup - routing narrative + ringer footguns single-homed; KEEP list enumerated).
- [ ] Step 9: Run `scripts/gen-gate-registry.sh .` then `tests/run.sh`; expect exit 0. Commit - `git add -A && git commit -m "molt: loop-drive -> policy sheet, absorbs frontier-sandwich, routing + footguns single-homed, native lane cut"`

---

### Task 7: loop-plan slim

Depends on: Task 6

Molt bin: DELETE CHOREOGRAPHY (step-narration the frontier model runs unprompted). KEEP POLICY: the HARD-GATE, the header+task template, the loop-drive contract (depends-on / exclusive ownership / executed-check), the no-placeholder rule, the plan-draft dispatch, the prefactor rule.

**Files (exclusive ownership):**
- Modify: `skills/loop-plan/SKILL.md`
- Modify: `docs/molt-ledger.md`

**Interfaces:**
- Consumes: nothing new.
- Produces: unchanged plan-template contract downstream loop-drive/loop-which consume.

**Acceptance check:** `scripts/gen-gate-registry.sh . && tests/run.sh` exits 0 AND `bash tests/gates/loop-plan.sh` passes (plan-draft dispatch + dependency-graph review + prefactor/expand-contract all present) `[executed-check]`

- [ ] Step 1: Slim the Step-by-step narration (Steps 1-8) to decision content; keep the header template, task template, code policy, no-placeholder list, self-review checklist, and the loop-aware-structure rules verbatim-in-spirit (these are the teeth). Target budget: 222 -> ~150 lines. GATE-TAG GUARD (Rubix B6): this file's `[gate:BATCH]` tag is one of only 4 at the `tags.sh` floor - preserve it verbatim.
- [ ] Step 2: Confirm no routing narrative restated (grep `scoreboard posterior` = 0).
- [ ] Step 3: Probe (executable, recorded - Rubix B4): run loop-plan's decompose on a two-task toy brief; confirm it still emits header + tasks with depends-on/exclusive-ownership/executed-check. Paste the emitted plan skeleton into the commit body (or a referenced scratch note) so a degradation localizes to this commit.
- [ ] Step 4: Append ledger block. Run `scripts/gen-gate-registry.sh .` then `tests/run.sh`; expect 0. Commit - `git add -A && git commit -m "molt: loop-plan choreography slimmed, template + contract kept"`

---

### Task 8: loop-improve + audit-playbook slim

Depends on: Task 7

Molt bin: DELETE CHOREOGRAPHY (procedural narration). KEEP POLICY: read-only HARD-GATE, findings-table contract, tracker-scan wiring, ASK/DEFAULT gates, the `--focus harness-drift` delegation (premise), full audit capability (constraint register: keep shaping), and the `Supersedes: #N` supersede-close (close-covered-issues-at-brief-time) as improve-ONLY policy - NOT moved to the shared home (Rubix B1).

**Files (exclusive ownership):**
- Modify: `skills/loop-improve/SKILL.md`, `skills/loop-improve/references/audit-playbook.md`
- Modify: `docs/molt-ledger.md`

**Interfaces:**
- Consumes: the shared `brief-pipeline.md` (unchanged here).
- Produces: unchanged findings-table + delegation contract that `loop-improve.sh` and `molt.sh` assert.

**Acceptance check:** `scripts/gen-gate-registry.sh . && tests/run.sh` exits 0 AND `bash tests/gates/loop-improve.sh` passes (columns, covered/related, tracker scan, ASK/DEFAULT, graduate-parking, supersede) `[executed-check]`

- [ ] Step 1: Slim `audit-playbook.md` category prose to the checkable finding criteria (188 -> ~120); keep the Finding format and every category's file:line-evidence rule.
- [ ] Step 2: Slim `loop-improve/SKILL.md` narration; keep the read-only gate, the eight-column table contract, the `--focus harness-drift` one-line delegation (no audit method duplicated - `molt.sh` asserts this). Reduce the Step 6 graduation restatement (the shared `graduate-parking.sh` invocation contract + bullet-shape rule) to a pointer at `brief-pipeline.md` (its single home from Task 4), leaving the required `graduate-parking.sh` and `Parking lot` lines that `loop-improve.sh` greps. KEEP verbatim (improve-only, Rubix B1) the supersede-close block: the `Supersedes: #N` recording and the `scripts/tracker.sh close <num>` close-covered-issues-at-brief-time policy - this does NOT move to the shared home. Rewrite the now-stale `loop-improve/SKILL.md:76` sentence ("The shared reference contains NO graduation...") to point at the shared graduation contract while noting the supersede-close remains improve's own.
- [ ] Step 3: Probe: run an improve audit (quick effort) on this repo; confirm a file:line findings table renders with the eight columns and the tracker column. No degradation.
- [ ] Step 4: Append ledger block. Regenerate registry, `tests/run.sh`; expect 0. Commit - `git add -A && git commit -m "molt: loop-improve + audit-playbook slimmed, contracts kept"`

---

### Task 9: loop-molt + protocol slim

Depends on: Task 8

Molt bin: DELETE CHOREOGRAPHY (step pointers that merely restate the protocol's running order). KEEP POLICY: the one-line test, the ASK constraint-register gate, the single-home bins invariant (bins DEFINED only in `protocol.md` - `molt.sh` enforces), the brief-pipeline routing, the ledger-home name.

**Files (exclusive ownership):**
- Modify: `skills/loop-molt/SKILL.md`, `skills/loop-molt/references/protocol.md`
- Modify: `docs/molt-ledger.md`

**Interfaces:**
- Consumes: nothing new.
- Produces: unchanged - `molt.sh` asserts bins live only in `protocol.md`, the ASK gate, `docs/molt-ledger.md` named, and the loop-improve delegation.

**Acceptance check:** `scripts/gen-gate-registry.sh . && tests/run.sh` exits 0 AND `bash tests/gates/molt.sh` passes (bins single-homed, ASK gate, ledger name `docs/molt-ledger.md`, delegation) `[executed-check]`

- [ ] Step 1: Slim `protocol.md` to the method essentials (98 -> ~78); keep the four-bin definitions (their single home), the policy-membership test, the subtraction test, and the constraint-register-first rule.
- [ ] Step 2: Slim `loop-molt/SKILL.md` step pointers; keep the one-line test, the ASK gate, the reference pointer, the brief-pipeline routing, and `docs/molt-ledger.md`. Do NOT let bin UPPERCASE tokens leak into SKILL.md (`molt.sh` fails if they do).
- [ ] Step 3: Append ledger block. Regenerate registry, `tests/run.sh`; expect 0. Commit - `git add -A && git commit -m "molt: loop-molt + protocol slimmed, bins single-home intact"`

---

### Task 10: wayfinder slim + routing pointer

Depends on: Task 9

Molt bin: DELETE CHOREOGRAPHY (procedural narration). KEEP POLICY: the plan-don't-do rule, the map/ticket schema, ticket types, fog/out-of-scope discipline, one-ticket-per-session, the loop-plan hand-off. Convert the routing line to the Task 3 pointer.

**Files (exclusive ownership):**
- Modify: `skills/wayfinder/SKILL.md`
- Modify: `docs/molt-ledger.md`

**Interfaces:**
- Consumes: the canonical routing home (Task 3).
- Produces: unchanged - `wayfinder.sh` asserts labels, loop-plan/loop-brainstorm hand-offs, and mirror exclusion.

**Acceptance check:** `scripts/gen-gate-registry.sh . && tests/run.sh` exits 0 AND `bash tests/gates/wayfinder.sh` passes AND `grep -c 'scoreboard posterior' skills/wayfinder/SKILL.md` is 0 `[executed-check]`

- [ ] Step 1: Convert wayfinder's routing line ("Per-ticket model choice follows the loop-drive evidence chain: scoreboard posterior, else benchmark prior, else orchestrator pin.") to the Task 3 pointer: `Per-ticket model choice follows the routing chain (config/routing/model-benchmarks.md).`
- [ ] Step 2: Slim narration (183 -> ~125); keep the schema blocks, ticket types, fog/out-of-scope rules, one-ticket-per-session, and both invocation modes' decision content.
- [ ] Step 3: Append ledger block. Regenerate registry, `tests/run.sh`; expect 0. Commit - `git add -A && git commit -m "molt: wayfinder slimmed, routing single-homed"`

---

### Task 11: loop-setup + import-triage slim

Depends on: Task 10

Molt bin: DELETE CHOREOGRAPHY (procedural narration of setup.sh). KEEP POLICY: the no-`none`-mode decision, the three-mode presentation rule, `tracker-remote-ack`, the import-sweep triage judgment, attended-only. `setup.sh` (492 lines of code) is NOT slimmed.

**Files (exclusive ownership):**
- Modify: `skills/loop-setup/SKILL.md`, `skills/loop-setup/references/import-triage.md`
- Modify: `docs/molt-ledger.md`

**Interfaces:**
- Consumes: nothing new.
- Produces: unchanged - `loop-setup` test suite (`tests/loop-setup/`) asserts behavior via `setup.sh`, unaffected by prose slim.

**Acceptance check:** `scripts/gen-gate-registry.sh . && tests/run.sh` exits 0 (loop-setup suites still pass) `[executed-check]`

- [ ] Step 1: Slim `SKILL.md` (100 -> ~85) and `import-triage.md` (130 -> ~95) to decision content; keep the no-`none` decision, the mode-viability caveats, `tracker-remote-ack`, the triage steps' judgment, and the non-interactive hooks list (tests use them).
- [ ] Step 2: Append ledger block. Regenerate registry, `tests/run.sh`; expect 0. Commit - `git add -A && git commit -m "molt: loop-setup + import-triage slimmed, setup.sh untouched"`

---

### Task 12: loop-review slim

Depends on: Task 11

Molt bin: DELETE CHOREOGRAPHY (procedural narration). KEEP POLICY: the two-axis separation, the disclosure-before-findings contract, the spec-source discovery ladder, the empty-diff trap message, and the Fowler 12-smell baseline VERBATIM (the Standards subagent has no other access to it - deleting it breaks the axis).

**Files (exclusive ownership):**
- Modify: `skills/loop-review/SKILL.md`
- Modify: `docs/molt-ledger.md`

**Interfaces:**
- Consumes: nothing new.
- Produces: unchanged - `tests/loop-review/` asserts behavior.

**Acceptance check:** `scripts/gen-gate-registry.sh . && tests/run.sh` exits 0 (loop-review suites pass) AND `grep -c 'Mysterious Name' skills/loop-review/SKILL.md` is 1 (smell baseline kept verbatim) `[executed-check]`

- [ ] Step 1: Slim the process narration (128 -> ~105); keep the discovery ladder, disclosure contract, empty-diff message, the two subagent prompts, and the full 12-smell baseline verbatim (POLICY - do not compress the smell list).
- [ ] Step 2: Append ledger block. Regenerate registry, `tests/run.sh`; expect 0. Commit - `git add -A && git commit -m "molt: loop-review narration slimmed, smell baseline kept verbatim"`

---

### Task 13: loop-auto + handoff slim

Depends on: Task 12

Molt bin: DELETE CHOREOGRAPHY (command-list restatement). KEEP POLICY: the four gate-class definitions (single home; `knob-consumption.sh` + `loop-auto.sh` assert), the verbatim live-consumption sentence, the batch-review journal format + reversal-path field, the never-spawn-Fable continuation, the per-repo-default rule. handoff (already "near done molting"): keep its four policy blocks.

**Files (exclusive ownership):**
- Modify: `skills/loop-auto/SKILL.md`, `skills/handoff/SKILL.md`
- Modify: `docs/molt-ledger.md`

**Interfaces:**
- Consumes: nothing new.
- Produces: unchanged gate-class taxonomy the whole chain's `[gate:...]` tags reference.

**Acceptance check:** `scripts/gen-gate-registry.sh . && tests/run.sh` exits 0 AND `bash tests/gates/loop-auto.sh` AND `bash tests/gates/knob-consumption.sh` AND `bash tests/gates/loop-auto-keyless.sh` all pass `[executed-check]`

- [ ] Step 1: Slim `loop-auto/SKILL.md` (106 -> ~92); keep the four gate-class definitions, the verbatim sentence `Consumption is live: the knob now governs gate behavior per the four gate classes below.`, the batch-review format with the reversal field, the never-Fable clause, the recognized-phrases list, and `docs/chain-state.md` as source of truth (all asserted by tests).
- [ ] Step 2: Slim `handoff/SKILL.md` only where CHOREOGRAPHY remains (the ledger flagged two cheap candidates); keep the purpose contract, repo-placement convention, required suggested-skills section, and redaction invariant (POLICY).
- [ ] Step 3: Append ledger block. Regenerate registry, `tests/run.sh`; expect 0. Commit - `git add -A && git commit -m "molt: loop-auto + handoff slimmed, gate taxonomy + knob protocol intact"`

---

### Task 14: Regenerate, verify all criteria, close the ledger

Depends on: Task 13

Molt bin: n/a (verification + doc reconciliation).

**Files (exclusive ownership):**
- Modify: `docs/gate-registry.md` (final regeneration), `README.md` (skill-table + narrative rows: drop frontier-sandwich/loop-which rows, note the folds), `docs/molt-ledger.md` (closing summary)

**Interfaces:**
- Consumes: every prior task's output.
- Produces: the criteria verdicts recorded in the batch-review journal / ledger.

**Acceptance check:** all of the following exit 0 in one run `[executed-check]`:
```bash
scripts/gen-gate-registry.sh . && bash tests/gates/check.sh    # registry fresh
tests/run.sh                                                    # full suite green
test "$(ls skills/ | wc -l)" -eq 10                            # accepted count (Jeremy 2026-08-15; <=8 unreachable)
test ! -e skills/frontier-sandwich && test ! -e skills/loop-which
# prose-only line reduction vs tagged baseline (611 fixed script lines excluded per Jeremy 2026-08-15).
# -type f is load-bearing: without it, cat follows the gitignored model-benchmarks.md symlink and
# inflates the count with benchmark data, and the git-derived 2429 baseline excludes it (Rubix B2):
base=2429; cur=$(find skills -name '*.md' -type f -exec cat {} + | wc -l); pct=$(( (base-cur)*100/base ))
echo "prose: ${cur}/${base} lines, ${pct}% cut (target >=40%, <=1457)"; test "$cur" -le 1457
# repo-wide: no live frontier-sandwich/loop-which SKILL-DIR reference survives except install retire
# list + the loop-drive fold pointer (moved here from Task 2 - the conversions land in Tasks 4/5/6, Rubix A1):
test "$(grep -rl 'skills/frontier-sandwich\|skills/loop-which' skills config scripts claude-md 2>/dev/null | wc -l)" -eq 0
# graduation single-home: the shared bullet-shape/title-truncation narration greps to one home, not
# the trivially-retained graduate-parking.sh token (Rubix B1):
test "$(grep -rl 'truncates the title\|period-free' skills/ | wc -l)" -eq 1
grep -q 'truncates the title\|period-free' skills/loop-brainstorm/references/brief-pipeline.md
# routing narrative single-homed:
test "$(grep -rl 'scoreboard posterior' skills/ config/routing/ | wc -l)" -eq 1
grep -q 'scoreboard posterior' config/routing/model-benchmarks.md
# ringer footguns single-homed (only in ringer-substrate.md, not in loop-drive SKILL):
test "$(grep -rl 'opencode' skills/ | wc -l)" -eq 1
# (brief-graduation single-home is verified above by the 'truncates the title' uniqueness grep, Rubix B1)
# every retired/slimmed artifact has a ledger line:
grep -q '2026-08-15 - molt cycle 1 brief 3' docs/molt-ledger.md
```

- [ ] Step 1: Update `README.md`: remove the frontier-sandwich and loop-which skill-table rows and the `skills/frontier-sandwich/`, `skills/loop-which/` tree lines; note frontier-sandwich folded into loop-drive and the One-Minute Test moved to the brainstorm front door; keep the `loop-molt` row (`molt.sh` asserts it).
- [ ] Step 2: Run the full acceptance block above; record each result.
- [ ] Step 3: Record the two resolved-criteria verdicts in the batch-review journal: `ls skills/` = 10 (accepted floor, Jeremy 2026-08-15); prose-only reduction = achieved `${pct}%` vs the 40% target (<=1457 off the 2429 baseline) - if a policy-preserving near-miss, record it for the Task 14 human checkpoint rather than cutting policy.
- [ ] Step 4: Toy happy-path chain (executed smoke + human checkpoint): produce a toy brief via the brainstorm front door, a plan via loop-plan, a One-Minute-Test verdict, and a loop-drive Step 0 routing on the plan; confirm the artifacts lint/gate-pass and read as equivalent to pre-molt. The judgment equivalence is the human checkpoint; the load/lint/gate is the executed part.
- [ ] Step 5: Append the ledger closing summary (skills 12 -> 10; prose reduction achieved; constraints re-confirmed; done-molting verdict per artifact). Run `scripts/gen-gate-registry.sh .` and `tests/run.sh` a final time; expect 0.
- [ ] Step 6: Commit - `git add -A && git commit -m "molt cycle 1 brief 3: verify criteria, regenerate registry, close ledger"`

---

## Self-review (Step 5, run inline)

- **Brief coverage.** Every checkable criterion maps to a task's `[executed-check]`: skill count -> Task 14 (asserts 10, the accepted floor; <=8 resolved by Jeremy 2026-08-15, not softened by the driver); frontier-sandwich retired via install.sh -> Task 2 (+ rewritten retirement contract) with the repo-wide reference sweep at Task 14 (Rubix A1); loop-which retired via install.sh's retire list -> Task 5 (Rubix A2/B3); routing narrative greps to one file -> Task 14 (`grep -rl 'scoreboard posterior' | wc -l -eq 1`), converted in Tasks 3/6/10; ringer footguns single-home -> Task 6 removes them from loop-drive SKILL, kept only in `ringer-substrate.md`, verified by Task 14's `opencode` grep; brief-graduation single-home -> Task 4 moves the SHARED contract (graduate-parking invocation + bullet-shape rule, currently duplicated across brainstorm Step 8 and improve Step 6) into `brief-pipeline.md` and rewrites the stale "NOT here" disclaimers, Task 8 repoints improve and keeps its supersede-close improve-only, verified by Task 14's `truncates the title` uniqueness grep (Rubix B1, replacing the old presence-only sentinel); line count 40% -> Task 14 prose-only executed check (`<=1457` off the 2429 baseline via `-type f` so the benchmark symlink is not followed, Rubix B2); every deletion has a ledger line -> every task appends, Task 14 verifies; surviving blocks trace to policy -> the KEEP lists (incl. the three worktree hazards and the ringer-absent fallback kept as policy, Rubix A4/A6) + spot-check at Task 14; `tests/run.sh` + fresh registry + toy chain -> Task 14. No criterion is silently dropped.
- **Placeholder scan.** No TBD/TODO; every task names exact files, exact commands, exact grep targets. Line budgets are targets with a policy-preserving floor and an escape (human checkpoint) if subtraction would hit policy.
- **Type consistency.** Produced/consumed paths line up: benchmark leaf `skills/loop-drive/references/model-benchmarks.md` (Task 2 produces, Task 6 consumes); routing pointer sentence (Task 3 produces, Tasks 6/10 consume); `one-minute-test.md` rehome (Task 4 produces via git mv, Task 6 consumes - moved from Task 5 to close the dangling-reference window, Rubix B5); ledger entry shape (Task 1 produces, all consume).
- **Loop-drive contract check.** Every task: scope stated, acceptance `[executed-check]` (a command, not judgment - residual behavioral judgment routed to Task 14's checkpoint, with the deepest slims (Tasks 4/6/7) now recording an executable probe output per-commit so a regression localizes, Rubix B4), depends-on explicit and complete, readable in isolation. Exclusive ownership holds under the serial spine (no two tasks share a `SKILL.md`, the registry, or the ledger at once); the one deliberate sequential share is the `skills/loop-which/` dir - Task 4 git-moves `one-minute-test.md` out, Task 5 (which depends on Task 4) removes the remainder - never concurrent. The spine is serial by design (shared registry + ledger), documented so it is not "fixed" into a race.
- **Agnosticism scan.** The plan names files, greps, git, and bash; the only skill NAMES appearing are the artifacts being edited (unavoidable - they are the subject). No executor is assumed to have any skill installed; every check is a shell command against the repo.
- **Rubix incorporation (2026-08-15).** All 10 Rubix findings (A1-A6, B1-B6, A5 folded into A3) verified against disk and revised in: Task 2 gate scoped (A1), loop-which retire list (A2/B3), loop-drive frontmatter triggers (A3/A5), worktree hazards kept as policy (A4), ringer-absent fallback preserved (A6), graduation dedup sized to the shared contract (B1), Task 14 `-type f` (B2), executable recorded probes (B4), git-mv moved to Task 4 (B5), STOP/BATCH floor guards on Tasks 6-7 (B6). None declined.
