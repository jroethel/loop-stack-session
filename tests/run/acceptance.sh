#!/usr/bin/env bash
# The runner discovers tests/*/*.sh, fails when any suite fails, excludes build-fixtures.sh,
# and exports LOOP_REVIEW_SKIP_BEHAVIOR=1 to the suites it runs.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
RUN="$REPO/tests/run.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$RUN" ] || fail "tests/run.sh missing or not executable"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/suite" "$TMP/loop-review"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP/suite/ok.sh"
printf '#!/usr/bin/env bash\nexit 1\n' > "$TMP/suite/bad.sh"
# A helper that MUST be excluded: it exits non-zero when run with no argument, so if the runner
# ran it, the all-green case below would wrongly fail.
printf '#!/usr/bin/env bash\n[ $# -ge 1 ] || exit 3\n' > "$TMP/loop-review/build-fixtures.sh"
chmod +x "$TMP"/suite/*.sh "$TMP"/loop-review/*.sh

# Failing probe: with bad.sh present, the runner exits non-zero and names the failing suite.
set +e
out="$(bash "$RUN" "$TMP" 2>&1)"; rc=$?
set -e 2>/dev/null || true
[ "$rc" -ne 0 ] || fail "runner exited 0 despite a failing suite"
printf '%s\n' "$out" | grep -q 'bad.sh' || fail "runner did not name the failing suite bad.sh"

# All-green: remove the failing suite; the runner now exits 0. This also proves build-fixtures.sh
# was excluded, because its bare exit 3 would otherwise fail the run.
rm "$TMP/suite/bad.sh"
bash "$RUN" "$TMP" >/dev/null 2>&1 \
  || fail "runner exited non-zero on an all-passing suite (build-fixtures.sh not excluded?)"

# LOOP_REVIEW_SKIP_BEHAVIOR=1 is exported to the suites the runner runs.
printf '#!/usr/bin/env bash\n[ "${LOOP_REVIEW_SKIP_BEHAVIOR:-0}" = 1 ] || exit 7\n' > "$TMP/suite/env.sh"
chmod +x "$TMP/suite/env.sh"
bash "$RUN" "$TMP" >/dev/null 2>&1 \
  || fail "runner did not export LOOP_REVIEW_SKIP_BEHAVIOR=1 to the suites"

# live.sh is skipped (not failed) when gh auth is unavailable, and runs when auth succeeds.
mkdir -p "$TMP/repo-state"
printf '#!/usr/bin/env bash\nexit 1\n' > "$TMP/repo-state/live.sh"
chmod +x "$TMP/repo-state/live.sh"
FAKEBIN="$(mktemp -d)"; trap 'rm -rf "$TMP" "$FAKEBIN"' EXIT
printf '#!/usr/bin/env bash\nexit 1\n' > "$FAKEBIN/gh"; chmod +x "$FAKEBIN/gh"
out="$(PATH="$FAKEBIN:$PATH" bash "$RUN" "$TMP" 2>&1)" \
  || fail "runner failed although live.sh must be skipped without gh auth"
printf '%s\n' "$out" | grep -q 'SKIP:.*live.sh' \
  || fail "runner did not print a SKIP: line for live.sh without gh auth"
printf '#!/usr/bin/env bash\nexit 0\n' > "$FAKEBIN/gh"
PATH="$FAKEBIN:$PATH" bash "$RUN" "$TMP" >/dev/null 2>&1 \
  && fail "runner passed although authenticated gh means live.sh (exit 1) must run and fail"

echo "PASS: runner discovers tests/*/*.sh, fails on a failing suite, excludes build-fixtures.sh, exports the skip flag, and skips live.sh without gh auth"
