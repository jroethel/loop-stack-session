#!/usr/bin/env bash
# loop-setup/setup.sh - declare a repo's tracker mode (ask once when the key is missing),
#   render its config/repo-state.md, create the docs/ homes, and run the mode-appropriate
#   finalize (github: gh auth fail-fast, idea label, mirrors; local: docs/issues, mirrors, zero gh).
# Runs FROM this repo INTO the target repo's cwd. Idempotent; safe to re-run.
set -uo pipefail
fail() { echo "FAIL: $1" >&2; exit 1; }
ask() {   # $1 = prompt; 0 = yes, 1 = no. Env-then-read, mirroring determine_mode.
  [ "${LOOP_ASSUME_YES:-0}" = 1 ] && return 0
  [ "${LOOP_ASSUME_NO:-0}"  = 1 ] && return 1
  local a; printf '%s [y/N]: ' "$1" >&2; read -r a || return 1
  case "$a" in [yY]*) return 0;; *) return 1;; esac
}
version_of() { grep -E '^template-version:' "$1" 2>/dev/null | head -1 \
  | sed -E 's/^template-version:[[:space:]]*//; s/[[:space:]]*$//'; }

# Resolve physically (-P): the installed skill is a symlink chain (~/.claude/skills ->
# ~/.agents/skills -> repo), and a logical walk up from the link lands in ~/.claude.
HERE="$(cd "$(dirname "$0")" && pwd -P)"
REPO="$(cd "$HERE/../.." && pwd -P)"
TPL="$REPO/config/repo-state.template.md"
GEN="$REPO/scripts/gen-mirrors.sh"
[ -f "$TPL" ] || fail "template not found: $TPL"
[ -x "$GEN" ] || fail "gen-mirrors.sh not found or not executable: $GEN"
TIDY="$REPO/scripts/tidy.sh"
[ -x "$TIDY" ] || fail "tidy.sh not found or not executable: $TIDY"

DRY_REMOTE=0
SCAN_ROOTS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run-remote) DRY_REMOTE=1; shift ;;
    --scan) [ $# -ge 2 ] || fail "--scan requires a directory argument"; SCAN_ROOTS+=("$2"); shift 2 ;;
    *) fail "unknown argument: $1" ;;
  esac
done

# Detect a GitHub remote in the target repo (the cwd we were called from).
# Advisory only: it phrases the suggestion, never picks the mode.
remote_url=""
if [ "$DRY_REMOTE" -eq 1 ]; then
  # Dry-run forces remote-present treatment; use origin if present, else a stub.
  remote_url="$(git remote get-url origin 2>/dev/null || true)"
  [ -n "$remote_url" ] || remote_url="https://github.com/dry-run/remote.git"
else
  remote_url="$(git remote -v 2>/dev/null | awk '{print $2}' | grep -i 'github\.com' | head -n1 || true)"
fi

mkdir -p config docs/handoffs docs/reviews docs/archive

# Install the mirror generator into the target repo (skip-if-exists), so the regen command the
# config declares (`scripts/gen-mirrors.sh .`) is true locally - not a dangling pointer to loop-stack.
if [ ! -f scripts/gen-mirrors.sh ]; then
  mkdir -p scripts
  cp "$GEN" scripts/gen-mirrors.sh && chmod +x scripts/gen-mirrors.sh
  echo "installed scripts/gen-mirrors.sh"
fi

TRK="$REPO/scripts/tracker.sh"
[ -x "$TRK" ] || fail "tracker.sh not found or not executable: $TRK"
if [ ! -f scripts/tracker.sh ]; then
  mkdir -p scripts; cp "$TRK" scripts/tracker.sh && chmod +x scripts/tracker.sh
  echo "installed scripts/tracker.sh"
fi

