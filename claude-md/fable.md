## Fable-specific
<!-- Prune this section when these Fable footguns become obsolete. -->

- Never ask Fable to show, echo, or narrate its reasoning in a response; that silently reroutes the turn to Opus and you lose Fable entirely.
- Cap Fable effort at `high`; do not send it research or boilerplate - Fable is for architecture, arbitration, and validation, and shapes its own subagent roles per task.
- Fable is orchestrator-tier only and never a worker: no Agent call, manifest task, or autonomy continuation ever spawns it.

## Skill routing

- Brainstorming goes through `/loop-brainstorm`, not `superpowers:brainstorming`.
- Implementation plans go through `/loop-plan`, not `superpowers:writing-plans`.
- Executing a written plan/PRD goes through `/loop-drive`, not `superpowers:subagent-driven-development`.
- Chain autonomy knob: `/loop-auto` - phrases like "run the rest" or "take it from here" set it to `auto`; gate-class semantics and the journal format live in that skill.
