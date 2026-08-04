#!/usr/bin/env bash
# loop-brainstorm absorbs domain modeling (E), keeps "Reading the user" untouched, and wires the
# parking-lot graduation script; the script's dry-run emits one gh issue create per parked item.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
S="$REPO/skills/loop-brainstorm/SKILL.md"
G="$REPO/scripts/graduate-parking.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -f "$S" ] || fail "loop-brainstorm SKILL missing"
# E: domain modeling absorbed.
grep -Eqi 'glossary|domain model|domain term' "$S" || fail "no domain-modeling / glossary probe"
grep -Eqi 'stress-test|scenario stress' "$S" || fail "no scenario stress-test probe"
# Reading the user block is present and unchanged in spirit (the heading survives).
grep -qi 'Reading the user' "$S" || fail "the Reading the user section was removed"
# Graduation script wired (with preview/confirm) and exists.
grep -q 'graduate-parking.sh' "$S" || fail "brainstorm does not wire the graduation script"
grep -Eqi 'preview|confirm|assent|DEFAULT' "$S" || fail "brainstorm does not preview/confirm before graduating"
[ -x "$G" ] || fail "scripts/graduate-parking.sh missing or not executable"
# Dry-run emits one gh issue create per parked item, labels idea, carries the template + continuation.
TMPB="$(mktemp -d)"; trap 'rm -rf "$TMPB"' EXIT
mkdir -p "$TMPB/config"
# Minimal repo-state.md carrying the graduated-item template fields the script fills in.
cat > "$TMPB/config/repo-state.md" <<'EOF'
Graduated-item issue body template (label the issue `idea`):
<verbatim parking-lot prose from the brief>
---
Source brief:
Graduated: <date>
Restart context: <one line>
EOF
cat > "$TMPB/brief.md" <<'EOF'
## Parking lot

- First parked thread: do the thing later.
- Second parked thread: revisit the other thing.
  Restart context: pick up where the sketch left off.

## Out of scope
EOF
out="$( cd "$TMPB" && GRADUATE_DRY_RUN=1 bash "$G" brief.md )" || fail "graduate-parking dry-run failed"
n="$(printf '%s\n' "$out" | grep -c 'tracker.sh create')"
[ "$n" -eq 2 ] || fail "expected 2 tracker.sh create calls, got $n"
printf '%s\n' "$out" | grep -q -- '--label idea' || fail "graduation does not label issues idea"
printf '%s\n' "$out" | grep -q 'Source brief:' || fail "body missing the Source brief template field"
printf '%s\n' "$out" | grep -q 'Restart context:' || fail "body missing the Restart context template field"
printf '%s\n' "$out" | grep -q 'pick up where the sketch left off' || fail "multi-line continuation dropped from the body"
echo "PASS: loop-brainstorm E absorbed, Reading-the-user intact, graduation previews + dry-runs 2 items with template"
