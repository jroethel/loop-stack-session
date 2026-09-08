#!/usr/bin/env bash
# board-cards.sh parses the real tracker JSON shape, maps labels to columns, tokenizes idea as B,
# emits a git card per repo, keeps same-numbered issues in different repos distinct, sanitizes a
# tab in a title, and renders a failed tracker source as a single failed card.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/repoA" "$tmp/repoB" "$tmp/repoFail"        # real dirs so the stub's `cd` succeeds

# Stub tracker: emits the gh-shaped JSON array board-cards.sh must parse (cf. tracker.sh do_list).
stub="$tmp/tracker-stub.sh"
cat > "$stub" <<'EOF'
#!/usr/bin/env bash
case "$PWD" in
  *repoA) printf '[{"number":52,"title":"Board\tMVP","labels":[{"name":"agent:working"}],"updatedAt":"2026-09-01T00:00:00Z"},{"number":7,"title":"An idea","labels":[{"name":"idea"}],"updatedAt":"2026-09-01T00:00:00Z"}]\n' ;;
  *repoB) printf '[{"number":52,"title":"Other repo issue","labels":[{"name":"agent:todo"}],"updatedAt":"2026-09-01T00:00:00Z"}]\n' ;;
  *repoFail) exit 4 ;;
esac
EOF
chmod +x "$stub"

now="$(date +%s)"
# Discovery TSV rows: path key root conf incl epoch unc ahead behind
disc() { printf '%s\t%s\tcreate\tyes\tyes\t%s\t%s\t%s\t\n' "$1" "$2" "$now" "$3" "$4"; }
{
  disc "$tmp/repoA" "create/repoA" 2 0
  disc "$tmp/repoB" "create/repoB" 0 0
  disc "$tmp/repoFail" "create/repoFail" 0 0
} > "$tmp/discovery.tsv"

out="$(TRACKER_CMD="$stub" bash "$REPO/scripts/board-cards.sh" < "$tmp/discovery.tsv")" || fail "cards exited non-zero"

col() { awk -F'\t' -v id="$1" '$1==id{print $4}' <<<"$out"; }
tok() { awk -F'\t' -v id="$1" '$1==id{print $6}' <<<"$out"; }
[ "$(col 'create/repoA#I52')" = in-session ] || fail "agent:working should map to in-session"
[ "$(col 'create/repoA#B7')" = backlog ] || fail "idea label should map to backlog with a B token"
[ "$(tok 'create/repoA#B7')" = B7 ] || fail "idea issue should carry a B token"
[ "$(col 'create/repoB#I52')" = next-up ] || fail "agent:todo should map to next-up"
[ -n "$(col 'create/repoA#I52')" ] && [ -n "$(col 'create/repoB#I52')" ] || fail "same-number issues merged across repos"
[ "$(col 'create/repoA#git')" = next-up ] || fail "git card missing or wrong column"
awk -F'\t' '$1=="create/repoA#git" && $9 ~ /uncommitted/{ok=1} END{exit ok?0:3}' <<<"$out" || fail "git position not composed"
awk -F'\t' '$5 ~ /\t/{exit 3}' <<<"$out" || fail "a tab survived into a title field"   # sanitization
[ "$(awk -F'\t' '$1=="create/repoFail#tracker"{print $11}' <<<"$out")" = failed ] || fail "failed tracker source not a failed card"
[ "$(grep -c 'create/repoFail' <<<"$out")" -eq 1 ] || fail "failed source must be exactly one card, never zero or many"
# --- session, handoff, closed-issue sources, the two markers, and the suppression exception ---
mkdir -p "$tmp/repoC"                              # clean, conforming, went-stale: the D9 exception case
disc "$tmp/repoC" "create/repoC" 0 0 >> "$tmp/discovery.tsv"
ts="$tmp/take-stock-stub.sh"
cat > "$ts" <<'EOF'
#!/usr/bin/env bash
today="$(date -u +%Y-%m-%d)"
case "$PWD" in
  *repoA)
    printf 'repo\t\t\t\t\t%s\twent-stale\n' "$today"
    printf 'session\tdocs/sessions/2026-09-05.I52.blocked.md\tblocked\tI52\tBlocked on a fact\t%s\t\n' "$today"
    printf 'session\tdocs/sessions/2026-09-06.I52.stalled.md\topen\t\tStalled work\t%s\tdied-mid-work\n' "$today"
    printf 'session\tdocs/sessions/2026-01-01.I52.ancient.md\tdone\tI52\tAncient done\t2026-01-01\t\n'
    printf 'handoff\tdocs/handoffs/2026-09-07.I52.live.md\tlive\tI52\tLive handoff\t%s\t\n' "$today" ;;
  *repoB)  printf 'repo\t\t\t\t\t%s\t\n' "$today" ;;
  *repoC)  printf 'repo\t\t\t\t\t2026-09-01\twent-stale\n' ;;
