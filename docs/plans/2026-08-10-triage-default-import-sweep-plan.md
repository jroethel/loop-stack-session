# Triage-Default Import Sweep Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes. No specific tooling, harness, or skills are assumed.

**Goal:** Make agent-run scan/classify/verify/add-if-outstanding the default loop-setup import workflow, with two small setup.sh changes and prose rewrites, no new tooling.
**Approach:** Add a side-effect-free `--list-candidates` flag and widen the unattended issue-creation gate to all tracker modes in setup.sh, then promote references/import-triage.md from an exception reference to the documented default workflow and update SKILL.md to lead with it.
**Tech stack:** Bash (setup.sh, tests), Markdown reference and skill docs.
**Source brief:** docs/briefs/2026-08-10-triage-default-import-sweep-brief.md

## Global constraints

- Minimal machinery: net code diff is two setup.sh changes plus a few test lines; invent no flags, files, state, or abstractions beyond D1-D5.
- loop-setup is attended-only and ignores the loop-auto autonomy knob; there is no unattended triage mode.
- House markdown style for the two prose tasks: plain dashes only, never the em-dash character.
- House markdown style: one sentence per physical line in prose.
- House markdown style: pipe-table columns aligned in raw text, total table width under 110 chars.

## Dependency graph

- Task 1 (setup.sh flag and gate plus tests) has no dependencies.
- Task 2 (rewrite references/import-triage.md) depends on Task 1.
- Task 3 (update SKILL.md) depends on Task 1.
- Task 2 and Task 3 are parallel-eligible with each other (disjoint files).

```
Task 1 ---> Task 2
       \--> Task 3
```

## Human checkpoints

- Criterion 1 [judgment] field run: after all three tasks land, the user runs `/loop-setup` on a real
  repo holding pre-existing work files and confirms the resulting tracker contains zero already-done
  or noise issues filed.
  This is a field judgment on a live repo, not an automated check, and routes here rather than to any task.
- User review of the two rewritten prose docs (references/import-triage.md and SKILL.md) for voice,
  accuracy, and completeness before they are considered final.

## How to run

Run the single import test:

```bash
bash tests/loop-setup/import.sh
```

Run the full suite:

```bash
tests/run.sh
```

## Task 1: setup.sh --list-candidates flag and all-modes unattended gate

Depends on: none

**Files (exclusive ownership):**
- Modify: `skills/loop-setup/setup.sh` (arg parse near line 32; scan functions `is_excluded`/`is_candidate`/`collect_candidates` at lines 218-266; the unattended gate inside `reconcile_import` at lines 324-332)
- Modify/Test: `tests/loop-setup/import.sh` (scenario A env fix at line 71; new scenarios C and D; final PASS line)
- Modify/Test: `tests/loop-setup/idempotence.sh` (three local-mode unattended invocations gain the opt-in flag; lines 32, 93, 108)

**Interfaces:**
- Consumes: existing `collect_candidates` output (one normalized path per line, honoring `SCAN_ROOTS` from `--scan`); existing `LOOP_ASSUME_YES`, `LOOP_IMPORT_REMOTE`, `DRY_REMOTE`, `MODE`.
- Produces:
  - The flag `--list-candidates`: prints exactly `collect_candidates` output to stdout, exits 0, with
    NO side effects (no mkdir, no vendored-script installs, no drift-refresh offers, no prompts, no
    remote detection output, nothing else on stdout). Honors any `--scan` roots.
  - Widened gate semantics: `LOOP_IMPORT_REMOTE=1` is now required alongside `LOOP_ASSUME_YES` before
    an unattended run creates issues in ALL modes (local included), not just remote modes. The variable
    keeps its name. The per-candidate `import candidate:` line still prints under the skip.

**Acceptance check:** `tests/run.sh` ends with `0 failed` and exits 0 (baseline before this task: 36 suites, all passing).
The gate change touches shared setup.sh behavior reached by multiple suites, so the whole suite is the done-criterion, not `import.sh` alone. [executed-check]

- [ ] Step 1 (arg parse, near line 32): initialize `LIST_ONLY=0` alongside `DRY_REMOTE=0`, and add a
      `--list-candidates) LIST_ONLY=1; shift ;;` case to the while-loop arg parser. `--scan` collection
      into `SCAN_ROOTS` is unchanged and must still be honored when `--list-candidates` is given.
