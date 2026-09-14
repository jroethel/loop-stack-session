#!/usr/bin/env bash
# Check for U14 (proof pass part 2). Authored by the orchestrator; the worker does not own this file.
# Lean by design: the multi-minute clean-room re-run happens at the orchestrator gate, not here.
set -uo pipefail
fail() { echo "CHECK FAIL: $*" >&2; exit 1; }
TASKDIR="${TASKDIR:-$PWD}"
cd "$TASKDIR" || fail "no worktree at $TASKDIR"
changed=$(git status --porcelain -uall | awk '{print $NF}') || true
for f in $changed; do
  case "$f" in
    README.md|docs/2026-09-13.proof-pass-receipts.md|NOTES) ;;
    *) fail "scope violation: $f is outside U14's ownership list" ;;
  esac
done
grep -qF '<VERSION>' README.md && fail "README still carries the <VERSION> placeholder"
grep -qE 'npx skills@[0-9][A-Za-z0-9.-]* add jroethel/jrit-loop' README.md || fail "README npx line is not pinned to a concrete version"
rlines=$(git diff -- README.md | grep -cE '^[+-][^+-]') || true
[ "$rlines" -le 2 ] || fail "README diff touches $rlines lines; only the npx pin line may change"
D=docs/2026-09-13.proof-pass-receipts.md
git diff -- "$D" | grep -E '^-[^-]' | grep -q . && fail "receipts doc has deleted lines; Part 1 must be untouched"
awk '/^## Part 2, post-flip/{f=1} f' "$D" > /tmp/u14-part2.txt
grep -qF 'clean-room-npx.sh' /tmp/u14-part2.txt || fail "Part 2 records no clean-room line"
grep -qF 'skills-package-version' /tmp/u14-part2.txt || fail "Part 2 does not quote the captured package version"
grep -qF 'single-resolution.sh' /tmp/u14-part2.txt || fail "Part 2 records no single-resolution line"
grep -qF "$(hostname)" /tmp/u14-part2.txt || fail "Part 2 does not name this host for the per-host single-resolution record"
grep -qF 'run-all.sh' /tmp/u14-part2.txt || fail "Part 2 records no pinned-README run-all re-run"
grep -qi 'exit' /tmp/u14-part2.txt || fail "Part 2 records no exit codes"
grep -qE 'gh issue (close|comment)' /tmp/u14-part2.txt && fail "Part 2 mentions issue mutations, which are the orchestrator's"
bash ci/run-all.sh >/dev/null 2>&1 || fail "run-all does not exit 0 with the pinned README"
bash ci/single-resolution.sh >/dev/null 2>&1 || fail "single-resolution does not pass at check time"
EMDASH=$(printf '\xe2\x80\x94'); grep -qF "$EMDASH" "$D" && fail "em dash in the receipts doc"
git add -A
git diff --cached > /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u14.patch || fail "patch export failed"
[ -s /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u14.patch ] || fail "patch export is empty"
echo "PASS: u14-proof-2"
