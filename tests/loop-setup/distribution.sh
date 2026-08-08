#!/usr/bin/env bash
# setup.sh installs graduate-parking.sh into the target repo and refreshes drifted vendored scripts.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SETUP="$REPO/skills/loop-setup/setup.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$SETUP" ] || fail "skills/loop-setup/setup.sh missing or not executable"

# --- criterion 1: fresh local setup installs an executable graduate-parking.sh, and a dry-run
#     graduation of a parking-lot fixture succeeds using the installed copy ---
L="$(mktemp -d)"; trap 'rm -rf "$L"' EXIT
( cd "$L" && git init -q )
( cd "$L" && LOOP_TRACKER_ANSWER=local "$SETUP" </dev/null ) || fail "local setup exited non-zero"
[ -x "$L/scripts/graduate-parking.sh" ] || fail "setup did not install an executable scripts/graduate-parking.sh"

cat > "$L/brief.md" <<'EOS'
# Brief

## Parking lot

- Add a widget cache. Restart context: revisit after the v2 cutover.
EOS
grad_out="$( cd "$L" && GRADUATE_DRY_RUN=1 ./scripts/graduate-parking.sh brief.md )" \
  || fail "dry-run graduation via the installed script exited non-zero"
printf '%s\n' "$grad_out" | grep -q "Add a widget cache" \
  || fail "dry-run graduation did not emit a create command for the parked item"

# --- criterion 5: on a re-run, a drifted vendored script is detected and an assented refresh
#     restores it; declining leaves the drift in place ---
# Drift the installed tracker.sh, then re-run setup with assent -> file is restored to loop-stack's copy.
printf '\n# LOCAL DRIFT MARKER\n' >> "$L/scripts/tracker.sh"
cmp -s "$L/scripts/tracker.sh" "$REPO/scripts/tracker.sh" \
  && fail "test setup error: drift marker did not change tracker.sh"
( cd "$L" && LOOP_ASSUME_YES=1 "$SETUP" </dev/null ) || fail "re-run (assent) setup exited non-zero"
cmp -s "$L/scripts/tracker.sh" "$REPO/scripts/tracker.sh" \
  || fail "assented refresh did not restore scripts/tracker.sh to loop-stack's copy"

# Drift again, re-run with decline -> the drift stays (file NOT restored).
printf '\n# LOCAL DRIFT MARKER 2\n' >> "$L/scripts/tracker.sh"
( cd "$L" && LOOP_ASSUME_NO=1 "$SETUP" </dev/null ) || fail "re-run (decline) setup exited non-zero"
cmp -s "$L/scripts/tracker.sh" "$REPO/scripts/tracker.sh" \
  && fail "declined refresh wrongly overwrote scripts/tracker.sh"
grep -q 'LOCAL DRIFT MARKER 2' "$L/scripts/tracker.sh" \
  || fail "declined refresh did not leave the drifted file untouched"

echo "PASS: setup installs graduate-parking.sh, dry-run graduation works, drift refresh assents and declines correctly"
