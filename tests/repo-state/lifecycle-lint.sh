#!/usr/bin/env bash
# lifecycle-lint flags a superseded+unlinked plan (a) and an orphaned brief (b), spares the newest
# cycle and a linked plan, exits 1 iff findings, cd's into its arg, and touches NO live tracker.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; REPO="$(cd "$HERE/../.." && pwd)"; L="$REPO/scripts/lifecycle-lint.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$L" ] || fail "scripts/lifecycle-lint.sh missing or not executable"
BIN="$(mktemp -d)"; SB="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB"' EXIT
GHLOG="$BIN/gh.calls"
cat > "$BIN/gh" <<EOF
#!/usr/bin/env bash
echo "GH CALLED: \$*" >> "$GHLOG"; exit 1
EOF
chmod +x "$BIN/gh"; export PATH="$BIN:$PATH"
mkdir -p "$SB/docs/plans" "$SB/docs/briefs" "$SB/docs/archive"
# NO config/repo-state.md tracker mode in the fixture -> issue-classes must be skipped, not error

# an OLD plan-set, superseded by a newer one, not archived, no open issue -> class (a)
echo "# Old thing plan"   > "$SB/docs/plans/2026-08-04-old-thing-plan.md"
# the newest cycle -> must NOT be flagged
echo "# New thing plan"   > "$SB/docs/plans/2026-08-15-new-thing-plan.md"
# a brief whose plan is already archived -> class (b)
echo "# Orphan brief"     > "$SB/docs/briefs/2026-08-01-orphan-brief.md"
echo "# Orphan plan"      > "$SB/docs/archive/2026-08-01-orphan-plan.md"

out="$("$L" "$SB")"; rc=$?
[ "$rc" -eq 1 ] || fail "lint did not exit 1 with findings (rc=$rc)"
printf '%s\n' "$out" | grep -q '^LINT a .*old-thing'  || fail "did not flag the superseded+unlinked plan"
printf '%s\n' "$out" | grep -q '^LINT b .*orphan-brief' || fail "did not flag the orphaned brief"
printf '%s\n' "$out" | grep -q 'new-thing' && fail "flagged the newest cycle's plan (should be spared)"

# clean tree: remove the two offenders -> exit 0
rm "$SB/docs/plans/2026-08-04-old-thing-plan.md" "$SB/docs/briefs/2026-08-01-orphan-brief.md"
"$L" "$SB" >/dev/null; rc=$?
[ "$rc" -eq 0 ] || fail "lint flagged a clean tree (rc=$rc)"

[ ! -s "$GHLOG" ] || { cat "$GHLOG"; fail "lint leaked to a live tracker with no mode declared"; }
echo "PASS: lifecycle-lint flags a+b, spares newest cycle, exit-codes right, no live-tracker leak"
