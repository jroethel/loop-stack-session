# Session Archive: Loop Engineering Without /workflows

- **Date:** 2026-07-10
- **Participants:** Jeremy (user) and Claude Fable 5 (Claude Code session)
- **Working directories:** `~/loops` (research materials), `~/repos/ringer` (explored mid-session)
- **Outcome:** A converged architecture for running agent loops in Anthropic-only or mixed-provider scope, a detailed implementation plan, and this archive package.

Formatting note: Jeremy's messages are quoted verbatim (lightly trimmed).
Claude's responses are condensed for readability, but every table, diagram, and verdict is preserved exactly.
The principle/choice IDs (P1-P14, C1-C8) referenced in callouts are defined in `principles.md`.

---

## Exchange 1: The opening questions

**Jeremy:**

> I turned /workflows off due to excessive token consumption. Questions for you -
> 1. will /frontier-loop still work?
> 2. review the materials in this directory. is there a way to orchestrate a loop with agent teams without /workflows?
> 3. what revisions would you make to the skill based on the contents of this directory, and/or what files would you create in references based on the contents?

**Claude (Fable 5):**

Explored `~/loops` (eight articles/guides on loop engineering, the fable-orchestration skill repo, two Anthropic Managed Agents notebooks) and the installed `frontier-loop` skill.
Answers:

1. **frontier-loop mostly works.** It is a plan-converter; Steps 1-4 and 6 are tool-agnostic. Two breaks: Step 5's "Launch one Workflow for the wave; `pipeline()` over the wave's units" is a /workflows primitive that no longer exists, and Step 1 points at an external dshon-project file as its output example.
2. **Yes, native Claude Code primitives replace /workflows fully:** parallel background Agent calls (per-agent model override, worktree isolation), completion notifications reproduce `pipeline()` semantics (validator launches as each implementer finishes, no barrier between units), SendMessage carries the repair pass to the same implementer with context intact. One real loss: no detached durable pipeline, so the orchestrator session must stay alive; the skill's existing quota/resume machinery covers it. [C1]
3. **Proposed revisions:** rewrite Step 5 for native mechanics, replace the dshon pointer with a bundled example, add "judge raw evidence; ignore the implementer's narrative" to the validator prompt, add a distill step to the wave gate (the antifragile "evolve" move). New references: `native-orchestration.md`, `example-output-plan.md`. Deliberately excluded: duplicating fable-orchestration (install it instead), the Mira promo article, standing-loop/cron material (different shape).

A plan file was drafted; verification via RED-GREEN subagent testing per the writing-skills discipline.

---

## Exchange 2: Enter Ringer

**Jeremy:**

> okay. now explore ~/repos/ringer/ and tell me if that changes anything. it could mean one or more skill additions, revisions, deletions.. I'm just trying to be able to run loops either within an anthropic-only scope, or using a mix of model providers (anthropic, glm via z.ai using claude code, and openrouter for very cheap models.

**Claude (Fable 5):**

Explored the Ringer repo (README, its own orchestrator skill, config, templates, MODEL-NOTES).
**Yes, it changes the plan significantly.** [C2]

Ringer is a verified-swarm orchestrator: manifest of tasks -> parallel cheap CLI workers, each verified by an **executed check command** (exit 0 is the only PASS), one retry with failure context injected, all attempts logged to a local scoreboard with an explore/promotion ladder. [P1, P8]

Key changes:

1. **Ringer is the mixed-provider substrate, nearly complete.** It already implements the one-repair-pass rule, worktree isolation with the patch-export pattern, durable run state, and evidence-based routing that beats frontier-loop's hardcoded "Sonnet implements, Opus validates." Its executed-check verification is stronger ground truth than an LLM validator's opinion (a worker self-reported "all 213 match exactly" while the check found 13 fabrications). [P2, P9]
2. **frontier-loop's revision becomes a substrate fork:** Anthropic-only -> native Agent tool; mixed-provider -> emit Ringer manifests, with model assignment from `./ringer.py models --task-type` instead of guesses.
3. **One real gap:** no engine for GLM via z.ai's flat-rate coding plan through the Claude Code CLI (config block + tiny wrapper script, not a skill). [C5]
4. **Additions by installing, not writing:** the ringer skill (`./ringer.py install-agent`) and fable-orchestration. Deletions: none; nothing conflicts.

