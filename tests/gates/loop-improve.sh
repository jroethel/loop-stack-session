#!/usr/bin/env bash
# loop-improve: read-only audit front end sharing loop-brainstorm's convergence half.
# Asserts the greppable deliverable contracts, the anti-drift guard (the brief section table
# lives ONLY in the shared reference), and the README rows.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
S="$REPO/skills/loop-improve/SKILL.md"
PB="$REPO/skills/loop-improve/references/audit-playbook.md"
BP="$REPO/skills/loop-brainstorm/references/brief-pipeline.md"
TS="$REPO/skills/loop-brainstorm/references/tracker-scan.md"
BS="$REPO/skills/loop-brainstorm/SKILL.md"
RM="$REPO/README.md"
fail() { echo "FAIL: $1" >&2; exit 1; }

[ -f "$S" ]  || fail "loop-improve SKILL missing"
[ -f "$PB" ] || fail "vendored audit playbook missing"
[ -f "$BP" ] || fail "shared brief-pipeline reference missing"
[ -f "$TS" ] || fail "shared tracker-scan reference missing"

# frontmatter: name + trigger phrases + read-only + one-brief convergence
grep -qE '^name:[[:space:]]*loop-improve' "$S" || fail "frontmatter name is not loop-improve"
grep -qi 'audit this repo for improvements' "$S" || fail "description missing the audit trigger"
grep -qi 'what should I improve'            "$S" || fail "description missing the what-to-improve trigger"
grep -qi 'improvement brief'                "$S" || fail "description missing the improvement-brief trigger"
grep -qi 'read-only'                        "$S" || fail "skill does not state it is read-only on source code"

# effort knobs: focus argument + quick/standard/deep
grep -qi 'focus' "$S" || fail "no focus argument"
grep -Eqi 'quick[ /].*standard[ /].*deep|quick/standard/deep' "$S" || fail "no quick/standard/deep effort knob"

# findings table: the eight columns in order, plus covered/related renders and definitions
grep -qE 'Finding.*Category.*Impact.*Effort.*Risk.*Confidence.*Tracker' "$S" \
  || fail "findings table header columns wrong or out of order"
grep -q 'covered by #' "$S"  || fail "Tracker column does not render 'covered by #N'"
grep -q 'related: #'   "$S"  || fail "Tracker column does not render 'related: #N'"
grep -qi 'same work'   "$S"  || fail "no definition of covered (same work)"
grep -qi 'different ask' "$S" || fail "no definition of related (same area, different ask)"

# tracker scan wired to the backend-agnostic lister, via the shared reference
grep -q 'scripts/tracker.sh list' "$S" || fail "tracker scan not wired to scripts/tracker.sh list"
grep -q 'tracker-scan.md' "$S" || fail "loop-improve does not point at the shared tracker-scan reference"

# selection gate is ASK; convergence/commit/graduation/supersede are DEFAULT
grep -qE '\[gate:ASK\]'     "$S" || fail "findings-selection round is not tagged ASK"
grep -qE '\[gate:DEFAULT\]' "$S" || fail "convergence steps are not tagged DEFAULT"

# unselected findings ride graduate-parking.sh unchanged; supersede offers a close
grep -q 'graduate-parking.sh'      "$S" || fail "unselected findings do not ride graduate-parking.sh"
grep -qi 'Parking lot'             "$S" || fail "unselected findings are not written to the Parking lot"
grep -q 'scripts/tracker.sh close' "$S" || fail "supersede does not offer scripts/tracker.sh close"
grep -qi 'Supersedes: #'           "$S" || fail "brief does not record the supersede link"

# terminal state hands to /loop-plan
grep -q '/loop-plan' "$S" || fail "terminal state does not name /loop-plan"

# pointer to the shared convergence reference (absolute, resolves under both install styles)
grep -q '~/.claude/skills/loop-brainstorm/references/brief-pipeline.md' "$S" \
  || fail "loop-improve does not point at the shared brief-pipeline reference"

# vendored playbook: attribution + all 9 categories + Finding format, no plans-directory machinery
grep -qi 'MIT'             "$PB" || fail "playbook missing MIT attribution"
grep -q  'vendored 2026-08-08' "$PB" || fail "playbook missing vendored-date attribution"
for cat in Correctness Security Performance 'Test Coverage' 'Tech Debt' Dependencies 'DX' Docs Direction; do
  grep -qi "$cat" "$PB" || fail "playbook missing category: $cat"
done
grep -qi 'Finding format' "$PB" || fail "playbook missing the Finding format"
if grep -qi 'investigate.*plan' "$PB"; then fail "playbook still references /improve plan machinery (rephrase to brief/backlog terms)"; fi
if grep -qi 'those files get committed' "$PB"; then fail "playbook secret rule still names /improve plan files (recast to the brief)"; fi
if grep -qi 'execute the plans'          "$PB"; then fail "playbook DX line still references executing plans (recast to a briefable finding)"; fi

# single-home guards: the SHARED graduation contract now lives in the shared reference as its single
# home (the brief's single-home mandate corrects the earlier "graduation is per-skill" invariant);
# the improve-only supersede-close and the per-skill terminal-state routing do NOT leak into it.
grep -q  'graduate-parking.sh' "$BP" || fail "shared graduation contract missing from the shared reference (its single home)"
if grep -qi 'Supersedes: #'      "$BP"; then fail "improve-only supersede-close leaked into the shared reference (it stays in loop-improve)"; fi
if grep -qi 'frontier-sandwich'   "$BP"; then fail "terminal-state routing leaked into the shared reference (it is a per-skill step)"; fi
if grep -qi 'frontier-sandwich'   "$S";  then fail "loop-improve must not offer frontier-sandwich (its terminal is /loop-plan only)"; fi

# anti-drift: the brief section table lives ONLY in the shared reference.
# Key on 'Three bins: verified' (unique to the table row); the bare phrase 'Known vs guessed'
# legitimately survives in loop-brainstorm Step 2b prose, so it is NOT a safe marker.
grep -q 'Three bins: verified' "$BP" || fail "shared reference is missing the brief section table"
if grep -q 'Three bins: verified' "$BS"; then fail "brief section table duplicated into loop-brainstorm SKILL.md (drift)"; fi
if grep -q 'Three bins: verified' "$S";  then fail "brief section table duplicated into loop-improve SKILL.md (drift)"; fi

# README rows
grep -q 'loop-improve' "$RM" || fail "README missing a loop-improve row/line"

echo "PASS: loop-improve contracts, anti-drift guard, and README rows all hold"
