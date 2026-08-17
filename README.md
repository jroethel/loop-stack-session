# loop-stack

Agent loop engineering without `/workflows`: a brainstormer, a planner, a router, a compiler/driver, and a verified execution substrate for running agent-team loops in Anthropic-only or mixed-provider scope.

This repo is the product of a 2026-07-10 session between Jeremy and Claude Fable 5.
The trigger: `/workflows` was turned off after it burned too many tokens, raising the question of whether agent-team loops were still possible.
Nine exchanges later the session had converged on a three-layer architecture, adopted an off-the-shelf execution substrate ([Ringer](https://github.com/natebjones), by Nate B. Jones: 8,300 lines of zero-LLM stdlib Python), and produced the two skills this repo ships.
The full story is in `learning_guide.html` (the seven aha moments), `conversation-archive.md` (the verbatim design conversation), and `PLAN.md` (the build plan, with post-execution amendments).

## The architecture

Five layers, one brain.
The same Claude Code session that brainstorms and drafts the PRD also compiles it into waves, drives each wave, and reads the gates.
Ringer is muscle, not brain: it fans tasks out to cheap engine lanes and verifies each with an executed check command, but makes zero LLM judgment calls of its own.

```
/loop-brainstorm ──> One-Minute Test front door (the chain's first question)
                     ├─ CHAT ........... paste one prompt into a session
                     ├─ DON'T BOTHER ... manual checklist
                     └─ proceed ──> idea brief
                         └─ /loop-plan ──> executor-agnostic plan (+ optional rubix review)
                             └─ /loop-drive  (derives ONE AGENT vs AGENT TEAM, then compiles + drives)
                                 compiles: deps -> waves, steps -> specs + checks,
                                 assigns models per unit, then DRIVES execution
                                 ├─ native substrate: parallel Claude Code subagents
                                 └─ ringer substrate: manifests on GLM / OpenRouter engines
```

| Layer       | Skill / tool      | Job                                                                            |
|-------------|-------------------|--------------------------------------------------------------------------------|
| Brainstorm  | `loop-brainstorm` | Turn a raw idea into a loop-ready idea brief: outcome, checkable criteria,     |
|             |                   | seams, assumptions - no architecture                                            |
| Audit       | `loop-improve`    | Read-only audit front end: survey the repo and scan Issues and Backlog for     |
|             |                   | overlap; converge the findings the user selects into a brief for /loop-plan.   |
| Molt        | `loop-molt`       | Audit instruction prose against the live harness: classify each block, delete  |
|             |                   | plumbing, keep policy; emit a drift ledger line, brief structural findings.    |
| Plan        | `loop-plan`       | Turn a brief into an executor-agnostic task plan: depends-on graph, exclusive  |
|             |                   | file ownership, executed acceptance checks; optional rubix fresh-eyes review    |
| Compiler    | `loop-drive`      | Turn a plan or flat PRD into waves, specs, checks, and model routing; drive it |
| Executor    | Ringer            | Zero-LLM swarm runner: isolation, executed checks, one retry, scoreboard       |

Key design points, argued in full in the learning guide:

- **No `/workflows` needed.** Parallel background Agent calls, completion notifications, and SendMessage reproduce `pipeline()` semantics natively. The one loss is a detached durable pipeline, so the loop's interruption-and-resume design is load-bearing.
- **Checkability is the routing gate.** Work enters the swarm only when checking the output is cheaper than producing it. Taste-only work stays in the orchestrator's own judgment lane.
- **Evidence over vibes.** Ringer-mode model routing comes from the local scoreboard posterior, falling back to benchmark priors, never from "seems hard".
- **Executed checks beat LLM reviewers.** Exit 0 is the only PASS. A check script costs zero model tokens; a per-task LLM reviewer does not.

## The human-paced mode

The human-paced run-book (you opening sessions and pasting model-routed prompts step by step) is now `loop-drive`'s human-paced output mode, not a separate skill.
This molt cycle folded the former `frontier-sandwich` skill into loop-drive, realizing the repo's own conclusion that the sandwich and loop-drive were "two halves of one compile step".
For an autonomous loop, hand the plan or PRD straight to `/loop-drive`; it derives the wave structure itself, even from a flat PRD, and re-derives model assignments rather than copying hints.

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
skills/loop-brainstorm/  Brainstorm skill: idea to loop-ready brief (checkable criteria, seams, parking lot)
skills/loop-improve/     Audit skill: read-only repo survey, converge selected findings into a brief for /loop-plan
skills/loop-molt/        Molt skill: audit instruction prose against the live harness (protocol reference + drift ledger)
skills/loop-plan/        Plan skill: brief to executor-agnostic task plan, with the optional rubix review
skills/loop-drive/       Compiler/driver skill: wave derivation, routing, hazards, gates, launch UX, human-paced mode
config/ringer/           Engine config: claude-zai wrapper (GLM flat-rate) and the config templates
config/ringer/config.toml.template  Ringer engine config; rendered per host into ~/.config/ringer/config.toml
config/host.env.template            Per-host parameters; first install copies it to gitignored config/host.env
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
Symlinks every skill under `skills/` (default style: repo -> `~/.agents/skills/<name>`, with `~/.claude/skills/<name>` linking there), renders ringer config from `config/ringer/config.toml.template` into `~/.config/ringer/config.toml` only when absent (a live config is never clobbered), and maintains exactly one managed block in `~/.claude/CLAUDE.md`.

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

- This repo's `config/ringer/` ships a `claude-zai.sh` engine wrapper (GLM flat-rate via z.ai) and the `config.toml.template` the installer renders; `./install.sh` installs the wrapper and renders `~/.config/ringer/config.toml` only when absent, so run loop-stack's installer after (or instead of) step 2.
- `loop-drive` shells out to `./ringer.py` in the ringer checkout, whose location is the parameter home's `LOOP_STACK_RINGER_ROOT` (default `~/repos/ringer`); set it in `config/host.env` if the clone lives elsewhere.
- `./ringer.py install-agent` is what registers the ringer skill and its once-per-session nudge hooks; uninstall with `./ringer.py uninstall-agent`.

## Multi-host

Git push/pull is the supported reconciliation mechanism between the owner's hosts: each host installs via `git pull && ./install.sh && tests/run.sh`.
Each host's specific values (ringer checkout path, version pin, skill style) live only in `config/host.env`, which is gitignored and created from `config/host.env.template` on first install; environment variables override the file.
On a first run on a new host, `./install.sh` creates `config/host.env`; set `LOOP_STACK_SKILL_STYLE` there (or pass it on the command line) and re-run.
A non-interactive first run with the style undeclared refuses by design rather than silently defaulting.
Stale-config recovery: editing `config/host.env` does not re-render an existing `~/.config/ringer/config.toml`, so if the installer's doctor WARNS that config.toml engine bins do not exist, delete that file and re-run to re-render it for this host.
Scoreboard posteriors stay host-local by design: routing numbers are not portable between hosts, git syncs the repo but never the evidence ledger, and each host re-earns its posteriors.
This section supersedes backlog #16 ("multi-host support"); that item closes when this work ships.

## Naming and provenance

- `loop-which` was `one-minute-test`; `loop-drive` was `frontier-loop`; "Fable Sandwich" is "Frontier Sandwich" in package materials. `PLAN.md` keeps the old names as the historical record.
- The One-Minute Test framework and Ringer are Nate B. Jones's work. `frontier-loop` and `fable-sandwich` were Jeremy's pre-session skills. `principles.md` tags every principle as inherited, jeremy's, hybrid, or ours.
