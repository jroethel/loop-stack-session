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

## 2026-08-15 - skills/handoff/SKILL.md
- Harness snapshot: 2026-08-15, thin refresh (Claude Code current, Opus 4.8); no live probe - smoke run validating /loop-molt on a lean 21-line artifact.
- Deleted: none this pass (subtraction test not run; a smoke run does not edit a shared artifact).
- Candidates flagged for a real audit: choreography x2 - the "reference by path, don't duplicate" line and the "if the user passed arguments, treat as focus" line (both are judgment a frontier model applies unprompted); each needs the subtraction test + owner review before removal.
- Kept as policy: 4 - purpose/outcome contract; repo-placement convention (harness does not know config/repo-state.md unprompted); required suggested-skills section; redaction/safety invariant.
- Premises: none classified expired, so the constraint-register ASK gate had nothing to confirm this pass.
- Constraints re-confirmed: none contested (smoke run).
- Verdict: handoff is near "done molting" - lean, mostly policy; two cheap choreography candidates remain for the next real pass.