render_github() {
  # Fill the placeholder with the remote URL and strip the Local tracker section by heading;
  # drop the "Render it into" instruction line. Local-mode disclosures must not survive here.
  awk -v url="$1" '
    BEGIN { skip = 0 }
    index($0, "Render it into") { next }
    index($0, "{{REMOTE_OR_FALLBACK}}") { print "Remote: " url; next }
    /^## Local tracker/ { skip = 1; next }
    /^## / { skip = 0 }
    index($0, "the Local tracker section governs local mode") {
      print "The tracker backend (github or local) is declared in the `tracker:` key below."
      next
    }
    { if (skip) next; print }
  ' "$TPL"
}

render_local() {
  # Fill the placeholder noting local mode; drop the "Render it into" line.
  # KEEP the ## Local tracker section intact - its disclosures are required in local config.
  local note="none (local tracker; see the Local tracker section)"
  awk -v note="$note" '
    index($0, "Render it into") { next }
    index($0, "{{REMOTE_OR_FALLBACK}}") { print "Remote: " note; next }
    { print }
  ' "$TPL"
}

report_remote() {    # human-facing remote status -> STDOUT (so callers/tests that capture stdout see it)
  if [ -n "$remote_url" ]; then
    echo "GitHub remote found: $remote_url - suggesting tracker: github"
  else
    echo "No GitHub remote found - choose a tracker mode (no default)"
  fi
}
determine_mode() {   # resolves the answer ONLY; echoes the bare mode word to stdout, prompt text to stderr
  if [ -n "${LOOP_TRACKER_ANSWER:-}" ]; then echo "$LOOP_TRACKER_ANSWER"; return; fi
  local ans; printf 'tracker mode (github|local): ' >&2; read -r ans; echo "$ans"
}

ensure_roadmap() {
  [ -f ROADMAP.md ] || printf '# Roadmap\n\n_Living file; edit in place._\n' > ROADMAP.md
}

reconcile_config() {   # offer a re-render when the config's template-version differs from the template's
  [ -f config/repo-state.md ] || return 0
  local tv cv cand remote
  tv="$(version_of "$TPL")"
  cv="$(version_of config/repo-state.md)"
  [ "$cv" = "$tv" ] && return 0                 # already current -> report nothing
  if [ "$MODE" = github ]; then
    remote="$(grep -E '^Remote:' config/repo-state.md | head -1 | sed -E 's/^Remote:[[:space:]]*//')"
    [ -n "$remote" ] || remote="$remote_url"    # fall back to the detected remote when the config has no Remote: line
    cand="$(render_github "$remote")"
  else
    cand="$(render_local)"
  fi
  cand="$cand"$'\n'"tracker: $MODE"             # mirror tracker.sh mode set's appended key
  echo "config/repo-state.md is stale (template-version '${cv:-none}' vs '$tv'); proposed re-render:"
  diff -u config/repo-state.md <(printf '%s\n' "$cand") || true
  echo "note: accepting REPLACES the whole file with the render above; any hand edits not shown as kept are lost."
  if ask "re-render config/repo-state.md to template-version $tv (preserving mode $MODE)?"; then
    printf '%s\n' "$cand" > config/repo-state.md
    echo "re-rendered config/repo-state.md (template-version $tv)"
  else
    echo "left config/repo-state.md unchanged"
  fi
}

