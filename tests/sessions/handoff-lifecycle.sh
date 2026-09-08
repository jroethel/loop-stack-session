#!/usr/bin/env bash
# handoff-log.sh enumerates a handoff's actions, refuses to consume while any action lacks a
# disposition, appends dispositions to an append-only ## Transitions log rather than mutating a
# status field, archives automatically and announces when the last disposition lands, and
# lifecycle-lint class h flags a consumed-unarchived handoff only on or after lifecycle-lint-since.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
HL="$REPO/scripts/handoff-log.sh"
LINT="$REPO/scripts/lifecycle-lint.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/docs/handoffs" "$tmp/docs/archive" "$tmp/config"
printf 'template-version: 7\nlifecycle-lint-since: 2026-09-08\n' > "$tmp/config/repo-state.md"
h="$tmp/docs/handoffs/2026-09-10.I52.example-handoff.md"
cat > "$h" <<'EOF'
# Handoff: example (#52)

## Next actions

- Run the seam 1 plan.
- Roll template-version 7.

## Notes

- Not an action, a different section.
EOF

[ "$(bash "$HL" actions "$h" | grep -c .)" -eq 2 ] \
  || fail "actions must enumerate exactly the two ## Next actions entries, not the Notes bullet"
[ "$(bash "$HL" state "$h")" = live ] || fail "a handoff with no dispositions is not live"
bash "$HL" consume "$h" 2>/dev/null && fail "consume succeeded with no dispositions present"
bash "$HL" disposition "$h" 1 bogus "x" 2>/dev/null && fail "disposition accepted a value outside executed|superseded"
bash "$HL" disposition "$h" 9 executed "x" 2>/dev/null && fail "disposition accepted an out-of-range action number"

bash "$HL" disposition "$h" 1 executed "seam 1 shipped" || fail "disposition 1 exited non-zero"
grep -q '^## Transitions$' "$h" || fail "disposition did not create a ## Transitions section"
grep -qE '^- [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z action 1 executed - seam 1 shipped$' "$h" \
  || fail "the transition line is not '- <ISO ts> action <n> <disposition> - <note>'"
grep -qE '^status:' "$h" && fail "disposition mutated a status field instead of appending to the log"
bash "$HL" consume "$h" 2>/dev/null && fail "consume succeeded with action 2 still undispositioned"
[ "$(bash "$HL" state "$h")" = live ] || fail "a partially dispositioned handoff is not live"
[ "$(bash "$HL" actions "$h" | awk -F'\t' '$1==1{print $3}')" = executed ] \
  || fail "actions does not report the disposition it just recorded"

out="$(bash "$HL" disposition "$h" 2 superseded "the seam 1 brief replaces it")" || fail "disposition 2 exited non-zero"
[ -f "$h" ] && fail "the last disposition did not archive the handoff automatically"
a="$tmp/docs/archive/2026-09-10.I52.example-handoff.md"
[ -f "$a" ] || fail "the archived handoff is not in docs/archive/"
printf '%s\n' "$out" | grep -q "moved $tmp/docs/handoffs/2026-09-10.I52.example-handoff.md to $tmp/docs/archive/" \
  || fail "the automatic archive was not verbose-announced with the paths exactly as given (archive rule 5)"
[ "$(bash "$HL" state "$a")" = consumed ] || fail "an archived, fully dispositioned handoff is not consumed"
[ "$(grep -c '^- .* action ' "$a")" -eq 2 ] || fail "the transition log is not append-only with both entries"

# class h: a consumed-unarchived handoff dated on/after lifecycle-lint-since is flagged
cp "$a" "$tmp/docs/handoffs/2026-09-10.I52.example-handoff.md"
[ "$(bash "$HL" state "$tmp/docs/handoffs/2026-09-10.I52.example-handoff.md")" = consumed-unarchived ] \
  || fail "a fully dispositioned handoff still in docs/handoffs/ is not consumed-unarchived"
bash "$LINT" "$tmp" > "$tmp/lint.out" 2>/dev/null && fail "lint exited 0 with a consumed-unarchived handoff"
grep -q '^LINT h docs/handoffs/2026-09-10.I52.example-handoff.md:' "$tmp/lint.out" \
  || fail "class h did not flag the consumed-unarchived handoff"

