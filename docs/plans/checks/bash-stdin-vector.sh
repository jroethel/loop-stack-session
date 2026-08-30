#!/usr/bin/env bash
# Bash-path evidence: a piped-`y` stdin stream files an issue with NO env flag (the 406 double-gate
# never fires because its LOOP_ASSUME_YES=1 test is false), and the memo bash section was written.
set -uo pipefail
SETUP="$(pwd)/skills/loop-setup/setup.sh"
M="$(pwd)/docs/memos/2026-08-29-import-gate-diagnosis.md"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
( cd "$T" && git init -q )
mkdir -p "$T/docs"; printf '# Fix the thing\nLabel: idea\nMARKER_STDIN\n' > "$T/docs/fix-thing.md"
# 'local' answers the mode prompt; the y-stream answers every ask() with no LOOP_ASSUME_YES set.
( cd "$T" && printf 'local\ny\ny\ny\ny\n' | "$SETUP" >/dev/null 2>&1 )
grep -Rq 'MARKER_STDIN' "$T/docs/issues/" 2>/dev/null \
  || { echo "FAIL: piped-y stdin did NOT file an issue (vector not reproduced)"; exit 1; }
grep -q '^## Bash reconcile_import fallback' "$M" \
  || { echo "FAIL: memo is missing the '## Bash reconcile_import fallback' section"; exit 1; }
echo "PASS: bash path - piped-y stdin files an issue with no env flag; memo section present"
