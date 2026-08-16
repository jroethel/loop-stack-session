# loop-setup Reconcile Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its acceptance check passes. No specific tooling, harness, or skills are assumed.

**Goal:** Make loop-setup and migrate-tracker reconcile a repo that already carries state - stale config, importable issue files, migration residue, scratch byproducts - instead of assuming a greenfield repo.
**Approach:** Extend the existing surfaces rather than add a new concept for target repos to carry.
`skills/loop-setup/setup.sh` gains detect-and-offer reconcile steps (stale-config diff and re-render, issue import, tidy inventory) and `scripts/migrate-tracker.sh` gains a state-freeze plus a removal offer.
One entry point per surface, every gap lands in the existing `tests/` harness, and every action is offered with a preview and never fired without acceptance.
**Tech stack:** bash, awk/sed, git, gh (github mode only).
**Source brief:** docs/briefs/2026-08-07-loop-setup-reconcile-brief.md

## Global constraints

- No `jq`; parse frontmatter and JSON with grep/sed/awk only, matching the existing scripts.
- Portable awk/sed only: no gawk-only or GNU-sed-only features, no `sed -i`, no in-place rewrites without a `mktemp` temp file.
- Every script starts `set -uo pipefail` and defines its own `fail()`; do not rely on `set -e`.
- Under `set -u`, never expand a possibly-empty array bare; guard with a count check or the `${arr[@]+"${arr[@]}"}` form (bash 3.2 aborts otherwise).
- Every offer reads a `y`/`n` answer via one shared contract: `LOOP_ASSUME_YES=1` forces yes, `LOOP_ASSUME_NO=1` forces no, otherwise read one line from stdin and treat EOF or any non-`y` answer as no.
- `LOOP_ASSUME_YES`/`LOOP_ASSUME_NO` are global and all-or-nothing: they answer every offer in the run the same way (config re-render, each import, each `.scratch` deletion, the migration `git rm`), so interactive per-item control requires leaving them unset.
- Every action is offered with a printed preview and never fired without acceptance; nothing is deleted, removed, or overwritten silently.
- House markdown style in any file this plan writes: one sentence per line, plain dashes only (never the em-dash character), aligned table pipes.

## Dependency graph

Tasks 1 -> 2 -> 3 form a strict chain because all three modify `skills/loop-setup/setup.sh` (exclusive ownership is enforced by ordering, never by parallelism).
Task 4 modifies only `scripts/migrate-tracker.sh` and its test, shares no file with the chain, and runs parallel to it.

```
Task 1 (config reconcile + render fix + template stamp)
   -> Task 2 (issue import + --scan flag)
        -> Task 3 (tidy script + tidy wiring)
Task 4 (migrate freeze + git-rm offer)   [parallel to the whole chain]
```

## Human checkpoints

The brief has no `[judgment]` criteria; all six acceptance checks are executed checks.
The only human-fired steps are the irreversible offers, which the tooling stages but the operator triggers by answering `y`: the config re-render (`reconcile_config`), each issue import, each `.scratch` deletion (`scripts/tidy.sh`), and the `git rm` of migrated ledger files (`scripts/migrate-tracker.sh`).
Tests drive every one of these non-interactively via `LOOP_ASSUME_YES` / `LOOP_ASSUME_NO`, so no test blocks on a prompt.

## How to run

```
bash tests/loop-setup/reconcile.sh
bash tests/loop-setup/import.sh
bash tests/loop-setup/tidy.sh
bash tests/repo-state/migrate.sh
bash tests/loop-setup/acceptance.sh
bash tests/repo-state/local-workflow.sh
```

The last two are the pre-existing suites; they must stay green (Task 1 relies on the offer defaulting to no on stdin EOF, which preserves their legacy-config assertions byte-for-byte).

---

### Task 1: Config reconcile, render fix, and template version stamp

Depends on: none

**Files (exclusive ownership):**
- Modify: `config/repo-state.template.md` (add a `template-version: 1` line-anchored key)
- Modify: `skills/loop-setup/setup.sh` (add `ask()` and `version_of()` helpers; edit `render_github`; add `reconcile_config()`; add its call site)
- Test: `tests/loop-setup/reconcile.sh`

**Interfaces:**
- Consumes: existing `render_github(url)` and `render_local()` functions, the `$TPL` and `$MODE` and `$remote_url` variables already defined in setup.sh, and the `Remote:` line format in a rendered config.
- Produces:
  - A `template-version: N` line-anchored key in the template and in both rendered configs (starts at `1`).
  - `ask "<prompt>"` -> returns 0 for yes, 1 for no; honors `LOOP_ASSUME_YES=1` (all yes), `LOOP_ASSUME_NO=1` (all no), else reads one stdin line, EOF or non-`y` = no. Reused by Task 2.
  - `version_of <file>` -> prints the file's `template-version` value or empty string.
  - `reconcile_config` -> compares the config's stamp to the template's; on mismatch or absent stamp it prints a `diff` and offers a re-render that preserves the declared mode and remote; a current config prints nothing.

