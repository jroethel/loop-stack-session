#!/usr/bin/env bash
# migrate-tracker.sh --to gitlab: labels first, one issue per local file, closed issues re-closed,
# frontmatter stamped, mode flipped to gitlab. Dry run prints glab commands and touches nothing.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
M="$REPO/scripts/migrate-tracker.sh"
TRK="$REPO/scripts/tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$M" ] || fail "scripts/migrate-tracker.sh missing"

BIN="$(mktemp -d)"; SB="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB"' EXIT
LOG="$BIN/glab.calls"
cat > "$BIN/glab" <<EOF
#!/usr/bin/env bash
echo "GLAB CALLED: \$*" >> "$LOG"
if [ "\$1" = auth ] && [ "\$2" = status ]; then
  for a in "\$@"; do [ "\$a" = --hostname ] && exit 0; done
  exit 1
fi
if [ "\$1" = issue ] && [ "\$2" = create ]; then
  n=\$(( \$(cat "$BIN/n" 2>/dev/null || echo 100) + 1 )); echo "\$n" > "$BIN/n"
  echo "https://gitlab.example.com/grp/repo/-/issues/\$n"
  exit 0
fi
exit 0
EOF
chmod +x "$BIN/glab"
# gh stub: the default-target dry run below must not depend on this host's real gh auth state
cat > "$BIN/gh" <<'STUB'
#!/usr/bin/env bash
[ "$1" = auth ] && exit 0
if [ "$1" = issue ] && [ "$2" = create ]; then echo "https://github.com/acme/x/issues/9"; exit 0; fi
exit 0
STUB
chmod +x "$BIN/gh"
export PATH="$BIN:$PATH"

mkdir -p "$SB/scripts" "$SB/config" "$SB/docs/issues"
cp "$TRK" "$SB/scripts/tracker.sh"; chmod +x "$SB/scripts/tracker.sh"
( cd "$SB" && git init -q && git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git' )
printf 'tracker: local\n' > "$SB/config/repo-state.md"

cat > "$SB/docs/issues/001-open-one.md" <<'EOS'
---
number: 1
title: an open item
labels: idea
state: open
updated: 2026-08-01T00:00:00Z
---
body one
EOS
cat > "$SB/docs/issues/002-closed-one.md" <<'EOS'
---
number: 2
title: a closed item
labels:
state: closed
updated: 2026-08-01T00:00:00Z
---
body two
EOS

# --- dry run prints glab commands and changes nothing ---
before="$(cat "$SB/docs/issues/001-open-one.md")"
out="$( cd "$SB" && MIGRATE_DRY_RUN=1 "$M" --to gitlab )" || fail "dry run exited non-zero"
printf '%s\n' "$out" | grep -q 'glab issue create' || fail "dry run did not print glab issue create"
printf '%s\n' "$out" | grep -q 'gh issue create'   && fail "dry run printed gh commands for a gitlab target"
printf '%s\n' "$out" | grep -q 'glab label create' || fail "dry run did not print glab label create"
[ "$before" = "$(cat "$SB/docs/issues/001-open-one.md")" ] || fail "dry run modified a local issue file"
[ "$(grep '^tracker:' "$SB/config/repo-state.md")" = "tracker: local" ] || fail "dry run flipped the mode"

# --- the default target is still github, asserted POSITIVELY while the files are unstamped ---
# `|| true` with only a negative grep would pass vacuously if --to became mandatory (a usage
# error contains no glab line either); this must run BEFORE the real run stamps every file.
out2="$( cd "$SB" && MIGRATE_DRY_RUN=1 "$M" )" || fail "default-target dry run exited non-zero"
printf '%s\n' "$out2" | grep -q 'gh issue create'   || fail "the default github dry run printed no gh issue create"
printf '%s\n' "$out2" | grep -q 'glab issue create' && fail "the default target became gitlab"

# --- real run ---
( cd "$SB" && LOOP_ASSUME_NO=1 "$M" --to gitlab >/dev/null 2>&1 ) || fail "real run exited non-zero"
grep -q 'GLAB CALLED: auth status --hostname gitlab.example.com' "$LOG" \
  || fail "migration did not run a --hostname-scoped auth status"
grep -E 'GLAB CALLED: auth status$' "$LOG" && fail "migration ran a BARE glab auth status"
grep -q 'GLAB CALLED: label create --name idea' "$LOG" || fail "migration did not pre-create the idea label"
[ "$(grep -c 'GLAB CALLED: issue create' "$LOG")" -eq 2 ] || fail "migration did not create exactly two issues"
grep -q 'GLAB CALLED: issue close' "$LOG" || fail "migration did not re-close the locally-closed issue"
grep -q '^migrated: https://gitlab.example.com' "$SB/docs/issues/001-open-one.md" \
  || fail "migrated file was not stamped with its new URL"
grep -q '^state: migrated' "$SB/docs/issues/001-open-one.md" || fail "migrated file state was not frozen"
[ "$(grep '^tracker:' "$SB/config/repo-state.md")" = "tracker: gitlab" ] || fail "mode was not flipped to gitlab"

# --- a second real run is a no-op: every file is already stamped ---
: > "$LOG"
( cd "$SB" && LOOP_ASSUME_NO=1 "$M" --to gitlab >/dev/null 2>&1 ) || fail "re-run exited non-zero"
grep -q 'GLAB CALLED: issue create' "$LOG" && fail "re-run re-created an already-migrated issue"

# --- an unknown target is rejected ---
( cd "$SB" && MIGRATE_DRY_RUN=1 "$M" --to bitbucket >/dev/null 2>&1 ) && fail "an unknown target was accepted"

# --- a real run on UNTRACKED issue files still exits 0 (the git rm exit-status fix) ---
# The files in $SB were never `git add`ed, so the end-of-run `git rm --cached` cannot succeed;
# a successful migration must not inherit that failure as its exit status.
V="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB" "$V"' EXIT
mkdir -p "$V/scripts" "$V/config" "$V/docs/issues"
cp "$TRK" "$V/scripts/tracker.sh"; chmod +x "$V/scripts/tracker.sh"
( cd "$V" && git init -q && git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git' )
printf 'tracker: local\n' > "$V/config/repo-state.md"
cp "$SB/docs/issues/001-open-one.md" "$V/docs/issues/001-open-one.md"
sed -i.bak '/^migrated:/d; s/^state: migrated/state: open/' "$V/docs/issues/001-open-one.md"
rm -f "$V/docs/issues/001-open-one.md.bak"
( cd "$V" && LOOP_ASSUME_YES=1 "$M" --to gitlab >/dev/null 2>&1 ) \
  || fail "a successful migration reported failure because git rm --cached hit untracked files"
[ -f "$V/docs/issues/001-open-one.md" ] || fail "the frozen audit file was removed from disk"

# --- setup.sh vendors migrate-tracker.sh, so the SKILL.md suggestion names a real path ---
SETUP="$REPO/skills/loop-setup/setup.sh"
W="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB" "$V" "$W"' EXIT
( cd "$W" && git init -q )
( cd "$W" && LOOP_TRACKER_ANSWER=local LOOP_ASSUME_NO=1 "$SETUP" </dev/null >/dev/null 2>&1 ) \
  || fail "vendoring setup run exited non-zero"
[ -x "$W/scripts/migrate-tracker.sh" ] \
  || fail "setup.sh did not vendor migrate-tracker.sh (the documented command would be a dangling path)"

echo "PASS: migrate-tracker gitlab target"