---

## Exchange 3: Why three skills?

**Jeremy:**

> can you create a matrix comparing/contrasting the 3 skills then, along with use cases and token use estimates and relative costs? and relative complexities? just trying to understand why I need 3 skills if 1 would do.

**Claude (Fable 5):**

Short answer: they are 3 layers, not 3 competitors, but you could live with fewer. [C8]

| | **fable-orchestration** | **frontier-loop** | **ringer** (skill + tool) |
|---|---|---|---|
| **What it actually is** | A prompting style-guide: how to talk to Fable so it delegates instead of implements | A plan compiler: converts a multi-step handoff run-book into a wave/gate execution plan | An execution substrate: manifests -> parallel cheap workers -> executed checks -> scoreboard |
| **Layer** | Prompting discipline | Planning / work structuring | Execution / verification |
| **Runs anything?** | No | No (emits a plan doc) | Yes (spawns real workers) |
| **Providers** | Anthropic only (Fable/Opus) | Anthropic subagents (post-revision: can emit ringer manifests) | Any CLI: Codex, Grok, OpenRouter/GLM; z.ai lane addable |
| **Use case** | Any session where Fable might over-think or implement instead of delegating | Big multi-wave builds with dependencies, human checkpoints, resume-after-crash | Any parallel batch: fix swarms, reviews, focus groups, bakeoffs, migrations - one task or fifty |
| **Trigger frequency** | Passive, every Fable session | Rare - once per project kickoff | Constant - every batch of work |
| **Context cost when loaded** | ~0.9k tokens | ~1.5k tokens | ~3.5k tokens |
| **Cost to run** | $0 (it *saves* money - routes work off Fable) | One Fable conversion session, ~20-60k tokens, once per project | Orchestrator tokens for specs/checks (~5-15k/run) + workers: GLM ~1-3 cents/task, Codex/Grok flat-plan, frontier only for review |
| **Setup complexity** | Trivial - copy one file | Low - but its output plans carry real ceremony (waves, gates, run-state, resume prompts) | Highest setup (config, engines, sandbox wrappers, check-writing craft) - lowest marginal complexity per run after that |
| **Run complexity** | None | Medium - you babysit wave gates | Low - lint, run, read verdicts |
| **Unique thing only it has** | The Fable footguns (reasoning-extraction reroute, effort caps) | Dependency waves + validator tier + interruption/resume design | **Executed verification** - exit codes, not model self-reports - plus the per-model evidence scoreboard |

Overlap analysis: fable-orchestration is ~30% inside frontier-loop; frontier-loop's implementer/validator/retry structure is ~70% of what ringer does natively.
What ringer lacks: dependency ordering between tasks and the human-checkpoint/resume culture.

**Verdict:** if you keep only one, keep ringer.
Keep frontier-loop only if multi-wave dependent builds are real for you.
fable-orchestration's genuinely unique content is ~10 lines; fold them into CLAUDE.md and skip the third skill. [P4]

---

## Exchange 4: What does Ringer eat?

**Jeremy:**

> what inputs does ringer need? could I give it a fable-sandwich plan? would that plan need to be translated or would I need to set it up as a series of steps that eval/return a specific condition?

**Claude (Fable 5):**

Ringer takes one manifest JSON, a **flat list of independent tasks**, each `{key, spec, check, expect_files, engine, model, task_type, timeout_s}`.
The whole contract: spec in, executable verdict out.

**A fable-sandwich plan cannot be fed directly.** Three structural mismatches: [C4]

1. **No dependency graph** - a manifest is one parallel wave; sequencing is the orchestrator's job.
2. **Specs need rewriting** - workers are stateless and mute; everything must be in the spec text (pointer specs are a lint violation).
3. **Every task needs an executable check** - the real translation work; judgment-shaped acceptance criteria must become something a shell can fail. [P6, P14]

The translation, mapped:

