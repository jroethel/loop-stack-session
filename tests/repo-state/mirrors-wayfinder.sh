#!/usr/bin/env bash
# gen-mirrors.sh renders open wayfinder:map issues into WAYFINDER.md: one section per map,
# with child tickets carrying type, open/closed state, and Blocked-by - never touching gh live.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
GEN="$REPO/scripts/gen-mirrors.sh"
FIX="$HERE/fixtures/issues-wayfinder.json"
CHILDREN_DIR="$HERE/fixtures/wayfinder-children"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$GEN" ] || fail "scripts/gen-mirrors.sh missing or not executable"

OUT="$(mktemp -d)"; trap 'rm -rf "$OUT"' EXIT
MIRRORS_JSON_FILE="$FIX" MIRRORS_CHILDREN_DIR="$CHILDREN_DIR" "$GEN" "$OUT" \
  || fail "gen-mirrors exited non-zero under fixture"

[ -f "$OUT/WAYFINDER.md" ] || fail "WAYFINDER.md not written"
grep -qi 'DO NOT EDIT'     "$OUT/WAYFINDER.md" || fail "WAYFINDER.md missing DO NOT EDIT disclosure"
grep -q 'Wayfinder map: pick storage (#91)' "$OUT/WAYFINDER.md" || fail "map title/number heading missing"

row() { grep -En "^\| *$1 *\|" "$2" | head -1; }
r5="$(row 5 "$OUT/WAYFINDER.md")"; [ -n "$r5" ] || fail "child ticket #5 is not a table row"
printf '%s' "$r5" | grep -q 'research' || fail "ticket #5 missing its research type"
printf '%s' "$r5" | grep -q 'closed'   || fail "ticket #5 missing its closed state"
r6="$(row 6 "$OUT/WAYFINDER.md")"; [ -n "$r6" ] || fail "child ticket #6 is not a table row"
printf '%s' "$r6" | grep -q 'grilling' || fail "ticket #6 missing its grilling type"
printf '%s' "$r6" | grep -q 'open'     || fail "ticket #6 missing its open state"
printf '%s' "$r6" | grep -Eq '\| *5 *\|$' || fail "ticket #6 missing Blocked-by #5"

# wayfinder:map issue #91 itself never leaks into ISSUES.md/BACKLOG.md
grep -Eq '^\| *91 *\|' "$OUT/ISSUES.md" "$OUT/BACKLOG.md" && fail "map issue #91 leaked into a mirror"

# no maps: WAYFINDER.md still written, discloses the empty state
OUT2="$(mktemp -d)"; trap 'rm -rf "$OUT" "$OUT2"' EXIT
NOMAPS="$HERE/fixtures/issues.json"
MIRRORS_JSON_FILE="$NOMAPS" "$GEN" "$OUT2" || fail "gen-mirrors exited non-zero with no maps"
grep -qi 'no open wayfinder maps' "$OUT2/WAYFINDER.md" || fail "empty-map disclosure missing"

echo "PASS: WAYFINDER.md renders map + children (type, state, blocked-by), excluded from other mirrors"
