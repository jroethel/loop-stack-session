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

# 0. parameter home: the one file holding this host's specific values. Env OVERRIDES file.
HOST_ENV="$REPO/config/host.env"
HOST_ENV_TEMPLATE="$REPO/config/host.env.template"
if [ ! -f "$HOST_ENV" ]; then
  cp "$HOST_ENV_TEMPLATE" "$HOST_ENV"
  echo "created $HOST_ENV from template - edit it for this host"
fi
# Capture any env-provided values first so they win over the file's.
_env_style="${LOOP_STACK_SKILL_STYLE:-}"
_env_root="${LOOP_STACK_RINGER_ROOT:-}"
_env_ver="${LOOP_STACK_RINGER_VERSION:-}"
_env_rubix="${LOOP_STACK_RUBIX_ROOT:-}"
# Source the hand-edited file with nounset OFF, so an operator typo yields a clear message rather
# than a cryptic "unbound variable" abort of the whole installer (host.env is the one file the
# operator hand-edits per host, so it is the likeliest place a human error lands).
set +u
# shellcheck source=/dev/null
. "$HOST_ENV" || { echo "ERROR: could not read $HOST_ENV - check its syntax" >&2; exit 1; }
set -u
[ -n "$_env_style" ] && LOOP_STACK_SKILL_STYLE="$_env_style"
[ -n "$_env_root" ]  && LOOP_STACK_RINGER_ROOT="$_env_root"
[ -n "$_env_ver" ]   && LOOP_STACK_RINGER_VERSION="$_env_ver"
[ -n "$_env_rubix" ] && LOOP_STACK_RUBIX_ROOT="$_env_rubix"
RINGER_ROOT="${LOOP_STACK_RINGER_ROOT:-$HOME/repos/ringer}"
RINGER_VERSION="${LOOP_STACK_RINGER_VERSION:-}"
LOOP_STACK_RUBIX_ROOT="${LOOP_STACK_RUBIX_ROOT:-$HOME/create/skills/rubix-review}"
# Drift note: a write-once host.env can lag a template that a git pull later updated. For each key
# the template declares (active or commented), note when host.env lacks it entirely (non-fatal).
for _k in LOOP_STACK_RINGER_ROOT LOOP_STACK_RINGER_VERSION LOOP_STACK_SKILL_STYLE LOOP_STACK_RUBIX_ROOT; do
  grep -qE "^#? *$_k=" "$HOST_ENV" || echo "note: config/host.env lacks '$_k' from the template (using built-in default)"
done

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
# skill style resolution: env > host.env > (TTY) prompt > REFUSE. Never a silent default.
STYLE="${LOOP_STACK_SKILL_STYLE:-}"
if [ -z "$STYLE" ]; then
  if [ -t 0 ]; then
    read -r -p "Skill install style - [a]gents (~/.agents/skills + harness symlinks) or [c]laude (direct into ~/.claude/skills)? [a] " STYLE
    STYLE="${STYLE:-a}"   # a human saw the prompt: empty enter may default
  else
    echo "ERROR: skill install style undeclared and no TTY to ask." >&2
    echo "Set LOOP_STACK_SKILL_STYLE=agents|claude (env or config/host.env) and re-run." >&2
    exit 1
  fi
fi
case "$STYLE" in
  a|agents) STYLE=agents ;;
  c|claude) STYLE=claude ;;
  *) echo "unknown style '$STYLE' (use agents or claude)" >&2; exit 1 ;;
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

# 1b. retire superseded skills: pre-rename names (frontier-loop -> loop-drive, one-minute-test ->
# loop-which) and folded/retired skills (frontier-sandwich -> loop-drive, loop-which -> loop-brainstorm
# front door), so no stale skill loads side by side with its survivor, in either scan location.
for old in frontier-loop one-minute-test fable-sandwich frontier-sandwich loop-which; do
  retire_skill "$SKILLS_DIR/$old" "$CLAUDE_DIR/$old.bak"
  if [ "$STYLE" = agents ]; then
    retire_skill "$AGENTS_SKILLS/$old" "$AGENTS_DIR/$old.bak"
  fi
