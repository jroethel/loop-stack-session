#!/usr/bin/env bash
# session-card.sh open creates one card carrying the frontmatter key set, log appends timestamped
# ## Log lines, close writes a terminal status from the closed vocabulary and rejects anything else,
# a closed card refuses further logs, a same-day same-slug open takes the -2 suffix, and no field
# names a specific agent harness.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SC="$REPO/scripts/session-card.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cd "$tmp" || fail "cannot cd into the scratch repo"

card="$(bash "$SC" open "Seam 1 recording convention" I52)" || fail "open exited non-zero"
[ -f "$card" ] || fail "open did not print the path of a card it created"
case "$card" in docs/sessions/*.md) ;; *) fail "card is not under docs/sessions/: $card" ;; esac
for k in session_card session token title status closed why next; do
  grep -qE "^$k:" "$card" || fail "frontmatter key '$k' missing from a fresh card"
done
[ "$(grep -c '^status: open$' "$card")" -eq 1 ] || fail "a fresh card is not status: open"
grep -qE '^token: I52$' "$card" || fail "the token argument did not land in the frontmatter"
case "$card" in *.I52.*) ;; *) fail "the token did not land in the filename: $card" ;; esac
grep -q '^## Log$' "$card" || fail "a fresh card has no ## Log section"

bash "$SC" log "ran tests/run.sh, 56 suites green" || fail "log exited non-zero"
bash "$SC" log "second step" || fail "second log exited non-zero"
[ "$(grep -cE '^- [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z ' "$card")" -eq 3 ] \
  || fail "expected 3 log lines (open plus two logs), each '- <ISO ts> <text>'"
grep -q 'ran tests/run.sh, 56 suites green' "$card" || fail "log text did not land in the card"

bash "$SC" close bogus "why" "next" 2>/dev/null && fail "close accepted a status outside the closed vocabulary"
grep -qE '^status: open$' "$card" || fail "a rejected close still mutated the card"
bash "$SC" close handed-off "quota ended the session" "run task 4" || fail "close exited non-zero"
grep -qE '^status: handed-off$' "$card" || fail "close did not write the terminal status"
grep -qE '^closed: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' "$card" \
  || fail "close did not stamp closed: with an ISO-8601 UTC timestamp"
grep -qE '^why: quota ended the session$' "$card" || fail "close did not record why"
grep -qE '^next: run task 4$' "$card" || fail "close did not record next"
[ "$(grep -c '^status:' "$card")" -eq 1 ] || fail "close duplicated the status key"
bash "$SC" log "after close" 2>/dev/null && fail "log accepted an entry on a closed card"

# collision: a second open the same day with the same slug takes the -2 suffix, never overwrites
card2="$(bash "$SC" open "Seam 1 recording convention" I52)" || fail "second open exited non-zero"
[ "$card2" != "$card" ] || fail "second open reused the first card's path"
case "$card2" in *-2.md) ;; *) fail "collision did not take the -2 suffix: $card2" ;; esac
grep -qE '^status: handed-off$' "$card" || fail "second open mutated the first card"
bash "$SC" close parked "collision probe done" "none" || fail "close of the collision card exited non-zero"
grep -qE '^status: parked$' "$card2" || fail "close did not hit the collision card"

# every remaining terminal status is accepted, one open card at a time so each close is unambiguous
for s in done blocked aborted; do
  c="$(bash "$SC" open "status probe $s")" || fail "open for status $s exited non-zero"
  bash "$SC" close "$s" "probe" "none" || fail "close rejected the valid status '$s'"
  grep -qE "^status: $s\$" "$c" || fail "status '$s' did not land in the card"
done

# same-second tie: two open cards with identical session: timestamps make log/close refuse, never guess
ca="$(bash "$SC" open "tie probe")" || fail "tie open a exited non-zero"
cb="$(bash "$SC" open "tie probe")" || fail "tie open b exited non-zero"
case "$cb" in *-2.md) ;; *) fail "tie probe b did not collide into -2: $cb" ;; esac
ts_a="$(grep -E '^session:' "$ca")"
awk -v k="$ts_a" '{sub(/^session:.*/, k)} 1' "$cb" > "$cb.tmp" && mv "$cb.tmp" "$cb"   # force the exact tie
bash "$SC" close done "tie" "none" 2>/dev/null
[ $? -eq 7 ] || fail "close must exit 7 on a same-second open-card tie instead of picking one at random"
grep -qE '^status: open$' "$ca" && grep -qE '^status: open$' "$cb" || fail "a refused close still mutated a card"

grep -qiE 'claude|anthropic|opencode|ringer' "$card2" && fail "a card field names a specific agent harness"
echo "PASS: open/log/close lifecycle, closed status vocabulary, -2 collision suffix, harness-agnostic"
