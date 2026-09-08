#!/usr/bin/env bash
# Render writes one note per card with correct frontmatter, seeds .base files only when absent,
# preserves user edits to an existing .base, writes a health note, survives a failed re-render
# without wiping the prior board (atomicity), and touches nothing outside the board home.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cortex="$tmp/Cortex"; home="$cortex/00_System/Board"; mkdir -p "$home"
outside="$cortex/20_Knowledge/keep.md"; mkdir -p "$(dirname "$outside")"; echo "do not touch" > "$outside"
outside_hash() { find "$cortex" -type f -not -path "$home/*" -exec shasum {} + | sort | shasum; }
run() { LOOP_BOARD_HOME="$home" LOOP_BOARD_CORTEX="$cortex" bash "$REPO/scripts/board-render-obsidian.sh"; }

now="$(date +%s)"
card() { printf '%s\tcreate/%s\t%s\t%s\t%s\t%s\t1\t2026-09-01\t%s\t%s\tok\t%s\t%s\n' \
  "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$now" "$9"; }
{
  card 'create/repoA#I52' repoA tracker in-session 'Board MVP' I52 '' '' ''
  card 'create/repoA#git' repoA git next-up 'repoA working tree' '' '2 uncommitted, +0 ahead' '' went-stale
  printf '#tracker\tcreate/repoZ\tok (no open issues)\n'   # conforming, zero tracker cards
} > "$tmp/cards.tsv"

before="$(outside_hash)"
run < "$tmp/cards.tsv" || fail "render exited non-zero"
n="$(grep -rl 'board_card: true' "$home" | grep -c .)"
[ "$n" -eq 2 ] || fail "expected 2 card notes, got $n"
grep -rq 'column: in-session' "$home" || fail "frontmatter column missing"
grep -rq 'Resume:' "$home" || fail "resume prompt block missing"
[ -f "$home/_health.md" ] || fail "health note missing"
grep -q 'create/repoZ: ok (no open issues)' "$home/_health.md" \
  || fail "a conforming repo with zero tracker cards is missing from the health note"
grep -q "First commands: cd $HOME/create/repoA " "$home/create-repoA-git.md" \
  || fail "the resume block's first-commands line does not resolve the repo key"
[ -f "$home/by-lane.base" ] || fail "by-lane.base not seeded"
[ -f "$home/Board.md" ] || fail "Board.md not seeded"

# user edits an existing .base; re-render must preserve it and must not touch outside files
echo "# user tweak" >> "$home/by-lane.base"
run < "$tmp/cards.tsv" || fail "re-render exited non-zero"
grep -q '# user tweak' "$home/by-lane.base" || fail "re-render clobbered the user .base edit"
[ "$(outside_hash)" = "$before" ] || fail "re-render altered a file outside the board home"

grep -q '^marker: went-stale$' "$home/create-repoA-git.md" || fail "the marker did not reach the card frontmatter"
grep -q '\[went-stale\]' "$home/create-repoA-git.md" || fail "the marker did not prefix the rendered title"
grep -q '^marker:' "$home/create-repoA-I52.md" || fail "an unmarked card still needs an explicit marker key"
grep -q '^title: .*\[' "$home/create-repoA-I52.md" && fail "an unmarked card must carry no marker prefix in its title"

# atomicity: a render fed a malformed (12-field, the pre-marker shape) row must exit non-zero and
# leave the prior board intact, never a wiped or half-built board.
printf 'a\tb\tc\td\te\tf\tg\th\ti\tj\tk\tl\n' > "$tmp/bad.tsv"
run < "$tmp/bad.tsv" && fail "render should reject a 12-field row now that the contract is 13"
[ "$(grep -rl 'board_card: true' "$home" | grep -c .)" -eq 2 ] || fail "failed render wiped the prior board"
echo "PASS: notes, frontmatter, marker, resume block, health note, .base preserved, atomic, outside untouched"
