# Build Wave Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes. No specific tooling, harness, or skills are assumed.

**Goal:** Apply the settled ledger to the four chain skills in one pass and make the autonomy knob's gate consumption live, so a start-and-stop multi-SME project can move through brainstorm -> plan -> drive with working gates, handoffs, and a batch-review journal.
**Approach:** One wave of mostly file-disjoint tasks, each owning one skill or script, so parallel workers never collide; the gate tags already exist, so "consumption" is flipping the managed block's rules from staged to live and letting this wave's own drive run prove it; a terminal task regenerates the single derived registry and retires the now-stale tags-only guard.
**Tech stack:** Markdown skill bodies, POSIX bash scripts, awk, `gh` CLI, git worktrees; tests are bash grep/behavior assertions under `tests/`.
**Source brief:** `docs/briefs/2026-08-02-build-wave-brief.md`.

## Execution model (how this plan is run)

`/loop-drive` compiles this into a single wave; the per-task `git commit` lines are the unit boundaries, and git is the resume ground truth (a session that dies mid-wave relaunches any task whose commit is absent - it never resumes a half-done task).
This plan mutates no global state during the wave: installing symlinks and the managed block, and editing the out-of-repo benchmark-refresh skill, are deferred to the "Post-wave orchestrator steps" section, applied by a human or the orchestrator from the merged main checkout - never by a worktree worker and never auto-taken.

## Demonstration semantics (Criterion 2)

This wave is executed by the running session before its edits are installed, so the session's loaded managed block still reads "records intent only."
The orchestrator therefore runs the new four-gate protocol by direction from Task 1's not-yet-installed prose, journaling every auto-take, and the journal it leaves is the demonstration artifact.
The *validated* proof that live consumption works from a clean start is the post-install fresh session (HC2 / Criterion 10), run after the Post-wave orchestrator steps.

## Global constraints

- Markdown edits follow the user's rules: one sentence per line, plain dashes (never "-"'s em-dash form), aligned table pipes.
- Never touch the Jeremy-maintained "Reading the user" section of `skills/loop-brainstorm/SKILL.md` (the bulleted block under "Reading the user").
- The gate tags already exist and are complete (the 19-gate inventory); no task may add, remove, or reword any line carrying a `[gate:...]` tag, with two exceptions, both in Task 3: the deliberate double-STOP line split, and the spec-edit gate retype (its `[gate:STOP]` line reworded and a sized `[gate:BATCH]` line added).
- Autonomy-consumption prose is added adjacent to gate sites, never by editing a tagged line's own text, so registry churn stays localized to Task 3.
- `docs/gate-registry.md` is a derived file; only Task 10 regenerates and commits it. No other task commits it.
- Do not run `tests/gates/tags.sh` or `tests/gates/check.sh` as any task's acceptance except Task 10; they assert global and derived state that is green only after consolidation.
- No task runs `install.sh` or edits any file outside this repo (`~/.agents/skills/benchmark-refresh/SKILL.md`, `~/.agents/skills/fable-sandwich/`); reads of those paths are fine. Installing symlinks/managed block and the benchmark-refresh edit are the Post-wave orchestrator steps, applied from merged main.
- No committed symlink may be machine-absolute; install-generated leaves (the benchmarks symlink) are created by `install.sh` at install time, never committed.
- Every new script that calls `gh` carries a fixture/dry-run hook (the `gen-mirrors.sh` `MIRRORS_JSON_FILE` pattern) so tests never hit the network.
- The rubix review of this plan is flagged high-stakes: lens B resolves to the Fable role pin.

## Dependency graph

```
Wave 1 (parallel, file-disjoint):
  Task 1  managed-block consumption goes live        (claude-md/fable.md)
  Task 3  loop-drive: compile dispatch + entry + STOP split
  Task 4  loop-plan: H decompose dispatch + K prefactor
  Task 5  loop-brainstorm: E + parking-lot graduation
  Task 6  loop-which: frontmatter trim
  Task 7  wayfinder skill + mirror exclusion
  Task 9  gen-gate-registry awk parity

Wave 2 (parallel, file-disjoint):
  Task 2  loop-auto: flip to live + per-repo default rider   depends on Task 1
  Task 8  frontier-sandwich rename sweep                      depends on Tasks 1,3,5,6

Wave 3 (terminal):
  Task 10 regenerate registry + retire tags-only guard + full suite   depends on all
```

## Human checkpoints

- Criterion 12 `[judgment]`: after Task 10, a human reads the four rewritten skills plus the managed block and confirms they read as one voice and contradict neither each other nor the managed block. This is not a worker task.
- Criterion 2 (the demonstration): this plan is itself executed by `/loop-drive` under the knob set to `auto`; the journal it produces at `docs/reviews/<run-date>-build-wave-batch-review.md` is inspected at the end-of-run checkpoint. Completeness check: the count of BATCH+DEFAULT journal entries must equal the count of BATCH+DEFAULT gates the orchestrator's run-state artifact recorded as fired; each entry carries decision, rationale, and reversal path. A mismatch means a decision went unlogged - reject and reconcile. Producing and accepting that journal is the demonstration; it is validated by human review, not a task.
- Criterion 10 (HC2): after the wave, a human opens a fresh session, poses a model-routing question, and confirms it resolves through the evidence chain (scoreboard posterior -> benchmark prior -> orchestrator pin) without hand-holding.

## How to run

- Per-task acceptance: `bash tests/gates/<name>.sh` prints `PASS` and exits 0.
- Full suite (Task 10 only): `LOOP_REVIEW_SKIP_BEHAVIOR=1 LOOP_SETUP_SKIP_BEHAVIOR=1 bash -c 'for t in $(find tests -name "*.sh" -not -name "build-fixtures.sh"); do echo "== $t"; bash "$t" || exit 1; done' && bash tests/gates/check.sh` - the two skip flags drop loop-review's and loop-setup's live behavior legs (green in their own prior waves); `tests/repo-state/live.sh` is the one leg that hits live `gh` and needs network/auth.
- Registry regeneration: `scripts/gen-gate-registry.sh .`
- Mirror regeneration: `scripts/gen-mirrors.sh .`
- Post-wave install (orchestrator step, from merged main only): `LOOP_STACK_SKILL_STYLE=agents ./install.sh`.

