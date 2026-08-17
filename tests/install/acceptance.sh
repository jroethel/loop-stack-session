#!/usr/bin/env bash
# install acceptance: the #30 style guard (both directions), the config.toml render, and never-clobber.
# Runs the working-tree install.sh against throwaway HOME + REPO copies; the real HOME is never touched.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
# Control the environment: an inherited LOOP_STACK_* export would leak into the refusal case (turning
# a passing guard into a spurious failure) and into the render/never-clobber runs. Unset all three;
# each case passes the values it needs as per-command prefixes.
unset LOOP_STACK_SKILL_STYLE LOOP_STACK_RINGER_ROOT LOOP_STACK_RINGER_VERSION
LOG=""
fail() {
  [ -n "$LOG" ] && [ -f "$LOG" ] && { echo "--- last install log ($LOG) ---" >&2; cat "$LOG" >&2; }
  echo "FAIL: $1" >&2; exit 1
}

# isolated REPO copy without .git or any gitignored host.env (so nothing pre-declares the style)
mkrepo() {
  local d; d="$(mktemp -d)"
  ( cd "$REPO" && tar --exclude=.git -cf - . ) | ( cd "$d" && tar -xf - )
  rm -f "$d/config/host.env"
  printf '%s' "$d"
}

# --- criterion 1: style set, non-interactive, dotfile-free HOME -> exit 0, skills symlinked ---
H1="$(mktemp -d)"; R1="$(mkrepo)"; trap 'rm -rf "$H1" "$R1"' EXIT
LOG="$H1/install.log"
HOME="$H1" LOOP_STACK_SKILL_STYLE=agents bash "$R1/install.sh" </dev/null > "$LOG" 2>&1 \
  || fail "install with style=agents did not exit 0"
[ -L "$H1/.claude/skills/loop-drive" ] || fail "agents-style install did not symlink loop-drive"

# --- criterion 2 / #30: style unset in BOTH env and host.env, no TTY -> REFUSE nonzero, install nothing ---
H2="$(mktemp -d)"; R2="$(mkrepo)"; trap 'rm -rf "$H1" "$R1" "$H2" "$R2"' EXIT
LOG="$H2/install.log"
if HOME="$H2" bash "$R2/install.sh" </dev/null > "$LOG" 2>&1; then
  fail "no-style non-interactive run exited 0 (silently defaulted instead of refusing)"
fi
[ -e "$H2/.claude/skills/loop-drive" ] && fail "the refused run still installed skills"

# --- decision 4: config.toml rendered from template, placeholders substituted, template not copied ---
H3="$(mktemp -d)"; R3="$(mkrepo)"; trap 'rm -rf "$H1" "$R1" "$H2" "$R2" "$H3" "$R3"' EXIT
LOG="$H3/install.log"
HOME="$H3" LOOP_STACK_SKILL_STYLE=agents LOOP_STACK_RINGER_ROOT=/opt/ringer-xyz \
  bash "$R3/install.sh" </dev/null > "$LOG" 2>&1 || fail "render install did not exit 0"
cfg="$H3/.config/ringer/config.toml"
[ -f "$cfg" ] || fail "config.toml was not rendered"
grep -q '__RINGER_ROOT__\|__RINGER_CONFIG_DIR__' "$cfg" && fail "placeholders left unsubstituted in rendered config.toml"
grep -q '/opt/ringer-xyz/engines/opencode-sandboxed.sh' "$cfg" || fail "RINGER_ROOT not substituted into the opencode bin"
grep -q "$H3/.config/ringer/claude-zai.sh" "$cfg" || fail "RINGER_CONFIG_DIR not substituted into the claude-zai bin"
[ -e "$H3/.config/ringer/config.toml.template" ] && fail "the template file was copied literally into ~/.config/ringer"

# --- decision 4: never clobber a live config.toml ---
H4="$(mktemp -d)"; R4="$(mkrepo)"; trap 'rm -rf "$H1" "$R1" "$H2" "$R2" "$H3" "$R3" "$H4" "$R4"' EXIT
LOG="$H4/install.log"
mkdir -p "$H4/.config/ringer"; printf 'SENTINEL-LIVE-CONFIG\n' > "$H4/.config/ringer/config.toml"
HOME="$H4" LOOP_STACK_SKILL_STYLE=agents bash "$R4/install.sh" </dev/null > "$LOG" 2>&1 \
  || fail "install over an existing config.toml did not exit 0"
grep -q 'SENTINEL-LIVE-CONFIG' "$H4/.config/ringer/config.toml" || fail "install clobbered a live config.toml"

echo "PASS: install style guard + config.toml render + never-clobber"
