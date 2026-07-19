# Model Routing Unification Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes. No specific tooling, harness, or skills are assumed.

**Goal:** one evidence-first model-choice procedure for every loop-drive unit, with substrate demoted to a per-unit derived transport attribute.
**Approach:** unified-chain rewrite (brief approach A): loop-drive Steps 0 and 2 are rewritten around the chain "integrity-gated scoreboard posterior, else benchmark prior, else orchestrator pin", transport is derived per unit, and each wave's ringer units pack into one manifest while native units launch alongside.
The surgical-amendment and shared-reference-file alternatives were declined in the brief; do not partially revive them.
**Tech stack:** markdown skill files, plain bash (install.sh), no new dependencies.
**Source brief:** `docs/briefs/2026-07-18-model-routing-unification-brief.md`.

## Open-question resolutions (from the brief, decided here)

1. Routing-table columns, in order: `Unit | Wave | task_type | Model | Transport | Engine | Impl. effort | Val. effort | Evidence`.
   task_type leads the model choice, transport replaces substrate, engine is the ringer engine name or `Agent tool`.
   The Evidence cell carries a short tag only - `posterior`, `prior`, or `pin:<reason-word>` - with any longer rationale in a footnote beneath the table, so the approval-gate table stays scannable at laptop width (rubix finding 8).
2. Step 0 ONE AGENT / single-wave exits apply the same chain to their single unit; no table, but the exit line must name model, transport, and evidence tier.
3. The doctor stays plain grep/test bash (no tomllib, no new dependencies), remains section 4 of install.sh, and stays never-fatal.
4. The PR framing note is a new standalone file `docs/PR-65-FRAMING.md` in the ringer repo (`~/repos/ringer`), so it travels with the repo the PR is authored from and cannot conflict with work-PC edits to existing files.
5. loop-which gets a one-sentence vocabulary alignment pointing at the unified evidence chain; its existing ground-truth-config paragraph and benchmark-file reference stay.
6. Benchmark prior file format: one markdown table using loop-which's tier vocabulary (Frontier / Strong / Fast / Specialty), one row per model, with a prior-semantics header (untested then probation then proven at 3+ scoreboard rows).
7. The benchmark file's canonical source lives in this repo at `config/fable-sandwich/model-benchmarks.md`; install.sh symlinks it into `~/.claude/skills/fable-sandwich/references/`, matching the repo's "source of truth here, installer produces the copies" doctrine without importing the whole fable-sandwich skill.

## Global constraints

- One sentence per line in all markdown; plain dashes, never the em dash character; aligned table pipes.
- The stm-nav lesson lines landed 2026-07-17/18 must survive every edit verbatim or strengthened, never weakened: verdict discipline, run-JSON-is-truth, FAIL attribution before relaunch, and the check-rules pointer to the ringer skill.
- loop-drive defers to the ringer skill's check-writing rules by pointer, never paraphrase.
- Fable is orchestrator-tier only and is never assigned as a worker, in any file this plan touches.
- No changes to `ringer.py`, to ringer's config schema, or to any file under `~/.config/`.
- install.sh stays plain bash, idempotent, never writes secrets, and its doctor section never exits non-zero.
- The Agent tool's worker model set is treated as the fixed enum sonnet, opus, haiku (fable exists in the enum but is never a worker); GLM and codex exist only as ringer engines.
- Skill-file edits land in this repo's working tree (the installed copies are symlinks into it); nothing edits `~/.claude/skills/` directly.

## Dependency graph

```
Wave 1 (parallel, disjoint files):
  Task 1  loop-drive SKILL.md rewrite
  Task 3  benchmark prior file
  Task 6  PR-65 framing note (ringer repo)

Wave 2 (parallel, disjoint files):
  Task 2  loop-drive references update ......... depends on Task 1
  Task 5  loop-which + managed-block touch-ups . depends on Task 1

Wave 3:
  Task 4  install.sh symlink + doctor growth ... depends on Task 3, Task 5
```

