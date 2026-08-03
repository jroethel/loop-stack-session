#!/usr/bin/env bash
# loop-plan gains the H decompose-dispatch + dependency-graph review, and the K prefactor rule.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
S="$REPO/skills/loop-plan/SKILL.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$S" ] || fail "loop-plan SKILL missing"
# H: plan-draft dispatch + dependency-graph review.
grep -qi 'plan-draft' "$S" || fail "no plan-draft role-pin reference"
grep -Eqi 'dependency graph|depends-on edges|dependency-graph' "$S" || fail "no dependency-graph review step"
# K: prefactor rule + expand-contract reference.
grep -qi 'prefactor' "$S" || fail "no prefactor rule"
grep -Eqi 'expand-contract|expand/contract' "$S" || fail "no expand-contract reference"
echo "PASS: loop-plan carries H decompose dispatch and K prefactor rule"
