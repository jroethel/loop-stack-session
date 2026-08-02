#!/usr/bin/env bash
# loop-setup/setup.sh - render a repo's config/repo-state.md from the template,
#   create the docs/ homes, and (when a GitHub remote is present) ensure the
#   `idea` label and generate the ISSUES/BACKLOG mirrors. Idempotent.
# Runs FROM this repo INTO the target repo's cwd. Safe to re-run.
set -uo pipefail
fail() { echo "FAIL: $1" >&2; exit 1; }

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
TPL="$REPO/config/repo-state.template.md"
GEN="$REPO/scripts/gen-mirrors.sh"
[ -f "$TPL" ] || fail "template not found: $TPL"
[ -x "$GEN" ] || fail "gen-mirrors.sh not found or not executable: $GEN"

DRY_REMOTE=0
[ "${1:-}" = "--dry-run-remote" ] && DRY_REMOTE=1

# Detect a GitHub remote in the target repo (the cwd we were called from).
remote_url=""
if [ "$DRY_REMOTE" -eq 1 ]; then
  # Dry-run forces remote-present treatment; use origin if present, else a stub.
  remote_url="$(git remote get-url origin 2>/dev/null || true)"
  [ -n "$remote_url" ] || remote_url="https://github.com/dry-run/remote.git"
else
  remote_url="$(git remote -v 2>/dev/null | awk '{print $2}' | grep -i 'github\.com' | head -n1 || true)"
fi

mkdir -p config docs/handoffs docs/reviews docs/archive

render_no_remote() {
  # Keep the full template (Fallback section included); note the fallback inline.
  local note="none (no remote - local markdown fallback; see section below)"
  awk -v note="$note" '
    index($0, "{{REMOTE_OR_FALLBACK}}") { print "Remote: " note; next }
    { print }
  ' "$TPL"
}

render_remote() {
  # Fill the placeholder with the URL, drop the Fallback section, and scrub any
  # remaining line whose text mentions the no-remote fallback machinery
  # (fallback / scratch / no remote) - those markers must not appear in a
  # remote repo's config. The template carries several such mentions outside
  # the Fallback section (intro, Handoffs row, cross-repo search line), so the
  # per-line scrub is what makes the remote render clean.
  awk -v url="$1" '
    BEGIN { skip = 0 }
    index($0, "{{REMOTE_OR_FALLBACK}}") { print "Remote: " url; next }
    /^## Fallback \(no remote\)/ { skip = 1; next }
    /^## / { skip = 0 }
    {
      if (skip) next
      low = tolower($0)
      if (index(low, "fallback")) next
      if (index(low, "scratch")) next
      if (index(low, "no remote")) next
      print
    }
  ' "$TPL"
}

ensure_roadmap() {
  [ -f docs/roadmap.md ] || printf '# Roadmap\n\n_Living file; edit in place._\n' > docs/roadmap.md
}

if [ -n "$remote_url" ]; then
  # --- remote-present branch ---
  if [ ! -f config/repo-state.md ]; then
    render_remote "$remote_url" > config/repo-state.md
    echo "wrote config/repo-state.md (remote: $remote_url)"
  else
    echo "config/repo-state.md exists; skipping render"
  fi
  ensure_roadmap

  if [ "$DRY_REMOTE" -eq 0 ]; then
    # Ensure the load-bearing `idea` label exists (skip if present). Live gh only.
    if ! gh label list --limit 200 2>/dev/null | awk '{print $1}' | grep -qx 'idea'; then
      gh label create idea --description "Backlog candidate" 2>/dev/null \
        && echo "created label idea" \
        || echo "label idea not created (gh unavailable or already exists); continuing"
    else
      echo "label idea exists; skipping"
    fi
  else
    echo "dry-run-remote: skipping gh label create"
  fi

  # Mirrors regenerate from GitHub, or from MIRRORS_JSON_FILE when that env hook is set.
  "$GEN" . || fail "gen-mirrors.sh failed"
else
  # --- no-remote branch: local-markdown tracker fallback at .scratch/<feature>/issues/ ---
  if [ ! -f config/repo-state.md ]; then
    render_no_remote > config/repo-state.md
    echo "wrote config/repo-state.md (no remote - local markdown fallback)"
  else
    echo "config/repo-state.md exists; skipping render"
  fi
  ensure_roadmap
fi

echo "loop-setup complete"
