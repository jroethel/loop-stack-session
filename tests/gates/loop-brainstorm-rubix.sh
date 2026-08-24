#!/usr/bin/env bash
# loop-brainstorm offers a soft-checked Rubix pass on the finished brief before planning.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
S="$REPO/skills/loop-brainstorm/SKILL.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$S" ] || fail "loop-brainstorm SKILL missing"

grep -q 'rubix-review' "$S" || fail "loop-brainstorm does not reference the rubix-review skill"
grep -Eqi 'brief' "$S" || fail "offer is not tied to the brief"
grep -Eqi 'warn once|once per context|fall(s)? back|fallback' "$S" \
  || fail "no graceful fallback when rubix-review is absent"
# The offer must not smuggle in the verbatim contract.
grep -qF 'writes outside this repository checkout' "$S" \
  && fail "loop-brainstorm carries the verbatim reviewer-conduct contract (it should not)"

echo "PASS: loop-brainstorm offers a soft-checked Rubix pass on the finished brief"
