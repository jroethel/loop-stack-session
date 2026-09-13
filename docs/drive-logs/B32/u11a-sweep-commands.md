# Task 11 tracker sweep: the C8 command packet

Staged 2026-09-13 by U11a from the live tracker; nothing below has been executed.
Every mutation in the command list waits on Jeremy's explicit go at human checkpoint C8.
Plan of record: docs/plans/2026-09-13.B32.jrit-loop-plugin-port-plan.md, Task 11 and Decision D12.

## Live snapshot: 24 open issues in jroethel/loop-stack-session

Fetched 2026-09-13 with Task 11 step 1's command.
The raw JSON sits beside this file as u11a-lss-open-before.json.

| #  | Title                                                                                                                                             | Labels |
| -- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| 3  | Quota-aware scheduling / unattended auto-resume (third parking)                                                                                   | idea   |
| 7  | Case for Matt's triage / tdd / prototype skills                                                                                                   | idea   |
| 15 | github-to-gitlab data migration                                                                                                                   | idea   |
| 18 | Reconcile the 'who routes, and on what basis' seam across loop-drive, ringer, and the model-intel reference                                       | idea   |
| 28 | A `/dev/tty`-hardened enforcement gate, if the cooperative-agent assumption ever breaks and an agent-proof import gate is actually wanted         | idea   |
| 32 | Public-phase genericization - license posture, stranger-first README onboarding, secrets documentation, template or release form                  | idea   |
| 33 | RIT-team turnkey phase with no OS assumption                                                                                                      | idea   |
| 36 | Decision E remainder: standing glossary (CONTEXT.md) + ADR side-effects from loop-brainstorm                                                      | idea   |
| 39 | context-map: LLM-friendly JSON form of the index section                                                                                          | idea   |
| 40 | Second amendment direction - human rejection of a bad PASS as a reclassify value, the mirror image barthballard named, schema-ready but unshipped | idea   |
| 44 | wayfinder: GitLab (and partly GitHub) child-issue support doesn't match SKILL.md's claim                                                          | bug    |
| 45 | Session coordination: check-before-modify + ownership handoff between concurrent sessions                                                         | idea   |
| 47 | tests/run.sh: transient single-suite failure observed post-install, unattributed                                                                  | (none) |
| 48 | loop-drive pre-run Rubix pass                                                                                                                     | idea   |
| 51 | Model routing: task_type has no definition, no per-shape model-fit signal, and Agent-tool transport never feeds the evidence loop                 | idea   |
| 52 | No reliable resume pointer: where work paused and what is truly next                                                                              | (none) |
| 53 | Cross-host aggregation of the board                                                                                                               | idea   |
| 54 | Interactive write-back board where moving a card writes to its owning source                                                                      | idea   |
| 55 | Evaluate an existing kanban app as a pure view layer over the recording convention                                                                | idea   |
| 56 | Where does architecture brainstorming/research fit in the loop-stack process?                                                                     | (none) |
| 61 | Fable retirement path - gate the claude-md managed block behind a host flag and split fable-guidelines into model-agnostic and Fable-era content  | idea   |
| 62 | Role-pin single home - consolidate the three resolves-to-Opus pin declarations into one routing home with pointers                                | idea   |
| 63 | Worked examples for the orchestrator pin trigger - add one positive and one rejected pin example under the routing chain's step 3                 | idea   |
| 64 | herdr plugin surface - a herdr plugin manifest pane hosting a drive panel or board view                                                           | idea   |

## D12 disposition table

Reproduced verbatim from the plan.

| Disposition                                  | Issues                                                                       |
| -------------------------------------------- | ---------------------------------------------------------------------------- |
| Migrate to jrit-loop's tracker               | #7, #15, #18, #28, #40, #48, #51, #56, #45, #33, #61, #62, #63, #64, #36, #3 |
| Close as obsoleted by the port               | #39, #47                                                                     |
| Close as superseded by the brief             | #32                                                                          |
| Closes only when the resume pointer lands    | #52                                                                          |
| Folds into the wayfinder port task           | #44                                                                          |
| Travels with board extraction, not this plan | #53, #54, #55                                                                |

## Agreement

The live snapshot and D12 agree exactly: 24 live issues against 24 dispositions, every open number appears in exactly one disposition, and no disposition names a number that is not open.
There is no remainder on either side.

## The command list, in execution order

Run verbatim from any directory, one fenced block at a time.
Every transfer carries -R jroethel/loop-stack-session, which is load-bearing: without it gh resolves the source repo from the working directory, and an unqualified transfer run from the wrong directory targets the wrong repo.
The three close commands and the #3 migration note are verbatim from the plan; the comments on the five issues that stay open are composed for this packet from the plan's stated intent.
The blocks are separate on purpose, so a whole-list paste cannot run past the dry-run verification gate: block (b) transfers only #7, and nothing below it fires until you have verified that landing.
There are exactly sixteen transfers across the list: #7 in the dry-run block, fourteen in the loop, and #3 on its own at the end.
Each transfer prints its new issue's URL on stdout, and every capture appends one old=#<n> new=<url> line to docs/drive-logs/B32/u11b-transfer-urls.txt beside this file, so the file ends with sixteen lines.
Those sixteen pairs fill the pending cells in jrit-loop's docs/issue-migration-map.md afterward, per Task 11 step 6.

