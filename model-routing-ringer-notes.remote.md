jjrdar@RIT-UADV2223:~/.claude/projects/-mnt-c-python-claude-forge/memory$ tail -n +1 model-delegation-preference.md ringer-check-craft.md loop-stack-lesson-routing.md session-skill-diffs.md
==> model-delegation-preference.md <==
---
name: model-delegation-preference
description: "Jeremy reserves Fable for design/judgment; execution typing goes to Ringer's claude-zai lane (GLM-5.2 on z.ai flat-rate plan) to save Anthropic API; Sonnet/Opus only when Anthropic-side workers are needed"
metadata:
  node_type: memory
  type: feedback
  originSessionId: d477bc27-1cb1-4593-8857-e13aeb84b520
---

On the Forge Studio design work (2026-07-12), Jeremy asked that Fable focus exclusively on design and orchestrate subagents for coding and research tasks (then: Sonnet 4.6 High mechanical, Opus 4.8 complex).

Updated 2026-07-17: for plan execution he prefers Ringer's `claude-zai` engine (claude CLI pointed at z.ai's Anthropic-compatible endpoint, GLM coding plan, model glm-5.2) over Sonnet subagents, explicitly to save Anthropic API/quota.
The lane was probe-validated on the WSL machine (run `zai-engine-probe`, first-try pass); the ringer config at `~/.config/ringer/config.toml` had Mac `/Users/` bin paths from migration, fixed to `/home/` on 2026-07-17.

**Why:** he orchestrates model tiers under chronic quota pressure; flat-rate GLM typing keeps Anthropic tokens for orchestration, review gates, and judgment.

**How to apply:** for multi-task execution (loop-drive runs, fix swarms, mechanical passes), route workers through Ringer with `"engine": "claude-zai"`; keep Fable as orchestrator/validator.
The claude-zai lane has no OS sandbox - isolation is disjoint ownership + executed checks, so serialize tasks sharing files.
Note: the Agent tool only exposes sonnet (Sonnet 5), opus, haiku, fable - Sonnet 4.6 is not selectable; tell him when substituting.

==> ringer-check-craft.md <==
---
name: ringer-check-craft
description: "Check-writing lessons distilled from the stm-nav loop's false FAILs (2026-07-17); rules now baked into the ringer skill's check-writing section"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 96f18ab4-2ac8-487e-8362-e021374720e8
---

During the stm-nav-restructure loop (2026-07-17), every recorded failure but one was the orchestrator's eval, not GLM-5.2: an unsatisfiable repo-wide negative grep (check demanded a state the spec forbade), a negative phrase-grep matching the requested link-out stub, an over-strict determinism check missing the plan's timestamp exception, and a validator first-attempt writing pass against its own contradicting notes.

