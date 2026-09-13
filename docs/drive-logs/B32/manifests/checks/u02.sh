#!/usr/bin/env bash
# Check for U02 (repo skeleton). Authored by the orchestrator; the worker does not own this file.
set -uo pipefail
fail() { echo "CHECK FAIL: $*" >&2; exit 1; }
R=/home/jjrdar/repos/jrit/jrit-loop
cd "$R" || fail "repo missing at $R"
git rev-parse --abbrev-ref HEAD | grep -qx main || fail "not on branch main"
n=$(git rev-list --count HEAD 2>/dev/null) || fail "no commits"
[ "$n" -eq 1 ] || fail "expected exactly 1 commit, got $n"
if git remote | grep -q .; then fail "a git remote exists; C2 (remote create + push) is human-fired"; fi
if git status --porcelain | grep -q .; then fail "uncommitted or untracked files: $(git status --porcelain | head -5 | tr '\n' ' ')"; fi
jq -e '.name=="jrit-loop" and .version=="0.1.0" and .license=="MIT"' .claude-plugin/plugin.json >/dev/null || fail "plugin.json name/version/license wrong"
jq -e '.plugins | length==1' .claude-plugin/marketplace.json >/dev/null || fail "marketplace.json plugins length != 1"
jq -e '.plugins[0].name=="jrit-loop" and .plugins[0].source=="./"' .claude-plugin/marketplace.json >/dev/null || fail "marketplace entry name/source wrong"
jq -e '.plugins[0] | has("version") | not' .claude-plugin/marketplace.json >/dev/null || fail "marketplace entry carries a version key against the spec"
c=$(grep -c '^<!-- jrit-loop-version: 0.1.0 -->$' README.md) || true
[ "${c:-0}" -eq 1 ] || fail "README version marker line count ${c:-0}, expected exactly 1"
grep -q 'MIT License' LICENSE || fail "LICENSE does not carry the MIT License header"
grep -q '2026 Jeremy Roethel' LICENSE || fail "LICENSE copyright line missing"
grep -qF '/plugin marketplace add jroethel/jrit-loop' README.md || fail "README missing marketplace install route"
grep -qF 'npx skills@<VERSION> add jroethel/jrit-loop' README.md || fail "README missing npx route with <VERSION> placeholder"
grep -qi 'portability doctrine' README.md || fail "README missing the contributing/portability-doctrine section"
grep -qi 'requirements' README.md || fail "README missing a Requirements section"
for l in '*:Zone.Identifier' '*.TMP' '.DS_Store' '*.swp' 'evals/results/' '.scratch/'; do
  grep -qxF "$l" .gitignore || fail ".gitignore missing exact line: $l"
done
[ -f skills/.gitkeep ] || fail "skills/.gitkeep missing"
[ ! -f CLAUDE.md ] || fail "root CLAUDE.md present (verified --strict failure)"
[ ! -f AGENTS.md ] || fail "root AGENTS.md present (banned by D1)"
[ ! -f /home/jjrdar/repos/jrit/jrit-loop-seam0-findings.md ] || fail "seam-0 findings not moved out of ~/repos/jrit"
f=docs/2026-09-13.seam0-native-primitive-findings.md
[ -f "$f" ] || fail "findings doc missing at $f"
for p in background-dispatch agent-view goal loop hooks auto-memory skill-frontmatter plugin-root validate eval marketplace agents-md; do
  grep -qE "^- \*\*$p\*\*: (EXISTS|PARTIAL|DOES-NOT-EXIST) " "$f" || fail "findings verdict line missing for: $p"
done
if find . -path ./.git -prune -o -type l -print | grep -q .; then fail "symlink present in the tree"; fi
if grep -rlP '\x{2014}' --include='*.md' .; then fail "em dash character found in a markdown file"; fi
claude plugin validate --strict . || fail "claude plugin validate --strict . failed (marketplace manifest)"
claude plugin validate --strict .claude-plugin/plugin.json || fail "claude plugin validate --strict plugin.json failed"
echo "PASS: u02-skeleton"