---

### Task 1: Managed-block autonomy consumption goes live

Depends on: none

**Files (exclusive ownership):**
- Modify: `claude-md/fable.md` (the `## Chain autonomy` section)
- Test: `tests/gates/knob-consumption.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: the authoritative statement that gate consumption is live - the sentence "Setting the knob records intent only; it changes no runtime behavior until the build wave wires consumption into the chain skills." and the sentence "Today the skills still fire their gates live regardless of the mode." are removed and replaced with live-consumption language; the four-gate consumption protocol and the per-gate journal-append protocol (already present under "The four gate classes under autonomy" and "Batch-review list format") are stated as active behavior, not staged. Later tasks (2, 8) rely on this section being live and authoritative.

**Acceptance check:** `bash tests/gates/knob-consumption.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test verbatim:

```bash
#!/usr/bin/env bash
# The managed block declares gate consumption LIVE (not staged) and keeps the full four-gate
# protocol plus the journal-append rules.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
CMD="$REPO/claude-md/fable.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$CMD" ] || fail "claude-md/fable.md missing"
# The staged-only disclaimers must be gone.
grep -qi 'records intent only' "$CMD" && fail "managed block still says 'records intent only' (consumption not made live)"
grep -qi 'still fire their gates live regardless' "$CMD" && fail "managed block still carries the staged disclaimer"
# The four gate classes and their auto-mode behavior remain.
grep -qi '## *Chain autonomy' "$CMD" || fail "missing Chain autonomy section"
for t in ASK STOP BATCH DEFAULT; do
  grep -q "$t" "$CMD" || fail "gate class $t not described"
done
# The journal (batch-review list) protocol remains: created when autonomy takes effect, appended per gate, with a reversal path.
grep -qi 'batch-review list' "$CMD" || fail "journal/batch-review protocol dropped"
grep -Eqi 'appended at every gate|appended per gate' "$CMD" || fail "per-gate append rule dropped"
grep -qi 'reversal' "$CMD" || fail "reversal-path field dropped"
# Live-consumption language is present (the knob now changes behavior).
grep -q 'Consumption is live: the knob now governs gate behavior per the four gate classes below.' "$CMD" || fail "verbatim live-consumption sentence missing"
echo "PASS: managed block consumption is live, four gate classes and journal protocol intact"
```

- [ ] Step 2: Run it - `bash tests/gates/knob-consumption.sh` - expected FAIL on "still says 'records intent only'".
- [ ] Step 3: Edit `claude-md/fable.md`: in `## Chain autonomy`, delete the two staged-disclaimer sentences ("Setting the knob records intent only; it changes no runtime behavior until the build wave wires consumption into the chain skills." and "Today the skills still fire their gates live regardless of the mode.") and replace them with this exact sentence: `Consumption is live: the knob now governs gate behavior per the four gate classes below.` Leave the four-gate-classes, batch-review-list-format, and continuation-rule subsections intact.
- [ ] Step 4: Run it - `bash tests/gates/knob-consumption.sh` - expected PASS.
- [ ] Step 5: Commit - `git add claude-md/fable.md tests/gates/knob-consumption.sh && git commit -m "task1: managed-block gate consumption goes live"`

---

### Task 2: loop-auto flips to live and gains the per-repo default rider

Depends on: Task 1

**Files (exclusive ownership):**
- Modify: `skills/loop-auto/SKILL.md`
- Modify: `scripts/loop-auto.sh`
- Modify: `config/repo-state.md` (add one `Autonomy default` lane/line)
- Test: `tests/gates/loop-auto.sh` (extend the existing test)

**Interfaces:**
- Consumes: Task 1's live-consumption managed block (the SKILL must agree with it, not contradict it).
- Produces:
  - `scripts/loop-auto.sh default {get|set <pause|auto>|clear}` - reads/writes a committed per-repo default stored line-anchored as `autonomy-default: <mode>` in `config/repo-state.md`; `default get` prints `pause` when unset; `default set` prints the exact `git add config/repo-state.md && git commit` reminder, since it touches a tracked file that would otherwise trip `preflight`'s dirty-tree STOP.
  - `scripts/loop-auto.sh get` stays a bare single-word effective mode (for script consumers): chain-state (`docs/chain-state.md`) if present, else the committed default, else `pause`. Existing bare-word assertions must keep passing.
  - `scripts/loop-auto.sh status` - a new, human-facing labeled line naming the effective mode and its source (e.g. `mode: auto (repo default)`, `mode: pause (session)`). This is the display surface for rider #4; `get` is unchanged in shape.
  - The SKILL documents: on first `set` in a repo, ask whether to persist as the repo default (committed via `default set`) or this session only (runtime `set`); and that `status` displays the effective mode and its source.

**Acceptance check:** `bash tests/gates/loop-auto.sh` exits 0 `[executed-check]`

- [ ] Step 1: In the existing `tests/gates/loop-auto.sh`, first DELETE the now-obsolete assertion that requires the staged disclaimer (the `grep -qi 'intent only\|records intent\|no runtime' "$SKILL" || fail ...` line), because Task 2 removes that text. Then append this block verbatim, keeping all other existing assertions (the bare-word `get` checks still hold because `get` stays bare):

