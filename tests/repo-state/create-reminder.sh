#!/usr/bin/env bash
# tracker.sh create (local backend) prints the bare issue number on stdout (so the $(...) capture
# in graduate-parking.sh keeps working) and the doc-token reminder on stderr.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; REPO="$(cd "$HERE/../.." && pwd)"; T="$REPO/scripts/tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$T" ] || fail "scripts/tracker.sh missing or not executable"
CR="$(mktemp -d)"; trap 'rm -rf "$CR"' EXIT
mkdir -p "$CR/config" "$CR/docs/issues"
printf 'tracker: local\n' > "$CR/config/repo-state.md"
out="$( cd "$CR" && "$T" create --title "reminder probe" --body "reminder probe body" 2>"$CR/err.txt" )" \
  || fail "create against a local sandbox exited non-zero"
printf '%s\n' "$out" | grep -Eq '^[0-9]+$' || fail "create stdout is not a bare number (got: $out)"
grep -q 'gain its token' "$CR/err.txt" || fail "create did not emit the stderr token reminder"
echo "PASS: create prints the bare number on stdout, token reminder on stderr"
