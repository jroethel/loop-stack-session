# Tracker Mode Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes. No specific tooling, harness, or skills are assumed.

**Goal:** Make a repo's issue tracker an explicit declared choice (`tracker: github` or `tracker: local`) that every loop-stack script obeys, so no script ever infers the backend from `git remote`.
**Approach:** Add a line-anchored `tracker:` key to `config/repo-state.md` exactly parallel to the existing `autonomy-default:` key, and route every gh call through one new seam, `scripts/tracker.sh`, that switches on the key.
Consumers (gen-mirrors, graduate-parking, setup, migration) each do a one-line mode read and never guess.
Local mode gains a real committed tracker under `docs/issues/`; its inherent gaps are disclosed, not papered over.
**Tech stack:** bash, awk, git, gh (github mode only).
**Source brief:** docs/briefs/2026-08-03-tracker-mode-brief.md

## Global constraints

- The backend is a line-anchored `^tracker:` key in `config/repo-state.md`, value `github` or `local`; read it with the same `grep -E '^tracker:' | sed` idiom `loop-auto.sh` uses for `autonomy-default:`.
- Local mode makes ZERO gh invocations anywhere in the workflow (setup, list, create, close, reopen, mirrors, graduation).
- Github mode fails fast: before any gh call, `gh auth status` must succeed (covers gh-absent AND unauthenticated), else exit non-zero with a message naming the prerequisite.
- Local issue files are durable and committed under `docs/issues/`, one file per issue, `NNN-<slug>.md`, never scratch, never deleted (closed issues keep their file with `state: closed`).
- "Graduation" means parking-lot to backlog only; "migration" means local tracker to GitHub; the two words stay distinct.
- Every script reads the key; no script infers the backend from `git remote` (remote detection is advisory only, used by setup to phrase a suggestion).

## Dependency graph

```
Task 1 (config schema)  ─┐
                         ├────────────> Task 5 (setup, declared mode)
Task 2 (tracker.sh) ─────┤                │
   │                     │                │
   ├─> Task 3 (gen-mirrors) ──────────────┤
   ├─> Task 4 (graduate-parking)          │
   ├─> Task 6 (migration)                 │
   │                                      │
   └──────────────┬───────────────────────┘
                  └─> Task 7 (full local-mode workflow integration)

Task 8 (prose fixes) - independent leaf, no code dependency
```

