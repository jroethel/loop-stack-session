#!/usr/bin/env bash
# board-render-obsidian.sh - read the Card TSV (stdin, 12 fields, board-cards.sh's contract) and
# write the board directory under LOOP_BOARD_HOME: one note per card, a _health.md note, and the
# two .base views seeded from the committed templates only when absent. Every note is staged in
# <home>/.staging and swapped in as a set, so a rejected or dying render leaves the prior board
# intact and no card note is deleted before its replacement exists. The one sanctioned write
# outside the board home is the CSS snippet (LOOP_BOARD_CSS=1, create-if-absent, never refreshed).
# macOS stock bash 3.2: no associative arrays, no ${var,,}, no grep -P.
set -uo pipefail
US=$'\037'                  # unit separator: non-whitespace, so empty Card TSV fields survive `read`
NL='
'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"    # templates live beside the script, not the cwd
ASSETS="$SCRIPT_DIR/../assets/board"

fail() { echo "board: $*" >&2; exit 1; }

# board.sh passes home/cortex/skips as arguments; a bare run takes them from the environment
home="${1:-${LOOP_BOARD_HOME:-}}"
cortex="${2:-${LOOP_BOARD_CORTEX:-}}"
skips="${3:-}"
[ -n "$home" ] || fail "LOOP_BOARD_HOME is required (the board directory under LOOP_BOARD_CORTEX)"
[ -n "$cortex" ] || fail "LOOP_BOARD_CORTEX is required to scope LOOP_BOARD_HOME"
cortex="${cortex%/}"
[ -n "$cortex" ] || fail "LOOP_BOARD_CORTEX is required to scope LOOP_BOARD_HOME"

