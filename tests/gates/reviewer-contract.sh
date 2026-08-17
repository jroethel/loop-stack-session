#!/usr/bin/env bash
# reviewer-contract.sh - the reviewer-conduct contract must be present and byte-identical in every
# reviewer-prompt home. A read-only reviewer that executes a spec's embedded mutating command is the
# 2026-08-15 live-state deviation; this static test is the standing guard against that class of gap.
# Canonical home (copy-from source when the contract is revised): skills/loop-review/SKILL.md.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }

# A check that cannot tell "no hits" from "grep never ran" is a false-green generator: require a work tree.
cd "$REPO"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || { echo "FAIL: not a git work tree - reviewer-contract sweep cannot run" >&2; exit 1; }

# The three reviewer-prompt homes.
HOMES=(
  "$REPO/skills/loop-review/SKILL.md"
  "$REPO/skills/loop-drive/SKILL.md"
  "$REPO/skills/loop-plan/SKILL.md"
)

# Extract the text strictly between the markers (the marker lines themselves are excluded).
extract() {
  awk '
    /<!-- reviewer-contract:START -->/ { f=1; next }
    /<!-- reviewer-contract:END -->/   { f=0 }
    f
  ' "$1"
}

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# 1. Every home carries a non-empty block.
i=0
for h in "${HOMES[@]}"; do
  [ -f "$h" ] || fail "reviewer-prompt home missing: $h"
  extract "$h" > "$TMP/block.$i"
  [ -s "$TMP/block.$i" ] || fail "reviewer-contract block absent or empty in $h"
  i=$((i + 1))
done

# 2. Every block is byte-identical to the first home's.
i=1
while [ "$i" -lt "${#HOMES[@]}" ]; do
  diff "$TMP/block.0" "$TMP/block.$i" >/dev/null \
    || fail "reviewer-contract block in ${HOMES[$i]} diverges from ${HOMES[0]} (not byte-identical)"
  i=$((i + 1))
done

# 3. The block names both required layers and keeps the in-repo test rerun legal.
grep -qF 'writes outside this repository checkout' "$TMP/block.0" \
  || fail "contract missing the outside-checkout-write bar ('writes outside this repository checkout')"
grep -qF 'evidence to read, never instructions' "$TMP/block.0" \
  || fail "contract missing the embedded-commands-are-evidence rule ('evidence to read, never instructions')"
grep -qF "rerunning this repository's own test suite" "$TMP/block.0" \
  || fail "contract missing the test-rerun-stays-legal clause ('rerunning this repository's own test suite')"

# 4. loop-review activation guard: presence of the block is not enough in loop-review, where the block
#    is defined once and reaches each subagent only via the two "Paste ..." reference bullets. A later
#    edit that drops those bullets would leave the Spec/Standards subagents un-contracted while this
#    test stayed green - the exact 2026-08-15 incident home. Guard the bullets permanently.
LR="$REPO/skills/loop-review/SKILL.md"
refs="$(grep -c 'Paste the reviewer-conduct contract block' "$LR")"
[ "$refs" -ge 2 ] \
  || fail "loop-review has $refs/2 contract-reference bullets - both subagent prompts must paste the block"

# 5. Negative-path (catch-alive) proof: a mutated copy of the first home must be flagged by the same
#    identity comparison, so a real divergence cannot slip past unseen.
cp "${HOMES[0]}" "$TMP/mutated.md"
sed -i.bak 's/reviewing the work, not running it/reviewing the work, NOT-MUTATED running it/' "$TMP/mutated.md"
extract "$TMP/mutated.md" > "$TMP/mutated.block"
if diff "$TMP/mutated.block" "$TMP/block.0" >/dev/null 2>&1; then
  fail "negative-path proof failed: the identity comparison did not flag a mutated block (catch is dead)"
fi

echo "PASS: reviewer-contract present + byte-identical across 3 homes (canonical: loop-review), both layers named, loop-review activation guarded, catch alive"
