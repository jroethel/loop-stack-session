## Fable-specific
<!-- Prune this section when these Fable footguns become obsolete. -->

- Never ask Fable to show, echo, or narrate its reasoning in a response; that silently reroutes the turn to Opus and you lose Fable entirely.
- Cap Fable effort at `high`. `xhigh`/`max` make Fable over-reason and waste the turn.
- Do not predefine subagent archetypes for Fable; let it shape the roles per task.
- Do not send research or boilerplate to Fable; that is Opus/Sonnet work. Fable is for architecture, arbitration, and validation.

## Skill routing

- Brainstorming goes through `/loop-brainstorm`, not `superpowers:brainstorming`.
- Implementation plans go through `/loop-plan`, not `superpowers:writing-plans`.

## Model routing

- Execution typing defaults to ringer's `claude-zai` engine (the z.ai flat-rate lane) unless a unit needs Anthropic-side capability, in-session context sharing, or taste judgment. Keep Anthropic quota for orchestration, review gates, and judgment.
- Wired engines are ground truth in `~/.config/ringer/config.toml`; read it, don't assume.