# canonicalize both paths before the containment check: a raw string-prefix compare on the
# unresolved values is defeated by a `..` segment that resolves outside LOOP_BOARD_CORTEX
mkdir -p "$home" || fail "cannot create LOOP_BOARD_HOME ($home)"
cortex="$(cd "$cortex" 2>/dev/null && pwd -P)" || fail "LOOP_BOARD_CORTEX does not resolve to a real directory"
home="$(cd "$home" 2>/dev/null && pwd -P)" || fail "LOOP_BOARD_HOME does not resolve to a real directory"
case "$home" in
  "$cortex") ;;
  "$cortex"/*) ;;
  *) fail "LOOP_BOARD_HOME ($home) is not under LOOP_BOARD_CORTEX ($cortex)" ;;
esac

fmt_epoch() {              # epoch -> strftime output; BSD date first, GNU date fallback
  date -u -r "$1" "$2" 2>/dev/null || date -u -d "@$1" "$2" 2>/dev/null || :
}

fm_free() {                # free-text frontmatter value: quoted, so a title with ": " cannot break YAML
  if [ -n "$2" ]; then
    printf '%s "%s"\n' "$1" "$(printf '%s' "$2" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  else
    printf '%s\n' "$1"
  fi
}

band_emoji() {             # staleness band -> colored dot on the body H1 (spike: Bases has no CSS hook)
  case "$1" in
    1) echo "🟢" ;;
    2) echo "🟡" ;;
    3) echo "🟠" ;;
    4) echo "🔴" ;;
    *) echo "" ;;
  esac
}

entry_point() {            # column source position repo_key -> resume entry, first match wins
  [ "$1" = done ] && { echo "archive or close"; return 0; }
  [ "$1" = blocked-on-you ] && { echo "answer the needs-input, then /loop-drive"; return 0; }
  if [ "$2" = git ] && [ -n "$3" ] && [ "$3" != clean ]; then
    echo "review and commit, then /loop-drive"; return 0
  fi
  local p
  for p in "$HOME/$4"/docs/plans/*.md; do
    [ -f "$p" ] && { echo "/loop-drive"; return 0; }
  done
  echo "/loop-plan"
}

fn_seen() { case "$NL$1" in *"$NL$2$NL"*) return 0 ;; *) return 1 ;; esac; }

is_card_note() {           # true when the file's frontmatter block carries board_card: true
  awk '
    NR == 1 { if ($0 != "---") exit 1; next }
    $0 == "---" { exit found ? 0 : 1 }
    /^board_card:[ \t]*true[ \t]*$/ { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$1" 2>/dev/null
}

# Reject a malformed row before any write, and hand the render loop US-joined fields (a tab IFS
# would collapse the empty position/behind fields mid-row; US is non-whitespace so they survive).
input="$(cat)" || fail "cannot read the Card TSV from stdin"
cards="$(printf '%s\n' "$input" | awk -F'\t' -v us="$US" '
    NF == 0 || $1 ~ /^#/ { next }
    NF != 12 { printf "row %d carries %d fields, expected 12\n", NR, NF | "cat 1>&2"; exit 3 }
    { for (i = 1; i <= 12; i++) printf "%s%s", $i, us; printf "\n" }
  ')" || fail "rejecting the Card TSV: a row does not have exactly 12 fields; no writes made"

# a render that dies mid-staging must not leave stray card notes inside the board home
trap '[ -e "$home/.staging" ] && rm -rf "$home/.staging" || true' EXIT

stamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
keep="$NL" tracker_seen="$NL" tracker_report="$NL" git_ok=0 git_deg=0
rm -rf "$home/.staging"
mkdir -p "$home/.staging" || fail "cannot stage into $home/.staging"

while IFS= read -r row; do
  [ -n "$row" ] || continue
  IFS="$US" read -r -a f <<< "$row"
  card_id="${f[0]:-}"; repo="${f[1]:-}"; source="${f[2]:-}"; column="${f[3]:-}"
  title="${f[4]:-}"; token="${f[5]:-}"; band="${f[6]:-}"; last_work="${f[7]:-}"
  pos="${f[8]:-}"; behind="${f[9]:-}"; health="${f[10]:-}"; epoch="${f[11]:-}"

  asof="$(fmt_epoch "${epoch:-0}" '+%Y-%m-%dT%H:%M:%SZ')"
  [ -n "$asof" ] || asof="$stamp"
  if [ "$source" = tracker ]; then
    fn_seen "$tracker_seen" "$repo" || {
      tracker_seen="$tracker_seen$repo$NL"; tracker_report="$tracker_report$repo: $health$NL"
    }
  elif [ "$source" = git ]; then
    if [ "$health" = degraded ]; then git_deg=$((git_deg + 1)); else git_ok=$((git_ok + 1)); fi
  fi

  name="${card_id//\//-}"; name="${name//#/-}"; name="$name.md"
  keep="$keep$name$NL"
  emoji="$(band_emoji "$band")"
  h1="$title"; [ -n "$emoji" ] && h1="$emoji $title"
  {
    printf -- '---\n'
    printf 'board_card: true\n'
    printf 'repo: %s\n' "$repo"
    printf 'source: %s\n' "$source"
    printf 'column: %s\n' "$column"
    fm_free 'token:' "$token"
    printf 'staleness: %s\n' "$band"
    printf 'last_work: %s\n' "$last_work"
    fm_free 'position:' "$pos"
    fm_free 'behind:' "$behind"
    printf 'health: %s\n' "$health"
    printf 'render_asof: %s\n' "$asof"
    fm_free 'title:' "$title"
    printf -- '---\n\n'
    printf '# %s\n\n' "$h1"
    printf '**Column:** %s\n' "$column"
    printf '**Last work:** %s\n\n' "$last_work"
    printf 'Staleness: band %s\n' "$band"
    [ -n "$pos" ] && printf 'Position: %s\n' "$pos"
    [ -n "$behind" ] && printf 'Behind: %s\n' "$behind"
    printf '\nAs of: %s\n\n' "$asof"
    printf '```\n'
    printf 'Resume: %s  %s\n' "$repo" "${token:-$title}"
    printf 'State: %s | %s | last work %s (band %s)\n' "$column" "${pos:-clean}" "$last_work" "$band"
    [ -n "$behind" ] && printf '%s\n' "$behind"
    printf 'Entry: %s\n' "$(entry_point "$column" "$source" "$pos" "$repo")"
    printf 'Next: cd %s && git log --oneline -5 && git status ; read config/context-map.md\n' "$HOME/$repo"
    printf '```\n'
  } > "$home/.staging/$name" || fail "cannot write the staged note for $card_id"
done <<< "$cards"

{
  printf '# Board health\n\n'
  printf 'Rendered: %s\n\n' "$stamp"
  printf '## Tracker (per conforming repo)\n'
  if [ "$tracker_report" != "$NL" ]; then
    while IFS= read -r l; do printf -- '- %s\n' "$l"; done <<< "$tracker_report"
  else
    printf 'no tracker cards this render\n'
  fi
  printf '\n## Git working trees\n'
  printf 'ok: %d, degraded: %d\n\n' "$git_ok" "$git_deg"
  printf '## Non-git dirs skipped by discovery\n'
  if ! grep '^# skipped:' "$skips" 2>/dev/null | sed 's/^# /- /'; then
    printf 'none reported\n'
  fi
  if [ "${LOOP_BOARD_CSS:-}" = 1 ]; then
    printf '\n## CSS snippet\n'
    printf 'One-time: enable `loop-board` under Settings > Appearance > CSS snippets.\n'
  fi
} > "$home/.staging/_health.md" || fail "cannot write the staged health note"

for v in by-lane by-repo; do
  [ -f "$home/$v.base" ] || cp "$ASSETS/$v.base" "$home/$v.base" \
    || fail "cannot seed $v.base from $ASSETS"
done

for p in "$home/.staging"/*; do                 # swap the whole set in, then prune orphans
  [ -e "$p" ] || continue
  mv "$p" "$home/" || fail "cannot move ${p##*/} into $home"
done
for p in "$home"/*.md; do
  [ -f "$p" ] || continue
  is_card_note "$p" || continue
  fn_seen "$keep" "${p##*/}" || rm "$p"
done
rm -rf "$home/.staging"

if [ "${LOOP_BOARD_CSS:-}" = 1 ]; then           # the one write outside the board home, once ever
  snip="$cortex/.obsidian/snippets/loop-board.css"
  if [ ! -f "$snip" ]; then
    mkdir -p "$(dirname "$snip")" || fail "cannot create $(dirname "$snip")"
    cp "$ASSETS/loop-board.css" "$snip" || fail "cannot write the CSS snippet once"
  fi
fi
