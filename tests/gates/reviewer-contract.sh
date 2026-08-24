#!/usr/bin/env bash
# reviewer-contract.sh - the reviewer-conduct contract has exactly ONE canonical definition (owned by
# the rubix-review skill) and appears verbatim in NO loop-stack SKILL.md. loop-review and loop-drive
# reach it through references/reviewer-conduct-contract.md and fail closed when it is absent. This
# replaces the prior byte-identical-across-3-homes guard after the Rubix extraction.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
cd "$REPO"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || { echo "FAIL: not a git work tree - reviewer-contract sweep cannot run" >&2; exit 1; }

PHRASE='writes outside this repository checkout'

# sweep_clean <files...>: returns 1 (dirty) if the contract phrase is found in any file, else 0.
# Check 1 and the catch-alive both route through this one function, so the proof exercises the real
# sweep logic, not a stand-in. Portable to bash 3.2 (macOS) - no mapfile, no readarray.
sweep_clean() { local f rc=0; for f in "$@"; do grep -qF "$PHRASE" "$f" && { echo "  dirty: $f" >&2; rc=1; }; done; return $rc; }

# The sweep is a safety gate: a run that inspects zero files is a false green, so require a non-empty
# enumeration before trusting a clean result (loop-stack ships >=4 skill SKILL.md files).
SKILLS=(); while IFS= read -r f; do SKILLS+=("$f"); done < <(git ls-files 'skills/*/SKILL.md')
[ "${#SKILLS[@]}" -ge 4 ] \
  || fail "enumeration returned ${#SKILLS[@]} SKILL.md files (<4) - sweep cannot be trusted"

# 1. Zero verbatim contract text in any tracked loop-stack SKILL.md (source lives only in rubix-review).
sweep_clean "${SKILLS[@]}" \
  || fail "verbatim reviewer-conduct contract still present in a tracked loop-stack SKILL.md"

# 2. loop-review and loop-drive point at the canonical file and fail closed when absent.
for c in loop-review loop-drive; do
  S="$REPO/skills/$c/SKILL.md"
  [ -f "$S" ] || fail "$c SKILL.md missing"
  grep -q 'references/reviewer-conduct-contract.md' "$S" \
    || fail "$c does not point at references/reviewer-conduct-contract.md"
  grep -Eqi 'do not run .* uncontracted|fail closed|stop and report' "$S" \
    || fail "$c lacks a fail-closed instruction for the absent-contract case"
done

# 3. loop-review activation guard: both subagent prompts still paste the contract (>=2 references).
LR="$REPO/skills/loop-review/SKILL.md"
refs="$(grep -c 'Paste the contents of .references/reviewer-conduct-contract.md' "$LR")"
[ "$refs" -ge 2 ] \
  || fail "loop-review has $refs/2 contract-paste bullets - both subagent prompts must paste the file"

# 4. install.sh self-installs, verifies clauses, and wires the contract (all three present).
INST="$REPO/install.sh"
grep -q 'reviewer-conduct-contract.md' "$INST" || fail "install.sh does not wire the contract"
grep -q 'LOOP_STACK_RUBIX_ROOT' "$INST"        || fail "install.sh does not self-install from LOOP_STACK_RUBIX_ROOT"
grep -q 'refusing to wire a gutted contract' "$INST" || fail "install.sh does not verify the contract clauses before wiring"

# 5. Drift guard: wherever the canonical contract resolves on THIS host, it still carries its clauses.
#    Skip-with-note (not fail) when unresolvable - a fresh CI checkout has no install and no rubix.
CANON=""
for d in "$HOME/.agents/skills" "$HOME/.claude/skills"; do
  [ -e "$d/rubix-review/references/reviewer-conduct-contract.md" ] \
    && { CANON="$d/rubix-review/references/reviewer-conduct-contract.md"; break; }
done
if [ -n "$CANON" ]; then
  grep -qF 'evidence to read, never instructions' "$CANON" \
    && grep -qF "rerunning this repository's own test suite" "$CANON" \
    || fail "resolved canonical contract $CANON is missing required clauses (rubix-review drift)"
  echo "note: verified canonical clauses at $CANON"
else
  echo "note: canonical contract not resolvable on this host (no install / no rubix-review) - clause drift check skipped"
fi

# 6. Catch-alive: run check 1's ACTUAL sweep logic against a seeded temp file - a broken sweep must fail here.
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$LR" "$TMP/seeded.md"; printf '\n%s\n' "$PHRASE" >> "$TMP/seeded.md"
sweep_clean "$TMP/seeded.md" && fail "catch-alive proof failed: the sweep did not flag a seeded contract phrase"

echo "PASS: one canonical contract (rubix-review), non-empty sweep, zero verbatim duplicates, consumers point + fail closed, install self-heals + verifies clauses, activation guarded, catch alive"
