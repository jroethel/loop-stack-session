#!/usr/bin/env bash
# Tidy (criterion 4): inventory untracked .scratch/ byproducts with per-item deletion offers;
# decline keeps, accept deletes, nothing deletes without acceptance. Idempotency (criterion 6):
# a fully-reconciled repo re-run reports nothing to reconcile.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SETUP="$REPO/skills/loop-setup/setup.sh"
TIDY="$REPO/scripts/tidy.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$TIDY" ]  || fail "scripts/tidy.sh missing or not executable"
[ -x "$SETUP" ] || fail "setup.sh missing"

# --- criterion 4: decline keeps everything, and every byproduct is inventoried ---
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
( cd "$T" && git init -q )
mkdir -p "$T/.scratch/run-a"
echo one > "$T/.scratch/run-a/notes.txt"
echo two > "$T/.scratch/stray.log"
out="$( cd "$T" && LOOP_ASSUME_NO=1 "$TIDY" )" || fail "tidy (decline) exited non-zero"
printf '%s\n' "$out" | grep -q '.scratch/run-a/notes.txt' || fail "tidy did not inventory notes.txt"
printf '%s\n' "$out" | grep -q '.scratch/stray.log'       || fail "tidy did not inventory stray.log"
[ -f "$T/.scratch/run-a/notes.txt" ] || fail "declined tidy deleted notes.txt"
[ -f "$T/.scratch/stray.log" ]       || fail "declined tidy deleted stray.log"

# --- criterion 4: accept deletes the byproducts ---
( cd "$T" && LOOP_ASSUME_YES=1 "$TIDY" ) >/dev/null || fail "tidy (accept) exited non-zero"
[ ! -f "$T/.scratch/run-a/notes.txt" ] || fail "accepted tidy did not delete notes.txt"
[ ! -f "$T/.scratch/stray.log" ]       || fail "accepted tidy did not delete stray.log"

# --- a repo with no byproducts reports nothing ---
out2="$( cd "$T" && "$TIDY" )" || fail "tidy on a clean repo exited non-zero"
printf '%s\n' "$out2" | grep -qi 'byproduct' \
  && fail "tidy inventoried a byproduct on a repo with none"

# --- criterion 6: after all offers are resolved, a re-run reports nothing to reconcile ---
C="$(mktemp -d)"; trap 'rm -rf "$T" "$C"' EXIT
( cd "$C" && git init -q )
( cd "$C" && LOOP_TRACKER_ANSWER=local "$SETUP" </dev/null >/dev/null ) || fail "initial setup errored"
out3="$( cd "$C" && "$SETUP" </dev/null )" || fail "second setup run errored"
printf '%s\n' "$out3" | grep -qi 'stale'           && fail "idempotent re-run reported a stale config"
printf '%s\n' "$out3" | grep -qi 'import candidate' && fail "idempotent re-run reported an import candidate"
printf '%s\n' "$out3" | grep -qi 'byproduct'        && fail "idempotent re-run reported a tidy byproduct"

echo "PASS: tidy - inventory + per-item delete offers (criterion 4); fully-reconciled repo is a no-op (criterion 6)"