Task 2 (`scripts/tracker.sh`) is the foundation every consumer collapses into; it is created by exactly one task.
Task 1 and Task 2 have no dependency on each other and touch disjoint files, so they run in parallel.
Tasks 3, 4, 6 each depend only on Task 2 and touch disjoint files, so they run in parallel with each other.
Task 5 depends on Task 1 (renders the config, needs the Local-tracker section and key prose), Task 2 (writes the key via `tracker.sh mode set`, installs `tracker.sh` into the target), and Task 3 (its local finalize runs the installed `gen-mirrors.sh .` in a remote-less sandbox with no fixture hook; that call is only gh-free once gen-mirrors sources via `tracker.sh list`, so the original gh-calling gen-mirrors would fail Task 5's local acceptance).
Task 7 is the end-to-end integration and depends on Tasks 2, 3, 4, 5.
Task 8 is prose-only and independent.

## Human checkpoints

None are `[judgment]` criteria; all six success criteria are executed-checks.
One real-data eyeball is advisory, not gating: the FIRST live local-to-github migration on a real repo (Task 6) actually creates GitHub issues.
The executor runs Task 6's acceptance via `MIGRATE_DRY_RUN=1` (no gh calls); a human should run the un-dry migration once against a throwaway or real repo and confirm the created issues look right before trusting it on anything precious.

Upgrade note: repos that installed loop-stack before this change must re-run `skills/loop-setup/setup.sh` once to gain `scripts/tracker.sh` and the `tracker:` key (setup's legacy-keyless path handles this and is safe to re-run).

## How to run

There is no aggregate test runner in this repo; each test file is a standalone bash script where exit 0 = PASS.
Run from the repo root:

```bash
bash tests/repo-state/config.sh           # Task 1
bash tests/repo-state/tracker.sh          # Task 2
bash tests/repo-state/mirrors.sh          # Task 3
bash tests/gates/loop-brainstorm.sh       # Task 4
bash tests/repo-state/migrate.sh          # Task 6
bash tests/loop-setup/acceptance.sh       # Task 5 (criteria 1,2,3,5)
bash tests/repo-state/local-workflow.sh   # Task 7 (criterion 4)
bash tests/gates/check.sh                 # Task 8 regression (gate registry still fresh)
bash tests/gates/wayfinder.sh             # Task 8 regression (wayfinder note additive)
```

Full sweep in one line:

```bash
for t in tests/repo-state/config.sh tests/repo-state/tracker.sh tests/repo-state/mirrors.sh \
         tests/gates/loop-brainstorm.sh tests/repo-state/migrate.sh tests/loop-setup/acceptance.sh \
         tests/repo-state/local-workflow.sh tests/gates/check.sh tests/gates/wayfinder.sh; do
  echo "=== $t ==="; bash "$t" || { echo "FAILED: $t"; break; }
done
```

---

### Task 1: Config schema - the `tracker:` key and the Local tracker section

Depends on: none

**Files (exclusive ownership):**
- Modify: `config/repo-state.template.md` (intro lines 4-5; the `## Fallback (no remote)` section at lines 39-44; add `tracker:` prose near line 20's autonomy-default prose)
- Modify: `config/repo-state.md` (mirror the same edits; ADD a literal `tracker: github` line - this repo has a remote)
- Test: `tests/repo-state/config.sh` (replace the `## *Fallback`/`scratch` assertions; add `^tracker:` and disclosure assertions)

**Interfaces:**
- Produces: the template `## Local tracker` section containing the two verbatim disclosure phrases `invisible to cross-repo idea search` and `wayfinder requires \`tracker: github\``; a mode-neutral intro; a `tracker:` key prose paragraph.
- Produces: this repo's `config/repo-state.md` carries a line-anchored `tracker: github`.
- Consumed by: Task 5 (setup renders github/local variants of this template; strips the `## Local tracker` section in github mode by its `^## Local tracker` heading).
- MUST preserve: the template's `{{REMOTE_OR_FALLBACK}}` placeholder line and the `Render it into` line. Task 5's `render_github`/`render_local` depend on both (they fill the placeholder with the remote URL or the local note, and drop the `Render it into` line). Task 1 rewrites the intro and the Fallback->Local tracker section AROUND these two lines; it must not delete them.

**Acceptance check:** `bash tests/repo-state/config.sh` exits 0 `[executed-check]`

- [ ] Step 1: Rewrite the template. In `config/repo-state.template.md`:
  - Replace intro line 5 (`For a repo with no remote, replace it with the no-remote note and follow the Fallback section.`) with a mode-neutral line: `The tracker backend (github or local) is declared in the \`tracker:\` key below; the Local tracker section governs local mode.`
  - Immediately after the `autonomy-default:` prose paragraph (around line 20-21), add this paragraph verbatim:
    ```
    The committed tracker backend is a line-anchored `tracker:` key in this same file (value `github` or `local`).
    Every loop-stack script reads it and obeys it; none infers the backend from `git remote`.
    `scripts/tracker.sh mode get|set` reads and writes it; `skills/loop-setup/setup.sh` asks it once when the key is missing.
    ```
  - Replace the entire `## Fallback (no remote)` section (lines 39-44) with this section verbatim:
    ```
    ## Local tracker

    When `tracker: local`, the Issues and Backlog lanes live in `docs/issues/`, one file per issue.
    These files are durable and committed - not scratch, not disposable.
    Each file is named `NNN-<title-slug>.md` (NNN zero-padded, numbers never reused) with line-anchored frontmatter keys `number:`, `title:`, `labels:` (comma-separated), `state:` (open|closed), and `updated:`.
    Closed issues keep their files with `state: closed` - archive, never delete.
    `scripts/tracker.sh` reads and writes these files; `scripts/gen-mirrors.sh .` renders ISSUES.md/BACKLOG.md from them.
    Issues are updated by editing `docs/issues/NNN-<slug>.md` directly; the safe-to-edit frontmatter keys are `title:`, `labels:` (comma-separated), and `state:` (open|closed) - keep each on its own single line, and do not renumber.
    Progress notes are appended to the body.
    Local-mode limitations, disclosed:
    - A local repo is invisible to cross-repo idea search - `gh search issues` needs a remote.
    - wayfinder requires `tracker: github`; its map is issue-shaped end to end, with no local variant.
    - Numbering is safe only for a single linear writer: two branches or contributors can both mint the same number in differently-slugged files that git merges cleanly; shared or branched work should use `tracker: github`.
    Migration to GitHub - distinct from graduation - recreates every local issue as a GitHub issue via `scripts/migrate-tracker.sh`.
    Migration renumbers issues (GitHub assigns its own numbers); any existing `#N` reference in commits, other issues, or ROADMAP must be updated afterward - the migration prints the old->new mapping.
    ```
- [ ] Step 2: Mirror the SAME two edits into `config/repo-state.md`, and additionally insert a literal `tracker: github` line directly beneath the `Remote:` line (line 6). Leave every other section (Lanes, Scope rule, Archive and graduation, cross-repo search line) untouched.
- [ ] Step 3: Rewrite the affected assertions in `tests/repo-state/config.sh`. Replace line 33 (`grep -qi '## *Fallback' "$CFG" || fail "no-remote fallback section missing"`) and add the new schema assertions. The final assertion block for the tracker key and disclosures is VERBATIM:
    ```bash
    # tracker: key is a line-anchored declared choice in this repo's config
    grep -q '^tracker:' "$CFG" || fail "config/repo-state.md missing the line-anchored tracker: key"
    # template carries the Local tracker section and both disclosed limitations (source for local renders)
    grep -Eqi '## *Local tracker' "$TPL" || fail "template missing the Local tracker section"
    grep -qi 'cross-repo idea search' "$TPL" || fail "template missing the cross-repo-search disclosure"
    grep -qi 'wayfinder requires' "$TPL"     || fail "template missing the wayfinder-requires-github disclosure"
    grep -qi 'single linear writer' "$TPL"   || fail "template missing the single-linear-writer numbering disclosure"
    ```
    Delete the now-stale `## *Fallback` assertion (the section was renamed). Leave the lane loop (lines 15-18) and all other assertions unchanged - they still hold.
- [ ] Step 4: Run `bash tests/repo-state/config.sh`; expect `PASS: config/repo-state.md and CLAUDE.md pointer complete`.
- [ ] Step 5: Commit:
    ```bash
    git add config/repo-state.template.md config/repo-state.md tests/repo-state/config.sh
    git commit -m "tracker mode: declared tracker: key + Local tracker section in repo-state schema"
    ```

---

### Task 2: `scripts/tracker.sh` - the single backend seam

Depends on: none

**Files (exclusive ownership):**
- Create: `scripts/tracker.sh` (executable)
- Test: `tests/repo-state/tracker.sh` (new)

**Interfaces:**
- Produces the subcommand contract every consumer relies on. All operate on the caller's cwd repo (`config/repo-state.md`, `docs/issues/`), never on this script's own location - same convention as `loop-auto.sh`:
  - `tracker.sh mode get` - prints `github` or `local` (bare word) read from `^tracker:` in `config/repo-state.md`; exit 0. If the file is missing or has no `^tracker:` line, prints nothing and exits 3 (callers detect absence).
  - `tracker.sh mode set <github|local>` - line-anchored write (grep -v / tmp / mv), validates the value, prints the value, exit 0.
  - `tracker.sh list` - prints an issue-JSON array to stdout in EXACTLY the shape of `gh issue list --state open --json number,title,labels,updatedAt` (array of objects; each has `number` int, `title` string, `labels` array of `{"name":...}`, `updatedAt` string). github mode: shells to that gh command. local mode: builds the JSON from open `docs/issues/*.md`. Empty set prints `[]`. exit 0.
  - `tracker.sh create --label <l> --title <t> --body <b>` - prints the new issue number (bare integer) to stdout. github: `gh issue create ...`, number parsed from the returned URL. local: writes `docs/issues/NNN-<slug>.md`, prints NNN unpadded.
  - `tracker.sh close <num>` / `tracker.sh reopen <num>` - github: `gh issue close|reopen <num>`. local: flip `state:` in the matching file's frontmatter.
  - Every github-backed op first calls a fail-fast guard: `command -v gh` AND `gh auth status`; on failure exit non-zero with a message naming the prerequisite. Every local-backed op makes zero gh invocations.
  - `list/create/close/reopen` bind the mode in the PARENT scope (`mode="$(tracker_mode_get)" || fail ...`), never a `require_mode` subshell: a keyless/modeless repo MUST hard-fail non-zero, never silently default to the local backend.
  - LOCAL `create`/`close`/`reopen` print a one-line reminder to STDERR (`note: ISSUES.md/BACKLOG.md now stale - run scripts/gen-mirrors.sh .`). This is a reminder only - the design is on-demand regen with no hooks/daemons; the mutation never auto-runs gen-mirrors. Stderr keeps it out of the stdout the callers capture.
- Consumed by: Task 3 (`list`), Task 4 (`create`), Task 5 (`mode set`), Task 6 (`mode set`), Task 8's prose (`close`).

**Acceptance check:** `bash tests/repo-state/tracker.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test VERBATIM to `tests/repo-state/tracker.sh`:
    ```bash
    #!/usr/bin/env bash
    # tracker.sh unit: mode read/write, local create/close/reopen, and list JSON shape - zero gh in local mode.
    set -uo pipefail
    HERE="$(cd "$(dirname "$0")" && pwd)"
    REPO="$(cd "$HERE/../.." && pwd)"
    T="$REPO/scripts/tracker.sh"
    fail() { echo "FAIL: $1" >&2; exit 1; }
    [ -x "$T" ] || fail "scripts/tracker.sh missing or not executable"

    # gh stub that RECORDS any invocation, so "zero gh in local mode" is provable, not assumed.
    BIN="$(mktemp -d)"; SB="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB"' EXIT
    GHLOG="$BIN/gh.calls"
    cat > "$BIN/gh" <<EOF
    #!/usr/bin/env bash
    echo "GH CALLED: \$*" >> "$GHLOG"
    exit 1
    EOF
    chmod +x "$BIN/gh"
    export PATH="$BIN:$PATH"

    cd "$SB" && git init -q && mkdir -p config

    # mode get on a keyless config exits non-zero and prints nothing
    : > config/repo-state.md
    out="$("$T" mode get 2>/dev/null)"; rc=$?
    [ "$rc" -ne 0 ] || fail "mode get returned 0 on a keyless config"
    [ -z "$out" ] || fail "mode get printed '$out' on a keyless config"

    # a keyless/modeless repo MUST hard-fail list AND create - never silently default to the local backend
    "$T" list >/dev/null 2>&1 && fail "list did not hard-fail on a keyless config"
    "$T" create --label idea --title "should not exist" --body x >/dev/null 2>&1 \
      && fail "create did not hard-fail on a keyless config"
    [ ! -e docs/issues ] || fail "keyless create created something under docs/issues/"

    # mode set writes a line-anchored key, get reads it back, set is idempotent (no duplicate line)
    [ "$("$T" mode set local)" = "local" ] || fail "mode set local did not echo local"
    [ "$("$T" mode get)" = "local" ]       || fail "mode get did not read back local"
    "$T" mode set github >/dev/null
    "$T" mode set local  >/dev/null
    [ "$(grep -c '^tracker:' config/repo-state.md)" -eq 1 ] || fail "mode set duplicated the tracker: line"
    [ "$("$T" mode get)" = "local" ]       || fail "mode get did not reflect the last set"

    # local create -> file written, number printed, next number increments and never reuses
    n1="$("$T" create --label idea   --title "Crash on empty input" --body "steps")"
    n2="$("$T" create --label bug     --title "Second bug"            --body "body two")"
    [ "$n1" = "1" ] || fail "first local issue was not number 1 (got '$n1')"
    [ "$n2" = "2" ] || fail "second local issue was not number 2 (got '$n2')"
    ls docs/issues/001-crash-on-empty-input.md >/dev/null 2>&1 || fail "issue file not named NNN-slug.md"
    grep -q '^number: 1'    docs/issues/001-crash-on-empty-input.md || fail "frontmatter number: missing"
    grep -q '^labels: idea' docs/issues/001-crash-on-empty-input.md || fail "frontmatter labels: missing"
    grep -q '^state: open'  docs/issues/001-crash-on-empty-input.md || fail "frontmatter state: missing"

    # list emits gh-shaped JSON for open issues; labels are an array of {name}
    j="$("$T" list)"
    printf '%s' "$j" | grep -q '"number":1'                 || fail "list missing number 1"
    printf '%s' "$j" | grep -q '"title":"Crash on empty input"' || fail "list missing/garbled title"
    printf '%s' "$j" | grep -q '"labels":\[{"name":"idea"}\]'   || fail "list labels not gh-shaped"
    printf '%s' "$j" | grep -q '"updatedAt":"'              || fail "list missing updatedAt"

    # JSON escaping: a title with a double-quote, a backslash, and a pipe round-trips create->list as valid escaped JSON
    "$T" create --label idea --title 'Weird "q" \ and | pipe' --body b >/dev/null
    je="$("$T" list)"
    printf '%s' "$je" | grep -q '\\"q\\"' || fail 'double-quote in title not escaped as \" in list JSON'
    printf '%s' "$je" | grep -q '| pipe'  || fail "pipe in title lost from list JSON"

    # empty labels: a bare labels: line must render "labels":[] and must NOT crash (bash 3.2 empty-array under set -u)
    cat > docs/issues/004-no-labels.md <<'EOS'
    ---
    number: 4
    title: No labels issue
    labels:
    state: open
    updated: 2026-08-04T00:00:00Z
    ---
    body
    EOS
    jn="$("$T" list)" || fail "list crashed on an empty-labels issue"
    printf '%s' "$jn" | grep -q '"title":"No labels issue","labels":\[\]' || fail "empty-labels issue did not render labels:[]"

    # seed: issue #1 body carries a line starting "state:", and a known-old updated: stamp, so close proves it
    # (a) refreshes updated: and (b) rewrites state: only inside the first frontmatter block, never a body line
    f1=docs/issues/001-crash-on-empty-input.md
    printf 'state: needs repro\n' >> "$f1"
    awk '/^updated:/{print "updated: 2000-01-01T00:00:00Z"; next} {print}' "$f1" > "$f1.t" && mv "$f1.t" "$f1"

    # close flips state and drops the issue from list; reopen restores it; the file survives (archive, not delete)
    "$T" close 1 >/dev/null
    grep -q '^state: closed' "$f1" || fail "close did not flip state to closed"
    grep -q '^updated: 2000-01-01T00:00:00Z' "$f1" && fail "close did not refresh the updated: stamp"
    grep -qx 'state: needs repro' "$f1" || fail "close clobbered a body line that begins state:"
    [ -f "$f1" ] || fail "close deleted the file (must archive)"
    printf '%s' "$("$T" list)" | grep -q '"number":1' && fail "closed issue #1 still appears in list"
    "$T" reopen 1 >/dev/null
    grep -q '^state: open' "$f1" || fail "reopen did not restore state"

    # THE hard local-mode guarantee: not one gh call happened
    [ ! -s "$GHLOG" ] || { echo "gh was invoked in local mode:"; cat "$GHLOG"; fail "local mode is not gh-free"; }
    echo "PASS: tracker.sh mode r/w, local create/close/reopen/list JSON shape, and zero-gh guarantee verified"
    ```
- [ ] Step 2: Run `bash tests/repo-state/tracker.sh`; expect FAIL with `scripts/tracker.sh missing or not executable`.
- [ ] Step 3: Implement `scripts/tracker.sh`. The load-bearing pieces are VERBATIM below (they ARE the decisions - key r/w, JSON emit, frontmatter parse, number assignment); wrap them in a `loop-auto.sh`-style `set -uo pipefail` / `fail()` / subcommand-dispatch skeleton.
    ```bash
    #!/usr/bin/env bash
    # tracker.sh - the single backend seam. Reads config/repo-state.md's tracker: key and
    # dispatches every issue operation to github (gh) or local (docs/issues/*.md) accordingly.
    # Operates on the caller's cwd repo, never on this script's own location (cf. loop-auto.sh).
    set -uo pipefail
    fail() { echo "tracker: $1" >&2; exit 1; }
    RS="config/repo-state.md"
    ISSUE_DIR="docs/issues"

    tracker_mode_get() {          # prints mode, or exits 3 when the key is absent
      [ -f "$RS" ] || return 3
      local v
      v="$(grep -E '^tracker:' "$RS" | head -1 | sed -E 's/^tracker:[[:space:]]*//; s/[[:space:]]*$//')"
      [ -n "$v" ] || return 3
      printf '%s\n' "$v"
    }
    tracker_mode_set() {
      local m="$1"
      case "$m" in github|local) ;; *) fail "mode set: must be 'github' or 'local' (got '$m')";; esac
      mkdir -p "$(dirname "$RS")"; touch "$RS"
      grep -v '^tracker:' "$RS" > "${RS}.tmp" || true
      printf 'tracker: %s\n' "$m" >> "${RS}.tmp"
      mv "${RS}.tmp" "$RS"
      printf '%s\n' "$m"
    }

    gh_guard() {                  # fail-fast: covers gh-absent AND unauthenticated (criterion 3)
      command -v gh >/dev/null 2>&1 || fail "github mode requires the gh CLI, which is not on PATH"
      gh auth status >/dev/null 2>&1 || fail "github mode requires an authenticated gh CLI (run: gh auth login)"
    }

    # --- local backend helpers ---
    slugify() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'; }
    fm() { grep -E "^$2:" "$1" | head -1 | sed -E "s/^$2:[[:space:]]*//; s/[[:space:]]*$//"; }  # frontmatter value
    # ponytail: escapes only \ and " (zero-dependency, no jq). Tab/newline/other control chars in a title
    # are NOT escaped - rare in issue titles, and frontmatter values are single-line so embedded newlines
    # cannot occur. Upgrade path: pipe through jq -Rn if control-char titles ever matter.
    json_escape() { printf '%s' "$1" | sed -E 's/\\/\\\\/g; s/"/\\"/g'; }

    next_number() {
      local max=0 n f
      shopt -s nullglob
      for f in "$ISSUE_DIR"/*.md; do
        n="$(fm "$f" number)"
        [ -n "$n" ] && [ "$n" -gt "$max" ] 2>/dev/null && max="$n"
      done
      echo $((max + 1))
    }
    find_issue_file() {           # arg: number -> prints path, exit 1 if none
      local f n
      shopt -s nullglob
      for f in "$ISSUE_DIR"/*.md; do
        n="$(fm "$f" number)"
        [ "$n" = "$1" ] && { printf '%s\n' "$f"; return 0; }
      done
      return 1
    }
    local_create() {              # args: label title body -> prints number
      local label="$1" title="$2" body="$3" num slug file
      mkdir -p "$ISSUE_DIR"
      num="$(next_number)"; slug="$(slugify "$title")"; slug="${slug:-issue}"  # all-punctuation title -> NNN-issue.md
      file="$(printf '%s/%03d-%s.md' "$ISSUE_DIR" "$num" "$slug")"
      {
        echo "---"
        echo "number: $num"
        echo "title: $title"
        echo "labels: $label"
        echo "state: open"
        echo "updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "---"
        printf '%s\n' "$body"
      } > "$file"
      echo "note: ISSUES.md/BACKLOG.md now stale - run scripts/gen-mirrors.sh ." >&2  # reminder only; no auto-regen
      printf '%s\n' "$num"
    }
    local_set_state() {           # args: number newstate ; rewrites state: and updated: only inside the first frontmatter block
      local f tmp now; f="$(find_issue_file "$1")" || fail "no local issue #$1"
      now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      tmp="$(mktemp)"
      awk -v st="$2" -v up="$now" '
        /^---$/ { d++; print; next }
        d==1 && /^state:/   { print "state: " st; next }
        d==1 && /^updated:/ { print "updated: " up; next }
        { print }
      ' "$f" > "$tmp" && mv "$tmp" "$f"
      echo "note: ISSUES.md/BACKLOG.md now stale - run scripts/gen-mirrors.sh ." >&2  # reminder only; no auto-regen
    }
    local_list() {                # emit gh-shaped JSON for open issues
      local first=1 out="[" f state num title upd labels_raw labels_json l
      shopt -s nullglob
      for f in "$ISSUE_DIR"/*.md; do
        state="$(fm "$f" state)"; [ "$state" = "open" ] || continue
        num="$(fm "$f" number)"; title="$(fm "$f" title)"; upd="$(fm "$f" updated)"
        labels_raw="$(fm "$f" labels)"
        labels_json=""
        if [ -n "$labels_raw" ]; then   # guard: iterating an empty array under set -u aborts on bash 3.2 (macOS)
          IFS=',' read -ra _larr <<< "$labels_raw"
          for l in "${_larr[@]}"; do
            l="$(printf '%s' "$l" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
            [ -n "$l" ] || continue
            [ -n "$labels_json" ] && labels_json="$labels_json,"
            labels_json="$labels_json{\"name\":\"$(json_escape "$l")\"}"
          done
        fi
        [ "$first" -eq 1 ] || out="$out,"; first=0
        out="$out{\"number\":$num,\"title\":\"$(json_escape "$title")\",\"labels\":[$labels_json],\"updatedAt\":\"$(json_escape "$upd")\"}"
      done
      printf '%s]\n' "$out"
    }
    ```
    Then the dispatch. `create` parses `--label/--title/--body` in a `while` loop. `list/create/close/reopen` bind the mode in the PARENT scope and hard-fail on a keyless/modeless repo - VERBATIM: `mode="$(tracker_mode_get)" || fail "no tracker mode declared in $RS (run loop-setup)"`. This is deliberately NOT a `mode="$(require_mode)"` subshell: with `set -uo pipefail` and no `set -e`, a `fail` fired inside a command-substitution subshell exits only that subshell and the parent would continue with an empty `$mode` and silently fall into the local branch. Binding with `tracker_mode_get` (which `return 3`s on absence) and a parent-scope `|| fail` makes a modeless repo abort with non-zero exit - it MUST hard-fail, never run a default backend. If `$mode` = github call `gh_guard` then the gh command, else the local helper. `create` github path: `url="$(gh issue create --label "$label" --title "$title" --body "$body")"; printf '%s\n' "${url##*/}"`. `close`/`reopen` github path: `gh issue close|reopen "$1"`. The local `create`/`close`/`reopen` reminder to stderr lives inside `local_create`/`local_set_state` (above) - a stale-mirror advisory only, never an auto-run of gen-mirrors. Usage string lists all subcommands, unknown subcommand exits 1. `chmod +x scripts/tracker.sh`.
- [ ] Step 4: Run `bash tests/repo-state/tracker.sh`; expect `PASS: tracker.sh mode r/w, local create/close/reopen/list JSON shape, and zero-gh guarantee verified`.
- [ ] Step 5: Commit:
    ```bash
    git add scripts/tracker.sh tests/repo-state/tracker.sh
    git commit -m "tracker mode: scripts/tracker.sh backend seam (github|local) with unit test"
    ```

---

### Task 3: `gen-mirrors.sh` sources issues via `tracker.sh list`

Depends on: Task 2

**Files (exclusive ownership):**
- Modify: `scripts/gen-mirrors.sh` (the "1. Source the issue JSON" block, lines 18-26; the header line 91 `source of truth: GitHub issues`)
- Test: `tests/repo-state/mirrors.sh` (add a local-source subtest)

**Interfaces:**
- Consumes: `scripts/tracker.sh list` (gh-shaped JSON array).
- Consumes: `scripts/tracker.sh mode get` (best-effort, for the header label only).
- Produces: unchanged mirror files ISSUES.md/BACKLOG.md whose header `source of truth:` line reads `GitHub issues` (github/unknown) or `docs/issues/ local tracker` (local). The awk render core (lines 28-119) is untouched.

**Acceptance check:** `bash tests/repo-state/mirrors.sh` exits 0 `[executed-check]`

- [ ] Step 1: Append a local-source subtest to `tests/repo-state/mirrors.sh`, VERBATIM, before the final `echo "PASS..."`:
    ```bash
    # --- local backend: gen-mirrors sources from docs/issues/ via tracker.sh list, zero gh ---
    LSB="$(mktemp -d)"; BIN2="$(mktemp -d)"; trap 'rm -rf "$OUT" "$LSB" "$BIN2"' EXIT
    cat > "$BIN2/gh" <<'EOS'
    #!/usr/bin/env bash
    echo "GH CALLED" >&2; exit 1
    EOS
    chmod +x "$BIN2/gh"
    mkdir -p "$LSB/scripts" "$LSB/config" "$LSB/docs/issues"
    cp "$REPO/scripts/tracker.sh" "$LSB/scripts/tracker.sh"; chmod +x "$LSB/scripts/tracker.sh"
    printf 'tracker: local\n' > "$LSB/config/repo-state.md"
    cat > "$LSB/docs/issues/001-a-real-bug.md" <<'EOS'
    ---
    number: 1
    title: a real bug
    labels: bug
    state: open
    updated: 2026-08-04T00:00:00Z
    ---
    body
    EOS
    cat > "$LSB/docs/issues/002-an-idea.md" <<'EOS'
    ---
    number: 2
    title: an idea
    labels: idea
    state: open
    updated: 2026-08-04T00:00:00Z
    ---
    body
    EOS
    ( cd "$LSB" && PATH="$BIN2:$PATH" "$GEN" . ) || fail "gen-mirrors failed sourcing the local tracker"
    grep -Eq '^\| *2 *\|' "$LSB/BACKLOG.md" || fail "local idea issue #2 did not render into BACKLOG.md"
    grep -Eq '^\| *1 *\|' "$LSB/ISSUES.md"  || fail "local bug issue #1 did not render into ISSUES.md"
    grep -q 'bug' "$LSB/ISSUES.md"          || fail "labels not carried through from local files"
    grep -qi 'local tracker' "$LSB/BACKLOG.md" || fail "local-mode header did not disclose docs/issues/ as source"
    ```
- [ ] Step 2: Run `bash tests/repo-state/mirrors.sh`; expect FAIL at `local idea issue #2 did not render into BACKLOG.md` (gen-mirrors still calls gh directly, and no MIRRORS_JSON_FILE is set so it errors on the gh stub).
- [ ] Step 3: Implement. In `scripts/gen-mirrors.sh`, replace the `else` branch of the source block (lines 22-25) so that after the `MIRRORS_JSON_FILE` hook (which stays FIRST and unchanged - tests depend on it), the non-fixture path reads from the seam:
    ```bash
    else
      JSON_SRC="$(scripts/tracker.sh list)" || fail "tracker.sh list failed"
    fi
    ```
    Then make the header label mode-appropriate. Before `write_mirror` is defined, compute:
    ```bash
    SRC_LABEL="GitHub issues"
    if [ "$(scripts/tracker.sh mode get 2>/dev/null || true)" = "local" ]; then
      SRC_LABEL="docs/issues/ local tracker"
    fi
    ```
    and change line 91 to `echo "source of truth: $SRC_LABEL"`. Note the existing fixture-hook test (top of mirrors.sh) runs with cwd = repo root where mode is `github`, so its header still contains `source of truth` with the `GitHub issues` label - that assertion still passes.
- [ ] Step 4: Run `bash tests/repo-state/mirrors.sh`; expect `PASS: mirror split, disclosure, table-row anchoring, and descending sort all verified`.
- [ ] Step 5: Commit:
    ```bash
    git add scripts/gen-mirrors.sh tests/repo-state/mirrors.sh
    git commit -m "tracker mode: gen-mirrors sources issues via tracker.sh list, mode-aware header"
    ```

---

### Task 4: `graduate-parking.sh` creates via `tracker.sh create`

Depends on: Task 2

**Files (exclusive ownership):**
- Modify: `scripts/graduate-parking.sh` (the dry-run print line 74 and the create+parse block lines 77-80)
- Test: `tests/gates/loop-brainstorm.sh` (update the dry-run assertions, lines 42-43)

**Interfaces:**
- Consumes: `scripts/tracker.sh create --label idea --title <t> --body <b>` (prints the new number).
- Produces: unchanged verbose graduation output; the number now comes from `tracker.sh` stdout, not a parsed gh URL.
- Dry-run (`GRADUATE_DRY_RUN=1`) prints one `tracker.sh create` line per parked item instead of one `gh issue create` line.

**Acceptance check:** `bash tests/gates/loop-brainstorm.sh` exits 0 `[executed-check]`

- [ ] Step 1: Update the dry-run assertions in `tests/gates/loop-brainstorm.sh`. Change line 42-43 so the counted command is the seam call, VERBATIM:
    ```bash
    n="$(printf '%s\n' "$out" | grep -c 'tracker.sh create')"
    [ "$n" -eq 2 ] || fail "expected 2 tracker.sh create calls, got $n"
    ```
    Leave the `--label idea`, `Source brief:`, `Restart context:`, and multi-line-continuation assertions (lines 44-47) unchanged - the body and label are still emitted.
- [ ] Step 2: Run `bash tests/gates/loop-brainstorm.sh`; expect FAIL with `expected 2 tracker.sh create calls, got 0` (script still prints `gh issue create`).
- [ ] Step 3: Implement. In `scripts/graduate-parking.sh`:
  - Dry-run branch (line 74): change the printf to `printf "scripts/tracker.sh create --label idea --title '%s' --body:\n" "$title"`.
  - Real branch (lines 77-79): replace the gh call and URL parse with:
    ```bash
    num="$(scripts/tracker.sh create --label idea --title "$title" --body "$body")" \
      || fail "tracker.sh create failed for: $title"
    printf 'Graduated idea #%s: %s\n' "$num" "$title"
    ```
    (The `url` variable and `num="${url##*/}"` line are removed; `tracker.sh` prints the bare number directly. Local mode has no URL to print, so drop the trailing URL line.)
- [ ] Step 4: Run `bash tests/gates/loop-brainstorm.sh`; expect `PASS: loop-brainstorm E absorbed, Reading-the-user intact, graduation previews + dry-runs 2 items with template`.
- [ ] Step 5: Commit:
    ```bash
    git add scripts/graduate-parking.sh tests/gates/loop-brainstorm.sh
    git commit -m "tracker mode: graduate-parking creates via tracker.sh create (backend-agnostic)"
    ```

---

### Task 5: `setup.sh` declares the mode, never detects it

Depends on: Task 1, Task 2, Task 3

**Files (exclusive ownership):**
- Modify: `skills/loop-setup/setup.sh` (whole render/branch flow, lines 41-116)
- Modify: `skills/loop-setup/SKILL.md` (rewrite the git-remote-detection narrative into declared-mode; drop `.scratch`)
- Test: `tests/loop-setup/acceptance.sh` (structural greps + behavioral both-mode / legacy / fail-fast coverage - criteria 1, 2, 3, 5)

**Interfaces:**
- Consumes: `config/repo-state.template.md` with the `## Local tracker` section (Task 1); `scripts/tracker.sh mode get|set` (Task 2).
- Env hooks: `LOOP_TRACKER_ANSWER=github|local` supplies the mode answer non-interactively (mirrors `--dry-run-remote`); `--dry-run-remote` forces remote-present treatment AND skips the gh auth fail-fast and `gh label create`.
- Produces: a rendered `config/repo-state.md` carrying a line-anchored `tracker:` key; in local mode the config includes the `## Local tracker` section with both disclosures; installs `scripts/tracker.sh` into the target repo alongside `scripts/gen-mirrors.sh`.
- Behavior contract:
  - Remote detection is advisory only - used to phrase the suggestion, never to pick the mode.
  - If `config/repo-state.md` already has a `^tracker:` key: skip the question entirely (idempotent, never re-ask); run only the mode-appropriate idempotent finalize.
  - Else determine mode: `LOOP_TRACKER_ANSWER` if set, else `read -r` prompt. Before asking, the MAIN flow prints a remote report to STDOUT (not stderr, so captured output contains it): if a github remote exists print `GitHub remote found: <url> - suggesting tracker: github`; if none, print `No GitHub remote found - choose a tracker mode (no default)` and suggest nothing (never assume local). `determine_mode` itself only resolves the answer and echoes the bare mode word to stdout; its `read -r` prompt text goes to stderr so it never pollutes the captured mode word or the report grep.
  - Fresh repo (no config file): render github or local variant, then `tracker.sh mode set <mode>`.
  - Legacy config (file exists, no key): do NOT re-render (preserve content); just report remote, determine mode, `tracker.sh mode set <mode>`.
  - github finalize: unless `--dry-run-remote`, run the gh auth fail-fast (`gh auth status`, exit non-zero naming the prerequisite if it fails); offer `gh repo create --private` when no remote; ensure the `idea` label; `scripts/gen-mirrors.sh .`.
  - local finalize: `mkdir -p docs/issues`; `scripts/gen-mirrors.sh .` (zero gh).
  - Keep the existing physical (`pwd -P`) symlink resolution and the install-gen-mirrors-into-target behavior.

**Acceptance check:** `bash tests/loop-setup/acceptance.sh` exits 0 `[executed-check]`

- [ ] Step 1: Rewrite `tests/loop-setup/acceptance.sh` VERBATIM (this single file carries criteria 1, 2, 3, and 5):
    ```bash
    #!/usr/bin/env bash
    # loop-setup: declared-mode structural + behavioral. Covers success criteria 1,2,3,5.
    set -uo pipefail
    HERE="$(cd "$(dirname "$0")" && pwd)"
    REPO="$(cd "$HERE/../.." && pwd)"
    SKILL="$REPO/skills/loop-setup/SKILL.md"
    SETUP="$REPO/skills/loop-setup/setup.sh"
    FIX="$REPO/tests/repo-state/fixtures/issues.json"
    fail() { echo "FAIL: $1" >&2; exit 1; }

    # --- structural: SKILL narrates the DECLARED-mode model, not remote-detection guessing ---
    [ -f "$SKILL" ]                       || fail "skills/loop-setup/SKILL.md missing"
    grep -q  '^name: loop-setup' "$SKILL" || fail "frontmatter name is not loop-setup"
    grep -q  'config/repo-state.md' "$SKILL" || fail "loop-setup never writes config/repo-state.md"
    grep -qi 'tracker'           "$SKILL" || fail "loop-setup does not narrate the tracker mode"
    grep -qi 'idea'              "$SKILL" || fail "loop-setup does not mention the idea label"
    grep -q  'scripts/gen-mirrors.sh' "$SKILL" || fail "loop-setup does not cite the mirror regen command"
    grep -qi 'scratch' "$SKILL" && fail "loop-setup SKILL still references the dropped .scratch fallback"
    echo "structural: PASS"
    [ "${LOOP_SETUP_SKIP_BEHAVIOR:-0}" = 1 ] && { echo "PASS: structural only"; exit 0; }
    [ -x "$SETUP" ] || fail "skills/loop-setup/setup.sh missing (runnable core)"

    # --- criterion 1a: fresh LOCAL setup renders the tracker: key; second run is a clean no-op ---
    L="$(mktemp -d)"; trap 'rm -rf "$L"' EXIT
    ( cd "$L" && git init -q )
    ( cd "$L" && LOOP_TRACKER_ANSWER=local "$SETUP" </dev/null ) || fail "local setup exited non-zero"
    grep -q '^tracker: local' "$L/config/repo-state.md" || fail "local config missing 'tracker: local' key"
    # criterion 5: rendered local config discloses BOTH limitations, grep-verifiable
    grep -qi 'cross-repo idea search' "$L/config/repo-state.md" || fail "local config omits the cross-repo-search disclosure"
    grep -qi 'wayfinder requires'     "$L/config/repo-state.md" || fail "local config omits the wayfinder disclosure"
    # second run: no re-ask (stdin closed), exit 0, key not duplicated, still local
    ( cd "$L" && "$SETUP" </dev/null ) || fail "local setup second run errored (should be idempotent)"
    [ "$(grep -c '^tracker:' "$L/config/repo-state.md")" -eq 1 ] || fail "second run duplicated the tracker: key"
    grep -q '^tracker: local' "$L/config/repo-state.md" || fail "second run changed the declared mode"

    # --- criterion 1b: fresh GITHUB setup renders the key; dry-run skips live gh; second run idempotent ---
    G="$(mktemp -d)"; trap 'rm -rf "$L" "$G"' EXIT
    ( cd "$G" && git init -q && git remote add origin https://example.invalid/x.git )
    ( cd "$G" && LOOP_TRACKER_ANSWER=github MIRRORS_JSON_FILE="$FIX" "$SETUP" --dry-run-remote </dev/null ) \
      || fail "github (dry-run) setup errored"
    grep -q '^tracker: github' "$G/config/repo-state.md" || fail "github config missing 'tracker: github' key"
    [ -f "$G/ISSUES.md" ] || fail "github setup did not generate mirrors"
    grep -qi 'cross-repo idea search' "$G/config/repo-state.md" && fail "github config wrongly kept the local disclosure"
    ( cd "$G" && LOOP_TRACKER_ANSWER=github MIRRORS_JSON_FILE="$FIX" "$SETUP" --dry-run-remote </dev/null ) \
      || fail "github setup second run errored"
    [ "$(grep -c '^tracker:' "$G/config/repo-state.md")" -eq 1 ] || fail "github second run duplicated the key"

    # --- criterion 2: keyless legacy config re-asks and reports remote status; suggests github only when found ---
    # 2a: legacy + remote present -> reports the remote URL and suggests tracker: github
    LG1="$(mktemp -d)"; trap 'rm -rf "$L" "$G" "$LG1"' EXIT
    ( cd "$LG1" && git init -q && git remote add origin https://github.com/acme/legacy.git )
    mkdir -p "$LG1/config"; printf '# legacy repo-state, no tracker key\nRemote: x\n' > "$LG1/config/repo-state.md"
    # the remote report is on STDOUT now, so out1 (stdout capture) genuinely carries it
    out1="$( cd "$LG1" && LOOP_TRACKER_ANSWER=github MIRRORS_JSON_FILE="$FIX" "$SETUP" --dry-run-remote </dev/null )" \
      || fail "legacy+remote setup errored"
    printf '%s\n' "$out1" | grep -q 'GitHub remote found' || fail "legacy re-ask did not print the remote report on stdout"
    printf '%s\n' "$out1" | grep -q 'acme/legacy' || fail "remote report did not name the remote"
    printf '%s\n' "$out1" | grep -q 'suggesting tracker: github' || fail "legacy+remote did not suggest tracker: github"
    grep -q '^tracker: github' "$LG1/config/repo-state.md" || fail "legacy re-ask did not write the key"
    grep -q 'legacy repo-state' "$LG1/config/repo-state.md" || fail "legacy re-ask clobbered existing config content"
    # 2b: legacy + NO remote -> reports no-remote on stdout and does NOT suggest github
    LG2="$(mktemp -d)"; trap 'rm -rf "$L" "$G" "$LG1" "$LG2"' EXIT
    ( cd "$LG2" && git init -q )
    mkdir -p "$LG2/config"; printf '# legacy repo-state, no tracker key\n' > "$LG2/config/repo-state.md"
    out2="$( cd "$LG2" && LOOP_TRACKER_ANSWER=local "$SETUP" </dev/null )" || fail "legacy+no-remote setup errored"
    printf '%s\n' "$out2" | grep -q 'No GitHub remote found' || fail "legacy no-remote case did not report absence on stdout"
    printf '%s\n' "$out2" | grep -q 'suggesting tracker: github' && fail "no-remote case wrongly suggested github"
    grep -q '^tracker: local' "$LG2/config/repo-state.md" || fail "legacy no-remote re-ask did not write the key"

    # --- criterion 3: tracker: github with gh unauthenticated/absent fails fast, non-zero, naming the prerequisite ---
    BIN="$(mktemp -d)"; F3="$(mktemp -d)"; trap 'rm -rf "$L" "$G" "$LG1" "$LG2" "$BIN" "$F3"' EXIT
    cat > "$BIN/gh" <<'EOS'
    #!/usr/bin/env bash
    # unauthenticated stub: auth status fails
    [ "$1" = "auth" ] && exit 1
    exit 1
    EOS
    chmod +x "$BIN/gh"
    ( cd "$F3" && git init -q && git remote add origin https://github.com/acme/x.git )
    set +e
    err3="$( cd "$F3" && PATH="$BIN:$PATH" LOOP_TRACKER_ANSWER=github "$SETUP" </dev/null 2>&1 )"
    rc3=$?
    set -e 2>/dev/null || true
    [ "$rc3" -ne 0 ] || fail "github mode with unauth gh did NOT fail fast (exit 0)"
    printf '%s\n' "$err3" | grep -qi 'gh\|auth' || fail "fail-fast message does not name the gh/auth prerequisite"
    echo "PASS: loop-setup declared-mode - criteria 1 (both modes idempotent), 2 (legacy re-ask), 3 (fail-fast), 5 (disclosures)"
    ```
- [ ] Step 2: Run `bash tests/loop-setup/acceptance.sh`; expect FAIL at the structural `tracker` grep (SKILL not yet rewritten) or the first `tracker: local` assertion (setup not yet declaring the mode).
- [ ] Step 3: Implement.
  - Rewrite `skills/loop-setup/setup.sh` per the Behavior contract above. Keep lines 1-39 (shebang, `pwd -P` resolution, `TPL`/`GEN` checks, `--dry-run-remote` flag, remote detection, `mkdir -p`, gen-mirrors install). ADD a tracker.sh install alongside the gen-mirrors install:
    ```bash
    TRK="$REPO/scripts/tracker.sh"
    [ -x "$TRK" ] || fail "tracker.sh not found or not executable: $TRK"
    if [ ! -f scripts/tracker.sh ]; then
      mkdir -p scripts; cp "$TRK" scripts/tracker.sh && chmod +x scripts/tracker.sh
      echo "installed scripts/tracker.sh"
    fi
    ```
    Replace `render_no_remote`/`render_remote` with `render_local`/`render_github`. `render_github` fills the `{{REMOTE_OR_FALLBACK}}` placeholder with the URL and strips the `## Local tracker` section by heading (same shape as the old `/^## Fallback/{skip=1}` rule, now `/^## Local tracker/{skip=1}` ... `/^## /{skip=0}`), dropping the `Render it into` line. `render_local` fills the placeholder with `none (local tracker; see the Local tracker section)`, drops the `Render it into` line, and KEEPS the `## Local tracker` section intact. (The per-line `scratch`/`fallback`/`no remote` scrub is deleted - Task 1 removed those words from the template.)
    Replace the remote-vs-no-remote branch (lines 79-114) with the declared-mode flow:
    ```bash
    report_remote() {    # human-facing remote status -> STDOUT (so callers/tests that capture stdout see it)
      if [ -n "$remote_url" ]; then
        echo "GitHub remote found: $remote_url - suggesting tracker: github"
      else
        echo "No GitHub remote found - choose a tracker mode (no default)"
      fi
    }
    determine_mode() {   # resolves the answer ONLY; echoes the bare mode word to stdout, prompt text to stderr
      if [ -n "${LOOP_TRACKER_ANSWER:-}" ]; then echo "$LOOP_TRACKER_ANSWER"; return; fi
      local ans; printf 'tracker mode (github|local): ' >&2; read -r ans; echo "$ans"
    }

    existing_mode="$(scripts/tracker.sh mode get 2>/dev/null || true)"
    if [ -n "$existing_mode" ]; then
      echo "tracker mode: $existing_mode (declared); not re-asking"
      MODE="$existing_mode"
    else
      report_remote                 # STDOUT report before resolving the mode (never picks a default)
      if [ ! -f config/repo-state.md ]; then
        MODE="$(determine_mode)"
        case "$MODE" in github) render_github "$remote_url" > config/repo-state.md ;;
                        local)  render_local          > config/repo-state.md ;;
                        *) fail "tracker mode must be 'github' or 'local' (got '$MODE')";; esac
        echo "wrote config/repo-state.md (tracker: $MODE)"
      else
        MODE="$(determine_mode)"      # legacy keyless config: keep content, just set the key
        echo "legacy config found; recording tracker: $MODE without re-rendering"
      fi
      scripts/tracker.sh mode set "$MODE" >/dev/null
    fi
    ensure_roadmap
    if [ "$MODE" = github ]; then
      if [ "$DRY_REMOTE" -eq 0 ]; then
        command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 \
          || fail "tracker: github requires an authenticated gh CLI (install gh and run: gh auth login)"
        [ -n "$remote_url" ] || echo "no remote - to create one: gh repo create --private"
        if ! gh label list --limit 200 2>/dev/null | awk '{print $1}' | grep -qx 'idea'; then
          gh label create idea --description "Backlog candidate" 2>/dev/null \
            && echo "created label idea" || echo "label idea not created; continuing"
        else echo "label idea exists; skipping"; fi
      else
        echo "dry-run-remote: skipping gh auth check and gh label create"
      fi
      scripts/gen-mirrors.sh . || fail "gen-mirrors.sh failed"
    else
      mkdir -p docs/issues
      scripts/gen-mirrors.sh . || fail "gen-mirrors.sh failed"   # local source, zero gh
    fi
    echo "loop-setup complete"
    ```
    Note: `render_local`/`render_github` and `determine_mode` must be defined before this block. `ensure_roadmap` stays as-is.
  - Rewrite `skills/loop-setup/SKILL.md` sections "What it does" (items 2, 4, 5) and the Dry-run note: replace the `git remote` detection narrative with the declared-mode story - setup asks the tracker mode once when the key is missing, reports remote status, suggests `tracker: github` only when a remote exists, writes the key via `tracker.sh mode set`, and never re-asks. Document both finalizes (github: auth fail-fast, `gh repo create --private` offer, idea label, mirrors; local: `docs/issues/`, mirrors, zero gh). Remove every mention of `.scratch`. Mention `LOOP_TRACKER_ANSWER` as the test/non-interactive answer hook alongside `--dry-run-remote`.
- [ ] Step 4: Run `bash tests/loop-setup/acceptance.sh`; expect `PASS: loop-setup declared-mode - criteria 1 (both modes idempotent), 2 (legacy re-ask), 3 (fail-fast), 5 (disclosures)`.
- [ ] Step 5: Commit:
    ```bash
    git add skills/loop-setup/setup.sh skills/loop-setup/SKILL.md tests/loop-setup/acceptance.sh
    git commit -m "tracker mode: setup declares tracker mode (asks once, never guesses), installs tracker.sh"
    ```

---

### Task 6: `migrate-tracker.sh` - lossless local to github migration

Depends on: Task 2

**Files (exclusive ownership):**
- Create: `scripts/migrate-tracker.sh` (executable)
- Test: `tests/repo-state/migrate.sh` (new)

**Interfaces:**
- Consumes: `docs/issues/*.md` (local issue files); `scripts/tracker.sh mode set github` (flips the key after a real run).
- Produces: one `gh issue create --title <t> --body <b> --label <labels>` per local issue, preserving title/body/labels; a closed local issue is created then `gh issue close`d. Each real create prints `migrated local #N -> <url>` - that line IS the old->new number map the local-tracker migration disclosure references.
- Ensures labels first: before the create loop it collects the distinct labels across all `docs/issues/*.md` and runs `gh label create <l> 2>/dev/null || true` per label (idempotent), because `gh issue create --label X` aborts if X is not defined on the remote and setup only ever creates the `idea` label. DRY_RUN prints one `gh label create <l>` line per distinct label instead of executing.
- Idempotent / resume-safe: after each successful real create it stamps the source file's frontmatter with `migrated: <url>`, and the loop SKIPS any file already carrying a `^migrated:` line. A mid-run failure therefore leaves the already-created issues stamped; a re-run recreates only the unstamped remainder, never duplicates. Dry-run neither stamps nor skips (it previews all).
- `MIGRATE_DRY_RUN=1` prints the gh commands (label ensures, then one create line per local issue) without executing and without flipping the key.
- Fail-fast on gh auth exactly like tracker.sh (real runs only).
- Note: GitHub assigns its own issue numbers; the local number is not preservable via gh and criterion 6 does not require it. The old local number is referenced in the migrated body for traceability.

**Acceptance check:** `bash tests/repo-state/migrate.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test VERBATIM to `tests/repo-state/migrate.sh`:
    ```bash
    #!/usr/bin/env bash
    # migrate-tracker.sh: dry-run emits one gh issue create per local issue, title/body/labels preserved.
    set -uo pipefail
    HERE="$(cd "$(dirname "$0")" && pwd)"
    REPO="$(cd "$HERE/../.." && pwd)"
    M="$REPO/scripts/migrate-tracker.sh"
    fail() { echo "FAIL: $1" >&2; exit 1; }
    [ -x "$M" ] || fail "scripts/migrate-tracker.sh missing or not executable"

    SB="$(mktemp -d)"; trap 'rm -rf "$SB"' EXIT
    mkdir -p "$SB/docs/issues" "$SB/config"
    printf 'tracker: local\n' > "$SB/config/repo-state.md"
    cat > "$SB/docs/issues/001-crash-on-empty-input.md" <<'EOS'
    ---
    number: 1
    title: crash on empty input
    labels: bug
    state: open
    updated: 2026-08-04T00:00:00Z
    ---
    Steps to reproduce the crash.
    EOS
    cat > "$SB/docs/issues/002-vault-backlog-view.md" <<'EOS'
    ---
    number: 2
    title: vault backlog view
    labels: idea
    state: closed
    updated: 2026-08-04T00:00:00Z
    ---
    A closed idea, should still migrate then close.
    EOS

    out="$( cd "$SB" && MIGRATE_DRY_RUN=1 bash "$M" )" || fail "migrate dry-run exited non-zero"
    creates="$(printf '%s\n' "$out" | grep -c 'gh issue create')"
    [ "$creates" -eq 2 ] || fail "expected 2 gh issue create commands (one per local issue), got $creates"
    printf '%s\n' "$out" | grep -q 'crash on empty input' || fail "title of issue #1 not carried into migration"
    printf '%s\n' "$out" | grep -q 'vault backlog view'   || fail "title of issue #2 not carried into migration"
    printf '%s\n' "$out" | grep -q -- "--label 'bug'"  || fail "labels of issue #1 not preserved"
    printf '%s\n' "$out" | grep -q -- "--label 'idea'" || fail "labels of issue #2 not preserved"
    printf '%s\n' "$out" | grep -q 'gh issue close'  || fail "closed local issue #2 not re-closed after migration"
    # labels must be ensured on the remote BEFORE the creates (gh issue create --label X fails on an undefined label)
    lbl_ln="$(printf '%s\n' "$out" | grep -n 'gh label create bug' | head -1 | cut -d: -f1)"
    crt_ln="$(printf '%s\n' "$out" | grep -n 'gh issue create'     | head -1 | cut -d: -f1)"
    [ -n "$lbl_ln" ] || fail "dry-run did not emit a 'gh label create bug' ensure line"
    [ "$lbl_ln" -lt "$crt_ln" ] || fail "label ensure was not emitted before the issue creates"
    # dry-run must NOT flip the declared mode
    grep -q '^tracker: local' "$SB/config/repo-state.md" || fail "dry-run wrongly changed the tracker key"

    # --- resume after partial failure: a real run skips files already carrying migrated:, recreates only the rest ---
    RB="$(mktemp -d)"; RBIN="$(mktemp -d)"; trap 'rm -rf "$SB" "$RB" "$RBIN"' EXIT
    GHCALLS="$RBIN/gh.calls"
    cat > "$RBIN/gh" <<EOF
    #!/usr/bin/env bash
    echo "\$*" >> "$GHCALLS"
    case "\$1" in
      auth)  exit 0 ;;
      label) exit 0 ;;
      issue) [ "\$2" = create ] && { echo "https://github.com/x/y/issues/50"; exit 0; }; exit 0 ;;
    esac
    exit 0
    EOF
    chmod +x "$RBIN/gh"
    mkdir -p "$RB/docs/issues" "$RB/config" "$RB/scripts"
    printf 'tracker: local\n' > "$RB/config/repo-state.md"
    cp "$REPO/scripts/tracker.sh" "$RB/scripts/tracker.sh"; chmod +x "$RB/scripts/tracker.sh"
    cat > "$RB/docs/issues/001-already-done.md" <<'EOS'
    ---
    number: 1
    title: already migrated issue
    labels: bug
    state: open
    migrated: https://github.com/x/y/issues/11
    updated: 2026-08-04T00:00:00Z
    ---
    body one
    EOS
    cat > "$RB/docs/issues/002-still-pending.md" <<'EOS'
    ---
    number: 2
    title: still pending issue
    labels: bug
    state: open
    updated: 2026-08-04T00:00:00Z
    ---
    body two
    EOS
    ( cd "$RB" && PATH="$RBIN:$PATH" bash "$M" ) >/dev/null || fail "resume (real) migration exited non-zero"
    grep -q 'already migrated issue' "$GHCALLS" && fail "resume recreated issue #1 which already carried migrated:"
    grep -q 'still pending issue'    "$GHCALLS" || fail "resume did not create the un-migrated issue #2"
    grep -q '^migrated:' "$RB/docs/issues/002-still-pending.md" || fail "resume did not stamp issue #2 after creating it"
    echo "PASS: migrate-tracker dry-run emits one create per local issue with title/labels preserved, closes closed ones; resume skips stamped files"
    ```
- [ ] Step 2: Run `bash tests/repo-state/migrate.sh`; expect FAIL with `scripts/migrate-tracker.sh missing or not executable`.
- [ ] Step 3: Implement `scripts/migrate-tracker.sh`. The load-bearing loop is VERBATIM (dry-run output shape is asserted); wrap in `set -uo pipefail` / `fail()`:
    ```bash
    #!/usr/bin/env bash
    # migrate-tracker.sh - recreate every local docs/issues/ file as a GitHub issue (local -> github).
    # MIGRATE_DRY_RUN=1 prints the gh commands without executing. Real runs flip tracker: github at the end.
    set -uo pipefail
    fail() { echo "migrate-tracker: $1" >&2; exit 1; }
    ISSUE_DIR="docs/issues"
    DRY=0; [ "${MIGRATE_DRY_RUN:-0}" = "1" ] && DRY=1
    fm() { grep -E "^$2:" "$1" | head -1 | sed -E "s/^$2:[[:space:]]*//; s/[[:space:]]*$//"; }
    body_of() { awk 'f{print} /^---$/{c++; if(c==2){f=1}}' "$1"; }   # everything after the frontmatter
    stamp_migrated() {   # append a migrated: <url> line inside the FIRST frontmatter block (before its closing ---)
      local f="$1" u="$2" tmp; tmp="$(mktemp)"
      awk -v u="$u" '/^---$/ { d++; if (d==2) print "migrated: " u } { print }' "$f" > "$tmp" && mv "$tmp" "$f"
    }

    if [ "$DRY" = 0 ]; then
      command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 \
        || fail "migration to github requires an authenticated gh CLI (run: gh auth login)"
    fi
    shopt -s nullglob
    files=("$ISSUE_DIR"/*.md)
    [ "${#files[@]}" -gt 0 ] || { echo "migrate-tracker: no local issues in $ISSUE_DIR"; exit 0; }

    # ensure every distinct label exists first - gh issue create --label X aborts if X is not defined on the remote
    labelset="$(for f in "${files[@]}"; do fm "$f" labels; done | tr ',' '\n' \
      | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | grep -v '^$' | sort -u)"
    if [ -n "$labelset" ]; then
      while IFS= read -r lbl; do
        [ -n "$lbl" ] || continue
        if [ "$DRY" = 1 ]; then printf 'gh label create %s\n' "$lbl"
        else gh label create "$lbl" 2>/dev/null || true; fi
      done <<< "$labelset"
    fi

    for f in "${files[@]}"; do
      # resume-safe: a real run skips any file already stamped migrated: (a prior partial run created it).
      # dry-run never skips - it previews every issue.
      if [ "$DRY" = 0 ] && grep -q '^migrated:' "$f"; then
        echo "skip: local #$(fm "$f" number) already migrated ($(fm "$f" migrated))"; continue
      fi
      num="$(fm "$f" number)"; title="$(fm "$f" title)"; labels="$(fm "$f" labels)"; state="$(fm "$f" state)"
      body="$(printf '%s\n---\nMigrated from local issue #%s\n' "$(body_of "$f")" "$num")"
      if [ "$DRY" = 1 ]; then
        printf "gh issue create --title '%s' --label '%s' --body <migrated body of local #%s>\n" "$title" "$labels" "$num"
        [ "$state" = closed ] && printf "gh issue close <new #> (local #%s was closed)\n" "$num"
      else
        url="$(gh issue create --title "$title" --label "$labels" --body "$body")" \
          || fail "gh issue create failed for local #$num ($title)"
        new="${url##*/}"
        stamp_migrated "$f" "$url"   # record BEFORE anything else so a re-run after a later failure skips this file
        echo "migrated local #$num -> $url"
        [ "$state" = closed ] && { gh issue close "$new" >/dev/null && echo "  re-closed #$new (was closed locally)"; }
      fi
    done
    [ "$DRY" = 0 ] && { scripts/tracker.sh mode set github >/dev/null; echo "flipped tracker: github"; }
    ```
    `chmod +x scripts/migrate-tracker.sh`. Note: `gh issue create --label` accepts a comma-separated list, so multi-label local issues (`labels: bug,idea`) pass through in one flag.
- [ ] Step 4: Run `bash tests/repo-state/migrate.sh`; expect `PASS: migrate-tracker dry-run emits one create per local issue with title/labels preserved, closes closed ones; resume skips stamped files`.
- [ ] Step 5: Commit:
    ```bash
    git add scripts/migrate-tracker.sh tests/repo-state/migrate.sh
    git commit -m "tracker mode: migrate-tracker.sh local->github migration with dry-run"
    ```

---

### Task 7: Full local-mode workflow, gh absent (criterion 4)

Depends on: Task 2, Task 3, Task 4, Task 5

**Files (exclusive ownership):**
- Test: `tests/repo-state/local-workflow.sh` (new - this task adds no production code; it proves the assembled local lane runs gh-free end to end)

**Interfaces:**
- Consumes: `skills/loop-setup/setup.sh` (local mode), `scripts/tracker.sh create`, `scripts/gen-mirrors.sh .`, `scripts/graduate-parking.sh <brief>` - all as assembled by Tasks 2-5.
- Produces: nothing; a passing integration gate.

**Acceptance check:** `bash tests/repo-state/local-workflow.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test VERBATIM to `tests/repo-state/local-workflow.sh`:
    ```bash
    #!/usr/bin/env bash
    # Criterion 4: the whole local-mode workflow - setup, create issues, regenerate mirrors,
    # graduate a brief's parking lot - runs to exit 0 with gh proven UNCALLED, and the mirrors
    # render from the local files with labels intact.
    set -uo pipefail
    HERE="$(cd "$(dirname "$0")" && pwd)"
    REPO="$(cd "$HERE/../.." && pwd)"
    SETUP="$REPO/skills/loop-setup/setup.sh"
    fail() { echo "FAIL: $1" >&2; exit 1; }

    # gh stub at the FRONT of PATH that records every call and fails: if any step touches gh, we catch it.
    BIN="$(mktemp -d)"; SB="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB"' EXIT
    GHLOG="$BIN/gh.calls"
    cat > "$BIN/gh" <<EOF
    #!/usr/bin/env bash
    echo "GH CALLED: \$*" >> "$GHLOG"
    exit 1
    EOF
    chmod +x "$BIN/gh"
    export PATH="$BIN:$PATH"

    cd "$SB" && git init -q     # NO remote: a deliberately-off-GitHub repo

    # 1. setup in local mode (declared, not detected)
    LOOP_TRACKER_ANSWER=local "$SETUP" </dev/null || fail "local setup exited non-zero"
    grep -q '^tracker: local' config/repo-state.md || fail "setup did not declare tracker: local"
    [ -x scripts/tracker.sh ]    || fail "setup did not install scripts/tracker.sh into the local repo"
    [ -x scripts/gen-mirrors.sh ] || fail "setup did not install scripts/gen-mirrors.sh into the local repo"

    # 2. create issues directly through the seam (one plain, one idea)
    scripts/tracker.sh create --label bug  --title "Crash on empty input" --body "repro steps" >/dev/null \
      || fail "tracker.sh create (bug) failed"
    scripts/tracker.sh create --label idea --title "Cross-repo digest idea" --body "an idea" >/dev/null \
      || fail "tracker.sh create (idea) failed"

    # 3. regenerate mirrors from the local files
    scripts/gen-mirrors.sh . || fail "gen-mirrors.sh failed in local mode"
    grep -Eq '^\| *1 *\|' ISSUES.md  || fail "bug issue #1 did not render into ISSUES.md"
    grep -Eq '^\| *2 *\|' BACKLOG.md  || fail "idea issue #2 did not render into BACKLOG.md"
    grep -q 'bug'  ISSUES.md  || fail "labels lost: 'bug' not in ISSUES.md"
    grep -q 'idea' BACKLOG.md || fail "labels lost: 'idea' not in BACKLOG.md"

    # 4. graduate a brief's parking lot into local backlog issues
    cat > brief.md <<'EOS'
    ## Parking lot

    - A parked local thread: revisit the enrichment idea later.

    ## Out of scope
    EOS
    "$REPO/scripts/graduate-parking.sh" brief.md || fail "graduate-parking.sh failed in local mode"
    grep -Rql 'revisit the enrichment idea later' docs/issues/ \
      || fail "graduated parking item did not land as a local issue file"

    # THE criterion: not one gh invocation across the entire workflow
    [ ! -s "$GHLOG" ] || { echo "gh was invoked during the local workflow:"; cat "$GHLOG"; fail "local workflow is not gh-free"; }
    echo "PASS: full local-mode workflow (setup->create->mirrors->graduate) ran to exit 0 with zero gh calls and labels intact"
    ```