```bash
# --- build-wave additions: live disclaimer flip, per-repo default, status display ---
# The staged/intent-only disclaimer is gone from the skill; live-consumption language is present.
grep -Eqi 'records intent only|not yet live|staged, not yet live' "$SKILL" \
  && fail "loop-auto SKILL still says the knob is staged/intent-only after consumption went live"
grep -Eqi 'consumption is live|now governs|the knob is live' "$SKILL" \
  || fail "loop-auto SKILL does not state consumption is live"
grep -Eqi 'repo default|this repo|inherit' "$SKILL" || fail "SKILL missing the per-repo default ask"
grep -q 'default' "$LA" || fail "loop-auto.sh has no default subcommand"
grep -q 'status' "$LA" || fail "loop-auto.sh has no status subcommand"
# Per-repo default round-trips, line-anchored, in config/repo-state.md.
TMP2="$(mktemp -d)"; trap 'rm -rf "$TMP" "$TMP2"' EXIT
( cd "$TMP2" && git init -q && mkdir -p config docs && echo 'docs/chain-state.md' > .gitignore \
    && printf '# Repo State Map\n' > config/repo-state.md \
    && git add -A && git commit -q -m init )
cp "$LA" "$TMP2/loop-auto.sh"
( cd "$TMP2" && bash loop-auto.sh default set auto ) || fail "default set auto failed"
grep -q '^autonomy-default: *auto' "$TMP2/config/repo-state.md" || fail "committed default not stored line-anchored"
[ "$( cd "$TMP2" && bash loop-auto.sh default get )" = "auto" ] || fail "committed default not read back as auto"
# with no runtime chain-state, effective get falls back to the committed default (bare word)
[ "$( cd "$TMP2" && bash loop-auto.sh get )" = "auto" ] || fail "effective get did not fall back to committed default"
# status discloses the effective mode AND its source (human-facing)
st="$( cd "$TMP2" && bash loop-auto.sh status )"
echo "$st" | grep -qi 'auto' || fail "status missing the effective mode"
echo "$st" | grep -Eqi 'default|source|repo' || fail "status does not disclose the mode's source"
# runtime chain-state overrides the committed default
( cd "$TMP2" && bash loop-auto.sh set pause )
[ "$( cd "$TMP2" && bash loop-auto.sh get )" = "pause" ] || fail "runtime chain-state did not override committed default"
# default set reminds the human to commit the tracked config change
( cd "$TMP2" && bash loop-auto.sh default set auto ) | grep -Eqi 'git (add|commit)|commit' \
  || fail "default set does not print the commit reminder"
```

- [ ] Step 2: Run it - `bash tests/gates/loop-auto.sh` - expected FAIL on the staged-disclaimer grep (or the missing `default`/`status` subcommand).
- [ ] Step 3: Implement against the Interfaces:
  - `scripts/loop-auto.sh`: add a `default` subcommand storing/reading `autonomy-default: <mode>` line-anchored (`^autonomy-default:`) in `config/repo-state.md`, `default get` printing `pause` when absent, and `default set` echoing the `git add config/repo-state.md && git commit ...` reminder; change `get` to resolve the effective mode (chain-state, else committed default, else `pause`) still as a bare word; add a `status` subcommand printing the labeled effective mode and its source. Keep `set`/`preflight` behavior and the chain-state exclusion in `preflight`.
  - `skills/loop-auto/SKILL.md`: remove the "Important - it records intent only" section; state consumption is live per the managed block; add a short section on the per-repo default (the first-set ask: repo default vs session-only) and that `status` shows the effective mode and source.
  - `config/repo-state.md`: add one line documenting the `autonomy-default:` key (committed per-repo default, runtime-overridden by `docs/chain-state.md`), written so the line does not itself begin with the bare key at column zero in a way a value parse would mistake for data (place the doc under a heading or prose, not as a bare `autonomy-default: <x>` example line).
- [ ] Step 4: Run it - `bash tests/gates/loop-auto.sh` - expected PASS.
- [ ] Step 5: Commit - `git add skills/loop-auto/SKILL.md scripts/loop-auto.sh config/repo-state.md tests/gates/loop-auto.sh && git commit -m "task2: loop-auto live + per-repo default rider (#4)"`

---

### Task 3: loop-drive compile dispatch, existing-_loop.md entry, and STOP-line split

Depends on: none

**Files (exclusive ownership):**
- Modify: `skills/loop-drive/SKILL.md`
- Test: `tests/gates/loop-drive.sh`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - A restated Step boundary (G): Steps 1-4 and Step 6 are compiled by one fresh-context dispatch at the drive-compile role pin; the driving session keeps Step 0, a pin review of the compiled output, the Step 5 gates, and the Step 7 launch. The skill cites the role pin by name (drive-compile dispatch), never a hard model id.
  - An explicit "start from an existing `_loop.md`" entry point: a named way to enter the skill when the orchestration plan already exists, skipping compilation and going to pin-review plus Step 7.
  - Step 5.4's minimum-checkpoint sentence is split so the effort-cap STOP, the spec-edit gate, and the outward-facing-unit STOP each sit on their own line (removing the duplicate registry row from two `[gate:STOP]` tags on one line). The spec-edit line is reworded to the relaxed rule on ONE line so the threshold and the tag co-occur: a spec edit confined to a single unit or criterion, leaving unchanged what that unit is asked to produce, and touching 15 or fewer lines, auto-takes as BATCH `[gate:BATCH]`; a larger edit, or one touching multiple units, a global constraint, or a unit's produced contract, stays `[gate:STOP]`. Record the rationale in the same clause (the boundary is blast radius, not raw size; 15 lines is the agreed threshold) so it is not relitigated.

**Acceptance check:** `bash tests/gates/loop-drive.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test verbatim:

```bash
#!/usr/bin/env bash
# loop-drive gains the compile dispatch, the existing-_loop.md entry point, and splits the
# double-STOP line; the spec-edit gate relaxes to the sized BATCH rule.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
S="$REPO/skills/loop-drive/SKILL.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$S" ] || fail "loop-drive SKILL missing"
# G: compile dispatch at the drive-compile role pin, covering steps 1-4 and 6.
grep -qi 'drive-compile' "$S" || fail "no drive-compile role-pin reference"
grep -qi 'compile' "$S" || fail "no compile-dispatch language"
# Entry point: start from an existing _loop.md.
grep -Eqi 'existing .*_loop\.md|start from an existing' "$S" || fail "no start-from-existing-_loop.md entry point"
# STOP split: no single line carries two [gate:STOP] tags.
if grep -nE '\[gate:STOP\].*\[gate:STOP\]' "$S"; then fail "a line still carries two STOP tags (duplicate registry row)"; fi
# The spec-edit gate now relaxes to a sized BATCH on ONE line: threshold and BATCH tag co-occur.
grep -E '15 (or fewer )?lines?' "$S" | grep -q '\[gate:BATCH\]' \
  || fail "the sized spec-edit rule (15 lines) and its BATCH tag are not on the same line"