Task 4 depends on Task 5 through runtime, not files: its acceptance check runs install.sh, which regenerates the live managed CLAUDE.md block from `claude-md/fable.md`; running it before Task 5's edit would install the stale routing language (rubix finding 7).

Deviation from the brief's seams, recorded: brief seams 1-3 (Step 2, Step 0, consistency touches) collapse into Tasks 1-2 because Steps 0-7 share one file and exclusive ownership forbids parallel edits to it; brief seam 6 (managed block) folds into Task 5 with the loop-which touch-up because both are one-to-two-line edits under one reviewer gate.
Deviation from the brief's interim-integrity wording, recorded (rubix finding 1): the brief describes "applying the jq exclusion overlay" from AMENDMENTS-PENDING Section C, but that query yields model-level row counts, not a task-typed posterior, so it cannot be mechanically applied to `models --task-type` output; the chain instead states the operator action directly - treat glm-5.2's posterior as depressed on the four affected task_types and defer to prior or pin until amend lands.

## Human checkpoints

- After Task 1: review the rewritten SKILL.md prose before Wave 2 starts; skill-text taste is a judgment call the executor does not own (brief `[judgment]` criterion, part 1).
- After all tasks: in a fresh session, compile any sample plan with the rewritten loop-drive skill and confirm the routing table applies the chain without asking which substrate to use and without inventing a second rulebook (brief `[judgment]` criterion, part 2).
- Before running Task 4's acceptance check: confirm the executor may run `install.sh` on this machine (it rewrites the managed CLAUDE.md block and refreshes symlinks in `~/.claude/skills/`; idempotent by design).

## How to run

```bash
cd ~/repos/loop-stack-session
# non-interactive install (used by Task 4's acceptance check):
LOOP_STACK_SKILL_STYLE=agents bash install.sh
# commit per task:
git add <files> && git commit -m "<message>"
```

There is no test suite in this repo; acceptance checks are the grep/test commands embedded per task.

### Task 1: Rewrite loop-drive SKILL.md around the unified chain

Depends on: none

