#!/usr/bin/env bash
# loop-setup/setup.sh - declare a repo's tracker mode (ask once when the key is missing),
#   render its config/repo-state.md, create the docs/ homes, and run the mode-appropriate
#   finalize (github: gh auth fail-fast, idea label, mirrors; gitlab: glab host-scoped auth,
#   idea label, mirrors; local: docs/issues, mirrors, zero gh).
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
offers=0     # incremented by every offer source; zero is what earns the "nothing to do" summary
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run-remote) DRY_REMOTE=1; shift ;;
    --scan) [ $# -ge 2 ] || fail "--scan requires a directory argument"; SCAN_ROOTS+=("$2"); shift 2 ;;
    *) fail "unknown argument: $1" ;;
  esac
done

# Detect and classify the target repo's remote (the cwd we were called from).
# Advisory only: it phrases the suggestion, never picks the mode.
remote_url="$(git remote get-url origin 2>/dev/null || true)"
# Falling back matters: setup used to scan `git remote -v` for ANY remote, so a repo whose
# only GitHub remote is named `upstream` was detected. Keying solely on origin would regress it.
[ -n "$remote_url" ] || remote_url="$(git remote -v 2>/dev/null | awk 'NR==1 {print $2}' || true)"
remote_kind=none
if [ "$DRY_REMOTE" -eq 1 ]; then
  # Dry-run forces remote-present treatment; only the github stub below is forced github so the
  # no-remote dry-run tests keep their behavior - a real origin is classified exactly as the elif.
  if [ -n "$remote_url" ]; then
    remote_kind=other
    case "$remote_url" in *github.com*) remote_kind=github ;; *gitlab*) remote_kind=gitlab ;; esac
  else
    remote_url="https://github.com/dry-run/remote.git"
    remote_kind=github
  fi
elif [ -n "$remote_url" ]; then
  remote_kind=other
  case "$remote_url" in *github.com*) remote_kind=github ;; *gitlab*) remote_kind=gitlab ;; esac
fi
# Classifying on the substring `gitlab` is a heuristic, not a fact: a self-hosted instance at a
# hostname without "gitlab" in it correctly falls to `other`, which reports the remote and suggests nothing.

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

GRAD="$REPO/scripts/graduate-parking.sh"
[ -x "$GRAD" ] || fail "graduate-parking.sh not found or not executable: $GRAD"
if [ ! -f scripts/graduate-parking.sh ]; then
  mkdir -p scripts; cp "$GRAD" scripts/graduate-parking.sh && chmod +x scripts/graduate-parking.sh
  echo "installed scripts/graduate-parking.sh"
fi

MIG="$REPO/scripts/migrate-tracker.sh"
[ -x "$MIG" ] || fail "migrate-tracker.sh not found or not executable: $MIG"
if [ ! -f scripts/migrate-tracker.sh ]; then
  mkdir -p scripts; cp "$MIG" scripts/migrate-tracker.sh && chmod +x scripts/migrate-tracker.sh
  echo "installed scripts/migrate-tracker.sh"
fi

# Refresh vendored scripts that have drifted from loop-stack's current copies (content compare via
# cmp -s, no version stamps). Each drifted file is offered on its own; declining leaves it untouched.
for pair in "gen-mirrors.sh:$GEN" "tracker.sh:$TRK" "graduate-parking.sh:$GRAD" "migrate-tracker.sh:$MIG"; do
  name="${pair%%:*}"; src="${pair#*:}"
  [ -f "scripts/$name" ] || continue
  cmp -s "scripts/$name" "$src" && continue
  echo "scripts/$name differs from loop-stack's current copy"
  offers=$((offers + 1))
  diff -u "scripts/$name" "$src" || true
  echo "note: accepting REPLACES scripts/$name with loop-stack's copy; any local edits shown above are lost."
  if ask "refresh scripts/$name from loop-stack?"; then
    cp "$src" "scripts/$name" && chmod +x "scripts/$name" && echo "refreshed scripts/$name"
  else
    echo "left scripts/$name unchanged"
  fi