**Why:** the check is the product; a bad check burns retries, pollutes the per-model scoreboard (no amendment mechanism - see ringer issue #65 and [[model-delegation-preference]]), and punishes correct workers.

**How to apply:** four rules now live in the ringer skill's check-writing section (grep "stm-nav lesson" in ~/.claude/skills/ringer/SKILL.md): checks must be satisfiable under the spec's boundary; negative assertions only over owned files and structure not prose; invariants carry their exceptions; validator specs state "any criterion fails = verdict fail". Gate from the run JSON, not the shell exit code, for detached runs.

==> loop-stack-lesson-routing.md <==
---
name: loop-stack-lesson-routing
description: "Where loop-stack lessons get filed (manifest craft vs loop craft) and the skill-file topology: loop-drive/loop-which live in repos/loop-stack-session via symlinks; ringer skill's canonical copy is in repos/ringer (.claude/skills/ringer), installed copy gets overwritten"
metadata:
  node_type: memory
  type: project
  originSessionId: 96f18ab4-2ac8-487e-8362-e021374720e8
---

Division of labor for distilled lessons (established 2026-07-17 with Jeremy):
**manifest craft** (spec boundaries, check-writing rules) files into the ringer skill - it applies to every manifest (probes, swarms, bakeoffs), not just loops;
**loop craft** (three-tier validator structure, verdict discipline, gates, FAIL attribution) files into loop-drive - it must reach native Anthropic-subagent loops that never load ringer.
loop-drive DEFERS to ringer's check rules by pointer, never paraphrases (paraphrases drift).

File topology (verify before editing - symlinks and installs):
- `~/.claude/skills/loop-drive` and `loop-which` are symlinks -> `~/.agents/skills/...` -> git repo `~/repos/loop-stack-session/skills/...`; edits land as working-tree mods there, Jeremy pulls upstream into it.
- `~/.claude/skills/ringer/` is a plain dir INSTALLED by `ringer.py install-agent`; the canonical source is `~/repos/ringer/.claude/skills/ringer/SKILL.md` - edit BOTH or the installed copy's changes die on the next install (mirrored 2026-07-17).
- Upstream loop-stack added a `loop-plan` skill (commit 01993a1, unpulled 2026-07-17) - future loop lessons may also belong there; check after Jeremy pulls.

Related: [[ringer-check-craft]], [[model-delegation-preference]].

==> session-skill-diffs.md <==
# Claude session updated SKILL.md file. I then pulled from repo and diff'd.
diff --git a/skills/loop-drive/SKILL.md b/skills/loop-drive/SKILL.md
index 24a97f7..2af1f8f 100644
--- a/skills/loop-drive/SKILL.md
+++ b/skills/loop-drive/SKILL.md
@@ -61,6 +61,10 @@ The loop is a three-tier structure regardless of substrate:

 Route each unit by substrate:

+Standing default (Jeremy, 2026-07-17): execution typing routes to the ringer `claude-zai` engine (GLM-5.2 on the z.ai flat-rate coding plan - zero Anthropic API, probe-validated on this machine via run `zai-engine-probe`) unless a unit genuinely needs Anthropic-side capability or in-session context sharing.
+Which engines are wired is ground truth in `[engines.*]` blocks of `~/.config/ringer/config.toml`; read it, do not assume.
+A standing default covers typing, not taste: any unit whose acceptance criteria are aesthetic (a showcase page, a visual system, anything the human will judge by look) gets flagged in the routing table and offered the per-unit engine ask despite the default - the human may want a design-stronger model or the orchestrator's own design pass there (stm-nav lesson, 2026-07-17: the site map rode the default unflagged).
+
 **Native (Anthropic-only):** keep the Sonnet-default / Opus-promotion ladder.
 Promote an implementer to Opus only when the unit is architecture-defining (others plug into its interfaces), math- or reasoning-heavy, or a known risk concentration (touches live consumers, deletes legacy, is the integration point).
 Expect a quarter to a third of units on Opus; if you flag more than half, your criteria are too loose.
@@ -116,11 +120,12 @@ What you MUST carry into the plan are ringer's own footguns:
 - **Ownership list.** Name every file the worker may create or edit, especially in multi-worker runs over one repo.
 - **Embedded how-to-run.** State exactly how to build/test so the worker and the check agree.
 - **Output contract.** State the exact deliverable files (and set `expect_files`).
-- **Check-writing rules (P14: checks are as important as specs).** The check prints WHY it fails (a silent exit 1 starves the retry prompt and the eval log). It verifies substance, not just presence. Be strict on substance, tolerant on format.
+- **Check-writing rules (P14: checks are as important as specs).** The check prints WHY it fails (a silent exit 1 starves the retry prompt and the eval log). It verifies substance, not just presence. The FULL check-writing ruleset lives in the ringer skill's "Check-writing rules" section - read it before writing any check; do not work from this summary (it summarizes, ringer governs, and the stm-nav 2026-07-17 false FAILs all came from checks that would have passed this summary but broke ringer's rules: unsatisfiable under the spec's boundary, repo-wide negative greps, invariants missing their exceptions).

 **Both modes:** the validator/review stance is adversarial and evidence-first (P2: worker self-reports are worthless).
 Judge the raw evidence (the diff, the executed check output, the artifact), and ignore the implementer's own narrative of what it did.
 Native validators also get: mandatory independent test rerun, criterion-by-criterion walk with evidence, scope-boundary diff audit, read-only, and a `{verdict: pass|fail|spec-problem, criteria: [...], notes}` contract (spec-problem routes spec bugs to the orchestrator instead of a futile fix loop).
+Every validator prompt (both substrates) states verdict discipline explicitly: if ANY criterion fails, the overall verdict is fail - without this line, first attempts write pass while their own notes contradict it (stm-nav lesson, 2026-07-17).

 ## Step 5 - Write the wave loop and gates

@@ -134,6 +139,8 @@ The output plan's core procedure, per wave, depends on substrate for item 1 and
 **2. Gate (orchestrator).**
 Read all results and verdicts.
 Ringer: consume the run JSON in `~/.ringer/runs/` and the raw worker logs in `<workdir>/logs/` per ringer's post-run ritual (read every retried/failed log, spot-check at least one passing artifact).
+The run JSON is truth; a detached/background shell's exit status is transport and can report failure for a run that passed (stm-nav lesson).
+On a FAIL, attribute before relaunching: re-run the check's steps yourself against the tree - if the worker's output was correct and the CHECK was wrong, fix the check, commit the audited work, and annotate the model log (MODEL-NOTES + amendment when available) instead of burning a round.
 Native: skim diffs of Opus-tier units and test files of Sonnet-tier units.
 Merge passing branches (or apply reviewed patches) into the integration branch; run the full suite there.
 Resolve stopped units: a small spec issue means edit the spec artifact and relaunch that unit; a design issue is recorded for the plan's downstream review step under the source plan's slip rules.
diff --git a/skills/loop-which/SKILL.md b/skills/loop-which/SKILL.md
index 99da775..e615d1f 100644
--- a/skills/loop-which/SKILL.md
+++ b/skills/loop-which/SKILL.md
@@ -54,6 +54,11 @@ vocabulary so the answer plugs straight into a build plan later if the verdict c
 Don't ask what you already know from context. If the conversation already established the user's
 available tiers or that they're chat-only, don't re-ask that part.

+Orchestration availability has a ground-truth file: read the `[engines.*]` blocks in
+`~/.config/ringer/config.toml` instead of asking. As of 2026-07-17 the ringer `claude-zai` lane
+(GLM-5.2 on the z.ai flat-rate coding plan - zero Anthropic API) is wired and probe-validated on
+this machine, and Jeremy prefers it over Sonnet for execution typing.
+
 ### 3. Score the plan against the seven questions

 Walk the plan through the framework (full detail in the reference file):

