#!/usr/bin/env bash
# loop-which is retired: its One-Minute Test policy relocated to the loop-brainstorm front door
# (and loop-drive Step 0), its reference git-moved to loop-brainstorm/references, and install.sh
# retires any already-installed copy. No policy was deleted.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }

# 1. The skill dir/body is absent.
[ ! -e "$REPO/skills/loop-which" ] || fail "skills/loop-which still present; it must be retired"
[ ! -f "$REPO/skills/loop-which/SKILL.md" ] || fail "loop-which SKILL.md still present"

# 2. install.sh retires any already-installed copy via the retire list.
grep -Eq 'for old in .*loop-which' "$REPO/install.sh" \
  || fail "loop-which is not in install.sh's retire list (stale symlink would load side by side)"

# 3. The One-Minute Test reference is at its new brainstorm home with the body intact.
OMT="$REPO/skills/loop-brainstorm/references/one-minute-test.md"
[ -f "$OMT" ] || fail "one-minute-test.md not at its brainstorm home"
grep -qi 'One-Minute Test' "$OMT" || fail "one-minute-test.md lost the One-Minute Test body"
grep -qi "DON'T BOTHER" "$OMT" || fail "one-minute-test.md lost the four-route verdicts"

# 4. The brainstorm SKILL names the One-Minute Test front door (the policy's new home).
grep -qi 'One-Minute Test' "$REPO/skills/loop-brainstorm/SKILL.md" \
  || fail "loop-brainstorm SKILL does not name the One-Minute Test front door"

echo "PASS: loop-which retired, in the retire list, One-Minute Test rehomed to the brainstorm front door"