done

render_github() {
  # Fill the placeholder with the remote URL and strip the Local tracker section by heading;
  # drop the "Render it into" instruction line and the gitlab-only lines (backlog-group key and
  # the two glab backlog-view lines). Local-mode disclosures must not survive here.
  awk -v url="$1" '
    BEGIN { skip = 0 }
    index($0, "Render it into") { next }
    index($0, "backlog-group:") { next }
    index($0, "glab issue list") { next }
    index($0, "{{REMOTE_OR_FALLBACK}}") { print "Remote: " url; next }
    /^## Local tracker/ { skip = 1; next }
    /^## / { skip = 0 }
    index($0, "the Local tracker section governs local mode") {
      print "The tracker backend (github, gitlab, or local) is declared in the `tracker:` key below."
      next
    }
    { if (skip) next; print }
  ' "$TPL"
}

render_local() {
  # Fill the placeholder noting local mode; drop the "Render it into" line and the gitlab-only lines.
  # KEEP the ## Local tracker section intact - its disclosures are required in local config.
  local note="none (local tracker; see the Local tracker section)"
  awk -v note="$note" '
    index($0, "Render it into") { next }
    index($0, "backlog-group:") { next }
    index($0, "glab issue list") { next }
    index($0, "{{REMOTE_OR_FALLBACK}}") { print "Remote: " note; next }
    { print }
  ' "$TPL"
}

render_gitlab() {
  # Like render_github but substitutes the backlog group into the gitlab-only lines instead of
  # dropping them. Strips the Local tracker section, drops the "Render it into" line, and rewrites
  # the dangling "Local tracker section governs local mode" pointer.
  awk -v url="$1" -v grp="$2" '
    BEGIN { skip = 0 }
    { gsub(/{{BACKLOG_GROUP}}/, grp) }
    index($0, "Render it into") { next }
    index($0, "{{REMOTE_OR_FALLBACK}}") { print "Remote: " url; next }
    /^## Local tracker/ { skip = 1; next }
    /^## / { skip = 0 }
    index($0, "the Local tracker section governs local mode") {
      print "The tracker backend (github, gitlab, or local) is declared in the `tracker:` key below."
      next
    }
    { if (skip) next; print }
  ' "$TPL"
}

report_remote() {    # human-facing remote status -> STDOUT (so callers/tests that capture stdout see it)
  case "$remote_kind" in
    github) echo "GitHub remote found: $remote_url - suggesting tracker: github" ;;
    gitlab) echo "GitLab remote found: $remote_url - suggesting tracker: gitlab" ;;
    other)  echo "Remote found: $remote_url - no backend inferred; choose a tracker mode (no default)" ;;
    none)   echo "No remote found - choose a tracker mode (no default)" ;;
  esac
}
determine_mode() {   # resolves the answer ONLY; echoes the bare mode word to stdout, prompt text to stderr
  if [ -n "${LOOP_TRACKER_ANSWER:-}" ]; then echo "$LOOP_TRACKER_ANSWER"; return; fi
  local ans; printf 'tracker mode (github|gitlab|local): ' >&2; read -r ans; echo "$ans"
}

ensure_roadmap() {
  [ -f ROADMAP.md ] || printf '# Roadmap\n\n_Living file; edit in place._\n' > ROADMAP.md
}

