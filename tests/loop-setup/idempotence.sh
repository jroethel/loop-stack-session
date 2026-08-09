#!/usr/bin/env bash
# Criteria 7 and 8 (revised): the sweep runs in all three modes behind one gate question then
# per-item confirmation; archive-on-import makes a settled repo offer nothing on re-run and SAY
# so; a declined-and-left candidate re-offers next run (durability lives in the archive move,
# not a state file); remote modes need LOOP_IMPORT_REMOTE for unattended creation, and the gate
# keys on the unattended variable, never on MODE; --dry-run-remote never creates; docs/plans/
# and root project files are never offered; the archive move never overwrites and never
# reaches outside the repo; mirrors are re-rendered after an importing sweep.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SETUP="$REPO/skills/loop-setup/setup.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$SETUP" ] || fail "setup.sh missing"

mk() {   # $1 = dir; a local-mode repo with one root candidate and one docs candidate
  mkdir -p "$1/docs"
  ( cd "$1" && git init -q )
  printf '# What is next\nLabel: idea\nship the thing\n' > "$1/whats_next.md"
  printf '# The todo\nLabel: idea\ndo the work\n'        > "$1/docs/some-todo.md"
}

# ---------- criterion 7: gate then per-item in local mode; the repo root is reached ----------
A="$(mktemp -d)"; trap 'rm -rf "$A"' EXIT
mk "$A"
# never offered: docs/plans/ is a governed lane, and a root PLAN.md is a project document
mkdir -p "$A/docs/plans" "$A/docs/nested"
printf '# Old plan\nLabel: idea\nsettled work\n'   > "$A/docs/plans/2020-01-01-old-plan.md"
printf '# Plan\nLabel: idea\nproject file\n'       > "$A/PLAN.md"
# offered: the root-name exclusion is depth-1 only, so a nested PLAN.md stays a candidate
printf '# Nested plan\nLabel: idea\nnested work\n' > "$A/docs/nested/PLAN.md"
out="$( cd "$A" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_YES=1 "$SETUP" </dev/null 2>/dev/null )" \
  || fail "local sweep run exited non-zero"
# the count line prints to stdout BEFORE the gate, because ask() returns without printing its
# prompt when LOOP_ASSUME_* is set - the count is the only always-visible trace of the gate
printf '%s\n' "$out" | grep -q 'found 3 import candidate' || fail "sweep did not announce its candidate count"
printf '%s\n' "$out" | grep -qi 'import candidate:' || fail "sweep offered no candidates in local mode"
# the ROOT file is reached - the current scan roots miss it, which is the forge bug
printf '%s\n' "$out" | grep -q 'whats_next.md' || fail "sweep did not reach the repo-root whats_next.md"
printf '%s\n' "$out" | grep -q 'docs/some-todo.md' || fail "sweep did not reach docs/some-todo.md"
printf '%s\n' "$out" | grep -q 'docs/nested/PLAN.md' \
  || fail "a nested PLAN.md stopped being a candidate (the root-name exclusion must be depth-1 only)"
printf '%s\n' "$out" | grep -q 'docs/plans/' \
  && fail "the sweep offered a plan-lane file (docs/plans/ archival is owned by the Archive-and-graduation rules)"
printf '%s\n' "$out" | grep -q 'import candidate: PLAN.md ' \
  && fail "the sweep offered the root PLAN.md project file"
[ "$(ls "$A/docs/issues"/*.md 2>/dev/null | wc -l)" -eq 3 ] || fail "accept-all did not create three issues"
# accept-all also accepts the archive offer, so the imported sources moved and the originals are gone
[ -f "$A/docs/archive/whats_next.md" ] || fail "imported root candidate was not archived"
[ -f "$A/docs/archive/some-todo.md" ]  || fail "imported docs candidate was not archived"
[ -f "$A/docs/archive/PLAN.md" ]       || fail "imported nested candidate was not archived"
[ -f "$A/whats_next.md" ] && fail "archived candidate still present at its original path"
[ -f "$A/PLAN.md" ] || fail "the excluded root PLAN.md was moved or deleted"
[ -f "$A/docs/plans/2020-01-01-old-plan.md" ] || fail "the excluded plan-lane file was moved or deleted"
# an importing sweep re-renders the mirrors, so the run never ends over stale ISSUES/BACKLOG
grep -q 'What is next' "$A/BACKLOG.md" || fail "the mirrors were not re-rendered after the sweep imported issues"

