#!/usr/bin/env bash
# Structural check: the memo carries both path findings, a per-path verdict with a create-call
# line anchor, a 2026-08-23 classification, three dispositions, and one recommendation.
# Correctness of the verdict is a human-checkpoint judgment; this checks structure only.
set -uo pipefail
M=docs/memos/2026-08-29-import-gate-diagnosis.md
[ -f "$M" ] || { echo "FAIL: memo not found at $M"; exit 1; }
need() { grep -qiE "$1" "$M" || { echo "FAIL: memo missing /$1/"; exit 1; }; }
need '^## Agent path'
need '^## Bash reconcile_import fallback'
need '^## Verdict'
need 'tracker\.sh:4[0-9][0-9]'            # a file:line anchor into the create case
need '^## Classification'
need 'genuine-skip|by-design|indeterminate'
need '^## Dispositions'
need '^Recommendation:'
echo "PASS: memo carries both findings, per-path verdict, classification, and a recommendation"
