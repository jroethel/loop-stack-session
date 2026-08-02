#!/usr/bin/env bash
# gen-gate-registry.sh - render the chain skills' gate tags into docs/gate-registry.md,
# and (with --scan-untagged) flag gate-signal lines that lack a covering tag.
# Source of truth is the inline [gate:TYPE] tags in skills/loop-*/SKILL.md; the registry is
# generated, never hand-edited.
# Usage:
#   scripts/gen-gate-registry.sh <repo-root>                  # write docs/gate-registry.md
#   scripts/gen-gate-registry.sh --scan-untagged <repo-root>  # print file:line per untagged
#                                                             #   signal line; exit nonzero if any
set -uo pipefail
fail() { echo "FAIL: $1" >&2; exit 1; }

MODE="gen"
if [ "${1:-}" = "--scan-untagged" ]; then
  MODE="scan"; shift
fi
[ $# -eq 1 ] || fail "usage: $0 [--scan-untagged] <repo-root>"
ROOT="$1"
SKILLS="$ROOT/skills"
[ -d "$SKILLS" ] || fail "skills/ not found under $ROOT"
GEN_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TAB=$'\t'

# Freshness scanner: a line is a candidate only under a `## Step` heading (not before the first
# one, not in a non-Step section, not inside a fenced code block) AND containing a human-handoff
# token. A candidate is COVERED if a [gate:...] tag sits within +/-2 lines or on the governing
# `## Step` heading line. loop-which uses `### N.` headings, so it yields no candidates by design
# (precision over recall - the registry's "tagged gates only" disclosure carries the rest).
# ponytail: fixed token list, substring match; narrow on purpose so a clean scan is meaningful.
scan_one() {
  # $1 = file, $2 = repo-relative path (for output)
  awk -v F="$2" '
    function hastag(s) { return (s ~ /\[gate:(ASK|STOP|BATCH|DEFAULT|none)\]/) }
    BEGIN { in_fence = 0; in_step = 0; cur_hdr = 0 }
    {
      ln[NR] = $0
      if (hastag($0)) tagln[NR] = 1
      if ($0 ~ /^[`]{3,}/) { in_fence = !in_fence; next }   # fence toggle line
      if (in_fence) next
      if ($0 ~ /^## /) {                                    # level-2 heading governs membership
        if ($0 ~ /^## Step/) { in_step = 1; cur_hdr = NR }
        else { in_step = 0; cur_hdr = 0 }
        next
      }
      if (!in_step) next
      stepof[NR] = cur_hdr
      low = tolower($0)
      if (low ~ /askuserquestion/ || low ~ /offer the commit/ || low ~ /want me to commit/ \
          || low ~ /wait for the response/ || low ~ /ask the human/) cand[NR] = 1
    }
    END {
      bad = 0
      for (i = 1; i <= NR; i++) {
        if (!cand[i]) continue
        cov = 0
        for (j = i - 2; j <= i + 2; j++) if (tagln[j]) { cov = 1; break }
        if (!cov && tagln[stepof[i]]) cov = 1
        if (!cov) { printf "%s:%d: %s\n", F, i, ln[i]; bad = 1 }
      }
      exit (bad ? 1 : 0)
    }
  ' "$1"
}

if [ "$MODE" = "scan" ]; then
  rc=0
  for f in "$SKILLS"/loop-*/SKILL.md; do
    [ -f "$f" ] || continue
    scan_one "$f" "skills/${f#"$SKILLS"/}" || rc=1
  done
  exit "$rc"
fi

# --- generation: one row per [gate:ASK|STOP|BATCH|DEFAULT] tag, sorted by type then skill ---
rows="$(mktemp)"; trap 'rm -f "$rows"' EXIT
for f in "$SKILLS"/loop-*/SKILL.md; do
  [ -f "$f" ] || continue
  skill="$(basename "$(dirname "$f")")"
  awk -v SKILL="$skill" -v OFS='\t' '
    function ord(t) {
      if (t == "ASK") return 1
      if (t == "STOP") return 2
      if (t == "BATCH") return 3
      return 4
    }
    function excerpt(s,   t) {
      t = s
      gsub(/`?\[gate:(ASK|STOP|BATCH|DEFAULT|none)\]`?/, "", t)
      gsub(/^[ \t]+|[ \t]+$/, "", t)
      gsub(/\|/, "\\|", t)
      if (length(t) > 75) t = substr(t, 1, 72) "..."
      return t
    }
    {
      rest = $0
      while (match(rest, /\[gate:(ASK|STOP|BATCH|DEFAULT)\]/)) {
        ty = substr(rest, RSTART + 6, RLENGTH - 7)   # text between "[gate:" and "]"
        print ord(ty), SKILL, NR, ty, excerpt($0)
        rest = substr(rest, RSTART + RLENGTH)
      }
    }
  ' "$f" >> "$rows"
done

OUT="$ROOT/docs/gate-registry.md"
mkdir -p "$ROOT/docs"
{
  echo "<!-- generated: $GEN_TIME -->"
  echo "<!-- regenerate: scripts/gen-gate-registry.sh . -->"
  echo "<!-- DO NOT EDIT -->"
  echo "<!-- This registry reflects tagged gates only and is not a completeness guarantee. -->"
  echo ""
  echo "# Gate registry"
  echo ""
  echo "| skill | type | trigger |"
  echo "|---|---|---|"
  sort -t"$TAB" -k1,1n -k2,2 -k3,3n "$rows" | awk -F'\t' '{ printf "| %s | %s | %s |\n", $2, $4, $5 }'
} > "$OUT"
echo "wrote $OUT ($GEN_TIME)"
