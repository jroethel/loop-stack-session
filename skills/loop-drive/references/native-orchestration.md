# Native orchestration (Anthropic-only substrate)

How the orchestrator session drives a wave of Claude Code subagents with the Agent tool.
This is the substrate to use when workers benefit from shared context and mid-flight steering, and every worker can be Anthropic.

## Tier mapping

- **Orchestrator**: this session. Owns the wave loop, gates, merges, spec edits, escalation. Never implements.
- **Implementer**: one subagent per unit, launched with the Agent tool.
- **Validator**: a fresh Opus subagent per unit, read-only, adversarial.

## Wave mechanics

1. **Parallel background launch.** Launch every implementer in the wave as a background Agent call in one batch. Background launches let the session keep control while workers run; you are notified as each finishes.
2. **Completion-notification handling.** On each completion notification, launch that unit's validator immediately (do not wait for the whole wave). Units flow implement then validate independently, with no barrier between siblings.
3. **SendMessage repair pass.** On a failed validation, send the itemized verdict back to the SAME implementer with SendMessage (its context is intact, so it repairs rather than restarts), then revalidate. A second failure stops that unit and leaves its siblings running.
4. **Task-tool bookkeeping.** Track, per unit, the implementer agent id, its branch and worktree path, validator verdict, and repair count, in the run-state artifact. You need the agent id to SendMessage the repair pass; you need the branch to merge at the gate.

## Isolation

- **Default**: give each implementer its own worktree. When the harness offers native `isolation: worktree`, use it; the worker gets an isolated checkout automatically.
- **Nested repos**: if the code lives in a repo nested inside the session's outer repo, native `isolation: worktree` snapshots the WRONG repo. The implementer must create the worktree itself with explicit `git -C <inner-repo> worktree add ../<unit>-wt -b <unit-branch>` commands you spell out in the prompt.
- **Environments do not travel**: an in-project venv is not in the fresh worktree; the prompt must run the install step (`poetry install`, `pip install -r requirements.txt`) inside the worktree.

## The session-alive constraint

The orchestrator is the loop.
If this session dies (quota, crash), the loop stops; background subagents are not a durable scheduler.
So: implementers commit their work and unit log before returning, the run-state artifact is updated at every launch and gate, and the plan carries a verbatim resume prompt plus a reconciliation procedure that trusts git over the state file and relaunches (never resumes) half-done units.

## Headless / scheduled loops

When the loop must run without a live session (overnight, on a schedule, unattended), Agent-tool orchestration is the wrong tool; it needs a live session.
Point to the Managed Agents API (headless equivalent) for that case rather than trying to keep an interactive session alive.
This skill's native mode assumes a live orchestrator session.
