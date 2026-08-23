#!/usr/bin/env bash
# loop-track.sh - resolve a loop-setup'd repo and file one tracker issue in it.
# Usage: loop-track.sh <repo-path-or-name> <label> <title> <body>
#   <label> is "idea", "wayfinder:map", or "" (plain issue) - passed straight to tracker.sh create.
set -uo pipefail
fail() { echo "loop-track: $1" >&2; exit 1; }

[ $# -eq 4 ] || fail "usage: loop-track.sh <repo-path-or-name> <label> <title> <body>"
repo="$1"; label="$2"; title="$3"; body="$4"

# ponytail: repo-name search is a bounded find under $HOME, not a registry - fine at
# personal-machine scale; revisit if this ever needs to resolve across multiple hosts.
resolve_repo() {
  local r="$1" hits=() d
  if [ -d "$r" ]; then
    [ -f "$r/config/repo-state.md" ] || fail "not a loop-setup'd repo (no config/repo-state.md): $r"
    (cd "$r" && pwd)
    return
  fi
  while IFS= read -r d; do
    [ -f "$d/config/repo-state.md" ] && hits+=("$d")
  done < <(find "$HOME" -maxdepth 4 -type d -iname "$r" \
             -not -path '*/node_modules/*' -not -path '*/.git/*' \
             -not -path '/private/tmp/*' -not -path "$HOME/Library/*" 2>/dev/null)
  case "${#hits[@]}" in
    0) fail "no loop-setup'd repo named '$r' found under \$HOME - pass a path instead" ;;
    1) printf '%s\n' "${hits[0]}" ;;
    *) fail "multiple repos named '$r' found (${hits[*]}) - pass a path instead" ;;
  esac
}

target="$(resolve_repo "$repo")" || exit 1
num="$(cd "$target" && scripts/tracker.sh create --label "$label" --title "$title" --body "$body")" \
  || fail "tracker.sh create failed in $target"

kind="issue"
[ "$label" = "idea" ] && kind="idea"
[ "$label" = "wayfinder:map" ] && kind="wayfinder item"
printf 'Filed %s #%s in %s: %s\n' "$kind" "$num" "$(basename "$target")" "$title"