# grandfathering: the same defect dated before lifecycle-lint-since is ignored
mv "$tmp/docs/handoffs/2026-09-10.I52.example-handoff.md" "$tmp/docs/handoffs/2026-09-01.I52.old-handoff.md"
bash "$LINT" "$tmp" > "$tmp/lint2.out" 2>/dev/null
grep -q '^LINT h ' "$tmp/lint2.out" && fail "class h flagged a handoff dated before lifecycle-lint-since"

# absence of the key skips class h entirely (the same absence-skips pattern as class f)
printf 'template-version: 7\n' > "$tmp/config/repo-state.md"
cp "$a" "$tmp/docs/handoffs/2026-09-10.I52.example-handoff.md"
bash "$LINT" "$tmp" > "$tmp/lint3.out" 2>/dev/null
grep -q '^LINT h ' "$tmp/lint3.out" && fail "class h ran with no lifecycle-lint-since key present"

# a live handoff is never flagged
rm -f "$tmp/docs/handoffs"/*.md
printf 'template-version: 7\nlifecycle-lint-since: 2026-09-08\n' > "$tmp/config/repo-state.md"
printf '# H\n\n## Next actions\n\n- one\n' > "$tmp/docs/handoffs/2026-09-11.I52.live-handoff.md"
bash "$LINT" "$tmp" > "$tmp/lint4.out" 2>/dev/null
grep -q '^LINT h ' "$tmp/lint4.out" && fail "class h flagged a live handoff"

# the real corpus shape: a prefix-variant heading with numbered items enumerates, and `all` bulk-dispositions it
h2="$tmp/docs/handoffs/2026-09-12.I52.numbered.md"
printf '# H2\n\n## Next actions, in recommended order\n\n1. First numbered action.\n2. Second numbered action.\n\n## Notes\n\n- not an action\n' > "$h2"
[ "$(bash "$HL" actions "$h2" | grep -c .)" -eq 2 ] \
  || fail "a prefix-variant heading with numbered items must enumerate 2 actions"
bash "$HL" disposition "$h2" all superseded "replaced by the next thread" || fail "bulk disposition exited non-zero"
a2="$tmp/docs/archive/2026-09-12.I52.numbered.md"
[ -f "$a2" ] || fail "bulk disposition of every action did not auto-archive"
[ "$(grep -c '^- .* action [12] superseded' "$a2")" -eq 2 ] || fail "bulk form must write one line per action 1..N"

# zero parsed actions: live until the action 0 bulk line, never vacuously consumed
h3="$tmp/docs/handoffs/2026-09-13.I52.proseonly.md"
printf '# H3\n\n## Next actions\n\nProse only, nothing enumerable.\n' > "$h3"
[ "$(bash "$HL" state "$h3")" = live ] || fail "a section parsing to zero actions must derive live, not vacuously consumed"
bash "$HL" consume "$h3" 2>/dev/null && fail "consume must refuse a zero-action file instead of vacuously succeeding"
bash "$LINT" "$tmp" > "$tmp/lint5.out" 2>/dev/null
grep -q '^LINT h docs/handoffs/2026-09-13' "$tmp/lint5.out" && fail "class h flagged a zero-action live handoff"
bash "$HL" disposition "$h3" all executed "legacy shape" || fail "bulk disposition of a zero-action file exited non-zero"
a3="$tmp/docs/archive/2026-09-13.I52.proseonly.md"
[ -f "$a3" ] || fail "the zero-action bulk path did not archive"
grep -qE '^- .* action 0 executed - legacy shape$' "$a3" || fail "the zero-action bulk line is not the action 0 shape"
[ "$(bash "$HL" state "$a3")" = consumed ] || fail "an archived action-0 file must derive consumed"

# archive-destination collision takes a -2 suffix instead of stranding consumed-unarchived
h4="$tmp/docs/handoffs/2026-09-13.I52.proseonly.md"
printf '# H4\n\n## Next actions\n\nAlso prose only.\n' > "$h4"
bash "$HL" disposition "$h4" all superseded "collision probe" || fail "disposition into a colliding archive name exited non-zero"
[ -f "$tmp/docs/archive/2026-09-13.I52.proseonly-2.md" ] || fail "archive collision did not take the -2 suffix"
echo "PASS: enumeration incl. numbered, consume rejected, append-only log, all-bulk, zero-action live, archive announced, -2 collision, class h -since gate"
