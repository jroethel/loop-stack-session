#!/usr/bin/env bash
# Import (criterion 2): the sweep runs in all three modes, scanning the repo root plus the
# standard and --scan roots, offering each issue-shaped/keyword .md for import, inferring the
# label, and never listing excluded dirs.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SETUP="$REPO/skills/loop-setup/setup.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$SETUP" ] || fail "setup.sh missing"

# ---------- scenario A: accept-all imports every candidate, skips every excluded path ----------
A="$(mktemp -d)"; EXTRA="$(mktemp -d)"; trap 'rm -rf "$A" "$EXTRA"' EXIT
( cd "$A" && git init -q )

# a live tracker issue already exists (its home docs/issues/ is excluded from the scan)
mkdir -p "$A/docs/issues"
cat > "$A/docs/issues/001-live.md" <<'EOS'
---
number: 1
title: live issue
labels: bug
state: open
updated: 2026-08-04T00:00:00Z
---
MARKER_LIVE body
EOS

# candidates in each standard root
mkdir -p "$A/docs/plans" "$A/.planning" "$A/.ralph" "$A/.scratch/old/issues"
# docs/plans/ is a governed lane, not a scan root: this fixture is exercised as an EXCLUSION
# (MARKER_PLAN below), because the Archive-and-graduation rules own plan and brief archival.
cat > "$A/docs/plans/big-plan.md" <<'EOS'
# Big plan
Label: idea
MARKER_PLAN
EOS
cat > "$A/docs/notes.md" <<'EOS'
# Some notes
Status: open
MARKER_NOTES
EOS
printf '# Next up\nMARKER_NEXT\n'   > "$A/.planning/next.md"
printf '# Todo list\nMARKER_TODO\n' > "$A/.ralph/todo.md"
cat > "$A/.scratch/old/issues/001-fix-thing.md" <<'EOS'
# Fix the thing
Label: bug
MARKER_SCRATCH
EOS
# a frontmatter-shaped prior-local issue (no # H1, no Label: line - title/labels live in frontmatter)
cat > "$A/.scratch/old/issues/002-frontmatter.md" <<'EOS'
---
number: 7
title: Frontmatter issue title
labels: idea
state: open
updated: 2026-08-04T00:00:00Z
---
MARKER_FM body content
EOS
printf '# Extra root issue\nMARKER_EXTRA\n' > "$EXTRA/extra-plan.md"

# excluded paths that WOULD be candidates but must never be listed
mkdir -p "$A/docs/handoffs" "$A/docs/reviews" "$A/docs/briefs" "$A/docs/archive"
printf '# Handoff plan\nStatus: open\nMARKER_HANDOFF\n'  > "$A/docs/handoffs/h.md"
printf '# Review plan\nStatus: open\nMARKER_REVIEW\n'    > "$A/docs/reviews/r-batch-review.md"
printf '# Brief plan\nStatus: open\nMARKER_BRIEF\n'      > "$A/docs/briefs/b.md"
printf '# Archived plan\nStatus: open\nMARKER_ARCHIVE\n' > "$A/docs/archive/a.md"
printf '# Issues plan\nStatus: open\nMARKER_MIRROR\n'    > "$A/docs/ISSUES.md"

out="$( cd "$A" && LOOP_ASSUME_YES=1 LOOP_TRACKER_ANSWER=local "$SETUP" --scan "$EXTRA" </dev/null )" \
  || fail "import setup (accept-all) errored"

# every candidate landed as a tracker issue
for m in MARKER_NOTES MARKER_NEXT MARKER_TODO MARKER_SCRATCH MARKER_FM MARKER_EXTRA; do
  grep -Rq "$m" "$A/docs/issues/" || fail "candidate $m was not imported into docs/issues/"
done
# label inference: the Label: bug candidate produced a labels: bug issue
grep -Rl 'MARKER_SCRATCH' "$A/docs/issues/" | head -1 | xargs grep -q '^labels: bug' \
  || fail "import did not infer 'bug' from the Label: line"
# frontmatter-shaped candidate: title/labels come from frontmatter, old frontmatter stripped from body
fmfile="$(grep -Rl 'MARKER_FM' "$A/docs/issues/" | head -1)"
[ -n "$fmfile" ] || fail "frontmatter candidate MARKER_FM was not imported"
grep -q '^title: Frontmatter issue title' "$fmfile" || fail "frontmatter title not carried into the imported issue"
grep -q '^labels: idea' "$fmfile"                    || fail "frontmatter labels not inferred into the imported issue"
grep -q '2026-08-04T00:00:00Z' "$fmfile"             && fail "old frontmatter leaked into the imported body"
# a no-label candidate still imports (writes an empty labels: line, no crash)
grep -Rl 'MARKER_NEXT' "$A/docs/issues/" | head -1 | xargs grep -q '^labels:' \
  || fail "no-label candidate did not import with a labels: line"
# excluded content is never imported (MARKER_PLAN: docs/plans/ is the governed plan lane)
for m in MARKER_PLAN MARKER_HANDOFF MARKER_REVIEW MARKER_BRIEF MARKER_ARCHIVE MARKER_MIRROR; do
  grep -Rq "$m" "$A/docs/issues/" && fail "excluded path content $m was wrongly imported"
done
# accept-all also accepted the archive offers, so every in-tree candidate now lives in docs/archive/
for b in notes.md next.md todo.md 001-fix-thing.md 002-frontmatter.md; do
  [ -f "$A/docs/archive/$b" ] || fail "imported candidate $b was not archived"
done
[ -f "$A/docs/plans/big-plan.md" ] || fail "the excluded plan-lane fixture was moved or deleted"
# the out-of-tree --scan candidate is imported but NEVER archived: no offer reaches outside the repo
[ -f "$EXTRA/extra-plan.md" ] \
  || fail "the out-of-tree --scan candidate was moved out of its own directory"
# the live tracker home is not re-imported (MARKER_LIVE still appears in exactly one file)
[ "$(grep -Rl 'MARKER_LIVE' "$A/docs/issues/" | wc -l | tr -d ' ')" -eq 1 ] \
  || fail "live tracker issue was re-imported (duplicated)"

# ---------- scenario B: decline-all imports nothing ----------
B="$(mktemp -d)"; trap 'rm -rf "$A" "$EXTRA" "$B"' EXIT
( cd "$B" && git init -q )
mkdir -p "$B/docs"
printf '# A plan\nLabel: idea\nMARKER_DECLINE\n' > "$B/docs/decline-plan.md"
( cd "$B" && LOOP_ASSUME_NO=1 LOOP_TRACKER_ANSWER=local "$SETUP" </dev/null >/dev/null ) \
  || fail "import setup (decline-all) errored"
grep -Rq 'MARKER_DECLINE' "$B/docs/issues/" 2>/dev/null \
  && fail "declined candidate was imported anyway"

echo "PASS: import - standard + --scan roots offered, labels inferred, excluded dirs never imported, decline skips"