- [ ] Step 2: Run `bash tests/repo-state/local-workflow.sh`; before Tasks 2-5 are complete it FAILs early (e.g. `setup did not declare tracker: local`). After they are complete it should pass; run it here to confirm the assembled lane holds.
- [ ] Step 3: No production code - this task is the integration gate. If it fails, the defect is in the Task it exercises (2-5); fix there, not here.
- [ ] Step 4: Run `bash tests/repo-state/local-workflow.sh`; expect `PASS: full local-mode workflow (setup->create->mirrors->graduate) ran to exit 0 with zero gh calls and labels intact`.
- [ ] Step 5: Commit:
    ```bash
    git add tests/repo-state/local-workflow.sh
    git commit -m "tracker mode: end-to-end local-mode workflow gate (criterion 4, gh-absent)"
    ```

---

### Task 8: Prose fixes - stray gh assumptions in skills and roadmap

Depends on: none

**Files (exclusive ownership):**
- Modify: `skills/loop-brainstorm/SKILL.md` (line 201: `gh issue close <num>`)
- Modify: `skills/wayfinder/SKILL.md` (add a disclosed `requires tracker: github` note)
- Modify: `ROADMAP.md` (lines 6, 14: the `gh issue list --label idea` references)

**Interfaces:**
- Consumes: the `scripts/tracker.sh close` verb (Task 2) - referenced in prose only, no execution.
- Produces: skill/roadmap prose that no longer hard-codes a github-only tracker verb where the backend is now declared.

