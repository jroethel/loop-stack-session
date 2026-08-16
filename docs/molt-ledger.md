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

## 2026-08-15 - skills/loop-plan/SKILL.md
- Harness snapshot: v2.1.204; /workflows off.
- Deleted: CHOREOGRAPHY - the AskUserQuestion tool mechanics and Other-response handling compressed to the frontier-rounds decision content; the Rubix flavor line + verbose two-paragraph lens A/B descriptions compressed to one line each; Step 7 review-gate narration tightened; the retired-skill routing narration in the pipeline diagram collapsed.
- Bare-reference cleanup (owned-file, in scope): the three stale `/loop-which` skill references (frontmatter consumer list, pipeline diagram, Step 8 handoff) converted - the run-shape verdict now routes to /loop-drive's front-door triage ("is this worth automating / how should I run this plan", the One-Minute Test for a plan in hand).
- Kept as policy: HARD-GATE; the header + task templates verbatim (the downstream loop-drive contract's teeth); the loop-drive contract (depends-on / exclusive ownership / executed-check loop-aware bullets); the no-placeholder list; the code policy; the self-review checklist; the plan-draft dispatch + dependency-graph review + Opus pin (single home); the prefactor + expand-contract rule; the Rubix role pins (single home); every gate tag verbatim incl. the `[gate:BATCH]` at the tags.sh floor.
- Budget note (policy-preserving near-miss): plan target was 222 -> ~150; landed 223 -> 198. The remaining bulk is the ~70-line verbatim header/task template block (explicit KEEP - the teeth) plus KEEP decision content (frontier-rounds, decomposition judgment, self-review). Reaching ~150 would require cutting the template or the loop-drive contract, both POLICY-keep; per the plan's Human-checkpoint, policy is kept and the shortfall recorded here rather than cutting to a number.
- Premises: none expired.
- Constraints re-confirmed: single-home-plus-pointers (routing narrative absent - `scoreboard posterior` = 0; role pins single-homed here), /workflows off, executor-agnostic (no skill invocation the executor must have installed).

## 2026-08-15 - skills/loop-improve/ (SKILL + audit-playbook slim)
- Harness snapshot: v2.1.204; /workflows off.
- Deleted: CHOREOGRAPHY - audit-playbook verbose prose (Security handling/by-design paragraphs, Direction narration) compressed to their checkable core; dedup - the shared graduation restatement in SKILL Step 6 (graduate-parking invocation contract + the parking-lot bullet-shape/"truncates the title"/"period-free" rule) reduced to a pointer at `brief-pipeline.md` (its single home from Task 4), removing the last duplicate so the shared narration greps to exactly one home.
- Bare-reference cleanup (owned-file, in scope): the stale `/loop-which` ref in the terminal step dropped - it named a route loop-improve explicitly does NOT take ("never invokes /loop-which or /loop-drive"), so a substitution would be nonsensical; rewritten to "terminal is /loop-plan only; never invokes /loop-drive or an implementation skill."
- Kept as policy: the read-only HARD-GATE; the eight-column findings-table contract (covered/related renders + same-work/different-ask defs); the `scripts/tracker.sh list` scan; ASK/DEFAULT gates; the `--focus harness-drift` one-line delegation to /loop-molt (no audit method duplicated, `molt.sh` asserts); the FULL audit capability - every category's checkable file:line-evidence criteria KEPT verbatim-in-spirit per the constraint register ("improve keeps full shaping capability"); the improve-ONLY supersede-close KEPT verbatim (the `Supersedes: #N` recording and `scripts/tracker.sh close` close-covered-issues-at-brief-time policy) - NOT moved to the shared home; the MIT + vendored-2026-08-08 attribution and license block verbatim.
- Rewrote the stale `loop-improve/SKILL.md` "shared reference contains NO graduation" sentence to point at the shared graduation contract while noting the supersede-close stays improve's own.
- Probe: the findings-table contract (eight columns + covered/related + tracker scan) is gate-verified by `tests/gates/loop-improve.sh` (passes); a full quick-audit run was not spent since the gate asserts exactly what the probe would check.
- Budget note (policy-preserving near-miss): audit-playbook target 188 -> ~120; landed 188 -> 178; SKILL slimmed 99 -> 95. The category criteria are improve's audit capability (constraint-register-protected: "improve keeps full shaping capability"); reaching ~120 would require dropping checkable audit criteria, so per the plan's Human-checkpoint they are kept and the shortfall recorded.
- Premises: none expired (the "graduation is per-skill" premise was already re-evaluated in Task 4; this task completes the improve side of that single-home move).
- Constraints re-confirmed: single-home-plus-pointers (graduation narration now single-homed), improve keeps FULL audit capability, /workflows off.

## 2026-08-15 - skills/loop-molt/ (SKILL + protocol slim)
- Harness snapshot: v2.1.204; /workflows off.
- Deleted: CHOREOGRAPHY - the SKILL's Step 0-5 per-step narration (which restated the protocol's running order) collapsed to a thin numbered pointer list; the protocol's Step-0 refresh verbosity, the "Where molt sits" workflow paragraph, and the "Wiring it into the stack" entry-point narration compressed to their decision content.
- Bare-reference cleanup (owned-file, in scope): the stale `/loop-which` node dropped from the downstream chain arrow in both SKILL.md and protocol.md (`/loop-plan -> /loop-which -> /loop-drive -> /loop-review` -> `/loop-plan -> /loop-drive -> /loop-review`); loop-which's run-shape triage is now loop-drive's front door, so the node is redundant rather than substitutable inside an arrow sequence.
- Kept as policy: the one-line test; the ASK constraint-register-FIRST gate (`[gate:ASK]`, names "constraint register"); the single-home four-bin invariant (bins DEFINED only in `protocol.md` - no UPPERCASE bin token leaks into SKILL.md, `molt.sh` enforces, verified clean); the policy-membership test; the test-by-subtraction rule; the expected-steady-state / "done molting" definition; the `brief-pipeline.md` routing for structural findings; the `docs/molt-ledger.md` ledger-home name; the `--focus harness-drift` delegation; the MIT/vendored-2026-08-15 attribution.
- Budget note (policy-preserving near-miss): protocol target 98 -> ~78; landed 98 -> 90 (SKILL 91 -> 56, well under). The four-bin table, membership test, subtraction test, constraint-register rule and steady-state definition are the method's single home (POLICY); reaching ~78 would cut method content, so per the plan's Human-checkpoint they are kept and the shortfall recorded.
- Premises: none expired.
- Constraints re-confirmed: single-home-plus-pointers (bins single-homed in protocol.md, method single-homed there), portability/harness-agnostic (SKILL is the only Claude-Code wrapper), /workflows off.