**Files (exclusive ownership):**
- Modify: `skills/loop-drive/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: the canonical vocabulary every other task aligns to - "evidence tier" (posterior / prior / pin), "transport" (ringer / Agent tool), the routing-table column set from resolution 1, and the pin criteria (design, math, risk, taste).
- Produces: the canonical chain sentence and transport rule quoted below; Tasks 2 and 5 must use these terms verbatim.

**Content contract.**

Frontmatter description: replace "Covers both Anthropic-only subagent swarms and mixed-provider ringer runs." with "Covers ringer-transported and Agent-tool-transported workers, mixed freely within a wave.".

Intro (lines "There are two execution substrates, chosen per wave" through the two substrate bullets): replace with transport framing.
The two references keep their roles: `references/ringer-substrate.md` documents the ringer transport, `references/native-orchestration.md` the Agent-tool transport.

Step 0 gains a "Capability probe" block (after the loop-which verdict routing, before the checkability gate) containing verbatim:

> Probe capabilities before routing: read the `[engines.*]` blocks of `~/.config/ringer/config.toml`.
> If ringer is present, its scoreboard is the evidence source of record; resolve and record the ringer repo root (the directory holding `ringer.py`, normally `~/repos/ringer`) here, once - Step 2's evidence chain and the gate receipts use that recorded root, never bare relative paths.
> If ringer is absent on this machine, every unit takes the Agent tool as degraded-mode transport, and the emitted plan says so in its pre-flight.

Step 0's single-artifact exits (ONE AGENT / single-wave TEAM) additionally require the exit to name the unit's model, transport, and evidence tier (resolution 2).
Step 0's "If two shapes or substrates are close" sentence changes to compare shapes only; substrate closeness is no longer a choice to diagram.

Step 2 replaces the entire "Route each unit by substrate:" block (the standing-default paragraph, the Native ladder paragraph, and the Ringer scoreboard paragraph) with the unified procedure, containing verbatim:

> Model choice is one chain for every unit, regardless of transport (P7: route by evidence, not vibes).
> If the Step 0 probe reported ringer absent, skip tier 1 entirely and route every unit by benchmark prior, else orchestrator pin, among the Agent-tool roster.
> 1. Integrity-gated scoreboard posterior: from the ringer repo root recorded by the Step 0 probe, run `./ringer.py models --task-type <type>`; before trusting a posterior, read `<ringer-repo>/docs/MODEL-NOTES.md` and `<ringer-repo>/docs/AMENDMENTS-PENDING.md` for the models under consideration; if the ringer repo is missing, treat the posterior as unverified and fall to the prior tier.
>    Known pending state while ringer #65 is unpatched: the seven excluded stm-nav rows are all glm-5.2 on site-build, docs, code-fix, and code-review - for those task_types treat glm-5.2's raw posterior as depressed by up to seven misattributed fails and defer to its benchmark prior or a pin; once amend lands, read the Amended column instead.
> 2. Else benchmark prior: a model with no trusted local evidence routes by its row in `model-benchmarks.md` (the fable-sandwich reference file).
> 3. Else orchestrator pin: design, math- or reasoning-heavy, risk concentration, or taste - pin `engine` and `model` and record the reason.
> A pin outranks the chain at any tier when its trigger holds; the reason is never "seems hard".
> Evidence cells carry the short tag only (`posterior`, `prior`, `pin:<reason-word>`); longer rationale goes in a footnote beneath the table.

And the transport rule, verbatim:

> Transport is derived per unit, never chosen per wave: a unit that needs in-session tools or mid-flight continuation takes the Agent tool; if ringer is absent, every unit takes the Agent tool (degraded mode); otherwise the unit takes ringer.
> Within a wave, all ringer-transport units pack into one manifest; Agent-tool units launch as parallel background calls; both meet at the same gate.

Step 2 must also contain, rehomed inside or after the chain (note: the first two exist only in the crashed session's diff record, never landed in this repo - they are ADDED here, verified absent 2026-07-19):

- The standing quota preference: execution typing leans to the flat-rate `claude-zai` lane when evidence ties or is thin; the preference lives in the managed CLAUDE.md block and is cited as a tie-break, not a tier.
- The taste flag: units with aesthetic acceptance criteria get flagged in the routing table and offered the per-unit engine ask despite any default (stm-nav lesson, 2026-07-17: the site map rode the default unflagged).
- The roster facts: Agent-tool workers are sonnet, opus, haiku; Fable is never a worker; GLM and codex run only via ringer.
- The task_type requirement for every unit, the effort rules, and the per-unit table requirement, with the table columns from resolution 1.
- Runtime escalation reworded transport-neutrally: a unit that fails validation twice is re-routed at the gate by the same chain, usually a pin to a stronger model with the reason recorded; it is not an automatic ladder.

Step 3: the two mode headings ("Ringer mode:" / "Native mode:") become "Ringer-transport units:" and "Agent-tool units:"; hazard content is unchanged; add one sentence that on a mixed wave both hazard sets are active at once.

Step 4: same heading treatment ("Native mode:" / "Ringer mode:" become per-transport); prompt/spec content and the stm-nav validator-discipline line unchanged.

Step 5 item 1: reword so a wave launches its packed manifest and its Agent-tool units concurrently; ringer's built-in retry stays the repair pass for ringer units, SendMessage stays the repair pass for Agent-tool units.
Step 5 item 2: unchanged except the opening becomes "Read all results and verdicts from both transports."
Step 5 item 3: the MODEL-NOTES sentence becomes mandatory for Agent-tool units, verbatim:

> Agent-tool units MUST leave dated MODEL-NOTES receipts at the gate - their only durable receipt, since only ringer runs feed the scoreboard.
> Batch them: one dated line per (model, task_type) per wave in `<ringer-repo>/docs/MODEL-NOTES.md`, plus a separate line only for signal events (a pin, a runtime re-route, a check-bug attribution, an off-nominal result); support them only with validator verdicts and diffs, and read them back through the same integrity discipline as any posterior.
> Committing the ringer-repo receipt is part of closing the gate: commit it before advancing the wave, so the git-is-truth reconciliation covers both repos.

Step 5's quota/resume paragraph adds one sentence: the reconciliation procedure also checks the ringer repo for an uncommitted MODEL-NOTES receipt owed by the last gate (the run drives two repos; both are checkpointed).

Step 6 item 2 becomes: "Routing table: the per-unit table with the columns Unit, Wave, task_type, Model, Transport, Engine, Impl. effort, Val. effort, Evidence."
Step 6 item 5 (pre-flight) adds: the capability-probe result (which engines were found, or degraded mode).
Step 7's dashboard line changes "unit, wave, engine/model, effort" to "unit, wave, model, transport, effort".

**Acceptance check:** `[executed-check]`

```bash
cd ~/repos/loop-stack-session/skills/loop-drive
! grep -q "keep the Sonnet-default / Opus-promotion ladder" SKILL.md \
&& ! grep -q "two execution substrates" SKILL.md \
&& grep -q "Integrity-gated scoreboard posterior" SKILL.md \
&& grep -q "Else benchmark prior" SKILL.md \
&& grep -q "Else orchestrator pin" SKILL.md \
&& grep -q "Transport is derived per unit, never chosen per wave" SKILL.md \
&& grep -q "MUST leave dated MODEL-NOTES receipts" SKILL.md \
&& grep -q "AMENDMENTS-PENDING" SKILL.md \
&& grep -q "overall verdict is fail" SKILL.md \
&& grep -q "run JSON is truth" SKILL.md \
&& grep -q "attribute before relaunching" SKILL.md \
&& grep -q "FULL check-writing ruleset" SKILL.md \
&& grep -q "rode the default unflagged" SKILL.md \
&& awk '/^## Step 2/,/^## Step 3/' SKILL.md | grep -q "Integrity-gated scoreboard posterior" \
&& ! grep -q "—" SKILL.md \
&& echo PASS
```

Expected: `PASS`.
The four per-lesson greps (verdict discipline, run-JSON-is-truth, FAIL attribution, check-rules pointer) each guard one stm-nav lesson independently, so deleting any one fails the gate; the taste-flag grep guards the line this rewrite adds; the awk range asserts the chain lives in Step 2, not merely somewhere in the file (rubix findings 4 and 10).

- [ ] Step 1: Run the acceptance check; expected FAIL (the chain sentences are absent today).
- [ ] Step 2: Apply the content contract above to `SKILL.md`, section by section in file order.
- [ ] Step 3: Run the acceptance check; expected PASS.
- [ ] Step 4: Reread the full file once for coherence: no orphaned references to "substrate" as a choice, no duplicated rules between Steps 0 and 2.
- [ ] Step 5: Commit: `git add skills/loop-drive/SKILL.md && git commit -m "loop-drive: unify model routing (evidence chain + derived transport)"`.

### Task 2: Update loop-drive reference files to the unified vocabulary

Depends on: Task 1

**Files (exclusive ownership):**
- Modify: `skills/loop-drive/references/example-output-plan.md`
- Modify: `skills/loop-drive/references/ringer-substrate.md`
- Modify: `skills/loop-drive/references/native-orchestration.md`

**Interfaces:**
- Consumes, from Task 1, verbatim (do not invent variants): the routing-table columns `Unit | Wave | task_type | Model | Transport | Engine | Impl. effort | Val. effort | Evidence`; the evidence tags `posterior`, `prior`, `pin:<reason-word>` (longer rationale goes in a footnote beneath the table); the transport values `ringer` and `Agent tool`.
- Produces: nothing later tasks consume.

**Content contract.**

`example-output-plan.md`:
- Section 2's table adopts the Task 1 column set exactly.
- The `parser` row: transport `Agent tool`, engine `Agent tool`, evidence cell `pin:continuation`, with a footnote beneath the table: "parser: pinned - the repair pass needs in-session continuation; model from benchmark prior (sonnet, Strong tier; no scoreboard rows for code-feature on Agent tool)".
- The `changelog-doc` row: transport `ringer`, engine `claude-zai`, evidence cell `posterior`, with the current citation (glm-5.2 first-try 1.00 on docs, 3 rows) moved to a footnote.
- Section 2's intro sentence changes from substrate language to: "Wave 1 mixes transports: unit `changelog-doc` rides ringer, unit `parser` rides the Agent tool.".
- Sections 3-9: replace remaining "substrate"/"native" labels with transport terms where they name the mechanism ("native / Sonnet" becomes "Agent tool / Sonnet"); mechanics content unchanged.
- Section 5 pre-flight adds the capability-probe line (engines found).

`ringer-substrate.md`:
- Title and intro reframe from "the substrate to use when..." to "the ringer transport: how the orchestrator drives a wave's packed manifest".
- The "Model assignment: prior then posterior (P7)" section is replaced by a pointer to Step 2's unified chain plus the two ringer-specific mechanics that stay here: the untested/probation/proven promotion ladder, now citing `model-benchmarks.md` (the fable-sandwich reference file) as the prior source by name, and the MODEL-NOTES post-run line.
- No duplicated chain text: this file points to Step 2, it does not restate the chain (pointer-not-paraphrase doctrine).

`native-orchestration.md`:
- Title and intro reframe as "the Agent-tool transport".
- Add one sentence to the intro: model choice for these units comes from Step 2's unified chain; this file covers transport mechanics only.
- Wave mechanics, isolation, session-alive, and headless sections unchanged.

**Acceptance check:** `[executed-check]`

```bash
cd ~/repos/loop-stack-session/skills/loop-drive/references
grep -q "| Transport |" example-output-plan.md \
&& grep -q "mixes transports" example-output-plan.md \
&& grep -q "pin:continuation" example-output-plan.md \
&& ! grep -qi "native default ladder" example-output-plan.md \
&& grep -q "model-benchmarks.md" ringer-substrate.md \
&& ! grep -q "prior then posterior" ringer-substrate.md \
&& grep -qi "unified chain" native-orchestration.md \
&& ! grep -q "—" example-output-plan.md ringer-substrate.md native-orchestration.md \
&& echo PASS
```

Expected: `PASS`.

- [ ] Step 1: Run the acceptance check; expected FAIL (old vocabulary present).
- [ ] Step 2: Apply the content contract to the three files.
- [ ] Step 3: Run the acceptance check; expected PASS.
- [ ] Step 4: Commit: `git add skills/loop-drive/references/ && git commit -m "loop-drive references: transport vocabulary + benchmark prior pointer"`.

### Task 3: Create the benchmark prior file

Depends on: none

**Files (exclusive ownership):**
- Create: `config/fable-sandwich/model-benchmarks.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: the file Task 4 symlinks and the prior tier the Step 2 chain cites; the installed path will be `~/.claude/skills/fable-sandwich/references/model-benchmarks.md` (the path loop-which already names).