**Acceptance check:** `bash tests/loop-setup/reconcile.sh` exits 0 `[executed-check]` (maps success criteria 1 and 5, plus config-level idempotency for 6).

- [ ] Step 1: Write the failing test.

VERBATIM `tests/loop-setup/reconcile.sh`:

```bash
#!/usr/bin/env bash
# Reconcile: stale/keyless config re-render (criterion 1) and github render drops the
# dangling Local-tracker reference (criterion 5); a current config is a no-op (idempotency).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SETUP="$REPO/skills/loop-setup/setup.sh"
FIX="$REPO/tests/repo-state/fixtures/issues.json"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$SETUP" ] || fail "setup.sh missing"

# --- reference: a clean local setup carries the current template-version ---
REF="$(mktemp -d)"; trap 'rm -rf "$REF"' EXIT
( cd "$REF" && git init -q && LOOP_TRACKER_ANSWER=local "$SETUP" </dev/null >/dev/null ) \
  || fail "reference local setup failed"
grep -q '^template-version:' "$REF/config/repo-state.md" \
  || fail "fresh local config carries no template-version stamp"

# --- criterion 1: a keyless/older config is detected; decline = byte-identical, accept = current render ---
S="$(mktemp -d)"; trap 'rm -rf "$REF" "$S"' EXIT
( cd "$S" && git init -q )
mkdir -p "$S/config"
# legacy config: has the tracker key (mode is not re-asked) but NO template-version stamp
printf 'old legacy body, hand notes\ntracker: local\n' > "$S/config/repo-state.md"

# decline (LOOP_ASSUME_NO) leaves the file byte-identical
before="$(cat "$S/config/repo-state.md")"
( cd "$S" && LOOP_ASSUME_NO=1 "$SETUP" </dev/null >/dev/null ) || fail "declined reconcile exited non-zero"
after="$(cat "$S/config/repo-state.md")"
[ "$before" = "$after" ] || fail "declined reconcile changed the config (must be byte-identical)"

# accept (LOOP_ASSUME_YES) re-renders to match a fresh render of the current template
( cd "$S" && LOOP_ASSUME_YES=1 "$SETUP" </dev/null >/dev/null ) || fail "accepted reconcile exited non-zero"
diff "$REF/config/repo-state.md" "$S/config/repo-state.md" \
  || fail "accepted re-render does not match the current fresh render"

# a config already at the current version reports nothing
out="$( cd "$S" && "$SETUP" </dev/null )" || fail "third run errored"
printf '%s\n' "$out" | grep -qi 'stale' && fail "config already current still reported as stale"
[ "$(grep -c '^tracker:' "$S/config/repo-state.md")" -eq 1 ] || fail "reconcile duplicated the tracker key"

# --- criterion 5: github render carries no reference to the stripped Local tracker section ---
G="$(mktemp -d)"; trap 'rm -rf "$REF" "$S" "$G"' EXIT
( cd "$G" && git init -q && git remote add origin https://github.com/acme/x.git )
( cd "$G" && LOOP_TRACKER_ANSWER=github MIRRORS_JSON_FILE="$FIX" "$SETUP" --dry-run-remote </dev/null >/dev/null ) \
  || fail "github setup errored"
grep -qi 'Local tracker' "$G/config/repo-state.md" \
  && fail "github config still references the Local tracker section"
grep -q '^template-version:' "$G/config/repo-state.md" \
  || fail "github config carries no template-version stamp"

echo "PASS: reconcile - stale/keyless detect+re-render (criterion 1), github render drops Local-tracker (criterion 5), current config is a no-op"
```

