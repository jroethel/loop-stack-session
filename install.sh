#!/bin/bash
# Loop-stack installer. The only thing that touches ~/.claude and ~/.config.
# Idempotent, plain bash, no dependencies. Never writes secrets.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
RINGER_DIR="$HOME/.config/ringer"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
BEGIN_MARK="# --- loop-stack (managed) ---"
END_MARK="# --- end loop-stack (managed) ---"

# 1. skills: back up a real dir once, then symlink each repo skill (repo edits stay live).
# Two styles:
#   agents (default): repo -> ~/.agents/skills/<name>, and ~/.claude/skills/<name> -> ~/.agents/skills/<name>
#                     (skills live in the harness-neutral home; each harness gets a symlink)
#   claude:           repo -> ~/.claude/skills/<name> directly
# Non-interactive runs: set LOOP_STACK_SKILL_STYLE=agents|claude.
# Backups go OUTSIDE any skills/ dir - Claude Code scans every subdir of skills/ as a skill,
# so a *.bak left in there would load as a stale duplicate skill.
AGENTS_DIR="$HOME/.agents"
AGENTS_SKILLS="$AGENTS_DIR/skills"
STYLE="${LOOP_STACK_SKILL_STYLE:-}"
if [ -z "$STYLE" ] && [ -t 0 ]; then
  read -r -p "Skill install style - [a]gents (~/.agents/skills + harness symlinks) or [c]laude (direct into ~/.claude/skills)? [a] " STYLE
fi
case "${STYLE:-a}" in
  a|agents) STYLE=agents ;;
  c|claude) STYLE=claude ;;
  *) echo "unknown style '$STYLE' (use agents or claude)"; exit 1 ;;
esac
echo "skill style: $STYLE"

# link_skill <target> <link> <backup-path>: replace <link> with a symlink to <target>,
# backing up a pre-existing real dir once.
link_skill() {
  if [ -e "$2" ] && [ ! -L "$2" ]; then
    if [ ! -e "$3" ]; then
      mv "$2" "$3"
      echo "backed up existing skill -> $3"
    else
      echo "skipping backup: $3 already exists; removing live dir"
      rm -rf "$2"
    fi
  fi
  ln -sfn "$1" "$2"
  echo "symlinked $2 -> $1"
}

# retire_skill <path> <backup-path>: remove a superseded skill (symlinks deleted, real dirs backed up once).
retire_skill() {
  if [ -L "$1" ]; then
    rm "$1"
    echo "removed superseded skill symlink $1"
  elif [ -e "$1" ]; then
    if [ ! -e "$2" ]; then
      mv "$1" "$2"
      echo "retired superseded skill $1 -> $2"
    else
      rm -rf "$1"
      echo "removed superseded skill $1 ($2 already exists)"
    fi
  fi
}

mkdir -p "$SKILLS_DIR"
if [ "$STYLE" = agents ]; then
  mkdir -p "$AGENTS_SKILLS"
