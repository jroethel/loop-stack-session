---
name: loop-which
description: >
  Evaluates a plan, PRD, proposal, or task description and gives a verdict on which approach
  to take: a plain chat prompt, one accountable agent, a small agent team, or "don't automate
  this" - based on Nate B. Jones's One-Minute Test framework (full source in references/).
  Before giving the verdict, asks the user which models and orchestration tools are actually
  available to them and any big-picture constraints (access, sensitivity, how often the work
  recurs), so the recommendation is something they can actually run, not a theoretical ideal.
  Use this whenever the user shares a plan, PRD, spec, proposal, or roadmap and asks how to
  proceed, which approach they need, whether it's worth automating, whether to use one agent
  or a team, or "should I bother with AI for this" - even if they never say "loop-which",
  "one-minute test", or "route this."
---

# loop-which: the One-Minute Test router

Most AI mistakes are routing mistakes: an agent team built for a task an evening of chat would've
solved, a lone agent handed work that needed a second, independent check, or effort spent
automating something that should've stayed a fifteen-minute checklist. This skill applies Nate B.
Jones's One-Minute Test to a real plan or PRD the user has in hand, so the routing call happens
before the setup cost, not after.

Read `references/one-minute-test.md` for the full framework, the seven questions, and worked
examples (tax-folder organization, product naming, dishwasher research) of things that look
agent-shaped but aren't agent-worth. Read it in full before scoring a plan - the worked examples
are what keep the verdict honest instead of defaulting to whatever looks most impressive.

## Workflow

### 1. Get the plan

Read the plan, PRD, or task description the user gives you - pasted text, a file, or a
description in chat. If it's vague or bundles several unrelated deliverables together, don't
force it into one verdict: name the seams and offer to triage the pieces separately.

### 2. Ask what's actually available

The four routes only mean something relative to what the user can actually run. Before scoring,
ask in one batch (skip anything they've already told you). Use the `fable-sandwich` skill's tier
vocabulary so the answer plugs straight into a build plan later if the verdict calls for one:

- **Model tiers available** (multi-select): Frontier (best judgment - architecture, ambiguity
  calls, final review), Strong (solid all-around execution), Fast (cheap, mechanical work), and
  Specialty (a model that spikes hard on one category but is mediocre elsewhere - only trust it
  for that category). If `~/.claude/skills/fable-sandwich/references/model-benchmarks.md` exists,
  skim it first and offer the user its current concrete model names as examples for each tier
  instead of asking them to classify blind.
- **Big-picture constraints** (one question, can be free text): can you orchestrate multiple
  agents at all or is it chat-only, does the work touch sensitive access (financial, medical,
  credentials, anything irreversible), how often does this recur, and is there a hard deadline
  that changes what setup is worth it?

Don't ask what you already know from context. If the conversation already established the user's
available tiers or that they're chat-only, don't re-ask that part.

Orchestration availability has a ground-truth file: read the `[engines.*]` blocks in
`~/.config/ringer/config.toml` instead of asking which engines are wired.

Per-unit model choice downstream follows loop-drive Step 2's evidence chain (scoreboard posterior, else benchmark prior, else orchestrator pin); this skill only establishes what is available, never which model a unit gets.

### 3. Score the plan against the seven questions

Walk the plan through the framework (full detail in the reference file):

1. **Size** - how much source material has to stay in view at once?
2. **Independence** - can the useful parts proceed in parallel?
3. **Separation** - does any step need a fresh mind (a critic distinct from the producer)?
4. **Checkability** - is checking the output cheaper than producing it?
5. **Judgment** - how much of the work is judgment call versus mechanical?
6. **Access & consequence** - what access does it need, and what does a mistake cost?
7. **Payoff vs. setup** - does the frequency and value earn the setup cost?

Score the plan as a whole - most plans lean clearly toward one route even when a sub-task or two
doesn't fit. Note any part that obviously needs a different route than the overall verdict rather
than forcing everything into one bucket.

### 4. Reconcile with what's available

This is the step the source tool can't do on its own, since it has no idea what the user actually
has. If the ideal route needs something they don't have - the plan wants an agent team but they
only have a chat window, or it wants tool access they haven't mentioned having - say so plainly:
name the mismatch, then either

- recommend the best approximation achievable with what they described, or
- tell them what unlocking the ideal route would take, and give both: "this wants an agent team;
  if you have Claude Code that looks like {shape}, otherwise here's the chat-only version."

### 5. Give the verdict

Output, in this order:

- **Verdict** - CHAT / ONE AGENT / AGENT TEAM / DON'T BOTHER. Pick the lightest one that actually
  fits; don't round up because agent work feels more thorough.
- **Why** - 2-4 sentences tied to the specific questions from step 3 that drove the call, not a
  generic restatement of the framework.
- **Map** - a compact flow diagram showing where the verdict sits and what comes next, with the
  chosen path marked. Always plain monospace text in a fenced code block - never Mermaid, never
  a generated image, never a diagram skill or plugin - so it renders identically in any terminal
  or markdown view. Adapt the next-step labels to what the user actually has (e.g. drop the
  `/loop-drive` pointers for a chat-only user); the shape is:

  ```
  plan / PRD
   └─ /loop-which
       ├─ CHAT ........... paste the prompt below into a session
       ├─ DON'T BOTHER ... use the manual checklist below
       ├─ ONE AGENT ...... /loop-drive emits one brief or manifest   <== VERDICT
       └─ AGENT TEAM ..... /loop-drive compiles waves and drives them
  ```

- **Next step** - a ready-to-use artifact matching the verdict, adapted to the models/tools the
  user actually said they have (templates and shape for each are in
  `references/one-minute-test.md` under "What happens next"):
  - CHAT -> a narrow, pasteable prompt (task + source + what to return).
  - ONE AGENT -> a run-card (goal, done state, tools, cap, check).
  - AGENT TEAM -> a small named team spec (roles, gate).
  - DON'T BOTHER -> a short manual checklist, plus a trigger for when to revisit (e.g. "rerun
    this if it becomes a weekly job").

## Notes

- This is a triage step, not a build step. Once the verdict is ONE AGENT or AGENT TEAM and the
  user wants to actually build it, `loop-drive` is the skill that compiles and drives the
  execution; `fable-sandwich` is the alternative when they want a human-paced Frontier Sandwich
  run-book instead of an orchestrated loop.
- DON'T BOTHER is a legitimate, frequent verdict, not a failure to find a use case. Plans can look
  agent-shaped (files, steps, checks) and still not earn automation because the judgment isn't
  cheap to check or the payoff doesn't cover the setup - see the worked examples in the
  reference file.
- If the plan is really several unrelated tasks stapled together, say so and triage them
  separately rather than forcing one verdict across all of them.