- [ ] Step 2: Run it - `bash tests/loop-setup/reconcile.sh` - expect FAIL with "fresh local config carries no template-version stamp" (the stamp and reconcile do not exist yet).
- [ ] Step 3: Implement against the contract.

  a. In `config/repo-state.template.md`, add a standalone line-anchored key `template-version: 1` immediately above the `Remote: {{REMOTE_OR_FALLBACK}}` line (keep a blank line on each side).
  It is a generic line, so both existing render functions copy it through unchanged.

  b. In `skills/loop-setup/setup.sh`, add these helpers just after the existing `fail()` definition:

  ```bash
  ask() {   # $1 = prompt; 0 = yes, 1 = no. Env-then-read, mirroring determine_mode.
    [ "${LOOP_ASSUME_YES:-0}" = 1 ] && return 0
    [ "${LOOP_ASSUME_NO:-0}"  = 1 ] && return 1
    local a; printf '%s [y/N]: ' "$1" >&2; read -r a || return 1
    case "$a" in [yY]*) return 0;; *) return 1;; esac
  }
  version_of() { grep -E '^template-version:' "$1" 2>/dev/null | head -1 \
    | sed -E 's/^template-version:[[:space:]]*//; s/[[:space:]]*$//'; }
  ```

  c. Edit `render_github` so the dangling intro clause is dropped.
  Add this rule inside its awk program, before the final `{ if (skip) next; print }` rule (decision: fixes cosmetic gap 5, which rides this render path):

  ```awk
  index($0, "the Local tracker section governs local mode") {
    print "The tracker backend (github or local) is declared in the `tracker:` key below."
    next
  }
  ```

  This leaves the github-rendered config with no occurrence of the string "Local tracker" (the `## Local tracker` heading and body are already stripped by the existing `skip` logic).

  d. Add `reconcile_config()`:

  ```bash
  reconcile_config() {   # offer a re-render when the config's template-version differs from the template's
    [ -f config/repo-state.md ] || return 0
    local tv cv cand remote
    tv="$(version_of "$TPL")"
    cv="$(version_of config/repo-state.md)"
    [ "$cv" = "$tv" ] && return 0                 # already current -> report nothing
    if [ "$MODE" = github ]; then
      remote="$(grep -E '^Remote:' config/repo-state.md | head -1 | sed -E 's/^Remote:[[:space:]]*//')"
      [ -n "$remote" ] || remote="$remote_url"    # fall back to the detected remote when the config has no Remote: line
      cand="$(render_github "$remote")"
    else
      cand="$(render_local)"
    fi
    cand="$cand"$'\n'"tracker: $MODE"             # mirror tracker.sh mode set's appended key
    echo "config/repo-state.md is stale (template-version '${cv:-none}' vs '$tv'); proposed re-render:"
    diff -u config/repo-state.md <(printf '%s\n' "$cand") || true
    echo "note: accepting REPLACES the whole file with the render above; any hand edits not shown as kept are lost."
    if ask "re-render config/repo-state.md to template-version $tv (preserving mode $MODE)?"; then
      printf '%s\n' "$cand" > config/repo-state.md
      echo "re-rendered config/repo-state.md (template-version $tv)"
    else
      echo "left config/repo-state.md unchanged"
    fi
  }
  ```

  The re-render reproduces the fresh-setup sequence (render then append `tracker: <mode>`), so an accepted re-render is byte-identical to a fresh render of the current template; a decline never touches the file, so it stays byte-identical to the original.

  e. Insert the call site immediately after the mode-establishment `if/else/fi` block (the block ending at the line `fi` after `scripts/tracker.sh mode set "$MODE"`), before `ensure_roadmap`:

  ```bash
  reconcile_config
  ```

  Compatibility note: because `ask` returns no on stdin EOF, the existing `tests/loop-setup/acceptance.sh` legacy-config cases (which pass `</dev/null` and set no `LOOP_ASSUME_*`) decline the re-render and keep their configs byte-identical, so they stay green.

- [ ] Step 4: Run it - `bash tests/loop-setup/reconcile.sh` - expect PASS.
      Also run `bash tests/loop-setup/acceptance.sh` and `bash tests/repo-state/local-workflow.sh` - both expect PASS (no regression).
- [ ] Step 5: Commit.

  ```
  git add config/repo-state.template.md skills/loop-setup/setup.sh tests/loop-setup/reconcile.sh
  git commit -m "loop-setup: detect stale/keyless config and offer a re-render; version-stamp the template; drop dangling Local-tracker line in github render"
  ```

---

### Task 2: Issue import from standard and user-supplied roots

Depends on: Task 1

**Files (exclusive ownership):**
- Modify: `skills/loop-setup/setup.sh` (replace the argument parse; add `reconcile_import()` with its `is_excluded`/`is_candidate` helpers; add its call site)
- Test: `tests/loop-setup/import.sh`

**Interfaces:**
- Consumes: `ask()` from Task 1; the installed `scripts/tracker.sh create --label L --title T --body B` seam (prints the new issue number); `$MODE`.
- Produces:
  - A repeatable `--scan <dir>` flag on setup.sh, collected into a `SCAN_ROOTS` array, coexisting with `--dry-run-remote`.
  - `reconcile_import` (local mode only): recursively scans standard roots plus `SCAN_ROOTS`, offers each candidate `.md` for import, and creates an accepted candidate as a tracker issue; title and label come from frontmatter (`title:`/`labels:`) for a frontmatter-shaped file, else from the `# ` H1 and `Label:` line of a prose file, with the old frontmatter stripped from the body.

**Acceptance check:** `bash tests/loop-setup/import.sh` exits 0 `[executed-check]` (maps success criterion 2).

- [ ] Step 1: Write the failing test.

VERBATIM `tests/loop-setup/import.sh`:

