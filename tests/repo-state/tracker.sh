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
