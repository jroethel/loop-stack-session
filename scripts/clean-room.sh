#!/usr/bin/env bash
# clean-room.sh - prove loop-stack installs and its suite passes in a dotfile-free sandbox,
# that the #30 guard refuses an undeclared style, and that a no-network degraded probe (ringer
# absent) still passes. Uses throwaway HOMEs; the real HOME is never touched.
# Run after Tasks 1-2 are committed (it clones HEAD).
set -uo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "CLEAN-ROOM FAIL: $1" >&2; exit 1; }
# An exported LOOP_STACK_* would leak into proof 2's refusal check; control the environment.
unset LOOP_STACK_SKILL_STYLE LOOP_STACK_RINGER_ROOT LOOP_STACK_RINGER_VERSION
# Seed a git identity into the current sandbox HOME so suites that commit do not depend on the
# host having a global git ident (auto-detection yields "user@host.(none)" and fails on some hosts).
seed_git() { git config --global user.email clean@room.invalid; git config --global user.name cleanroom; }

SANDBOX="$(mktemp -d)"; trap 'rm -rf "$SANDBOX"' EXIT
SRC="$SANDBOX/repo"
# A real local clone (committed HEAD only, no gitignored host.env), so the tree has a .git and
# the tracked-tree checks (the hardcode sweep) actually run instead of trivially passing.
git clone --quiet "$REPO" "$SRC" || fail "could not clone the repo into the sandbox"

# --- proof 1: non-interactive install with style set, then the full suite (criteria 1, 3) ---
export HOME="$SANDBOX/home"; mkdir -p "$HOME"; seed_git
LOOP_STACK_SKILL_STYLE=agents bash "$SRC/install.sh" </dev/null || fail "install.sh (style=agents) did not exit 0"
[ -L "$HOME/.claude/skills/loop-drive" ] || fail "install did not symlink skills"
bash "$SRC/tests/run.sh" || fail "tests/run.sh not green in the clean room"

# --- proof 2: the #30 guard - style undeclared, no TTY, must REFUSE (criterion 2) ---
rm -f "$SRC/config/host.env"   # ensure nothing declares the style
if bash "$SRC/install.sh" </dev/null >/dev/null 2>&1; then
  fail "install.sh defaulted the skill style with no TTY (the #30 guard did not fire)"
fi

# --- proof 3: no-network degraded probe, ringer absent (criterion 4) ---
export HOME="$SANDBOX/home2"; mkdir -p "$HOME"; seed_git
export LOOP_STACK_RINGER_ROOT="$SANDBOX/no-ringer-here"   # guaranteed absent
# Blackhole HTTP egress so any standard network call fails fast. The install/test path makes no
# network calls, so this proves the stack is offline-clean in degraded mode.
# ponytail: proxy-level guard only, not a kernel firewall; sufficient because the stack uses no raw sockets.
export http_proxy=http://127.0.0.1:1 https_proxy=http://127.0.0.1:1 all_proxy=http://127.0.0.1:1
LOOP_STACK_SKILL_STYLE=agents bash "$SRC/install.sh" </dev/null || fail "degraded install (ringer absent) did not exit 0"
bash "$SRC/tests/run.sh" || fail "degraded-mode suite not green (ringer absent)"

echo "CLEAN-ROOM PASS: install green, suite green, #30 guard fires, degraded probe green"
