#!/usr/bin/env bash
# lifecycle-lint flags a superseded+unlinked plan (a) and an orphaned brief (b), spares the newest
# cycle and a linked plan, exits 1 iff findings, cd's into its arg, and touches NO live tracker.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; REPO="$(cd "$HERE/../.." && pwd)"; L="$REPO/scripts/lifecycle-lint.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$L" ] || fail "scripts/lifecycle-lint.sh missing or not executable"
BIN="$(mktemp -d)"; SB="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB"' EXIT
GHLOG="$BIN/gh.calls"
cat > "$BIN/gh" <<EOF
#!/usr/bin/env bash
echo "GH CALLED: \$*" >> "$GHLOG"; exit 1
EOF
chmod +x "$BIN/gh"; export PATH="$BIN:$PATH"
mkdir -p "$SB/docs/plans" "$SB/docs/briefs" "$SB/docs/archive"
# NO config/repo-state.md tracker mode in the fixture -> issue-classes must be skipped, not error

# an OLD plan-set, superseded by a newer one, not archived, no open issue -> class (a)
echo "# Old thing plan"   > "$SB/docs/plans/2026-08-04-old-thing-plan.md"
# the newest cycle -> must NOT be flagged
echo "# New thing plan"   > "$SB/docs/plans/2026-08-15-new-thing-plan.md"
# a brief whose plan is already archived -> class (b)
echo "# Orphan brief"     > "$SB/docs/briefs/2026-08-01-orphan-brief.md"
echo "# Orphan plan"      > "$SB/docs/archive/2026-08-01-orphan-plan.md"

out="$("$L" "$SB")"; rc=$?
[ "$rc" -eq 1 ] || fail "lint did not exit 1 with findings (rc=$rc)"
printf '%s\n' "$out" | grep -q '^LINT a .*old-thing'  || fail "did not flag the superseded+unlinked plan"
printf '%s\n' "$out" | grep -q '^LINT b .*orphan-brief' || fail "did not flag the orphaned brief"
printf '%s\n' "$out" | grep -q 'new-thing' && fail "flagged the newest cycle's plan (should be spared)"

# clean tree: remove the two offenders -> exit 0
rm "$SB/docs/plans/2026-08-04-old-thing-plan.md" "$SB/docs/briefs/2026-08-01-orphan-brief.md"
"$L" "$SB" >/dev/null; rc=$?
[ "$rc" -eq 0 ] || fail "lint flagged a clean tree (rc=$rc)"

# (e) context-map pointer resolution: a broken in-repo pointer trips class-e; header prose is spared
mkdir -p "$SB/config"
cat > "$SB/config/context-map.md" <<'MAP'
# Context map
Header prose naming `MEMORY.md` must be ignored - it is not a repo file.
## The index
- Real pointer - `docs/plans/` - resolves.
- Broken pointer - `docs/nope/ghost.md` - does not resolve.
MAP
out="$("$L" "$SB")"; rc=$?
[ "$rc" -eq 1 ] || fail "class-e: lint did not exit 1 with a broken map pointer (rc=$rc)"
printf '%s\n' "$out" | grep -q '^LINT e .*ghost.md' || fail "class-e: did not flag the broken pointer"
printf '%s\n' "$out" | grep -q 'MEMORY.md' && fail "class-e: false-positived on header prose MEMORY.md"
# all pointers resolve -> class-e clean
cat > "$SB/config/context-map.md" <<'MAP'
# Context map
## The index
- Real pointer - `docs/plans/` - resolves.
MAP
"$L" "$SB" >/dev/null; rc=$?
[ "$rc" -eq 0 ] || fail "class-e: lint flagged a map whose pointers all resolve (rc=$rc)"

# (c) idea-lane exemption: an open `idea` issue citing an archived stem is NOT a class-c finding;
# a non-idea open issue citing it still is (local backend, real tracker.sh against the sandbox).
# The GHLOG no-leak assertion below stays valid: everything before this point ran with no mode
# declared, and the local backend added here never shells out to gh.
printf 'tracker: local\n' > "$SB/config/repo-state.md"
mkdir -p "$SB/docs/issues"
echo "# Old thing plan" > "$SB/docs/archive/2026-08-04-old-thing-plan.md"
cat > "$SB/docs/issues/0007-parked-idea.md" <<'ISS'
number: 7
title: parked idea citing old-thing
state: open
labels: idea
updated: 2026-08-18T00:00:00Z
ISS
cat > "$SB/docs/issues/0008-live-ticket.md" <<'ISS'
number: 8
title: live ticket citing old-thing
state: open
labels:
updated: 2026-08-18T00:00:00Z
ISS
out="$("$L" "$SB")"; rc=$?
[ "$rc" -eq 1 ] || fail "class-c: lint did not exit 1 with a non-idea citing issue (rc=$rc)"
printf '%s\n' "$out" | grep -q '^LINT c #8' || fail "class-c: did not flag the non-idea issue"
printf '%s\n' "$out" | grep -q '^LINT c #7' && fail "class-c: flagged the idea-lane issue (should be exempt)"

