#!/usr/bin/env bash
# Reconcile: stale/keyless config re-render (criterion 1) and github render drops the
# dangling Local-tracker reference (criterion 5); a current config is a no-op (idempotency).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SETUP="$REPO/skills/loop-setup/setup.sh"
TPL="$REPO/config/repo-state.template.md"
FIX="$REPO/tests/repo-state/fixtures/issues.json"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$SETUP" ] || fail "setup.sh missing"
TV="$(grep -E '^template-version:' "$TPL" | head -1 | sed -E 's/^template-version:[[:space:]]*//; s/[[:space:]]*$//')"

# --- reference: a clean local setup carries the current template-version ---
REF="$(mktemp -d)"; trap 'rm -rf "$REF"' EXIT
( cd "$REF" && git init -q && LOOP_TRACKER_ANSWER=local "$SETUP" </dev/null >/dev/null ) \
  || fail "reference local setup failed"
grep -q '^template-version:' "$REF/config/repo-state.md" \
  || fail "fresh local config carries no template-version stamp"

# fresh render stamps the grammar key with today's date
grep -q "^filename-grammar-since: $(date +%Y-%m-%d)\$" "$REF/config/repo-state.md" \
  || fail "fresh render did not stamp filename-grammar-since with today's date"

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

# v4 is a two-file shape: the accepted re-render also produces conventions.md, verbatim from the template
[ -f "$S/config/conventions.md" ] || fail "accepted re-render did not create config/conventions.md"
diff "$REPO/config/conventions.template.md" "$S/config/conventions.md" \
  || fail "rendered conventions.md is not a verbatim copy of the template"
# the reworked v4 template must still feed the render anchors: the rendered machine surface
# carries the tracker-backend disclosure and never leaks the template-only render instruction
grep -q '(github, gitlab, or local)' "$S/config/repo-state.md" \
  || fail "v4 render lost the tracker-backend disclosure (template intro anchor broken)"
! grep -q 'Render it into' "$S/config/repo-state.md" \
  || fail "v4 render leaked the template-only 'Render it into' instruction"

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

# --- v2-era fixture: a v4 re-render preserves every line-anchored key (Remote, tracker,
#     autonomy-default, tracker-remote-ack), not just the two the v3 reconcile carried ---
V="$(mktemp -d)"; trap 'rm -rf "$REF" "$S" "$G" "$V"' EXIT
( cd "$V" && git init -q )
mkdir -p "$V/config"
cat > "$V/config/repo-state.md" <<'EOS'
# Repo State Map

template-version: 2
filename-grammar-since: 2026-01-01

Remote: none (local tracker; see the Local tracker section)
tracker: local
autonomy-default: auto
tracker-remote-ack: github

old v2 doctrine prose that should be dropped from the machine surface
EOS
( cd "$V" && LOOP_ASSUME_YES=1 "$SETUP" </dev/null >/dev/null ) || fail "v2 accept re-render exited non-zero"
grep -q "^template-version: $TV\$"     "$V/config/repo-state.md" || fail "v2->current re-render did not bump the version to $TV"
grep -q '^tracker: local$'             "$V/config/repo-state.md" || fail "v4 re-render dropped tracker:"
grep -q '^autonomy-default: auto$'     "$V/config/repo-state.md" || fail "v4 re-render dropped autonomy-default:"
grep -q '^tracker-remote-ack: github$' "$V/config/repo-state.md" || fail "v4 re-render dropped tracker-remote-ack:"
[ -f "$V/config/conventions.md" ]                                || fail "v4 re-render did not create conventions.md"
grep -q '^filename-grammar-since: 2026-01-01$' "$V/config/repo-state.md" \
  || fail "accepted re-render did not preserve the earlier filename-grammar-since date"
[ "$(grep -c '^filename-grammar-since:' "$V/config/repo-state.md")" -eq 1 ] \
  || fail "reconcile duplicated the filename-grammar-since key (renderer plus carry-forward)"

echo "PASS: reconcile - stale/keyless detect+re-render (criterion 1), github render drops Local-tracker (criterion 5), current config is a no-op"
