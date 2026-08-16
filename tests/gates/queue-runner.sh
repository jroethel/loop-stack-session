#!/usr/bin/env bash
# The queue-runner reference exists, invokes the scripted one-per-run primitive (incl. stale relaunch),
# claims + evidenced-dones through the guard, lists all five boundary terms, and stays portable.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; REPO="$(cd "$HERE/../.." && pwd)"
Q="$REPO/skills/loop-drive/references/queue-runner.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$Q" ] || fail "queue-runner reference missing"
grep -q 'tracker.sh next-eligible' "$Q" || fail "prompt does not invoke the scripted selection primitive"
grep -q 'tracker.sh claim'         "$Q" || fail "prompt does not claim via the claim-lock"
grep -q 'tracker.sh done'          "$Q" || fail "prompt does not complete via the evidence-gated done"
grep -qi 'reclaim'                 "$Q" || fail "prompt has no stale-working relaunch path"
grep -Eqi 'at most one|one .* per run|exactly one' "$Q" || fail "one-per-run stop rule absent"
grep -qi 'STOP' "$Q" || fail "boundary gate class (STOP) not named"
for term in publish deploy delete email billing credential; do
  grep -qi "$term" "$Q" || fail "boundary-first list missing '$term'"
done
grep -Eqi 'claude code|claude-code|claude\.ai' "$Q" && fail "prompt carries a Claude-Code-specific field (must stay portable)"
echo "PASS: queue-runner wires primitives, stale relaunch, one-per-run, full boundary list, portable"