grep -Eqi 'single unit|single criterion|one unit' "$S" || fail "spec-edit single-unit condition not stated"
grep -qE '\[gate:STOP\]' "$S" || fail "loop-drive lost its STOP tags"
echo "PASS: loop-drive compile dispatch, entry point, STOP split, and sized spec-edit gate present"
```

- [ ] Step 2: Run it - expected FAIL on "no drive-compile role-pin reference".
- [ ] Step 3: Edit `skills/loop-drive/SKILL.md` per the Interfaces: add the compile-dispatch framing (Steps 1-4 + 6 as one drive-compile-pinned fresh-context dispatch; session keeps Step 0, pin review, Step 5 gates, Step 7); add the explicit existing-`_loop.md` entry point (likely in Step 0 or a short "Entry points" note); split the Step 5.4 minimum-set sentence into one STOP per line and reword the spec-edit line to the sized BATCH rule (single unit/criterion and <= 15 lines -> BATCH; else STOP).
- [ ] Step 4: Run it - expected PASS.
- [ ] Step 5: Commit - `git add skills/loop-drive/SKILL.md tests/gates/loop-drive.sh && git commit -m "task3: loop-drive compile dispatch, _loop.md entry, STOP split (#5)"`

---

### Task 4: loop-plan H decompose dispatch and K prefactor rule

Depends on: none

**Files (exclusive ownership):**
- Modify: `skills/loop-plan/SKILL.md`
- Test: `tests/gates/loop-plan.sh`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - H: Step 3 (Decompose) states that a fresh-context dispatch at the plan-draft role pin does decompose plus draft plus self-review as one bundle, and the driving session then reviews the dependency graph (missing depends-on edges) against the conversation before the rubix step. Role cited by pin name, never a hard model id.
  - K: a prefactor rule in the decompose guidance - restructuring that must precede a change is called out as its own earlier task or step so it never rides inside a feature task - and a one-line pointer to expand-contract as the reference pattern for wide refactors.

**Acceptance check:** `bash tests/gates/loop-plan.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test verbatim:

```bash
#!/usr/bin/env bash
# loop-plan gains the H decompose-dispatch + dependency-graph review, and the K prefactor rule.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
S="$REPO/skills/loop-plan/SKILL.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$S" ] || fail "loop-plan SKILL missing"
# H: plan-draft dispatch + dependency-graph review.
grep -qi 'plan-draft' "$S" || fail "no plan-draft role-pin reference"
grep -Eqi 'dependency graph|depends-on edges|dependency-graph' "$S" || fail "no dependency-graph review step"
# K: prefactor rule + expand-contract reference.
grep -qi 'prefactor' "$S" || fail "no prefactor rule"
grep -Eqi 'expand-contract|expand/contract' "$S" || fail "no expand-contract reference"
echo "PASS: loop-plan carries H decompose dispatch and K prefactor rule"
```

- [ ] Step 2: Run it - expected FAIL on "no plan-draft role-pin reference".
- [ ] Step 3: Edit `skills/loop-plan/SKILL.md` Step 3 (Decompose) per the Interfaces: add the plan-draft-pinned decompose+draft+self-review dispatch, the session dependency-graph review before rubix, the prefactor rule, and the expand-contract pointer.
- [ ] Step 4: Run it - expected PASS.
- [ ] Step 5: Commit - `git add skills/loop-plan/SKILL.md tests/gates/loop-plan.sh && git commit -m "task4: loop-plan H decompose dispatch + K prefactor"`

---

### Task 5: loop-brainstorm domain modeling (E) and parking-lot graduation

Depends on: none

**Files (exclusive ownership):**
- Modify: `skills/loop-brainstorm/SKILL.md` (never the "Reading the user" block)
- Create: `scripts/graduate-parking.sh`
- Test: `tests/gates/loop-brainstorm.sh`

**Interfaces:**
- Consumes: the graduated-item body template in `config/repo-state.md` (read at runtime, not edited).
- Produces:
  - E: an added domain-modeling probe in the brainstorm flow - glossary challenge and sharpening of fuzzy terms, and scenario stress-tests offered as an optional probe when domain terms are load-bearing - without touching the "Reading the user" block.
  - `scripts/graduate-parking.sh <brief-path>`: parse each parked item in the brief's `## Parking lot` (a top-level `- ` bullet plus any indented continuation lines, e.g. a `Restart context:` line - stop at the next `## ` heading), and for each run `gh issue create --label idea` with the body built from the `config/repo-state.md` graduated-item template (verbatim item prose, `Source brief:` = the brief path, `Graduated:` = today, `Restart context:` = the item's continuation), printing each created issue number verbosely; resolve `config/repo-state.md` from the caller's cwd repo (the `loop-auto.sh` convention). A `GRADUATE_DRY_RUN=1` hook prints the `gh` invocations (with the full `--body`) instead of running them (network-free tests).
  - A wired step in the brainstorm brief-commit flow (Step 8) that, on commit, previews the parked-item count and titles, and on assent invokes `scripts/graduate-parking.sh` - classified as a DEFAULT gate so an autonomous run auto-takes it but journals the created issues for accept-or-reverse, rather than firing silently.

**Acceptance check:** `bash tests/gates/loop-brainstorm.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test verbatim:

```bash
#!/usr/bin/env bash
# loop-brainstorm absorbs domain modeling (E), keeps "Reading the user" untouched, and wires the
# parking-lot graduation script; the script's dry-run emits one gh issue create per parked item.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
S="$REPO/skills/loop-brainstorm/SKILL.md"
G="$REPO/scripts/graduate-parking.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$S" ] || fail "loop-brainstorm SKILL missing"
# E: domain modeling absorbed.
grep -Eqi 'glossary|domain model|domain term' "$S" || fail "no domain-modeling / glossary probe"
grep -Eqi 'stress-test|scenario stress' "$S" || fail "no scenario stress-test probe"
# Reading the user block is present and unchanged in spirit (the heading survives).
grep -qi 'Reading the user' "$S" || fail "the Reading the user section was removed"
# Graduation script wired (with preview/confirm) and exists.
grep -q 'graduate-parking.sh' "$S" || fail "brainstorm does not wire the graduation script"
grep -Eqi 'preview|confirm|assent|DEFAULT' "$S" || fail "brainstorm does not preview/confirm before graduating"
[ -x "$G" ] || fail "scripts/graduate-parking.sh missing or not executable"
# Dry-run emits one gh issue create per parked item, labels idea, carries the template + continuation.
TMPB="$(mktemp -d)"; trap 'rm -rf "$TMPB"' EXIT
mkdir -p "$TMPB/config"
# Minimal repo-state.md carrying the graduated-item template fields the script fills in.
cat > "$TMPB/config/repo-state.md" <<'EOF'
Graduated-item issue body template (label the issue `idea`):
<verbatim parking-lot prose from the brief>
---
Source brief:
Graduated: <date>
Restart context: <one line>
EOF
cat > "$TMPB/brief.md" <<'EOF'
## Parking lot

