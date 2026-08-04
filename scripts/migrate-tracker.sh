#!/usr/bin/env bash
# migrate-tracker.sh - recreate every local docs/issues/ file as a GitHub issue (local -> github).
# MIGRATE_DRY_RUN=1 prints the gh commands without executing. Real runs flip tracker: github at the end.
set -uo pipefail
fail() { echo "migrate-tracker: $1" >&2; exit 1; }
ISSUE_DIR="docs/issues"
DRY=0; [ "${MIGRATE_DRY_RUN:-0}" = "1" ] && DRY=1
fm() { grep -E "^$2:" "$1" | head -1 | sed -E "s/^$2:[[:space:]]*//; s/[[:space:]]*$//"; }
body_of() { awk 'f{print} /^---$/{c++; if(c==2){f=1}}' "$1"; }   # everything after the frontmatter
stamp_migrated() {   # append a migrated: <url> line inside the FIRST frontmatter block (before its closing ---)
  local f="$1" u="$2" tmp; tmp="$(mktemp)"
  awk -v u="$u" '/^---$/ { d++; if (d==2) print "migrated: " u } { print }' "$f" > "$tmp" && mv "$tmp" "$f"
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
    printf "gh issue create --title '%s' --label '%s' --body <migrated body of local #%s>\n" "$title" "$labels" "$num"
    [ "$state" = closed ] && printf "gh issue close <new #> (local #%s was closed)\n" "$num"
  else
    url="$(gh issue create --title "$title" --label "$labels" --body "$body")" \
      || fail "gh issue create failed for local #$num ($title)"
    new="${url##*/}"
    stamp_migrated "$f" "$url"   # record BEFORE anything else so a re-run after a later failure skips this file
    echo "migrated local #$num -> $url"
    [ "$state" = closed ] && { gh issue close "$new" >/dev/null && echo "  re-closed #$new (was closed locally)"; }
  fi
done
if [ "$DRY" = 0 ]; then
  scripts/tracker.sh mode set github >/dev/null; echo "flipped tracker: github"
fi
