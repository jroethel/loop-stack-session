# Loop-stack Plumbing Hardening Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes. No specific tooling, harness, or skills are assumed.

**Goal:** Make loop-stack's vendored plumbing keep its documented promises in every target repo, and add one command that verifies the whole test suite.
**Approach:** Fix each of the eight audit findings in place at its named location, no redesign of the vendoring convention. The test runner lands first as the shared verification baseline, then every other fix ships with its check plugged into that runner. All work is bash and gh only, in-repo and reversible.
**Tech stack:** bash + awk, gh CLI, no external dependencies.
**Source brief:** docs/briefs/2026-08-08-audit-sweep-brief.md

## Global constraints

- House style for any markdown a task touches: never the em dash character, plain "-" only; one full sentence per line; pipe tables aligned.
- Every shell script keeps `set -uo pipefail` and stays zero-dependency bash (awk and gh are the only external calls; no jq, no python).
- Test runner shape: a discovery runner over `tests/*/*.sh` with an explicit skip list inside the runner (chosen over a per-file marker: one place to read, no scanning of file contents, and the runner already opens every path).
- Runner exclusion facts to design around: `tests/loop-review/build-fixtures.sh` is a helper that exits non-zero when run with no argument, so it is skipped by basename; `tests/loop-review/acceptance.sh` makes real model calls in its layer B unless `LOOP_REVIEW_SKIP_BEHAVIOR=1`, so the runner exports that variable; `tests/repo-state/live.sh` asserts this repo's own live GitHub state, so the runner runs it only when `gh auth status` succeeds and otherwise emits a `SKIP:` line that does not count as a failure.
- Vendored-script drift detection (setup.sh): content compare with `cmp -s` between the target repo's `scripts/gen-mirrors.sh` + `scripts/tracker.sh` + `scripts/graduate-parking.sh` and loop-stack's current copies; on drift, offer an assented refresh via the existing `ask()` pattern honoring `LOOP_ASSUME_YES`/`LOOP_ASSUME_NO`; declining leaves the file untouched. No version stamps.
- Handoff fallback: for a repo WITHOUT `config/repo-state.md`, the handoff lands in `docs/handoffs/` inside that repo (created on demand), NOT the OS temp dir. Both `skills/handoff/SKILL.md` and `tests/handoff/location.sh` change in the same task so the suite never contradicts itself.
- tracker.sh github list fetch bound: a fixed constant `--limit 1000` (a constant is acceptable per the brief; no pagination reader).
- graduate-parking.sh is installed by setup.sh the same skip-if-exists way gen-mirrors.sh and tracker.sh are, and then also participates in the drift refresh above.
- migrate-tracker.sh empty label: the create command omits `--label` entirely when the labels frontmatter is empty (gh's `--label` takes a label name value and an empty string would target an empty-named label; verified from `gh issue create --help`, which documents `-l, --label name`).
- README.md lines 35 and 75 describe loop-improve selection as multi-finding into the single brief.
- loop-auto.sh `cmd_get` falls back to `repo_default` when `docs/chain-state.md` exists but has no `autonomy:` key, so `get` and `status` always agree.

## Dependency graph

- Task 1 (test runner) gates every other task: each later task adds a new suite that must ride the runner baseline.
- Tasks 3, 4, 5, 6, and 7 depend only on Task 1 and touch mutually disjoint files, so all five run in parallel once Task 1 is done.
- Task 2 additionally depends on Task 3: its acceptance test uses `scripts/tracker.sh` as the `cmp` baseline for drift detection, and Task 3 rewrites that file, so running them in parallel in a shared tree can flake the comparison.

```
Task 1 ──┬── Task 3 (tracker.sh limit) ──── Task 2 (setup.sh distribution)
         ├── Task 4 (migrate-tracker empty label)
         ├── Task 5 (loop-auto fallback)
         ├── Task 6 (handoff skill + test)
         └── Task 7 (README wording)
```

## Human checkpoints

The brief has zero `[judgment]` criteria, so there are no human checkpoints on content quality.
No step in this plan is destructive or hard to reverse: every change is an in-repo edit under version control, every test runs in a `mktemp` sandbox, and no task calls a live network mutation (the gh calls in tests are stubbed; the one read-only gh behavior check in Task 4 uses `gh issue create --help`, which creates nothing).
The driving session commits each task; a bad task is reverted with `git revert` or `git checkout`.

## How to run

Run the whole suite (the end artifact; exits 0 only when every suite passes, and requires an authenticated gh CLI because `tests/repo-state/live.sh` asserts this repo's live state):

```sh
bash tests/run.sh
```

On a fresh clone, stand up the gitignored mirrors once first, or `tests/repo-state/live.sh` fails on the missing `ISSUES.md`/`BACKLOG.md`:

```sh
scripts/gen-mirrors.sh .
```

Without an authenticated gh CLI the runner reports `tests/repo-state/live.sh` as `SKIP:` (not a failure), so an offline run can still go green.

Rollout note: this plan makes fresh setups correct, but every already-set-up target repo still lacks `scripts/graduate-parking.sh` until `skills/loop-setup/setup.sh` is re-run there once; that re-run also offers the drift refreshes.

Run a single suite directly:

```sh
bash tests/repo-state/tracker-limit.sh
```

Point the runner at an alternate tests directory (used by the runner's own acceptance test):

```sh
bash tests/run.sh /path/to/tests-root
```

---

### Task 1: Test runner

Depends on: none

**Files (exclusive ownership):**
- Create: `tests/run.sh`
- Test: `tests/run/acceptance.sh`

**Interfaces:**
- Consumes: the existing per-suite scripts under `tests/*/*.sh` (each is a standalone bash script that exits 0 on pass, non-zero on fail).
- Produces: `tests/run.sh [tests-dir]`. With no argument it discovers `tests/*/*.sh` relative to its own directory; with one argument it discovers `<tests-dir>/*/*.sh`. It skips any suite whose basename is `build-fixtures.sh`, and also skips basename `live.sh` (with a printed `SKIP:` line) when `gh auth status` fails, because that suite can then only fail for environmental reasons. It exports `LOOP_REVIEW_SKIP_BEHAVIOR=1` to every suite it runs. It prints a per-suite `PASS:`/`FAIL:` line and a final `ran N suites: P passed, F failed` summary, and exits 0 only when F is 0 (skipped suites count in neither number).

**Acceptance check:** `bash tests/run/acceptance.sh` exits 0 and prints its final `PASS:` line [executed-check]

- [ ] Step 1: Write the failing test at `tests/run/acceptance.sh`:

```bash
#!/usr/bin/env bash
# The runner discovers tests/*/*.sh, fails when any suite fails, excludes build-fixtures.sh,
# and exports LOOP_REVIEW_SKIP_BEHAVIOR=1 to the suites it runs.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
RUN="$REPO/tests/run.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$RUN" ] || fail "tests/run.sh missing or not executable"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/suite" "$TMP/loop-review"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP/suite/ok.sh"
printf '#!/usr/bin/env bash\nexit 1\n' > "$TMP/suite/bad.sh"
# A helper that MUST be excluded: it exits non-zero when run with no argument, so if the runner
# ran it, the all-green case below would wrongly fail.
printf '#!/usr/bin/env bash\n[ $# -ge 1 ] || exit 3\n' > "$TMP/loop-review/build-fixtures.sh"
chmod +x "$TMP"/suite/*.sh "$TMP"/loop-review/*.sh

# Failing probe: with bad.sh present, the runner exits non-zero and names the failing suite.
set +e
out="$(bash "$RUN" "$TMP" 2>&1)"; rc=$?
set -e 2>/dev/null || true
[ "$rc" -ne 0 ] || fail "runner exited 0 despite a failing suite"
printf '%s\n' "$out" | grep -q 'bad.sh' || fail "runner did not name the failing suite bad.sh"

# All-green: remove the failing suite; the runner now exits 0. This also proves build-fixtures.sh
# was excluded, because its bare exit 3 would otherwise fail the run.
rm "$TMP/suite/bad.sh"
bash "$RUN" "$TMP" >/dev/null 2>&1 \
  || fail "runner exited non-zero on an all-passing suite (build-fixtures.sh not excluded?)"

# LOOP_REVIEW_SKIP_BEHAVIOR=1 is exported to the suites the runner runs.
printf '#!/usr/bin/env bash\n[ "${LOOP_REVIEW_SKIP_BEHAVIOR:-0}" = 1 ] || exit 7\n' > "$TMP/suite/env.sh"
chmod +x "$TMP/suite/env.sh"
bash "$RUN" "$TMP" >/dev/null 2>&1 \
  || fail "runner did not export LOOP_REVIEW_SKIP_BEHAVIOR=1 to the suites"

# live.sh is skipped (not failed) when gh auth is unavailable, and runs when auth succeeds.
mkdir -p "$TMP/repo-state"
printf '#!/usr/bin/env bash\nexit 1\n' > "$TMP/repo-state/live.sh"
chmod +x "$TMP/repo-state/live.sh"
FAKEBIN="$(mktemp -d)"; trap 'rm -rf "$TMP" "$FAKEBIN"' EXIT
printf '#!/usr/bin/env bash\nexit 1\n' > "$FAKEBIN/gh"; chmod +x "$FAKEBIN/gh"
out="$(PATH="$FAKEBIN:$PATH" bash "$RUN" "$TMP" 2>&1)" \
  || fail "runner failed although live.sh must be skipped without gh auth"
printf '%s\n' "$out" | grep -q 'SKIP:.*live.sh' \
  || fail "runner did not print a SKIP: line for live.sh without gh auth"
printf '#!/usr/bin/env bash\nexit 0\n' > "$FAKEBIN/gh"
PATH="$FAKEBIN:$PATH" bash "$RUN" "$TMP" >/dev/null 2>&1 \
  && fail "runner passed although authenticated gh means live.sh (exit 1) must run and fail"

echo "PASS: runner discovers tests/*/*.sh, fails on a failing suite, excludes build-fixtures.sh, exports the skip flag, and skips live.sh without gh auth"
```

- [ ] Step 2: Run it - `bash tests/run/acceptance.sh` - expect FAIL with `FAIL: tests/run.sh missing or not executable` (the runner does not exist yet).
- [ ] Step 3: Implement `tests/run.sh` exactly as follows, then `chmod +x tests/run.sh`:

```bash
#!/usr/bin/env bash
# run.sh - discover and run every tests/*/*.sh suite; exit non-zero if any fails.
# Skips helper scripts that are not standalone suites (see SKIP). Exports
# LOOP_REVIEW_SKIP_BEHAVIOR=1 so loop-review's behavioral layer B makes no model calls.
# Usage: tests/run.sh [tests-dir]   (tests-dir defaults to this script's own directory)
set -uo pipefail
ROOT="${1:-$(cd "$(dirname "$0")" && pwd)}"
export LOOP_REVIEW_SKIP_BEHAVIOR=1

# Basenames that are helpers, not standalone suites: build-fixtures.sh needs an argument
# and exits non-zero when run bare.
SKIP="build-fixtures.sh"

# live.sh asserts this repo's live GitHub state; without an authenticated gh CLI it can only
# fail for environmental reasons, so it is skipped (reported, not counted) when auth is absent.
if ! gh auth status >/dev/null 2>&1; then
  SKIP="$SKIP live.sh"
  echo "SKIP: live.sh (no authenticated gh CLI)"
fi

pass=0; fail=0
shopt -s nullglob
for t in "$ROOT"/*/*.sh; do
  base="$(basename "$t")"
  case " $SKIP " in *" $base "*) continue ;; esac
  out="$(bash "$t" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ]; then
    pass=$((pass + 1))
    echo "PASS: $t"
  else
    fail=$((fail + 1))
    printf '%s\n' "$out"
    echo "FAIL: $t (exit $rc)"
  fi
done
echo "ran $((pass + fail)) suites: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
```

- [ ] Step 4: Run it - `bash tests/run/acceptance.sh` - expect PASS ending with `PASS: runner discovers tests/*/*.sh, fails on a failing suite, excludes build-fixtures.sh, exports the skip flag, and skips live.sh without gh auth`.
- [ ] Step 5: Commit:

```sh
git add tests/run.sh tests/run/acceptance.sh
git commit -m "tests: add discovery runner over tests/*/*.sh with skip list"
```

---

### Task 2: setup.sh distribution (install graduate-parking + drift refresh)

Depends on: Task 1, Task 3 (this task's acceptance test reads `scripts/tracker.sh` as its drift baseline, which Task 3 modifies)

**Files (exclusive ownership):**
- Modify: `skills/loop-setup/setup.sh` (add a graduate-parking install block after the tracker install at lines 61-64, and a drift-refresh loop immediately after it)
- Test: `tests/loop-setup/distribution.sh`

**Interfaces:**
- Consumes: `tests/run.sh` from Task 1 (the new suite rides the runner baseline). The existing `ask()` helper in setup.sh (env `LOOP_ASSUME_YES`/`LOOP_ASSUME_NO` then read), and the `REPO`, `GEN`, `TRK` variables already defined in setup.sh.
- Produces: after `skills/loop-setup/setup.sh` runs in a target repo, `scripts/graduate-parking.sh` exists there and is executable (skip-if-exists on first install). On a re-run where any of `scripts/gen-mirrors.sh`, `scripts/tracker.sh`, or `scripts/graduate-parking.sh` differs by content from loop-stack's copy, setup shows a `diff -u` and a data-loss warning (mirroring the `reconcile_config` precedent at setup.sh:124-126), then offers a per-file refresh honoring `LOOP_ASSUME_YES`/`LOOP_ASSUME_NO`, copying the loop-stack copy over on assent and leaving the file untouched on decline. The offer is per-run with no persisted memory, and a non-interactive run with neither env var set declines by default (`ask()` returns no on EOF), so scripted re-runs never overwrite a customized script.

**Acceptance check:** `bash tests/loop-setup/distribution.sh` exits 0 and prints its final `PASS:` line [executed-check]

- [ ] Step 1: Write the failing test at `tests/loop-setup/distribution.sh`:

```bash
#!/usr/bin/env bash
# setup.sh installs graduate-parking.sh into the target repo and refreshes drifted vendored scripts.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SETUP="$REPO/skills/loop-setup/setup.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$SETUP" ] || fail "skills/loop-setup/setup.sh missing or not executable"

# --- criterion 1: fresh local setup installs an executable graduate-parking.sh, and a dry-run
#     graduation of a parking-lot fixture succeeds using the installed copy ---
L="$(mktemp -d)"; trap 'rm -rf "$L"' EXIT
( cd "$L" && git init -q )
( cd "$L" && LOOP_TRACKER_ANSWER=local "$SETUP" </dev/null ) || fail "local setup exited non-zero"
[ -x "$L/scripts/graduate-parking.sh" ] || fail "setup did not install an executable scripts/graduate-parking.sh"

cat > "$L/brief.md" <<'EOS'
# Brief

## Parking lot

- Add a widget cache. Restart context: revisit after the v2 cutover.
EOS
grad_out="$( cd "$L" && GRADUATE_DRY_RUN=1 ./scripts/graduate-parking.sh brief.md )" \
  || fail "dry-run graduation via the installed script exited non-zero"
printf '%s\n' "$grad_out" | grep -q "Add a widget cache" \
  || fail "dry-run graduation did not emit a create command for the parked item"

# --- criterion 5: on a re-run, a drifted vendored script is detected and an assented refresh
#     restores it; declining leaves the drift in place ---
# Drift the installed tracker.sh, then re-run setup with assent -> file is restored to loop-stack's copy.
printf '\n# LOCAL DRIFT MARKER\n' >> "$L/scripts/tracker.sh"
cmp -s "$L/scripts/tracker.sh" "$REPO/scripts/tracker.sh" \
  && fail "test setup error: drift marker did not change tracker.sh"
( cd "$L" && LOOP_ASSUME_YES=1 "$SETUP" </dev/null ) || fail "re-run (assent) setup exited non-zero"
cmp -s "$L/scripts/tracker.sh" "$REPO/scripts/tracker.sh" \
  || fail "assented refresh did not restore scripts/tracker.sh to loop-stack's copy"

# Drift again, re-run with decline -> the drift stays (file NOT restored).
printf '\n# LOCAL DRIFT MARKER 2\n' >> "$L/scripts/tracker.sh"
( cd "$L" && LOOP_ASSUME_NO=1 "$SETUP" </dev/null ) || fail "re-run (decline) setup exited non-zero"
cmp -s "$L/scripts/tracker.sh" "$REPO/scripts/tracker.sh" \
  && fail "declined refresh wrongly overwrote scripts/tracker.sh"
grep -q 'LOCAL DRIFT MARKER 2' "$L/scripts/tracker.sh" \
  || fail "declined refresh did not leave the drifted file untouched"

echo "PASS: setup installs graduate-parking.sh, dry-run graduation works, drift refresh assents and declines correctly"
```

- [ ] Step 2: Run it - `bash tests/loop-setup/distribution.sh` - expect FAIL with `FAIL: setup did not install an executable scripts/graduate-parking.sh`.
- [ ] Step 3: Implement in `skills/loop-setup/setup.sh`. Immediately after the existing tracker install block (the `if [ ! -f scripts/tracker.sh ]; then ... fi` ending at line 64), insert:

```bash
GRAD="$REPO/scripts/graduate-parking.sh"
[ -x "$GRAD" ] || fail "graduate-parking.sh not found or not executable: $GRAD"
if [ ! -f scripts/graduate-parking.sh ]; then
  mkdir -p scripts; cp "$GRAD" scripts/graduate-parking.sh && chmod +x scripts/graduate-parking.sh
  echo "installed scripts/graduate-parking.sh"
fi

# Refresh vendored scripts that have drifted from loop-stack's current copies (content compare via
# cmp -s, no version stamps). Each drifted file is offered on its own; declining leaves it untouched.
for pair in "gen-mirrors.sh:$GEN" "tracker.sh:$TRK" "graduate-parking.sh:$GRAD"; do
  name="${pair%%:*}"; src="${pair#*:}"
  [ -f "scripts/$name" ] || continue
  cmp -s "scripts/$name" "$src" && continue
  echo "scripts/$name differs from loop-stack's current copy"
  diff -u "scripts/$name" "$src" || true
  echo "note: accepting REPLACES scripts/$name with loop-stack's copy; any local edits shown above are lost."
  if ask "refresh scripts/$name from loop-stack?"; then
    cp "$src" "scripts/$name" && chmod +x "scripts/$name" && echo "refreshed scripts/$name"
  else
    echo "left scripts/$name unchanged"
  fi
done
```

- [ ] Step 4: Run it - `bash tests/loop-setup/distribution.sh` - expect PASS ending with `PASS: setup installs graduate-parking.sh, dry-run graduation works, drift refresh assents and declines correctly`.
- [ ] Step 5: Commit:

```sh
git add skills/loop-setup/setup.sh tests/loop-setup/distribution.sh
git commit -m "loop-setup: install graduate-parking.sh and offer drift refresh for vendored scripts"
```

---

### Task 3: tracker.sh github list limit

Depends on: Task 1

**Files (exclusive ownership):**
- Modify: `scripts/tracker.sh` line 142 (the `gh issue list` invocation in the github branch of the `list` command)
- Test: `tests/repo-state/tracker-limit.sh`

**Interfaces:**
- Consumes: `tests/run.sh` from Task 1.
- Produces: `scripts/tracker.sh list` in github mode invokes `gh issue list` with `--limit 1000` so the result is not capped at gh's default 30-issue page.

**Acceptance check:** `bash tests/repo-state/tracker-limit.sh` exits 0 and prints its final `PASS:` line [executed-check]

- [ ] Step 1: Write the failing test at `tests/repo-state/tracker-limit.sh`:

```bash
#!/usr/bin/env bash
# tracker.sh list (github mode) passes --limit 1000 so it fetches past gh's default 30-issue page.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
TRK="$REPO/scripts/tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$TRK" ] || fail "scripts/tracker.sh missing or not executable"

TMP="$(mktemp -d)"; BIN="$(mktemp -d)"; trap 'rm -rf "$TMP" "$BIN"' EXIT
mkdir -p "$TMP/config"
printf 'tracker: github\n' > "$TMP/config/repo-state.md"

CALLS="$BIN/gh.calls"
cat > "$BIN/gh" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$CALLS"
case "\$1" in
  auth)  exit 0 ;;
  issue) [ "\$2" = list ] && { echo "[]"; exit 0; }; exit 0 ;;
esac
exit 0
EOF
chmod +x "$BIN/gh"

( cd "$TMP" && PATH="$BIN:$PATH" bash "$TRK" list ) >/dev/null || fail "tracker.sh list (github) exited non-zero"
grep -q 'issue list' "$CALLS" || fail "tracker.sh list did not call gh issue list"
grep -q -- '--limit 1000' "$CALLS" \
  || fail "tracker.sh list did not pass --limit 1000 (capped at gh's default 30-issue page)"

echo "PASS: tracker.sh list passes --limit 1000 in github mode"
```

- [ ] Step 2: Run it - `bash tests/repo-state/tracker-limit.sh` - expect FAIL with `FAIL: tracker.sh list did not pass --limit 1000 (capped at gh's default 30-issue page)`.
- [ ] Step 3: Implement in `scripts/tracker.sh`. Change line 142 from:

```bash
      gh issue list --state open --json number,title,labels,updatedAt
```

to:

```bash
      gh issue list --state open --limit 1000 --json number,title,labels,updatedAt
```

- [ ] Step 4: Run it - `bash tests/repo-state/tracker-limit.sh` - expect PASS ending with `PASS: tracker.sh list passes --limit 1000 in github mode`.
- [ ] Step 5: Commit:

```sh
git add scripts/tracker.sh tests/repo-state/tracker-limit.sh
git commit -m "tracker: fetch up to 1000 issues in list so it is not capped at 30"
```

---

### Task 4: migrate-tracker.sh empty label

Depends on: Task 1

**Files (exclusive ownership):**
- Modify: `scripts/migrate-tracker.sh` (the dry-run print at lines 56-58 and the real create at line 60)
- Test: `tests/repo-state/migrate-unlabeled.sh`

**Interfaces:**
- Consumes: `tests/run.sh` from Task 1. The existing `MIGRATE_DRY_RUN=1` behavior and the frontmatter reader `fm`.
- Produces: when a local issue's `labels:` frontmatter is empty, `scripts/migrate-tracker.sh` emits and runs a `gh issue create` with NO `--label` argument at all (never `--label ''`). Issues that do carry labels keep their `--label` argument unchanged.
- Scope note: migrate-tracker.sh is a loop-stack-central one-shot tool, never vendored into target repos by setup.sh, so this fix is verified only in this repo.

**Acceptance check:** `bash tests/repo-state/migrate-unlabeled.sh` exits 0 and prints its final `PASS:` line [executed-check]

- [ ] Step 1: Write the failing test at `tests/repo-state/migrate-unlabeled.sh`:

```bash
#!/usr/bin/env bash
# migrate-tracker.sh omits --label entirely for an unlabeled local issue, and keeps it for a labeled one.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
M="$REPO/scripts/migrate-tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$M" ] || fail "scripts/migrate-tracker.sh missing or not executable"

SB="$(mktemp -d)"; trap 'rm -rf "$SB"' EXIT
mkdir -p "$SB/docs/issues" "$SB/config"
printf 'tracker: local\n' > "$SB/config/repo-state.md"
# Unlabeled issue: the Issues lane's defined shape (empty labels:).
cat > "$SB/docs/issues/001-unlabeled.md" <<'EOS'
---
number: 1
title: unlabeled issue
labels:
state: open
updated: 2026-08-04T00:00:00Z
---
An issue with no labels.
EOS
# Labeled issue: proves the fix is selective, not a blanket drop of --label.
cat > "$SB/docs/issues/002-labeled.md" <<'EOS'
---
number: 2
title: labeled issue
labels: bug
state: open
updated: 2026-08-04T00:00:00Z
---
An issue with a label.
EOS

out="$( cd "$SB" && MIGRATE_DRY_RUN=1 bash "$M" )" || fail "migrate dry-run exited non-zero"
# The unlabeled issue's create line must carry no --label at all.
un_line="$(printf '%s\n' "$out" | grep 'gh issue create' | grep 'unlabeled issue')"
[ -n "$un_line" ] || fail "no create line emitted for the unlabeled issue"
printf '%s\n' "$un_line" | grep -q -- '--label' \
  && fail "unlabeled issue create still carries a --label argument"
# The labeled issue keeps its --label.
lb_line="$(printf '%s\n' "$out" | grep 'gh issue create' | grep 'labeled issue')"
printf '%s\n' "$lb_line" | grep -q -- "--label 'bug'" \
  || fail "labeled issue lost its --label 'bug' argument"

echo "PASS: migrate-tracker omits --label for unlabeled issues and preserves it for labeled ones"
```

- [ ] Step 2: Run it - `bash tests/repo-state/migrate-unlabeled.sh` - expect FAIL with `FAIL: unlabeled issue create still carries a --label argument`.
- [ ] Step 3: First verify gh's empty-label behavior read-only (no issue is created): run `gh issue create --help` and confirm it documents `-l, --label name`, i.e. `--label` expects a label name value, so passing `""` targets an empty-named label. Then implement in `scripts/migrate-tracker.sh`. Replace the dry-run print block at lines 56-58:

```bash
  if [ "$DRY" = 1 ]; then
    printf "gh issue create --title '%s' --label '%s' --body <migrated body of local #%s>\n" "$title" "$labels" "$num"
    [ "$state" = closed ] && printf "gh issue close <new #> (local #%s was closed)\n" "$num"
```

with:

```bash
  if [ "$DRY" = 1 ]; then
    if [ -n "$labels" ]; then
      printf "gh issue create --title '%s' --label '%s' --body <migrated body of local #%s>\n" "$title" "$labels" "$num"
    else
      printf "gh issue create --title '%s' --body <migrated body of local #%s>\n" "$title" "$num"
    fi
    [ "$state" = closed ] && printf "gh issue close <new #> (local #%s was closed)\n" "$num"
```

and replace the real create at line 60:

```bash
    url="$(gh issue create --title "$title" --label "$labels" --body "$body")" \
      || fail "gh issue create failed for local #$num ($title)"
```

with:

```bash
    if [ -n "$labels" ]; then
      url="$(gh issue create --title "$title" --label "$labels" --body "$body")" \
        || fail "gh issue create failed for local #$num ($title)"
    else
      url="$(gh issue create --title "$title" --body "$body")" \
        || fail "gh issue create failed for local #$num ($title)"
    fi
```

- [ ] Step 4: Run it - `bash tests/repo-state/migrate-unlabeled.sh` - expect PASS ending with `PASS: migrate-tracker omits --label for unlabeled issues and preserves it for labeled ones`.
- [ ] Step 5: Commit:

```sh
git add scripts/migrate-tracker.sh tests/repo-state/migrate-unlabeled.sh
git commit -m "migrate-tracker: omit --label when a local issue is unlabeled"
```

---

### Task 5: loop-auto.sh keyless fallback

Depends on: Task 1

**Files (exclusive ownership):**
- Modify: `skills/loop-auto/loop-auto.sh` line 37 (the last line of `cmd_get`)
- Test: `tests/gates/loop-auto-keyless.sh`

**Interfaces:**
- Consumes: `tests/run.sh` from Task 1. The existing `repo_default` function in loop-auto.sh.
- Produces: `loop-auto.sh get` returns the committed repo default (via `repo_default`) when `docs/chain-state.md` exists but contains no `autonomy:` key, matching what `loop-auto.sh status` already reports for that same state.

**Acceptance check:** `bash tests/gates/loop-auto-keyless.sh` exits 0 and prints its final `PASS:` line [executed-check]

- [ ] Step 1: Write the failing test at `tests/gates/loop-auto-keyless.sh`:

```bash
#!/usr/bin/env bash
# get and status agree when docs/chain-state.md exists but has no autonomy: key and the repo default is auto.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
LA="$REPO/skills/loop-auto/loop-auto.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$LA" ] || fail "skills/loop-auto/loop-auto.sh missing or not executable"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/config" "$TMP/docs"
# committed repo default is auto
printf '# Repo State Map\nautonomy-default: auto\n' > "$TMP/config/repo-state.md"
# chain-state present but WITHOUT an autonomy: key (a keyless runtime file)
printf 'generated: 2026-08-08T00:00:00Z\n' > "$TMP/docs/chain-state.md"

got="$( cd "$TMP" && "$LA" get )"
[ "$got" = "auto" ] \
  || fail "keyless chain-state: get returned '$got', not the committed default 'auto'"

st="$( cd "$TMP" && "$LA" status )"
echo "$st" | grep -qi 'auto' \
  || fail "keyless chain-state: status did not report the effective mode auto"

# get and status must agree on the effective mode for the same keyless state.
echo "$st" | grep -qi "$got" \
  || fail "get ('$got') and status ('$st') disagree on the keyless-chain-state effective mode"

echo "PASS: get and status agree (both auto) on a keyless chain-state with an auto repo default"
```

- [ ] Step 2: Run it - `bash tests/gates/loop-auto-keyless.sh` - expect FAIL with `FAIL: keyless chain-state: get returned 'pause', not the committed default 'auto'`.
- [ ] Step 3: Implement in `skills/loop-auto/loop-auto.sh`. Change line 37 from:

```bash
    [ -n "$v" ] && echo "$v" || echo "pause"
```

to:

```bash
    [ -n "$v" ] && echo "$v" || repo_default
```

- [ ] Step 4: Run it - `bash tests/gates/loop-auto-keyless.sh` - expect PASS ending with `PASS: get and status agree (both auto) on a keyless chain-state with an auto repo default`.
- [ ] Step 5: Commit:

```sh
git add skills/loop-auto/loop-auto.sh tests/gates/loop-auto-keyless.sh
git commit -m "loop-auto: get falls back to repo default on a keyless chain-state so get and status agree"
```

---

### Task 6: handoff non-conforming fallback (skill + its test)

Depends on: Task 1

**Files (exclusive ownership):**
- Modify: `skills/handoff/SKILL.md` line 12; `tests/handoff/location.sh` line 12
- Test: `tests/handoff/location.sh` (the same file that is modified; it is this task's acceptance suite)

**Interfaces:**
- Consumes: `tests/run.sh` from Task 1.
- Produces: `skills/handoff/SKILL.md` directs a handoff in a repo WITHOUT `config/repo-state.md` to `docs/handoffs/` inside that project, created on demand, and no longer names the OS temp directory. `tests/handoff/location.sh` asserts the in-project fallback and asserts the temp fallback is gone.

**Acceptance check:** `bash tests/handoff/location.sh` exits 0 and prints its final `PASS:` line [executed-check]

- [ ] Step 1: Edit the test `tests/handoff/location.sh`. Replace line 12:

```bash
grep -qi 'temp'               "$SKILL" || fail "handoff dropped the OS-temp-dir fallback"
```

with these two lines:

```bash
grep -qi 'temp'               "$SKILL" && fail "handoff still names the OS-temp-dir fallback (must land in-project)"
grep -qi 'non-conforming\|created on demand\|create .*docs/handoffs' "$SKILL" || fail "handoff does not name the in-project fallback for a repo without config/repo-state.md"
```

Also update the header comment on line 2 from:

```bash
# handoff is location-aware: names the in-repo home for conforming repos AND the OS-temp fallback.
```

to:

```bash
# handoff is location-aware: names the in-repo home for conforming repos AND the in-project fallback.
```

- [ ] Step 2: Run it - `bash tests/handoff/location.sh` - expect FAIL with `FAIL: handoff still names the OS-temp-dir fallback (must land in-project)` (the current SKILL still says temp).
- [ ] Step 3: Implement in `skills/handoff/SKILL.md`. Replace line 12:

```
Otherwise, save to the OS temp directory of the user's OS - not the current workspace.
```

with:

```
Otherwise this is a non-conforming repo: create `docs/handoffs/` inside the project on demand and write the handoff to `docs/handoffs/YYYY-MM-DD-<slug>.md` there, never outside the project.
```

- [ ] Step 4: Run it - `bash tests/handoff/location.sh` - expect PASS ending with `PASS: handoff is location-aware, mirror-refreshing, and kept its content rules`.
- [ ] Step 5: Commit:

```sh
git add skills/handoff/SKILL.md tests/handoff/location.sh
git commit -m "handoff: land non-conforming-repo handoffs in docs/handoffs/, not the OS temp dir"
```

---

### Task 7: README loop-improve selection wording

Depends on: Task 1

**Files (exclusive ownership):**
- Modify: `README.md` line 35 and line 75
- Test: `tests/readme/selection.sh`

**Interfaces:**
- Consumes: `tests/run.sh` from Task 1.
- Produces: no line of `README.md` describes loop-improve selection as a single finding; both the layer table (line 35) and the repo-layout block (line 75) describe selection as multi-finding into one brief.

**Acceptance check:** `bash tests/readme/selection.sh` exits 0 and prints its final `PASS:` line [executed-check]

- [ ] Step 1: Write the failing test at `tests/readme/selection.sh`:

```bash
#!/usr/bin/env bash
# README describes loop-improve selection as multi-finding into one brief, never as a single finding.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
RM="$REPO/README.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$RM" ] || fail "README.md missing"

grep -qi 'one finding' "$RM" && fail "README still describes loop-improve selection as a single finding"
grep -qi 'converge the findings the user selects\|converge selected findings' "$RM" \
  || fail "README does not describe loop-improve selection as multi-finding into a brief"

echo "PASS: README describes loop-improve selection as multi-finding"
```

- [ ] Step 2: Run it - `bash tests/readme/selection.sh` - expect FAIL with `FAIL: README still describes loop-improve selection as a single finding`.
- [ ] Step 3: Implement in `README.md`. Change line 35 from:

```
|             |                   | overlap; converge the one finding the user picks into a brief for /loop-plan.  |
```

to:

```
|             |                   | overlap; converge the findings the user selects into a brief for /loop-plan.   |
```

and change line 75 from:

```
skills/loop-improve/     Audit skill: read-only repo survey, converge one finding into a brief for /loop-plan
```

to:

```
skills/loop-improve/     Audit skill: read-only repo survey, converge selected findings into a brief for /loop-plan
```

- [ ] Step 4: Run it - `bash tests/readme/selection.sh` - expect PASS ending with `PASS: README describes loop-improve selection as multi-finding`.
- [ ] Step 5: Commit:

```sh
git add README.md tests/readme/selection.sh
git commit -m "readme: describe loop-improve selection as multi-finding into one brief"
```