reconcile_config() {   # offer a re-render when the config's template-version differs from the template's
  [ -f config/repo-state.md ] || return 0
  local tv cv cand remote grp
  tv="$(version_of "$TPL")"
  cv="$(version_of config/repo-state.md)"
  [ "$cv" = "$tv" ] && return 0                 # already current -> report nothing
  case "$MODE" in
    github)
      remote="$(grep -E '^Remote:' config/repo-state.md | head -1 | sed -E 's/^Remote:[[:space:]]*//')"
      # A remote mode must never preserve a local-tracker placeholder as its Remote value.
      if [ -z "$remote" ] || [ "${remote#none}" != "$remote" ]; then remote="$remote_url"; fi
      cand="$(render_github "$remote")"
      ;;
    gitlab)
      remote="$(grep -E '^Remote:' config/repo-state.md | head -1 | sed -E 's/^Remote:[[:space:]]*//')"
      if [ -z "$remote" ] || [ "${remote#none}" != "$remote" ]; then remote="$remote_url"; fi
      grp="$(grep -E '^backlog-group:' config/repo-state.md | head -1 | sed -E 's/^backlog-group:[[:space:]]*//')"
      [ -n "$grp" ] || grp="$(scripts/tracker.sh group 2>/dev/null || true)"
      cand="$(render_gitlab "$remote" "$grp")"
      ;;
    *)
      cand="$(render_local)"
      ;;
  esac
  cand="$cand"$'\n'"tracker: $MODE"             # mirror tracker.sh mode set's appended key
  offers=$((offers + 1))
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

is_excluded() {   # $1 = NORMALIZED path (no ./ prefix); true for the live tracker home, loop-stack's
                  # own dirs, the ALL-CAPS mirrors, and the depth-1 root project documents
  case "$1" in
    docs/issues/*|docs/handoffs/*|docs/reviews/*|docs/briefs/*|docs/plans/*|docs/archive/*) return 0 ;;
  esac
  # docs/plans/* is a governed lane: config/repo-state.md's Archive-and-graduation rules own plan
  # and brief archival ("a brief archives when its plan archives"), so the sweep never offers one.
  # Root project documents, matched against the whole normalized path so only depth-1 files are
  # excluded - a normalized depth-1 path contains no `/`, and matching on basename would also
  # hide docs/notes/PLAN.md and any nested README.md, which is wider than intended. The list is
  # deliberately wider than this repo's own root ls: setup.sh is vendored into other repos.
  case "$1" in
    README.md|CLAUDE.md|AGENTS.md|PLAN.md|CHANGELOG.md|LICENSE.md|CONTRIBUTING.md) return 0 ;;
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
collect_candidates() {   # print one normalized candidate path per line: repo root (depth 1) + the recursive roots
  local roots=() r f
  # The root pass runs UNCONDITIONALLY and stays out of the recursive find below. `find` with an
  # empty path list expands to `find .` and scans the whole tree, which is what the roots guard
  # exists to prevent; the ${roots[@]+...} idiom is no substitute, it passes no path operand at all.
  while IFS= read -r f; do
    f="${f#./}"                      # the root pass yields ./x.md, the recursive pass docs/x.md
    [ -n "$f" ] || continue
    is_excluded "$f" && continue
    is_candidate "$f" || continue
    printf '%s\n' "$f"
  done < <(find . -maxdepth 1 -type f -name '*.md' | sort)
  for r in docs .planning .ralph; do [ -d "$r" ] && roots+=("$r"); done
  for r in .scratch/*/issues; do [ -d "$r" ] && roots+=("$r"); done
  for r in ${SCAN_ROOTS[@]+"${SCAN_ROOTS[@]}"}; do [ -d "$r" ] && roots+=("$r"); done
  [ "${#roots[@]}" -gt 0 ] || return 0
  while IFS= read -r f; do
    f="${f#./}"
    [ -n "$f" ] || continue
    is_excluded "$f" && continue
    is_candidate "$f" || continue
    printf '%s\n' "$f"
  done < <(find "${roots[@]}" -type f -name '*.md' | sort)
}