```bash
#!/usr/bin/env bash
# Import (criterion 2): local-mode setup scans standard + --scan roots, offers each
# issue-shaped/keyword .md for import, infers the label, and never lists excluded dirs.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SETUP="$REPO/skills/loop-setup/setup.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$SETUP" ] || fail "setup.sh missing"

# ---------- scenario A: accept-all imports every candidate, skips every excluded path ----------
A="$(mktemp -d)"; EXTRA="$(mktemp -d)"; trap 'rm -rf "$A" "$EXTRA"' EXIT
( cd "$A" && git init -q )

# a live tracker issue already exists (its home docs/issues/ is excluded from the scan)
mkdir -p "$A/docs/issues"
cat > "$A/docs/issues/001-live.md" <<'EOS'
---
number: 1
title: live issue
labels: bug
state: open
updated: 2026-08-04T00:00:00Z
---
MARKER_LIVE body
EOS

# candidates in each standard root
mkdir -p "$A/docs/plans" "$A/.planning" "$A/.ralph" "$A/.scratch/old/issues"
cat > "$A/docs/plans/big-plan.md" <<'EOS'
# Big plan
Label: idea
MARKER_PLAN
EOS
cat > "$A/docs/notes.md" <<'EOS'
# Some notes
Status: open
MARKER_NOTES
EOS
printf '# Next up\nMARKER_NEXT\n'   > "$A/.planning/next.md"
printf '# Todo list\nMARKER_TODO\n' > "$A/.ralph/todo.md"
cat > "$A/.scratch/old/issues/001-fix-thing.md" <<'EOS'
# Fix the thing
Label: bug
MARKER_SCRATCH
EOS
# a frontmatter-shaped prior-local issue (no # H1, no Label: line - title/labels live in frontmatter)
cat > "$A/.scratch/old/issues/002-frontmatter.md" <<'EOS'
---
number: 7
title: Frontmatter issue title
labels: idea
state: open
updated: 2026-08-04T00:00:00Z
---
MARKER_FM body content
EOS
printf '# Extra root issue\nMARKER_EXTRA\n' > "$EXTRA/extra-plan.md"

# excluded paths that WOULD be candidates but must never be listed
mkdir -p "$A/docs/handoffs" "$A/docs/reviews" "$A/docs/briefs" "$A/docs/archive"
printf '# Handoff plan\nStatus: open\nMARKER_HANDOFF\n'  > "$A/docs/handoffs/h.md"
printf '# Review plan\nStatus: open\nMARKER_REVIEW\n'    > "$A/docs/reviews/r-batch-review.md"
printf '# Brief plan\nStatus: open\nMARKER_BRIEF\n'      > "$A/docs/briefs/b.md"
printf '# Archived plan\nStatus: open\nMARKER_ARCHIVE\n' > "$A/docs/archive/a.md"
printf '# Issues plan\nStatus: open\nMARKER_MIRROR\n'    > "$A/docs/ISSUES.md"

out="$( cd "$A" && LOOP_ASSUME_YES=1 LOOP_TRACKER_ANSWER=local "$SETUP" --scan "$EXTRA" </dev/null )" \
  || fail "import setup (accept-all) errored"

# every candidate landed as a tracker issue
for m in MARKER_PLAN MARKER_NOTES MARKER_NEXT MARKER_TODO MARKER_SCRATCH MARKER_FM MARKER_EXTRA; do
  grep -Rq "$m" "$A/docs/issues/" || fail "candidate $m was not imported into docs/issues/"
done
# label inference: the Label: bug candidate produced a labels: bug issue
grep -Rl 'MARKER_SCRATCH' "$A/docs/issues/" | head -1 | xargs grep -q '^labels: bug' \
  || fail "import did not infer 'bug' from the Label: line"
# frontmatter-shaped candidate: title/labels come from frontmatter, old frontmatter stripped from body
fmfile="$(grep -Rl 'MARKER_FM' "$A/docs/issues/" | head -1)"
[ -n "$fmfile" ] || fail "frontmatter candidate MARKER_FM was not imported"
grep -q '^title: Frontmatter issue title' "$fmfile" || fail "frontmatter title not carried into the imported issue"
grep -q '^labels: idea' "$fmfile"                    || fail "frontmatter labels not inferred into the imported issue"
grep -q '2026-08-04T00:00:00Z' "$fmfile"             && fail "old frontmatter leaked into the imported body"
# a no-label candidate still imports (writes an empty labels: line, no crash)
grep -Rl 'MARKER_NEXT' "$A/docs/issues/" | head -1 | xargs grep -q '^labels:' \
  || fail "no-label candidate did not import with a labels: line"
# excluded content is never imported
for m in MARKER_HANDOFF MARKER_REVIEW MARKER_BRIEF MARKER_ARCHIVE MARKER_MIRROR; do
  grep -Rq "$m" "$A/docs/issues/" && fail "excluded path content $m was wrongly imported"
done
# the live tracker home is not re-imported (MARKER_LIVE still appears in exactly one file)
[ "$(grep -Rl 'MARKER_LIVE' "$A/docs/issues/" | wc -l | tr -d ' ')" -eq 1 ] \
  || fail "live tracker issue was re-imported (duplicated)"

# ---------- scenario B: decline-all imports nothing ----------
B="$(mktemp -d)"; trap 'rm -rf "$A" "$EXTRA" "$B"' EXIT
( cd "$B" && git init -q )
mkdir -p "$B/docs"
printf '# A plan\nLabel: idea\nMARKER_DECLINE\n' > "$B/docs/decline-plan.md"
( cd "$B" && LOOP_ASSUME_NO=1 LOOP_TRACKER_ANSWER=local "$SETUP" </dev/null >/dev/null ) \
  || fail "import setup (decline-all) errored"
grep -Rq 'MARKER_DECLINE' "$B/docs/issues/" 2>/dev/null \
  && fail "declined candidate was imported anyway"

echo "PASS: import - standard + --scan roots offered, labels inferred, excluded dirs never imported, decline skips"
```

