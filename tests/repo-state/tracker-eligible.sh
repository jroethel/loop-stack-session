#!/usr/bin/env bash
# next-eligible: picks exactly one unblocked todo (lowest number) with a reason; skips a blocked one;
# resurfaces a STALE agent:working ticket ahead of fresh todo; parses realistic multi-field gh JSON.
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
cd "$SB" && git init -q && mkdir -p config && "$T" mode set local >/dev/null

"$T" create --label agent:todo --title "Alpha"   --body "work" >/dev/null   # #1
"$T" create --label agent:todo --title "Bravo"   --body "work" >/dev/null   # #2
"$T" create --label agent:todo --title "Charlie" --body "work" >/dev/null   # #3

out="$("$T" next-eligible)"; rc=$?
[ "$rc" -eq 0 ] || fail "next-eligible exited nonzero with eligible tickets"
[ "$(printf '%s\n' "$out" | grep -c '^SELECTED')" -eq 1 ] || fail "did not select exactly one"
printf '%s\n' "$out" | grep -q '^SELECTED #1:' || fail "did not select the lowest-number eligible (#1)"
printf '%s\n' "$out" | grep -qi 'todo' || fail "selection reason not recorded"

# a ticket blocked by an OPEN issue is skipped; claim #1/#2/#3 (fresh receipts, working, not stale)
"$T" create --label agent:todo --title "Delta" --body "Blocked by: #1" >/dev/null  # #4 blocked by open #1
"$T" claim 1 sess-old >/dev/null; "$T" claim 2 sess-old >/dev/null; "$T" claim 3 sess-old >/dev/null
# those three carry FRESH claims -> not stale; #4 is blocked -> nothing eligible this run
out2="$(STALE_CLAIM_SECS=3600 "$T" next-eligible sess-me)"
printf '%s\n' "$out2" | grep -q '^NONE ELIGIBLE' || fail "fresh-working + blocked queue did not report NONE"
printf '%s\n' "$out2" | grep -q '^SELECTED' && fail "selected a blocked or fresh-working ticket"

# STALE working resurfaces: backdate #2's claim receipt (no .bak left behind), then it is selected
tmp="$(mktemp)"
sed -E 's/AGENT CLAIMED sess-old [0-9T:Z-]+/AGENT CLAIMED sess-old 2000-01-01T00:00:00Z/' \
  docs/issues/002-bravo.md > "$tmp" && mv "$tmp" docs/issues/002-bravo.md
out3="$(STALE_CLAIM_SECS=3600 "$T" next-eligible sess-me)"
printf '%s\n' "$out3" | grep -q '^SELECTED #2: stale working' || fail "stale working ticket not resurfaced for relaunch"

[ ! -s "$GHLOG" ] || { cat "$GHLOG"; fail "local mode touched gh"; }

# --- GITHUB stub: realistic multi-field label JSON parses to the right lane ---
BIN2="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB" "$BIN2"' EXIT
cat > "$BIN2/gh" <<'EOS'
#!/usr/bin/env bash
[ "$1 $2" = "auth status" ] && exit 0
if [ "$1" = issue ] && [ "$2" = list ]; then
  cat <<'JSON'
[{"number":5,"title":"Echo","labels":[{"id":"a","name":"agent:todo","color":"ededed","description":""}],"updatedAt":"2026-08-15T00:00:00Z"}]
JSON
  exit 0
fi
if [ "$1" = issue ] && [ "$2" = view ]; then echo "no blockers here"; exit 0; fi
exit 0
EOS
chmod +x "$BIN2/gh"
out4="$(cd "$SB" && PATH="$BIN2:$PATH" "$T" mode set github >/dev/null 2>&1; PATH="$BIN2:$PATH" "$T" next-eligible)"
printf '%s\n' "$out4" | grep -q '^SELECTED #5: agent:todo' || fail "github multi-field JSON did not parse to a todo selection"

echo "PASS: next-eligible one-per-run, blockers honored, stale-working resurfaced, remote JSON parsed"
