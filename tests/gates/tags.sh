#!/usr/bin/env bash
# Every chain skill carries gate tags; all four types appear; tags are well-formed; and the diff is
# TAGS ONLY - stripping the tags from working tree and baseline yields byte-identical text.
# Run before committing so the baseline ref is the pre-edit skill text.
# TAGS_BASE_REF overrides the baseline (default HEAD).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
BASE="${TAGS_BASE_REF:-HEAD}"
fail() { echo "FAIL: $1" >&2; exit 1; }
SKILLS="loop-brainstorm loop-plan loop-drive loop-which"
TOK='\[gate:(ASK|STOP|BATCH|DEFAULT)\]'
strip_tags() { sed -E 's/`?\[gate:(ASK|STOP|BATCH|DEFAULT|none)\]`?//g'; }

total=0
for s in $SKILLS; do
  f="$REPO/skills/$s/SKILL.md"
  [ -f "$f" ] || fail "skills/$s/SKILL.md missing"
  n="$(grep -oE "$TOK" "$f" | wc -l | tr -d ' ')"
  [ "$n" -ge 1 ] || fail "$s carries no gate tag"
  total=$((total + n))
  # tags-only invariant: current file minus tags == baseline file minus tags
  if git -C "$REPO" cat-file -e "$BASE:skills/$s/SKILL.md" 2>/dev/null; then
    diff <(git -C "$REPO" show "$BASE:skills/$s/SKILL.md" | strip_tags) \
         <(strip_tags < "$f") >/dev/null \
      || fail "$s changed more than tags (prose differs after stripping gate tags) - tags-only violated"
  fi
done
[ "$total" -ge 15 ] || fail "only $total gate tags across the chain; inventory expects ~19"
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
echo "PASS: $total gate tags, all four types, STOP in loop-drive, diff is tags-only vs $BASE"
