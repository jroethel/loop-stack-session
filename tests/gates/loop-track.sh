#!/usr/bin/env bash
# loop-track: files exactly one tracker issue per invocation, in the right lane (idea / plain
# issue / wayfinder:map), resolving a bare repo name via a filesystem search when not given a path.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
LT="$REPO/skills/loop-track/loop-track.sh"
SKILL="$REPO/skills/loop-track/SKILL.md"
fail() { echo "FAIL: $1" >&2; exit 1; }

[ -x "$LT" ]    || fail "skills/loop-track/loop-track.sh missing or not executable"
[ -f "$SKILL" ] || fail "skills/loop-track/SKILL.md missing"

# skill contract: frontmatter, trigger phrases, and the narrow-scope HARD-GATE
# (description checks flatten hard-wraps first - a folded YAML `>` block can break a phrase
# across lines that a plain grep would miss even though the rendered text reads as one string)
grep -qE '^name:[[:space:]]*loop-track' "$SKILL" || fail "frontmatter name is not loop-track"
flat="$(tr '\n' ' ' < "$SKILL" | tr -s ' ')"
printf '%s' "$flat" | grep -qi 'add as an idea/issue'  || fail "description missing the add-as-idea trigger"
printf '%s' "$flat" | grep -qi 'file this as an idea'  || fail "description missing the file-as-idea trigger"
printf '%s' "$flat" | grep -qi 'wayfinder'             || fail "description missing the wayfinder trigger"
printf '%s' "$flat" | grep -qi 'never writes a memo'   || fail "HARD-GATE does not rule out memo-capture"
printf '%s' "$flat" | grep -qi 'structured body'       || fail "HARD-GATE does not rule out building a real wayfinder map"

# fixture: a local-mode loop-setup'd repo, vendored with the real tracker.sh
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FIX="$TMP/home/fixture-repo"
mkdir -p "$FIX/config" "$FIX/scripts"
printf 'tracker: local\n' > "$FIX/config/repo-state.md"
cp "$REPO/scripts/tracker.sh" "$FIX/scripts/tracker.sh"
chmod +x "$FIX/scripts/tracker.sh"

# by path, plain issue (empty label)
out="$("$LT" "$FIX" "" "Plain issue title" "Plain body")" || fail "plain-issue create failed: $out"
printf '%s\n' "$out" | grep -q "Filed issue #1 in fixture-repo: Plain issue title" \
  || fail "plain-issue announce line wrong: $out"
f="$FIX/docs/issues/001-plain-issue-title.md"
[ -f "$f" ] || fail "plain-issue file not created: $f"
grep -q '^labels: $' "$f" || fail "plain issue carries a label (should be none): $(grep labels: "$f")"

# by path, idea label
out="$("$LT" "$FIX" idea "Idea title" "Idea body")" || fail "idea create failed: $out"
printf '%s\n' "$out" | grep -q "Filed idea #2 in fixture-repo: Idea title" \
  || fail "idea announce line wrong: $out"
grep -q '^labels: idea$' "$FIX/docs/issues/002-idea-title.md" || fail "idea file missing labels: idea"

# by path, wayfinder label - attaches the label only, builds no map structure
out="$("$LT" "$FIX" "wayfinder:map" "Wayfinder title" "Wayfinder body")" || fail "wayfinder create failed: $out"
printf '%s\n' "$out" | grep -q "Filed wayfinder item #3 in fixture-repo: Wayfinder title" \
  || fail "wayfinder announce line wrong: $out"
grep -q '^labels: wayfinder:map$' "$FIX/docs/issues/003-wayfinder-title.md" || fail "wayfinder file missing labels: wayfinder:map"

# bare name resolution: search under $HOME, not cwd, and not a hardcoded path
out="$(cd "$TMP" && HOME="$TMP/home" "$LT" fixture-repo "" "Found by name" "Body")" \
  || fail "bare-name resolution failed: $out"
printf '%s\n' "$out" | grep -q "Filed issue #4 in fixture-repo: Found by name" \
  || fail "bare-name announce line wrong: $out"

# not-found failure names the repo and suggests a path
out="$(cd "$TMP" && HOME="$TMP/home" "$LT" no-such-repo "" "T" "B" 2>&1)" && fail "should have failed for an unknown repo name"
printf '%s\n' "$out" | grep -qi 'no-such-repo' || fail "not-found failure does not name the repo"
printf '%s\n' "$out" | grep -qi 'pass a path'  || fail "not-found failure does not suggest a path"

echo "PASS: loop-track resolves by path and by name, files idea/issue/wayfinder correctly, one issue per call"
