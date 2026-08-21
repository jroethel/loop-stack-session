#!/usr/bin/env bash
# Gate consumption is LIVE, and the autonomy protocol lives in the loop-auto skill (its single
# home); the managed block stays lean - footguns, skill routing, and the /loop-auto pointer only.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
CMD="$REPO/claude-md/fable.md"
LA="$REPO/skills/loop-auto/SKILL.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$CMD" ] || fail "claude-md/fable.md missing"
[ -f "$LA" ]  || fail "skills/loop-auto/SKILL.md missing"
# The staged-only disclaimers must be gone everywhere.
grep -qi 'records intent only' "$CMD" "$LA" && fail "a file still says 'records intent only' (consumption not live)"
grep -qi 'still fire their gates live regardless' "$CMD" "$LA" && fail "the staged disclaimer survives"
# The managed block stays lean (Fable footguns only) and keeps the never-a-worker invariant;
# routing lives entirely in skill descriptions now that superpowers is uninstalled.
grep -qi 'superpowers' "$CMD" && fail "managed block re-grew superpowers arbitration lines (plugin is uninstalled)"
grep -Eqi 'never a worker|never.*spawns it' "$CMD" || fail "managed block lost the Fable never-a-worker invariant"
# The block must NOT re-absorb the protocol (that is the bloat this layout retired).
grep -qi 'batch-review list' "$CMD" && fail "managed block re-absorbed the journal protocol (belongs in loop-auto)"
# The four gate classes and their auto-mode behavior live in the loop-auto skill.
for t in ASK STOP BATCH DEFAULT; do
  grep -q "$t" "$LA" || fail "gate class $t not described in loop-auto"
done
# The journal (batch-review list) protocol: created when autonomy takes effect, appended per gate, reversal path.
grep -qi 'batch-review list' "$LA" || fail "journal/batch-review protocol missing from loop-auto"
grep -Eqi 'appended at every gate|appended per gate' "$LA" || fail "per-gate append rule missing from loop-auto"
grep -qi 'reversal' "$LA" || fail "reversal-path field missing from loop-auto"
# Live-consumption language is present (the knob changes behavior).
grep -q 'Consumption is live: the knob now governs gate behavior per the four gate classes below.' "$LA" || fail "verbatim live-consumption sentence missing from loop-auto"
# On 'set auto', offers already on the table are re-presented as one ASK, never auto-taken as DEFAULTs (#13).
grep -qi 'outstanding before autonomy commences' "$LA" || fail "on-set-auto re-presentation ASK missing from loop-auto"
echo "PASS: consumption live, protocol homed in loop-auto, managed block lean with pointer + invariant"
