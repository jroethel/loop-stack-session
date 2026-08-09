#!/usr/bin/env bash
# gen-mirrors.sh discloses GitLab as the source of truth in gitlab mode, and still renders the
# lane split (idea -> BACKLOG.md, everything else -> ISSUES.md) from gh-shaped JSON.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
GEN="$REPO/scripts/gen-mirrors.sh"
TRK="$REPO/scripts/tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$GEN" ] || fail "scripts/gen-mirrors.sh missing or not executable"

SB="$(mktemp -d)"; trap 'rm -rf "$SB"' EXIT
mkdir -p "$SB/scripts" "$SB/config"
cp "$GEN" "$SB/scripts/gen-mirrors.sh"; chmod +x "$SB/scripts/gen-mirrors.sh"
cp "$TRK" "$SB/scripts/tracker.sh";     chmod +x "$SB/scripts/tracker.sh"
printf 'tracker: gitlab\n' > "$SB/config/repo-state.md"

cat > "$SB/issues.json" <<'EOS'
[{"number":7,"title":"a backlog item","labels":[{"name":"idea"}],"updatedAt":"2026-08-01T00:00:00Z"},
 {"number":4,"title":"a plain issue","labels":[],"updatedAt":"2026-07-01T00:00:00Z"},
 {"number":9,"title":"the map","labels":[{"name":"wayfinder:map"}],"updatedAt":"2026-08-02T00:00:00Z"}]
EOS

( cd "$SB" && MIRRORS_JSON_FILE=./issues.json ./scripts/gen-mirrors.sh . >/dev/null ) \
  || fail "gen-mirrors.sh failed in gitlab mode"

grep -q 'source of truth: GitLab issues' "$SB/ISSUES.md" \
  || fail "ISSUES.md does not disclose GitLab as the source of truth"
grep -q 'source of truth: GitLab issues' "$SB/BACKLOG.md" \
  || fail "BACKLOG.md does not disclose GitLab as the source of truth"
grep -q 'GitHub issues' "$SB/ISSUES.md" && fail "gitlab-mode mirror still claims GitHub"

grep -q '| 4 | a plain issue' "$SB/ISSUES.md"   || fail "unlabelled issue missing from ISSUES.md"
grep -q '| 7 | a backlog item' "$SB/BACKLOG.md" || fail "idea issue missing from BACKLOG.md"
grep -q '| 7 |' "$SB/ISSUES.md"  && fail "idea issue leaked into ISSUES.md"
grep -q '| 9 |' "$SB/ISSUES.md"  && fail "wayfinder issue leaked into ISSUES.md"
grep -q '| 9 |' "$SB/BACKLOG.md" && fail "wayfinder issue leaked into BACKLOG.md"

# github and local disclosures are unchanged
printf 'tracker: github\n' > "$SB/config/repo-state.md"
( cd "$SB" && MIRRORS_JSON_FILE=./issues.json ./scripts/gen-mirrors.sh . >/dev/null ) || fail "github regen failed"
grep -q 'source of truth: GitHub issues' "$SB/ISSUES.md" || fail "github disclosure regressed"
printf 'tracker: local\n' > "$SB/config/repo-state.md"
( cd "$SB" && MIRRORS_JSON_FILE=./issues.json ./scripts/gen-mirrors.sh . >/dev/null ) || fail "local regen failed"
grep -q 'source of truth: docs/issues/ local tracker' "$SB/ISSUES.md" || fail "local disclosure regressed"

echo "PASS: gen-mirrors gitlab disclosure"
