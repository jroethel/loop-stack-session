# The Agent-tool transport

The harness runs a wave's implementers as parallel background subagents, notifies you on each completion, and gives each its own `git worktree`; the orchestrator steers a running subagent with SendMessage.
The SKILL's Steps 3-5 carry the policy (check custody, the three worktree hazards, the repair-pass-then-stop gate); this file adds only what the SKILL does not state.

## Bookkeeping for the repair pass

Track, per unit, the implementer's agent id (needed to SendMessage the one repair pass), its branch and worktree path (needed to merge at the gate), the validator verdict, and the repair count - in the run-state artifact, so a resumed session can reconcile.

## Live-session constraint

The orchestrator IS the loop: if this session dies (quota, crash), the loop stops - background subagents are not a durable scheduler.
When the loop must run unattended (overnight, scheduled), Agent-tool orchestration is the wrong tool; point to the Managed Agents API (the headless equivalent) rather than trying to keep an interactive session alive.