- First parked thread: do the thing later.
- Second parked thread: revisit the other thing.
  Restart context: pick up where the sketch left off.

## Out of scope
EOF
out="$( cd "$TMPB" && GRADUATE_DRY_RUN=1 bash "$G" brief.md )" || fail "graduate-parking dry-run failed"
n="$(printf '%s\n' "$out" | grep -c 'gh issue create')"
[ "$n" -eq 2 ] || fail "expected 2 gh issue create calls, got $n"
printf '%s\n' "$out" | grep -q -- '--label idea' || fail "graduation does not label issues idea"
printf '%s\n' "$out" | grep -q 'Source brief:' || fail "body missing the Source brief template field"
printf '%s\n' "$out" | grep -q 'Restart context:' || fail "body missing the Restart context template field"
printf '%s\n' "$out" | grep -q 'pick up where the sketch left off' || fail "multi-line continuation dropped from the body"
echo "PASS: loop-brainstorm E absorbed, Reading-the-user intact, graduation previews + dry-runs 2 items with template"
```

- [ ] Step 2: Run it - expected FAIL on "no domain-modeling / glossary probe".
- [ ] Step 3: Implement:
  - `scripts/graduate-parking.sh`: parse the brief's `## Parking lot` section (stop at the next `## ` heading) into one item per top-level `- ` bullet; for each, build the graduated-item body from the `config/repo-state.md` template and run `gh issue create --label idea --title <derived> --body <body>`; under `GRADUATE_DRY_RUN=1` echo the `gh` command instead; print each created issue number; `chmod +x` the script.
  - `skills/loop-brainstorm/SKILL.md`: add the E domain-modeling probe (glossary challenge, fuzzy-term sharpening, optional scenario stress-tests) outside the "Reading the user" block; wire `scripts/graduate-parking.sh` into the Step 8 brief-commit flow so it previews the parked-item count and titles and runs on assent (a DEFAULT gate, journaled), replacing the manual graduation prose while keeping the verbose-announce rule.
- [ ] Step 4: Run it - expected PASS.
- [ ] Step 5: Commit - `git add skills/loop-brainstorm/SKILL.md scripts/graduate-parking.sh tests/gates/loop-brainstorm.sh && git commit -m "task5: loop-brainstorm E + parking-lot graduation"`

---

### Task 6: loop-which frontmatter trim

Depends on: none

**Files (exclusive ownership):**
- Modify: `skills/loop-which/SKILL.md` (frontmatter `description` only)
- Test: `tests/gates/loop-which.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: a trimmed `description` (the current ~144-word block reduced to <= 75 words, target ~60) that still names the ONE AGENT / AGENT TEAM / DON'T BOTHER verdicts and the core routing triggers ("which approach", "how to proceed", "route") so invocation accuracy holds. Body text and the `name:` line are untouched.

**Acceptance check:** `bash tests/gates/loop-which.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test verbatim:

```bash
#!/usr/bin/env bash
# loop-which frontmatter description is trimmed but still triggers on the core intent.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
S="$REPO/skills/loop-which/SKILL.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$S" ] || fail "loop-which SKILL missing"
# Extract the frontmatter, then drop the name: line so 'which' in the skill name can't vacuously pass.
fm="$(awk 'NR==1&&/^---$/{f=1;next} f&&/^---$/{exit} f' "$S")"
desc="$(printf '%s\n' "$fm" | grep -v '^name:')"
words="$(printf '%s' "$desc" | wc -w | tr -d ' ')"
[ "$words" -le 75 ] || fail "description still $words words; trim to <= 75"
# Concrete verdict names survive the trim (not the vacuous skill-name match).
echo "$desc" | grep -Eqi 'one agent'            || fail "trimmed description dropped the ONE AGENT verdict"
echo "$desc" | grep -Eqi 'team'                 || fail "trimmed description dropped the AGENT TEAM verdict"
echo "$desc" | grep -Eqi "don.?t bother|not worth" || fail "trimmed description dropped the DON'T BOTHER verdict"
# A core routing trigger survives.
echo "$desc" | grep -Eqi 'which approach|how to proceed|route' || fail "trimmed description lost its routing trigger"
# Body is intact.
grep -qi 'One-Minute Test' "$S" || fail "loop-which body damaged (lost One-Minute Test)"
echo "PASS: loop-which description trimmed to $words words, verdicts + trigger + body intact"
```

- [ ] Step 2: Run it - expected FAIL on the word count.
- [ ] Step 3: Edit only the `description:` frontmatter of `skills/loop-which/SKILL.md` down to <= 75 words (target ~60), keeping the ONE AGENT / AGENT TEAM / DON'T BOTHER verdict names and at least one core routing trigger phrase; leave `name:` and the body untouched.
- [ ] Step 4: Run it - expected PASS.
- [ ] Step 5: Commit - `git add skills/loop-which/SKILL.md tests/gates/loop-which.sh && git commit -m "task6: loop-which frontmatter trim"`

---

### Task 7: Wayfinder skill and mirror exclusion

Depends on: none

**Files (exclusive ownership):**
- Create: `skills/wayfinder/SKILL.md`
- Modify: `scripts/gen-mirrors.sh` (exclude `wayfinder:*`-labeled issues from both mirrors)
- Test: `tests/gates/wayfinder.sh`