## 2026-08-15 - skills/wayfinder/SKILL.md
- Harness snapshot: v2.1.204; /workflows off.
- Deleted: CHOREOGRAPHY - the multi-sentence procedural narration across the intro, Plan-don't-do, Refer-by-name, Tickets, Ticket Types, Fog of war, Out of scope, and both Invocation mode step-lists compressed to their decision content (each rule kept, the surrounding explanatory prose tightened); dedup - the routing narrative converted to the Task 3 pointer.
- Routing single-homed: the per-ticket routing line "follows the loop-drive evidence chain: scoreboard posterior, else benchmark prior, else orchestrator pin" -> "follows the routing chain (`config/routing/model-benchmarks.md`)" (`scoreboard posterior` now 0 in this file).
- Kept as policy: the plan-don't-do rule (produce decisions, not deliverables; hand to /loop-plan when the way is clear); the map/ticket schema code blocks verbatim; the `wayfinder:map` + ticket-type labels; the four ticket types (HITL/AFK); fog-vs-ticket and out-of-scope discipline; one-ticket-per-session (research excepted); the /loop-plan hand-off and /loop-brainstorm grilling remap; mirror-exclusion behavior (`wayfinder.sh` asserts the schema, labels, hand-offs, and mirror exclusion).
- Budget note (policy-preserving near-miss, small): target 183 -> ~125; landed 183 -> 142. The map/ticket schema code blocks and the full rule set are POLICY; the residual gap is schema + decision content, not cuttable narration, so kept per the plan's Human-checkpoint.
- Premises: none expired.
- Constraints re-confirmed: single-home-plus-pointers (routing now a pointer), remote-tracker requirement, /workflows off.

