# Harness / Loop Engineering Principles and Critical Path Choices

Distilled from the 2026-07-10 session (Jeremy + Claude Fable 5) on running agent loops without /workflows, across Anthropic-only and mixed-provider scopes.
Principles carry IDs (P1-P14) so the diagrams and learning guide can reference them.

## Provenance: what we generated vs what we inherited

Most of the PRINCIPLES were inherited from the materials studied; the session's original contribution is the ARCHITECTURE - every critical path choice (C1-C8), plus three genuine syntheses within the principles.

Attribution of the sources themselves:

- **ringer** and the **one-minute-test** framework are Nate B. Jones's work (github.com/NateBJones-Projects/ringer, whose README credits "Jon Edwards and his agent fleet"; unlock-ai.natebjones.com for the one-minute-test).
- **frontier-loop** and **fable-sandwich** are JEREMY'S own skills, built pre-session on his workflow and architecture atop principles that already existed.
  In particular the graceful-resume / design-for-interruption machinery (P11) is Jeremy's.
- The **~loops articles** are by their named authors (Kopadze, rody, Shann, Zhou, JUMPERZ).

Legend: **[R]** ringer (Nate B. Jones) - **[1MT]** one-minute-test (Nate B. Jones) - **[FL]** frontier-loop (Jeremy's pre-session skill) - **[A:name]** a ~loops article - **[S]** generated in this session.

| ID | Provenance | Origin |
|---|---|---|
| P1 | [R] [A:Kopadze] | Inherited: "verify is the heart of the loop" (Kopadze); "exit 0 is the only PASS" (ringer) |
| P2 | [R] [A:architect-guide] | Inherited: the 213-quotes case (MODEL-NOTES); "the builder never grades its own work" |
| P3 | [A:Kopadze] [A:rody] [FL] | Inherited: maker/checker split; fresh-eyes fixer agent; validator tier |
| P4 | [A:architect-guide] [A:Shann] [R] | Inherited: architect judges, builder types; premium spend scales with decisions |
| P5 | [A:Shann] | Inherited: one model plans and scores or evaluation drifts |
| P6 | [1MT] + [S] | **Hybrid**: the checkability question is 1MT's slider 4; this session elevated it to THE routing gate of the whole stack |
| P7 | [R] + [S] | **Hybrid**: scoreboard and promotion ladder are ringer's; the prior/posterior framing tying public benchmarks to the local log is ours |
| P8 | [R] [A:rody] | Inherited: retry-once-with-context; retry limits; same-error-twice rule |
| P9 | [R] [FL] | Inherited: worktrees, patch-export footguns; disjoint-files-by-construction |
| P10 | [A:Zhou] | Inherited: state vs logs, the evolve move, antifragile loops |
| P11 | [FL] | **Jeremy's (pre-session)**: the graceful-resume and durable-state design from his frontier-loop skill |
| P12 | [A:Zhou] [FL] [R] | Inherited: earned autonomy, boundaries, checkpoint culture, review bandwidth |
| P13 | [S] on [R] foundation | **Mostly ours**: ringer says "a single task is a one-task manifest"; the W-scaling analysis, gate-bandwidth-as-binding-constraint, and "W=50 is a mis-compiled W=8" came from this session |
| P14 | [R] | Inherited: check-craft rules and the process lessons (checks were the top failure source) |
| C1-C8 | [S] | **All ours by definition** - these are the decisions this session made, each informed by the sources above but existing nowhere in them |

## Part 1: The principles

### P1. Verification is the heart of the loop

Without a real check, a loop is the agent agreeing with itself on repeat.
The strongest check is an EXECUTED one: exit codes, rendered output, fetched citations - not a model reading a diff and forming an opinion.
"A check that cannot fail is trusting the worker with extra steps."

### P2. Worker self-reports are worthless

The evidence case: a worker self-reported "all 213 quotes match exactly, 0 errors" while the executed check found 13 stitched/paraphrased quotes.
Judge raw evidence; ignore the implementer's narrative.
Verdicts belong to the orchestrator and the human, never to the producer.

### P3. Maker and checker must be separate minds

The model that wrote the code is too close to it, too proud of it, too likely to overlook its own mistakes.
Validators never fix; implementers never grade.
A fresh context beats the fifth retry of a tired session.

### P4. Split roles by the price of judgment

Frontier tokens are priced like senior-engineer hours, and most of a build is not senior-engineer work.
The frontier model plans, arbitrates, and reviews (~5-15% of the work); cheap workers do the typing.
Premium spend then scales with decisions made, not lines of code written.

### P5. One brain orchestrates, or evaluation drifts

Multi-agent setups break when different models judge the output - inconsistent evaluation compounds.
One model owns planning AND scoring, even as the fleet grows.
Corollary risk: if the same model writes the goal and scores it, one wrong assumption survives every layer - which is why P1's executed checks anchor the judge to ground truth.

### P6. Checkability is the routing gate

Work enters the swarm only when checking the output is cheaper than producing it.
Taste-only work (naming, strategy, "is this good?") fails the test: judging costs as much as making, so more agents just produce a larger pile of fluent options.
This is a property of the work's shape, not its size.

### P7. Route models by evidence, not vibes

Public benchmarks are a PRIOR (signal about models you've never run); your local executed-check log is the POSTERIOR (ground truth on your tasks, your specs, your machine).
The promotion ladder operationalizes it: untested -> probation -> proven (3+ tasks, first_try_pass_rate >= 0.67).
Spend a small slice of every suitable run auditioning cheap/free candidates so the bench refills itself.
Numbers are not portable between users.

### P8. Bounded failure, isolated blast radius

One retry with the check's failure output injected; a second failure stops that unit without blocking siblings.
No retry limit = an agent burning an hour circling one error.
Two identical failures in a row means the model is guessing - escalate, don't re-roll.

### P9. Isolation is what makes parallelism safe

Parallel agents cannot share one checkout: one worktree per worker, disjoint file ownership by construction, merge conflict at the gate = scope violation, not something to quietly resolve.
Footgun class: passing worktrees get deleted, so deliverables must be exported (patch-export pattern) and gitignored outputs copied out explicitly.

### P10. State is memory; distill or repeat forever

Split durable state (small, read every run) from append-only logs (the record).
Logs only ever get longer; distilling lessons into state, specs, and contracts is what makes a loop antifragile - worth more in month three than week one.
The "evolve" move: periodically read the last dozen runs and change the loop itself.

### P11. Design for interruption

The loop must die safely at any moment (quota, crash).
Workers commit and log before returning; the orchestrator maintains a run-state artifact; recovery trusts git over the state file and relaunches (never resumes) half-done units.

### P12. Human gates scale with risk, not with size

Gates sit at wave boundaries and in front of anything outward-facing (live consumers, publishing, deletion).
Autonomy is earned per lane by evidence (a segment's reply rate, a model's pass rate), not granted globally.
Respect review bandwidth: a loop that buries the human in 30 unreviewed PRs is a failed loop with good throughput.

### P13. Marginal overhead is flat; gate bandwidth is the constraint

The stack works at W=1, T=1 (a single task is a one-task manifest) because per-task overhead is a spec + a check.
At W=50 the binding constraint is the human: every wave gate is a review sitting.
Big jobs want fewer, fatter waves - W=50 is almost always a mis-compiled W=8.

### P14. Check craft is as important as spec craft

In practice the orchestrator's CHECKS were the top failure source - fixture bugs and over-strict regexes failed honest work repeatedly.
Checks must print WHY they fail (the retry prompt depends on it), verify substance not existence, stay strict on substance and tolerant on format, and get the same review care as production code.
Read raw logs before blaming the model: post-mortems ruled FOR the worker three times in one run.

## Part 2: The critical path choices

The decisions that shaped the final architecture, in the order they were made:

### C1. /workflows off; native primitives replace pipeline()

Background Agent calls + completion notifications + SendMessage reproduce pipeline semantics for Anthropic-only work.
Cost: no detached durable pipeline - the orchestrator session must stay alive, making P11's durable-state rules load-bearing.

### C2. Adopt Ringer off the shelf rather than build an execution layer

Ringer already implements the implement -> executed-check -> retry-with-context unit loop, worktree isolation, evidence logging, and a dashboard - in tested, zero-LLM stdlib Python.
Writing our own would duplicate ~70% of it, worse.

### C3. Ringer has no model in it; the orchestrator is YOUR session

Ringer is muscle, not brain.
One brain (P5) runs the whole pipeline: brainstorm -> plan -> compile -> drive waves -> gate -> final verdict.
Orchestrator tokens were already being paid; the stack removes frontier tokens spent on typing.

### C4. frontier-loop becomes the wave compiler, not a parallel orchestrator

A fable-sandwich plan cannot be fed to Ringer directly: no dependency graph, stateless specs, and every task needs an executable check.
That translation (plan -> waves -> manifests) is exactly one skill's job.
fable-sandwich's per-step model routing collapses into the manifest's engine/model fields, informed by the scoreboard (P7).

### C5. Provider mix is config, not skills

GLM via z.ai's flat-rate coding plan = one engine block + a wrapper script exporting ANTHROPIC_BASE_URL to the claude CLI.
OpenRouter cheap lane = the existing opencode engine.
Engines are pluggable; skills don't multiply.

### C6. one-minute-test is the front door

Route before building: CHAT / ONE AGENT / AGENT TEAM / DON'T BOTHER decides how much of the stack a job engages.
DON'T BOTHER is a legitimate, frequent verdict that protects against the "everything looks agent-shaped" trap - which low marginal overhead (P13) otherwise invites.

### C7. The architecture decision is three questions on three axes

1. Scale (one-minute-test verdict): none / chat / one agent / team.
2. Dependencies (only if team): flat -> one manifest; dependent -> waves.
3. Checkability (per UNIT, not per project): executable check -> ringer task; judgment -> orchestrator lane.
Real PRDs are mixtures; routing per unit is what resolves them.

### C8. Keep three skills as three layers, minimized

ringer (execution playbook, ships with the tool), frontier-loop revised (compile + wave driving), one-minute-test (routing).
fable-orchestration folds to ~10 unique lines (the reasoning-extraction reroute footgun, effort ceiling) rather than remaining a fourth skill.
They are layers, not competitors: router -> compiler -> executor.
