#!/usr/bin/env bash
# Check for U03 (CI checks). Authored by the orchestrator; the worker does not own this file.
set -uo pipefail
fail() { echo "CHECK FAIL: $*" >&2; exit 1; }
cd "$TASKDIR" || fail "no worktree at $TASKDIR"

# 1. Ownership audit over the final tree: only ci/**, .github/**, NOTES may differ from base.
changed=$(git status --porcelain | awk '{print $NF}') || true
for f in $changed; do
  case "$f" in
    ci/*|.github/*|NOTES) ;;
    *) fail "scope violation: $f is outside U03's ownership list" ;;
  esac
done

# 2. Substance: the eleven owned artifacts exist.
for f in ci/structure-check.sh ci/budget-check.sh ci/version-drift.sh ci/secrets-scan.sh \
         ci/consumer-sweep.sh ci/clean-room-npx.sh ci/single-resolution.sh ci/run-all.sh \
         ci/banned-tokens.txt ci/reference-allowlist.txt .github/workflows/ci.yml; do
  [ -f "$f" ] || fail "missing deliverable: $f"
done

# 3. Script discipline: set -uo pipefail, a fail helper, an explicit PASS: line, in every check script.
for s in ci/*.sh; do
  grep -q 'set -uo pipefail' "$s" || fail "$s missing set -uo pipefail"
  grep -qE 'fail\(\)' "$s" || fail "$s missing fail() helper"
  grep -qE 'PASS: ' "$s" || fail "$s missing an explicit PASS: line"
done

# 4. Data files carry the load-bearing seeds.
for t in '${CLAUDE_PLUGIN_ROOT}' '~/.claude/skills/' '~/.agents/skills/' 'scripts/tracker.sh' 'docs/chain-state.md' '/home/' 'C:\'; do
  grep -qF "$t" ci/banned-tokens.txt || fail "banned-tokens.txt missing seed: $t"
done
for t in config/repo-state.md config/conventions.md AGENTS.md CLAUDE.md README.md ROADMAP.md; do
  grep -q "^$t" ci/reference-allowlist.txt || fail "reference-allowlist.txt missing seed: $t"
done
bad=$(grep -vE '^\s*(#|$)' ci/reference-allowlist.txt | grep -v '# why' | head -3) || true
[ -z "$bad" ] || fail "allow-list lines missing '# why' justification: $bad"

# 5. Workflow substance.
grep -q 'gitleaks/gitleaks-action@v2' .github/workflows/ci.yml || fail "ci.yml missing gitleaks action"
grep -q 'fetch-depth: 0' .github/workflows/ci.yml || fail "ci.yml missing fetch-depth: 0"

# 6. The task's acceptance command, verbatim.
bash ci/run-all.sh
rc=$?
[ "$rc" -eq 0 ] || fail "bash ci/run-all.sh exited $rc"

# 7. One live negative probe: structure-check must fail on a planted banned token, then pass clean.
mkdir -p skills/tmp-check-probe
printf 'x ${CLAUDE_PLUGIN_ROOT} x\n' > skills/tmp-check-probe/SKILL.md
if bash ci/structure-check.sh >/dev/null 2>&1; then
  rm -rf skills/tmp-check-probe
  fail "structure-check passed with a planted banned token; Check A is vacuous"
fi
rm -rf skills/tmp-check-probe
bash ci/structure-check.sh >/dev/null 2>&1 || fail "structure-check does not pass on the clean tree after probe removal"

# 8. Export the deliverable BEFORE the worktree is deleted.
git add -A
git diff --cached > /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u03.patch \
  || fail "patch export failed"
[ -s /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u03.patch ] \
  || fail "patch export is empty: no work to harvest"
echo "PASS: u03-ci"