## 2026-08-15 - skills/loop-setup/ (SKILL + import-triage slim)
- Harness snapshot: v2.1.204; /workflows off.
- Deleted: CHOREOGRAPHY - the per-mode "What it does" step-by-step narration of setup.sh (github/gitlab/local sub-bullets) folded to one tighter per-mode block; the import-sweep numbered walkthrough compressed to prose; the import-triage default-workflow framing and on-approval prose tightened; the redundant second example table in the D1 record-doc section dropped (the batch-disclosure example already shows the shape).
- Kept as policy: the no-`none`-mode decision (local supersedes none); the three-mode presentation rule (all three verbatim with viability caveats); `tracker-remote-ack` (the deliberate mode-vs-remote split); the import-sweep triage judgment (split/merge/leave/titling/labelling/disclosure - loop-setup's shaping capability, constraint-register-protected); attended-only (ignores the loop-auto knob); the four remote-report strings verbatim (tests assert they match setup.sh); the non-interactive hooks (`LOOP_TRACKER_ANSWER`, `LOOP_IMPORT_REMOTE`, `--dry-run-remote`, `--list-candidates`); `migrate-tracker.sh --to` suggestion; the `references/import-triage.md` pointer. `setup.sh` (492 lines of code) untouched.
- Budget note (policy-preserving near-miss): import-triage target 130 -> ~95; landed 130 -> 114 (SKILL 100 -> 87, target met). The judgment rules, batch-disclosure contract, issue-body footer template, and D1 record-doc contract are triage POLICY; reaching ~95 would cut triage judgment, so kept per the plan's Human-checkpoint.
- Premises: none expired.
- Constraints re-confirmed: attended-only (loop-auto knob ignored), no-`none`-mode, single-home (import-triage is the triage workflow's single home), /workflows off; house style (no em dash) verified clean.

## 2026-08-15 - skills/loop-review/SKILL.md
- Harness snapshot: v2.1.204; /workflows off.
- Deleted: CHOREOGRAPHY - the process narration across Pin-the-fixed-point, spec-discovery tail, disclosure, spawn-subagents framing, and aggregate compressed to decision content; dedup - the illustrative second `Mysterious Name` occurrence inside the Standards subagent prompt removed (the smell is named "with its exact baseline label" instead), so the baseline token now appears exactly once (`grep -c 'Mysterious Name'` = 1, the plan's Task 12 acceptance).
- Kept as policy: the two-axis Spec/Standards separation and the _Why two axes_ rationale; the disclosure-before-findings ("basis-before-findings") contract with the exact "matched by branch name" / "no spec available" phrases; the 5-rung spec-source discovery ladder verbatim; the empty-diff flagship-command trap message verbatim; the two subagent prompts; and the **Fowler 12-smell baseline VERBATIM** (all 12 smells untouched - deleting it would break the Standards axis, which has no other access to it).
- Budget note (policy-preserving near-miss): target 128 -> ~105; landed 128 -> 112. The 12-smell baseline (12 lines), the two verbatim subagent prompts, the discovery ladder and the disclosure contract are POLICY; reaching ~105 would compress the smell list or a prompt, both KEEP, so kept per the plan's Human-checkpoint.
- Premises: none expired.
- Constraints re-confirmed: zero-setup portability (runs in any repo), single-home (smell baseline lives only here), /workflows off.

## 2026-08-15 - skills/loop-auto/ + skills/handoff/ (SKILL slim)
- Harness snapshot: v2.1.204; /workflows off.
- Deleted (loop-auto): CHOREOGRAPHY - the "What it does" invoke-narration, the knob-off / when-autonomy-takes-effect prose, and the reversal-by-gate-type prose compressed to decision content; one duplicated source-of-truth sentence dropped (the "Where it lives" section is its canonical home).
- Deleted (handoff): CHOREOGRAPHY x2 - the two candidates the handoff ledger entry flagged for a real pass: the "don't duplicate other artifacts, reference by path/URL" line and the "if the user passed arguments, treat as focus" line (the latter redundant with the frontmatter `argument-hint`). Both are judgment a current frontier model applies to a handoff unprompted; subtraction test = `tests/run.sh` green (handoff/location.sh asserts none of the required strings were in those lines). FLAG FOR OWNER (per the ledger entry's "needs owner review before removal"): both removals are reversible via `git revert`; if the owner wants the reference-by-path discipline explicit, restore that one line.
- Kept as policy (loop-auto): the four gate-class definitions (single home; `knob-consumption.sh` + `loop-auto.sh` assert); the VERBATIM live-consumption sentence `Consumption is live: the knob now governs gate behavior per the four gate classes below.`; the batch-review journal format (created when autonomy takes effect, appended at every gate, three fields incl. the reversal path); the scope-narrowing-is-ASK rule; the never-spawn-Fable continuation; the per-repo-default ask + `autonomy-default:` key; the recognized-phrases list; `docs/chain-state.md` as runtime source of truth; the `/loop-auto` subcommand reference.
- Kept as policy (handoff): the four policy blocks - purpose/outcome contract; repo-placement convention (conforming vs non-conforming, in-project only, mirror refresh); required suggested-skills section; redaction/safety invariant.
- Budget note: loop-auto target 106 -> ~92; landed 106 -> 98 (policy-preserving near-miss - gate-class defs + journal format + command reference are POLICY). handoff 22 -> 16.
- Verdict: handoff is now "done molting" - the two flagged choreography candidates removed, only its four policy blocks remain.
- Premises: none expired.
- Constraints re-confirmed: never-spawn-Fable (continuation never delegates to Fable), single-home (autonomy protocol homed in loop-auto; gate classes defined only here), /workflows off.


## 2026-08-15 - cycle 1 brief 3 closing summary

Harness snapshot: v2.1.204. Skills: 12 -> 10 (retired frontier-sandwich -> loop-drive human-paced mode; loop-which -> loop-brainstorm One-Minute Test front door). Both retirements relocate policy, none deleted.

Prose reduction (skills/ .md, fixed shell scripts excluded per the resolved criterion): 2429 (v1-pre-molt) -> 1833 = 24% cut. The resolved target was prose-only 40%+ (<=1457); the achieved policy-preserving floor is 24%. OWNER-ACCEPTED as the honest floor (Jeremy, 2026-08-15): the 40% target was set on an optimistic ~1500 projection, and closing the 376-line gap would cut policy the constraint register protects. Cause: every surviving prose file bottomed out on KEEP-listed policy (loop-plan verbatim templates, audit-playbook per-category criteria, loop-molt four-bin table, loop-review Fowler baseline, loop-auto gate-class defs, wayfinder schema blocks). No policy was cut to chase the number; each per-file near-miss is recorded in its artifact entry above and the drive batch journal.

Single-home verified (each greps to exactly one file): routing-chain narrative -> config/routing/model-benchmarks.md; ringer footguns -> ringer-substrate.md; shared brief-graduation contract -> brief-pipeline.md (improve-only supersede-close kept divergent).

Constraints re-confirmed: /workflows off; portability standing (ringer spine, ringer-absent degraded-routing fallback preserved); Fable never a worker; single-home-plus-pointers; the three Agent-tool worktree hazards kept as policy.

Done-molting verdicts: handoff is done molting (down to its four policy blocks). frontier-sandwich, loop-which retired. All other skills slimmed this cycle to policy sheets; a next cycle diffing this ledger confirms convergence (an artifact deleting nothing two cycles running is done).

Gate state: tests/run.sh 37/37; gate registry fresh. Behavioral judgment-equivalence of the toy happy-path chain is the human checkpoint (merge gate).

## 2026-08-16 - skills/loop-drive/SKILL.md (shakedown, first standalone /loop-molt run)
- Harness snapshot: v2.1.204 probed 2026-08-16 - unchanged since the 2026-08-15 cycle-1 snapshot; live probes via current-session tool schemas: background-by-default subagents with completion notifications, SendMessage continuation, `isolation: worktree` as opt-in parameter, Agent-tool roster enum (sonnet/opus/haiku present, fable excluded by constraint); ringer present (4 engines), `~/repos/ringer` and `~/.ringer/runs/` resolve.
- Scope: the never-molted brief-4 additions (run-state-onto-tickets block, watch-points line, P11 cite) plus re-confirmation of the brief-3 verdicts against the unchanged harness. `references/queue-runner.md` (94 lines, brief-4, never molted) is the next audit surface, deferred to its own pass.
- Deleted: dedup 1 (N-1) - the AGENT STATUS narrative (receipt command string, claim/gate cadence, git-over-receipt relaunch, next-eligible/--reclaim path) was stated in both SKILL Step 5 and `native-orchestration.md`, violating that reference's own "adds only what the SKILL does not state" charter; single-homed to the SKILL. native-orchestration.md keeps only its native-only delta (implementer agent id stays session-local - a fresh session cannot SendMessage a dead subagent) plus a pointer; the SKILL's stale "same fields ... lists" acknowledgment clause dropped.
- Kept as policy: the run-state-onto-tickets block (P11 - the harness will never write tracker receipts unprompted; consolidated-recommendations Section 7 mandates exactly this shape); the watch-points receipts line.
- Subtraction test: tests/run.sh 43/43 post-deletion; one real task - a two-unit toy plan compiled through Steps 0-5 by a fresh-context Opus dispatch at the drive-compile pin against the post-deletion files: receipt policy, relaunch-never-resume, reclaim path, degraded-mode routing, check custody, and the session-local agent-id rationale all present; no degradation.
- Premises: verified - P11 defined (principles.md:99); every pointer target exists (config/routing/model-benchmarks.md, one-minute-test.md, fable-guidelines.md, scripts/tracker.sh, ringer-repo MODEL-NOTES.md).
- Constraint register: owner ruling 2026-08-16 - ALL register items are re-derivable WITH APPROVAL, measured against two axes: current implementation and the consolidated recommendations, now memo-ized at docs/memos/2026-08-15-pcs-consolidated-recommendations.md (superseding cycle-1's fixed list; the next audit inherits this ruling). Re-derived this pass, no change proposed on either axis: Opus role-pin resolutions (a repin needs scoreboard evidence), 15-line BATCH threshold (implements the blast-radius policy, no counter-evidence), claude-zai tie-break (durable while the quota constraint is real - recommendations Section 2), MODEL-NOTES dual-repo receipts (portable learning stays in files - Section 3). Cycle-1 register re-confirmed: /workflows off, portability/ringer-spine, do-not-worsen list, single-home-plus-pointers (enforced by this pass's one deletion), Fable-never-a-worker + effort cap high.
- Verdict: SKILL.md is near done molting - one dedup deletion, zero plumbing or choreography found; if the next cycle deletes nothing it is done.
