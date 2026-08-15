# Model Benchmarks - Prior Tier

This file is the prior tier of the loop-drive routing chain.
It is also loop-which's concrete set of tier examples, skimmed to offer current model names per tier.

A model with no local scoreboard evidence routes by its row here.
Prior semantics follow the ringer promotion ladder: a model is untested until it has scoreboard rows, on probation through its first rows, and proven at 3+ scoreboard rows.

Maintenance rule: rows are dated; update a row when a benchmark lands or when a scoreboard graduation changes a model's tier.
Tier vocabulary is Frontier / Strong / Fast / Specialty (loop-which's tiers).

| Model | Tier | Best for | Avoid for | Prior source (dated) | Notes |
| --- | --- | --- | --- | --- | --- |
| fable | Frontier | Orchestration, arbitration, validation. | Never a worker - orchestrator-tier only. | DeepSuite 2026 benchmark | Low effort $3.76/task at 60% pass beats Opus 4.8 max $13/task 59%; effort capped at high. |
| opus-4.8 | Frontier | Architecture-defining, math- or reasoning-heavy, risk-concentrated units. | Quota-thin routine execution. | DeepSuite 2026 benchmark | The usual pin target for design, math, risk, or taste. |
| sonnet-5 | Strong | General execution on the Agent-tool transport. | Architecture-defining or risk-concentrated units; pin up. | loop-which tier examples, 2026-07-19 | Default execution worker on the Agent-tool roster. |
| haiku-4.5 | Fast | Thin, mechanical, well-referenced units. | Open-ended reasoning or unscaffolded work. | loop-which tier examples, 2026-07-19 | Cheapest Agent-tool worker; tightens latency on thin units. |
| glm-5.2 (claude-zai) | Strong | Execution typing at zero Anthropic quota. | Taste judgment; high-stakes reasoning (pin up). | zai-engine-probe, 2026-07-17 | Posterior depressed pending seven stm-nav amendments (ringer #65, AMENDMENTS-PENDING.md); read prior until amended. |
| codex | Specialty | Codex-engine-only tasks, if wired. | Anything unless the codex engine is wired. | none yet (no local evidence) | No local scoreboard evidence; treat as untested until a run lands. |

## Routing chain

This section is the single home of the routing-chain narrative.
Every skill that routes a unit (loop-drive, wayfinder, ringer-substrate) carries one pointer line to here - `Per-unit model choice follows the routing chain (config/routing/model-benchmarks.md).` - never a restatement.

Per-unit model choice is one chain, in order (P7: route by evidence, not vibes):

1. **Integrity-gated scoreboard posterior.** From the ringer repo root recorded by the loop-drive Step 0 probe, run `./ringer.py models --task-type <type>`. Before trusting a posterior, read `<ringer-repo>/docs/MODEL-NOTES.md` and `<ringer-repo>/docs/AMENDMENTS-PENDING.md` for the models under consideration; if the ringer repo is missing, treat the posterior as unverified and fall to the prior tier.
2. **Else benchmark prior.** A model with no trusted local scoreboard evidence routes by its row in the tier table above.
3. **Else orchestrator pin.** Design, math- or reasoning-heavy, risk concentration, or taste: pin `engine` and `model` and record the reason. A pin outranks the chain at any tier when its trigger holds; the reason is never "seems hard".

The distilled form: **scoreboard posterior, else benchmark prior, else orchestrator pin.**

**Ringer-absent degraded routing (operative portability policy, not narrative).**
If the Step 0 capability probe reported ringer absent on this machine, skip tier 1 entirely and route every unit by benchmark prior, else orchestrator pin, among the Agent-tool roster. This keeps a ringer-less machine routing on evidence rather than stalling.

**Tie-break.** The flat-rate `claude-zai` (GLM) lane takes ties or thin evidence, keeping Anthropic quota for orchestration and gates; this is a tie-break, not a tier.

**Promotion ladder.** Prior semantics follow the ringer ladder: a model is untested until it has scoreboard rows, on probation through its first rows, and proven at 3+ scoreboard rows.

**Roster.** Fable is orchestrator-tier only and never a worker; GLM and codex run only via ringer; sonnet, opus, and haiku are the Agent-tool workers.
