#!/usr/bin/env bash
# frontier-sandwich is retired: its SKILL body is gone (kept policy relocated to loop-drive),
# install.sh retires any installed copy, and the benchmark-prior leaf moved to loop-drive/references.
# Scoped to what is true at retirement: the repo-wide "no live reference" sweep is Task 14's
# (the reference conversions land across Tasks 4/5/6), not this contract's.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }

# 1. The skill dir/body is absent.
[ ! -e "$REPO/skills/frontier-sandwich" ] || fail "skills/frontier-sandwich still present; it must be retired"
[ ! -f "$REPO/skills/frontier-sandwich/SKILL.md" ] || fail "frontier-sandwich SKILL.md still present"

# 2. install.sh retires any already-installed copy (symlink or dir) via the retire list.
grep -Eq 'for old in .*frontier-sandwich' "$REPO/install.sh" \
  || fail "frontier-sandwich is not in install.sh's retire list (stale symlink would load side by side)"

# 3. The benchmark-prior leaf moved to loop-drive; it is install-generated, so never tracked, always gitignored.
X="skills/loop-drive/references/model-benchmarks.md"
if git -C "$REPO" ls-files --error-unmatch "$X" >/dev/null 2>&1; then
  fail "install-generated benchmarks leaf is committed at $X; install.sh must create it"
fi
git -C "$REPO" check-ignore -q "$X" || fail "benchmarks leaf $X not gitignored (post-install it would dirty the tree)"

echo "PASS: frontier-sandwich retired, in the retire list, benchmark leaf moved to loop-drive and uncommitted"
