# B32 jrit-loop port - resume state (written 2026-09-14 at the wave-7/8 boundary)

## Where the run is

Waves 0-7 are DONE and merged; jroethel/jrit-loop is PUBLIC at 5e683c9 with a --strict-clean tree and run-all green.
All criteria banked with executed evidence except criterion 14 (C6) and the Mac's per-host criterion 12.
loop-stack-session tracker holds exactly #53, #54, #55 (board extraction, out of scope by design).
C1, C2, C8, C4, C3-on-WSL all fired and receipted; C5 never triggered (helper SLOC 196).

## Blocked on Jeremy, in order

1. C6 (criterion 14): one real loop from a marketplace install on the Windows 11 desktop app; he reports repo, unit, and receipt location.
2. After C6: the orchestrator records the criterion-14 line in docs/2026-09-13.proof-pass-receipts.md, then launches U15 (Task 15, plan lines 1168-1190: stage docs/community-submission.md; ringer glm-5.2 docs; check must assert the acceptance compound at line 1180 and the C6 line's presence; eval-report publish decision defaults to unpublished unless Jeremy says otherwise).
3. C7: hand Jeremy docs/community-submission.md and https://platform.claude.com/plugins/submit; he fires; then the advisory /loop-review b32-w2-base (B32_BASE = b811337) from main, non-blocking, findings recorded at the C7 handoff.
4. Independent: Mac (RIT-UADV2213) C3 - docs/decommission.md Section 2 there, sweep must include ~/create/ at depth reaching create/skills/rubix-review; its single-resolution line lands in the receipts doc Part 2.

## Mechanics a fresh session needs

- Wave materials pattern: manifests + orchestrator-owned checks live in loop-stack-session/docs/drive-logs/B32/manifests/; every check starts TASKDIR="${TASKDIR:-$PWD}" and gets a fail-first probe before gating a worker; patches export to drive-logs/B32/patches/ and merge with --exclude=NOTES.
- Ringer check ceiling is 60s hardcoded; long checks are harvested by running the check standalone with TASKDIR pointed at the surviving worktree.
- The harness memory watchdog kills background shells under pressure; long ringer runs go detached (setsid) with a featherweight pgrep watcher.
- Four check-bug classes hit this run (unset TASKDIR, porcelain without -uall, unanchored sed, prose-matching negative greps) - all fixed in the live check files; do not reintroduce.
- MODEL-NOTES receipts are owed per (model, task_type) per wave in ~/repos/ringer/docs/MODEL-NOTES.md, committed before advancing.

## The paste-ready resume prompt

Resume the B32 jrit-loop plugin port drive.
Read, in order: /home/jjrdar/repos/loop-stack-session/docs/plans/2026-09-13.B32.jrit-loop-plugin-port-plan_loop.md (orchestration plan), /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/whats_next.md (current state, supersedes the generic reconciliation for position), /home/jjrdar/repos/loop-stack-session/docs/reviews/2026-09-13.B32.jrit-loop-plugin-port-batch-review.md (journal), and the source plan beside the _loop.md.
Then run the _loop.md Section 6 reconciliation (git is truth; verify C4 via gh repo view, C3-WSL via ls $HOME/.claude/skills/loop-drive failing, tracker end state {53,54,55} open).
The run waits at C6; when Jeremy supplies the C6 result, proceed per the Blocked-on-Jeremy list above.
Autonomy: the knob was auto (session-only) and dies with the old session; ask Jeremy whether to re-set auto or run the tail human-gated (three steps remain, so pause costs little).