archive_offer() {   # $1 = normalized candidate path; offer a move to docs/archive/ (the idempotence mechanism)
  local f="$1" dest
  # Never reach outside the repo: --scan takes any directory, so an out-of-tree candidate is
  # imported normally and keeps its home rather than being dragged into this repo's archive.
  case "$f" in /*|../*) return 0 ;; esac
  ask "move $f to docs/archive/?" || return 0
  dest="docs/archive/$(basename "$f")"
  # Never overwrite: two candidates sharing a basename would collapse onto one destination and
  # the first would be destroyed silently. Stdout, not stderr - this is a user-facing decision.
  if [ -e "$dest" ]; then
    echo "skipping archive move: $dest already exists; left at $f"
    return 0
  fi
  mkdir -p docs/archive
  if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    git mv "$f" "$dest" >/dev/null 2>&1 || { echo "archive move failed for $f; left in place"; return 0; }
  else
    mv "$f" "$dest" 2>/dev/null || { echo "archive move failed for $f; left in place"; return 0; }
  fi
  echo "moved $f to $dest"
}

reconcile_import() {   # all modes: scan repo root + standard/--scan roots, offer each candidate for import
  local cands=() n f label title body num imported=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    cands+=("$f")
  done < <(collect_candidates)
  n="${#cands[@]}"
  [ "$n" -gt 0 ] || return 0                 # silent; the end-of-run summary is what says "nothing to do"
  # The count line is separate from the gate prompt on purpose: ask() returns without printing when
  # LOOP_ASSUME_YES/NO is set, so this is the only trace of the gate that survives an unattended run.
  echo "found $n import candidate(s)"
  offers=$((offers + 1))
  # A declined gate records nothing anywhere, so the same candidates are announced again next run:
  # re-offering is the contract, and durability comes from archiving, not from remembering declines.
  ask "review them?" || return 0
  for f in "${cands[@]}"; do
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
    ask "import $f as a tracker issue?" || continue
    # Ungating the sweep changed the unattended blast radius from "writes local markdown" to "files
    # an issue per candidate on a shared instance", so remote creation needs an explicit opt-in.
    # The gate keys on the unattended-yes variable and on DRY_REMOTE, never on MODE alone: an
    # interactive per-item `y` in github/gitlab mode creates the issue with no extra variable.
    if [ "$MODE" != local ]; then
      if [ "$DRY_REMOTE" -eq 1 ]; then
        echo "dry-run-remote: skipping remote import of $f"
        continue
      elif [ "${LOOP_ASSUME_YES:-0}" = 1 ] && [ "${LOOP_IMPORT_REMOTE:-0}" != 1 ]; then
        echo "skipping remote import of $f (set LOOP_IMPORT_REMOTE=1 to allow unattended remote creation)"
        continue
      fi
    fi
    # Guard the create: treating a failure as imported would archive a file whose issue does not
    # exist, and on a shared instance a create can fail for label, permission, or rate reasons
    # partway through a multi-candidate sweep.
    num="$(scripts/tracker.sh create --label "$label" --title "$title" --body "$body")" \
      || { echo "create failed for $f; skipping" >&2; continue; }
    [ -n "$num" ] || { echo "create returned no issue number for $f; skipping" >&2; continue; }
    echo "imported $f as issue #$num"
    imported=1
    archive_offer "$f"
  done
  # A sweep that just filed issues must not end by printing completion over mirrors that lack them.
  [ "$imported" -eq 1 ] && { scripts/gen-mirrors.sh . || fail "gen-mirrors.sh failed"; }
  return 0
}

existing_mode="$(scripts/tracker.sh mode get 2>/dev/null || true)"
if [ -n "$existing_mode" ]; then
  echo "tracker mode: $existing_mode (declared); not re-asking"
  MODE="$existing_mode"
  # State the remote on every run, not just first setup. Skip when none: the fresh-setup wording
  # ends in "choose a tracker mode", which would be a standing false instruction on a settled no-remote repo.
  if [ "$remote_kind" != none ]; then
    report_remote
    # Offer a declinable switch when a declared mode disagrees with an inferable github/gitlab
    # remote, unless the user acknowledged the disagreement via a tracker-remote-ack: line.
    if [ "$remote_kind" = github ] || [ "$remote_kind" = gitlab ]; then
      ack="$(grep -E '^tracker-remote-ack:' config/repo-state.md 2>/dev/null | head -1 | sed -E 's/^tracker-remote-ack:[[:space:]]*//')"
      if [ "$remote_kind" != "$existing_mode" ] && [ "$ack" != "$remote_kind" ]; then
        echo "declared tracker: $existing_mode, but the remote is $remote_kind: $remote_url"
        offers=$((offers + 1))
        if ask "switch this repo to tracker: $remote_kind?"; then
          scripts/tracker.sh mode set "$remote_kind" \
            || fail "scripts/tracker.sh rejected mode '$remote_kind' - it may predate this backend; accept the drift refresh and re-run"
          MODE="$remote_kind"
        else
          echo "to stop this suggestion, add 'tracker-remote-ack: $remote_kind' to config/repo-state.md"
        fi
      fi
    fi
  fi
else
  report_remote                 # STDOUT report before resolving the mode (never picks a default)
  if [ ! -f config/repo-state.md ]; then
    MODE="$(determine_mode)"
    case "$MODE" in github) render_github "$remote_url" > config/repo-state.md ;;
                    gitlab)  render_gitlab "$remote_url" "$(scripts/tracker.sh group 2>/dev/null || true)" > config/repo-state.md ;;
                    local)   render_local          > config/repo-state.md ;;
                    *) fail "tracker mode must be 'github', 'gitlab', or 'local' (got '$MODE')";; esac
    echo "wrote config/repo-state.md (tracker: $MODE)"
  else
    MODE="$(determine_mode)"      # legacy keyless config: keep content, just set the key
    echo "legacy config found; recording tracker: $MODE without re-rendering"
  fi
  scripts/tracker.sh mode set "$MODE" \
    || fail "scripts/tracker.sh rejected mode '$MODE' - it may predate this backend; accept the drift refresh and re-run"
