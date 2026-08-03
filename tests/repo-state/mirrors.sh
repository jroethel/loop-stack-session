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
echo "PASS: mirror split, disclosure, table-row anchoring, and descending sort all verified"
