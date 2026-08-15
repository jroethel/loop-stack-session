#!/usr/bin/env bash
# loop-molt: thin standalone harness-drift audit skill, one implementation with a loop-improve
# delegation entry point. Asserts the trigger phrases, the mandatory ASK constraint-register gate,
# the single-home bins invariant (defined only in the reference), the loop-improve delegation with
# no duplicated audit procedure, and the README row.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
S="$REPO/skills/loop-molt/SKILL.md"
PROTO="$REPO/skills/loop-molt/references/protocol.md"
LI="$REPO/skills/loop-improve/SKILL.md"
RM="$REPO/README.md"
fail() { echo "FAIL: $1" >&2; exit 1; }

[ -f "$S" ]     || fail "loop-molt SKILL missing"
[ -f "$PROTO" ] || fail "vendored protocol reference missing"

# frontmatter: name + trigger phrases
grep -qE '^name:[[:space:]]*loop-molt' "$S" || fail "frontmatter name is not loop-molt"
grep -qi 'molt'          "$S" || fail "description missing the molt trigger"
grep -qi 'harness drift\|harness-drift' "$S" || fail "description missing the harness-drift trigger"

# constraint-register step is present, mandatory, and ASK-class
grep -qE '\[gate:ASK\]' "$S" || fail "no ASK gate in loop-molt (constraint register must be ASK-class)"
grep -qi 'constraint register' "$S" || fail "SKILL does not name the constraint register"

# single-home bins invariant: the four bins are DEFINED only in the reference, never in SKILL.md.
# The brief's check is a case-sensitive grep for the UPPERCASE canonical tokens; SKILL.md points to
# the bins in lowercase prose, the reference owns the uppercase definitions.
grep -q 'PLUMBING' "$PROTO" || fail "reference does not define the bins (no PLUMBING token)"
if grep -q 'PLUMBING\|CHOREOGRAPHY' "$S"; then fail "bin definitions leaked into SKILL.md (must live only in the reference)"; fi
# exactly one file under skills/loop-molt/ carries the uppercase bin tokens
N="$(grep -rl 'PLUMBING\|POLICY\|PREMISE\|CHOREOGRAPHY' "$REPO/skills/loop-molt/" | wc -l | tr -d ' ')"
[ "$N" = "1" ] || fail "bins defined in $N files under skills/loop-molt/ (must be exactly 1: the reference)"

# SKILL points at the reference and at the shared brief pipeline for structural findings
grep -q 'references/protocol.md' "$S" || fail "SKILL does not point at its vendored protocol reference"
grep -q 'brief-pipeline.md' "$S" || fail "SKILL does not route structural findings through the shared brief pipeline"

# drift ledger home named
grep -q 'docs/molt-ledger.md' "$S" || fail "SKILL does not name the drift ledger docs/molt-ledger.md"

# loop-improve delegation: present, and no audit procedure duplicated into loop-improve
grep -qi 'harness-drift' "$LI" || fail "loop-improve missing the --focus harness-drift delegation"
grep -qi 'loop-molt'     "$LI" || fail "loop-improve delegation does not name loop-molt"
if grep -q 'PLUMBING\|CHOREOGRAPHY' "$LI"; then fail "audit bins duplicated into loop-improve (delegation must be a pointer only)"; fi

# README row
grep -q 'loop-molt' "$RM" || fail "README missing a loop-molt row/line"

echo "PASS: loop-molt contracts, single-home bins, delegation, and README row all hold"
