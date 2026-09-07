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
awk -F'\t' 'NF!=12{exit 3}' <<<"$out" || fail "a row does not have 12 fields"
echo "PASS: json parse, columns, B token, negative join, git card, sanitized title, failed source, 12 fields"
