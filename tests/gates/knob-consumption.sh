#!/usr/bin/env bash
# The managed block declares gate consumption LIVE (not staged) and keeps the full four-gate
# protocol plus the journal-append rules.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
CMD="$REPO/claude-md/fable.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$CMD" ] || fail "claude-md/fable.md missing"
# The staged-only disclaimers must be gone.
grep -qi 'records intent only' "$CMD" && fail "managed block still says 'records intent only' (consumption not made live)"
grep -qi 'still fire their gates live regardless' "$CMD" && fail "managed block still carries the staged disclaimer"
# The four gate classes and their auto-mode behavior remain.
grep -qi '## *Chain autonomy' "$CMD" || fail "missing Chain autonomy section"
for t in ASK STOP BATCH DEFAULT; do
  grep -q "$t" "$CMD" || fail "gate class $t not described"
done
# The journal (batch-review list) protocol remains: created when autonomy takes effect, appended per gate, with a reversal path.
grep -qi 'batch-review list' "$CMD" || fail "journal/batch-review protocol dropped"
grep -Eqi 'appended at every gate|appended per gate' "$CMD" || fail "per-gate append rule dropped"
grep -qi 'reversal' "$CMD" || fail "reversal-path field dropped"
# Live-consumption language is present (the knob now changes behavior).
grep -q 'Consumption is live: the knob now governs gate behavior per the four gate classes below.' "$CMD" || fail "verbatim live-consumption sentence missing"
echo "PASS: managed block consumption is live, four gate classes and journal protocol intact"
