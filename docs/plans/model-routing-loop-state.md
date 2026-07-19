# Run state: model-routing-unification loop

Updated: 2026-07-19, RUN COMPLETE; merged to main at 6f3cc82 (fast-forward), integration branch deleted.
Result: 6/6 units passed on first attempt, zero retries, all on glm-5.2 (claude-zai).

| Unit | Status | Committed | Gate |
|------|--------|-----------|------|
| T1 skill rewrite   | pass, first try | 6f0d155 | HC1 approved by Jeremy |
| T3 benchmark file  | pass, first try | 4d3d285 | done |
| T6 PR framing      | pass, first try | ringer repo acbbc1a (surgical add, confirmed) | done |
| T2 references      | pass, first try | dabb530 | done |
| T5 touch-ups       | pass, first try | 9b7a691 | done |
| T4 install doctor  | pass, first try | 6f3cc82 | HC3 approved; LIVE install.sh exit 0, all doctor lines verified, symlink resolves |

## Waiting on Jeremy

- HC2 (final brief criterion, [judgment]): in a FRESH session, compile any sample plan with the rewritten loop-drive skill and confirm the routing table applies the chain (posterior/prior/pin tags, transport column) without asking which substrate to use.
  Suggested trigger: open a new session and run /loop-drive on any small PRD.
- Optional: `git push` (4+ commits ahead of origin/main).
- Open secret-free dirt in ~/repos/ringer left untouched by design: modified ringer SKILL.md and docs/MODEL-NOTES.md (now also carrying this run's appended receipt, uncommitted to avoid commingling the work-PC sync), untracked AMENDMENT-ROWS.md / AMENDMENTS-PENDING.md.

## Distill log

- Wave 1 pre-launch: `$RINGER_EXPORT_DIR` is a phantom variable (absent from ringer.py), inherited from the old example plan; fixed in the source plan (79f7552) and purged from the example by T2.
- Doctor live finding: opencode binary missing while `[engines.opencode]` is wired; install or remove the block when convenient.
- MODEL-NOTES receipt appended for glm-5.2 (6/6 first-try; adds a clean code-fix row against the amendment-depressed posterior).
