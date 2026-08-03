#!/usr/bin/env bash
# fable-sandwich is renamed to frontier-sandwich as a repo skill; no live fable-sandwich id remains.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$REPO/skills/frontier-sandwich/SKILL.md" ] || fail "skills/frontier-sandwich/SKILL.md missing"
grep -q '^name: frontier-sandwich' "$REPO/skills/frontier-sandwich/SKILL.md" || fail "skill id not frontier-sandwich"
# The install-generated benchmarks leaf must never be TRACKED (install.sh creates it in the
# working tree post-install, so existence on disk is legitimate; a committed copy is the bug).
X="skills/frontier-sandwich/references/model-benchmarks.md"
if git -C "$REPO" ls-files --error-unmatch "$X" >/dev/null 2>&1; then
  fail "install-generated benchmarks leaf is committed; install.sh must create it"
fi
git -C "$REPO" check-ignore -q "$X" || fail "benchmarks leaf not gitignored (post-install it would dirty the tree)"
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
# The benchmark-prior path lives with the skill now (the managed block stays lean by design).
grep -q 'config/routing/model-benchmarks.md' "$REPO/skills/frontier-sandwich/SKILL.md" \
  || fail "frontier-sandwich skill does not name the benchmark-prior repo source"
echo "PASS: frontier-sandwich repo skill in place, old id only in the retire list, benchmarks leaf uncommitted"
