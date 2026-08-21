#!/usr/bin/env bash
# Structural check for config/repo-state.md and the repo CLAUDE.md pointer.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
CFG="$REPO/config/repo-state.md"
TPL="$REPO/config/repo-state.template.md"
CONV="$REPO/config/conventions.md"
CONVTPL="$REPO/config/conventions.template.md"
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
# scope rule: the active stream and elevation limits are declared, in the doctrine doc
grep -Eqi '## *Scope rule' "$CONV" || fail "conventions.md missing the Scope rule section"
grep -q 'ROADMAP.md'           "$CFG" || fail "roadmap home not declared"
grep -q 'ISSUES.md'            "$CFG" || fail "ISSUES.md mirror not declared"
grep -q 'BACKLOG.md'           "$CFG" || fail "BACKLOG.md mirror not declared"
grep -q 'docs/chain-state.md'  "$CFG" || fail "chain-state home not declared (C consumes this)"
grep -q 'docs/reviews/'        "$CFG" || fail "batch-review home not declared (C consumes this)"
grep -q 'docs/handoffs/'       "$CFG" || fail "handoff home not declared"
grep -q 'scripts/gen-mirrors.sh' "$CFG" || fail "mirror regen command not declared"
# tracker: key is a line-anchored declared choice in this repo's config
grep -q '^tracker:' "$CFG" || fail "config/repo-state.md missing the line-anchored tracker: key"
# template carries the Local tracker section and both disclosed limitations (source for local renders)
grep -Eqi '## *Local tracker' "$TPL" || fail "template missing the Local tracker section"
grep -qi 'cross-repo idea search' "$TPL" || fail "template missing the cross-repo-search disclosure"
grep -qi 'wayfinder requires' "$TPL"     || fail "template missing the wayfinder-requires-github disclosure"
grep -qi 'single linear writer' "$TPL"   || fail "template missing the single-linear-writer numbering disclosure"
# "where I left off" degrades to git, not to nothing
grep -Eqi 'git (log|status)' "$CONV" || fail "Handoffs lane missing the git fallback for 'where I left off'"
grep -qi 'idea'                "$CONV" || fail "the 'idea' backlog label not documented"
grep -Eqi '## *Archive and graduation' "$CONV" || fail "archive/graduation rules section missing"
grep -qi 'Source brief:'       "$CONV" || fail "graduated-item issue template (Source brief/Restart) missing"
[ -f "$CLAUDEMD" ] || fail "repo CLAUDE.md missing"
grep -q 'config/repo-state.md' "$CLAUDEMD" || fail "CLAUDE.md pointer to config/repo-state.md missing"
echo "PASS: config/repo-state.md and CLAUDE.md pointer complete"
