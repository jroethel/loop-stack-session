#!/usr/bin/env bash
# tracker.sh list (github mode) passes --limit 1000 so it fetches past gh's default 30-issue page.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
TRK="$REPO/scripts/tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$TRK" ] || fail "scripts/tracker.sh missing or not executable"

TMP="$(mktemp -d)"; BIN="$(mktemp -d)"; trap 'rm -rf "$TMP" "$BIN"' EXIT
mkdir -p "$TMP/config"
printf 'tracker: github\n' > "$TMP/config/repo-state.md"

CALLS="$BIN/gh.calls"
cat > "$BIN/gh" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$CALLS"
case "\$1" in
  auth)  exit 0 ;;
  issue) [ "\$2" = list ] && { echo "[]"; exit 0; }; exit 0 ;;
esac
exit 0
EOF
chmod +x "$BIN/gh"

( cd "$TMP" && PATH="$BIN:$PATH" bash "$TRK" list ) >/dev/null || fail "tracker.sh list (github) exited non-zero"
grep -q 'issue list' "$CALLS" || fail "tracker.sh list did not call gh issue list"
grep -q -- '--limit 1000' "$CALLS" \
  || fail "tracker.sh list did not pass --limit 1000 (capped at gh's default 30-issue page)"

echo "PASS: tracker.sh list passes --limit 1000 in github mode"