- [ ] Step 2: Run it - `bash tests/loop-setup/import.sh` - expect FAIL with "candidate MARKER_PLAN was not imported into docs/issues/" (import does not exist yet), or an "unknown argument: --scan" fail from the current arg parse.
- [ ] Step 3: Implement against the contract.

  a. Replace the current two argument-parse lines:

  ```bash
  DRY_REMOTE=0
  [ "${1:-}" = "--dry-run-remote" ] && DRY_REMOTE=1
  ```

  with a loop that also collects repeatable `--scan` roots:

  ```bash
  DRY_REMOTE=0
  SCAN_ROOTS=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run-remote) DRY_REMOTE=1; shift ;;
      --scan) [ $# -ge 2 ] || fail "--scan requires a directory argument"; SCAN_ROOTS+=("$2"); shift 2 ;;
      *) fail "unknown argument: $1" ;;
    esac
  done
  ```

  b. Add the import function and its helpers (place them with the other function definitions, above the main flow):

  ```bash
  is_excluded() {   # $1 = path; true for the live tracker home, loop-stack's own dirs, and the ALL-CAPS mirrors
    case "$1" in
      docs/issues/*|docs/handoffs/*|docs/reviews/*|docs/briefs/*|docs/archive/*) return 0 ;;
    esac
    case "$(basename "$1")" in ROADMAP.md|ISSUES.md|BACKLOG.md) return 0 ;; esac
    return 1
  }
  is_candidate() { # $1 = path; keyword filename OR issue-shaped content
    local base; base="$(basename "$1")"
    # keyword match anchored to whole filename tokens so "fixture"/"explanation" do not match "fix"/"plan"
    printf '%s' "$base" | grep -qiE '(^|[^a-z])(issues|next|backlog|plan|fix|todo)([^a-z]|$)' && return 0
    if grep -qE '^# ' "$1" && grep -qiE '^(Label|Filed|Status):' "$1"; then return 0; fi
    grep -qiE '^(number|title|state):' "$1" && return 0
    return 1
  }
  reconcile_import() {   # local mode only: scan standard + --scan roots, offer each candidate for import
    local roots=() r f label title body
    for r in docs .planning .ralph; do [ -d "$r" ] && roots+=("$r"); done
    for r in .scratch/*/issues; do [ -d "$r" ] && roots+=("$r"); done
    for r in ${SCAN_ROOTS[@]+"${SCAN_ROOTS[@]}"}; do [ -d "$r" ] && roots+=("$r"); done
    [ "${#roots[@]}" -gt 0 ] || return 0
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      is_excluded "$f" && continue
      is_candidate "$f" || continue
      if head -1 "$f" | grep -qE '^---$'; then
        # frontmatter-shaped file: read title/labels from frontmatter, strip the first frontmatter block from the body
        title="$(grep -E '^title:'  "$f" | head -1 | sed -E 's/^title:[[:space:]]*//; s/[[:space:]]*$//')"
        label="$(grep -E '^labels:' "$f" | head -1 | sed -E 's/^labels:[[:space:]]*//; s/[[:space:]]*$//')"
        body="$(awk 'f{print} /^---$/{c++; if(c==2){f=1}}' "$f")"
      else
        # prose file: title from the # H1, label from the Label: line
        label="$(grep -iE '^Label:' "$f" | head -1 | sed -E 's/^[Ll]abel:[[:space:]]*//; s/[[:space:]]*$//')"
        title="$(grep -E '^# ' "$f" | head -1 | sed -E 's/^#[[:space:]]+//')"
        body="$(cat "$f")"
      fi
      [ -n "$title" ] || title="$(basename "$f" .md)"
      echo "import candidate: $f (title: $title, label: ${label:-none})"
      if ask "import $f as a tracker issue?"; then
        scripts/tracker.sh create --label "$label" --title "$title" --body "$body" >/dev/null \
          && echo "imported $f"
      fi
    done < <(find "${roots[@]}" -type f -name '*.md' | sort)
  }
  ```

  c. Add the call site after the mode-finalize `if/else/fi` block (the block that runs gen-mirrors), before the closing `echo "loop-setup complete"`:

  ```bash
  [ "$MODE" = local ] && reconcile_import
  ```

  Import is scoped to local mode because github mode has no `docs/issues/` home to import into.
  Note `docs/plans/` is deliberately NOT excluded, so plan files are fair game.

- [ ] Step 4: Run it - `bash tests/loop-setup/import.sh` - expect PASS.
- [ ] Step 5: Commit.

  ```
  git add skills/loop-setup/setup.sh tests/loop-setup/import.sh
  git commit -m "loop-setup: import pre-existing issue-shaped markdown from standard and --scan roots (local mode)"
  ```

---

### Task 3: Tidy script and its setup wiring

Depends on: Task 2

