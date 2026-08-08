#!/usr/bin/env bash
# migrate-tracker.sh - recreate every local docs/issues/ file as a GitHub issue (local -> github).
# MIGRATE_DRY_RUN=1 prints the gh commands without executing. Real runs flip tracker: github at the end.
set -uo pipefail
fail() { echo "migrate-tracker: $1" >&2; exit 1; }
ask() {   # $1 = prompt; 0 = yes, 1 = no
  [ "${LOOP_ASSUME_YES:-0}" = 1 ] && return 0
  [ "${LOOP_ASSUME_NO:-0}"  = 1 ] && return 1
  local a; printf '%s [y/N]: ' "$1" >&2; read -r a || return 1
  case "$a" in [yY]*) return 0;; *) return 1;; esac
}
ISSUE_DIR="docs/issues"
DRY=0; [ "${MIGRATE_DRY_RUN:-0}" = "1" ] && DRY=1
fm() { grep -E "^$2:" "$1" | head -1 | sed -E "s/^$2:[[:space:]]*//; s/[[:space:]]*$//"; }
body_of() { awk 'f{print} /^---$/{c++; if(c==2){f=1}}' "$1"; }   # everything after the frontmatter
stamp_migrated() {   # append a migrated: <url> line inside the FIRST frontmatter block (before its closing ---)
  local f="$1" u="$2" tmp; tmp="$(mktemp)"
  awk -v u="$u" '/^---$/ { d++; if (d==2) print "migrated: " u } { print }' "$f" > "$tmp" && mv "$tmp" "$f"
}
freeze_state() {   # rewrite the state: VALUE to the frozen marker inside the FIRST frontmatter block
  local f="$1" tmp; tmp="$(mktemp)"
  awk '
    /^---$/ { d++; print; next }
    d==1 && /^state:/ { print "state: migrated"; next }
    { print }
  ' "$f" > "$tmp" && mv "$tmp" "$f"
}

if [ "$DRY" = 0 ]; then
  command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 \
    || fail "migration to github requires an authenticated gh CLI (run: gh auth login)"
fi
shopt -s nullglob
files=("$ISSUE_DIR"/*.md)
[ "${#files[@]}" -gt 0 ] || { echo "migrate-tracker: no local issues in $ISSUE_DIR"; exit 0; }

# ensure every distinct label exists first - gh issue create --label X aborts if X is not defined on the remote
labelset="$(for f in "${files[@]}"; do fm "$f" labels; done | tr ',' '\n' \
  | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | grep -v '^$' | sort -u)"
if [ -n "$labelset" ]; then
  while IFS= read -r lbl; do
    [ -n "$lbl" ] || continue
    if [ "$DRY" = 1 ]; then printf 'gh label create %s\n' "$lbl"
    else gh label create "$lbl" 2>/dev/null || true; fi
  done <<< "$labelset"
fi

for f in "${files[@]}"; do
  # resume-safe: a real run skips any file already stamped migrated: (a prior partial run created it).
  # dry-run never skips - it previews every issue.
  if [ "$DRY" = 0 ] && grep -q '^migrated:' "$f"; then
    echo "skip: local #$(fm "$f" number) already migrated ($(fm "$f" migrated))"; continue
  fi
  num="$(fm "$f" number)"; title="$(fm "$f" title)"; labels="$(fm "$f" labels)"; state="$(fm "$f" state)"
  body="$(printf '%s\n---\nMigrated from local issue #%s\n' "$(body_of "$f")" "$num")"
  if [ "$DRY" = 1 ]; then
    if [ -n "$labels" ]; then
      printf "gh issue create --title '%s' --label '%s' --body <migrated body of local #%s>\n" "$title" "$labels" "$num"
    else
      printf "gh issue create --title '%s' --body <migrated body of local #%s>\n" "$title" "$num"
    fi
    [ "$state" = closed ] && printf "gh issue close <new #> (local #%s was closed)\n" "$num"
  else
    if [ -n "$labels" ]; then
      url="$(gh issue create --title "$title" --label "$labels" --body "$body")" \
        || fail "gh issue create failed for local #$num ($title)"
    else
      url="$(gh issue create --title "$title" --body "$body")" \
        || fail "gh issue create failed for local #$num ($title)"
    fi
    new="${url##*/}"
    stamp_migrated "$f" "$url"   # record BEFORE anything else so a re-run after a later failure skips this file
    freeze_state "$f"
    echo "migrated local #$num -> $url"
    [ "$state" = closed ] && { gh issue close "$new" >/dev/null && echo "  re-closed #$new (was closed locally)"; }
  fi
done
if [ "$DRY" = 0 ]; then
  scripts/tracker.sh mode set github >/dev/null; echo "flipped tracker: github"
fi
if [ "$DRY" = 0 ] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  mig=()
  for f in "${files[@]}"; do grep -q '^migrated:' "$f" && mig+=("$f"); done
  if [ "${#mig[@]}" -gt 0 ] && ask "git rm the ${#mig[@]} migrated ledger file(s)?"; then
    # -f: freeze_state modified these files vs HEAD, and plain `git rm` refuses modified files.
    # --cached: stage the deletion in the index but leave the frozen audit file on disk for review.
    git rm -qf --cached "${mig[@]}" && echo "staged git rm of ${#mig[@]} migrated ledger file(s)"
  fi
fi