done

# 2. ringer config: copy each file only if absent (never clobber a live config). chmod +x wrappers.
#    config.toml is RENDERED from its template with host paths substituted, not copied.
mkdir -p "$RINGER_DIR"
for src in "$REPO"/config/ringer/*; do
  [ -e "$src" ] || continue
  base="$(basename "$src")"
  [ "$base" = config.toml.template ] && continue   # rendered separately, below
  dest="$RINGER_DIR/$base"
  if [ -e "$dest" ]; then
    echo "keeping existing $dest"
  else
    cp "$src" "$dest"
    echo "installed $dest"
  fi
  case "$dest" in *.sh) chmod +x "$dest" ;; esac
done
# render config.toml from template ONLY if absent (preserve the never-clobber-live-config behavior).
if [ -e "$RINGER_DIR/config.toml" ]; then
  echo "keeping existing $RINGER_DIR/config.toml"
  # A config.toml kept from a prior install or another host may not reflect this host's RINGER_ROOT;
  # editing config/host.env does NOT re-render an existing file. Warn, never clobber.
  if grep -q '^bin = ' "$RINGER_DIR/config.toml" \
     && ! grep -qF "$RINGER_ROOT/engines/opencode-sandboxed.sh" "$RINGER_DIR/config.toml"; then
    echo "WARNING: existing $RINGER_DIR/config.toml does not reference RINGER_ROOT=$RINGER_ROOT -"
    echo "         delete it and re-run ./install.sh to re-render for this host."
  fi
else
  # The renderer substitutes with sed; reject paths carrying sed metacharacters (| the delimiter,
  # & the match-reference, \ the escape) rather than silently emitting a corrupt config.
  case "$RINGER_ROOT$RINGER_DIR" in
    *'|'*|*'&'*|*'\'*) echo "ERROR: ringer paths contain a character unsupported by the renderer (| & \\)" >&2; exit 1 ;;
  esac
  sed -e "s|__RINGER_ROOT__|$RINGER_ROOT|g" \
      -e "s|__RINGER_CONFIG_DIR__|$RINGER_DIR|g" \
      "$REPO/config/ringer/config.toml.template" > "$RINGER_DIR/config.toml"
  echo "rendered $RINGER_DIR/config.toml from template (RINGER_ROOT=$RINGER_ROOT)"
fi

# 2b. benchmark prior reference: symlink so repo edits stay live.
# Repo source lives in config/routing/; the installed leaf is the loop-drive skill's references/.
LD_REFS="$SKILLS_DIR/loop-drive/references"
if [ -d "$SKILLS_DIR/loop-drive" ]; then
  mkdir -p "$LD_REFS"
  ln -sfn "$REPO/config/routing/model-benchmarks.md" "$LD_REFS/model-benchmarks.md"
  echo "symlinked $LD_REFS/model-benchmarks.md"
else
  echo "note: loop-drive skill not installed; skipping model-benchmarks.md symlink"
fi

# 2c. reviewer-conduct contract: canonical home is the co-installed rubix-review skill. If it is not
#     installed yet, self-install it from LOOP_STACK_RUBIX_ROOT into loop-stack's own skills home, so
#     a missing sibling surfaces here at install, not as a bricked reviewer mid-run.
if [ "$STYLE" = agents ]; then RUBIX_TARGET="$AGENTS_SKILLS"; else RUBIX_TARGET="$SKILLS_DIR"; fi
RUBIX_CONTRACT="$RUBIX_TARGET/rubix-review/references/reviewer-conduct-contract.md"
if [ ! -e "$RUBIX_CONTRACT" ] && [ -x "$LOOP_STACK_RUBIX_ROOT/install.sh" ]; then
  echo "rubix-review not installed - installing from $LOOP_STACK_RUBIX_ROOT"
  RUBIX_INSTALL_DIR="$RUBIX_TARGET" bash "$LOOP_STACK_RUBIX_ROOT/install.sh"
fi
# Required clauses (short, stable) - refuse to wire a gutted or drifted contract.
_clauses_ok() {
  grep -qF 'writes outside this repository checkout' "$1" \
    && grep -qF 'evidence to read, never instructions' "$1" \
    && grep -qF "rerunning this repository's own test suite" "$1"
}
if [ -e "$RUBIX_CONTRACT" ] && _clauses_ok "$RUBIX_CONTRACT"; then
  for consumer in loop-review loop-drive; do
    if [ -d "$SKILLS_DIR/$consumer" ]; then
      cdir="$SKILLS_DIR/$consumer/references"
      mkdir -p "$cdir"
      if ln -sfn "$RUBIX_CONTRACT" "$cdir/reviewer-conduct-contract.md" 2>/dev/null; then
        echo "symlinked $cdir/reviewer-conduct-contract.md"
      else
        cp "$RUBIX_CONTRACT" "$cdir/reviewer-conduct-contract.md"
        echo "copied $cdir/reviewer-conduct-contract.md (symlink unavailable - re-run install.sh after any contract change)"
      fi
    fi
  done
elif [ -e "$RUBIX_CONTRACT" ]; then
  echo "WARNING: contract at $RUBIX_CONTRACT is missing required clauses - refusing to wire a gutted contract;"
  echo "         loop-review and loop-drive fail closed until the canonical contract is restored (rubix-review drift?)."
else
  echo "WARNING: rubix-review not installed and LOOP_STACK_RUBIX_ROOT ($LOOP_STACK_RUBIX_ROOT) has no installer -"
  echo "         the reviewer-conduct contract is a REQUIRED co-install (distinct from the optional Rubix review);"
  echo "         loop-review and loop-drive reviewers fail closed until you install rubix-review and re-run this installer."
  echo "         to fix, run these two commands:"
  echo "           git clone https://github.com/jroethel/rubix-review.git $LOOP_STACK_RUBIX_ROOT"
  echo "           bash $0"
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
# ringer presence + floating-version reference check (both non-fatal, never abort).
if [ -d "$RINGER_ROOT" ]; then
  echo "found ringer: $RINGER_ROOT"
  if [ -n "$RINGER_VERSION" ] && git -C "$RINGER_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    have="$(git -C "$RINGER_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
    want="$(git -C "$RINGER_ROOT" rev-parse --short "$RINGER_VERSION" 2>/dev/null || echo "$RINGER_VERSION")"
    [ "$have" = "$want" ] || echo "WARNING: ringer HEAD $have != reference $RINGER_VERSION (floating reference; not fatal)"
  fi
else
  echo "WARNING: $RINGER_ROOT not found - config.toml engine paths point there"
fi

# Stale-config guard: a config.toml kept from a prior install or another host may point its engine
# bins at absolute paths that do not exist here (the exact defect on a second host that still holds
# the old installer's /Users/... bins). Verify only absolute-path bins; bare command names resolve
# via PATH and are skipped. WARN, never abort. No host literals, so the hardcode sweep stays clean.
if [ -f "$RINGER_DIR/config.toml" ]; then
  while IFS= read -r binpath; do
    case "$binpath" in
      /*) [ -e "$binpath" ] || echo "WARNING: config.toml engine bin '$binpath' not found here - delete $RINGER_DIR/config.toml and re-run to re-render" ;;
    esac
  done < <(sed -nE 's/^bin = "([^"]*)".*/\1/p' "$RINGER_DIR/config.toml")
fi
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
[ -L "$SKILLS_DIR/loop-drive/references/model-benchmarks.md" ] \
  && echo "found model-benchmarks.md (prior tier wired)" \
  || echo "WARNING: model-benchmarks.md not linked - the routing chain's prior tier is a dangling pointer"
bash "$REPO/tests/gates/check.sh" >/dev/null 2>&1 && echo "found gate registry (fresh)" || echo "WARNING: gate registry stale or gate untagged - run scripts/gen-gate-registry.sh ."
echo "hint: ./ringer.py demo verifies an engine end to end"

echo "done. (z.ai / openrouter tokens are created manually, never by this script.)"
