#!/usr/bin/env bash
# This repo's live state exists: mirrors present + disclosed, roadmap present, idea issues queryable,
# and the cross-repo backlog command is checked advisorily.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }

[ -f "$REPO/ISSUES.md" ]      || fail "ISSUES.md not stood up"
[ -f "$REPO/BACKLOG.md" ]     || fail "BACKLOG.md not stood up"
[ -f "$REPO/docs/roadmap.md" ] || fail "docs/roadmap.md not seeded"
grep -qi 'DO NOT EDIT' "$REPO/ISSUES.md"  || fail "ISSUES.md not a disclosed mirror"
grep -qi 'DO NOT EDIT' "$REPO/BACKLOG.md" || fail "BACKLOG.md not a disclosed mirror"

# at least one idea issue exists on this repo (index-free path - the hard gate)
N="$(gh issue list --label idea --state open --json number --jq 'length' 2>/dev/null)" \
  || fail "gh issue list failed (auth or remote?)"
[ "${N:-0}" -ge 1 ] || fail "no open 'idea' issues on this repo - live parked items not graduated"

# cross-repo backlog command is ADVISORY, not a hard gate: the brief marks gh-search-over-private-repos
# a guess, and the search index lags issue creation by seconds-to-minutes. Warn on miss, never fail.
if gh search issues --owner jroethel --label idea --state open --json repository \
     --jq '.[].repository.name' 2>/dev/null | grep -q 'loop-stack-session'; then
  echo "note: cross-repo 'gh search issues' resolves this repo's idea issues"
else
  echo "WARNING: cross-repo 'gh search issues' did not return this repo (private-repo indexing or lag)."
  echo "         Fallback documented in config/repo-state.md: per-repo 'gh issue list --label idea'."
fi
echo "PASS: live mirrors, roadmap, and idea issues resolve (cross-repo view advisory)"
