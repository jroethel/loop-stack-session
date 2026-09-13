#!/usr/bin/env bash
# Check for U03b (scoped CI fixes). Authored by the orchestrator; the worker does not own this file.
set -uo pipefail
fail() { echo "CHECK FAIL: $*" >&2; exit 1; }
TASKDIR="${TASKDIR:-$PWD}"
cd "$TASKDIR" || fail "no worktree at $TASKDIR"
changed=$(git status --porcelain | awk '{print $NF}') || true
for f in $changed; do
  case "$f" in
    ci/structure-check.sh|ci/single-resolution.sh|NOTES) ;;
    *) fail "scope violation: $f is outside U03b's ownership list" ;;
  esac
done
bash ci/run-all.sh >/dev/null 2>&1 || fail "ci/run-all.sh does not exit 0 on the clean tree"
mkdir -p skills/loop-drive/references
printf 'The pointer doc is docs/loop/pointer.md.\n' > skills/loop-drive/references/tmp-probe.md
if ! bash ci/structure-check.sh >/dev/null 2>&1; then
  rm -rf skills/loop-drive; fail "Check H still trips on the literal path docs/loop/pointer.md"
fi
printf 'Run /loop to resume.\n' > skills/loop-drive/references/tmp-probe.md
if bash ci/structure-check.sh >/dev/null 2>&1; then
  rm -rf skills/loop-drive; fail "Check H no longer catches a real /loop invocation; the ban is now vacuous"
fi
printf 'Run /goal next.\n' > skills/loop-drive/references/tmp-probe.md
if bash ci/structure-check.sh >/dev/null 2>&1; then
  rm -rf skills/loop-drive; fail "Check H no longer catches a real /goal invocation"
fi
rm -rf skills/loop-drive
bash ci/structure-check.sh >/dev/null 2>&1 || fail "structure-check does not pass after probe cleanup"
printf 'x \xe2\x80\x94 x\n' > docs/tmp-probe.md
if bash ci/structure-check.sh >/dev/null 2>&1; then
  rm -f docs/tmp-probe.md; fail "Check G does not sweep docs/ markdown for the em dash"
fi
rm -f docs/tmp-probe.md
bash ci/structure-check.sh >/dev/null 2>&1 || fail "structure-check does not pass after Check G probe cleanup"
grep -qiE 'distinct|more than one|multiple' ci/single-resolution.sh || fail "single-resolution.sh shows no multi-record failure branch"
git add -A
git diff --cached > /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u03b.patch || fail "patch export failed"
[ -s /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u03b.patch ] || fail "patch export is empty"
echo "PASS: u03b-fixes"
