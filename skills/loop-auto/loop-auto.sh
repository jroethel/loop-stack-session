#!/usr/bin/env bash
# /loop-auto knob: read/write the chain-state autonomy mode and preflight the tree.
# Operates on the caller's cwd repo - never on the repo this script lives in.
set -uo pipefail
fail() { echo "loop-auto: $1" >&2; exit 1; }

CS="docs/chain-state.md"
RS="config/repo-state.md"
valid_mode() { case "$1" in pause|auto) return 0;; *) return 1;; esac; }

# Read the committed per-repo default from config/repo-state.md (line-anchored at
# ^autonomy-default:), or echo 'pause' when no such line is present.
repo_default() {
  [ -f "$RS" ] || { echo "pause"; return; }
  local v
  v="$(grep -E '^autonomy-default:' "$RS" | head -1 | sed -E 's/^autonomy-default:[[:space:]]*//; s/[[:space:]]*$//')"
  [ -n "$v" ] && echo "$v" || echo "pause"
}

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

# Effective mode for script consumers: the runtime chain-state value if present,
# else the committed repo default, else 'pause'. Prints a bare single word.
cmd_get() {
  if [ -f "$CS" ]; then
    local v
    v="$(grep -Ei '^autonomy:' "$CS" | head -1 | sed -E 's/^[Aa]utonomy:[[:space:]]*//; s/[[:space:]]*$//')"
    [ -n "$v" ] && echo "$v" || repo_default
  else
    repo_default
  fi
}

# Human-facing: the effective mode AND its source.
cmd_status() {
  if [ -f "$CS" ]; then
    local v
    v="$(grep -Ei '^autonomy:' "$CS" | head -1 | sed -E 's/^[Aa]utonomy:[[:space:]]*//; s/[[:space:]]*$//')"
    if [ -n "$v" ]; then
      echo "mode: $v (session)"
      return
    fi
  fi
  local d; d="$(repo_default)"
  if [ "$d" = "pause" ]; then
    echo "mode: pause (unset)"
  else
    echo "mode: $d (repo default)"
  fi
}

cmd_default() {
  local sub="$1"; shift
  case "$sub" in
    get) repo_default ;;
    set)
      [ $# -ge 1 ] || fail "default set: requires a mode ('pause' or 'auto')"
      local mode="$1"
      valid_mode "$mode" || fail "default set: mode must be 'pause' or 'auto' (got '$mode')"
      mkdir -p "$(dirname "$RS")"
      touch "$RS"
      grep -v '^autonomy-default:' "$RS" > "${RS}.tmp" || true
      printf 'autonomy-default: %s\n' "$mode" >> "${RS}.tmp"
      mv "${RS}.tmp" "$RS"
      # ponytail: one printf, not four echoes - a single stdout write survives an
      # early-closing downstream consumer (e.g. `| grep -q`) without SIGPIPE,
      # which matters under the test shell's `set -o pipefail`.
      printf '%s\ngit add config/repo-state.md\ngit commit -m "loop-auto: default %s"\n' "$mode" "$mode"
      ;;
    clear)
      if [ -f "$RS" ]; then
        grep -v '^autonomy-default:' "$RS" > "${RS}.tmp" || true
        mv "${RS}.tmp" "$RS"
      fi
      echo "pause"
      ;;
    *) fail "default: subcommand must be 'get', 'set <pause|auto>', or 'clear'" ;;
  esac
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

usage() { echo "Usage: loop-auto.sh {set <pause|auto>|get|status|default <get|set <pause|auto>|clear>|preflight <mode>}" >&2; }

[ $# -ge 1 ] || { usage; exit 1; }
sub="$1"; shift
case "$sub" in
  set)       [ $# -ge 1 ] || { usage; exit 1; }; cmd_set "$1" ;;
  get)       cmd_get ;;
  status)    cmd_status ;;
  default)   [ $# -ge 1 ] || { usage; exit 1; }; cmd_default "$@" ;;
  preflight) [ $# -ge 1 ] || { usage; exit 1; }; valid_mode "$1" || fail "preflight: mode must be 'pause' or 'auto'"; cmd_preflight ;;
  *)         usage; exit 1 ;;
esac