esac
EOF
chmod +x "$ts"
cat > "$stub" <<'EOF'
#!/usr/bin/env bash
today="$(date -u +%Y-%m-%d)"
if [ "${1:-}" = list-closed ]; then
  case "$PWD" in
    *repoA) printf '[{"number":40,"title":"Closed lately","labels":[],"updatedAt":"%sT00:00:00Z"},{"number":41,"title":"Closed map","labels":[{"name":"wayfinder:map"}],"updatedAt":"%sT00:00:00Z"}]\n' "$today" "$today" ;;
    *) printf '[]\n' ;;
  esac
  exit 0
fi
case "$PWD" in
  *repoA) printf '[{"number":52,"title":"Board\tMVP","labels":[{"name":"agent:working"}],"updatedAt":"%sT00:00:00Z"},{"number":7,"title":"An idea","labels":[{"name":"idea"}],"updatedAt":"%sT00:00:00Z"},{"number":9,"title":"Fact blocked","labels":[{"name":"blocked-on-fact"}],"updatedAt":"%sT00:00:00Z"}]\n' "$today" "$today" "$today" ;;
  *repoB) printf '[{"number":52,"title":"Other repo issue","labels":[{"name":"agent:todo"}],"updatedAt":"%sT00:00:00Z"}]\n' "$today" ;;
  *repoC) printf '[{"number":3,"title":"repoC issue","labels":[{"name":"agent:todo"}],"updatedAt":"%sT00:00:00Z"}]\n' "$today" ;;
  *repoFail) exit 4 ;;
esac
EOF
chmod +x "$stub"
out="$(TRACKER_CMD="$stub" TAKE_STOCK_CMD="$ts" bash "$REPO/scripts/board-cards.sh" < "$tmp/discovery.tsv")" \
  || fail "cards exited non-zero with the session sources wired"

[ "$(col 'create/repoA#s-2026-09-05.I52.blocked')" = blocked-on-fact ] \
  || fail "a session card closed blocked must land in blocked-on-fact"
[ "$(col 'create/repoA#h-2026-09-07.I52.live')" = handed-off ] \
  || fail "a live handoff must land in handed-off"
[ "$(col 'create/repoA#I40')" = done ] \
  || fail "a closed issue inside the lookback must land in done"
grep -q 'create/repoA#I41' <<<"$out" && fail "a closed wayfinder issue must get no card, as the open path rules"
grep -q 'ancient' <<<"$out" && fail "a done session card outside DONE_LOOKBACK_DAYS must get no card"
[ "$(col 'create/repoA#I9')" = blocked-on-fact ] \
  || fail "the blocked-on-fact label is still being skipped (line 104 un-skip)"
mark() { awk -F'\t' -v id="$1" '$1==id{print $13}' <<<"$out"; }
[ "$(mark 'create/repoA#s-2026-09-06.I52.stalled')" = died-mid-work ] \
  || fail "an unclosed session card older than the threshold must carry the died-mid-work marker"
[ "$(mark 'create/repoA#git')" = went-stale ] \
  || fail "a went-stale repo's git card must carry the went-stale marker"
grep -q 'create/repoB#git' <<<"$out" && fail "a clean conforming repo with a tracker card must stay suppressed"
[ "$(mark 'create/repoC#git')" = went-stale ] \
  || fail "the went-stale exception must bypass clean-conforming suppression so the marker has a carrier"
[ "$(grep -c 'create/repoB#' <<<"$out")" -ge 1 ] || fail "repoB lost its cards"
awk -F'\t' 'NF!=13{exit 3}' <<<"$out" || fail "a row with the session sources wired does not have 13 fields"
[ "$(awk -F'\t' '$1=="create/repoFail#tracker"{print $11}' <<<"$out")" = failed ] \
  || fail "the failed-source health model regressed once take-stock was wired in"
[ "$(grep -c 'create/repoFail' <<<"$out")" -eq 1 ] || fail "a failed source must still be exactly one card"
echo "PASS: json parse, columns, B token, negative join, closed rules, done bound, suppression exception, markers, 13 fields"
