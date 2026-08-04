#!/usr/bin/env bash
# gen-mirrors.sh splits idea/non-idea, discloses a header, never calls live gh under the fixture hook.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
GEN="$REPO/scripts/gen-mirrors.sh"
FIX="$HERE/fixtures/issues.json"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$GEN" ] || fail "scripts/gen-mirrors.sh missing or not executable"

OUT="$(mktemp -d)"; trap 'rm -rf "$OUT"' EXIT
MIRRORS_JSON_FILE="$FIX" "$GEN" "$OUT" || fail "gen-mirrors exited non-zero under fixture"

[ -f "$OUT/ISSUES.md" ]  || fail "ISSUES.md not written"
[ -f "$OUT/BACKLOG.md" ] || fail "BACKLOG.md not written"
# disclosure headers
grep -qi 'DO NOT EDIT'          "$OUT/ISSUES.md"  || fail "ISSUES.md missing DO NOT EDIT disclosure"
grep -qi 'regenerate'           "$OUT/ISSUES.md"  || fail "ISSUES.md missing regen command"
grep -qi 'source of truth'      "$OUT/BACKLOG.md" || fail "BACKLOG.md missing source-of-truth disclosure"
# lane split, anchored to a real table row (bare grep '101' would match timestamps/counts)
row() { grep -En "^\| *$1 *\|" "$2" | head -1 | cut -d: -f1; }  # -> line number of the #N row, empty if absent
[ -n "$(row 101 "$OUT/BACKLOG.md")" ] || fail "idea issue #101 is not a table row in BACKLOG.md"
[ -n "$(row 103 "$OUT/BACKLOG.md")" ] || fail "idea issue #103 is not a table row in BACKLOG.md"
[ -z "$(row 101 "$OUT/ISSUES.md")"  ] || fail "idea issue #101 leaked into ISSUES.md"
[ -n "$(row 102 "$OUT/ISSUES.md")"  ] || fail "non-idea issue #102 is not a table row in ISSUES.md"
[ -z "$(row 102 "$OUT/BACKLOG.md")" ] || fail "non-idea issue #102 leaked into BACKLOG.md"
# descending sort by number: within BACKLOG, #103's row must precede #101's row
[ "$(row 103 "$OUT/BACKLOG.md")" -lt "$(row 101 "$OUT/BACKLOG.md")" ] \
  || fail "BACKLOG.md not sorted by issue number descending (#103 should precede #101)"

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
echo "PASS: mirror split, disclosure, table-row anchoring, and descending sort all verified"
