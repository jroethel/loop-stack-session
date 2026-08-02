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
- Benchmark prior file: `~/.claude/skills/fable-sandwich/references/model-benchmarks.md`; repo source is loop-stack `config/routing/model-benchmarks.md`.
- Role pins (skills cite roles, never hard-pin model names): rubix lens A = Opus; rubix lens B = Opus, or Fable when the plan is flagged high-stakes; optional third lens = GLM via claude-zai; native validator = Opus; plan-draft and drive-compile dispatches = Opus (these dispatch roles land with the build wave).
- Worker roster: Agent-tool workers are sonnet, opus, haiku; Fable is orchestrator-tier only and never a worker; GLM and codex run only via ringer.
