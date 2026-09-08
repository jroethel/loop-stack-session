#!/usr/bin/env bash
# take-stock.sh rebuilds recorded state from git, session cards, and handoffs: the human report
# names the authoritative handoff and the next step, --cards emits the 7-field intermediate TSV,
# an open card older than the 24-hour threshold marks died-mid-work, a closed card marks nothing,
# and a commit on a later calendar day than the recorded state marks went-stale.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
TS="$REPO/scripts/take-stock.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
R="$tmp/repo"; mkdir -p "$R/docs/sessions" "$R/docs/handoffs"
git -C "$R" init -q; git -C "$R" config user.email a@b.c; git -C "$R" config user.name t

today="$(date -u '+%Y-%m-%d')"
now="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
old="$(date -u -v-30H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '30 hours ago' '+%Y-%m-%dT%H:%M:%SZ')"
tomorrow="$(date -u -v+1d '+%Y-%m-%d' 2>/dev/null || date -u -d 'tomorrow' '+%Y-%m-%d')"

mkcard() {   # $1 filename  $2 status  $3 session-ts  $4 closed-ts (may be empty)  $5 last-log-ts
  cat > "$R/docs/sessions/$1" <<EOF
---
session_card: true
session: $3
token: I52
title: card $1
status: $2
closed: $4
why:
next: run the next task
---

# card $1

## Log

- $5 opened
EOF
}
mkcard "2026-09-05.I52.stalled.md" open "$old" "" "$old"

printf '# Handoff: older (#52)\n\n## Next actions\n\n- Do the older thing.\n' \
  > "$R/docs/handoffs/2026-09-01.I52.older.md"
printf '# Handoff: authoritative (#52)\n\n## Next actions\n\n- Do the newest thing.\n' \
  > "$R/docs/handoffs/$today.I52.authoritative.md"
( cd "$R" && git add -A && git commit -qm "seed" )

rep="$(bash "$TS" "$R")" || fail "take-stock exited non-zero"
grep -q "$today.I52.authoritative.md" <<<"$rep" || fail "the report does not name the authoritative handoff"
grep -qi '^next step:' <<<"$rep" || fail "the report has no 'next step:' line"
grep -q 'run the next task' <<<"$rep" || fail "the next step was not taken from the session card"

rows="$(bash "$TS" "$R" --cards)" || fail "--cards exited non-zero"
awk -F'\t' 'NF!=7{exit 3}' <<<"$rows" || fail "a --cards row does not have 7 fields"
[ "$(awk -F'\t' '$1=="repo"' <<<"$rows" | grep -c .)" -eq 1 ] || fail "--cards must emit exactly one repo row"
[ "$(head -1 <<<"$rows" | cut -f1)" = repo ] || fail "the repo row must be emitted first"
[ "$(awk -F'\t' '$1=="handoff"' <<<"$rows" | grep -c .)" -eq 2 ] || fail "both live handoffs should emit a row"
[ "$(awk -F'\t' '$1=="handoff"{print $3}' <<<"$rows" | sort -u)" = live ] || fail "handoff rows are not derived live"
[ "$(awk -F'\t' '$1=="session"{print $7}' <<<"$rows")" = died-mid-work ] \
  || fail "an open card older than 24 hours did not mark died-mid-work"
[ "$(awk -F'\t' '$1=="repo"{print $7}' <<<"$rows")" = "" ] \
  || fail "recorded state is current for today, went-stale must be empty"

# a commit on a later calendar day than the recorded state makes the repo went-stale
echo x > "$R/f"
( cd "$R" && git add f && GIT_AUTHOR_DATE="${tomorrow}T12:00:00Z" GIT_COMMITTER_DATE="${tomorrow}T12:00:00Z" \
    git commit -qm "later work" )
[ "$(bash "$TS" "$R" --cards | awk -F'\t' '$1=="repo"{print $7}')" = went-stale ] \
  || fail "a commit on a later day than the recorded state did not mark went-stale"

# a closed card carries its terminal status and no marker
mkcard "2026-09-08.I52.closed.md" done "$now" "$now" "$now"
st="$(bash "$TS" "$R" --cards | awk -F'\t' '$2 ~ /closed.md$/ {print $3 "|" $7}')"
[ "$st" = "done|" ] || fail "a closed card should carry status done and no marker, got '$st'"

# an empty repo reports rather than failing
E="$tmp/empty"; mkdir -p "$E"; git -C "$E" init -q
bash "$TS" "$E" > "$tmp/empty.out" || fail "take-stock failed on a repo with no records"
grep -qi 'none' "$tmp/empty.out" || fail "an empty repo's report does not say none anywhere"
echo "PASS: report names the authoritative handoff and next step, 7-field --cards rows, died-mid-work at 24h, went-stale by day"