**Interfaces:**
- Consumes: the lane scheme in `config/repo-state.md` (read only); the `idea` label semantics.
- Produces:
  - A ported wayfinder skill adapted to loop-stack: the map is a `wayfinder:map`-labeled GitHub issue with `wayfinder:<research|prototype|grilling|task>` child tickets; grilling tickets resolve via `/loop-brainstorm` (which absorbed domain modeling in Task 5, but this skill only names the skill, no ordering dependency); research tickets resolve via a fresh-context research subagent; prototype tickets produce a throwaway artifact with no dependency on any uninstalled skill; blocking uses a GitHub issue-body convention (`Blocked by: #N`) since the tracker lacks native blocking; the routing hand-off (J): when the way is clear the map hands off to `/loop-plan`, and per-ticket model choice follows the loop-drive evidence chain. No reference to `/setup-matt-pocock-skills`, `/grilling`, `/domain-modeling`, or `/prototype` remains.
  - `scripts/gen-mirrors.sh` filters out any issue whose labels include a `wayfinder:` prefix from both `ISSUES.md` and `BACKLOG.md`, leaving `idea`-lane logic unchanged.

**Acceptance check:** `bash tests/gates/wayfinder.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test verbatim:

```bash
#!/usr/bin/env bash
# Wayfinder is ported to loop-stack conventions and its labels are excluded from the mirrors.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
W="$REPO/skills/wayfinder/SKILL.md"
M="$REPO/scripts/gen-mirrors.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$W" ] || fail "skills/wayfinder/SKILL.md missing"
grep -q '^name: wayfinder' "$W" || fail "frontmatter name is not wayfinder"
# Labels layered on the lane scheme.
grep -q 'wayfinder:map' "$W" || fail "no wayfinder:map label"
grep -Eq 'wayfinder:(research|grilling|task|prototype)' "$W" || fail "no wayfinder ticket-type labels"
# Routing hand-off to loop-plan; per-ticket routing via the evidence chain.
grep -qi 'loop-plan' "$W" || fail "no routing hand-off to loop-plan"
grep -qi 'loop-brainstorm' "$W" || fail "grilling tickets not remapped to loop-brainstorm"
# Uninstalled Matt-only skill references are gone.
for bad in 'setup-matt-pocock-skills' '/grilling' '/domain-modeling' '/prototype'; do
  grep -q "$bad" "$W" && fail "wayfinder still references uninstalled '$bad'"
done
# Mirror exclusion: a wayfinder-labeled issue never appears in either mirror.
TMPW="$(mktemp -d)"; trap 'rm -rf "$TMPW"' EXIT
cat > "$TMPW/issues.json" <<'EOF'
[{"number":91,"title":"Map: pick storage","labels":[{"name":"wayfinder:map"}],"updatedAt":"2026-08-02T00:00:00Z"},
 {"number":92,"title":"A real backlog idea","labels":[{"name":"idea"}],"updatedAt":"2026-08-02T00:00:00Z"},
 {"number":93,"title":"A plain issue","labels":[],"updatedAt":"2026-08-02T00:00:00Z"}]