**Acceptance check:** `bash tests/gates/check.sh && bash tests/gates/wayfinder.sh && bash tests/gates/loop-brainstorm.sh` exits 0 `[executed-check]`

- [ ] Step 1: There is no failing-test-first for pure prose; the guard is that the existing gate tests still pass after the edits. Run `bash tests/gates/check.sh` and `bash tests/gates/wayfinder.sh` first to capture the green baseline.
- [ ] Step 2: Make the edits.
  - `skills/loop-brainstorm/SKILL.md` line 201: change `Reverse a graduated issue with \`gh issue close <num>\`.` to `Reverse a graduated issue with \`scripts/tracker.sh close <num>\` (backend-agnostic; works in either tracker mode).`
  - `skills/wayfinder/SKILL.md`: add one disclosed line near the top (after the intro paragraph, before `## Plan, don't do`): `Wayfinder requires \`tracker: github\`: its map and tickets are GitHub issues end to end, with no local-tracker variant (a disclosed limitation, promotable later).` No local branch - out of scope per the brief.
  - `ROADMAP.md`: line 6 change `Ideas not yet scheduled live on the backlog (\`gh issue list --label idea\`, mirror \`BACKLOG.md\`).` to reference the mode-agnostic mirror: `Ideas not yet scheduled live on the backlog - see the \`BACKLOG.md\` mirror (regenerated by \`scripts/gen-mirrors.sh .\`, backend per \`tracker:\`).` line 14 change `Revisit parked backlog ideas as they come due: \`gh issue list --label idea\`.` to `Revisit parked backlog ideas as they come due: see \`BACKLOG.md\`.`
