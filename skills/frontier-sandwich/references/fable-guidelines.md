# Frontier Sandwich Guidelines

Distilled from Jeremy Roethel's NotebookLM notebook "AI: Claude Fable" (July 2026).
These are the routing rules and prompt patterns the plan should embody.

## The core pattern

Use the frontier model for judgment, not keystrokes.

- **Phase 1 - Explore (Strong/Fast):** map the repo, collect files, summarize architecture, identify test commands, run deep research, prepare a clean brief. Research does not require frontier reasoning, and deep-research workflows can spawn 100+ subagents; never run those on Fable.
- **Phase 2 - Plan (Frontier):** feed the brief to Fable as staff engineer/architect. Design the safest plan, surface hidden coupling and risks, define verification steps. Start in plan mode / read-only to prevent accidental over-editing and to force a clean handoff artifact.
- **Phase 3 - Execute (Strong/Fast):** hand the written plan to Opus/GLM/Sonnet as implementation agents for mechanical edits, CRUD, boilerplate, test updates.
- **Phase 4 - Review (Frontier):** Fable reviews the diff for correctness bugs, edge cases, regression risk, missing tests; delivers a ship/no-ship recommendation. Fable reviewing another model's PR is one of its strongest documented use cases.
- **Phase 5 - Ship (Human):** final accountability.

## Task routing map

Great Frontier (Fable) tasks:
architecture decisions and reviews, migration planning, large multi-file refactor plans, complex bug diagnosis, ambiguous product-to-code translation, repo-wide dependency analysis, test strategy, codebase archaeology, comparing implementation approaches, long-running agent orchestration, final PR review.

Waste of Frontier tokens (route to Strong/Fast):
tiny syntax fixes, simple CRUD, renames, formatting, boilerplate, routine file search, basic test updates, mechanical implementation of an already-written plan.

Mental model: use Fable where mistakes are expensive.

## Effort dial (high leverage)

Pricing context: Fable 5 is ~2x Opus 4.8 ($10/$50 vs $5/$25 per Mtok); caching gives 90% off input, batch halves it.

DeepSuite long-horizon benchmark: Fable at **low** effort ($3.76/task, 60% pass) beats Opus 4.8 at **max** ($13/task, 59%).
Fable medium = 65%, high = 69%, xhigh = 70% ($22/task).
Max effort barely improves on xhigh.

Recommendations:
- `medium`: interactive coding help, routine work.
- `high`: default for serious engineering tasks.
- `xhigh`: architecture, migrations, deep debugging, final reviews only.
- Never xhigh for tiny edits.
- Pair higher effort with an instruction not to over-refactor beyond the requested scope.

## Prompt patterns

**Interview first.**
For large or messy work, have the model interview the user in batches before building: "before writing any code, interview me; ask every question you need about features, data, and design, one batch at a time, until you fully understand the build."
Practitioners report night-and-day better results.

**Tell it why.**
Give the reason behind the task, who it is for, and what it feeds into.
Context beats micromanagement.

**Ground claims in tool results.**
On long or autonomous runs, instruct the model to audit progress claims against actual tool output (tests, diffs).
Anthropic reports this nearly eliminated fabricated status reports.

**Never ask for hidden reasoning.**
Prompts like "show your full chain of thought step by step" trigger Fable's reasoning-extraction safeguards and can cause silent fallback to Opus 4.8 (billed as Opus, performing as Opus).
Ask instead for: conclusion, key evidence, tradeoffs, risks, recommended next action.
Audit skills and system prompts for show-your-thinking instructions.

**Security work: be explicit and defensive.**
State legitimate defensive scope clearly; vague vulnerability/exploit phrasing can trigger fallback.
Use `/security-review` for a deeper read-only pass.

## Orchestration options

**Subagents:** Fable = orchestrator and final synthesis; Strong = implementation agents; Fast/Haiku = scan and extraction agents.
Keep teams small, spawn prompts focused, shut agents down when done.

**Advisor mode:** set the session model to Opus (the executive that writes code and runs tools), then `/advisor fable` so Fable is consulted only when the executive is stuck.
Anthropic's Opus/Sonnet data showed the advisor pattern gives better results for cheaper.

**Worktree experiments:** have Fable propose 2-3 implementation strategies, run each in a separate git worktree with cheap implementation agents, then bring the diffs back to Fable to pick the safest.

## Environment hygiene (put these in the plan's setup step when relevant)

- Lean `CLAUDE.md`: package manager, how to run one test / full suite / lint / typecheck, non-obvious architecture rules, known traps. No tutorials, no obvious conventions, no stale info; bloat causes instructions to be ignored.
- `/clear` between unrelated tasks; `/context` to inspect; prefer `@file` references over descriptions; prefer CLI tools (`gh`, `aws`, `gcloud`) over MCP/API equivalents for context efficiency.
- Hooks for rules that must always happen: format/lint after edits, block writes to generated files or prod config, filter 10k-line logs down to failing lines before the model sees them. Instructions are advisory; hooks are deterministic.
