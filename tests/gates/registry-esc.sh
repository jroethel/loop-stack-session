#!/usr/bin/env bash
# gen-gate-registry escapes a pipe inside a gate excerpt (parity with gen-mirrors' esc()).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
GEN="$REPO/scripts/gen-gate-registry.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
# Source parity: pipe escaping uses the char-loop esc(), not gsub (which diverges gawk vs BWK awk).
# A behavioral fixture alone is vacuous here: BWK awk on darwin already renders the current gsub as \|.
grep -Eq 'gsub\(/\\\|/' "$GEN" && fail "still uses gsub for pipe escaping (the gawk/BWK divergence remains)"
grep -q 'function esc(' "$GEN" || fail "no char-loop esc() function adopted from gen-mirrors"
# Behavioral cross-check: a gate excerpt with a pipe renders as one escaped row of exactly 3 columns.
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/skills/loop-esc/" "$TMP/docs"
printf '## Step 1 - has a pipe\nChoose left | right here and decide.`[gate:BATCH]`\n' > "$TMP/skills/loop-esc/SKILL.md"
"$GEN" "$TMP" >/dev/null || fail "gen-gate-registry failed on the pipe fixture"
row="$(grep 'loop-esc' "$TMP/docs/gate-registry.md")" || fail "escaped row missing"
printf '%s' "$row" | grep -q '\\|' || fail "pipe in excerpt not escaped"
# Removing escaped pipes leaves exactly the 4 table delimiters (3 data columns).
bars="$(printf '%s' "$row" | sed 's/\\|//g' | tr -cd '|' | wc -c | tr -d ' ')"
[ "$bars" -eq 4 ] || fail "malformed row: $bars unescaped pipes, expected 4 (3 columns)"
echo "PASS: gen-gate-registry uses esc() char-loop and renders a pipe as one escaped 3-column row"