- [ ] Step 3: Not applicable (prose only).
- [ ] Step 4: Run `bash tests/gates/check.sh` (registry still fresh, no newly-untagged gate-signal line), `bash tests/gates/wayfinder.sh` (added note is additive), and `bash tests/gates/loop-brainstorm.sh` (graduation greps unaffected); expect all three to PASS.
- [ ] Step 5: Commit:
    ```bash
    git add skills/loop-brainstorm/SKILL.md skills/wayfinder/SKILL.md ROADMAP.md
    git commit -m "tracker mode: prose fixes - backend-agnostic close verb, wayfinder github requirement, roadmap mirror refs"
    ```

---

## Self-review (performed; edits applied inline above)

1. **Brief coverage - all six criteria map to an executed-check:**
   - Criterion 1 (fresh setup renders `tracker:` key each mode; second run exits 0, no re-ask/dup) -> Task 5, `tests/loop-setup/acceptance.sh` (blocks 1a local, 1b github).
   - Criterion 2 (keyless legacy re-asks, reports remote-found/no-remote, suggests github only when found) -> Task 5, acceptance.sh criterion-2 blocks 2a/2b.
   - Criterion 3 (`tracker: github` + gh unauth/absent fails fast non-zero, names prerequisite) -> Task 5, acceptance.sh criterion-3 block.
   - Criterion 4 (full local workflow gh-absent, mirrors render with labels) -> Task 7, `tests/repo-state/local-workflow.sh`.
   - Criterion 5 (rendered local config discloses both limitations, grep-verifiable) -> Task 5, acceptance.sh block 1a (folded in - see Decisions).
   - Criterion 6 (migration lossless, dry-run comparable) -> Task 6, `tests/repo-state/migrate.sh`.
   No gap. No `[judgment]` criteria exist.
