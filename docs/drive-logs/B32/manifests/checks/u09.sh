#!/usr/bin/env bash
# Check for U09 (loop-drive re-plumb). Authored by the orchestrator; the worker does not own this file.
set -uo pipefail
fail() { echo "CHECK FAIL: $*" >&2; exit 1; }
TASKDIR="${TASKDIR:-$PWD}"
cd "$TASKDIR" || fail "no worktree at $TASKDIR"
changed=$(git status --porcelain -uall | awk '{print $NF}') || true
for f in $changed; do
  case "$f" in
    skills/loop-drive/SKILL.md|skills/loop-drive/references/*|ci/reference-allowlist.txt|NOTES) ;;
    *) fail "scope violation: $f is outside U09's ownership list" ;;
  esac
done
git diff --quiet -- skills/loop-drive/scripts/receipt.sh || fail "receipt.sh was modified; it is Task 4's file"
[ -f skills/loop-drive/references/native-orchestration.md ] && fail "transient native-orchestration.md still ships; step 10 deletes it"
for f in SKILL.md references/fable-guidelines.md references/model-benchmarks.md references/harness-appendix-claude-code.md references/queue-runner.md references/ringer-substrate.md references/reviewer-conduct-contract.md references/one-minute-test.md; do
  [ -s "skills/loop-drive/$f" ] || fail "missing deliverable: skills/loop-drive/$f"
done
cmp -s skills/loop-drive/references/reviewer-conduct-contract.md skills/loop-review/references/reviewer-conduct-contract.md || fail "reviewer contract not byte-identical to loop-review's copy"
cmp -s skills/loop-drive/references/one-minute-test.md skills/loop-brainstorm/references/one-minute-test.md || fail "one-minute-test not byte-identical to loop-brainstorm's copy"
cmp -s skills/loop-drive/references/model-benchmarks.md /home/jjrdar/repos/loop-stack-session/config/routing/model-benchmarks.md || fail "model-benchmarks diverges from the canonical routing source"
grep -rn 'scripts/tracker.sh' skills/loop-drive/ && fail "a scripts/tracker.sh string survives in loop-drive"
grep -rnF '${CLAUDE_PLUGIN_ROOT}' skills/loop-drive/ && fail "CLAUDE_PLUGIN_ROOT appears in loop-drive"
grep -rn 'config/routing/' skills/loop-drive/ && fail "a config/routing path survives; the intra-skill references/model-benchmarks.md is the rewrite"
grep -qF 'RINGER_ROOT' skills/loop-drive/SKILL.md || fail "ringer stub probe (RINGER_ROOT) missing from SKILL.md"
grep -qF 'herdr api schema --json' skills/loop-drive/SKILL.md || fail "herdr stub compatibility probe missing from SKILL.md"
for m in '**Probe.**' '**Present:**' '**Absent:**' '**Disclose:**'; do
  c=$(grep -cF "$m" skills/loop-drive/SKILL.md); [ "$c" -ge 2 ] || fail "stub marker $m appears $c times in SKILL.md; the ringer and herdr instances need it twice"
done
grep -qF 'bash scripts/receipt.sh' skills/loop-drive/SKILL.md || fail "helper invocation form missing from SKILL.md"
grep -qF 'bash scripts/receipt.sh' skills/loop-drive/references/queue-runner.md || fail "helper invocation form missing from queue-runner.md"
for code in 4 5 7; do grep -qE "exit(s)? ${code}" skills/loop-drive/SKILL.md || fail "exit ${code} semantics not documented in SKILL.md"; done
grep -qF '**Pre-plugin repo check.**' skills/loop-drive/SKILL.md || fail "D3 pre-plugin paragraph missing"
grep -qF 'Follow the user'"'"'s global markdown style instructions already loaded in this session'"'"'s context, when any exist.' skills/loop-drive/SKILL.md || fail "D5 house-style sentence missing"
grep -qF 'SendMessage' skills/loop-drive/references/harness-appendix-claude-code.md || fail "appendix does not name SendMessage"
grep -qE 'user-invoked' skills/loop-drive/references/harness-appendix-claude-code.md || fail "appendix does not record the /goal-/loop user-invoked verdict"
bash ci/structure-check.sh && bash ci/budget-check.sh && bash ci/version-drift.sh && claude plugin validate --strict skills && bash -c 'S=skills/loop-drive/SKILL.md; for m in "## Unit" "## State" "## Next step" "## Recent artifacts" "scripts/receipt.sh" "next-eligible" "handoffs-home"; do grep -qF "$m" "$S" || { echo "MISSING: $m"; exit 1; }; done'
rc=$?
[ "$rc" -eq 0 ] || fail "acceptance compound exited $rc"
bash ci/version-drift.sh | grep -q 'skip: eleven' && fail "eleven-directory assertion still skipping; it must run hard now"
git add -A
git diff --cached > /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u09.patch || fail "patch export failed"
[ -s /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u09.patch ] || fail "patch export is empty"
echo "PASS: u09-loop-drive"
