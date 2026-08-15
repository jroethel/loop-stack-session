# loop-molt Skill Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes. No specific tooling, harness, or skills are assumed.

**Goal:** Ship a thin standalone `skills/loop-molt/` skill that audits any instruction-prose artifact against a dated harness-capability snapshot, classifying blocks as PLUMBING / POLICY / PREMISE / CHOREOGRAPHY and emitting deletions, a drift ledger line, and (for structural findings) a brief through the shared pipeline.
**Approach:** Vendor the harness-drift-audit protocol as the skill's canonical reference; keep SKILL.md thin (trigger, one-line test, four bins pointer, step pointers); add a one-line `--focus harness-drift` delegation from loop-improve with zero duplicated audit content; the four bins are defined in exactly one file (the reference).
**Tech stack:** Bash gate tests, Markdown skill prose, existing loop-stack install/registry machinery.
**Source brief:** `docs/briefs/2026-08-15-loop-molt-skill-brief.md`

## Global constraints

- SKILL.md target under 100 lines: outcomes not choreography; the protocol is the reference doc.
- The four bins (PLUMBING/POLICY/PREMISE/CHOREOGRAPHY) are defined in exactly ONE file: `skills/loop-molt/references/protocol.md`. SKILL.md points to it, never restates the definitions.
- One implementation, two entry points: loop-improve gains a one-line `--focus harness-drift` delegation to /loop-molt; no audit content is duplicated into loop-improve.
- Constraint-register step is mandatory and ASK-class (`[gate:ASK]`): deliberate constraints are asked before any premise is classified expired.
- Molt itself must not require Claude Code to run conceptually - the protocol is harness-agnostic prose; only the SKILL.md wrapper is Claude-Code-specific.
- install.sh symlinks every `skills/*` automatically; the doctor check is generic (engine prereqs + gate-registry freshness via `tests/gates/check.sh`) and needs no change (confirmed this session).
- Drift ledger home: `docs/molt-ledger.md` (repo-level, committed). The skill appends one entry per audited artifact.
- Constraint register from brief 1 applies (portability, ringer spine, /workflows off, no worsening the known hardcodes).

## Dependency graph

```
Task 1 (skill + protocol + ledger seed) ─┐
Task 2 (loop-improve delegation) ────────┼─> Task 3 (gate suite) ─> Task 4 (registry + README + install + full suite + smoke run)
```

Task 1 and Task 2 touch disjoint files and could run in parallel; Task 3 asserts both their contents; Task 4 regenerates the registry that Task 1's new gate tag changes, then runs every check.

## Human checkpoints

- The smoke run (Task 4) is a live /loop-molt execution: its constraint-register step is `[gate:ASK]` by design, so a real molt run stops for the owner. For THIS session's smoke run against `skills/handoff/SKILL.md`, the owner (Jeremy) is the constraint-register respondent; the smoke run's success is measured by the classification output + one ledger line + zero unprompted edits to handoff, not by a merge.
- Merge gate: staged for Jeremy at session end, never fired by the executor.

## How to run

```
./install.sh                 # symlinks skills/*, runs doctor (non-fatal warnings ok)
scripts/gen-gate-registry.sh .   # regenerate docs/gate-registry.md after adding a gate tag
tests/run.sh                 # full suite; must end "0 failed"
bash tests/gates/molt.sh     # the new gate suite alone
```

## Global constraints on the plan itself

