#!/usr/bin/env bash
# tidy.sh - inventory UNTRACKED .scratch/ byproducts in the caller's cwd and offer per-item
# deletion. Never judges whether work is "merged"; the human decides each item.
# Honors LOOP_ASSUME_YES/NO. Reports nothing on a repo with no such byproducts.
set -uo pipefail
ask() {   # $1 = prompt; 0 = yes, 1 = no
  [ "${LOOP_ASSUME_YES:-0}" = 1 ] && return 0
  [ "${LOOP_ASSUME_NO:-0}"  = 1 ] && return 1
  local a; printf '%s [y/N]: ' "$1" >&2; read -r a || return 1
  case "$a" in [yY]*) return 0;; *) return 1;; esac
}
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
[ -d .scratch ] || exit 0
# -o lists untracked files; WITHOUT --exclude-standard it also includes gitignored scratch,
# which is exactly what a .scratch byproduct usually is.
while IFS= read -r f; do
  [ -n "$f" ] || continue
  echo "byproduct: $f"
  if ask "delete $f?"; then
    rm -f "$f" && echo "deleted $f"
  fi
done < <(git ls-files -o -- .scratch | sort)