2. **Placeholder scan:** no TBD/TODO, no "similar to Task N", no "handle edge cases" without naming them. Every named edge case (keyless config hard-fail, all-punctuation title -> `NNN-issue.md`, body line beginning `state:`, empty `labels:` on bash 3.2, quote/backslash/pipe in a title, closed issue in migration, empty issue set -> `[]`, multi-label pass-through, undefined remote label, resume after partial migration, second-run idempotency, gh-absent vs unauth) has explicit handling and, where behavioral, an executed assertion.
3. **Type/name consistency:** the subcommand names Task 2 defines (`mode get`, `mode set`, `list`, `create --label/--title/--body`, `close`, `reopen`) are exactly the ones Task 3 (`list`, `mode get`), Task 4 (`create`), Task 5 (`mode get`, `mode set`), Task 6 (`mode set`), and Task 8 (`close`) call. The local issue-file frontmatter keys (`number/title/labels/state/updated`, plus the migration-only `migrated:` stamp) and the gh-JSON output keys (`number/title/labels[].name/updatedAt`) are consistent across tracker.sh emit, gen-mirrors consumption, and migrate-tracker parse; the extra `migrated:` line is inert to `list`/gen-mirrors (their `fm` reads named keys only). The mode is bound in the PARENT scope (`mode="$(tracker_mode_get)" || fail`), never a `require_mode` subshell whose `fail` would not abort the parent under `set -uo pipefail`; `local_set_state` is the awk form scoped to the first frontmatter block (rewrites `state:` and refreshes `updated:` only there).
4. **Loop-drive contract:** every task states scope, an executed (not judged) acceptance command, exclusive file ownership, complete depends-on, and reads in isolation. Parallel sets touch disjoint files: {Task 1, Task 2} disjoint; {Task 3, Task 4, Task 6} disjoint; Task 5 and Task 7 are dependency-ordered after their subjects; Task 8 owns files no other task touches. `scripts/tracker.sh` is created by exactly one task (Task 2); every consumer depends on it. The Rubix-accepted edits changed only the CONTENTS of already-owned files (Task 1's template/config/config-test, Task 2's tracker.sh + its test, Task 5's setup + acceptance test, Task 6's migrate-tracker + its test); no file ownership moved and the dependency graph is unchanged - Task 5 still depends on Tasks 1, 2, 3.
5. **Agnosticism:** no step invokes a loop-stack skill (`/loop-*`); steps use only repo scripts (`scripts/*.sh`, `skills/loop-setup/setup.sh`) and standard tools (bash, awk, sed, grep, git, gh). An executor who never heard of loop-stack can run every acceptance command.