No implementation code is pre-written except the gate-test assertions (test code is the spec's teeth). The SKILL.md and protocol.md prose is authored at execution against the contracts below.

---

### Task 1: The skill - SKILL.md, vendored protocol, ledger seed

Depends on: none

**Files (exclusive ownership):**
- Create: `skills/loop-molt/SKILL.md`
- Create: `skills/loop-molt/references/protocol.md`
- Create: `docs/molt-ledger.md`

**Interfaces:**
- Produces: skill name `loop-molt`; a `[gate:ASK]` constraint-register step in SKILL.md; the four bin names defined only in `references/protocol.md`; a ledger file whose per-entry shape is `## YYYY-MM-DD - <artifact path>` followed by snapshot date, deletions by bin, policy kept, premises verified, constraints re-confirmed.
- Consumes: `~/create/pcs/harness-drift-audit-protocol.md` (vendored verbatim-in-substance as the reference, with a "vendored YYYY-MM-DD; this copy is canonical, the pcs copy is the historical draft" attribution line).

**SKILL.md contract (under 100 lines):**
- YAML frontmatter: `name: loop-molt`; a `description:` whose trigger phrases include "molt", "harness drift", "audit this skill/prose against the harness", "re-evaluate prose against what the harness now does", and "/loop-molt".
- Body: the one-line test ("would the harness or a current frontier model do this unprompted, today?"), a one-line-each pointer to the four bins in the reference (not their definitions), and pointers into the reference for steps 0-5.
- The constraint-register step carries `[gate:ASK]` and states: deliberate constraints are asked of the owner before any premise is classified expired.
- Workflow split stated in one place: small findings apply inline via the subtraction test + a `docs/molt-ledger.md` line same session; structural findings converge through `~/.claude/skills/loop-brainstorm/references/brief-pipeline.md` into a brief and ride the normal chain (/loop-plan onward).
- The drift-ledger step names `docs/molt-ledger.md` and its per-entry shape.
- SKILL.md restates NONE of the bin definitions, POLICY membership test, or subtraction procedure - those live in the reference.

**protocol.md contract:**
- The full harness-drift-audit protocol (the vendored pcs file), unchanged in substance, with the added attribution line at the top.
- This is the ONE file where PLUMBING / POLICY / PREMISE / CHOREOGRAPHY are defined (the bins table).

**molt-ledger.md contract:**
- A short header explaining the file (the repo's drift ledger; one entry per audited artifact per audit; appended, never rewritten), then ready for its first entry (added by the Task 4 smoke run).

**Acceptance check:** `test -f skills/loop-molt/SKILL.md && test -f skills/loop-molt/references/protocol.md && test -f docs/molt-ledger.md && awk 'END{exit (NR<=100)?0:1}' skills/loop-molt/SKILL.md && grep -qE '\[gate:ASK\]' skills/loop-molt/SKILL.md && [ "$(grep -rc 'PLUMBING\|POLICY\|PREMISE\|CHOREOGRAPHY' skills/loop-molt/ | grep -v ':0' | wc -l | tr -d ' ')" = "1" ]` exits 0 `[executed-check]`

- [ ] Step 1: Create `references/protocol.md` from the vendored pcs protocol with attribution.
- [ ] Step 2: Write `SKILL.md` under 100 lines, bins as pointers only, `[gate:ASK]` on the constraint-register step.
- [ ] Step 3: Seed `docs/molt-ledger.md` with its header.
- [ ] Step 4: Run the acceptance check, expect exit 0.

---

### Task 2: loop-improve delegation line

Depends on: none

**Files (exclusive ownership):**
- Modify: `skills/loop-improve/SKILL.md`

**Interfaces:**
- Produces: a one-line `--focus harness-drift` delegation that hands off to /loop-molt.
- Consumes: the existing focus-argument handling in loop-improve Step 1.

**Contract:**
- Add exactly one delegation line (a sentence, in the focus/Step 1 region) stating that `--focus harness-drift` delegates the audit to /loop-molt, which owns the harness-drift protocol.
- Duplicate ZERO audit procedure: no bins, no one-line test, no subtraction steps copied into loop-improve. A pointer only.

**Acceptance check:** `grep -qi 'harness-drift' skills/loop-improve/SKILL.md && grep -qi 'loop-molt' skills/loop-improve/SKILL.md && ! grep -q 'PLUMBING\|CHOREOGRAPHY' skills/loop-improve/SKILL.md` exits 0 `[executed-check]`

- [ ] Step 1: Add the delegation line in the focus region of loop-improve Step 1.
- [ ] Step 2: Run the acceptance check, expect exit 0 (delegation present, no bin definitions leaked in).

---

### Task 3: The molt gate suite

Depends on: Task 1, Task 2

**Files (exclusive ownership):**
- Create: `tests/gates/molt.sh`

**Interfaces:**
- Consumes: the files produced by Tasks 1 and 2, plus `README.md` (row asserted, added in Task 4 - see note).
- Produces: an executable suite discoverable by `tests/run.sh` (pattern `tests/*/*.sh`).

**Contract - the suite asserts (mirrors the `tests/gates/loop-improve.sh` style; `fail()` + `set -uo pipefail`):**
- `skills/loop-molt/SKILL.md` exists; frontmatter `name: loop-molt`.
- Trigger phrases present in the description: `molt` and `harness drift` (or `harness-drift`).
- `skills/loop-molt/references/protocol.md` exists.
- Constraint-register ASK gate present: `grep -qE '\[gate:ASK\]' SKILL.md`, and the surrounding line mentions the constraint register.
- The four bins are defined in exactly one file under `skills/loop-molt/`, and that file is the reference, NOT SKILL.md: `grep -q PLUMBING references/protocol.md` AND `! grep -q 'PLUMBING' SKILL.md` (SKILL points to the bins, never defines them). Gate tag well-formedness is covered generically by `tests/gates/check.sh`; this suite asserts the ASK gate's presence, not re-implements the scanner.
- loop-improve delegation present (`harness-drift` + `loop-molt`) and no audit-procedure duplication (`! grep -q PLUMBING skills/loop-improve/SKILL.md`).
- README has a `loop-molt` row.

**Acceptance check:** `bash tests/gates/molt.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write `tests/gates/molt.sh` with the assertions above.
- [ ] Step 2: Run it - expect FAIL on the README row (added in Task 4) until Task 4, then PASS. (Order Task 4's README edit before the final run, or run this suite as part of Task 4's full-suite pass.)

---

### Task 4: Registry refresh, README row, install, full suite, smoke run

Depends on: Task 1, Task 2, Task 3

**Files (exclusive ownership):**
- Modify: `README.md` (add a loop-molt row/line in the skills map)
- Modify: `docs/gate-registry.md` (regenerated, never hand-edited)
- Modify: `docs/molt-ledger.md` (first entry appended by the smoke run)

**Interfaces:**
- Consumes: everything from Tasks 1-3.
- Produces: a fresh gate registry including loop-molt's ASK gate; a README row; the first ledger entry.

**Contract:**
- Add a `loop-molt` row to the README skills map, matching the existing row style.
- Regenerate the registry: `scripts/gen-gate-registry.sh .` (loop-molt's new `[gate:ASK]` tag makes the committed registry stale until this runs).
- Run `./install.sh`; confirm loop-molt is symlinked and its metadata loads (frontmatter present at the install target).
- Run `tests/run.sh`; must end "0 failed" (regenerate mirrors first if the fresh worktree lacks them: `scripts/gen-mirrors.sh .`).
- Smoke run: execute /loop-molt against `skills/handoff/SKILL.md`. Produce a block classification, append ONE entry to `docs/molt-ledger.md`, and make ZERO edits to `skills/handoff/SKILL.md`. Verify no unprompted edit with `git diff --stat skills/handoff/SKILL.md` (empty).

**Acceptance check:** `scripts/gen-mirrors.sh . >/dev/null 2>&1; bash tests/gates/check.sh && tests/run.sh && grep -q 'loop-molt' README.md && grep -q 'handoff' docs/molt-ledger.md && [ -z "$(git diff --stat skills/handoff/SKILL.md)" ]` exits 0 `[executed-check]`

- [ ] Step 1: Add the README loop-molt row.
- [ ] Step 2: `scripts/gen-gate-registry.sh .` - registry now fresh with loop-molt.
- [ ] Step 3: `./install.sh` - confirm loop-molt symlink + metadata loads.
- [ ] Step 4: Smoke-run /loop-molt on `skills/handoff/SKILL.md`; append the ledger entry; verify handoff untouched.
- [ ] Step 5: `tests/run.sh` ends "0 failed"; run the acceptance check, expect exit 0.
- [ ] Step 6: Commit Tasks 1-4 together (one commit: the skill, delegation, gate suite, registry, README, ledger).

## Brief-criteria coverage map

| Brief criterion                                             | Task / acceptance check                          |
|------------------------------------------------------------|--------------------------------------------------|
| `./install.sh` installs /loop-molt; skill loads            | Task 4 Step 3 `[executed-check]`                 |
| `tests/gates/` gains a molt suite (triggers, ASK gate, ref)| Task 3 `bash tests/gates/molt.sh` `[executed-check]` |
| Bins defined in exactly one file, pointed to by SKILL.md   | Task 1 acceptance + Task 3 assertion `[executed-check]` |
| loop-improve has the delegation line, zero duplicated audit| Task 2 acceptance `[executed-check]`             |
| Smoke run: classification + ledger line + no unprompted edit| Task 4 Step 4 + acceptance `[executed-check]`    |
| `tests/run.sh` passes clean                                | Task 4 Step 5 `[executed-check]`                 |

Every checkable brief criterion maps to a task carrying an `[executed-check]`. Plan accepted.
