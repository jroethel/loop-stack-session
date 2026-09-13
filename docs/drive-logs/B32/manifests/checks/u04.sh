#!/usr/bin/env bash
# Check for U04 (receipt helper and its gate proofs). Authored by the orchestrator; the worker does not own this file.
# U04 is a check-custody exception: it owns tests/receipt-gates.sh and is judged by it, so this
# check audits the test file structurally before it trusts the test's own verdict.
set -uo pipefail
fail() { echo "CHECK FAIL: $*" >&2; exit 1; }
TASKDIR="${TASKDIR:-$PWD}"
cd "$TASKDIR" || fail "no worktree at $TASKDIR"

HELPER=skills/loop-drive/scripts/receipt.sh
TEST=tests/receipt-gates.sh
ALW=ci/reference-allowlist.txt

# 1. Ownership audit, over OWNED files only. NOTES is the one sanctioned unowned file.
changed=$(git status --porcelain | awk '{print $NF}')
for f in $changed; do
  case "$f" in
    skills/loop-drive/scripts/receipt.sh|tests/receipt-gates.sh|ci/reference-allowlist.txt|NOTES) ;;
    *) fail "scope violation: $f is outside U04's ownership list (helper, test, allow-list append, NOTES)" ;;
  esac
done

# 2. Deliverables exist and are non-trivial.
for f in "$HELPER" "$TEST"; do
  [ -s "$f" ] || fail "missing or empty deliverable: $f"
done

# 3. Script discipline, per the global constraints.
for s in "$HELPER" "$TEST"; do
  grep -q 'set -uo pipefail' "$s" || fail "$s is missing 'set -uo pipefail'"
  grep -qE 'fail *\(\)' "$s" || fail "$s is missing a fail() helper"
  grep -q 'PASS:' "$s" || fail "$s is missing an explicit PASS: line"
done
grep -qF 'PASS: receipt gates 0-6' "$TEST" || fail "$TEST does not print the required 'PASS: receipt gates 0-6' line"

# 4. The helper implements the four verbs and their flags, per D8 lines 315-322.
for v in 'next-eligible' 'claim' 'status' 'done'; do
  grep -qF "$v" "$HELPER" || fail "helper does not mention the verb '$v'; D8 fixes four verbs and no others"
done
for flag in '--receipt' '--ran' '--reclaim'; do
  grep -qF -- "$flag" "$HELPER" || fail "helper does not handle the flag $flag named in D8's verb signatures"
done
if grep -qF '${CLAUDE_PLUGIN_ROOT}' "$HELPER"; then
  fail "helper contains \${CLAUDE_PLUGIN_ROOT}, which is banned everywhere under skills/"
fi

# 5. STRUCTURAL AUDIT OF THE SELF-OWNED TEST, by literal marker.
#    Source-plan lines 762-774 name these; a weakened or deleted gate fails the unit here,
#    before the test's own verdict is trusted at all.
for i in 0 1 2 3 4 5 6; do
  grep -qiE "gate ${i}([^0-9]|$)" "$TEST" \
    || fail "$TEST no longer carries a marker for Gate $i; source-plan lines 765-771 require Gates 0 through 6"
done
for code in 4 5 7; do
  grep -qE "(-eq|-ne|==|!=)[[:space:]]*\"?${code}\"?([^0-9]|$)" "$TEST" \
    || fail "$TEST never compares against exit code ${code}; Gate 1 asserts 7, Gate 2 asserts 4, Gate 5 asserts 5"
done
grep -qF 'RACE:' "$TEST" || fail "$TEST does not assert the 'RACE:' string that Gate 2 requires on stderr"
grep -qF 'skip: gitlab gates (GITLAB_TEST_PROJECT unset)' "$TEST" \
  || fail "$TEST is missing the exact loud skip line 'skip: gitlab gates (GITLAB_TEST_PROJECT unset)'"
grep -qF 'GITLAB_TEST_PROJECT' "$TEST" || fail "$TEST does not branch on GITLAB_TEST_PROJECT at all"

# 5a. No assertion may be neutered with '|| true'.
#     The exception is deliberate and carried: a '|| true' on a PROVISIONING or CLEANUP line is
#     required (Gate 0 quotes loop-setup's 'gh label create ... || true' verbatim, and the stale
#     scratch-repo sweep uses it too). Only lines that OPEN with an assertion construct are judged.
vacuous=$(grep -nE '^[[:space:]]*(\[|test |assert|grep |cmp |diff ).*\|\|[[:space:]]*true[[:space:]]*$' "$TEST")
[ -z "$vacuous" ] || fail "assertion neutered with '|| true' in $TEST: $vacuous"

