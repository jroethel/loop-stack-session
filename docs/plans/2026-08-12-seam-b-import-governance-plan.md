# Seam B: import governance Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes. No specific tooling, harness, or skills are assumed.

**Goal:** Let a brief authored as a tracker seed be imported on purpose via an explicit `--seed` flag without un-excluding all briefs, and sharpen `import-triage.md` so an agent cannot mistake a pre-supplied classification for approval.
**Approach:** Add a `--seed <file>` flag to `setup.sh` that injects a named, normally-excluded doc into the sweep as a candidate (bypassing both `is_excluded` and `is_candidate`), and skip archive-on-import for seeded docs (they retain governed-lane archival). Independently, add two statements to `import-triage.md`'s "On approval" section. The two seams touch disjoint files and run in parallel.
**Tech stack:** Bash (target: bash 3.2 / macOS - no associative arrays), the repo's self-contained bash test suites, Markdown reference file.
**Source brief:** `docs/briefs/2026-08-11-import-governance-brief.md`. Issues: #20 (`--seed`), #21 (triage gate prose).

## Global constraints

- **Decided this session (brief's open questions):**
  - `--seed` bypasses **both** `is_excluded` and `is_candidate` for a named file. Explicit naming is the deliberate act and overrides the shape heuristic. (The brief itself fails `is_candidate` - no `Status:`/keyword - so bypassing only `is_excluded` would leave it un-swept.)
  - `--seed` is **repeatable**, mirroring `--scan` (a `SEED_FILES` array).
  - A `--seed`'d doc is **not** archive-offered on import. A brief is a governed lane (archives with its plan, and stays the `/loop-plan` source); it is excluded by default so it is never re-offered anyway.
- **Bash 3.2 target:** no `declare -A` / associative arrays anywhere. Track seeded paths via the `SEED_FILES` array plus an `is_seeded` linear-membership helper.
- Path normalization: store and compare seed paths with a leading `./` stripped (`${x#./}`), matching how `collect_candidates` normalizes every other path.
- Out of scope (do not do): un-excluding `docs/briefs/` or any governed lane by default; any enforcement mechanism treating the agent as adversarial; changing loop-brainstorm's parking-lot graduation. (The `/dev/tty` hard gate is parked as issue #28.)

## Dependency graph

Two tasks, **no dependency between them** - disjoint file ownership, run in parallel.

- Task 1 owns `skills/loop-setup/setup.sh` + `tests/loop-setup/import.sh`.
- Task 2 owns `skills/loop-setup/references/import-triage.md`.

## Human checkpoints

None. Every criterion is an executed check (grep or a driven test). The wording of Task 2's prose is the user's to eyeball at plan/commit review, but its presence is grep-verified.

## How to run

```
bash tests/loop-setup/import.sh                              # Task 1 suite; prints "PASS: import ...", exits 0
grep -q 'never approval to file' skills/loop-setup/references/import-triage.md \
  && grep -q 'Approval covers the issue bodies' skills/loop-setup/references/import-triage.md   # Task 2, exits 0
bash tests/run.sh                                            # full suite regression; "N passed, 0 failed", exits 0
```

---

### Task 1: `--seed` flag in `setup.sh` (#20)

Depends on: none (parallel with Task 2)

**Files (exclusive ownership):**
- Modify: `skills/loop-setup/setup.sh` (arg-parse block :83-90; add `SEED_FILES=()` near :81; `collect_candidates` :54-77; `reconcile_import` archive call :354; add an `is_seeded` helper)
- Test: `tests/loop-setup/import.sh` (add scenario E)

**Interfaces:**
- `--seed <file>` (repeatable): validated at parse (`[ -f ]`), appended normalized to `SEED_FILES`.
- `collect_candidates` emits each existing `SEED_FILES` path, bypassing `is_excluded` and `is_candidate`, but skipping any file the normal sweep already emits (non-excluded AND candidate-shaped) to avoid a double-offer.
- `is_seeded <normalized-path>` returns 0 if the path is in `SEED_FILES`. `reconcile_import` skips `archive_offer` for a seeded path.

**Acceptance check:** `bash tests/loop-setup/import.sh` exits 0, AND `bash tests/run.sh` exits 0 `[executed-check]`

**Exact edits (bash 3.2-safe; these are pinned because the array guards and the skip logic are the subtle part):**

Add the array declaration alongside `SCAN_ROOTS=()` (setup.sh:81):
```bash
SCAN_ROOTS=()
SEED_FILES=()
```

Add the `--seed` case to the arg-parse `case` (setup.sh:84-88), mirroring `--scan`:
```bash
    --seed) [ $# -ge 2 ] || fail "--seed requires a file argument"; [ -f "$2" ] || fail "--seed file not found: $2"; SEED_FILES+=("${2#./}"); shift 2 ;;
```

Add the `is_seeded` helper (place it right after `collect_candidates`'s closing brace, ~setup.sh:77):
```bash
is_seeded() {   # $1 = normalized path; true when it was named on the command line via --seed
  local s
  for s in ${SEED_FILES[@]+"${SEED_FILES[@]}"}; do [ "$s" = "$1" ] && return 0; done
  return 1
}
```

Inject the seed pass inside `collect_candidates`, immediately before its closing `}` (after the recursive-roots `done`, setup.sh:76):
```bash
  # --seed: named files bypass BOTH is_excluded and is_candidate - explicitly naming a file is the
  # deliberate act the exclusion exists to require, and overrides the shape heuristic. Skip a seed
  # the normal sweep already emits (non-excluded AND candidate-shaped) so it is not offered twice.
  local sf
  for sf in ${SEED_FILES[@]+"${SEED_FILES[@]}"}; do
    sf="${sf#./}"
    [ -f "$sf" ] || continue
    if ! is_excluded "$sf" && is_candidate "$sf"; then continue; fi
    printf '%s\n' "$sf"
  done
```
(`collect_candidates` already declares `local roots=() r f`; `sf` is a new local - add it to that `local` line or declare inline as shown.)

Skip archive for seeded docs in `reconcile_import` - change the archive call (setup.sh:354) from:
```bash
    archive_offer "$f"
```
to:
```bash
    is_seeded "$f" || archive_offer "$f"   # a --seed'd governed-lane doc archives with its plan, not on import
```

**Test - add scenario E** to `tests/loop-setup/import.sh`, immediately before the final `echo "PASS: ..."` (import.sh:157). Extend the trap to include `$E`:
```bash
# ---------- scenario E: --seed injects a normally-excluded, non-candidate-shaped brief (#20) ----------
E="$(mktemp -d)"; trap 'rm -rf "$A" "$EXTRA" "$B" "$C" "$CE" "$D" "$E"' EXIT
( cd "$E" && git init -q )
mkdir -p "$E/docs/briefs"
# excluded (docs/briefs/*) AND fails is_candidate (no Status:/keyword filename) - only --seed surfaces it
printf '# Brief: seed thing\nMARKER_SEED\n' > "$E/docs/briefs/seed-brief.md"

# without --seed, the brief is invisible to the sweep (the default exclusion stays intact)
list="$( cd "$E" && "$SETUP" --list-candidates </dev/null )" || fail "--list-candidates (no seed) errored"
printf '%s\n' "$list" | grep -q 'seed-brief.md' && fail "the brief was listed without --seed (exclusion broke)"

# with --seed, the named brief becomes a candidate despite being excluded and non-candidate-shaped
list="$( cd "$E" && "$SETUP" --list-candidates --seed docs/briefs/seed-brief.md </dev/null )" \
  || fail "--list-candidates --seed errored"
printf '%s\n' "$list" | grep -qx 'docs/briefs/seed-brief.md' \
  || fail "--seed did not surface the named excluded brief as a candidate"

# a --seed'd doc flows into reconcile_import (the per-file ask fires) and imports
outE="$( cd "$E" && LOOP_ASSUME_YES=1 LOOP_IMPORT_REMOTE=1 LOOP_TRACKER_ANSWER=local "$SETUP" --seed docs/briefs/seed-brief.md </dev/null )" \
  || fail "--seed import run errored"
printf '%s\n' "$outE" | grep -q '^import candidate: docs/briefs/seed-brief.md' \
  || fail "--seed'd brief never reached the per-file import prompt"
grep -Rq 'MARKER_SEED' "$E/docs/issues/" || fail "--seed'd brief was not imported as an issue"

# a --seed'd governed-lane doc is NOT archived (it archives with its plan, stays the /loop-plan source)
[ -f "$E/docs/briefs/seed-brief.md" ] || fail "--seed'd brief was archived/moved out of docs/briefs/"
[ ! -f "$E/docs/archive/seed-brief.md" ] || fail "--seed'd brief was copied into docs/archive/"

# a non-existent --seed path fails with a clear message
out="$( cd "$E" && "$SETUP" --seed docs/briefs/nope.md --list-candidates </dev/null 2>&1 )" \
  && fail "--seed with a missing file exited 0"
printf '%s\n' "$out" | grep -qi 'seed' || fail "--seed missing-file error did not mention the seed flag/path"
```

- [ ] Step 1: Add scenario E (and the extended trap) to `tests/loop-setup/import.sh`.
- [ ] Step 2: Run `bash tests/loop-setup/import.sh` - expect FAIL (`--seed` is an unknown argument today; the without/with-seed and no-archive assertions cannot pass).
- [ ] Step 3: Apply the `setup.sh` edits above (array decl, `--seed` case, `is_seeded`, seed pass, archive skip).
- [ ] Step 4: Run `bash tests/loop-setup/import.sh` - expect PASS. Then `bash tests/run.sh` - expect `0 failed` (default sweep still excludes briefs).
- [ ] Step 5: Commit:
```bash
git add skills/loop-setup/setup.sh tests/loop-setup/import.sh
git commit -m "loop-setup: --seed flag to import a named, normally-excluded doc into the sweep (#20)"
```

---

### Task 2: sharpen the triage approval gate (#21)

Depends on: none (parallel with Task 1)

**Files (exclusive ownership):**
- Modify: `skills/loop-setup/references/import-triage.md` (the `## On approval` section, currently :43)

**Interfaces:** none - prose only, consumed by an agent reading the reference at triage time.

**Acceptance check:** both statements are present `[executed-check]`:
```bash
grep -q 'never approval to file' skills/loop-setup/references/import-triage.md \
  && grep -q 'Approval covers the issue bodies' skills/loop-setup/references/import-triage.md
```
plus `bash tests/run.sh` exits 0 (no regression).

**Exact edit.** Under the `## On approval` heading (import-triage.md:43), insert this block immediately after the heading and before the existing `In this order:` line:

```markdown
Approval is the human's explicit assent at the batch-disclosure step of this run, and nothing else.
A pre-supplied classification - a `Label:` line, a `Status:` line, or a human-written "proposed lane entries" section - is never approval to file: it says what an item is, not that its issue may be created.
Approval covers the issue bodies the agent writes, not just the classification.
The human has not seen those bodies until the disclosure table, and they are the part no one else authored, so the proposed body (or at minimum its pointer-back footer) is shown for assent before any create.

```

- [ ] Step 1: Insert the block above under `## On approval`.
- [ ] Step 2: Run the acceptance grep - expect both matches (exit 0). Run `bash tests/run.sh` - expect `0 failed`.
- [ ] Step 3: Commit:
```bash
git add skills/loop-setup/references/import-triage.md
git commit -m "loop-setup: sharpen import-triage approval gate - classification is not approval, approval covers bodies (#21)"
```
