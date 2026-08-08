#!/usr/bin/env bash
# run.sh - discover and run every tests/*/*.sh suite; exit non-zero if any fails.
# Skips helper scripts that are not standalone suites (see SKIP). Exports
# LOOP_REVIEW_SKIP_BEHAVIOR=1 so loop-review's behavioral layer B makes no model calls.
# Usage: tests/run.sh [tests-dir]   (tests-dir defaults to this script's own directory)
set -uo pipefail
ROOT="${1:-$(cd "$(dirname "$0")" && pwd)}"
export LOOP_REVIEW_SKIP_BEHAVIOR=1

# Basenames that are helpers, not standalone suites: build-fixtures.sh needs an argument
# and exits non-zero when run bare.
SKIP="build-fixtures.sh"

# live.sh asserts this repo's live GitHub state; without an authenticated gh CLI it can only
# fail for environmental reasons, so it is skipped (reported, not counted) when auth is absent.
if ! gh auth status >/dev/null 2>&1; then
  SKIP="$SKIP live.sh"
  echo "SKIP: live.sh (no authenticated gh CLI)"
fi

pass=0; fail=0
shopt -s nullglob
for t in "$ROOT"/*/*.sh; do
  base="$(basename "$t")"
  case " $SKIP " in *" $base "*) continue ;; esac
  out="$(bash "$t" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ]; then
    pass=$((pass + 1))
    echo "PASS: $t"
  else
    fail=$((fail + 1))
    printf '%s\n' "$out"
    echo "FAIL: $t (exit $rc)"
  fi
done
echo "ran $((pass + fail)) suites: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
