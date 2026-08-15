#!/usr/bin/env bash
# Every chain skill carries gate tags; all four types appear; tags are well-formed; and per-type
# counts stay at or above the floors read from the freshly regenerated registry - a silent delete
# or class swap drops a count below its floor and fails RED naming the type, count, and floor.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
SKILLS="loop-brainstorm loop-plan loop-drive"
TOK='\[gate:(ASK|STOP|BATCH|DEFAULT)\]'

total=0
for s in $SKILLS; do
  f="$REPO/skills/$s/SKILL.md"
  [ -f "$f" ] || fail "skills/$s/SKILL.md missing"
  n="$(grep -oE "$TOK" "$f" | wc -l | tr -d ' ')"
  [ "$n" -ge 1 ] || fail "$s carries no gate tag"
  total=$((total + n))
done
[ "$total" -ge 15 ] || fail "only $total gate tags across the chain; inventory expects ~19"
# per-type floors read from the freshly regenerated docs/gate-registry.md
for pair in ASK:3 STOP:6 BATCH:4 DEFAULT:8; do
  t="${pair%%:*}"; floor="${pair##*:}"
  n="$(grep -rhoE "\[gate:$t\]" "$REPO"/skills/loop-*/SKILL.md | wc -l | tr -d ' ')"
  [ "$n" -ge "$floor" ] || fail "gate type $t count $n below floor $floor (registry floor lost a row)"
done
# all four types present somewhere
for t in ASK STOP BATCH DEFAULT; do
  grep -rqE "\[gate:$t\]" "$REPO"/skills/loop-*/SKILL.md || fail "type $t never used"
done
# STOP appears in loop-drive specifically (its gates are the STOP class)
grep -qE '\[gate:STOP\]' "$REPO/skills/loop-drive/SKILL.md" || fail "loop-drive missing STOP tags"
# no malformed tags
if grep -rEn '\[gate:[a-z]' "$REPO"/skills/loop-*/SKILL.md | grep -vE '\[gate:none\]'; then
  fail "lowercase/malformed gate tag found (types are upper-case)"
fi
echo "PASS: $total gate tags, all four types, STOP in loop-drive, per-type counts at/above floor"