fi
for TARGET in "$REPO"/skills/*; do
  [ -d "$TARGET" ] || continue
  name="$(basename "$TARGET")"
  if [ "$STYLE" = agents ]; then
    link_skill "$TARGET" "$AGENTS_SKILLS/$name" "$AGENTS_DIR/$name.bak"
    link_skill "$AGENTS_SKILLS/$name" "$SKILLS_DIR/$name" "$CLAUDE_DIR/$name.bak"
  else
    link_skill "$TARGET" "$SKILLS_DIR/$name" "$CLAUDE_DIR/$name.bak"
  fi
done

# 1b. retire pre-rename skill names (frontier-loop -> loop-drive, one-minute-test -> loop-which)
# so the old and new skills never load side by side, in either scan location.
for old in frontier-loop one-minute-test; do
  retire_skill "$SKILLS_DIR/$old" "$CLAUDE_DIR/$old.bak"
  if [ "$STYLE" = agents ]; then
    retire_skill "$AGENTS_SKILLS/$old" "$AGENTS_DIR/$old.bak"
  fi
done

# 2. ringer config: copy each file only if absent (never clobber the live config.toml). chmod +x wrappers.
mkdir -p "$RINGER_DIR"
for src in "$REPO"/config/ringer/*; do
  [ -e "$src" ] || continue
  dest="$RINGER_DIR/$(basename "$src")"
  if [ -e "$dest" ]; then
    echo "keeping existing $dest"
  else
    cp "$src" "$dest"
    echo "installed $dest"
  fi
  case "$dest" in *.sh) chmod +x "$dest" ;; esac
done

# 2b. fable-sandwich benchmark reference: symlink so repo edits stay live.
FS_REFS="$SKILLS_DIR/fable-sandwich/references"
if [ -d "$SKILLS_DIR/fable-sandwich" ]; then
  mkdir -p "$FS_REFS"
  ln -sfn "$REPO/config/fable-sandwich/model-benchmarks.md" "$FS_REFS/model-benchmarks.md"
  echo "symlinked $FS_REFS/model-benchmarks.md"
else
  echo "note: fable-sandwich skill not installed; skipping model-benchmarks.md symlink"
fi

# 3. CLAUDE.md managed block: replace in place, never duplicate.
mkdir -p "$CLAUDE_DIR"
touch "$CLAUDE_MD"
tmp="$(mktemp)"
# Drop any prior managed block (inclusive of both markers).
awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
  $0==b {skip=1; next}
  $0==e {skip=0; next}
  !skip {print}
' "$CLAUDE_MD" > "$tmp"
# Trim a trailing blank line so re-runs do not accumulate whitespace.
printf '%s\n\n%s\n' "$BEGIN_MARK" "$(cat "$REPO/claude-md/fable.md")" >> "$tmp"
printf '%s\n' "$END_MARK" >> "$tmp"
mv "$tmp" "$CLAUDE_MD"
echo "refreshed loop-stack managed block in $CLAUDE_MD"

# 4. doctor: warn about engine prerequisites the ringer lanes need at run time. Never fatal.
command -v claude >/dev/null 2>&1 \
  && echo "found claude: $(command -v claude)" \
  || echo "WARNING: claude CLI not found (claude + claude-zai lanes) - install: https://claude.com/claude-code"
command -v opencode >/dev/null 2>&1 \
  && echo "found opencode: $(command -v opencode)" \
  || echo "WARNING: opencode not found (openrouter lane) - install: brew install sst/tap/opencode, then wire the OpenRouter key"
command -v codex >/dev/null 2>&1 \
  && echo "found codex: $(command -v codex)" \
  || echo "note: codex not found (only needed if you use the sample codex engine) - install: npm i -g @openai/codex"
[ -d "$HOME/repos/ringer" ] \
  && echo "found ringer: $HOME/repos/ringer" \
  || echo "WARNING: ~/repos/ringer not found - config.toml points its engine paths there"
if [ -f "$RINGER_DIR/config.toml" ] && grep -q '^\[engines\.' "$RINGER_DIR/config.toml"; then
  echo "found engines: $(grep -c '^\[engines\.' "$RINGER_DIR/config.toml") block(s) in config.toml"
else
  echo "WARNING: no [engines.*] blocks in $RINGER_DIR/config.toml - routing has no wired engines"
fi
[ -f "$RINGER_DIR/zai-token" ] \
  && echo "found zai-token" \
  || echo "WARNING: $RINGER_DIR/zai-token missing - the claude-zai flat-rate lane cannot authenticate"
[ -w "$HOME/.ringer" ] \
  && echo "found ~/.ringer (writable)" \
  || echo "note: ~/.ringer missing or unwritable - ringer creates it on first run; scoreboard evidence lands there"
[ -L "$SKILLS_DIR/fable-sandwich/references/model-benchmarks.md" ] \
  && echo "found model-benchmarks.md (prior tier wired)" \
  || echo "WARNING: model-benchmarks.md not linked - the routing chain's prior tier is a dangling pointer"
echo "hint: ./ringer.py demo verifies an engine end to end"

echo "done. (z.ai / openrouter tokens are created manually, never by this script.)"
