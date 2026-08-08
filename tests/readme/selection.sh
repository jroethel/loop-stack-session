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
