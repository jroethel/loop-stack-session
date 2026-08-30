#!/usr/bin/env bash
# Agent-path evidence: the prose approval step exists, tracker.sh create AND its call-tree carry
# no gate, and the memo's agent-path section was written.
set -uo pipefail
IT=skills/loop-setup/references/import-triage.md
TR=scripts/tracker.sh
M=docs/memos/2026-08-29-import-gate-diagnosis.md
# The create case block, sliced from `create)` to the next top-level case `close|reopen)`:
if sed -n '/^  create)/,/^  close|reopen)/p' "$TR" | grep -qE 'ask|/dev/tty|confirm|approv'; then
  echo "FAIL: tracker.sh create block contains an approval/ask gate (agent path is NOT ungated)"; exit 1
fi
# The create call-tree helpers (gh_guard 28-31, glab_guard 47-54, local_create 100-118):
if sed -n '28,31p;47,54p;100,118p' "$TR" | grep -qE 'ask "|/dev/tty|confirm|approv'; then
  echo "FAIL: a create-call-tree helper contains an approval step"; exit 1
fi
grep -q 'Approval is the human' "$IT" \
  || { echo "FAIL: import-triage.md prose approval step ('Approval is the human') not found"; exit 1; }
grep -q 'scripts/tracker.sh create' "$IT" \
  || { echo "FAIL: import-triage.md does not name the tracker.sh create call the agent reaches"; exit 1; }
grep -q '^## Agent path' "$M" \
  || { echo "FAIL: memo is missing the '## Agent path' section (deliverable not written)"; exit 1; }
echo "PASS: agent path - prose approval is the only gate; tracker.sh create call-tree is ungated"
