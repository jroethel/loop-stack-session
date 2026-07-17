# loop-stack

Agent loop engineering without `/workflows`: a router, a compiler/driver, and a verified execution substrate for running agent-team loops in Anthropic-only or mixed-provider scope.

This repo is the product of a 2026-07-10 session between Jeremy and Claude Fable 5.
The trigger: `/workflows` was turned off after it burned too many tokens, raising the question of whether agent-team loops were still possible.
Nine exchanges later the session had converged on a three-layer architecture, adopted an off-the-shelf execution substrate ([Ringer](https://github.com/natebjones), by Nate B. Jones: 8,300 lines of zero-LLM stdlib Python), and produced the two skills this repo ships.
The full story is in `learning_guide.html` (the seven aha moments), `conversation-archive.md` (the verbatim design conversation), and `PLAN.md` (the build plan, with post-execution amendments).

## The architecture

Three layers, one brain.
The same Claude Code session that brainstorms and drafts the PRD also compiles it into waves, drives each wave, and reads the gates.
Ringer is muscle, not brain: it fans tasks out to cheap engine lanes and verifies each with an executed check command, but makes zero LLM judgment calls of its own.

```
brainstorm ──> plan / PRD
               └─ /loop-which (One-Minute Test triage)
                   ├─ CHAT ........... paste one prompt into a session
                   ├─ DON'T BOTHER ... manual checklist
                   ├─ ONE AGENT ┐
                   └─ AGENT TEAM ┴──> /loop-drive
                                       compiles: deps -> waves, steps -> specs + checks,
                                       assigns models per unit, then DRIVES execution
                                       ├─ native substrate: parallel Claude Code subagents
                                       └─ ringer substrate: manifests on GLM / OpenRouter engines
```

| Layer    | Skill / tool | Job                                                                            |
|----------|--------------|--------------------------------------------------------------------------------|
| Router   | `loop-which` | One-Minute Test verdict: CHAT, ONE AGENT, AGENT TEAM, or DON'T BOTHER          |
| Compiler | `loop-drive` | Turn a plan or flat PRD into waves, specs, checks, and model routing; drive it |
| Executor | Ringer       | Zero-LLM swarm runner: isolation, executed checks, one retry, scoreboard       |

Key design points, argued in full in the learning guide:

- **No `/workflows` needed.** Parallel background Agent calls, completion notifications, and SendMessage reproduce `pipeline()` semantics natively. The one loss is a detached durable pipeline, so the loop's interruption-and-resume design is load-bearing.
- **Checkability is the routing gate.** Work enters the swarm only when checking the output is cheaper than producing it. Taste-only work stays in the orchestrator's own judgment lane.
- **Evidence over vibes.** Ringer-mode model routing comes from the local scoreboard posterior, falling back to benchmark priors, never from "seems hard".
- **Executed checks beat LLM reviewers.** Exit 0 is the only PASS. A check script costs zero model tokens; a per-task LLM reviewer does not.

## Where fable-sandwich fits

`fable-sandwich` (a separate skill, predating this repo) is the alternative branch, not a prerequisite.
Use it when you want a human-paced run-book: you opening sessions and pasting model-routed prompts step by step.
For an autonomous loop, hand the plan or PRD straight to `/loop-which` and then `/loop-drive`.
`loop-drive` derives the wave structure itself, even from a flat PRD, and re-derives model assignments rather than copying hints.
The session's own conclusion: fable-sandwich and loop-drive are two halves of one compile step, so feeding a sandwich plan into loop-drive works but duplicates effort.

## Why not superpowers subagent-driven-development

Same skeleton (fresh implementer per task plus independent review), but three differences drive token cost:

| Aspect            | superpowers SDD                            | loop-drive                                    |
|-------------------|--------------------------------------------|-----------------------------------------------|
| Review per task   | LLM reviewer subagent, plus fix subagents  | Native: LLM validator; ringer: an executed    |
|                   | and a whole-branch final review            | check script, zero model tokens to verify     |
| Model per agent   | Must be pinned; an omitted model inherits  | Sonnet default with explicit Opus promotion   |
|                   | the session model (often the priciest)     | criteria, effort capped at high               |
| Where tokens land | All on the Anthropic quota                 | Ringer waves run on GLM / OpenRouter engines  |

SDD remains fine for small same-session plans, with cheap models pinned in every dispatch.

## Repo layout

```
skills/loop-which/       Router skill: the One-Minute Test, verdict formats, worked examples
skills/loop-drive/       Compiler/driver skill: wave derivation, routing, hazards, gates, launch UX
config/ringer/           Engine config: claude-zai wrapper (GLM flat-rate) and config.toml
claude-md/fable.md       The managed CLAUDE.md block: Fable-specific footguns (effort cap, rerouting)
install.sh               The only thing that touches ~/.claude and ~/.config; idempotent, no secrets
principles.md            P1-P14 and C1-C8: every principle and critical-path choice, with provenance
conversation-archive.md  The design session, verbatim on Jeremy's side, condensed on Claude's
PLAN.md                  The implementation plan, amended with execution-day notes and renames
learning_guide.html      The session writeup: seven aha moments, reference tables, diagrams
diagrams/                PlantUML sources and renders (conversation evolution, routing flow, ringer)
```

## Install

### This repo (loop-stack)

```sh
./install.sh
```

Idempotent.
Symlinks the two skills (default style: repo -> `~/.agents/skills/<name>`, with `~/.claude/skills/<name>` linking there), copies ringer config into `~/.config/ringer/` if absent, and maintains exactly one managed block in `~/.claude/CLAUDE.md`.

**Gotcha: the symlinks embed this repo's absolute path.**
If you move this repo, every harness symlink breaks silently and the skills stop loading, with no error.
Re-run `./install.sh` after any move.

This is all you need for the native (Anthropic-only) substrate.
The ringer substrate additionally needs Ringer itself, below.

### Ringer (mixed-provider substrate)

Ringer lives at [github.com/NateBJones-Projects/ringer](https://github.com/NateBJones-Projects/ringer).
Full install instructions are the **Quickstart** section of `README.md` inside that repo, with per-engine setup (OpenCode/OpenRouter, Grok, sandboxing) further down in the same file.

High-level summary of its install:

```sh
# needs Python 3.11+; macOS or Linux (Windows via WSL)
git clone https://github.com/NateBJones-Projects/ringer && cd ringer

# 1. install and sign in to at least one worker CLI (Codex is the built-in default engine)
npm install -g @openai/codex && codex login

# 2. optional config (sane defaults without it)
mkdir -p ~/.config/ringer && cp config.sample.toml ~/.config/ringer/config.toml

# 3. recommended: install the ringer orchestrator skill + hooks into Claude Code
./ringer.py install-agent

# 4. verify end to end: 3 real parallel workers, executed checks, Ringside dashboard opens itself
./ringer.py demo
```

Notes for using it with loop-stack:

- This repo's `config/ringer/` ships a `claude-zai.sh` engine wrapper (GLM flat-rate via z.ai) and a `config.toml`; `./install.sh` copies them into `~/.config/ringer/` if absent, so run loop-stack's installer after (or instead of) step 2.
- `loop-drive` shells out to `./ringer.py` in the ringer checkout, so keep the clone somewhere stable (here: `~/repos/ringer`).
- `./ringer.py install-agent` is what registers the ringer skill and its once-per-session nudge hooks; uninstall with `./ringer.py uninstall-agent`.

## Naming and provenance

- `loop-which` was `one-minute-test`; `loop-drive` was `frontier-loop`; "Fable Sandwich" is "Frontier Sandwich" in package materials. `PLAN.md` keeps the old names as the historical record.
- The One-Minute Test framework and Ringer are Nate B. Jones's work. `frontier-loop` and `fable-sandwich` were Jeremy's pre-session skills. `principles.md` tags every principle as inherited, jeremy's, hybrid, or ours.
