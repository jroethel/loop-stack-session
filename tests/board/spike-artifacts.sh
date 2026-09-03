#!/usr/bin/env bash
# The spike leaves two committed .base view templates that parse as YAML, filter on the board_card
# marker, and a findings note that records a CSS-needed verdict. Portable to macOS bash 3.2 / BSD grep.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
for f in assets/board/by-lane.base assets/board/by-repo.base; do
  [ -f "$REPO/$f" ] || fail "$f missing"
  grep -q 'board_card' "$REPO/$f" || fail "$f does not filter on board_card"
  grep -qE '^views:' "$REPO/$f" || fail "$f has no views block"
  awk '/\t/{exit 1}' "$REPO/$f" || fail "$f contains a tab (YAML must be spaces)"   # portable, no grep -P
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import sys,yaml; yaml.safe_load(open('$REPO/$f'))" 2>/dev/null || fail "$f is not valid YAML"
  fi
done
notes="$REPO/docs/spikes/2026-09-02.I52.board-bases-spike-findings.md"
[ -f "$notes" ] || fail "spike findings note missing"
grep -qiE 'css[ -]needed:[[:space:]]*(yes|no)' "$notes" || fail "findings note lacks a CSS-needed verdict line"
echo "PASS: spike artifacts present, .base templates parse and filter on board_card, verdict recorded"
