#!/usr/bin/env bash
# tracker.sh children: github mode calls the sub-issues endpoint and passes the array through;
# gitlab/local modes fail fast with no gh call at all.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
T="$REPO/scripts/tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$T" ] || fail "scripts/tracker.sh missing or not executable"

BIN="$(mktemp -d)"; SB="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB"' EXIT
GHLOG="$BIN/gh.calls"
cat > "$BIN/gh" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$GHLOG"
if [ "\$1" = "auth" ]; then exit 0; fi
if [ "\$1" = "api" ]; then
  echo '[{"number":5,"title":"x","state":"closed","labels":[],"body":""}]'
  exit 0
fi
exit 1
EOF
chmod +x "$BIN/gh"
export PATH="$BIN:$PATH"
mkdir -p "$SB/config"

printf 'tracker: github\n' > "$SB/config/repo-state.md"
out="$(cd "$SB" && "$T" children 91)" || fail "children exited non-zero in github mode"
printf '%s' "$out" | grep -q '"number": *5' || fail "children did not pass the sub-issues array through"
grep -q 'repos/{owner}/{repo}/issues/91/sub_issues' "$GHLOG" || fail "gh api not called with the sub_issues endpoint"

printf 'tracker: gitlab\n' > "$SB/config/repo-state.md"
: > "$GHLOG"
(cd "$SB" && "$T" children 91) >/dev/null 2>&1 && fail "children did not fail fast in gitlab mode"
[ ! -s "$GHLOG" ] || fail "children called gh in gitlab mode"

printf 'tracker: local\n' > "$SB/config/repo-state.md"
(cd "$SB" && "$T" children 91) >/dev/null 2>&1 && fail "children did not fail fast in local mode"
[ ! -s "$GHLOG" ] || fail "children called gh in local mode"

echo "PASS: tracker.sh children passes sub-issues through in github mode, fails fast elsewhere"
