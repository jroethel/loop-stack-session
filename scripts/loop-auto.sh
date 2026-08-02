#!/usr/bin/env bash
# /loop-auto knob: read/write the chain-state autonomy mode and preflight the tree.
# Operates on the caller's cwd repo - never on the repo this script lives in.
set -uo pipefail
fail() { echo "loop-auto: $1" >&2; exit 1; }

CS="docs/chain-state.md"
valid_mode() { case "$1" in pause|auto) return 0;; *) return 1;; esac; }

cmd_set() {
  local mode="$1"
  valid_mode "$mode" || fail "set: mode must be 'pause' or 'auto' (got '$mode')"
  mkdir -p "$(dirname "$CS")"
  cat > "$CS" <<EOF
autonomy: $mode
generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
  echo "$mode"
}

cmd_get() {
  if [ -f "$CS" ]; then
    grep -Ei '^autonomy:' "$CS" | head -1 | sed -E 's/^[Aa]utonomy:[[:space:]]*//; s/[[:space:]]*$//'
  else
    echo "pause"
  fi
}

cmd_preflight() {
  # STOP invariant: any uncommitted work halts, in either mode.
  # The chain-state file itself is excluded so `set` never trips its own guard.
  local dirty
  dirty="$(git status --porcelain -- . ':(exclude)docs/chain-state.md')"
  if [ -n "$dirty" ]; then
    echo "loop-auto: STOP - dirty working tree (excluding docs/chain-state.md):" >&2
    printf '%s\n' "$dirty" >&2
    return 1
  fi
  return 0
}

usage() { echo "Usage: loop-auto.sh {set <pause|auto>|get|preflight <mode>}" >&2; }

[ $# -ge 1 ] || { usage; exit 1; }
sub="$1"; shift
case "$sub" in
  set)       [ $# -ge 1 ] || { usage; exit 1; }; cmd_set "$1" ;;
  get)       cmd_get ;;
  preflight) [ $# -ge 1 ] || { usage; exit 1; }; valid_mode "$1" || fail "preflight: mode must be 'pause' or 'auto'"; cmd_preflight ;;
  *)         usage; exit 1 ;;
esac
