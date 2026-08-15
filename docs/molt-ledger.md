# Molt drift ledger

The repo's harness-drift ledger, written by /loop-molt (see `skills/loop-molt/`).
One entry per audited artifact per audit, appended - never rewritten.
Each entry records the harness snapshot the audit was run against, so the next audit diffs from a known point instead of re-researching from zero.

Per-entry shape:

```
## YYYY-MM-DD - <artifact path>
- Harness snapshot: <date + what was probed/scanned>
- Deleted: <bin> N (...), <bin> N (...)
- Kept as policy: N (invariant each protects)
- Premises: <verified / rewritten in place / re-confirmed as constraint>
- Constraints re-confirmed: <list>
```

<!-- entries below, newest last -->

## 2026-08-15 - molt cycle 1 brief 3 (slim/fold/dedup)
- Harness snapshot: v2.1.204 (native parallel background fan-out with notifications verified unprompted 2026-08-15; /workflows off)
- Scope: retire frontier-sandwich + loop-which (fold, not cut); single-home the routing-chain narrative, ringer footguns, and brief-graduation; slim every SKILL.md by test-by-subtraction to a policy sheet.
- Per-artifact deletion sub-blocks follow this opening block, newest last, one per slimmed or retired artifact.
- Constraints re-confirmed: portability / ringer-spine (native lane optional, ringer-lane policy never cut); Fable is never a worker (effort capped at high); single-home-plus-pointers mandatory in everything touched; /workflows stays off.

## 2026-08-15 - skills/frontier-sandwich/ (retired -> loop-drive)
- Harness snapshot: v2.1.204 (native parallel background fan-out with notifications; /workflows off)
- Deleted: CHOREOGRAPHY (interview cadence, phase-by-phase narration a frontier model runs unprompted; save-the-plan file layout); duplication (fan-out loop-readiness now single-homed in loop-drive Step 3).
- Kept as policy (relocated to loop-drive): tier vocabulary (Frontier/Strong/Fast) + task routing map, the effort dial defaults, the sandwich invariant (frontier judgment before/after cheap execution), and the prompt pitfalls (never ask for hidden reasoning) - moved to `skills/loop-drive/references/fable-guidelines.md`; loop-drive absorbs the human-paced mode in Task 6.
- Retirement plumbing: `frontier-sandwich` added to install.sh's retire list; benchmark-prior leaf moved to `skills/loop-drive/references/model-benchmarks.md` (install-generated symlink, gitignored, uncommitted); gate rewritten as `frontier-sandwich-retired.sh`.
- Premises: none expired (retirement relocates policy, it does not cut it).
- Constraints re-confirmed: single-home-plus-pointers (benchmark leaf single-homed to loop-drive), portability/ringer-spine.

## 2026-08-15 - config/routing/model-benchmarks.md (routing-chain canonical home)
- Harness snapshot: v2.1.204; /workflows off.
- Deleted (dedup): routing-chain narrative restated in 5 sites -> 1 home + pointers (loop-drive, wayfinder, ringer-substrate, loop-which[retired], frontier-sandwich[retired]). Sites convert to the pointer in Tasks 5/6/10.
- Kept as policy: the narrative content is P7 (route by evidence) and is KEPT - consolidated, not cut; the ringer-absent degraded-routing fallback is preserved verbatim as operative portability policy in this single home.
- Premises: none expired.
- Constraints re-confirmed: single-home-plus-pointers, portability/ringer-spine (ringer-absent fallback survives the dedup).

