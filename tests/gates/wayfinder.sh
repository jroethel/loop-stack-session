#!/usr/bin/env bash
# Wayfinder is ported to loop-stack conventions and its labels are excluded from the mirrors.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
W="$REPO/skills/wayfinder/SKILL.md"
M="$REPO/scripts/gen-mirrors.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$W" ] || fail "skills/wayfinder/SKILL.md missing"
grep -q '^name: wayfinder' "$W" || fail "frontmatter name is not wayfinder"
# Labels layered on the lane scheme.
grep -q 'wayfinder:map' "$W" || fail "no wayfinder:map label"
grep -Eq 'wayfinder:(research|grilling|task|prototype)' "$W" || fail "no wayfinder ticket-type labels"
# Routing hand-off to loop-plan; per-ticket routing via the evidence chain.
grep -qi 'loop-plan' "$W" || fail "no routing hand-off to loop-plan"
grep -qi 'loop-brainstorm' "$W" || fail "grilling tickets not remapped to loop-brainstorm"
# Uninstalled Matt-only skill references are gone.
for bad in 'setup-matt-pocock-skills' '/grilling' '/domain-modeling' '/prototype'; do
  grep -q "$bad" "$W" && fail "wayfinder still references uninstalled '$bad'"
done
# Mirror exclusion: a wayfinder-labeled issue never appears in either mirror.
TMPW="$(mktemp -d)"; trap 'rm -rf "$TMPW"' EXIT
cat > "$TMPW/issues.json" <<'EOF'
[{"number":91,"title":"Map: pick storage","labels":[{"name":"wayfinder:map"}],"updatedAt":"2026-08-02T00:00:00Z"},
 {"number":92,"title":"A real backlog idea","labels":[{"name":"idea"}],"updatedAt":"2026-08-02T00:00:00Z"},
 {"number":93,"title":"A plain issue","labels":[],"updatedAt":"2026-08-02T00:00:00Z"}]
EOF
( cd "$TMPW" && MIRRORS_JSON_FILE="$TMPW/issues.json" bash "$M" "$TMPW" ) || fail "gen-mirrors failed on fixture"
# Anchor to the table-row form so a tmpdir path containing 91/92/93 in the header cannot false-match.
grep -Eq '^\| *91 *\|' "$TMPW/ISSUES.md" "$TMPW/BACKLOG.md" && fail "wayfinder:map issue leaked into a mirror"
grep -Eq '^\| *92 *\|' "$TMPW/BACKLOG.md" || fail "idea issue missing from BACKLOG.md (exclusion over-reached)"
grep -Eq '^\| *93 *\|' "$TMPW/ISSUES.md" || fail "plain issue missing from ISSUES.md (exclusion over-reached)"
echo "PASS: wayfinder ported, hand-off wired, wayfinder:* excluded from mirrors, idea/plain lanes intact"