| Fable-sandwich element | Where it lands |
|---|---|
| Fable steps (architecture, judgment, kill/continue calls) | **Never enter ringer.** They're your orchestrator session's own lane |
| Opus/Sonnet execution steps | Ringer tasks - spec rewritten self-contained, model via `engine`/`model` fields |
| A step's acceptance criteria | The `check` command (the hard part - often a small validator script) |
| "Fable validates the result" steps | Either you read the artifacts at the wave gate, or a `code-review` task with a structure-enforcing check |
| Step ordering / dependencies | Separate runs, sequenced by you; same `run_name` so Ringside shows one evolving job |
| Human checkpoints | Between runs - you're already there reading the wave's results |

This translation IS the job of the revised frontier-loop: sandwich plan -> wave-sequenced manifests with executable checks.

---

## Exchange 5: One brain, and who verifies at the end

**Jeremy:**

> so extending the workflow it would be.. brainstorm -> research -> plan/prd -> fable sandwich -> frontier-loop (sandwich plan into waves, each becoming a ringer manifest -> ringer executes and verifies wave? what orchestrates the waves and verifies everything when it's done? doesn't ringer already use a frontier model for orchestration? I feel like I mostly understand.

**Claude (Fable 5):**

One correction closes the loop: **ringer has no model in it at all.** [C3]
It is 8,300 lines of stdlib Python; zero LLM calls of its own.
When ringer's docs say "the orchestrator," they mean whatever agent is typing `./ringer.py run` - your Claude Code session.
There is exactly **one brain through the whole pipeline**: [P5]

```
YOUR CLAUDE CODE SESSION (Fable or Opus - the only orchestrator anywhere)
│
├─ brainstorm ──────────── superpowers:brainstorming
├─ research ────────────── subagents (or a ringer research-with-proof run)
├─ plan / PRD ──────────── writing-plans / fable-sandwich
├─ compile to waves ────── frontier-loop: deps -> waves, steps -> specs+checks
│
└─ THE WAVE LOOP (same session, repeating):
     write wave-N manifest
     ./ringer.py lint && ./ringer.py run     <- ringer: dumb, verified muscle
     ── wave gate (this is the session again) ──
     read run JSON + raw logs of any retry/fail
     spot-check one PASSING artifact
     apply patches to integration branch, run full suite
     fold lessons into next wave's specs
     write wave-N+1 manifest from wave-N's results
```

Verification is three nested layers: per task (the executed check), per wave (the gate: post-run ritual + full suite on the integration branch), end of job (a final verification wave: adversarial-review tasks + an end-to-end task whose check runs the real thing cold, then you, then the human on the Ringside artifact page). [P12]

Cost: orchestrator tokens were already being paid; the stack removes frontier tokens spent on *typing*.
Simplification spotted: **fable-sandwich and frontier-loop are two halves of one compile step** - the sandwich's real contribution (model-tier routing) collapses into the manifest's `engine`/`model` fields, informed by `./ringer.py models`.

---

## Exchange 6: Does the compile skill exist? Scoreboard vs benchmarks

**Jeremy:**

> that helps. So.. brainstorm, research, get a plan/PRD (which serves multiple purposes). Then it's a skill that creates waves + manifests and runs ringer. Does that skill exist yet? Is the ./ringer.py models a model evaluator, a la how fable-sandwich uses model-benchmarks.md?

**Claude (Fable 5):**

**No, that skill does not exist yet.**
frontier-loop (current) assumes /workflows and doesn't know ringer exists; ringer's skill handles one run at a time with no concept of waves.
The gap between them - PRD -> waves -> manifests -> drive runs and gates - is exactly what the planned frontier-loop revision becomes.

On `./ringer.py models` vs fable-sandwich's benchmarks file: same job (evidence-based routing), opposite ends of the evidence spectrum, and they compose: [P7]

| | `model-benchmarks.md` (fable-sandwich) | `./ringer.py models` |
|---|---|---|
| Evidence | Public benchmark suite, someone else's 4 task categories | **Your own executed-check outcomes**, per (model, task_type), logged automatically every run |
| Nature | A *prior* - signal about models you've never run | A *posterior* - ground truth about models on *your* tasks, your specs, your machine |
| Granularity | 4 broad categories, one score each | `first_try_pass_rate`, retry-rescue rate, median tokens/duration per task shape |
| Freshness | Manual refresh via benchmark-refresh | Every attempt appends a row; `--explore` joins the OpenRouter catalog to queue untested/free candidates |
| Portability | Portable across users | Deliberately not - another machine's numbers are meaningless for yours |

The promotion ladder ties them: benchmarks (prior) pick which untested model earns an audition slot; the scoreboard (posterior) decides when it's proven (3+ tasks, first-try >= 0.67).
GLM-5.2 is the live example: benchmarks call it a knowledge-work specialist at 63 average, but the local log shows it proven on structured code review and persona work at 1-3 cents/task.

---

## Exchange 7: When to use it, and the One-Minute Test

**Jeremy:**

> I want to better understand when I would use this approach, or perhaps, when I would not use this approach? Does it work equally well when number of waves W = 1 and number of tasks T = 1 as it does when W = 50 and T = 10 per? Sounds like the marginal overhead is quite low, and I'm pondering because I'd like to keep the decisions of "how to architect this project" as straightforward as possible. Related, I wonder what /one-minute-test eval would contribute/say about this?

(Asked twice; the second time after the first answer got tangled in plan mechanics. Direct answer below.)

**Claude (Fable 5):**

**When to use:** when checking the output is cheaper than producing it - a test suite, a render, a grep-able contract, an exit code. Ringer's entire value is the executed check. [P6]

**When NOT to use:**
- Taste/judgment-dominant work (naming, strategy, "is this good?") - a check that cannot fail is trusting the worker with extra steps.
- Work coupled to your live session (needs back-and-forth).
- When the check would cost more than the task (do it inline).
- Rare + sensitive + human-reviewed-anyway (the tax-folder case).

**W=1, T=1 works by design** ("a single task is a one-task manifest"; the probe template is exactly this). Marginal overhead per task: one spec + one check, ~1-3k orchestrator tokens. The cost curve is nearly flat per task. [P13]

**What does not stay flat is the top end.** At W=50 the binding constraint is *you*: every wave gate is a review sitting. Practical ceilings: opencode's sqlite locks with even 2-6 simultaneous spawns; the "don't bury the human in 30 PRs" bandwidth rule. Big jobs want fewer, fatter waves - W=50 is almost always a mis-compiled W=8.

**The architecture decision, kept straightforward - two questions in order:**
1. Checkable by a command? No -> don't enter the stack; it's session/judgment work.
2. Do units depend on each other? No -> one manifest. Yes -> compile into waves, gate between them.

**What one-minute-test contributes:** it is exactly this router, pre-packaged - run after the PRD. [C6]

| Verdict | How much stack you use | Example |
|---|---|---|
| **CHAT** | None. One exchange in a session | "Summarize this transcript" |
| **ONE AGENT** | Ringer, one-task manifest. No compile skill | A probe, one scripted fix, one doc sweep |
| **AGENT TEAM** | Ringer, one manifest, W=1, T=N | Review swarm, focus group, migration batch |
| **AGENT TEAM + dependencies** | Full stack: PRD -> compile skill -> waves -> ringer | Multi-wave build where units plug into each other's interfaces |
| **DON'T BOTHER** | Checklist, your own hands | Rare + sensitive + taste-judged work |

Notably, the one-minute-test reference file literally names Ringer as the AGENT TEAM route ("Use Ringer or a small named team").
Its underrated contribution is the DON'T BOTHER verdict - protection from the "everything looks agent-shaped" trap that low marginal overhead invites.

---

## Exchange 8: The flowchart converges

**Jeremy:**

> got it. I like ringer off the shelf from the repo. I'm envisioning a plugin or skill pack that:
> step 0: starts with a plan/PRD input
> step 1: evaluates a la one-minute test (by the way, the slider is an interactive website, the skill distills that so the LLM can essentially replicate)
> based on that outcome:
> step 2a: don't bother - just give the PRD to chat session and have it get to work.
> step 2b: one agent OR agent team:
> - if checkable and checking is cheaper than producing, then ringer.
> - if judgement or back & forth or human needed then
>   - one agent: session w/ frontier model
>   - agent team: is this where frontier-loop comes into play with human gates?
> I'm picturing a flow chart. The "do units depend on each other" needs to be accounted for though.. thoughts?
> my intent here is to make sure I arrive at your plan.. or "a" plan, and understand how we got here.

**Claude (Fable 5):**

The flow is 90% right; two corrections and one restructure: [C7]

**Correction 1:** step 2a conflates two verdicts. DON'T BOTHER means *no AI* (human checklist); "give the PRD to the chat session" is the CHAT verdict.

**Correction 2:** checkability and team-ness are separate axes, and **checkability is asked per-unit, not per-project**. Real PRDs are mixtures; the compile step routes each unit. "Do units depend on each other" is a *third* axis deciding W.

Three questions asked in order, each owning one axis:
1. **Scale** (one-minute-test): none / chat / one / team
2. **Dependencies** (only if team): flat -> one manifest; dependent -> compile into waves
3. **Checkability** (per unit): executable check -> ringer task; judgment -> orchestrator lane

```
PRD/plan
   │
   ▼
[1] one-minute-test ──> DON'T BOTHER ──> human checklist, no AI
   │                ──> CHAT ─────────> current session, one pass, you review
   │                ──> ONE AGENT ────> checkable? ──yes──> one-task ringer manifest
   │                                        └──────no───> session/subagent (frontier), you review
   ▼
 AGENT TEAM
   │
[2] units depend on each other?
   │
   ├── no ──> ONE ringer manifest (W=1, T=N)
   │          judgment units stay behind with the orchestrator;
   │          you review the artifact page at the end
   │
   └── yes ─> frontier-loop (the compiler + wave driver)
              │  derive waves from the dependency graph
              │  per unit [3]: checkable -> ringer task (engine/model
              │      off the scoreboard); judgment -> orchestrator does
              │      it at the gate, or a fresh-mind review task whose
              │      CHECK enforces structure while YOU judge substance
              ▼
              wave loop: manifest -> run -> gate (review, integrate,
              distill lessons) -> next wave
              human gates: every wave gate + anything outward-facing
```

On "agent team + judgment -> frontier-loop with human gates?": half yes.
frontier-loop enters on the *dependency* axis, not the judgment axis.
A judgment-heavy team need is usually the "separation" case (fresh-mind critic), which ringer handles via review tasks whose checks enforce structure while the human judges substance.
Human gates are not frontier-loop's property; even a flat ringer run ends with the human on the artifact page.

This flowchart IS the plan: box [1] = one-minute-test (exists, untouched); boxes [2]+[3]+wave loop = the revised frontier-loop; ringer = off the shelf + the z.ai engine block.

---

## Exchange 9: The archive request (this deliverable)

**Jeremy:**

(Installed the plantuml plugin from the 365-skills marketplace, then:)

> I want this entire conversation archived in a .md file. include all tables, make it clear who is asking/responding.
> I want the full detailed plan created. I will review it in more depth before approving.
> I want you to do an exquisite job of capturing the evolution of the conversation and the learnings, *and* I want you to oversee a cheaper model actually producing #2 and #3 below (I need to preserve my Fable quota!)
> 1. identify the key harness / loop engineering principles and critical path choices at play?
> 2. use the /plantuml skills to create diagrams: (a) the evolution of the conversation with callouts to #1, (b) the three decisions on their own axis, (c) the routing flow with sufficient explanation, (d) ringer model deployment and dashboard architecture.
> 3. a learning_guide.html that captures this session's learnings, aha moments, and incorporates #1 and #2

**Claude (Fable 5):**

Produced this package in `~/loops/loop-stack-session/`:

- `conversation-archive.md` (this file) - written by Fable
- `principles.md` (P1-P14, C1-C8) - written by Fable
- `PLAN.md` (full detailed implementation plan, pending Jeremy's approval) - written by Fable
- `diagrams/` (four PlantUML diagrams, .puml + .png + .svg) - produced by Sonnet under Fable's review
- `learning_guide.html` - produced by Sonnet under Fable's review, incorporating the principles and diagrams