# ---------- criterion 8 (revised): the settled repo offers nothing AND says so ----------
# No state file: quiet follows from the archive move alone (docs/archive/* is excluded from the scan).
out2="$( cd "$A" && "$SETUP" </dev/null 2>/dev/null )" || fail "second run exited non-zero"
printf '%s\n' "$out2" | grep -qi 'import candidate' && fail "settled repo re-offered a candidate"
printf '%s\n' "$out2" | grep -qi 'nothing to do'    || fail "settled repo went quiet instead of saying nothing to do"

# ---------- a NEW candidate appearing later is offered; archived ones stay quiet ----------
printf '# Todo\nLabel: idea\nnew work\n' > "$A/docs/late-todo.md"
out3="$( cd "$A" && LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>/dev/null )" || fail "new-candidate run exited non-zero"
printf '%s\n' "$out3" | grep -q 'found 1 import candidate' \
  || fail "a newly added candidate was not picked up (or an archived one leaked back in)"

# ---------- declined-and-left re-offers next run: the CONTRACT, not a bug ----------
B="$(mktemp -d)"; trap 'rm -rf "$A" "$B"' EXIT
mk "$B"
outB="$( cd "$B" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>/dev/null )" \
  || fail "decline-at-gate run exited non-zero"
[ "$(printf '%s\n' "$outB" | grep -c 'found 2 import candidate')" -eq 1 ] \
  || fail "the candidate count was not announced exactly once"
printf '%s\n' "$outB" | grep -qi 'import candidate:' && fail "a declined gate still offered items"
# the false direction of the summary line: a run that OFFERED the gate may never claim quiet
printf '%s\n' "$outB" | grep -qi 'nothing to do' && fail "a run that offered the gate claimed nothing to do"
[ -f "$B/whats_next.md" ] || fail "a declined run touched a candidate file"
find "$B/docs/issues" -name '*.md' 2>/dev/null | grep -q . && fail "a declined run created issues"
outB2="$( cd "$B" && LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>/dev/null )" \
  || fail "post-decline re-run exited non-zero"
printf '%s\n' "$outB2" | grep -q 'found 2 import candidate' \
  || fail "declined-and-left candidates were not re-offered on the next run (nothing may suppress them)"

# ---------- the archive move never overwrites: same-basename candidates collide safely ----------
K="$(mktemp -d)"; trap 'rm -rf "$A" "$B" "$K"' EXIT
mkdir -p "$K/docs/a" "$K/docs/b"
( cd "$K" && git init -q )
printf '# First todo\nLabel: idea\none\n'  > "$K/docs/a/dup-todo.md"
printf '# Second todo\nLabel: idea\ntwo\n' > "$K/docs/b/dup-todo.md"
outK="$( cd "$K" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_YES=1 "$SETUP" </dev/null 2>/dev/null )" \
  || fail "collision run exited non-zero"
[ "$(ls "$K/docs/issues"/*.md 2>/dev/null | wc -l)" -eq 2 ] || fail "collision run did not import both candidates"
[ -f "$K/docs/archive/dup-todo.md" ] || fail "no candidate reached the archive"
[ -f "$K/docs/a/dup-todo.md" ] || [ -f "$K/docs/b/dup-todo.md" ] \
  || fail "BOTH same-basename candidates were moved onto one archive path - the first was silently destroyed"
printf '%s\n' "$outK" | grep -qi 'skip' || fail "the skipped collision move did not say so"

# ---------- an out-of-tree --scan candidate is imported but NEVER archived into this repo ----------
# tests/loop-setup/import.sh already runs `--scan "$(mktemp -d)"` under LOOP_ASSUME_YES, so
# without this guard the existing suite's first post-Task-4 run would move a file out of an
# unrelated directory and stay green.
L="$(mktemp -d)"; XT="$(mktemp -d)"; trap 'rm -rf "$A" "$B" "$K" "$L" "$XT"' EXIT
( cd "$L" && git init -q )
printf '# Extra todo\nLabel: idea\nelsewhere\n' > "$XT/extra-todo.md"
outL="$( cd "$L" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_YES=1 "$SETUP" --scan "$XT" </dev/null 2>/dev/null )" \
  || fail "out-of-tree scan run exited non-zero"
