#!/usr/bin/env bash
# get and status agree when docs/chain-state.md exists but has no autonomy: key and the repo default is auto.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
LA="$REPO/skills/loop-auto/loop-auto.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$LA" ] || fail "skills/loop-auto/loop-auto.sh missing or not executable"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/config" "$TMP/docs"
# committed repo default is auto
printf '# Repo State Map\nautonomy-default: auto\n' > "$TMP/config/repo-state.md"
# chain-state present but WITHOUT an autonomy: key (a keyless runtime file)
printf 'generated: 2026-08-08T00:00:00Z\n' > "$TMP/docs/chain-state.md"

got="$( cd "$TMP" && "$LA" get )"
[ "$got" = "auto" ] \
  || fail "keyless chain-state: get returned '$got', not the committed default 'auto'"

st="$( cd "$TMP" && "$LA" status )"
echo "$st" | grep -qi 'auto' \
  || fail "keyless chain-state: status did not report the effective mode auto"

# get and status must agree on the effective mode for the same keyless state.
echo "$st" | grep -qi "$got" \
  || fail "get ('$got') and status ('$st') disagree on the keyless-chain-state effective mode"

echo "PASS: get and status agree (both auto) on a keyless chain-state with an auto repo default"
