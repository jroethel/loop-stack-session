#!/usr/bin/env bash
# fable-sandwich is renamed to frontier-sandwich as a repo skill; no live fable-sandwich id remains.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$REPO/skills/frontier-sandwich/SKILL.md" ] || fail "skills/frontier-sandwich/SKILL.md missing"
grep -q '^name: frontier-sandwich' "$REPO/skills/frontier-sandwich/SKILL.md" || fail "skill id not frontier-sandwich"
# The install-generated benchmarks leaf must not be committed (install.sh creates it).
X="$REPO/skills/frontier-sandwich/references/model-benchmarks.md"
if [ -L "$X" ] || [ -e "$X" ]; then fail "install-generated benchmarks leaf is committed; install.sh must create it"; fi
# install.sh wires the new skill and mentions fable-sandwich EXACTLY once (the retire list).
grep -q 'frontier-sandwich' "$REPO/install.sh" || fail "install.sh does not reference frontier-sandwich"
c="$(grep -c 'fable-sandwich' "$REPO/install.sh")"
[ "$c" -eq 1 ] || fail "fable-sandwich should appear exactly once in install.sh (the retire list); found $c (line-157 self-check likely still stale)"
grep -Eq 'for old in .*fable-sandwich' "$REPO/install.sh" || fail "fable-sandwich is not in the retire list"
# No live old-name reference in either form (hyphen id or "Fable Sandwich" alias) in active source.
# install.sh is excepted (its retire list must name the hyphenated id); "Frontier Sandwich" is fine.
if grep -rniE 'fable[ -]sandwich' "$REPO/skills" "$REPO/config" "$REPO/scripts" "$REPO/claude-md" 2>/dev/null; then
  fail "a live fable-sandwich id or 'Fable Sandwich' alias remains in active source"
fi
# Managed block benchmark path points at frontier-sandwich.
grep -q 'frontier-sandwich' "$REPO/claude-md/fable.md" || fail "managed block benchmark path not renamed"
echo "PASS: frontier-sandwich repo skill in place, old id only in the retire list, benchmarks leaf uncommitted"
