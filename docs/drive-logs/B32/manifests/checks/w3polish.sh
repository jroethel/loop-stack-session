#!/usr/bin/env bash
# Check for W3POLISH. Authored by the orchestrator; the worker does not own this file.
set -uo pipefail
fail() { echo "CHECK FAIL: $*" >&2; exit 1; }
TASKDIR="${TASKDIR:-$PWD}"
cd "$TASKDIR" || fail "no worktree at $TASKDIR"
changed=$(git status --porcelain -uall | awk '{print $NF}') || true
for f in $changed; do
  case "$f" in
    ci/budget-check.sh|skills/loop-brainstorm/references/brief-pipeline.md|skills/loop-improve/references/brief-pipeline.md|skills/loop-molt/references/brief-pipeline.md|skills/loop-plan/SKILL.md|skills/loop-review/SKILL.md|skills/loop-setup/SKILL.md|skills/loop-setup/references/pointer-templates.md|NOTES) ;;
    *) fail "scope violation: $f is outside W3POLISH's ownership list" ;;
  esac
done
cmp -s skills/loop-brainstorm/references/brief-pipeline.md skills/loop-improve/references/brief-pipeline.md || fail "brief-pipeline copies diverge: brainstorm vs improve"
cmp -s skills/loop-brainstorm/references/brief-pipeline.md skills/loop-molt/references/brief-pipeline.md || fail "brief-pipeline copies diverge: brainstorm vs molt"
grep -q 'config/conventions.md' skills/loop-brainstorm/references/brief-pipeline.md && fail "brief-pipeline still points at config/conventions.md"
grep -q 'docs/loop/conventions.md' skills/loop-brainstorm/references/brief-pipeline.md || fail "brief-pipeline does not point at docs/loop/conventions.md"
c=$(grep -c 'not installed in this session; continuing without it' skills/loop-plan/SKILL.md); [ "$c" -ge 1 ] || fail "D6 disclosure wording missing from loop-plan"
grep -q 'is unavailable (rubix-review not installed)' skills/loop-plan/SKILL.md && fail "old rubix disclosure wording still ships in loop-plan"
grep -q 'loop-stack' skills/loop-review/SKILL.md && fail "stale loop-stack branding still in loop-review"
grep -q 'docs/agents/' skills/loop-review/SKILL.md && fail "dead docs/agents/ path still in loop-review"
grep -qi 'pause' skills/loop-setup/references/pointer-templates.md || grep -A2 'autonomy-default' skills/loop-setup/SKILL.md | grep -qi 'pause' || fail "fresh-install autonomy-default value (pause) stated nowhere in loop-setup"
grep -q 'runtime state file' skills/loop-setup/SKILL.md || fail "chain-state.md still described only as a mirror file in loop-setup"
mv skills/handoff/agents/openai.yaml /tmp/w3polish-probe.yaml || fail "cannot stage the hardening probe"
if bash ci/budget-check.sh >/dev/null 2>&1; then
  mv /tmp/w3polish-probe.yaml skills/handoff/agents/openai.yaml
  fail "budget-check still passes with openai.yaml missing; the existence assertion is not hard"
fi
mv /tmp/w3polish-probe.yaml skills/handoff/agents/openai.yaml
bash ci/budget-check.sh >/dev/null 2>&1 || fail "budget-check does not pass after probe restore"
bash ci/run-all.sh >/dev/null 2>&1 || fail "ci/run-all.sh does not exit 0 after the fixes"
git add -A
git diff --cached > /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/w3polish.patch || fail "patch export failed"
[ -s /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/w3polish.patch ] || fail "patch export is empty"
echo "PASS: w3polish"