**Files (exclusive ownership):**
- Create: `scripts/tidy.sh`
- Modify: `skills/loop-setup/setup.sh` (add the `TIDY` variable with an existence guard; add the invocation)
- Test: `tests/loop-setup/tidy.sh`

**Interfaces:**
- Consumes: nothing from earlier tasks except that setup.sh already defines `$REPO`; `scripts/tidy.sh` is self-contained (its own `ask()`).
- Produces:
  - `scripts/tidy.sh` (no args): inventories untracked `.scratch/` byproducts in the caller's cwd, prints one `byproduct: <path>` line per item, offers per-item deletion, deletes only accepted items, and reports nothing when there are none.
  - A setup.sh invocation of tidy on every run.

**Acceptance check:** `bash tests/loop-setup/tidy.sh` exits 0 `[executed-check]` (maps success criteria 4 and 6).

- [ ] Step 1: Write the failing test.

VERBATIM `tests/loop-setup/tidy.sh`:

```bash
#!/usr/bin/env bash
# Tidy (criterion 4): inventory untracked .scratch/ byproducts with per-item deletion offers;
# decline keeps, accept deletes, nothing deletes without acceptance. Idempotency (criterion 6):
# a fully-reconciled repo re-run reports nothing to reconcile.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SETUP="$REPO/skills/loop-setup/setup.sh"
TIDY="$REPO/scripts/tidy.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$TIDY" ]  || fail "scripts/tidy.sh missing or not executable"
[ -x "$SETUP" ] || fail "setup.sh missing"

# --- criterion 4: decline keeps everything, and every byproduct is inventoried ---
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
( cd "$T" && git init -q )
mkdir -p "$T/.scratch/run-a"
echo one > "$T/.scratch/run-a/notes.txt"
echo two > "$T/.scratch/stray.log"
out="$( cd "$T" && LOOP_ASSUME_NO=1 "$TIDY" )" || fail "tidy (decline) exited non-zero"
printf '%s\n' "$out" | grep -q '.scratch/run-a/notes.txt' || fail "tidy did not inventory notes.txt"
printf '%s\n' "$out" | grep -q '.scratch/stray.log'       || fail "tidy did not inventory stray.log"
[ -f "$T/.scratch/run-a/notes.txt" ] || fail "declined tidy deleted notes.txt"
[ -f "$T/.scratch/stray.log" ]       || fail "declined tidy deleted stray.log"

# --- criterion 4: accept deletes the byproducts ---
( cd "$T" && LOOP_ASSUME_YES=1 "$TIDY" ) >/dev/null || fail "tidy (accept) exited non-zero"
[ ! -f "$T/.scratch/run-a/notes.txt" ] || fail "accepted tidy did not delete notes.txt"
[ ! -f "$T/.scratch/stray.log" ]       || fail "accepted tidy did not delete stray.log"

# --- a repo with no byproducts reports nothing ---
out2="$( cd "$T" && "$TIDY" )" || fail "tidy on a clean repo exited non-zero"
printf '%s\n' "$out2" | grep -qi 'byproduct' \
  && fail "tidy inventoried a byproduct on a repo with none"

# --- criterion 6: after all offers are resolved, a re-run reports nothing to reconcile ---
C="$(mktemp -d)"; trap 'rm -rf "$T" "$C"' EXIT
( cd "$C" && git init -q )
( cd "$C" && LOOP_TRACKER_ANSWER=local "$SETUP" </dev/null >/dev/null ) || fail "initial setup errored"
out3="$( cd "$C" && "$SETUP" </dev/null )" || fail "second setup run errored"
printf '%s\n' "$out3" | grep -qi 'stale'           && fail "idempotent re-run reported a stale config"
printf '%s\n' "$out3" | grep -qi 'import candidate' && fail "idempotent re-run reported an import candidate"
printf '%s\n' "$out3" | grep -qi 'byproduct'        && fail "idempotent re-run reported a tidy byproduct"

echo "PASS: tidy - inventory + per-item delete offers (criterion 4); fully-reconciled repo is a no-op (criterion 6)"
```