printf '%s\n' "$outL" | grep -q 'found 1 import candidate' || fail "the --scan candidate was not found"
[ "$(ls "$L/docs/issues"/*.md 2>/dev/null | wc -l)" -eq 1 ] || fail "the --scan candidate was not imported"
[ -f "$XT/extra-todo.md" ] \
  || fail "an out-of-tree candidate was moved out of its directory (no archive offer may reach outside the repo)"
find "$L/docs/archive" -name 'extra-todo.md' 2>/dev/null | grep -q . \
  && fail "an out-of-tree candidate landed in this repo's archive"

# ---------- criterion 7: the sweep also runs in github mode ----------
D="$(mktemp -d)"; FIX="$REPO/tests/repo-state/fixtures/issues.json"
trap 'rm -rf "$A" "$B" "$K" "$L" "$XT" "$D"' EXIT
mk "$D"
( cd "$D" && git remote add origin https://github.com/acme/x.git )
out6="$( cd "$D" && LOOP_TRACKER_ANSWER=github MIRRORS_JSON_FILE="$FIX" LOOP_ASSUME_NO=1 \
         "$SETUP" --dry-run-remote </dev/null 2>/dev/null )" || fail "github sweep run exited non-zero"
printf '%s\n' "$out6" | grep -q 'found 2 import candidate' \
  || fail "the sweep did not run in github mode (criterion 7)"

# ---------- criterion 7: gitlab mode, and the remote-creation safety gate ----------
BIN="$(mktemp -d)"; E="$(mktemp -d)"
trap 'rm -rf "$A" "$B" "$K" "$L" "$XT" "$D" "$BIN" "$E"' EXIT
GLOG="$BIN/glab.calls"
cat > "$BIN/glab" <<'STUB'
#!/usr/bin/env bash
echo "GLAB CALLED: $*" >> "$GLAB_LOG"
if [ "$1" = auth ] && [ "$2" = status ]; then
  for a in "$@"; do [ "$a" = --hostname ] && exit 0; done
  exit 1
fi
if [ "$1" = issue ] && [ "$2" = list ]; then exit 0; fi
if [ "$1" = issue ] && [ "$2" = create ]; then
  [ "${GLAB_CREATE_FAIL:-0}" = 1 ] && { echo "ERROR 403" >&2; exit 1; }
  n=$(( $(cat "$GLAB_N" 2>/dev/null || echo 200) + 1 )); echo "$n" > "$GLAB_N"
  echo "https://gitlab.example.com/grp/repo/-/issues/$n"; exit 0
fi
if [ "$1" = label ] && [ "$2" = list ]; then echo "[]"; exit 0; fi
exit 0
STUB
chmod +x "$BIN/glab"
export GLAB_LOG="$GLOG" GLAB_N="$BIN/n"
mk "$E"
( cd "$E" && git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git' )

# SAFETY FIRST: LOOP_ASSUME_YES alone must NOT create issues on a remote instance.
out7="$( cd "$E" && PATH="$BIN:$PATH" LOOP_TRACKER_ANSWER=gitlab LOOP_ASSUME_YES=1 \
         "$SETUP" </dev/null 2>&1 )" || fail "gitlab sweep run exited non-zero"
printf '%s\n' "$out7" | grep -q 'found 2 import candidate' \
  || fail "the sweep did not run in gitlab mode (criterion 7)"
printf '%s\n' "$out7" | grep -q 'set LOOP_IMPORT_REMOTE=1' \
  || fail "unattended remote import was neither performed nor explained"
grep -q 'GLAB CALLED: issue create' "$GLOG" \
  && fail "LOOP_ASSUME_YES alone created remote issues without LOOP_IMPORT_REMOTE"
[ -f "$E/whats_next.md" ] \
  || fail "a skipped remote import still archived or removed the candidate (nothing was imported)"

# --dry-run-remote keeps its promise even with every unattended gate open: nothing is created.
# Without a DRY_REMOTE term in the sweep's gate, this exact invocation would file real issues.
: > "$GLOG"
outDR="$( cd "$E" && PATH="$BIN:$PATH" MIRRORS_JSON_FILE="$FIX" LOOP_ASSUME_YES=1 LOOP_IMPORT_REMOTE=1 \
          "$SETUP" --dry-run-remote </dev/null 2>&1 )" || fail "dry-run gitlab sweep exited non-zero"
grep -q 'GLAB CALLED: issue create' "$GLOG" \
  && fail "--dry-run-remote created remote issues (the flag promises no remote calls)"
printf '%s\n' "$outDR" | grep -q 'skipping remote import of' \
  || fail "the dry-run remote-import skip was silent (the finalize's own dry-run line does not count)"
[ -f "$E/whats_next.md" ] || fail "a dry-run archived a candidate whose issue was never created"

# With the explicit opt-in, the sweep creates through the glab backend and archives the sources.
: > "$GLOG"
out8="$( cd "$E" && PATH="$BIN:$PATH" LOOP_ASSUME_YES=1 LOOP_IMPORT_REMOTE=1 \
         "$SETUP" </dev/null 2>&1 )" || fail "opted-in gitlab sweep exited non-zero"
[ "$(grep -c 'GLAB CALLED: issue create' "$GLOG")" -eq 2 ] \
  || fail "the opted-in sweep did not create exactly two remote issues"
[ -f "$E/docs/archive/whats_next.md" ] || fail "the opted-in sweep did not archive the imported candidate"
find "$E/docs/issues" -name '*.md' 2>/dev/null | grep -q . \
  && fail "gitlab mode wrote local issue files instead of creating remote issues"

# ---------- the remote gate keys on the unattended variable, never on MODE ----------
# Interactive per-item answers create remote issues with no extra variable; a gate that keyed
# on MODE being remote would break exactly the interactive path Task 7 Steps 2 and 3 rely on.
M="$(mktemp -d)"; trap 'rm -rf "$A" "$B" "$K" "$L" "$XT" "$D" "$BIN" "$E" "$M"' EXIT
mk "$M"
( cd "$M" && git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git' )
: > "$GLOG"
outM="$( cd "$M" && printf 'y\ny\ny\ny\ny\ny\ny\ny\ny\ny\ny\ny\n' | \
         PATH="$BIN:$PATH" LOOP_TRACKER_ANSWER=gitlab "$SETUP" 2>&1 )" \
  || fail "interactive gitlab sweep exited non-zero"
[ "$(grep -c 'GLAB CALLED: issue create' "$GLOG")" -eq 2 ] \
  || fail "interactive per-item yes did not create both remote issues (the gate must key on LOOP_ASSUME_YES, not MODE)"
printf '%s\n' "$outM" | grep -q 'set LOOP_IMPORT_REMOTE=1' \
  && fail "an interactive run was told to set LOOP_IMPORT_REMOTE (the variable gates unattended runs only)"

# ---------- a failed create is never treated as imported: no archive, no "imported" line ----------
# On a shared instance a create can fail partway (label, permission, rate); archiving a file
# whose issue does not exist would lose the only copy of the work item.
N="$(mktemp -d)"; trap 'rm -rf "$A" "$B" "$K" "$L" "$XT" "$D" "$BIN" "$E" "$M" "$N"' EXIT
mk "$N"
( cd "$N" && git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git' )
: > "$GLOG"
outN="$( cd "$N" && PATH="$BIN:$PATH" GLAB_CREATE_FAIL=1 LOOP_TRACKER_ANSWER=gitlab \
         LOOP_ASSUME_YES=1 LOOP_IMPORT_REMOTE=1 "$SETUP" </dev/null 2>&1 )" \
  || fail "a run with failing creates aborted instead of skipping and continuing"
printf '%s\n' "$outN" | grep -q 'create failed' || fail "a failed create was not reported"
printf '%s\n' "$outN" | grep -q 'imported '     && fail "a failed create was announced as imported"
[ -f "$N/whats_next.md" ] || fail "a candidate whose create failed was archived or removed"
find "$N/docs/archive" -name '*.md' 2>/dev/null | grep -q . \
  && fail "a failed create still produced an archive move"

echo "PASS: loop-setup universal sweep"
