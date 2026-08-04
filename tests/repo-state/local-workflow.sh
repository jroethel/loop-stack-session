#!/usr/bin/env bash
# Criterion 4: the whole local-mode workflow - setup, create issues, regenerate mirrors,
# graduate a brief's parking lot - runs to exit 0 with gh proven UNCALLED, and the mirrors
# render from the local files with labels intact.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SETUP="$REPO/skills/loop-setup/setup.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }

# gh stub at the FRONT of PATH that records every call and fails: if any step touches gh, we catch it.
BIN="$(mktemp -d)"; SB="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB"' EXIT
GHLOG="$BIN/gh.calls"
cat > "$BIN/gh" <<EOF
#!/usr/bin/env bash
echo "GH CALLED: \$*" >> "$GHLOG"
exit 1
EOF
chmod +x "$BIN/gh"
export PATH="$BIN:$PATH"

cd "$SB" && git init -q     # NO remote: a deliberately-off-GitHub repo

# 1. setup in local mode (declared, not detected)
LOOP_TRACKER_ANSWER=local "$SETUP" </dev/null || fail "local setup exited non-zero"
grep -q '^tracker: local' config/repo-state.md || fail "setup did not declare tracker: local"
[ -x scripts/tracker.sh ]    || fail "setup did not install scripts/tracker.sh into the local repo"
[ -x scripts/gen-mirrors.sh ] || fail "setup did not install scripts/gen-mirrors.sh into the local repo"

# 2. create issues directly through the seam (one plain, one idea)
scripts/tracker.sh create --label bug  --title "Crash on empty input" --body "repro steps" >/dev/null \
  || fail "tracker.sh create (bug) failed"
scripts/tracker.sh create --label idea --title "Cross-repo digest idea" --body "an idea" >/dev/null \
  || fail "tracker.sh create (idea) failed"

# 3. regenerate mirrors from the local files
scripts/gen-mirrors.sh . || fail "gen-mirrors.sh failed in local mode"
grep -Eq '^\| *1 *\|' ISSUES.md  || fail "bug issue #1 did not render into ISSUES.md"
grep -Eq '^\| *2 *\|' BACKLOG.md  || fail "idea issue #2 did not render into BACKLOG.md"
grep -q 'bug'  ISSUES.md  || fail "labels lost: 'bug' not in ISSUES.md"
grep -q 'idea' BACKLOG.md || fail "labels lost: 'idea' not in BACKLOG.md"

# 4. graduate a brief's parking lot into local backlog issues
cat > brief.md <<'EOS'
## Parking lot

- A parked local thread: revisit the enrichment idea later.

## Out of scope
EOS
"$REPO/scripts/graduate-parking.sh" brief.md || fail "graduate-parking.sh failed in local mode"
grep -Rql 'revisit the enrichment idea later' docs/issues/ \
  || fail "graduated parking item did not land as a local issue file"

# THE criterion: not one gh invocation across the entire workflow
[ ! -s "$GHLOG" ] || { echo "gh was invoked during the local workflow:"; cat "$GHLOG"; fail "local workflow is not gh-free"; }
echo "PASS: full local-mode workflow (setup->create->mirrors->graduate) ran to exit 0 with zero gh calls and labels intact"
