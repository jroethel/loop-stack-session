# Full Implementation Plan: The Loop Stack

Status: APPROVED by Jeremy 2026-07-11; all previously open decisions resolved (section 4).
Execution starts with the kickoff prompt in section 6.
Supersedes and expands `~/.claude/plans/i-turned-workflows-off-cosmic-quill.md`.
Companion documents: `principles.md` (P/C references), `conversation-archive.md` (how we got here).

## 1. Context and intent

/workflows is off (token cost).
Goal: run agent loops in two scopes with one coherent architecture:

- **Anthropic-only**: native Claude Code subagents (Fable/Opus/Sonnet/Haiku on the existing plan).
- **Mixed-provider**: Anthropic orchestrates; workers on GLM via z.ai's flat-rate coding plan (through the claude CLI), very cheap models via OpenRouter (through OpenCode), and optionally Codex/Grok flat plans.

The architecture that converged (see archive Exchange 8), labeled with the skill/command at each step.
(Amended 2026-07-11 post-execution: skills renamed one-minute-test -> loop-which and frontier-loop -> loop-drive; "Fable Sandwich" is now "Frontier Sandwich" in package materials. WI text below keeps the old names as the historical execution record.)

```
PRD
 └─ skill: loop-which .................. user invokes it (or skips ahead: loop-drive Step 0 runs/references it)
     ├─ CHAT / DON'T BOTHER ............ no further skill; answer in-session or drop it
     └─ ONE AGENT / TEAM ............... skill: loop-drive
         ├─ Step 0: one agent or single-wave team (no wave ceremony)
         │    ├─ native substrate ...... one Agent-tool brief, launched in-session
         │    └─ mixed substrate ....... one ringer manifest -> ./ringer.py lint && ./ringer.py run
         └─ Steps 1-6: multi-wave team . emits the plan; the same session then drives it, per wave/unit:
              ├─ checkable, native ..... parallel background Agent calls + validator subagents
              ├─ checkable, mixed ...... manifest task -> ./ringer.py lint && ./ringer.py run
              └─ not checkable ......... orchestrator judgment lane (the session itself; never dispatched)
```

The handoff model is deliberate: each skill's output names the next command, and the user (or the session acting as orchestrator) invokes it.
loop-which's verdict tells you whether loop-drive is warranted; loop-drive's emitted plan tells you the exact ringer/Agent invocations per wave.
Three skills, three layers: loop-which (router), loop-drive (compiler/driver), ringer (executor, off the shelf).

### Repo layout and install model (added 2026-07-11)

All authored artifacts live in THIS repo; nothing edits `~/.claude/` or `~/.config/` directly except via `install.sh`.
This is the Open Skills "work package" pattern: the repo is the portable source of truth, the installer produces the tool-specific copies.

```
loop-stack-session/
  PLAN.md
  install.sh                      # the only thing that touches the home dir
  skills/loop-drive/              # (was frontier-loop) SKILL.md + references/, seeded by COPYING the current ~/.claude/skills/frontier-loop
  skills/loop-which/              # (added post-execution) the one-minute-test skill, renamed
  config/ringer/                  # claude-zai.sh + end-state snapshot of the working config.toml (no secrets, ever)
  claude-md/fable.md              # the ~10 fable-orchestration lines (WI-5)
```

`install.sh` behavior:

- Back up `~/.claude/skills/frontier-loop` once (to `~/.claude/frontier-loop.bak` - OUTSIDE `skills/`, since Claude Code loads every `skills/` subdir as a live skill; amended 2026-07-11 during execution), then symlink `skills/frontier-loop` into `~/.claude/skills/` (symlink, so repo edits are live).
- Copy `config/ringer/*` into `~/.config/ringer/` only if absent (never overwrite an existing config.toml, which is the live working copy); `chmod +x` the wrapper.
- Append/refresh a clearly marked `# --- loop-stack (managed) ---` block in `~/.claude/CLAUDE.md` containing `claude-md/fable.md`; idempotent (re-running replaces the block, never duplicates it).
- Never write secrets; `~/.config/ringer/zai-token` is created manually per the kickoff prompt.

## 2. Work items

### WI-1: Revise frontier-loop `SKILL.md` (in `skills/frontier-loop/`)

First copy the current `~/.claude/skills/frontier-loop/` into `skills/frontier-loop/` in this repo; all edits happen on the repo copy.
The skill becomes the wave compiler and driver for BOTH substrates.
Specific edits:

**(a) Description/frontmatter.**
Broaden the trigger: input is any plan/PRD or handoff run-book, not only a "Fable Sandwich" document.
Keep triggering conditions only; no workflow summary in the description (SDO rule).

**(b) New Step 0: route and scope.**
Run or reference the one-minute-test verdict.
CHAT or DON'T BOTHER: stop, say so.
ONE AGENT or single-wave TEAM: skip to emitting one ringer manifest directly (or one subagent brief in Anthropic-only scope); no wave ceremony.
Only multi-wave dependent builds proceed through Steps 1-6.
State the checkability gate explicitly: units whose output cannot be checked cheaper than produced never route to workers; they stay in the orchestrator's judgment lane (P6).
Every Step 0 exit names the concrete next command (e.g. "run `./ringer.py lint <manifest> && ./ringer.py run <manifest>`" or "launch this Agent-tool brief"), so the user never has to guess which skill or command comes next.

**(c) Step 1 (extract skeleton): two edits.**
Replace the external dshon reference with `references/example-output-plan.md`.
Add: derive the dependency graph even when the source plan is a flat PRD (the compiler owns wave derivation now).

**(d) Step 2 (roles/models/effort): substrate-aware routing.**
Anthropic-only: keep the existing Sonnet-default/Opus-promotion ladder.
Mixed-provider: model per unit comes from `./ringer.py models --task-type <type>` (posterior) with the benchmark file as prior for untested models; record which evidence drove each row (P7).
Give every unit a `task_type` from ringer's canonical vocabulary.

**(e) Step 3 (hazards): mark substrate coverage.**
In ringer mode, worktree isolation, per-task dirs, and log separation are handled by run-level `worktrees: true`; the plan must instead carry ringer's OWN footguns: deliverables die with passing worktrees (patch-export pattern), gitignored outputs need explicit copies, stagger opencode spawns (sqlite locking).
Native mode keeps the current Step 3 text (including the nested-repo worktree caveat).

**(f) Step 4 (prompt templates): per substrate.**
Native mode: subagent prompts as currently specified.
Ringer mode: emit manifest tasks instead; spec-writing rules per ringer's skill (self-contained, ownership lists, embedded how-to-run, output contract, no pointer specs); check-writing rules (print why they fail, verify substance, strict on substance / tolerant on format) (P14).
Both modes: validator/review stance gains "judge the raw evidence; ignore the implementer's narrative" (P2).

**(g) Step 5 (wave loop): rewrite item 1, keep gate structure.**
Native mode: launch the wave's implementers as parallel background Agent calls; on each completion notification launch that unit's validator; on failed validation one repair pass via SendMessage to the same implementer; second failure stops the unit without blocking siblings.
Ringer mode: one manifest per wave, same `run_name` across waves; `lint` then `run`; ringer's built-in retry IS the repair pass; gate consumes the run JSON and raw logs per ringer's post-run ritual.
Gate checklist addition (both modes): distill repeated failure patterns from verdicts into the spec artifact and templates before the next wave (P10); update MODEL-NOTES when a run taught something about a model.
Keep: green-integration-branch-to-advance, ask-the-human list, slip rules.

**(h) Step 6 (emit plan): add substrate declaration and routing table.**
The emitted plan opens with which substrate each wave uses and the per-unit routing table (unit, wave, substrate, engine/model or subagent model, effort, task_type, evidence for the choice).

### WI-2: Create `skills/frontier-loop/references/` (3 files)

**`native-orchestration.md`** - Agent-tool wave mechanics: parallel background launches, completion-notification handling, SendMessage repair pass, native `isolation: worktree` vs manual `git -C` worktrees for nested repos, Task-tool bookkeeping, session-must-stay-alive constraint, pointer to the Managed Agents API for headless/scheduled loops.

**`ringer-substrate.md`** - tier mapping (orchestrator = the session, implementer = manifest task, validation = executed check + optional review task); manifest conventions per unit; worktrees + patch-export as the isolation mitigation; wave gate = post-run review ritual; scoreboard-driven model assignment with the prior/posterior rule; the W-scaling guidance (fewer, fatter waves; gate bandwidth is the constraint, P13).

**`example-output-plan.md`** - self-contained skeleton of the emitted plan (all nine Step 6 sections) with a two-unit toy example, one unit per substrate.

### WI-3: Install what already exists

- `cd ~/repos/ringer && ./ringer.py install-agent` (installs the ringer skill user-level + two non-blocking nudge hooks).
- fable-orchestration: OPEN DECISION (see section 4).