- [ ] Step 2 (relocate scan functions, D2): move `is_excluded`, `is_candidate`, and `collect_candidates`
      (currently lines 218-266) above the arg-parse while-loop (near line 32), so they are already
      defined at the early-exit point in Step 3. The contract is behavioral, not structural: no behavior
      of these three functions changes, only their position (they read `SCAN_ROOTS` at call time, not
      at definition time).
- [ ] Step 3 (early exit, D2): immediately after the arg-parse while-loop, before remote detection,
      any mkdir, vendored-script install, or `report_remote` output, add: if `LIST_ONLY` is 1, run
      `collect_candidates` and `exit 0`. Nothing else may print to stdout on this path.
- [ ] Step 4 (widen the gate, D3, lines 324-332): move the
      `LOOP_ASSUME_YES=1 && LOOP_IMPORT_REMOTE!=1` skip OUT of the `if [ "$MODE" != local ]` wrapper so
      it fires in every mode, skipping issue creation with a note and `continue`. Keep the `DRY_REMOTE`
      skip inside the `MODE != local` wrapper, and keep that wrapper AHEAD of the moved-out gate so the
      dry-run diagnostic (`dry-run-remote: skipping remote import of ...`) still wins when both apply.
      The `echo "import candidate: $f ..."` line at line 318 stays before the gate and must still print.
      Generalize the note wording so it no longer says "remote" (for example, "skipping unattended
      import of $f; set LOOP_IMPORT_REMOTE=1 to allow unattended issue creation"); the literal substring
      `set LOOP_IMPORT_REMOTE=1` must survive, because `tests/loop-setup/idempotence.sh:157` greps for it.
      The variable keeps its name for compatibility; add a one-line comment at the gate stating the
      historical name now gates unattended creation in all modes, local included.
      Scenario B (`LOOP_ASSUME_NO`) behavior is untouched.
- [ ] Step 5 (scenario A env fix, line 71): add `LOOP_IMPORT_REMOTE=1` so accept-all still auto-files
      under the widened gate. Replace the existing invocation line VERBATIM:

```bash
out="$( cd "$A" && LOOP_ASSUME_YES=1 LOOP_IMPORT_REMOTE=1 LOOP_TRACKER_ANSWER=local "$SETUP" --scan "$EXTRA" </dev/null )" \
  || fail "import setup (accept-all) errored"
```

- [ ] Step 6 (idempotence.sh env fixes): the widened gate would otherwise break this suite's three
      local-mode unattended import blocks, whose assertions require creation (lines 47, 95, 111).
      Add `LOOP_IMPORT_REMOTE=1` to each invocation, replacing these three lines VERBATIM.
      Line 32:

```bash
out="$( cd "$A" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_YES=1 LOOP_IMPORT_REMOTE=1 "$SETUP" </dev/null 2>/dev/null )" \
```

      Line 93:

```bash
outK="$( cd "$K" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_YES=1 LOOP_IMPORT_REMOTE=1 "$SETUP" </dev/null 2>/dev/null )" \
```

      Line 108:

```bash
outL="$( cd "$L" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_YES=1 LOOP_IMPORT_REMOTE=1 "$SETUP" --scan "$XT" </dev/null 2>/dev/null )" \
```

      No other line in idempotence.sh changes; the remote-mode blocks (out7, outDR, out8, outM, outN)
      already carry the correct flags and their message greps (lines 157, 171, 197) are satisfied by
      Step 4's wording constraints.
- [ ] Step 7 (scenario C, `--list-candidates`): add this block after scenario B, before the final PASS
      line. Test code VERBATIM:

```bash
# ---------- scenario C: --list-candidates prints candidates only, zero side effects ----------
C="$(mktemp -d)"; CE="$(mktemp -d)"; trap 'rm -rf "$A" "$EXTRA" "$B" "$C" "$CE"' EXIT
( cd "$C" && git init -q )
mkdir -p "$C/docs"
printf '# C plan\nLabel: idea\nMARKER_C_PLAN\n'   > "$C/docs/c-plan.md"
printf '# Readme\nStatus: open\nMARKER_C_README\n' > "$C/README.md"
printf '# Scanned todo\nMARKER_C_SCAN\n'           > "$CE/todo.md"

list="$( cd "$C" && "$SETUP" --list-candidates --scan "$CE" </dev/null )" \
  || fail "--list-candidates exited nonzero"

# it prints the in-tree candidate and the --scan candidate, honoring --scan
printf '%s\n' "$list" | grep -qx 'docs/c-plan.md'   || fail "--list-candidates omitted docs/c-plan.md"
printf '%s\n' "$list" | grep -qF "$CE/todo.md"       || fail "--list-candidates omitted the --scan candidate"
# excluded root files never appear
printf '%s\n' "$list" | grep -qx 'README.md'         && fail "--list-candidates listed an excluded root file"
# nothing but candidate paths reaches stdout: no setup narration, no install lines
printf '%s\n' "$list" | grep -q 'loop-setup complete' && fail "--list-candidates emitted setup narration"
printf '%s\n' "$list" | grep -q 'installed'           && fail "--list-candidates emitted an install line"
# zero side effects: no config, no vendored scripts, no docs homes created
[ -f "$C/config/repo-state.md" ] && fail "--list-candidates wrote config/repo-state.md"
[ -d "$C/scripts" ]              && fail "--list-candidates installed vendored scripts"
[ -d "$C/docs/archive" ]         && fail "--list-candidates created docs/archive/"
[ -d "$C/docs/issues" ]          && fail "--list-candidates created docs/issues/"
```

- [ ] Step 8 (scenario D, all-modes unattended gate, criterion 5): add this block after scenario C,
      before the final PASS line. Test code VERBATIM:

```bash
# ---------- scenario D: unattended run (LOOP_ASSUME_YES, no LOOP_IMPORT_REMOTE) files nothing ----------
D="$(mktemp -d)"; trap 'rm -rf "$A" "$EXTRA" "$B" "$C" "$CE" "$D"' EXIT
( cd "$D" && git init -q )
mkdir -p "$D/docs"
printf '# D plan\nLabel: idea\nMARKER_D_PLAN\n' > "$D/docs/d-plan.md"

outD="$( cd "$D" && LOOP_ASSUME_YES=1 LOOP_TRACKER_ANSWER=local "$SETUP" </dev/null )" \
  || fail "unattended-gate setup errored"

# local mode, unattended, no LOOP_IMPORT_REMOTE: nothing is filed
grep -Rq 'MARKER_D_PLAN' "$D/docs/issues/" 2>/dev/null \
  && fail "unattended run without LOOP_IMPORT_REMOTE filed an issue"
# but the per-candidate line still prints (D3: the trace survives the skip)
printf '%s\n' "$outD" | grep -q '^import candidate: docs/d-plan.md' \
  || fail "unattended run did not print the import candidate line"
```

- [ ] Step 9 (final PASS line): replace the existing `echo "PASS: import - ..."` line VERBATIM so the
      message covers the new coverage:

```bash
echo "PASS: import - roots offered, labels inferred, exclusions honored, decline skips, --list-candidates clean, unattended files nothing"
```

## Task 2: rewrite references/import-triage.md as the default import workflow

Depends on: Task 1

**Files (exclusive ownership):**
- Modify: `skills/loop-setup/references/import-triage.md` (full rewrite)

**Interfaces:**
- Consumes: the `--list-candidates` flag from Task 1 (named as the scan entry point); the graduated-item
  body template shape in `config/repo-state.md` (Archive-and-graduation rules); `scripts/tracker.sh create`;
  `scripts/gen-mirrors.sh .`.
- Produces: the documented default workflow and the triage-record-doc definition that the field run
  (human checkpoint) is judged against.

**Acceptance check:** all grep commands below exit 0 (match found), and `bash tests/loop-setup/import.sh`
still exits 0. [executed-check]

```bash
F=skills/loop-setup/references/import-triage.md
grep -q -- '--list-candidates' "$F"
grep -q 'scripts/tracker.sh create' "$F"
grep -q 'scripts/gen-mirrors.sh' "$F"
grep -qi 'file:line' "$F"
grep -qi 'already-built' "$F"
grep -q 'docs/archive/' "$F"
grep -q 'import-triage.md' "$F"
grep -q 'Source doc:' "$F"
grep -q 'Imported:' "$F"
grep -q 'Restart context:' "$F"
grep -qi 'split' "$F"
grep -qi 'merge' "$F"
bash tests/loop-setup/import.sh
```

The rewrite must contain these sections and satisfy each content obligation.
Write the prose; do not merely restate these bullets.

- [ ] Section: intro framing. State that this IS the default import workflow (no longer an exception
      path), and that the agent runs it after the mechanical config and mirror steps. Note that
      verbatim one-file-one-issue import and skip remain fallbacks offered at the bash per-item prompt.
- [ ] Section: the workflow steps, as an ordered list in blast-radius order.
      1. Scan candidates via `setup.sh --list-candidates` (one normalized path per line, honoring `--scan`).
      2. Classify each discrete item as an issue (no label) or a backlog item (`idea` label).
      3. Verify each item as outstanding vs already-built, checked against the codebase and git history;
         every dropped item (already-built or noise) carries disclosed evidence, a `file:line` or a commit.
      4. Present ONE batch disclosure table, then offer a per-candidate walkthrough for any items the
         user picks.
      5. On approval: file each outstanding item, archive each source doc, write the record doc,
         regenerate mirrors.
- [ ] Section: the batch disclosure table shape. One table with columns source-doc, item, classification,
      verdict-plus-evidence, proposed-action. Keep the raw table under 110 chars wide; put long evidence
      or prose outside the table if a cell would exceed it.
- [ ] Section: on-approval actions, precise and in order.
      File outstanding items via `scripts/tracker.sh create --label <label> --title <title> --body <body>`
      (it prints the new issue number).
      Archive each source doc to `docs/archive/` (use `git mv` when the file is tracked, plain `mv` otherwise).
      Write the D1 triage record doc.
      Regenerate mirrors via `scripts/gen-mirrors.sh .`.
- [ ] Section: issue body pointer-back footer. Each filed issue body ends with the graduated-item template
      shape from `config/repo-state.md`: the verbatim item prose, then a `---` rule, then `Source doc: <archived path>`,
      `Imported: <date>`, `Restart context: <one line>`.
- [ ] Section: the triage record doc (D1). Path `docs/archive/YYYY-MM-DD-import-triage.md`, one per run
      that had candidates; a zero-candidate run writes none. It is written by the agent, never by bash.
      Contents: a triage table with columns source-doc, item, classification (issue or idea), verdict
      (outstanding, already-built, or noise), evidence, action, followed by the filed issue numbers.
      Every dropped row carries an evidence line, so the record contains no drop without evidence.
- [ ] Section: retained judgment rules. Keep the existing split, merge, leave-in-place, titling, labelling,
      and disclosure rules verbatim in intent. A doc holding N discrete items yields N issues, never one.
      The `idea` label is the one load-bearing label: `idea` for anything parked by decision, no label
      for active work.

## Task 3: update SKILL.md to lead with the triage default

Depends on: Task 1

**Files (exclusive ownership):**
- Modify: `skills/loop-setup/SKILL.md` (the "The import sweep" section and the "Non-interactive hooks" section)

**Interfaces:**
- Consumes: the `--list-candidates` flag and widened `LOOP_IMPORT_REMOTE` gate semantics from Task 1;
  the workflow spec in this plan's Task 2 obligations (the file `references/import-triage.md` is referenced
  by name only, so Task 2 and Task 3 stay parallel-eligible).
