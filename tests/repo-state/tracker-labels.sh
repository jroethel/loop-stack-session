#!/usr/bin/env bash
# tracker.sh label + comment primitives across all three backends: local mutates frontmatter with
# zero gh/glab; github/gitlab emit the exact CLI calls; comment appends a durable receipt; and
# label add refuses agent:done (bypass closed). bash 3.2 safe.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; REPO="$(cd "$HERE/../.." && pwd)"; T="$REPO/scripts/tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$T" ] || fail "scripts/tracker.sh missing or not executable"

BIN="$(mktemp -d)"; SB="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB"' EXIT
LOG="$BIN/cli.calls"
# fake gh/glab: 'auth' subcommand passes the guards, everything else is recorded (bash 3.2 safe)
cat > "$BIN/gh"  <<EOF
#!/usr/bin/env bash
[ "\$1" = auth ] && exit 0
echo "GH CALLED: \$*" >> "$LOG"; exit 0
EOF
cat > "$BIN/glab" <<EOF
#!/usr/bin/env bash
[ "\$1" = auth ] && exit 0
echo "GLAB CALLED: \$*" >> "$LOG"; exit 0
EOF
chmod +x "$BIN/gh" "$BIN/glab"; export PATH="$BIN:$PATH"
cd "$SB" && git init -q && mkdir -p config

# --- LOCAL backend: real frontmatter mutation, zero CLI ---
"$T" mode set local >/dev/null
n="$("$T" create --label agent:todo --title "Spine ticket" --body "do the thing")"
[ "$n" = "1" ] || fail "local create did not return #1"
f="docs/issues/001-spine-ticket.md"
"$T" label add 1 agent:working    || fail "label add failed"
grep -qE '^labels: .*agent:working' "$f" || fail "label add did not write agent:working to frontmatter"
"$T" label add 1 agent:working    # idempotent
[ "$(grep -o 'agent:working' "$f" | wc -l | tr -d ' ')" = "1" ] || fail "label add duplicated agent:working"
"$T" label remove 1 agent:todo    || fail "label remove failed"
grep -qE '^labels:.*agent:todo' "$f" && fail "label remove left agent:todo behind"
"$T" comment 1 "AGENT CLAIMED sess-x 2026-08-15T00:00:00Z" || fail "comment failed"
grep -q 'AGENT CLAIMED sess-x' "$f" || fail "comment did not append receipt to local body"
# bypass closed: label add refuses agent:done
"$T" label add 1 agent:done >/dev/null 2>&1; rc=$?
[ "$rc" -eq 6 ] || fail "label add agent:done was not rejected (rc=$rc)"
grep -qE '^labels:.*agent:done' "$f" && fail "rejected label add still wrote agent:done"
"$T" label ensure agent:review >/dev/null || fail "label ensure nonzero in local mode"
[ ! -s "$LOG" ] || { cat "$LOG"; fail "local mode touched gh/glab"; }

# --- GITHUB backend: exact CLI dispatch ---
: > "$LOG"; "$T" mode set github >/dev/null
"$T" label ensure agent:review  >/dev/null
"$T" label add 7 agent:review    >/dev/null
"$T" label remove 7 agent:todo   >/dev/null
"$T" comment 7 "receipt body"   >/dev/null
grep -q 'GH CALLED: label create agent:review'                "$LOG" || fail "github label ensure wrong call"
grep -q 'GH CALLED: issue edit 7 --add-label agent:review'    "$LOG" || fail "github label add wrong call"
grep -q 'GH CALLED: issue edit 7 --remove-label agent:todo'   "$LOG" || fail "github label remove wrong call"
grep -q 'GH CALLED: issue comment 7 --body receipt body'      "$LOG" || fail "github comment wrong call"

# --- GITLAB backend: exact CLI dispatch, incl. --unlabel ---
: > "$LOG"; "$T" mode set gitlab >/dev/null
git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git'
"$T" label ensure agent:review  >/dev/null
"$T" label add 7 agent:review    >/dev/null
"$T" label remove 7 agent:todo   >/dev/null
"$T" comment 7 "receipt body"   >/dev/null
grep -q 'GLAB CALLED: label create --name agent:review'       "$LOG" || fail "gitlab label ensure wrong call"
grep -q 'GLAB CALLED: issue update 7 --label agent:review'    "$LOG" || fail "gitlab label add wrong call"
grep -q 'GLAB CALLED: issue update 7 --unlabel agent:todo'    "$LOG" || fail "gitlab label remove wrong call"
grep -q 'GLAB CALLED: issue note 7 --message receipt body'    "$LOG" || fail "gitlab comment wrong call"

echo "PASS: label ensure/add/remove (+agent:done bypass closed) + comment across local, github, gitlab"