# (f) filename grammar: key present -> post-cutoff lane docs must match <date>.<tokens>.<slug>.md;
# dash-form post-cutoff names and malformed tokens are flagged; pre-cutoff legacy names are exempt;
# earlier runs in this suite had no key and no LINT f line, covering the absent-key skip.
printf 'filename-grammar-since: 2026-09-01\n' >> "$SB/config/repo-state.md"
mkdir -p "$SB/docs/handoffs" "$SB/docs/reviews"
echo "# Good tokened"  > "$SB/docs/briefs/2026-09-02.I6.good-brief.md"
echo "# Good multi"    > "$SB/docs/plans/2026-09-02.I6.I7.multi-plan.md"
echo "# Good wayfinder" > "$SB/docs/briefs/2026-09-02.W3.wayfinder-brief.md"
echo "# Good plain"    > "$SB/docs/handoffs/2026-09-02.plain-handoff.md"
echo "# Good loop"     > "$SB/docs/plans/2026-09-02.thing-plan_loop.md"
echo "# Old dash form" > "$SB/docs/briefs/2026-09-02-old-form-brief.md"
echo "# Lowercase tok" > "$SB/docs/briefs/2026-09-02.i6.lower-brief.md"
echo "# Pre-cutoff"   > "$SB/docs/briefs/2026-08-01-old-dash-brief.md"
out="$("$L" "$SB")"
printf '%s\n' "$out" | grep -q '^LINT f .*old-form-brief'  || fail "class-f: did not flag the post-cutoff dash-form name"
printf '%s\n' "$out" | grep -q '^LINT f .*lower-brief'     || fail "class-f: did not flag the malformed lowercase token"
printf '%s\n' "$out" | grep -q '^LINT f .*good-brief'      && fail "class-f: flagged a conforming tokened name"
printf '%s\n' "$out" | grep -q '^LINT f .*multi-plan'      && fail "class-f: flagged a conforming multi-token name"
printf '%s\n' "$out" | grep -q '^LINT f .*wayfinder-brief' && fail "class-f: flagged a conforming wayfinder-token name"
printf '%s\n' "$out" | grep -q '^LINT f .*plain-handoff'   && fail "class-f: flagged a conforming untokened dot name"
printf '%s\n' "$out" | grep -q '^LINT f .*plan_loop'       && fail "class-f: flagged a conforming _loop companion name"
printf '%s\n' "$out" | grep -q '^LINT f .*old-dash-brief'  && fail "class-f: flagged a pre-cutoff legacy name (grandfathering broken)"
# one grep per token: listing a token's docs stays a single pipeline
n="$(cd "$SB" && ls docs/briefs | grep '\.I6\.')"
[ "$n" = "2026-09-02.I6.good-brief.md" ] || fail "grep-by-token did not list the tokened brief"

# (g) roadmap R-tags: duplicates and malformed tags flagged; unique-only passes; absence passes
cat > "$SB/ROADMAP.md" <<'RM'
# Roadmap

## 1. First [R1]

## 2. Second [R1]

## 3. Third [R]
RM
out="$("$L" "$SB")"
printf '%s\n' "$out" | grep -q "^LINT g ROADMAP.md: duplicate R-tag '\[R1\]'" || fail "class-g: did not flag the duplicate tag"
printf '%s\n' "$out" | grep -q "^LINT g ROADMAP.md: malformed R-tag '\[R\]'"  || fail "class-g: did not flag the malformed tag"
printf '# Roadmap\n\n## 1. Only [R1]\n' > "$SB/ROADMAP.md"
out="$("$L" "$SB")"
printf '%s\n' "$out" | grep -q '^LINT g' && fail "class-g: flagged a unique-tag roadmap"
rm "$SB/ROADMAP.md"

[ ! -s "$GHLOG" ] || { cat "$GHLOG"; fail "lint leaked to a live tracker with no mode declared"; }
echo "PASS: lifecycle-lint flags a+b, spares newest cycle, exit-codes right, no live-tracker leak"
