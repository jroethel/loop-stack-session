# The Agent-tool transport

The harness runs a wave's implementers as parallel background subagents, notifies you on each completion, and gives each its own `git worktree`; the orchestrator steers a running subagent with SendMessage.
The SKILL's Steps 3-5 carry the policy (check custody, the three worktree hazards, the repair-pass-then-stop gate); this file adds only what the SKILL does not state.

## Bookkeeping for the repair pass

Track, per unit, the implementer's agent id (needed to SendMessage the one repair pass), its branch and worktree path (needed to merge at the gate), the validator verdict, and the repair count - on the claimed ticket, so a fresh session can reconcile.
The durable form is an `AGENT STATUS` receipt written by the orchestrator via `scripts/tracker.sh comment <num> "AGENT STATUS branch=<b> worktree=<path> verdict=<v> repairs=<n>"` at claim time and at each wave gate.
Git stays reconciliation truth (P11): a resumed session trusts git over any receipt and relaunches (never resumes) a half-done unit, finding it via `scripts/tracker.sh next-eligible` or `claim <num> <session-id> --reclaim`.

## Live-session constraint

The orchestrator IS the loop: if this session dies (quota, crash), the loop stops - background subagents are not a durable scheduler.
When the loop must run unattended (overnight, scheduled), Agent-tool orchestration is the wrong tool; point to the Managed Agents API (the headless equivalent) rather than trying to keep an interactive session alive.