- [ ] Step 2: Run it - `bash tests/loop-setup/tidy.sh` - expect FAIL with "scripts/tidy.sh missing or not executable".
- [ ] Step 3: Implement against the contract.

  a. Create `scripts/tidy.sh` (VERBATIM), then `chmod +x scripts/tidy.sh`:

  ```bash
  #!/usr/bin/env bash
  # tidy.sh - inventory UNTRACKED .scratch/ byproducts in the caller's cwd and offer per-item
  # deletion. Never judges whether work is "merged"; the human decides each item.
  # Honors LOOP_ASSUME_YES/NO. Reports nothing on a repo with no such byproducts.
  set -uo pipefail
  ask() {   # $1 = prompt; 0 = yes, 1 = no
    [ "${LOOP_ASSUME_YES:-0}" = 1 ] && return 0
    [ "${LOOP_ASSUME_NO:-0}"  = 1 ] && return 1
    local a; printf '%s [y/N]: ' "$1" >&2; read -r a || return 1
    case "$a" in [yY]*) return 0;; *) return 1;; esac
  }
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
  [ -d .scratch ] || exit 0
  # -o lists untracked files; WITHOUT --exclude-standard it also includes gitignored scratch,
  # which is exactly what a .scratch byproduct usually is.
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    echo "byproduct: $f"
    if ask "delete $f?"; then
      rm -f "$f" && echo "deleted $f"
    fi
  done < <(git ls-files -o -- .scratch | sort)
  ```

  b. In `skills/loop-setup/setup.sh`, add near the other resolved paths (after `GEN=...`):

  ```bash
  TIDY="$REPO/scripts/tidy.sh"
  [ -x "$TIDY" ] || fail "tidy.sh not found or not executable: $TIDY"
  ```

  c. Add the invocation just before the final `echo "loop-setup complete"`, after the `reconcile_import` line from Task 2:

  ```bash
  "$TIDY"
  ```

  Tidy runs from the loop-stack copy against the target cwd; it is not installed into the target repo because only setup invokes it.
  Import runs before tidy so an imported `.scratch` issue survives before tidy offers to delete its scratch source.

- [ ] Step 4: Run it - `bash tests/loop-setup/tidy.sh` - expect PASS.
      Re-run `bash tests/loop-setup/import.sh` and `bash tests/repo-state/local-workflow.sh` - both expect PASS.
      `import.sh` scenario A does carry a `.scratch` tree, but tidy deleting it under `LOOP_ASSUME_YES` is harmless because import runs first and has already copied the file into `docs/issues/`; `local-workflow.sh` has no `.scratch` at all.
- [ ] Step 5: Commit.

  ```
  git add scripts/tidy.sh skills/loop-setup/setup.sh tests/loop-setup/tidy.sh
  git commit -m "loop-setup: add scripts/tidy.sh to inventory and offer deletion of untracked .scratch byproducts; invoke it on every setup run"
  ```

---

### Task 4: Migration ledger freeze and removal offer

Depends on: none (parallel to the setup.sh chain)

**Files (exclusive ownership):**
- Modify: `scripts/migrate-tracker.sh` (add `ask()`; add `freeze_state()`; call it after `stamp_migrated`; add the post-migration `git rm` offer)
- Test: `tests/repo-state/migrate.sh` (extend with freeze + removal scenarios)

**Interfaces:**
- Consumes: the existing `stamp_migrated`, `fm`, and `files` array already in migrate-tracker.sh.
- Produces:
  - After each created GitHub issue, the file's `state:` VALUE is rewritten to `migrated` while the `migrated: <url>` audit line is kept.
  - After the migration completes, a `git rm` of exactly the migrated ledger files is offered (guarded by an in-worktree check); the human fires it. Freeze always happens; removal is offered.

**Acceptance check:** `bash tests/repo-state/migrate.sh` exits 0 `[executed-check]` (maps success criterion 3).

- [ ] Step 1: Write the failing test - append these two scenarios to `tests/repo-state/migrate.sh`, immediately before the final `echo "PASS: ..."` line, and update that final echo (shown below).

VERBATIM block to append (before the existing final echo):

```bash
# --- freeze + removal offer: real run freezes state: to migrated and offers git rm of exactly those files ---
FB="$(mktemp -d)"; FBIN="$(mktemp -d)"; trap 'rm -rf "$SB" "$RB" "$RBIN" "$FB" "$FBIN"' EXIT
cat > "$FBIN/gh" <<EOF
#!/usr/bin/env bash
case "\$1" in
  auth)  exit 0 ;;
  label) exit 0 ;;
  issue) [ "\$2" = create ] && { echo "https://github.com/x/y/issues/77"; exit 0; }; exit 0 ;;
esac
exit 0
EOF
chmod +x "$FBIN/gh"
( cd "$FB" && git init -q )
mkdir -p "$FB/docs/issues" "$FB/config" "$FB/scripts"
printf 'tracker: local\n' > "$FB/config/repo-state.md"
cp "$REPO/scripts/tracker.sh" "$FB/scripts/tracker.sh"; chmod +x "$FB/scripts/tracker.sh"
cat > "$FB/docs/issues/001-alpha.md" <<'EOS'
---
number: 1
title: alpha issue
labels: bug
state: open
updated: 2026-08-04T00:00:00Z
---
alpha body
EOS
cat > "$FB/docs/issues/002-beta.md" <<'EOS'
---
number: 2
title: beta issue
labels: bug
state: closed
updated: 2026-08-04T00:00:00Z
---
beta body
EOS
( cd "$FB" && git add -A && git commit -qm init )
( cd "$FB" && PATH="$FBIN:$PATH" LOOP_ASSUME_YES=1 bash "$M" ) >/dev/null || fail "freeze migration exited non-zero"
# freeze: no migrated file carries a live state: line
grep -REq '^state: (open|closed)$' "$FB/docs/issues/" \
  && fail "a migrated file still carries a live state: (open|closed) line"
grep -q '^state: migrated$' "$FB/docs/issues/001-alpha.md" || fail "issue #1 state was not frozen to migrated"
grep -q '^migrated:' "$FB/docs/issues/001-alpha.md"        || fail "issue #1 lost its migrated: audit line"
# accepted removal staged git rm of exactly the two migrated ledger files
staged="$( cd "$FB" && git diff --cached --name-only --diff-filter=D | sort )"
expected="$(printf 'docs/issues/001-alpha.md\ndocs/issues/002-beta.md\n')"
[ "$staged" = "$expected" ] || fail "git rm did not stage exactly the migrated files (got: $staged)"

# --- decline removal keeps the ledger files on disk (still frozen) ---
DB="$(mktemp -d)"; trap 'rm -rf "$SB" "$RB" "$RBIN" "$FB" "$FBIN" "$DB"' EXIT
( cd "$DB" && git init -q )
mkdir -p "$DB/docs/issues" "$DB/config" "$DB/scripts"
printf 'tracker: local\n' > "$DB/config/repo-state.md"
cp "$REPO/scripts/tracker.sh" "$DB/scripts/tracker.sh"; chmod +x "$DB/scripts/tracker.sh"
cat > "$DB/docs/issues/001-alpha.md" <<'EOS'
---
number: 1
title: alpha issue
labels: bug
state: open
updated: 2026-08-04T00:00:00Z
---
alpha body
EOS
( cd "$DB" && git add -A && git commit -qm init )
( cd "$DB" && PATH="$FBIN:$PATH" LOOP_ASSUME_NO=1 bash "$M" ) >/dev/null || fail "declined-removal migration exited non-zero"
[ -f "$DB/docs/issues/001-alpha.md" ] || fail "declined removal deleted the ledger file"
[ -z "$( cd "$DB" && git diff --cached --name-only --diff-filter=D )" ] || fail "declined removal wrongly staged a git rm"
grep -q '^state: migrated$' "$DB/docs/issues/001-alpha.md" || fail "freeze must happen even when removal is declined"
```