## Decisions made that the fixed design did not fully pin down

- **Rubix-accepted revisions (applied inline above):** idempotent, resume-safe migration via a `migrated: <url>` frontmatter stamp with skip-on-restamp; pre-ensuring every distinct label with `gh label create` before the create loop; `local_set_state` rewritten as an awk pass scoped to the first frontmatter block (rewrites `state:`, refreshes `updated:`, never clobbers a body line beginning `state:`); a keyless/modeless repo now hard-fails (parent-scope `mode="$(tracker_mode_get)" || fail`) instead of silently defaulting to local; the setup remote report moved to STDOUT so criterion 2 actually tests it; `slugify` empty-slug fallback to `issue`; a bash-3.2 empty-`labels:` guard; a stale-mirror stderr reminder on local mutations; and the expanded local-tracker disclosures (single-linear-writer numbering, migration renumber + old->new map, direct-edit key guidance). Notable DECLINES: no edit/comment verb on `tracker.sh` (out of scope; issues are edited by hand in local mode); no auto-regeneration of ISSUES.md/BACKLOG.md on mutation (on-demand only, reminder not daemon); no `jq` dependency (local mode stays zero-dependency, `json_escape` ceiling documented); and no gen-mirrors gh-fallback for un-upgraded installs - those repos re-run loop-setup (see the upgrade note).
- **Criterion 5 test placement:** folded into Task 5's `acceptance.sh` (block 1a) rather than a standalone file, because setup already renders a local config there - a separate file would re-render the identical config for one grep. Still an executed-check, still grep-verifiable; the mapping stays 5 -> Task 5.
- **Disclosures are template-resident, stripped in github render:** matching the existing `render_remote`/`render_no_remote` divergence (the old code stripped the `## Fallback` section by heading). The `## Local tracker` section lives in the template and is kept by `render_local`, dropped by `render_github`. This mirrors the current repo's own config, which likewise carries the full template section set.
- **`tracker:` key is written by `tracker.sh mode set`, not baked as a template literal:** exactly parallel to `autonomy-default:` (documented in prose, written only when set). The template carries no literal `tracker:` line; setup renders the config then calls `mode set`. This repo's committed `config/repo-state.md` does get a literal `tracker: github` line (Task 1) since it is already set up.
- **`migrate-tracker.sh` is NOT installed into target repos** by setup (only `tracker.sh` and `gen-mirrors.sh` are), because no success criterion runs migration from a target; criterion 6 invokes the loop-stack copy against a sandbox cwd, matching how other tests invoke `$REPO/scripts/...`. If field use wants per-repo migration, add the copy line to setup later.
- **The cross-repo `gh search issues` line stays in both config variants;** local mode does not delete it but explicitly discloses (in the `## Local tracker` section) that a local repo is invisible to it. Minimal change, honest disclosure, satisfies criterion 5 without extra scrubbing.
- **gh-absent is covered by the same `gh auth status` fail-fast as unauth:** when gh is not on PATH the guard's `command -v gh` (and the auth call's non-zero exit) trips the same message, so criterion 3's "unauthenticated OR absent" is one code path, tested with an always-failing gh stub.
- **`gen-mirrors` header mode lookup is best-effort** (`tracker.sh mode get 2>/dev/null || true`, default `GitHub issues`): the fixture-hook path has no guaranteed config in cwd, and defaulting to the github label keeps the existing `tests/repo-state/mirrors.sh` "source of truth" assertion green.
