## Fable-specific
<!-- Prune this section when these Fable footguns become obsolete. -->

- Never ask Fable to show, echo, or narrate its reasoning in a response; that silently reroutes the turn to Opus and you lose Fable entirely.
- Cap Fable effort at `high`. `xhigh`/`max` make Fable over-reason and waste the turn.
- Do not predefine subagent archetypes for Fable; let it shape the roles per task.
- Do not send research or boilerplate to Fable; that is Opus/Sonnet work. Fable is for architecture, arbitration, and validation.

## Skill routing

- Brainstorming goes through `/loop-brainstorm`, not `superpowers:brainstorming`.
- Implementation plans go through `/loop-plan`, not `superpowers:writing-plans`.
- Executing a written plan/PRD goes through `/loop-drive`, not `superpowers:subagent-driven-development` 

## Model routing

- Model choice for execution units follows the evidence chain (integrity-gated scoreboard posterior, else benchmark prior, else orchestrator pin); substrate is derived per-unit transport, not a per-wave choice.
- Execution typing leans to ringer's `claude-zai` engine (the z.ai flat-rate lane) when evidence ties or is thin; keep Anthropic quota for orchestration, review gates, and judgment.
- Wired engines are ground truth in `~/.config/ringer/config.toml`; read it, don't assume.
- Benchmark prior file: `~/.claude/skills/frontier-sandwich/references/model-benchmarks.md`; repo source is loop-stack `config/routing/model-benchmarks.md`.
- Role pins (skills cite roles, never hard-pin model names): rubix lens A = Opus; rubix lens B = Opus, or Fable when the plan is flagged high-stakes; optional third lens = GLM via claude-zai; native validator = Opus; plan-draft and drive-compile dispatches = Opus (these dispatch roles land with the build wave).
- Worker roster: Agent-tool workers are sonnet, opus, haiku; Fable is orchestrator-tier only and never a worker; GLM and codex run only via ringer.

## Chain autonomy

The chain has an autonomy knob with two modes: `pause` (the unset default) and `auto`.
The knob is set and read through `scripts/loop-auto.sh` and persisted to `docs/chain-state.md`, the single source of truth.
Consumption is live: the knob now governs gate behavior per the four gate classes below.
Recognized phrases set the knob to `auto` with a one-line confirmation (never silent): "run the rest", "run the rest from here", "take it from here", "go autonomous", "auto mode", "full auto".

### Knob off or unset

Knob off or unset equals today's behavior: every gate fires live.
Nothing is auto-taken; every ASK, STOP, BATCH, and DEFAULT gate surfaces to the human.

### When autonomy takes effect

Autonomy takes effect only after the last ASK gate passes.
Up to and including that gate, the human is in the loop.
After it, the active session orchestrates the rest of the chain under the rules below.

### The four gate classes under autonomy

- ASK always blocks.
  It asks the human and waits; autonomy does not auto-answer an ASK.
- STOP always halts and states what it needs.
  A STOP names the missing input or the failing invariant (dirty tree, exceeded effort cap, outward-facing unit) and waits; autonomy never auto-resolves a STOP.
- BATCH auto-takes the named lean, proceeds, and collects the decision for the end review.
  The lean was already named in the gate's prose; autonomy takes it, records it, and moves on.
- DEFAULT auto-takes the default and logs verbosely.
  The default was already declared at the gate; autonomy takes it, logs the decision in full, and moves on.

### Batch-review list format

The batch-review list is the run's gate journal: it is created the moment autonomy takes effect and appended at every gate as it fires, in chronological order, so a run that dies mid-chain still leaves the record of every decision taken so far.
The list home is `docs/reviews/YYYY-MM-DD-<slug>-batch-review.md` (declared in `config/repo-state.md`).
All four gate classes are logged, but they carry two different obligations.
ASK and STOP entries are record-only: the human was present for them, so they preserve the chronology and the context around neighboring decisions but need no review.
BATCH and DEFAULT entries are the review obligation: each is a decision auto-taken for the human, to accept or reverse at the end-of-chain checkpoint.
Each entry has three fields: the decision (for record-only entries, what was asked or halted and how the human resolved it), the rationale, and a reversal path (record-only entries mark it `n/a - resolved live`).
The reversal is named honestly by gate type.
A DEFAULT or commit reversal is cheap: `git revert`, or undoing the default on the next pass.
A BATCH taste reversal (topology choice, triage) is a scoped re-run with the alternate lean, because the lean was a judgment, not a fact.
An entry with no honest reversal path is a signal it should have been a STOP, not auto-taken.

### Continuation rule

The session active when autonomy takes effect orchestrates the rest of the chain.
Delegation only goes down-tier - the orchestrator hands work to sonnet, opus, or haiku workers, or to ringer-transported GLM/codex.
Nobody ever spawns Fable.
Fable is orchestrator-tier only and never a worker, so the autonomy continuation never delegates to it, not even under full auto.
