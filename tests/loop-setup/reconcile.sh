#!/usr/bin/env bash
# Reconcile: stale/keyless config re-render (criterion 1) and github render drops the
# dangling Local-tracker reference (criterion 5); a current config is a no-op (idempotency).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SETUP="$REPO/skills/loop-setup/setup.sh"
FIX="$REPO/tests/repo-state/fixtures/issues.json"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$SETUP" ] || fail "setup.sh missing"

# --- reference: a clean local setup carries the current template-version ---
REF="$(mktemp -d)"; trap 'rm -rf "$REF"' EXIT
( cd "$REF" && git init -q && LOOP_TRACKER_ANSWER=local "$SETUP" </dev/null >/dev/null ) \
  || fail "reference local setup failed"
grep -q '^template-version:' "$REF/config/repo-state.md" \
  || fail "fresh local config carries no template-version stamp"

# --- criterion 1: a keyless/older config is detected; decline = byte-identical, accept = current render ---
S="$(mktemp -d)"; trap 'rm -rf "$REF" "$S"' EXIT
( cd "$S" && git init -q )
mkdir -p "$S/config"
# legacy config: has the tracker key (mode is not re-asked) but NO template-version stamp
printf 'old legacy body, hand notes\ntracker: local\n' > "$S/config/repo-state.md"

# decline (LOOP_ASSUME_NO) leaves the file byte-identical
before="$(cat "$S/config/repo-state.md")"
( cd "$S" && LOOP_ASSUME_NO=1 "$SETUP" </dev/null >/dev/null ) || fail "declined reconcile exited non-zero"
after="$(cat "$S/config/repo-state.md")"
[ "$before" = "$after" ] || fail "declined reconcile changed the config (must be byte-identical)"

# accept (LOOP_ASSUME_YES) re-renders to match a fresh render of the current template
( cd "$S" && LOOP_ASSUME_YES=1 "$SETUP" </dev/null >/dev/null ) || fail "accepted reconcile exited non-zero"
diff "$REF/config/repo-state.md" "$S/config/repo-state.md" \
  || fail "accepted re-render does not match the current fresh render"

# a config already at the current version reports nothing
out="$( cd "$S" && "$SETUP" </dev/null )" || fail "third run errored"
printf '%s\n' "$out" | grep -qi 'stale' && fail "config already current still reported as stale"
[ "$(grep -c '^tracker:' "$S/config/repo-state.md")" -eq 1 ] || fail "reconcile duplicated the tracker key"

# --- criterion 5: github render carries no reference to the stripped Local tracker section ---
G="$(mktemp -d)"; trap 'rm -rf "$REF" "$S" "$G"' EXIT
( cd "$G" && git init -q && git remote add origin https://github.com/acme/x.git )
( cd "$G" && LOOP_TRACKER_ANSWER=github MIRRORS_JSON_FILE="$FIX" "$SETUP" --dry-run-remote </dev/null >/dev/null ) \
  || fail "github setup errored"
grep -qi 'Local tracker' "$G/config/repo-state.md" \
  && fail "github config still references the Local tracker section"
grep -q '^template-version:' "$G/config/repo-state.md" \
  || fail "github config carries no template-version stamp"

echo "PASS: reconcile - stale/keyless detect+re-render (criterion 1), github render drops Local-tracker (criterion 5), current config is a no-op"