- Produces: skill narration that leads with the triage workflow as the recommended default and documents
  the new flag and gate.

**Acceptance check:** all grep commands below exit 0 (match found), and `bash tests/loop-setup/import.sh`
still exits 0. [executed-check]

```bash
F=skills/loop-setup/SKILL.md
grep -q -- '--list-candidates' "$F"
grep -q 'import-triage.md' "$F"
grep -qi 'attended-only' "$F"
grep -qi 'loop-auto' "$F"
grep -q 'LOOP_IMPORT_REMOTE' "$F"
grep -qi 'fallback' "$F"
bash tests/loop-setup/import.sh
```

- [ ] Step 1 (import-sweep section): rewrite so it leads with the triage workflow as the recommended
      default: after the mechanical config and mirror steps, the agent scans via `setup.sh --list-candidates`,
      classifies each discrete item (issue vs `idea`), verifies outstanding vs already-built with disclosed
      evidence, presents one batch disclosure table, offers a per-candidate walkthrough, and on approval
      files, archives, writes the record doc, and regenerates mirrors, per `references/import-triage.md`.
      State that verbatim one-file-one-issue import and skip remain explicitly offered fallbacks and that
      the bash per-item prompt is unchanged.
- [ ] Step 2 (attended-only statement): state plainly that loop-setup is attended-only and ignores the
      loop-auto autonomy knob; there is no unattended triage mode.
- [ ] Step 3 (Non-interactive hooks section): update the `LOOP_IMPORT_REMOTE` description for D3's new
      semantics: `LOOP_IMPORT_REMOTE=1` is now required alongside `LOOP_ASSUME_YES` before an unattended
      run creates issues in ALL modes (local included), not only remote backends; without it, candidates
      are skipped with a note in every mode.
- [ ] Step 4 (document --list-candidates): document the `--list-candidates` flag in the Non-interactive
      hooks section: it prints the candidate paths (one normalized path per line, honoring `--scan`),
      exits 0, and has no side effects, serving as the triage scan entry point.
