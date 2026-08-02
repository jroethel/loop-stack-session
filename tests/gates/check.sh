#!/usr/bin/env bash
# Registry is fresh (regenerates identically) and no gate-signal line lacks a tag.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
GEN="$REPO/scripts/gen-gate-registry.sh"
REG="$REPO/docs/gate-registry.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$GEN" ] || fail "scripts/gen-gate-registry.sh missing or not executable"
[ -f "$REG" ] || fail "docs/gate-registry.md missing (never generated)"

# (a) freshness: regenerate to a temp root that mirrors skills/, diff registries
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/skills" "$TMP/docs"
cp -R "$REPO"/skills/loop-* "$TMP/skills/"
"$GEN" "$TMP" || fail "gen-gate-registry exited non-zero"
# Strip the whole disclosed-comment header block (everything before the first H1) so the volatile
# timestamp cannot cause a false STALE.
strip_header() { awk 'f{print} /^# /{f=1; print}' "$1"; }
diff <(strip_header "$REG") <(strip_header "$TMP/docs/gate-registry.md") >/dev/null \
  || fail "docs/gate-registry.md is STALE - rerun scripts/gen-gate-registry.sh ."

# (b) untagged gate-signal lines (the real skills). Uses the check's own scanner via a flag.
"$GEN" --scan-untagged "$REPO" >/tmp/untagged.$$ 2>&1
if [ -s /tmp/untagged.$$ ]; then cat /tmp/untagged.$$; rm -f /tmp/untagged.$$; fail "gate-signal line without a tag (see above)"; fi
rm -f /tmp/untagged.$$

# registry is a disclosed mirror
grep -qi 'DO NOT EDIT' "$REG" || fail "registry is not a disclosed mirror"
echo "PASS: registry fresh, disclosed, and no untagged gate-signal lines"