**Content contract.**

Header: what the file is (the prior tier of the routing chain and loop-which's tier examples), the prior semantics (a model with no local scoreboard evidence routes by its row here; untested then probation then proven at 3+ scoreboard rows, per the ringer promotion ladder), and the maintenance rule (dated rows; update when a benchmark or a scoreboard graduation changes a tier).

One table with columns: `Model | Tier | Best for | Avoid for | Prior source (dated) | Notes`.

Required rows, with this substance (exact prose is the executor's):
- `fable`: Frontier; orchestration, arbitration, validation; never a worker; DeepSuite 2026: low effort $3.76/task at 60% pass beats Opus 4.8 max at $13/task 59%; effort capped at high.
- `opus-4.8`: Frontier; architecture-defining, math- or reasoning-heavy, risk-concentrated units; the usual pin target.
- `sonnet-5`: Strong; general execution on the Agent-tool transport.
- `haiku-4.5`: Fast; thin, mechanical, well-referenced units.
- `glm-5.2` (via ringer `claude-zai`, z.ai flat rate): Strong for execution typing at zero Anthropic quota; probe-validated 2026-07-17 (run `zai-engine-probe`); note that its scoreboard posterior is depressed pending the seven stm-nav amendments (ringer #65, `AMENDMENTS-PENDING.md`).
- `codex`: Specialty; only if the codex engine is wired; no local evidence yet.

**Acceptance check:** `[executed-check]`

```bash
cd ~/repos/loop-stack-session
f=config/fable-sandwich/model-benchmarks.md
test -f $f \
&& grep -q "| Tier |" $f \
&& grep -qi "fable" $f && grep -qi "opus" $f && grep -qi "sonnet" $f \
&& grep -qi "haiku" $f && grep -qi "glm-5.2" $f \
&& grep -qi "proven at 3+" $f \
&& grep -qi "never a worker" $f \
&& ! grep -q "—" $f \
&& echo PASS
```

Expected: `PASS`.

- [ ] Step 1: Run the acceptance check; expected FAIL (file absent).
- [ ] Step 2: Write the file per the content contract.
- [ ] Step 3: Run the acceptance check; expected PASS.
- [ ] Step 4: Commit: `git add config/fable-sandwich/ && git commit -m "Add model-benchmarks.md: the routing chain's prior tier"`.

### Task 4: install.sh - benchmark symlink and doctor growth

Depends on: Task 3, Task 5 (runtime coupling: the acceptance check runs install.sh, which regenerates the live managed CLAUDE.md block from `claude-md/fable.md`; Task 5's edit must land first)

**Files (exclusive ownership):**
- Modify: `install.sh`

**Interfaces:**
- Consumes: `config/fable-sandwich/model-benchmarks.md` from Task 3.
- Produces: the installed symlink at `~/.claude/skills/fable-sandwich/references/model-benchmarks.md`.

**Content contract.**

New section 2b, after the ringer-config copy loop: symlink the benchmark file so repo edits stay live, creating the parent only if fable-sandwich exists (never scaffold someone else's skill):

```bash
# 2b. fable-sandwich benchmark reference: symlink so repo edits stay live.
FS_REFS="$SKILLS_DIR/fable-sandwich/references"
if [ -d "$SKILLS_DIR/fable-sandwich" ]; then
  mkdir -p "$FS_REFS"
  ln -sfn "$REPO/config/fable-sandwich/model-benchmarks.md" "$FS_REFS/model-benchmarks.md"
  echo "symlinked $FS_REFS/model-benchmarks.md"
else
  echo "note: fable-sandwich skill not installed; skipping model-benchmarks.md symlink"
fi
```

Doctor section 4 gains four never-fatal checks, appended before the final done line:

```bash
if [ -f "$RINGER_DIR/config.toml" ] && grep -q '^\[engines\.' "$RINGER_DIR/config.toml"; then
  echo "found engines: $(grep -c '^\[engines\.' "$RINGER_DIR/config.toml") block(s) in config.toml"
else
  echo "WARNING: no [engines.*] blocks in $RINGER_DIR/config.toml - routing has no wired engines"
fi
[ -f "$RINGER_DIR/zai-token" ] \
  && echo "found zai-token" \
  || echo "WARNING: $RINGER_DIR/zai-token missing - the claude-zai flat-rate lane cannot authenticate"
[ -w "$HOME/.ringer" ] \
  && echo "found ~/.ringer (writable)" \
  || echo "note: ~/.ringer missing or unwritable - ringer creates it on first run; scoreboard evidence lands there"
[ -L "$SKILLS_DIR/fable-sandwich/references/model-benchmarks.md" ] \
  && echo "found model-benchmarks.md (prior tier wired)" \
  || echo "WARNING: model-benchmarks.md not linked - the routing chain's prior tier is a dangling pointer"
echo "hint: ./ringer.py demo verifies an engine end to end"
```

The exact code above IS the decision (shell quoting and never-fatal discipline are the risk); place verbatim, adjusting only surrounding blank lines.

**Acceptance check:** `[executed-check]` (human checkpoint 3 clears running this)

```bash
cd ~/repos/loop-stack-session
LOOP_STACK_SKILL_STYLE=agents bash install.sh > /tmp/install-out.txt 2>&1; ec=$?
test $ec -eq 0 \
&& grep -q "found engines:" /tmp/install-out.txt \
&& grep -qE "(found|WARNING).*zai-token" /tmp/install-out.txt \
&& grep -qE "\.ringer" /tmp/install-out.txt \
&& grep -qE "model-benchmarks\.md" /tmp/install-out.txt \
&& grep -q "ringer.py demo" /tmp/install-out.txt \
&& test -L ~/.claude/skills/fable-sandwich/references/model-benchmarks.md \
&& echo PASS
```

Expected: `PASS`, and the install output shows no regression of the existing sections (skills symlinked, managed block refreshed).

- [ ] Step 1: Run the acceptance check; expected FAIL (doctor lines absent, symlink absent).
- [ ] Step 2: Apply the two code blocks per the content contract.
- [ ] Step 3: `bash -n install.sh` exits 0 (syntax gate).
- [ ] Step 4: Run the acceptance check; expected PASS.
- [ ] Step 5: Commit: `git add install.sh && git commit -m "install.sh: benchmark symlink + routing doctor checks"`.

### Task 5: Alignment touch-ups - loop-which and the managed CLAUDE.md block

Depends on: Task 1

**Files (exclusive ownership):**
- Modify: `skills/loop-which/SKILL.md`
- Modify: `claude-md/fable.md`

**Interfaces:**
- Consumes: the chain vocabulary from Task 1 (evidence tiers: posterior, prior, pin; derived transport).
- Produces: nothing later tasks consume.

**Content contract.**

`skills/loop-which/SKILL.md`: after the existing ground-truth-config paragraph (the one naming `[engines.*]` blocks), add one sentence:

> Per-unit model choice downstream follows loop-drive Step 2's evidence chain (scoreboard posterior, else benchmark prior, else orchestrator pin); this skill only establishes what is available, never which model a unit gets.

`claude-md/fable.md`, Model routing section: replace the two existing bullets with three:

> - Model choice for execution units follows the evidence chain (integrity-gated scoreboard posterior, else benchmark prior, else orchestrator pin); substrate is derived per-unit transport, not a per-wave choice.
> - Execution typing leans to ringer's `claude-zai` engine (the z.ai flat-rate lane) when evidence ties or is thin; keep Anthropic quota for orchestration, review gates, and judgment.
> - Wired engines are ground truth in `~/.config/ringer/config.toml`; read it, don't assume.

**Acceptance check:** `[executed-check]`

```bash
cd ~/repos/loop-stack-session
grep -q "evidence chain" skills/loop-which/SKILL.md \
&& grep -q "never which model a unit gets" skills/loop-which/SKILL.md \
&& grep -q "evidence chain" claude-md/fable.md \
&& grep -q "derived per-unit transport" claude-md/fable.md \
&& grep -q "claude-zai" claude-md/fable.md \
&& ! grep -q "—" skills/loop-which/SKILL.md claude-md/fable.md \
&& echo PASS
```

Expected: `PASS`.

- [ ] Step 1: Run the acceptance check; expected FAIL.
- [ ] Step 2: Apply both edits.
- [ ] Step 3: Run the acceptance check; expected PASS.
- [ ] Step 4: Commit: `git add skills/loop-which/SKILL.md claude-md/fable.md && git commit -m "Align loop-which and managed block to the unified evidence chain"`.

### Task 6: PR-65 framing note in the ringer repo

Depends on: none

**Files (exclusive ownership):**
- Create: `~/repos/ringer/docs/PR-65-FRAMING.md` (note: the ringer repo, not this one)

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: the framing prose to lift into the upstream #65 PR description.

**Content contract.**

The note contains, in order:
- What this file is: the argument for upstream acceptance of issue #65 (amendment rows), written for the PR description.
- The reframing: loop-stack's routing now leans on the scoreboard as its single evidence source for every unit, so amendment rows stop being a nice-to-have correction tool and become the integrity layer of the entire routing system; a check bug is no longer one bad log line, it silently mis-routes every future unit of that task_type.
- The evidence: the stm-nav run (2026-07-17/18) recorded 8 FAILs of which 7 were orchestrator check bugs, not model failures; data and per-row rationale in `AMENDMENTS-PENDING.md`, design in `AMENDMENT-ROWS.md`.
- Nate's own pre-argument, quoted verbatim with attribution (2026-07-08 Substack ringer article, "The appeals process"): "When a check fails a worker, sometimes the check is wrong, so build in the post-mortem that can rule for the accused. Without one, your verification layer calcifies into bureaucracy people learn to game."
- One closing line: the patch is specced in `AMENDMENT-ROWS.md` and the seven pending amendments in `AMENDMENTS-PENDING.md` Section D are its first acceptance test.

**Acceptance check:** `[executed-check]`

```bash
f=~/repos/ringer/docs/PR-65-FRAMING.md
test -f $f \
&& grep -q "integrity layer" $f \
&& grep -q "rule for the accused" $f \
&& grep -q "AMENDMENT-ROWS.md" $f \
&& grep -q "AMENDMENTS-PENDING.md" $f \
&& ! grep -q "—" $f \
&& echo PASS
```

Expected: `PASS`.

- [ ] Step 1: Run the acceptance check; expected FAIL (file absent).
- [ ] Step 2: Write the file per the content contract.
- [ ] Step 3: Run the acceptance check; expected PASS.
- [ ] Step 4: Guard the foreign repo before committing: `git -C ~/repos/ringer status --porcelain` shows nothing but this new file, and `git -C ~/repos/ringer branch --show-current` is the default branch; anything else stops and surfaces to the human.
- [ ] Step 5: Commit in the ringer repo: `git -C ~/repos/ringer add docs/PR-65-FRAMING.md && git -C ~/repos/ringer commit -m "docs: PR framing for #65 - amendment rows as the routing integrity layer"`.

## Brief-criteria coverage map

| Brief success criterion                         | Covered by                                  |
|--------------------------------------------------|----------------------------------------------|
| Ladder-as-mechanism gone; chain present          | Task 1 acceptance check                      |
| Transport derived per unit; example shows mix    | Task 1 + Task 2 acceptance checks            |
| Benchmark prior file exists with required rows   | Task 3 + Task 4 acceptance checks (symlink)  |
| install.sh doctor lines, exit 0                  | Task 4 acceptance check                      |
| Integrity gate procedural in Step 2              | Task 1 acceptance check (AMENDMENTS-PENDING) |
| Native receipts mandatory (MUST)                 | Task 1 acceptance check                      |
| stm-nav lesson lines survive                     | Task 1 acceptance check (4 per-lesson greps) |
| PR framing note with Nate quote                  | Task 6 acceptance check                      |
| Fresh-session compile behaves (judgment)         | Human checkpoint 2                           |
