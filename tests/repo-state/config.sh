#!/usr/bin/env bash
# Structural check for config/repo-state.md and the repo CLAUDE.md pointer.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
CFG="$REPO/config/repo-state.md"
TPL="$REPO/config/repo-state.template.md"
CLAUDEMD="$REPO/CLAUDE.md"
GI="$REPO/.gitignore"
fail() { echo "FAIL: $1" >&2; exit 1; }

[ -f "$TPL" ] || fail "config/repo-state.template.md missing (single schema source)"
[ -f "$CFG" ] || fail "config/repo-state.md missing"
# template and this repo's config carry the same lane set (drift guard)
for lane in Roadmap Issues Backlog Handoffs "Chain state" "Batch reviews" Archive; do
  grep -qi "$lane" "$TPL" || fail "template does not name the '$lane' lane"
  grep -qi "$lane" "$CFG" || fail "config/repo-state.md does not name the '$lane' lane"
done
# chain-state is gitignored runtime state
grep -q 'docs/chain-state.md' "$GI" || fail ".gitignore does not exclude docs/chain-state.md"
# "where I left off" degrades to git, not to nothing
grep -Eqi 'git (log|status)' "$CFG" || fail "Handoffs lane missing the git fallback for 'where I left off'"
grep -q 'docs/roadmap.md'      "$CFG" || fail "roadmap home not declared"
grep -q 'ISSUES.md'            "$CFG" || fail "ISSUES.md mirror not declared"
grep -q 'BACKLOG.md'           "$CFG" || fail "BACKLOG.md mirror not declared"
grep -q 'docs/chain-state.md'  "$CFG" || fail "chain-state home not declared (C consumes this)"
grep -q 'docs/reviews/'        "$CFG" || fail "batch-review home not declared (C consumes this)"
grep -q 'docs/handoffs/'       "$CFG" || fail "handoff home not declared"
grep -q 'scripts/gen-mirrors.sh' "$CFG" || fail "mirror regen command not declared"
grep -qi '## *Fallback'        "$CFG" || fail "no-remote fallback section missing"
grep -qi 'idea'                "$CFG" || fail "the 'idea' backlog label not documented"
grep -Eqi '## *Archive and graduation' "$CFG" || fail "archive/graduation rules section missing"
grep -qi 'Source brief:'       "$CFG" || fail "graduated-item issue template (Source brief/Restart) missing"
[ -f "$CLAUDEMD" ] || fail "repo CLAUDE.md missing"
grep -q 'config/repo-state.md' "$CLAUDEMD" || fail "CLAUDE.md pointer to config/repo-state.md missing"
echo "PASS: config/repo-state.md and CLAUDE.md pointer complete"
