#!/usr/bin/env bash
# Check for U13 (proof pass part 1). Authored by the orchestrator; the worker does not own this file.
set -uo pipefail
fail() { echo "CHECK FAIL: $*" >&2; exit 1; }
TASKDIR="${TASKDIR:-$PWD}"
cd "$TASKDIR" || fail "no worktree at $TASKDIR"
changed=$(git status --porcelain -uall | awk '{print $NF}') || true
for f in $changed; do
  case "$f" in
    docs/2026-09-13.proof-pass-receipts.md|NOTES) ;;
    *) fail "scope violation: $f is outside U13's ownership list" ;;
  esac
done
D=docs/2026-09-13.proof-pass-receipts.md
[ -s "$D" ] || fail "receipts doc missing"
grep -q '^## Part 1, pre-flip' "$D" || fail "Part 1 heading missing"
grep -q '^## Part 2, post-flip' "$D" || fail "Part 2 heading missing (Task 14's slot)"
for c in 'plugin validate --strict' 'ci/run-all.sh' 'tests/receipt-gates.sh' 'tests/local-mode-grammar.sh' 'tests/pre-plugin-detection.sh' 'plugin eval' 'ci/consumer-sweep.sh' 'secrets-scan.sh --full-history'; do
  grep -qF "$c" "$D" || fail "receipts doc records no line for: $c"
done
grep -qiE 'gitleaks|grep fallback' "$D" || fail "secrets line does not name its engine"
grep -qi 'PRIVATE' "$D" || fail "the visibility check's PRIVATE observation is not recorded"
grep -qi 'exit' "$D" || fail "no exit codes recorded"
if grep -qi 'clean-room\|single-resolution' "$D"; then fail "doc records a Task-14 command that must not run pre-flip"; fi
gh repo list jroethel --limit 100 2>/dev/null | grep -q 'jrit-loop-scratch' && fail "a scratch repo survived the receipt-gates run"
bash ci/consumer-sweep.sh || fail "consumer sweep does not pass at check time"
bash ci/secrets-scan.sh --full-history || fail "full-history secrets scan does not pass at check time"
EMDASH=$(printf '\xe2\x80\x94'); grep -qF "$EMDASH" "$D" && fail "em dash in the receipts doc"
git add -A
git diff --cached > /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u13.patch || fail "patch export failed"
[ -s /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u13.patch ] || fail "patch export is empty"
echo "PASS: u13-proof-1"
