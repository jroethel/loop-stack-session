#!/usr/bin/env bash
# handoff is location-aware: names the in-repo home for conforming repos AND the in-project fallback.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SKILL="$REPO/skills/handoff/SKILL.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$SKILL" ] || fail "skills/handoff/SKILL.md missing (not moved into the repo)"
grep -q  '^name: handoff'      "$SKILL" || fail "frontmatter name is not handoff"
grep -q  'config/repo-state.md' "$SKILL" || fail "handoff does not consult config/repo-state.md for its location"
grep -q  'docs/handoffs'       "$SKILL" || fail "handoff does not name the in-repo handoffs home"
grep -qi 'temp'               "$SKILL" && fail "handoff still names the OS-temp-dir fallback (must land in-project)"
grep -qi 'non-conforming\|created on demand\|create .*docs/handoffs' "$SKILL" || fail "handoff does not name the in-project fallback for a repo without config/repo-state.md"
grep -q  'scripts/gen-mirrors.sh' "$SKILL" || fail "handoff does not refresh mirrors in the same pass"
grep -qi 'suggested skills'    "$SKILL" || fail "handoff lost its suggested-skills section"
grep -qi 'redact'             "$SKILL" || fail "handoff lost its secret-redaction rule"
echo "PASS: handoff is location-aware, mirror-refreshing, and kept its content rules"