### (a) Label provisioning, Task 11 step 4

```bash
# Step 4: seed the seven labels in the destination repo
gh label create idea -R jroethel/jrit-loop --description "Backlog lane" || true
gh label create agent:todo -R jroethel/jrit-loop || true
gh label create agent:working -R jroethel/jrit-loop || true
gh label create agent:needs-input -R jroethel/jrit-loop || true
gh label create agent:review -R jroethel/jrit-loop || true
gh label create agent:done -R jroethel/jrit-loop || true
gh label create wayfinder:map -R jroethel/jrit-loop || true
```

### (b) The #7 dry-run transfer plus its verification reads, Task 11 step 5

```bash
# Step 5: dry-run the transfer with one issue, then verify it landed with body and comments
url7=$(gh issue transfer 7 -R jroethel/loop-stack-session jroethel/jrit-loop)
echo "old=#7 new=$url7" >> /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/u11b-transfer-urls.txt
gh issue list -R jroethel/jrit-loop --state all
# confirm body and comments came with it: gh issue view "$url7" --comments
```

**STOP and verify before continuing: confirm #7 landed in jroethel/jrit-loop with its body, its comments, and its idea label intact (gh issue view "$url7" --comments), and only then run the blocks below.**

### (c) The fourteen-transfer loop, with #7 and #3 both out of it

```bash
# Step 5 continued: transfer the remaining fourteen; the -R qualifier is load-bearing on every transfer
for n in 15 18 28 40 48 51 56 45 33 61 62 63 64 36; do
  url=$(gh issue transfer $n -R jroethel/loop-stack-session jroethel/jrit-loop)
  echo "old=#$n new=$url" >> /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/u11b-transfer-urls.txt
done
```

### (d) The solo #3 transfer and its migration note, Task 11 step 6

#3 transfers on its own with its new-issue URL captured, and the note targets that URL directly, so it can never land on the wrong issue regardless of any list ordering.

```bash
# Step 6: transfer #3 on its own, then comment on the URL it printed, carrying its migration note verbatim
url3=$(gh issue transfer 3 -R jroethel/loop-stack-session jroethel/jrit-loop)
echo "old=#3 new=$url3" >> /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/u11b-transfer-urls.txt
gh issue comment "$url3" --body 'Re-read this against `/goal` and `/loop` before building anything. Verified 2026-09-13: both are user-invoked slash commands only and cannot be invoked programmatically from skill prose, so an unattended auto-resume cannot be built on them.'
```

### (e) The closes and the stay-open comments, Task 11 steps 7 through 11

```bash
# Step 7: close the two issues obsoleted by the port
gh issue close 39 -R jroethel/loop-stack-session --comment "Obsoleted by the jrit-loop plugin port: the context-map mechanism does not survive the port." --reason "not planned"
gh issue close 47 -R jroethel/loop-stack-session --comment "Obsoleted by the jrit-loop plugin port: tests/run.sh and its suites do not survive the port." --reason "not planned"

# Step 8: close #32 as superseded by the brief
gh issue close 32 -R jroethel/loop-stack-session --comment "Superseded by docs/briefs/2026-09-12.B32.jrit-loop-plugin-port-brief.md, which carries the public-distribution scope in full." --reason "not planned"

# Step 9: #52 stays open; comment linking the plan and naming its gate
gh issue comment 52 -R jroethel/loop-stack-session --body "Stays open by design: closes only when the resume-pointer deliverable lands, which is Task 9's prose proven by Task 10's resume-pointer-written case. Gate recorded in docs/plans/2026-09-13.B32.jrit-loop-plugin-port-plan.md, Task 11 step 9."

# Step 10: #44 stays open; comment naming Task 7 as its gate
gh issue comment 44 -R jroethel/loop-stack-session --body "Stays open by design: closes with Task 7's receipt, which corrects wayfinder's child-issue claims to what gh and glab actually support. Gate recorded in docs/plans/2026-09-13.B32.jrit-loop-plugin-port-plan.md, Task 11 step 10."

# Step 11: #53, #54, #55 stay open; one-line comment on each saying they travel with board extraction
gh issue comment 53 -R jroethel/loop-stack-session --body "Stays open by design: travels with board extraction, which is a different plan, not the B32 jrit-loop plugin port. Recorded so a later sweep does not re-dispose it (Task 11 step 11)."
gh issue comment 54 -R jroethel/loop-stack-session --body "Stays open by design: travels with board extraction, which is a different plan, not the B32 jrit-loop plugin port. Recorded so a later sweep does not re-dispose it (Task 11 step 11)."
gh issue comment 55 -R jroethel/loop-stack-session --body "Stays open by design: travels with board extraction, which is a different plan, not the B32 jrit-loop plugin port. Recorded so a later sweep does not re-dispose it (Task 11 step 11)."
```

### (f) The loop-stack-session mirror deletion, Task 11 step 12

```bash
# Step 12: delete the three generated mirror files in loop-stack-session
cd ~/repos/loop-stack-session && git rm --cached ISSUES.md BACKLOG.md WAYFINDER.md 2>/dev/null; rm -f ISSUES.md BACKLOG.md WAYFINDER.md
```

Expected end state: five issues open in loop-stack-session, sixteen in jrit-loop.
The URL file ends with sixteen old-to-new pairs, one per transfer.