fi
reconcile_config
ensure_roadmap
case "$MODE" in
  github)
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
    ;;
  gitlab)
    if [ "$DRY_REMOTE" -eq 0 ]; then
      host="$(scripts/tracker.sh host 2>/dev/null || true)"
      [ -n "$host" ] || fail "tracker: gitlab requires an origin remote to resolve the GitLab host"
      command -v glab >/dev/null 2>&1 && glab auth status --hostname "$host" >/dev/null 2>&1 \
        || fail "tracker: gitlab requires glab authenticated to $host (install glab and run: glab auth login --hostname $host)"
      if ! glab label list -F json --jq '.[].name' 2>/dev/null | grep -qx 'idea'; then
        glab label create --name idea --description "Backlog candidate" >/dev/null 2>&1 \
          && echo "created label idea" || echo "label idea not created; continuing"
      else echo "label idea exists; skipping"; fi
    else
      echo "dry-run-remote: skipping glab auth check and glab label create"
    fi
    # A declined gen-mirrors.sh drift refresh would leave every mirror on a GitLab repo claiming
    # GitHub as the source of truth - a lie in the file whose entire purpose is disclosure.
    grep -q 'GitLab issues' scripts/gen-mirrors.sh \
      || fail "scripts/gen-mirrors.sh predates the gitlab backend and would disclose GitHub as the source of truth - accept the gen-mirrors.sh drift refresh and re-run"
    scripts/gen-mirrors.sh . || fail "gen-mirrors.sh failed"
    ;;
  local)
    mkdir -p docs/issues
    scripts/gen-mirrors.sh . || fail "gen-mirrors.sh failed"   # local source, zero gh
    ;;
esac
reconcile_import
# tidy is a child process that always exits 0, so its offers are invisible to the counter unless
# captured. Capture and re-emit: tidy's byproduct: lines stay on stdout, and the interactive
# ordering stays usable because tidy's own per-item prompt (`delete <f>?`, on stderr) names the file.
t="$("$TIDY")" || true
[ -n "$t" ] && printf '%s\n' "$t"
printf '%s' "$t" | grep -q '^byproduct:' && offers=$((offers + 1))
# The one line that must never be false: quiet is a statement, not an absence. A run that asked
# four drift-refresh questions and then claimed nothing to do would be worse than silence.
if [ "$offers" -eq 0 ]; then
  echo "loop-setup complete - nothing to do"
else
  echo "loop-setup complete"
fi