## 2026-08-15 - skills/loop-brainstorm/ (One-Minute Test front door + choreography slim)
- Harness snapshot: v2.1.204; /workflows off.
- Deleted: CHOREOGRAPHY - the "run these in this order" scope-probe/domain-modeling cadence prose compressed to decision content (probe names + what each catches kept); dedup - the shared brief-graduation narration (graduate-parking invocation contract + parking-lot bullet-shape/title-truncation rule), previously duplicated across brainstorm Step 8 and improve Step 6, single-homed to `references/brief-pipeline.md`.
- Added (POLICY relocation): Step 0 One-Minute Test front-door triage (P6/C6 checkability-as-routing-gate; exits CHAT/DON'T BOTHER before shaping spend), `[gate:DEFAULT]`; `one-minute-test.md` git-moved from loop-which and slimmed to the four routes, seven questions, worked examples, verdict->artifact.
- Kept as policy: HARD-GATE, the frontier-rounds clarifying-question machinery, all shaping structure, and the Jeremy-maintained "Reading the user" block (untouched).
- Premises: PREMISE re-evaluated - the on-disk "graduation is per-skill" comment predated and contradicted the brief's single-home mandate; shared contract single-homed here, improve's `Supersedes: #N` supersede-close kept divergent (improve-only). This also required inverting the now-stale assertion in `tests/gates/loop-improve.sh` line 70 (see batch journal - plan-defect resolution, the plan mandated the move but did not list the guarding test).
- Retired-skill handoff repointed: brainstorm Step 9 terminal state now routes `frontier-sandwich` -> **/loop-drive** (human-paced output mode); pipeline diagram and the stale `/loop-which` reference in brief-pipeline.md converted to the front-door framing.
- Constraints re-confirmed: brainstorm keeps FULL shaping capability (question generation, checkable criteria, seams, parking lot); single-home-plus-pointers; /workflows off.

## 2026-08-15 - skills/loop-which/ (retired -> brainstorm front door)
- Harness snapshot: v2.1.204; /workflows off.
- Deleted: CHOREOGRAPHY (the step-by-step scoring narration wrapping the One-Minute Test); the SKILL body is gone. No policy deleted - the One-Minute Test policy relocated to the brainstorm Step 0 front door and loop-drive Step 0 (Task 4/6), its reference git-moved to `skills/loop-brainstorm/references/one-minute-test.md` in Task 4.
- Retirement plumbing: `loop-which` added to install.sh's retire list (a dangling-symlink bug depends on it); dropped from `tests/gates/tags.sh` SKILLS list (per-type floors unchanged - post-retire counts ASK 4 / STOP 6 / BATCH 4 / DEFAULT 11 all at/above 3/6/4/8); gate rewritten as `loop-which-retired.sh`.
- DECISION recorded (Rubix A5, so a future cycle sees a decision not drift): the standalone "is this worth automating / DON'T BOTHER" invocation trigger is retired; its routing question is now caught at the brainstorm front door and, for a plan in hand, by loop-drive's extended frontmatter (Task 6).
- Stale-reference note (not converted here - files owned by later tasks): bare-word `loop-which` skill-invocation refs remain in loop-drive Step 0 (Task 6 converts), loop-plan (Task 7), loop-improve (Task 8), loop-molt + protocol (Task 9), README (Task 14); descriptive attributions remain in config/routing/model-benchmarks.md and a comment in scripts/gen-gate-registry.sh (not skill-invocations, not in this task's ownership).
- Premises: none expired.
- Constraints re-confirmed: single-home-plus-pointers, portability/ringer-spine.

## 2026-08-15 - skills/loop-drive/ (compile+drive policy sheet)
- Harness snapshot: v2.1.204 (native parallel background fan-out with completion notifications and per-subagent worktrees verified unprompted); /workflows off.
- Deleted: PLUMBING - generic single-repo worktree creation ("parallel agents cannot share one checkout, each works in its own git worktree..."), parallel-background-Agent-launch narration, completion-notification narration (harness does these unprompted); CHOREOGRAPHY - wave-derivation mechanics ("a wave = all currently unblocked units"); dedup - routing-chain narrative -> Task 3 pointer, ringer footguns -> single-homed in ringer-substrate.md pointer; references - `example-output-plan.md` deleted wholesale (SKILL Step 6 emit-spec is self-sufficient), `native-orchestration.md` slimmed 36 -> ~14 lines to the two native-lane policies the SKILL does not state (repair-pass bookkeeping, live-session/headless constraint), `ringer-substrate.md` routing line -> pointer + promotion-ladder duplicate dropped (now in config home).
- Kept as POLICY: checks-or-stall (P6); the three validation layers + `{verdict: pass|fail|spec-problem}` contract; the per-unit routing TABLE (all columns) + task_type vocabulary + effort caps + transport-derivation + roster; gate-class pointer to loop-auto; run-state/resume format; check custody (both-transports invariant, stays in SKILL); AND the three Agent-tool worktree HAZARDS the harness does NOT handle - nested-repo wrong-snapshot (`git -C <inner-repo> worktree add`), per-worktree venv install, shared-append -> one-file-per-unit (Rubix A4, test-by-subtraction can't catch their loss). Every `[gate:STOP]` (6) and `[gate:BATCH]` (3) preserved verbatim (Rubix B6).
- Added (fold): human-paced output mode (absorbs frontier-sandwich) - the sandwich invariant, tier/effort by pointer to `references/fable-guidelines.md`, one-file-vs-numbered-files output shape; frontmatter description extended to fire on project kickoff / break-into-prompts / model-routing / human-paced run-book / "is this worth automating" (Rubix A3/A5).
- Ringer-absent degraded-routing fallback preserved (Rubix A6): operative in the SKILL Step 2 and in the Task 3 canonical home. Step 0 loop-which pointer repointed to the One-Minute Test reference; benchmark leaf now loop-drive's own.
- Probe (Rubix B4): compiled a two-unit toy plan through Steps 0-2, recorded in `docs/reviews/2026-08-15-slim-fold-dedup-probes.md` - emits routing table, validator contract, check custody, ringer-absent fallback, Step 0 verdict + next command; no degradation.
- Premises: none expired.
- Constraints re-confirmed: portability/ringer-spine (ringer-lane footguns + check custody never cut; native lane optional), single-home-plus-pointers, Fable-never-a-worker, /workflows off.

## 2026-08-15 - skills/handoff/SKILL.md
- Harness snapshot: 2026-08-15, thin refresh (Claude Code current, Opus 4.8); no live probe - smoke run validating /loop-molt on a lean 21-line artifact.
- Deleted: none this pass (subtraction test not run; a smoke run does not edit a shared artifact).
- Candidates flagged for a real audit: choreography x2 - the "reference by path, don't duplicate" line and the "if the user passed arguments, treat as focus" line (both are judgment a frontier model applies unprompted); each needs the subtraction test + owner review before removal.
- Kept as policy: 4 - purpose/outcome contract; repo-placement convention (harness does not know config/repo-state.md unprompted); required suggested-skills section; redaction/safety invariant.
- Premises: none classified expired, so the constraint-register ASK gate had nothing to confirm this pass.
- Constraints re-confirmed: none contested (smoke run).
- Verdict: handoff is near "done molting" - lean, mostly policy; two cheap choreography candidates remain for the next real pass.

