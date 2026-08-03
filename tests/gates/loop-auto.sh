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
grep -qi 'loop-auto'          "$CMD"   || fail "managed CLAUDE.md block missing the /loop-auto pointer"
for t in ASK STOP BATCH DEFAULT; do
  grep -q "$t" "$SKILL" || fail "autonomy rules do not cover the $t class (protocol home is the skill)"
done
grep -qi 'reversal'           "$SKILL" || fail "batch-review format does not require a reversal path"
grep -qi 'never.*Fable\|Fable.*never' "$SKILL" || fail "continuation rule missing the never-spawn-Fable clause"
grep -qi 'never a worker\|never.*spawns it' "$CMD" || fail "managed block missing the ambient never-a-worker invariant"

# worked sample batch-review exists and distinguishes reversal by gate type
[ -f "$SAMPLE" ] || fail "no worked sample batch-review for checkpoint 4 to judge"
grep -qi 'reversal\|revert\|re-run' "$SAMPLE" || fail "sample batch-review names no reversal path"
grep -qi 'BATCH'   "$SAMPLE" || fail "sample batch-review lacks a BATCH entry"
grep -qi 'DEFAULT' "$SAMPLE" || fail "sample batch-review lacks a DEFAULT entry"

# --- build-wave additions: live disclaimer flip, per-repo default, status display ---
# The staged/intent-only disclaimer is gone from the skill; live-consumption language is present.
grep -Eqi 'records intent only|not yet live|staged, not yet live' "$SKILL" \
  && fail "loop-auto SKILL still says the knob is staged/intent-only after consumption went live"
grep -Eqi 'consumption is live|now governs|the knob is live' "$SKILL" \
  || fail "loop-auto SKILL does not state consumption is live"
grep -Eqi 'repo default|this repo|inherit' "$SKILL" || fail "SKILL missing the per-repo default ask"
grep -q 'default' "$LA" || fail "loop-auto.sh has no default subcommand"
grep -q 'status' "$LA" || fail "loop-auto.sh has no status subcommand"
# Per-repo default round-trips, line-anchored, in config/repo-state.md.
TMP2="$(mktemp -d)"; trap 'rm -rf "$TMP" "$TMP2"' EXIT
( cd "$TMP2" && git init -q && mkdir -p config docs && echo 'docs/chain-state.md' > .gitignore \
    && printf '# Repo State Map\n' > config/repo-state.md \
    && git add -A && git commit -q -m init )
cp "$LA" "$TMP2/loop-auto.sh"
( cd "$TMP2" && bash loop-auto.sh default set auto ) || fail "default set auto failed"
grep -q '^autonomy-default: *auto' "$TMP2/config/repo-state.md" || fail "committed default not stored line-anchored"
[ "$( cd "$TMP2" && bash loop-auto.sh default get )" = "auto" ] || fail "committed default not read back as auto"
# with no runtime chain-state, effective get falls back to the committed default (bare word)
[ "$( cd "$TMP2" && bash loop-auto.sh get )" = "auto" ] || fail "effective get did not fall back to committed default"
# status discloses the effective mode AND its source (human-facing)
st="$( cd "$TMP2" && bash loop-auto.sh status )"
echo "$st" | grep -qi 'auto' || fail "status missing the effective mode"
echo "$st" | grep -Eqi 'default|source|repo' || fail "status does not disclose the mode's source"
# runtime chain-state overrides the committed default
( cd "$TMP2" && bash loop-auto.sh set pause )
[ "$( cd "$TMP2" && bash loop-auto.sh get )" = "pause" ] || fail "runtime chain-state did not override committed default"
# default set reminds the human to commit the tracked config change
( cd "$TMP2" && bash loop-auto.sh default set auto ) | grep -Eqi 'git (add|commit)|commit' \
  || fail "default set does not print the commit reminder"
echo "PASS: knob persists, set never trips its own STOP, STOP fires on real work, rules + sample complete"
