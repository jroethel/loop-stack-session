#!/usr/bin/env bash
# loop-plan Step 6 is a soft-checked call to the rubix-review skill, not an inline block, and the
# reviewer-conduct contract no longer lives in loop-plan.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
S="$REPO/skills/loop-plan/SKILL.md"
RS="$REPO/config/repo-state.md"
RST="$REPO/config/repo-state.template.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$S" ] || fail "loop-plan SKILL missing"

# 1. Step 6 calls the rubix-review skill.
grep -q 'rubix-review' "$S" || fail "Step 6 does not reference the rubix-review skill"

# 2. Soft-check: both present and absent branches documented.
grep -Eqi 'rubix-autorun' "$S" || fail "Step 6 does not read the rubix-autorun key"
grep -Eqi 'warn once|once per context' "$S" || fail "no warn-once fallback for the absent case"
grep -Eqi 'never a hard failure|fall(s)? back|fallback' "$S" || fail "no graceful-fallback statement"

# 3. The inline contract block is gone from loop-plan.
grep -qF 'writes outside this repository checkout' "$S" \
  && fail "loop-plan still carries the verbatim reviewer-conduct contract"
grep -q 'reviewer-contract:START' "$S" \
  && fail "loop-plan still carries the reviewer-contract marker block"

# 4. No inline model pins in Step 6.
for m in Opus Fable GLM; do
  grep -Eq "lens .* = *$m|$m .* lens" "$S" && fail "inline lens model pin '$m' still present"
done

# 5. rubix-autorun key present in repo-state and its template, defaulting to ask.
grep -Eq '^rubix-autorun: (ask|off|on)$' "$RS" || fail "config/repo-state.md lacks a rubix-autorun key"
grep -Eq 'rubix-autorun' "$RST" || fail "config/repo-state.template.md lacks the rubix-autorun key"

echo "PASS: loop-plan Step 6 is a soft-checked rubix-review call; contract and model pins removed; rubix-autorun keyed"
