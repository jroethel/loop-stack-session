# Wave 7 summary - B32 jrit-loop port

Date: 2026-09-13/14.
Unit: U14 (T14 proof pass part 2), glm-5.2, ringer, docs.

## Results

| Unit | Ringer | Validation | Final | Repairs |
| --- | --- | --- | --- | --- |
| U14 | fail x2 (one real scope violation attempt 1; one orchestrator check bug attempt 2) | corrected check green; orchestrator ran the full acceptance compound itself, exit 0 | merged 5e683c9 | 1 real |

## The wave's findings

- Attempt 1 fixed ci/clean-room-npx.sh out of scope; the custody check rejected it correctly; attempt 2 reverted, re-proved everything in scope, and demonstrated the underlying defect with a labeled probe: the skills install lacked -g, landing project-level instead of in the sandbox HOME.
- Orchestrator fixed the one flag at the gate (check-bug-class precedent), then ran run-all + clean-room + single-resolution itself: exit 0, criterion 3 proven (anonymous public fetch, eleven installs, all references resolve, receipt.sh survives the copy; skills package 1.5.26 pinned in README from captured output only).
- Check bug #4, same class as before: the Part-2 mutation grep matched the prose word "closed"; narrowed to the literal command forms.
- Step 9 closes fired by the orchestrator: #52 and #44 closed with verbatim comments; loop-stack-session open set is now exactly {53, 54, 55}.

## Criteria banked this wave

Criterion 3 (clean-room npx, orchestrator-executed green), criterion 12 on this host (single-resolution 11/11, recorded per-host; RIT-UADV2213 pending), criterion 9 strong-engine (gitleaks, banked at wave 6), criterion 11 (consumer sweep).