EOF
( cd "$TMPW" && MIRRORS_JSON_FILE="$TMPW/issues.json" bash "$M" "$TMPW" ) || fail "gen-mirrors failed on fixture"
# Anchor to the table-row form so a tmpdir path containing 91/92/93 in the header cannot false-match.
grep -Eq '^\| *91 *\|' "$TMPW/ISSUES.md" "$TMPW/BACKLOG.md" && fail "wayfinder:map issue leaked into a mirror"
grep -Eq '^\| *92 *\|' "$TMPW/BACKLOG.md" || fail "idea issue missing from BACKLOG.md (exclusion over-reached)"
grep -Eq '^\| *93 *\|' "$TMPW/ISSUES.md" || fail "plain issue missing from ISSUES.md (exclusion over-reached)"
echo "PASS: wayfinder ported, hand-off wired, wayfinder:* excluded from mirrors, idea/plain lanes intact"
```

- [ ] Step 2: Run it - expected FAIL on "skills/wayfinder/SKILL.md missing".
- [ ] Step 3: Implement:
  - Port `~/repos/mattpocock/skills/skills/engineering/wayfinder/SKILL.md` into `skills/wayfinder/SKILL.md`, adapting per the Interfaces (gh-issues tracker, the label scheme, the `/loop-brainstorm` and research-subagent and `/loop-plan` remappings, the `Blocked by:` body convention, removal of uninstalled-skill references).
  - `scripts/gen-mirrors.sh`: in the emit path, skip any row whose labels contain a `wayfinder:`-prefixed name for both mirrors; keep the `idea` lane split unchanged.
- [ ] Step 4: Run it - expected PASS. Also run `bash tests/repo-state/mirrors.sh` to confirm the `gen-mirrors.sh` change did not regress the existing `idea`/plain lane behavior.
- [ ] Step 5: Commit - `git add skills/wayfinder/SKILL.md scripts/gen-mirrors.sh tests/gates/wayfinder.sh && git commit -m "task7: wayfinder skill + mirror exclusion (J, #2)"`

---

### Task 8: frontier-sandwich rename sweep

Depends on: Task 1, Task 3, Task 5, Task 6

**Files (exclusive ownership):**
- Create: `skills/frontier-sandwich/**` (ported from `~/.agents/skills/fable-sandwich/`, renamed; the install-generated `references/model-benchmarks.md` leaf is NOT committed)
- Modify: `install.sh` (add frontier-sandwich handling, retire fable-sandwich, repoint `FS_REFS`, and fix the line-157 self-check)
- Modify: `claude-md/fable.md` (benchmark-prior path line only)
- Modify: `skills/loop-which/SKILL.md` (fable-sandwich references)
- Modify: `skills/loop-brainstorm/SKILL.md` (Step 9 alternative reference)
- Modify: `skills/loop-drive/SKILL.md` (the "a.k.a. Fable Sandwich" alias)
- Test: `tests/gates/frontier-sandwich.sh`

(The `~/.agents/skills/benchmark-refresh/SKILL.md` write-path edit and running `install.sh` are NOT in this task; they are Post-wave orchestrator steps, since both mutate state outside the repo worktree.)

**Interfaces:**
- Consumes: Tasks 1, 3, 5, 6 (it re-opens their files, so it runs after them).
- Produces:
  - A repo-local `skills/frontier-sandwich/` skill (SKILL.md + references), content ported from fable-sandwich with the skill id and paths renamed; the format name "Frontier Sandwich" is retained, the skill-id `fable-sandwich` and the "Fable Sandwich" alias are removed. The `references/model-benchmarks.md` leaf is excluded from the commit (install.sh creates it as a symlink to `config/routing/model-benchmarks.md`), so no machine-absolute symlink is committed.
  - `install.sh`: symlinks `skills/frontier-sandwich` (the normal skills loop), adds `fable-sandwich` to the existing `for old in frontier-loop one-minute-test` retire list (the one place the old id legitimately appears), repoints `FS_REFS` to `skills/frontier-sandwich/references/model-benchmarks.md`, and updates the line-157 doctor self-check to assert the `frontier-sandwich` benchmarks symlink (not `fable-sandwich`).
  - `claude-md/fable.md`: the "Benchmark prior file:" line names the frontier-sandwich path.
  - No live reference to the old name in either form - the `fable-sandwich` id or the "Fable Sandwich" alias - remains in `skills/`, `config/`, `scripts/`, or `claude-md/`; the format name "Frontier Sandwich" is retained; in `install.sh` the hyphenated id appears exactly once (the retire list).

**Acceptance check:** `bash tests/gates/frontier-sandwich.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test verbatim:

```bash
#!/usr/bin/env bash
# fable-sandwich is renamed to frontier-sandwich as a repo skill; no live fable-sandwich id remains.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$REPO/skills/frontier-sandwich/SKILL.md" ] || fail "skills/frontier-sandwich/SKILL.md missing"
grep -q '^name: frontier-sandwich' "$REPO/skills/frontier-sandwich/SKILL.md" || fail "skill id not frontier-sandwich"
# The install-generated benchmarks leaf must not be committed (install.sh creates it).
X="$REPO/skills/frontier-sandwich/references/model-benchmarks.md"
if [ -L "$X" ] || [ -e "$X" ]; then fail "install-generated benchmarks leaf is committed; install.sh must create it"; fi
# install.sh wires the new skill and mentions fable-sandwich EXACTLY once (the retire list).
grep -q 'frontier-sandwich' "$REPO/install.sh" || fail "install.sh does not reference frontier-sandwich"
c="$(grep -c 'fable-sandwich' "$REPO/install.sh")"
[ "$c" -eq 1 ] || fail "fable-sandwich should appear exactly once in install.sh (the retire list); found $c (line-157 self-check likely still stale)"
grep -Eq 'for old in .*fable-sandwich' "$REPO/install.sh" || fail "fable-sandwich is not in the retire list"
# No live old-name reference in either form (hyphen id or "Fable Sandwich" alias) in active source.
# install.sh is excepted (its retire list must name the hyphenated id); "Frontier Sandwich" is fine.
if grep -rniE 'fable[ -]sandwich' "$REPO/skills" "$REPO/config" "$REPO/scripts" "$REPO/claude-md" 2>/dev/null; then
  fail "a live fable-sandwich id or 'Fable Sandwich' alias remains in active source"
fi
# Managed block benchmark path points at frontier-sandwich.
grep -q 'frontier-sandwich' "$REPO/claude-md/fable.md" || fail "managed block benchmark path not renamed"
echo "PASS: frontier-sandwich repo skill in place, old id only in the retire list, benchmarks leaf uncommitted"
```

- [ ] Step 2: Run it - expected FAIL on missing `skills/frontier-sandwich/SKILL.md`.
- [ ] Step 3: Implement (all in-repo file edits; do NOT run install.sh and do NOT touch benchmark-refresh - those are Post-wave steps):
  - `cp -R ~/.agents/skills/fable-sandwich skills/frontier-sandwich`, then `rm -f skills/frontier-sandwich/references/model-benchmarks.md` (that leaf is an install-generated symlink; install.sh recreates it), rename the skill id in the frontmatter to `frontier-sandwich`, drop the "Fable Sandwich" alias (keep "Frontier Sandwich"), and fix any internal path references.
  - Sweep the old name out: the hyphenated `fable-sandwich` id in `skills/loop-which/SKILL.md`, `skills/loop-brainstorm/SKILL.md`, and the benchmark path line of `claude-md/fable.md`; and the "a.k.a. Fable Sandwich" alias in `skills/loop-drive/SKILL.md` -> replace with `frontier-sandwich` / drop the alias.
  - `install.sh`: add `frontier-sandwich` handling - the normal skills loop symlinks it; add `fable-sandwich` to the existing `for old in frontier-loop one-minute-test` retire list; repoint `FS_REFS` to `skills/frontier-sandwich/references/model-benchmarks.md`; and update the line-157 doctor self-check so it tests the `frontier-sandwich` benchmarks symlink, leaving `fable-sandwich` mentioned exactly once (the retire list).
- [ ] Step 4: Run it - `bash tests/gates/frontier-sandwich.sh` - expected PASS. (Installing the symlinks is deferred to the Post-wave orchestrator steps; do not run install.sh here.)
- [ ] Step 5: Commit - `git add skills/frontier-sandwich install.sh claude-md/fable.md skills/loop-which/SKILL.md skills/loop-brainstorm/SKILL.md skills/loop-drive/SKILL.md tests/gates/frontier-sandwich.sh && git commit -m "task8: frontier-sandwich rename sweep"`

---

### Task 9: gen-gate-registry pipe-escape parity

Depends on: none

**Files (exclusive ownership):**
- Modify: `scripts/gen-gate-registry.sh` (the `excerpt` function's pipe escaping)
- Test: `tests/gates/registry-esc.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: `gen-gate-registry.sh` escapes `|` in a gate excerpt with the same char-loop approach `gen-mirrors.sh` uses (`esc()`), replacing the current `gsub(/\|/, "\\|", t)`, so the two generators treat pipes identically and a gate excerpt containing `|` renders as an escaped single cell.

**Acceptance check:** `bash tests/gates/registry-esc.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test verbatim:

```bash
#!/usr/bin/env bash
# gen-gate-registry escapes a pipe inside a gate excerpt (parity with gen-mirrors' esc()).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
GEN="$REPO/scripts/gen-gate-registry.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
# Source parity: pipe escaping uses the char-loop esc(), not gsub (which diverges gawk vs BWK awk).
# A behavioral fixture alone is vacuous here: BWK awk on darwin already renders the current gsub as \|.
grep -Eq 'gsub\(/\\\|/' "$GEN" && fail "still uses gsub for pipe escaping (the gawk/BWK divergence remains)"
grep -q 'function esc(' "$GEN" || fail "no char-loop esc() function adopted from gen-mirrors"
# Behavioral cross-check: a gate excerpt with a pipe renders as one escaped row of exactly 3 columns.
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/skills/loop-esc/" "$TMP/docs"
printf '## Step 1 - has a pipe\nChoose left | right here and decide.`[gate:BATCH]`\n' > "$TMP/skills/loop-esc/SKILL.md"
"$GEN" "$TMP" >/dev/null || fail "gen-gate-registry failed on the pipe fixture"
row="$(grep 'loop-esc' "$TMP/docs/gate-registry.md")" || fail "escaped row missing"
printf '%s' "$row" | grep -q '\\|' || fail "pipe in excerpt not escaped"
# Removing escaped pipes leaves exactly the 4 table delimiters (3 data columns).
bars="$(printf '%s' "$row" | sed 's/\\|//g' | tr -cd '|' | wc -c | tr -d ' ')"
[ "$bars" -eq 4 ] || fail "malformed row: $bars unescaped pipes, expected 4 (3 columns)"
echo "PASS: gen-gate-registry uses esc() char-loop and renders a pipe as one escaped 3-column row"
```

- [ ] Step 2: Run it - expected FAIL on "still uses gsub for pipe escaping" (the current source uses `gsub`; the behavioral fixture alone would pass vacuously on darwin, which is why the source-level assertion drives RED).
- [ ] Step 3: Edit `scripts/gen-gate-registry.sh`: replace the `gsub(/\|/, "\\|", t)` in `excerpt()` with a char-loop escape identical to `gen-mirrors.sh`'s `esc()`.
- [ ] Step 4: Run it - expected PASS.
- [ ] Step 5: Commit - `git add scripts/gen-gate-registry.sh tests/gates/registry-esc.sh && git commit -m "task9: gen-gate-registry pipe-escape parity"`

---

### Task 10: Regenerate the registry, retire the tags-only guard, run the full suite

Depends on: Task 1, Task 2, Task 3, Task 4, Task 5, Task 6, Task 7, Task 8, Task 9

**Files (exclusive ownership):**
- Modify: `docs/gate-registry.md` (regenerate)
- Modify: `tests/gates/tags.sh` (retire the stale tags-only invariant)
- Test: `tests/gates/check.sh` (existing; run, not modified) plus the whole suite

**Interfaces:**
- Consumes: every prior task's committed state.
- Produces: a freshly regenerated `docs/gate-registry.md` with no duplicate rows, and a `tags.sh` whose one-shot tags-only-diff assertion is replaced by per-type gate-count floors (forward drift protection: a future edit that deletes a gate or silently swaps a class drops a count below its floor and REDs), keeping the per-skill tag presence, four-types-present, STOP-in-loop-drive, and malformed-tag checks.

**Acceptance check:** `bash tests/gates/check.sh` exits 0 and the full suite passes `[executed-check]`

- [ ] Step 1: Update `tests/gates/tags.sh`: delete the `strip_tags`/baseline `diff` block and its `TAGS_BASE_REF` invariant (a one-shot guard for the tag-adding commit; the wave legitimately changes prose). In its place add per-type count floors - after counting each gate type, assert each count is at least its regenerated-registry value (set the floors from Step 2's fresh registry, e.g. `ASK>=N_ask`, `STOP>=N_stop`, `BATCH>=N_batch`, `DEFAULT>=N_default`), so a later silent deletion or class-swap fails. Keep the per-skill tag presence, four-types-present loop, STOP-in-loop-drive check, and malformed-tag guard.
- [ ] Step 2: Regenerate: `scripts/gen-gate-registry.sh .` and confirm no duplicate data rows: `grep '^|' docs/gate-registry.md | grep -v '^| skill' | grep -v '^|---' | sort | uniq -d` prints nothing. Read the per-type counts here to set Step 1's floors.
- [ ] Step 3: Run the full suite (live model leg skipped; one live-gh leg disclosed):
  ```
  LOOP_REVIEW_SKIP_BEHAVIOR=1 LOOP_SETUP_SKIP_BEHAVIOR=1 bash -c 'for t in $(find tests -name "*.sh" -not -name "build-fixtures.sh"); do echo "== $t"; bash "$t" || { echo "FAILED: $t"; exit 1; }; done'
  bash tests/gates/check.sh
  ```
  The two skip flags drop loop-review's and loop-setup's live behavior legs (green in their own prior waves); `tests/repo-state/live.sh` is the sole leg hitting live `gh` and needs network/auth. Expected: every script prints `PASS` and `check.sh` prints its fresh-registry PASS line.
- [ ] Step 4: If `check.sh` reports STALE, rerun Step 2; if any per-skill test fails, the owning task is not actually done - fix in that task, not here.
- [ ] Step 5: Commit - `git add docs/gate-registry.md tests/gates/tags.sh && git commit -m "task10: regenerate registry, gate-count floors, full suite green"`

---

## Post-wave orchestrator steps (out-of-worktree, applied from merged main)

These mutate state outside the repo worktree, so no worktree worker runs them; the human or the orchestrator applies them from the merged main checkout after Task 10. Under an autonomous run they are STOP-class (global mutation) - named, never auto-taken, and journaled if the knob is on.

1. Install: from the repo root on merged main, run `LOOP_STACK_SKILL_STYLE=agents ./install.sh`. Confirm it reports the `frontier-sandwich` and `wayfinder` symlinks, the `fable-sandwich` retire, the refreshed managed block, and a non-dangling benchmarks leaf (`found model-benchmarks.md (prior tier wired)`), with no WARNING about a stale `fable-sandwich` path.
2. benchmark-refresh path: edit `~/.agents/skills/benchmark-refresh/SKILL.md` so its overwrite target names the generalized benchmarks location (`config/routing/model-benchmarks.md`, reached via the installed `frontier-sandwich/references/model-benchmarks.md` leaf), per brief criterion 8. Confirm: `grep -q 'frontier-sandwich\|config/routing/model-benchmarks.md' ~/.agents/skills/benchmark-refresh/SKILL.md` and no remaining `fable-sandwich` in that file.
3. Then run the HC2 fresh-session routing check (Criterion 10) in a new session, and the Criterion 2 journal-completeness review, per Human checkpoints.
