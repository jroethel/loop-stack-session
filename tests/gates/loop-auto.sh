#!/usr/bin/env bash
# Knob persists across "sessions" (a fresh process reads the file); set never dirties its own preflight;
# STOP fires in auto mode on real dirty work.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
LA="$REPO/scripts/loop-auto.sh"
SKILL="$REPO/skills/loop-auto/SKILL.md"
CMD="$REPO/claude-md/fable.md"
SAMPLE="$REPO/docs/reviews/2026-08-02-sample-batch-review.md"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$LA" ]    || fail "scripts/loop-auto.sh missing or not executable"
[ -f "$SKILL" ] || fail "skills/loop-auto/SKILL.md missing"

# set/get persistence in an isolated repo with a .gitignored chain-state (mirrors the real repo)
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
( cd "$TMP" && git init -q && echo 'docs/chain-state.md' > .gitignore \
    && git add .gitignore && git commit -q -m init )
( cd "$TMP" && "$LA" set auto ) || fail "loop-auto set auto failed"
[ -f "$TMP/docs/chain-state.md" ] || fail "chain-state file not written"
grep -qi 'autonomy: *auto' "$TMP/docs/chain-state.md" || fail "mode not persisted as auto"
mode="$( cd "$TMP" && "$LA" get )"    # fresh process = across a session boundary
[ "$mode" = "auto" ] || fail "get returned '$mode', not the persisted 'auto'"

# set immediately followed by preflight must PASS on an otherwise-clean tree
( cd "$TMP" && "$LA" preflight auto ) \
  || fail "preflight auto blocked a clean tree - chain-state.md is tripping its own STOP guard"

# unset default is pause
rm -rf "$TMP/docs"
[ "$( cd "$TMP" && "$LA" get )" = "pause" ] || fail "unset default is not 'pause'"

# STOP invariant: real uncommitted WORK halts even in auto mode
( cd "$TMP" && echo dirt > work.txt )
( cd "$TMP" && "$LA" preflight auto ) && fail "preflight auto passed a DIRTY tree (STOP did not fire)"
( cd "$TMP" && git add -A && git commit -q -m clean )
( cd "$TMP" && "$LA" preflight auto ) || fail "preflight auto blocked a CLEAN tree"

# skill + rules content
grep -q  'loop-auto'          "$SKILL" || fail "skill does not name /loop-auto"
grep -q  'docs/chain-state.md' "$SKILL" || fail "skill does not point at the chain-state source of truth"
grep -qi 'run the rest'       "$SKILL" || fail "skill missing the recognized phrase list"
grep -qi 'intent only\|records intent\|no runtime' "$SKILL" \
  || fail "skill does not disclose the knob is inert until the build wave wires it"
grep -qi '## *Chain autonomy' "$CMD"   || fail "managed CLAUDE.md block missing the Chain autonomy section"
for t in ASK STOP BATCH DEFAULT; do
  grep -q "$t" "$CMD" || fail "autonomy rules do not cover the $t class"
done
grep -qi 'reversal'           "$CMD" || fail "batch-review format does not require a reversal path"
grep -qi 'never.*Fable\|Fable.*never' "$CMD" || fail "continuation rule missing the never-spawn-Fable clause"

# worked sample batch-review exists and distinguishes reversal by gate type
[ -f "$SAMPLE" ] || fail "no worked sample batch-review for checkpoint 4 to judge"
grep -qi 'reversal\|revert\|re-run' "$SAMPLE" || fail "sample batch-review names no reversal path"
grep -qi 'BATCH'   "$SAMPLE" || fail "sample batch-review lacks a BATCH entry"
grep -qi 'DEFAULT' "$SAMPLE" || fail "sample batch-review lacks a DEFAULT entry"
echo "PASS: knob persists, set never trips its own STOP, STOP fires on real work, rules + sample complete"
