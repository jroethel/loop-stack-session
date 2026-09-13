#!/usr/bin/env bash
# Check for U12 (cutover staging). Authored by the orchestrator; the worker does not own this file.
set -uo pipefail
fail() { echo "CHECK FAIL: $*" >&2; exit 1; }
TASKDIR="${TASKDIR:-$PWD}"
cd "$TASKDIR" || fail "no worktree at $TASKDIR"
changed=$(git status --porcelain -uall | awk '{print $NF}') || true
for f in $changed; do
  case "$f" in
    tests/pre-plugin-detection.sh|docs/decommission.md|NOTES) ;;
    *) fail "scope violation: $f is outside U12's ownership list" ;;
  esac
done
# The decommission must be STAGED, not fired: the farm still resolves and the plugin is not installed.
[ -e "$HOME/.claude/skills/loop-drive" ] || fail "the symlink farm is gone: something fired the decommission early"
claude plugin list 2>/dev/null | grep -qi 'jrit-loop' && fail "jrit-loop plugin is installed: the staged install was fired early"
[ -s tests/pre-plugin-detection.sh ] && [ -s docs/decommission.md ] || fail "a deliverable is missing or empty"
grep -qF '**Pre-plugin repo check.**' tests/pre-plugin-detection.sh || fail "the test does not hold the D3 paragraph copy it compares against"
grep -q 'loop-review' tests/pre-plugin-detection.sh && grep -q 'loop-molt' tests/pre-plugin-detection.sh || fail "the test does not assert the two non-carrier skills"
grep -qF 'Migrating a pre-plugin repo' tests/pre-plugin-detection.sh || fail "the test does not assert loop-setup's migration heading"
grep -q 'set -uo pipefail' tests/pre-plugin-detection.sh && grep -qE 'fail *\(\)' tests/pre-plugin-detection.sh || fail "test script discipline missing"
grep -qF 'PASS: pre-plugin detection wired in 8 skills' tests/pre-plugin-detection.sh || fail "the test does not print the mandated PASS line"
grep -qF 'ln -s' docs/decommission.md || fail "decommission.md has no rollback ln -s loop (Section 3)"
grep -qF -- '# --- loop-stack (managed) ---' docs/decommission.md || fail "managed-block opening marker missing (Section 4)"
grep -qF -- '# --- end loop-stack (managed) ---' docs/decommission.md || fail "managed-block closing marker missing (Section 4)"
grep -qF "find \$HOME/repos -maxdepth 3 -path" docs/decommission.md || fail "Section 5 does not use the mandated find form for the repo list"
grep -q 'per-host' docs/decommission.md || fail "Section 5 does not state the per-host rule"
grep -qF 'resolves twice' docs/decommission.md || fail "the transient double-resolution line is missing above the command block"
grep -qF 'bash ~/repos/jrit/jrit-loop/ci/single-resolution.sh' docs/decommission.md || fail "the staged block does not end with the single-resolution verification"
bash tests/pre-plugin-detection.sh && bash -c 'grep -q "rm -f \$HOME/.claude/skills" docs/decommission.md && grep -q "rm -f \$HOME/.agents/skills" docs/decommission.md && grep -q "loop-stack (managed)" docs/decommission.md && test "$(grep -n "claude plugin install" docs/decommission.md | head -1 | cut -d: -f1)" -lt "$(grep -n "rm -f \$HOME/.claude/skills" docs/decommission.md | head -1 | cut -d: -f1)"'
rc=$?
[ "$rc" -eq 0 ] || fail "acceptance compound exited $rc"
EMDASH=$(printf '\xe2\x80\x94'); grep -rqF "$EMDASH" tests/pre-plugin-detection.sh docs/decommission.md && fail "em dash in a deliverable"
git add -A
git diff --cached > /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u12.patch || fail "patch export failed"
[ -s /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u12.patch ] || fail "patch export is empty"
echo "PASS: u12-cutover"