Then replace the existing final line:

```bash
echo "PASS: migrate-tracker dry-run emits one create per local issue with title/labels preserved, closes closed ones; resume skips stamped files"
```

with:

```bash
echo "PASS: migrate-tracker dry-run one-create-per-issue; resume skips stamped files; freeze rewrites state: to migrated; accepted git rm stages exactly the migrated files, declined keeps them"
```

- [ ] Step 2: Run it - `bash tests/repo-state/migrate.sh` - expect FAIL with "a migrated file still carries a live state: (open|closed) line" (freeze does not exist yet).
- [ ] Step 3: Implement against the contract in `scripts/migrate-tracker.sh`.

  a. Add an `ask()` helper after the `fail()` definition:

  ```bash
  ask() {   # $1 = prompt; 0 = yes, 1 = no
    [ "${LOOP_ASSUME_YES:-0}" = 1 ] && return 0
    [ "${LOOP_ASSUME_NO:-0}"  = 1 ] && return 1
    local a; printf '%s [y/N]: ' "$1" >&2; read -r a || return 1
    case "$a" in [yY]*) return 0;; *) return 1;; esac
  }
  ```

  b. Add a `freeze_state()` helper next to `stamp_migrated`:

  ```bash
  freeze_state() {   # rewrite the state: VALUE to the frozen marker inside the FIRST frontmatter block
    local f="$1" tmp; tmp="$(mktemp)"
    awk '
      /^---$/ { d++; print; next }
      d==1 && /^state:/ { print "state: migrated"; next }
      { print }
    ' "$f" > "$tmp" && mv "$tmp" "$f"
  }
  ```

  c. In the real-run branch of the per-file loop, call `freeze_state "$f"` on the line immediately after the existing `stamp_migrated "$f" "$url"` call.
  Freeze always happens on a real migration; the `migrated: <url>` line stays as the audit trail.

  d. After the loop and after the `flipped tracker: github` step (still inside `if [ "$DRY" = 0 ]; then ... fi`, or add a new real-run block after it), add the removal offer:

  ```bash
  if [ "$DRY" = 0 ] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    mig=()
    for f in "${files[@]}"; do grep -q '^migrated:' "$f" && mig+=("$f"); done
    if [ "${#mig[@]}" -gt 0 ] && ask "git rm the ${#mig[@]} migrated ledger file(s)?"; then
      # -f is required: freeze_state modified these files vs HEAD, and plain `git rm` refuses modified files
      git rm -qf "${mig[@]}" && echo "staged git rm of ${#mig[@]} migrated ledger file(s)"
    fi
  fi
  ```

  The in-worktree guard means a non-git sandbox (such as the existing resume-test sandbox, which has no `git init`) skips the offer entirely, so that test stays green without modification.
  The dry-run path is untouched, so the existing dry-run assertions still hold.

- [ ] Step 4: Run it - `bash tests/repo-state/migrate.sh` - expect PASS.
- [ ] Step 5: Commit.

  ```
  git add scripts/migrate-tracker.sh tests/repo-state/migrate.sh
  git commit -m "migrate-tracker: freeze each migrated file's state: to migrated and offer git rm of the migrated ledger"
  ```
