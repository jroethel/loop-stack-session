#!/usr/bin/env bash
# board.sh - Obsidian board front door. `discover` walks the scan roots and emits the
# Discovery TSV (9 tab-separated fields per included repo) plus per-root skip comments on
# stderr; a bare invocation wires the full pipeline discover | board-cards.sh | board-render-obsidian.sh.
# Git signals are local only - this script never runs git fetch.
set -uo pipefail
fail() { echo "board: $1" >&2; exit 1; }

ROOTS="${LOOP_BOARD_ROOTS:-$HOME/create $HOME/projects $HOME/repos}"
OWNER="${LOOP_BOARD_OWNER:-jroethel}"
NL='
'

find_repos() {              # one scan root -> absolute repo paths, one per line
  local g
  [ -d "$1" ] || return 0
  while IFS= read -r g; do
    [ -n "$g" ] || continue
    (cd "$(dirname "$g")" && pwd) 2>/dev/null
  done < <(find "$1" -maxdepth 3 -name .git -type d 2>/dev/null)
}

owner_of() {                # origin owner from https or ssh-scp URLs, empty when no origin
  local url
  url="$(git -C "$1" remote get-url origin 2>/dev/null)" || return 0
  printf '%s\n' "$url" | sed -E 's#^[a-zA-Z]+://##; s#^[^@/]*@##; s#^[^/:]+[:/]##; s#/.*$##'
}

repo_row() {                # one repo -> its TSV row on stdout, or nothing when excluded
  local repo="$1" key="$2" root="$3"
  local conforming=no epoch unc ahead=-1 behind="" owner
  [ -f "$repo/config/repo-state.md" ] && conforming=yes
  owner="$(owner_of "$repo")"
  epoch="$(git -C "$repo" log -1 --format=%ct 2>/dev/null)"
  [ -n "$epoch" ] || epoch=0
  unc="$(git -C "$repo" status --porcelain 2>/dev/null | grep -c .)"
  if git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    ahead="$(git -C "$repo" rev-list --count '@{u}..HEAD' 2>/dev/null)"
    [ -n "$ahead" ] || ahead=0
    local bn fe
    bn="$(git -C "$repo" rev-list --count 'HEAD..@{u}' 2>/dev/null)"
    [ -n "$bn" ] || bn=0
    fe="$(stat -f %m "$repo/.git/FETCH_HEAD" 2>/dev/null)"
    [ -n "$fe" ] || fe=0
    behind="$bn:$fe"
  fi
  [ "$conforming" = yes ] || [ "$owner" = "$OWNER" ] \
    || [ "$unc" -gt 0 ] || [ "$ahead" -gt 0 ] || return 0
  printf '%s\t%s\t%s\t%s\tyes\t%s\t%s\t%s\t%s\n' \
    "$repo" "$key" "$root" "$conforming" "$epoch" "$unc" "$ahead" "$behind"
}

cmd_discover() {
  local root repo parent key d seen="$NL" repos skipped
  for root in $ROOTS; do
    if [ ! -d "$root" ]; then
      echo "# board: scan root not found: $root" >&2
      continue
    fi
    parent="$(cd "$root/.." && pwd)"
    repos="$NL"
    while IFS= read -r repo; do
      [ -n "$repo" ] || continue
      fn_seen "$seen" "$repo" && continue                 # already emitted under an earlier root
      seen="$seen$repo$NL"
      repos="$repos$repo$NL"
      key="${repo#$parent/}"                              # $HOME-relative for the default roots
      [ "$key" != "$repo" ] || key="${repo#$HOME/}"
      repo_row "$repo" "$key" "$root"
    done < <(find_repos "$root")
    skipped=0
    while IFS= read -r d; do
      [ -n "$d" ] || continue
      [ "${d##*/}" = .git ] && continue
      fn_seen "$repos" "$d" && continue                   # a repo root itself
      skipped=$((skipped + 1))
    done < <(find "$root" -mindepth 1 -maxdepth 2 -type d 2>/dev/null)
    echo "# skipped: $skipped non-git dirs under $root" >&2
  done
}

fn_seen() { case "$NL$1" in *"$NL$2$NL"*) return 0 ;; *) return 1 ;; esac; }

cmd_pipeline() {
  [ -n "${LOOP_BOARD_HOME:-}" ] || fail "LOOP_BOARD_HOME is required for a rendering run"
  if [ -z "${LOOP_BOARD_CSS:-}" ] \
    && grep -qiE 'css[ -]needed:[[:space:]]*yes' \
      docs/spikes/2026-09-02.I52.board-bases-spike-findings.md 2>/dev/null; then
    LOOP_BOARD_CSS=1
  fi
  local skips
  skips="$(mktemp)" || fail "cannot create a temp file for the skip counts"
  trap 'rm -f "$skips"' EXIT
  export LOOP_BOARD_CSS
  cmd_discover 2>"$skips" \
    | scripts/board-cards.sh \
    | scripts/board-render-obsidian.sh "$LOOP_BOARD_HOME" "${LOOP_BOARD_CORTEX:-}" "$skips"
}

case "${1:-}" in
  discover) cmd_discover ;;
  "")       cmd_pipeline ;;
  *)        fail "usage: board.sh [discover] - bare invocation runs the full render pipeline" ;;
esac
