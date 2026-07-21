#!/usr/bin/env bash
# Acceptance harness for loop-review.
#   Layer A (structural): deterministic greps over SKILL.md - no model calls. Drives RED; cheap to re-run.
#   Layer B (behavioral): one real headless review per fixture - costs a few model turns, some LLM variance.
# Exits 0 only if both layers pass. LOOP_REVIEW_SKIP_BEHAVIOR=1 runs layer A alone.
# NOTE: not -e. Each check handles its own failure so the message always prints (rubix B6).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SKILL="$REPO/skills/loop-review/SKILL.md"
fail() { echo "FAIL: $1" >&2; exit 1; }

# ---- Layer A: structural (deterministic, no model calls) ----
[ -f "$SKILL" ]                        || fail "skills/loop-review/SKILL.md missing"
grep -q  '^name: loop-review'   "$SKILL" || fail "frontmatter name is not loop-review"
grep -qi 'no spec available'    "$SKILL" || fail "SKILL.md never defines the no-spec wording"
grep -qi 'matched by branch name' "$SKILL" || fail "SKILL.md missing the branch-match disclosure phrasing"
grep -qi 'Fowler'               "$SKILL" || fail "SKILL.md missing the Fowler baseline"
grep -qi 'Mysterious Name'      "$SKILL" || fail "SKILL.md missing the smell baseline body"
grep -Eqi '## +Spec'            "$SKILL" || fail "SKILL.md does not mandate a ## Spec section"
grep -Eqi '## +Standards'       "$SKILL" || fail "SKILL.md does not mandate a ## Standards section"
echo "structural: PASS"
[ "${LOOP_REVIEW_SKIP_BEHAVIOR:-0}" = 1 ] && { echo "PASS: structural only (behavior skipped)"; exit 0; }

# ---- Layer B: behavioral (real headless reviews) ----
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
bash "$HERE/build-fixtures.sh" "$TMP" >/dev/null || fail "fixture build failed"

# --dangerously-skip-permissions: this runs ONLY against the throwaway temp repos built above,
# and the skill is read-only in intent (git-read, Read, Grep, Agent). Never point it at a real repo.
run_review() {  # $1 = repo dir -> prints report to stdout
  ( cd "$1" && claude -p "/loop-review base" --dangerously-skip-permissions )
}

# Capture without aborting so a CLI non-zero exit yields our message, not a silent die (rubix B6).
WITH="$(run_review "$TMP/with-spec")" || fail "with-spec review did not run (claude exited non-zero)"
NO="$(run_review   "$TMP/no-spec")"   || fail "no-spec review did not run (claude exited non-zero)"
[ -n "$WITH" ] || fail "with-spec produced an empty report"
[ -n "$NO" ]   || fail "no-spec produced an empty report"

# with-spec: discloses the BRANCH-MATCHED money plan, and NOT the newer unrelated widget decoy (rubix A5)
grep -qi '2099-01-01-money-plan.md' <<<"$WITH" || fail "did not disclose the money plan as spec source"
grep -qi 'widget-plan'              <<<"$WITH" && fail "resolved the wrong (newer, unrelated) plan"
# disclosure precedes the first axis section - basis before findings (rubix B4)
d_line="$(grep -ni 'spec source' <<<"$WITH" | head -1 | cut -d: -f1)"
s_line="$(grep -ni '## *Spec'    <<<"$WITH" | head -1 | cut -d: -f1)"
{ [ -n "$d_line" ] && [ -n "$s_line" ] && [ "$d_line" -lt "$s_line" ]; } \
    || fail "disclosure block does not precede the ## Spec section"
# two axes present and separate
grep -qi '## *Standards' <<<"$WITH" || fail "no ## Standards section (with-spec)"
# Spec axis: catches the in-diff missing requirement AND cites the spec line (ValueError appears only in the spec)
grep -qi 'negativ'    <<<"$WITH" || fail "Spec axis missed the negative-input requirement"
grep -qi 'ValueError' <<<"$WITH" || fail "Spec finding does not cite the spec line (no ValueError)"
# Spec axis: catches the scope-creep flag (rubix B9)
grep -qi 'export-json' <<<"$WITH" || fail "Spec axis missed the --export-json scope creep"
# Standards axis: names the smell AND the symbol `d` on one finding line (rubix B3).
# Requiring both on a line rejects the baseline-definition echo (which has no lone `d`) and plain prose,
# while allowing words between the label and the symbol in either order.
grep -Eqi 'mysterious name.*\bd\b|\bd\b.*mysterious name' <<<"$WITH" \
    || fail "Standards axis did not flag \`d\` as a Mysterious Name"

# no-spec: NOT-FOUND warning wording (rubix A6), Standards axis still delivers a concrete finding (rubix B3)
grep -qi 'no spec available'       <<<"$NO" || fail "no-spec run did not report 'no spec available'"
grep -qi 'not found automatically' <<<"$NO" || fail "no-spec run did not warn 'not found' vs 'confirmed none'"
grep -qi '## *Standards'           <<<"$NO" || fail "no-spec run dropped the Standards axis"
grep -Eqi 'mysterious name.*\bd\b|\bd\b.*mysterious name' <<<"$NO" \
    || fail "no-spec Standards axis produced no concrete finding"

echo "PASS: axes, disclosure ordering, spec citation, scope creep, and no-spec warning all verified"
