#!/usr/bin/env bash
# Check for U15 (community submission staged). Authored by the orchestrator; the worker does not own this file.
set -uo pipefail
fail() { echo "CHECK FAIL: $*" >&2; exit 1; }
TASKDIR="${TASKDIR:-$PWD}"
cd "$TASKDIR" || fail "no worktree at $TASKDIR"
changed=$(git status --porcelain -uall | awk '{print $NF}') || true
for f in $changed; do
  case "$f" in
    docs/community-submission.md|NOTES) ;;
    *) fail "scope violation: $f is outside U15's ownership list" ;;
  esac
done
D=docs/community-submission.md
[ -f "$D" ] || fail "$D does not exist"
# C6 dependency: the criterion-14 record must be present in the receipts doc (inherited from base, not the worker's).
grep -qF 'Criterion 14, checkpoint C6' docs/2026-09-13.proof-pass-receipts.md || fail "receipts doc carries no criterion-14 section; Task 15 depends on C6"
grep -qF 'platform.claude.com/plugins/submit' "$D" || fail "submission doc names no submission URL"
grep -qF 'github.com/jroethel/jrit-loop' "$D" || fail "submission doc names no repository URL"
V=$(jq -r .version .claude-plugin/plugin.json) || fail "cannot read version from plugin.json"
grep -qF "$V" "$D" || fail "submission doc does not carry the plugin.json version $V"
for s in loop-brainstorm loop-plan loop-drive loop-review loop-improve loop-molt loop-track loop-auto loop-setup wayfinder handoff; do
  grep -q "$s" "$D" || fail "submission doc does not name skill $s"
done
grep -qF 'MIT' "$D" || fail "submission doc names no license"
grep -q '^## Evidence' "$D" || fail "submission doc has no Evidence section"
awk '/^## Evidence/{f=1} f' "$D" > /tmp/u15-evidence.txt
grep -qi 'exit' /tmp/u15-evidence.txt || fail "Evidence section quotes no exit codes"
grep -qi 'secrets' /tmp/u15-evidence.txt || fail "Evidence section quotes no secrets-scan record"
grep -qi 'eval' /tmp/u15-evidence.txt || fail "Evidence section quotes no eval record"
grep -qi 'unpublish' /tmp/u15-evidence.txt || fail "Evidence section states no eval-report publish decision"
EMDASH=$(printf '\xe2\x80\x94'); grep -qF "$EMDASH" "$D" && fail "em dash in the submission doc"
# The plan's Task 15 acceptance compound (source plan line 1179), run from the worktree root in place of the cd.
claude plugin validate --strict . && claude plugin validate --strict .claude-plugin/plugin.json && bash ci/run-all.sh && bash -c 'test "$(gh repo view jroethel/jrit-loop --json visibility -q .visibility)" = PUBLIC && grep -q "platform.claude.com/plugins/submit" docs/community-submission.md' && echo PASS
rc=$?
[ "$rc" -eq 0 ] || fail "acceptance compound exited $rc"
git add -A
git diff --cached > /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u15.patch || fail "patch export failed"
[ -s /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u15.patch ] || fail "patch export is empty"
echo "PASS: u15-submission"
