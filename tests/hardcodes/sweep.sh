#!/usr/bin/env bash
# sweep.sh - host-specific literals may live ONLY in the parameter home and historical records.
# Greps the tracked + untracked (non-ignored) tree; PASSES iff every hit is under an allowlisted prefix.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"   # tests/hardcodes/ -> repo root (TWO levels up)

# Host-specific literals: this owner's absolute home paths on either OS, plus the ringer-root
# convention literal named in the brief's criterion 5. The absolute ringer engine-bin literals
# live under the home prefixes, so they are covered too. Portable CODE forms ("$HOME/...") are NOT
# matched - they resolve per host and are not hardcodes.
PATTERN='/Users/jjrdar|/home/jjrdar|~/repos/ringer'

# EXPLICIT allowlist of path prefixes where these literals are legitimately kept.
# The living-doc prefixes (docs/plans|briefs|memos and the root record files) are allowed BY DESIGN
# as historical-record paths: a literal newly authored into one of them is NOT caught. This is a
# deliberate limitation - narrow these to dated-file globs later if that ever becomes a real path.
ALLOW=(
  tests/hardcodes/                     # this sweep names the literals it hunts, so it matches itself
  config/host.env                      # the parameter home (gitignored)
  config/host.env.template             # ships the ~/repos/ringer convention default
  install.sh                           # the installer's portable fallback + doctor strings
  README.md                            # documents the ~/repos/ringer default
  skills/                              # skill prose references the runtime ringer convention
  diagrams/                            # conversation-evolution diagrams narrate the historical ~/repos/ringer explore
  docs/archive/
  docs/handoffs/
  docs/reviews/
  docs/briefs/
  docs/plans/
  docs/memos/
  docs/molt-ledger.md
  conversation-archive.md
  fixing-agent-errors.md
  model-routing-ringer-notes.local.md
  model-routing-ringer-notes.remote.md
  PLAN.md
)
allowed() {
  local f="$1" p
  for p in "${ALLOW[@]}"; do
    case "$f" in "$p"*) return 0 ;; esac
  done
  return 1
}

cd "$REPO"
# A check that cannot tell "no hits" from "grep never ran" is a false-green generator: require a work tree.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || { echo "FAIL: not a git work tree - sweep cannot run" >&2; exit 1; }
bad=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  allowed "$f" || { echo "HARDCODE outside allowlist: $f"; bad=$((bad + 1)); }
done < <(git grep --untracked -lE "$PATTERN" -- . 2>/dev/null)

if [ "$bad" -gt 0 ]; then
  echo "FAIL: $bad file(s) hold host-specific literals outside the parameter home / historical records"
  exit 1
fi
echo "PASS: no host-specific literals outside the allowlist"