# 5b. The helper is invoked as 'bash scripts/receipt.sh ...' everywhere, per D8 line 312.
badinv=$(grep -nE 'receipt\.sh[[:space:]]+(done|claim|status|next-eligible)' "$TEST" | grep -vE 'bash[[:space:]]')
[ -z "$badinv" ] || fail "invocation not in the mandated 'bash scripts/receipt.sh ...' form: $badinv"

# 5c. Scratch-repo naming and the delete guard, per the spec's hard rule.
grep -qF 'jrit-loop-scratch-' "$TEST" || fail "$TEST does not name the jrit-loop-scratch-<epoch>-<random> repo shape"
grep -qF '$RANDOM' "$TEST" || fail "$TEST does not use \$RANDOM in the scratch repo name; a PID collides across hosts"
pidname=$(grep -n 'scratch.*\$\$' "$TEST")
[ -z "$pidname" ] || fail "scratch repo name built from \$\$ instead of \$RANDOM: $pidname"
grep -q 'gh repo delete' "$TEST" || fail "$TEST never deletes its scratch repo; the cleanup trap is missing"
baddel=$(grep -n 'gh repo delete' "$TEST" | grep -v '\$' | grep -v 'jrit-loop-scratch')
[ -z "$baddel" ] || fail "gh repo delete targets something other than a scratch repo this run created: $baddel"

# 6. The helper line budget, measured here so the gate sees the C5 condition explicitly.
sloc=$(grep -cvE '^[[:space:]]*(#|$)' "$HELPER")
echo "measured helper SLOC (non-blank, non-comment) for $HELPER: $sloc"
[ "$sloc" -lt 200 ] \
  || fail "C5 CONDITION: helper SLOC is $sloc, which is 200 or more; D8 line 337 fails the unit here and the escalation is checkpoint C5"

# 7. Allow-list discipline: appends only, each appended line carrying a trailing '# why'.
[ -f "$ALW" ] || fail "$ALW is missing from the base tree; U03 owns and creates it"
alwdiff=$(git diff HEAD -- "$ALW")
dels=$(printf '%s\n' "$alwdiff" | sed -n 's/^-\([^-].*\)$/\1/p')
adds=$(printf '%s\n' "$alwdiff" | sed -n 's/^+\([^+].*\)$/\1/p')
while IFS= read -r line; do
  [ -n "$line" ] || continue
  printf '%s\n' "$adds" | grep -Fxq "$line" \
    || fail "pre-existing allow-list line deleted or rewritten, which is forbidden: $line"
done <<EOF
$dels
EOF
while IFS= read -r line; do
  [ -n "$line" ] || continue
  printf '%s\n' "$line" | grep -qE '^[[:space:]]*#' && continue
  printf '%s\n' "$line" | grep -q '# why' \
    || fail "appended allow-list line carries no trailing '# why' justification: $line"
done <<EOF
$adds
EOF

# 8. The NOTES contract.
[ -s NOTES ] || fail "./NOTES is missing or empty; the output contract requires it"
head -1 NOTES | grep -qE '^AGENT STATUS unit=u04 branch=worktree verdict=self-pass repairs=[0-9]+$' \
  || fail "./NOTES line 1 is not the required AGENT STATUS receipt: $(head -1 NOTES)"

# 9. The task's acceptance command, verbatim from source-plan line 751, exit code captured plainly.
bash tests/receipt-gates.sh && bash ci/budget-check.sh
rc=$?
[ "$rc" -eq 0 ] || fail "acceptance command 'bash tests/receipt-gates.sh && bash ci/budget-check.sh' exited $rc"

# 10. Post-run: the test must not leak scratch repos under the account (source-plan step 10).
if ! repolist=$(gh repo list jroethel --limit 200 2>&1); then
  fail "could not list repos to verify scratch cleanup, so cleanup is unproven: $repolist"
fi
leftover=$(printf '%s\n' "$repolist" | grep 'jrit-loop-scratch')
[ -z "$leftover" ] || fail "scratch repos survived the run and must be deleted by hand: $leftover"

# 11. Export the deliverable BEFORE the worktree is deleted.
git add -A
git diff --cached > /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u04.patch \
  || fail "patch export failed"
[ -s /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u04.patch ] \
  || fail "patch export is empty: no work to harvest"
echo "PASS: u04-receipt"
