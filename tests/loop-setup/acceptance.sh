#!/usr/bin/env bash
# loop-setup: structural (SKILL.md contract) + behavioral (produces a valid config in a bare repo).
# LOOP_SETUP_SKIP_BEHAVIOR=1 runs structural only.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SKILL="$REPO/skills/loop-setup/SKILL.md"
fail() { echo "FAIL: $1" >&2; exit 1; }

# --- structural ---
[ -f "$SKILL" ]                     || fail "skills/loop-setup/SKILL.md missing"
grep -q  '^name: loop-setup' "$SKILL" || fail "frontmatter name is not loop-setup"
grep -q  'config/repo-state.md' "$SKILL" || fail "loop-setup never writes config/repo-state.md"
grep -qi 'remote'            "$SKILL" || fail "loop-setup does not branch on remote presence"
grep -qi 'idea'             "$SKILL" || fail "loop-setup does not create the idea label"
grep -qi 'scratch'          "$SKILL" || fail "loop-setup missing the local-markdown fallback tracker"
grep -q  'scripts/gen-mirrors.sh' "$SKILL" || fail "loop-setup does not cite the mirror regen command"
echo "structural: PASS"
[ "${LOOP_SETUP_SKIP_BEHAVIOR:-0}" = 1 ] && { echo "PASS: structural only"; exit 0; }

# --- behavioral: run the documented no-remote path in a bare repo, assert a valid config lands ---
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
( cd "$TMP" && git init -q )
SETUP="$REPO/skills/loop-setup/setup.sh"
[ -x "$SETUP" ] || fail "skills/loop-setup/setup.sh missing (runnable core for the executed check)"
( cd "$TMP" && "$SETUP" ) || fail "setup.sh exited non-zero in a bare repo"
[ -f "$TMP/config/repo-state.md" ] || fail "no config/repo-state.md produced in bare repo"
# validate the generated config directly against the same required lanes B1 mandates
for lane in Roadmap Issues Backlog Handoffs Archive; do
  grep -qi "$lane" "$TMP/config/repo-state.md" || fail "generated config missing the '$lane' lane"
done
grep -qi 'fallback\|scratch\|no remote' "$TMP/config/repo-state.md" \
  || fail "bare-repo config did not record the no-remote fallback"

# idempotency: a second run must not error or duplicate
( cd "$TMP" && "$SETUP" ) || fail "setup.sh is not idempotent (second run errored)"
[ "$(grep -c '## *Fallback' "$TMP/config/repo-state.md")" -le 1 ] \
  || fail "re-running setup.sh duplicated config content"

# remote branch exercised without live gh, via the fixture hook
TMP2="$(mktemp -d)"; trap 'rm -rf "$TMP" "$TMP2"' EXIT
( cd "$TMP2" && git init -q && git remote add origin https://example.invalid/x.git )
( cd "$TMP2" && MIRRORS_JSON_FILE="$REPO/tests/repo-state/fixtures/issues.json" "$SETUP" --dry-run-remote ) \
  || fail "setup.sh remote branch (dry-run) errored"
[ -f "$TMP2/ISSUES.md" ] || fail "remote branch did not generate mirrors"
grep -qi 'fallback\|scratch\|no remote' "$TMP2/config/repo-state.md" \
  && fail "remote-repo config wrongly recorded the no-remote fallback"
echo "PASS: loop-setup config generation, idempotency, and remote branch all verified"
