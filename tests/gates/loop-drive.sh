#!/usr/bin/env bash
# loop-drive gains the compile dispatch, the existing-_loop.md entry point, and splits the
# double-STOP line; the spec-edit gate relaxes to the sized BATCH rule.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
S="$REPO/skills/loop-drive/SKILL.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$S" ] || fail "loop-drive SKILL missing"
# G: compile dispatch at the drive-compile role pin, covering steps 1-4 and 6.
grep -qi 'drive-compile' "$S" || fail "no drive-compile role-pin reference"
grep -qi 'compile' "$S" || fail "no compile-dispatch language"
# Entry point: start from an existing _loop.md.
grep -Eqi 'existing .*_loop\.md|start from an existing' "$S" || fail "no start-from-existing-_loop.md entry point"
# STOP split: no single line carries two [gate:STOP] tags.
if grep -nE '\[gate:STOP\].*\[gate:STOP\]' "$S"; then fail "a line still carries two STOP tags (duplicate registry row)"; fi
# The spec-edit gate now relaxes to a sized BATCH on ONE line: threshold and BATCH tag co-occur.
grep -E '15 (or fewer )?lines?' "$S" | grep -q '\[gate:BATCH\]' \
  || fail "the sized spec-edit rule (15 lines) and its BATCH tag are not on the same line"
grep -Eqi 'single unit|single criterion|one unit' "$S" || fail "spec-edit single-unit condition not stated"
grep -qE '\[gate:STOP\]' "$S" || fail "loop-drive lost its STOP tags"
echo "PASS: loop-drive compile dispatch, entry point, STOP split, and sized spec-edit gate present"