is_excluded() {   # $1 = path; true for the live tracker home, loop-stack's own dirs, and the ALL-CAPS mirrors
  case "$1" in
    docs/issues/*|docs/handoffs/*|docs/reviews/*|docs/briefs/*|docs/archive/*) return 0 ;;
  esac
  case "$(basename "$1")" in ROADMAP.md|ISSUES.md|BACKLOG.md) return 0 ;; esac
  return 1
}
is_candidate() { # $1 = path; keyword filename OR issue-shaped content
  local base; base="$(basename "$1")"
  # keyword match anchored to whole filename tokens so "fixture"/"explanation" do not match "fix"/"plan"
  printf '%s' "$base" | grep -qiE '(^|[^a-z])(issues|next|backlog|plan|fix|todo)([^a-z]|$)' && return 0
  if grep -qE '^# ' "$1" && grep -qiE '^(Label|Filed|Status):' "$1"; then return 0; fi
  grep -qiE '^(number|title|state):' "$1" && return 0
  return 1
}
reconcile_import() {   # local mode only: scan standard + --scan roots, offer each candidate for import
  local roots=() r f label title body
  for r in docs .planning .ralph; do [ -d "$r" ] && roots+=("$r"); done
  for r in .scratch/*/issues; do [ -d "$r" ] && roots+=("$r"); done
  for r in ${SCAN_ROOTS[@]+"${SCAN_ROOTS[@]}"}; do [ -d "$r" ] && roots+=("$r"); done
  [ "${#roots[@]}" -gt 0 ] || return 0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    is_excluded "$f" && continue
    is_candidate "$f" || continue
    if head -1 "$f" | grep -qE '^---$'; then
      # frontmatter-shaped file: read title/labels from frontmatter, strip the first frontmatter block from the body
      title="$(grep -E '^title:'  "$f" | head -1 | sed -E 's/^title:[[:space:]]*//; s/[[:space:]]*$//')"
      label="$(grep -E '^labels:' "$f" | head -1 | sed -E 's/^labels:[[:space:]]*//; s/[[:space:]]*$//')"
      body="$(awk 'f{print} /^---$/{c++; if(c==2){f=1}}' "$f")"
    else
      # prose file: title from the # H1, label from the Label: line
      label="$(grep -iE '^Label:' "$f" | head -1 | sed -E 's/^[Ll]abel:[[:space:]]*//; s/[[:space:]]*$//')"
      title="$(grep -E '^# ' "$f" | head -1 | sed -E 's/^#[[:space:]]+//')"
      body="$(cat "$f")"
    fi
    [ -n "$title" ] || title="$(basename "$f" .md)"
    echo "import candidate: $f (title: $title, label: ${label:-none})"
    if ask "import $f as a tracker issue?"; then
      scripts/tracker.sh create --label "$label" --title "$title" --body "$body" >/dev/null \
        && echo "imported $f"
    fi
  done < <(find "${roots[@]}" -type f -name '*.md' | sort)
}

existing_mode="$(scripts/tracker.sh mode get 2>/dev/null || true)"
if [ -n "$existing_mode" ]; then
  echo "tracker mode: $existing_mode (declared); not re-asking"
  MODE="$existing_mode"
else
  report_remote                 # STDOUT report before resolving the mode (never picks a default)
  if [ ! -f config/repo-state.md ]; then
    MODE="$(determine_mode)"
    case "$MODE" in github) render_github "$remote_url" > config/repo-state.md ;;
                    local)  render_local          > config/repo-state.md ;;
                    *) fail "tracker mode must be 'github' or 'local' (got '$MODE')";; esac
    echo "wrote config/repo-state.md (tracker: $MODE)"
  else
    MODE="$(determine_mode)"      # legacy keyless config: keep content, just set the key
    echo "legacy config found; recording tracker: $MODE without re-rendering"
  fi
  scripts/tracker.sh mode set "$MODE" >/dev/null
fi
reconcile_config
ensure_roadmap
if [ "$MODE" = github ]; then
  if [ "$DRY_REMOTE" -eq 0 ]; then
    command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 \
      || fail "tracker: github requires an authenticated gh CLI (install gh and run: gh auth login)"
    [ -n "$remote_url" ] || echo "no remote - to create one: gh repo create --private"
    if ! gh label list --limit 200 2>/dev/null | awk '{print $1}' | grep -qx 'idea'; then
      gh label create idea --description "Backlog candidate" 2>/dev/null \
        && echo "created label idea" || echo "label idea not created; continuing"
    else echo "label idea exists; skipping"; fi
  else
    echo "dry-run-remote: skipping gh auth check and gh label create"
  fi
  scripts/gen-mirrors.sh . || fail "gen-mirrors.sh failed"
else
  mkdir -p docs/issues
  scripts/gen-mirrors.sh . || fail "gen-mirrors.sh failed"   # local source, zero gh
fi
[ "$MODE" = local ] && reconcile_import
"$TIDY"
echo "loop-setup complete"
