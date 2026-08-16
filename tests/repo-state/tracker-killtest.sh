#!/usr/bin/env bash
# Kill-test (mechanical): a dead session claimed #1, wrote an AGENT STATUS receipt, and committed a
# partial branch. A fresh session, from tracker + git ALONE: (a) a plain claim is refused (race guard
# still protects live tickets), (b) claim --reclaim takes over (exit 0, re-owned), (c) the run-state
# receipt + git branch are readable for relaunch. Also asserts the NEW run-state artifact is documented.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; REPO="$(cd "$HERE/../.." && pwd)"; T="$REPO/scripts/tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
BIN="$(mktemp -d)"; SB="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB"' EXIT
GHLOG="$BIN/gh.calls"
cat > "$BIN/gh" <<EOF
#!/usr/bin/env bash
echo "GH CALLED: \$*" >> "$GHLOG"; exit 1
EOF
chmod +x "$BIN/gh"; export PATH="$BIN:$PATH"
cd "$SB"
git init -q -b main 2>/dev/null || { git init -q && git symbolic-ref HEAD refs/heads/main; }
git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
mkdir -p config && "$T" mode set local >/dev/null

# a dead session claimed #1, left a run-state receipt, committed a partial unit branch, then died
"$T" create --label agent:todo --title "Half done unit" --body "work" >/dev/null
"$T" claim 1 sess-DEAD >/dev/null
"$T" comment 1 "AGENT STATUS branch=unit-1 worktree=/tmp/wt verdict=pending repairs=0" >/dev/null
# commit tracker state on main FIRST: branching with it uncommitted would carry it onto unit-1
# and the later checkout of main would delete the issue file from the working tree
git -c user.email=t@t -c user.name=t add -A >/dev/null && git -c user.email=t@t -c user.name=t commit -qm "tracker state"
git checkout -q -b unit-1 && echo x > partial.txt
git -c user.email=t@t -c user.name=t add -A && git -c user.email=t@t -c user.name=t commit -q -m "partial unit-1"
git checkout -q main
f="docs/issues/001-half-done-unit.md"

# (a) a fresh plain claim is REFUSED - the race guard still protects a live-looking ticket
"$T" claim 1 sess-NEW >/dev/null 2>&1; rc=$?
[ "$rc" -eq 4 ] || fail "plain claim over an existing claim was not refused (rc=$rc)"

# (b) reclaim takes over from tracker alone
own="$("$T" claim 1 sess-NEW --reclaim)" || fail "reclaim of the dead ticket failed"
[ "$own" = "sess-NEW" ] || fail "reclaim did not re-own the ticket"
grep -qE '^labels:.*agent:working' "$f" || fail "reclaimed ticket is not agent:working"

# (c) the run-state receipt + git branch are readable for relaunch
grep -q 'AGENT STATUS branch=unit-1' "$f" || fail "run-state receipt missing from ticket"
git rev-parse --verify -q unit-1 >/dev/null || fail "git does not carry the half-done unit branch"

# the NEW run-state-onto-tickets convention is documented (not pre-existing P11 phrasing)
D="$REPO/skills/loop-drive/SKILL.md"
grep -q 'AGENT STATUS' "$D" || fail "SKILL does not document the AGENT STATUS run-state receipt"
grep -q 'tracker.sh comment' "$D" || fail "SKILL does not wire run-state onto tickets via tracker.sh comment"

[ ! -s "$GHLOG" ] || { cat "$GHLOG"; fail "local mode touched gh"; }
echo "PASS: killed unit refuses a plain claim, yields to reclaim, and is relaunchable from tracker + git"