### WI-4: Ringer engine config for the provider mix

Worked on LIVE in `~/.config/ringer/config.toml` (Jeremy, 2026-07-11: ringer installs itself where it needs to go, and its config is edited where it lands).
Once all engine probes pass, snapshot the working config.toml into `config/ringer/config.toml` so the package carries the delta (it holds no secrets - the z.ai token lives in a separate 0600 file; diff vs config.sample.toml is derivable if a patch view is ever wanted).

**(a) Enable `[engines.opencode]`** with `bin` set to the absolute path of `~/repos/ringer/engines/opencode-sandboxed.sh`; `model_default = "openrouter/z-ai/glm-5.2"`; requires OpenCode CLI installed and `opencode auth login` with an OpenRouter key.
This is the very-cheap OpenRouter lane; any model via per-task `"model": "openrouter/<slug>"`.

**(b) New `[engines.claude-zai]`** - the GLM flat-rate lane.
New wrapper script authored at `config/ringer/claude-zai.sh`, installed to `~/.config/ringer/claude-zai.sh` (Jeremy's pick: keeps the ringer clone pristine and survives repo updates):

```bash
#!/bin/bash
# claude CLI pointed at z.ai's Anthropic-compatible endpoint (GLM coding plan).
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export ANTHROPIC_AUTH_TOKEN="$(cat ~/.config/ringer/zai-token)"   # 0600 perms
exec claude "$@"
```

Note: ringer itself is not yet installed/configured on this machine; `~/.config/ringer/` gets created in step 1 of the execution order, before this wrapper lands in it.

Engine block sketch (final args to be verified against `claude --help` and ringer's spawn code):

```toml
[engines.claude-zai]
bin = "/absolute/path/to/claude-zai.sh"
model_default = "glm-5.2"
args_template = ["-p", "{spec}", "--model", "{model}", "{access_args}", "{engine_args}"]
sandbox_args = []           # verify: claude CLI sandbox/permission flags for headless writes to {taskdir}
full_access_args = ["--dangerously-skip-permissions"]
token_regex = "..."         # verify against claude -p output format
```

Implementation checks required before trusting it: how ringer applies `{taskdir}` as cwd for engines without a `-C` flag; that all four baked-in invariants hold (stdin closed, explicit sandbox, executed check, raw logs); that z.ai's endpoint accepts the headless flags.

**(c) `[engines.claude]`** - Anthropic-native worker lane, IN SCOPE per Jeremy's decision (2026-07-11).
Rationale: ringer cannot deploy a haiku (or sonnet) worker any other way - engines are its only worker mechanism, and none of the shipped engines speak to Anthropic.
No wrapper needed: `bin = "claude"` directly (normal subscription auth), per-task `"model": "haiku"` or `"sonnet"`, same `-p` headless args as claude-zai minus the env exports.
Division of labor stays: native subagents for in-session Anthropic work (context sharing, SendMessage); this lane for Anthropic workers that need executed checks and scoreboard rows alongside the other engines (e.g. haiku on mechanical manifest lanes, or in a bakeoff).

### WI-5: fable-orchestration - FOLD (decided 2026-07-11)

Write its ~10 unique lines to `claude-md/fable.md` in this repo; `install.sh` appends them to `~/.claude/CLAUDE.md` as the managed block; do not install the skill.
The lines: never ask Fable to show/echo reasoning in responses (silent reroute to Opus); cap effort at high (xhigh/max make Fable over-reason); don't predefine subagent archetypes; don't send research/boilerplate to Fable.
Put them under a short "Fable-specific" heading so they're easy to prune when they become obsolete.

### WI-6: `install.sh` (added 2026-07-11 per Jeremy)

The installer described in section 1 (Repo layout and install model).
Plain bash, idempotent, no dependencies.
Verify: run it twice on a scratch `$HOME` (`HOME=$(mktemp -d) ./install.sh` with pre-seeded fake `~/.claude/skills/frontier-loop` and `~/.claude/CLAUDE.md`); confirm symlink, backup, config copy-if-absent, and exactly one managed block after the second run.

## 3. Execution order

1. Scaffold the repo layout (section 1): copy the current frontier-loop skill into `skills/`, author `config/ringer/claude-zai.sh`, stub `claude-md/fable.md`.
2. WI-3 ringer install + `~/.config/ringer/` setup (unblocks everything; verify with `./ringer.py demo`).
3. WI-4c claude engine (simplest lane, no wrapper; proves the claude-CLI engine pattern before the z.ai variant; verify with a one-task haiku probe).
4. WI-4b claude-zai engine + wrapper (verify with a one-task probe).
5. WI-4a opencode engine (requires OpenCode CLI install + OpenRouter key; verify with a one-task probe).
6. WI-1 + WI-2 skill revision and references, in the repo copy (RED baseline first, then edit, then GREEN).
7. WI-5 write `claude-md/fable.md`.
8. WI-6 `install.sh`; run it for real (this is when the revised skill and fable lines actually land in `~/.claude/`); snapshot the working `~/.config/ringer/config.toml` into `config/ringer/`.
9. End-to-end dry run (section 5, item 4).

## 4. Decisions (resolved by Jeremy, 2026-07-11)

1. fable-orchestration: **FOLD** its ~10 unique lines into `~/.claude/CLAUDE.md`; no skill install.
2. claude-zai wrapper lives in **`~/.config/ringer/`** (created during install; ringer was not yet installed at decision time).
3. `[engines.claude]` Anthropic lane: **ADD NOW** - Jeremy needs haiku workers, and ringer has no claude -p lane without it.
4. Plugin/skill-pack packaging: **DEFER** until the revised skill has survived one real project.
   Amended 2026-07-11: a plain `install.sh` (WI-6) is IN scope now; full plugin packaging remains deferred.
5. Repo-as-source-of-truth (section 1 layout): **ADOPTED 2026-07-11** per Jeremy; also aligns with Nate Jones's Open Skills work-package model (portable source, installer produces tool-specific copies).

## 5. Verification

1. **Engines:** per new engine, `./ringer.py lint` then `run` a one-task probe manifest whose check MUST be able to fail (e.g. demand an exact string the spec asks the worker to compute); confirm PASS verdict, raw log, token count, and a scoreboard row via `./ringer.py models`.
2. **Skill revision (RED-GREEN per writing-skills):** baseline a fresh subagent on a sample handoff plan with the CURRENT skill and confirm the emitted plan references `pipeline()` (the failure); re-run with the revised skill in both scopes, pointing the subagent at the REPO copy (`skills/frontier-loop/SKILL.md`) since install happens later in the order; the Anthropic-only output must use Agent-tool mechanics with zero /workflows references; the mixed output must emit a lint-clean ringer manifest per wave with task_types and evidence-based model rows.
3. **Routing check:** hand the revised skill a trivially small PRD and confirm it exits early (Step 0) to a single manifest instead of producing wave ceremony.
4. **End-to-end:** one real two-wave micro-project (e.g. wave 1: two doc tasks on claude-zai + opencode; wave 2: one dependent task) driven start to finish; confirm Ringside shows one job across rounds, the gate ritual runs, and `./ringer.py demo` still passes afterward.

## 6. Kickoff prompt

Paste this into a fresh Claude Code session to start execution:

```
Read ~/loops/loop-stack-session/PLAN.md and execute it in the order given in section 3.
The plan is approved and all decisions are resolved in section 4 - don't re-ask them.
All authored files live in this repo per the layout in section 1; only install.sh touches ~/.claude/ and ~/.config/ (exceptions: ringer installs itself, and ~/.config/ringer/config.toml is edited live, then snapshotted into the repo at the end).
Highlights: scaffold the repo layout; install ringer's agent skill and set up ~/.config/ringer/; add three engines (claude for haiku/sonnet workers, claude-zai for GLM flat-rate, opencode for OpenRouter), each verified with a one-task probe whose check can actually fail; then revise the frontier-loop skill per WI-1/WI-2 (on the repo copy) with the RED-GREEN discipline from superpowers:writing-skills; then write claude-md/fable.md, build install.sh per WI-6, verify it on a scratch HOME, and run it for real; finish with the two-wave end-to-end dry run from section 5.
The z.ai key already exists at ~/.config/ringer/zai-token (0600) - don't ask for it; the endpoint is https://api.z.ai/api/anthropic as in the wrapper.
The OpenCode CLI and OpenRouter key may not be set up yet; if missing, tell me the exact commands to run rather than skipping the engine.
Stop and check with me before: anything the plan marks verify-first (WI-4's implementation checks), and before starting the end-to-end dry run.
```

## 7. Out of scope (deliberately)

- A standing-loop/cron skill (Jason Zhou contract/trigger material): different shape, revisit when a recurring monitor is wanted.
- Rewriting any part of ringer itself.
- Managed Agents API integration (headless equivalent; pointer only).
- Plugin packaging (decision 4 above).
