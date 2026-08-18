# Brief: Tracker as control plane (Open Engine adoption)

Source: pcs evaluation, `~/create/pcs/2026-08-15-consolidated-recommendations.md` Section 7; research base `~/create/pcs/research/nate-jones-open-engine-loop-graph-harness-context-analysis.md`.
Sequence: brief 4 of 4 in molt cycle 1; the deepest change, do last.

## Outcome

The stack's spine moves from "a session that must stay alive" to "a tracker that outlives sessions": work state lives on tracker tickets with statuses and receipts, any fresh session can claim and continue a dead session's pipeline, and no transition to Done is possible on a self-report.

## Tasks

1. **Status vocabulary as tracker labels**, through the existing `tracker.sh` seam so all three backends (github/gitlab/local) support it: `agent:todo`, `agent:working`, `agent:needs-input`, `agent:review`, `agent:done` (naming free to improve; semantics fixed).
2. **Claim lock convention**: claiming = move to working + `AGENT CLAIMED <session-id> <timestamp>` comment + re-read the issue to detect the race (Open Engine's own sequence).
3. **Queue-runner prompt** (a reference doc, pasteable into any session or scheduled): process AT MOST one eligible ticket per run; boundary-first (never publish, deploy, delete, email, or touch billing/credentials without issue-level approval); leave a receipt on every transition.
4. **Run-state onto tickets**: loop-drive's run-state artifact gains a ticket mirror (or moves entirely) so a killed session's wave state is claimable; reconciliation still trusts git over any state record (P11 unchanged).
5. **The P2 guard - the marriage that beats both parents**: `agent:done` requires a receipt containing executed-check evidence (command + exit status or artifact link); a bare "done" self-report cannot close a ticket.
   This is where loop-stack's checks fix Open Engine's known weakness (AGENT DONE is exactly the self-report P2 forbids).
6. Receipts align with the existing handoff skill format; gen-mirrors continues to reflect lanes.
7. **Lifecycle reconciliation lint** (repo-state.md's archive rules 1-3 exist but demonstrably decay - six completed plan-sets from 2026-08-04 onward sit unarchived while everything through 2026-08-02 was moved correctly): a deterministic script, run at the same moments mirrors regenerate (handoff time / on demand, no hooks, no daemons), flags (a) plans complete but not in `docs/archive/`, (b) briefs orphaned from archived plans, (c) completed work whose linked issue is still open, (d) closed issues referenced by live plans.
   Detection is script; the archive/close ACTION is a BATCH-class gate (auto-take + journal under `auto`, offered under `pause`); issue closure requires a receipt per task 5's guard.

## Additional checkable criterion

- Lint's first live run catches the existing backlog: the six unarchived post-Aug-4 plan-sets are flagged, and archiving them via the gate is the acceptance demo (rules 1-2 applied, briefs travel with plans, each move announced per rule 5).

## Checkable success criteria

- `tracker.sh` label operations pass in all three backend test suites (`tests/repo-state/`).
- Queue-runner test: given three eligible tickets, one run touches exactly one and stops with its reason recorded.
- Kill test: start a toy drive, kill the session mid-wave, open a fresh session with only the queue-runner prompt; it claims the ticket and relaunches (not resumes) the half-done unit from tracker + git alone.
- Close guard test: an `agent:done` transition without executed-check evidence in the receipt is rejected (script-enforced in tracker.sh, not prose).
- `tests/run.sh` passes clean.

## Constraint register

Same as brief 1; additionally: the control plane must work on the `local` tracker backend too (no hard remote dependency - unlike wayfinder's remote-only stance, the control plane is the spine and must run anywhere); ticket records stay portable prose (no Claude-Code-specific fields).

## Parking lot

- Scheduled/triggered queue-runner execution (cron, Claude scheduled tasks) - after the manual prompt proves out.
- Retiring `docs/chain-state.md` runtime knob in favor of ticket state - evaluate after this lands, not during.
- Wayfinder convergence with the new statuses (it has its own label family) - own brief later.
