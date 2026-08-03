#!/usr/bin/env bash
# loop-which frontmatter description is trimmed but still triggers on the core intent.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
S="$REPO/skills/loop-which/SKILL.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$S" ] || fail "loop-which SKILL missing"
# Extract the frontmatter, then drop the name: line so 'which' in the skill name can't vacuously pass.
fm="$(awk 'NR==1&&/^---$/{f=1;next} f&&/^---$/{exit} f' "$S")"
desc="$(printf '%s\n' "$fm" | grep -v '^name:')"
words="$(printf '%s' "$desc" | wc -w | tr -d ' ')"
[ "$words" -le 75 ] || fail "description still $words words; trim to <= 75"
# Concrete verdict names survive the trim (not the vacuous skill-name match).
echo "$desc" | grep -Eqi 'one agent'            || fail "trimmed description dropped the ONE AGENT verdict"
echo "$desc" | grep -Eqi 'team'                 || fail "trimmed description dropped the AGENT TEAM verdict"
echo "$desc" | grep -Eqi "don.?t bother|not worth" || fail "trimmed description dropped the DON'T BOTHER verdict"
# A core routing trigger survives.
echo "$desc" | grep -Eqi 'which approach|how to proceed|route' || fail "trimmed description lost its routing trigger"
# Body is intact.
grep -qi 'One-Minute Test' "$S" || fail "loop-which body damaged (lost One-Minute Test)"
echo "PASS: loop-which description trimmed to $words words, verdicts + trigger + body intact"
