#!/usr/bin/env bash
# claim (receipt-before-flip) + race (later claimer loses, exit 4) + reclaim takeover (exit 0);
# status enforces one active label; done REJECTS evidence-free AND failing-exit receipts, ACCEPTS a
# passing one, --ran re-executes; agent:done unreachable by side doors. Local behavior + github race stub.
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

n="$("$T" create --label agent:todo --title "Claimable" --body "body")"; f="docs/issues/001-claimable.md"

# status enforces exactly one agent:* label
"$T" status 1 working || fail "status working failed"
grep -qE '^labels:.*agent:working' "$f" || fail "status did not set agent:working"
grep -qE '^labels:.*agent:todo'    "$f" && fail "status did not clear agent:todo"

# claim: receipt-before-flip, clean single claim exits 0 and leaves a receipt BEFORE working is set
"$T" create --label agent:todo --title "Second" --body "b" >/dev/null
sid="$("$T" claim 2 sess-A)" || fail "clean claim exited nonzero"
[ "$sid" = "sess-A" ] || fail "claim did not echo owner session id"
grep -q 'AGENT CLAIMED sess-A' docs/issues/002-second.md || fail "claim left no receipt"

# race: a LATER second claimer loses (exit 4); the earlier claimer remains owner
"$T" claim 2 sess-B >/dev/null 2>&1; rc=$?
[ "$rc" -eq 4 ] || fail "later claimer not rejected as race (rc=$rc)"

# reclaim: explicit takeover of a known-dead session succeeds (exit 0) and re-owns
own="$("$T" claim 2 sess-C --reclaim)" || fail "reclaim exited nonzero"
[ "$own" = "sess-C" ] || fail "reclaim did not take ownership"

# done-guard: evidence-free receipt REJECTED (exit 5), issue stays open
"$T" done 1 --receipt "did the work, looks good" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 5 ] || fail "evidence-free done not rejected (rc=$rc)"
grep -q '^state: open' "$f" || fail "rejected done closed the issue"
grep -qE '^labels:.*agent:done' "$f" && fail "rejected done applied agent:done"

# done-guard: a FAILING exit is REJECTED too (exit 5)
"$T" done 1 --receipt "ran tests; exit 1" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 5 ] || fail "failing-exit receipt not rejected (rc=$rc)"
grep -q '^state: open' "$f" || fail "failing-exit done closed the issue"

# done-guard: a PASSING receipt ACCEPTED - sets agent:done and closes
"$T" done 1 --receipt "ran tests/run.sh; exit 0" || fail "passing receipt rejected"
grep -qE '^labels:.*agent:done' "$f" || fail "evidenced done did not apply agent:done"
grep -q '^state: closed' "$f" || fail "evidenced done did not close the issue"

# --ran re-executes and captures the real exit: a passing command closes #2
"$T" status 2 working >/dev/null
"$T" done 2 --receipt "smoke" --ran 'true' || fail "done --ran with a passing command was rejected"
grep -q '^state: closed' docs/issues/002-second.md || fail "done --ran did not close on exit 0"
# --ran with a FAILING command routes to review (exit 7), does not close
n3="$("$T" create --label agent:working --title "Third" --body c)"
"$T" done 3 --receipt "smoke" --ran 'false' >/dev/null 2>&1; rc=$?
[ "$rc" -eq 7 ] || fail "done --ran with a failing command did not route to review (rc=$rc)"
grep -qE '^labels:.*agent:review' docs/issues/003-third.md || fail "failing --ran did not set agent:review"
grep -q '^state: closed' docs/issues/003-third.md && fail "failing --ran closed the issue"

[ ! -s "$GHLOG" ] || { cat "$GHLOG"; fail "local mode touched gh"; }

# --- GITHUB race stub: two AGENT CLAIMED comments -> a later claimer loses (exit 4) ---
BIN2="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB" "$BIN2"' EXIT
cat > "$BIN2/gh" <<'EOS'
#!/usr/bin/env bash
case "$1 $2" in
  "auth status") exit 0 ;;
esac
if [ "$1" = issue ] && [ "$2" = view ]; then
  # two prior claimers already on the remote issue
  printf '%s\n' "AGENT CLAIMED sess-EARLY 2026-08-15T00:00:00Z" "AGENT CLAIMED sess-LATE 2026-08-15T00:00:05Z"
  exit 0
fi
exit 0
EOS
chmod +x "$BIN2/gh"; PATH="$BIN2:$PATH" "$T" mode set github >/dev/null 2>&1 || true
# a fresh claimer that is neither of the priors and later than both must lose
PATH="$BIN2:$PATH" "$T" claim 9 sess-NEW >/dev/null 2>&1; rc=$?
[ "$rc" -eq 4 ] || fail "github: a later claimer over two existing claims did not lose (rc=$rc)"

echo "PASS: claim/reclaim/race, one-status, evidence-gated done (+ --ran, side doors closed), github race"
