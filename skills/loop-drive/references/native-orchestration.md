# The Agent-tool transport

The harness runs a wave's implementers as parallel background subagents, notifies you on each completion, and gives each its own `git worktree`; the orchestrator steers a running subagent with SendMessage.
The SKILL's Steps 3-5 carry the policy (check custody, the three worktree hazards, the repair-pass-then-stop gate); this file adds only what the SKILL does not state.

## Bookkeeping for the repair pass

Track, per unit, the implementer's agent id session-locally - the one field the `AGENT STATUS` receipt does not carry, because a fresh session cannot SendMessage a dead subagent anyway; it exists only to route the single repair pass to the same implementer.
The receipt format, its claim/gate cadence, and the git-over-receipt relaunch procedure live in the SKILL's Step 5; do not restate them here.

## Live-session constraint

The orchestrator IS the loop: if this session dies (quota, crash), the loop stops - background subagents are not a durable scheduler.
When the loop must run unattended (overnight, scheduled), Agent-tool orchestration is the wrong tool; point to the Managed Agents API (the headless equivalent) rather than trying to keep an interactive session alive.
