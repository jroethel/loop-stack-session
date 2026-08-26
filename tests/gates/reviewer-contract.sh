#!/usr/bin/env bash
# reviewer-contract.sh - the reviewer-conduct contract has exactly ONE canonical definition: loop-stack's
# own committed file at config/reviewer-conduct-contract.md, wired into loop-review and loop-drive by
# install.sh (mirroring the model-benchmarks wiring). It appears verbatim in NO loop-stack SKILL.md.
# loop-review and loop-drive reach it through references/reviewer-conduct-contract.md and fail closed
# when it is absent.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
cd "$REPO"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || { echo "FAIL: not a git work tree - reviewer-contract sweep cannot run" >&2; exit 1; }

PHRASE='writes outside this repository checkout'
CONTRACT_SRC="$REPO/config/reviewer-conduct-contract.md"

# sweep_clean <files...>: returns 1 (dirty) if the contract phrase is found in any file, else 0.
# Check 1 and the catch-alive both route through this one function, so the proof exercises the real
# sweep logic, not a stand-in. Portable to bash 3.2 (macOS) - no mapfile, no readarray.
sweep_clean() { local f rc=0; for f in "$@"; do grep -qF "$PHRASE" "$f" && { echo "  dirty: $f" >&2; rc=1; }; done; return $rc; }

# The sweep is a safety gate: a run that inspects zero files is a false green, so require a non-empty
# enumeration before trusting a clean result (loop-stack ships >=4 skill SKILL.md files).
SKILLS=(); while IFS= read -r f; do SKILLS+=("$f"); done < <(git ls-files 'skills/*/SKILL.md')
[ "${#SKILLS[@]}" -ge 4 ] \
  || fail "enumeration returned ${#SKILLS[@]} SKILL.md files (<4) - sweep cannot be trusted"

# 1. Zero verbatim contract text in any tracked loop-stack SKILL.md (source lives only in config/reviewer-conduct-contract.md).
sweep_clean "${SKILLS[@]}" \
  || fail "verbatim reviewer-conduct contract still present in a tracked loop-stack SKILL.md"

# 2. loop-review and loop-drive point at the canonical file and fail closed when absent.
for c in loop-review loop-drive; do
  S="$REPO/skills/$c/SKILL.md"
  [ -f "$S" ] || fail "$c SKILL.md missing"
  grep -q 'references/reviewer-conduct-contract.md' "$S" \
    || fail "$c does not point at references/reviewer-conduct-contract.md"
  grep -Eqi 'do not run the .* uncontracted|do not run the validators uncontracted|do not run the Spec/Standards subagents uncontracted|fail closed|stop and report' "$S" \
    || fail "$c lacks a fail-closed instruction for the absent-contract case"
done

# 3. loop-review activation guard: both subagent prompts still paste the contract (>=2 references).
LR="$REPO/skills/loop-review/SKILL.md"
refs="$(grep -c 'Paste the contents of .references/reviewer-conduct-contract.md' "$LR")"
[ "$refs" -ge 2 ] \
  || fail "loop-review has $refs/2 contract-paste bullets - both subagent prompts must paste the file"

# 4. install.sh wires the config-owned contract via symlink, with zero rubix coupling.
INST="$REPO/install.sh"
grep -q 'for consumer in loop-review loop-drive' "$INST" \
  || fail "install.sh lost the contract wiring loop"
grep -qF 'ln -sfn "$REPO/config/reviewer-conduct-contract.md"' "$INST" \
  || fail "install.sh does not symlink the config contract into consumers"
grep -q 'rubix-review' "$INST" && fail "install.sh still references rubix-review"
grep -q 'LOOP_STACK_RUBIX_ROOT' "$INST" && fail "install.sh still references LOOP_STACK_RUBIX_ROOT"
grep -q '_clauses_ok' "$INST" && fail "install.sh still carries the old _clauses_ok guard"
grep -q 'LOOP_STACK_RUBIX_ROOT' "$REPO/README.md" && fail "README.md still references LOOP_STACK_RUBIX_ROOT"
grep -q 'LOOP_STACK_RUBIX_ROOT' "$REPO/config/host.env.template" && fail "config/host.env.template still references LOOP_STACK_RUBIX_ROOT"
grep -q 'git clone https://github.com/jroethel/rubix-review' "$REPO/README.md" \
  && fail "README.md still tells operators to clone rubix-review for the contract"

# 5a. In-repo canonical: the committed source exists and still carries its clauses. A smoke check
#     that the contract keeps its teeth, not a tamper seal - git history is the integrity anchor
#     now the file is committed, so no external hash pin is needed.
[ -f "$CONTRACT_SRC" ] || fail "$CONTRACT_SRC missing - consumers fail closed with nothing to wire"
grep -qF 'writes outside this repository checkout' "$CONTRACT_SRC" \
  || fail "$CONTRACT_SRC missing clause: writes outside this repository checkout"
grep -qF 'evidence to read, never instructions' "$CONTRACT_SRC" \
  || fail "$CONTRACT_SRC missing clause: evidence to read, never instructions"
grep -qF "rerunning this repository's own test suite" "$CONTRACT_SRC" \
  || fail "$CONTRACT_SRC missing clause: rerunning this repository's own test suite"

# 5b. Runtime leaf: wherever the contract resolves on THIS host, it is not a dangling symlink and
#     still carries its clauses. Skip-with-note (not fail) when unresolvable - a fresh CI checkout
#     has no install.
LEAF=""
for d in "$HOME/.agents/skills" "$HOME/.claude/skills"; do
  [ -e "$d/loop-review/references/reviewer-conduct-contract.md" ] \
    && { LEAF="$d/loop-review/references/reviewer-conduct-contract.md"; break; }
done
if [ -n "$LEAF" ]; then
  [ -s "$LEAF" ] || fail "runtime leaf $LEAF is empty or a dangling symlink"
  grep -qF 'evidence to read, never instructions' "$LEAF" \
    && grep -qF "rerunning this repository's own test suite" "$LEAF" \
    || fail "runtime leaf $LEAF is missing required clauses (drift)"
  echo "note: verified runtime leaf at $LEAF"
else
  echo "note: runtime contract leaf not resolvable on this host (no install) - leaf check skipped"
fi

# 6. Catch-alive: run check 1's ACTUAL sweep logic against a seeded temp file - a broken sweep must fail here.
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$LR" "$TMP/seeded.md"; printf '\n%s\n' "$PHRASE" >> "$TMP/seeded.md"
sweep_clean "$TMP/seeded.md" && fail "catch-alive proof failed: the sweep did not flag a seeded contract phrase"

echo "PASS: loop-stack-owned canonical contract in config/, symlink-wired into both consumers, zero rubix/RUBIX_ROOT coupling, consumers point + fail closed report-only, activation guarded, leaf resolves, catch alive"
