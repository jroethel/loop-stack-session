#!/usr/bin/env bash
# loop-setup: declared-mode structural + behavioral. Covers success criteria 1,2,3,5.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SKILL="$REPO/skills/loop-setup/SKILL.md"
SETUP="$REPO/skills/loop-setup/setup.sh"
FIX="$REPO/tests/repo-state/fixtures/issues.json"
fail() { echo "FAIL: $1" >&2; exit 1; }

# --- structural: SKILL narrates the DECLARED-mode model, not remote-detection guessing ---
[ -f "$SKILL" ]                       || fail "skills/loop-setup/SKILL.md missing"
grep -q  '^name: loop-setup' "$SKILL" || fail "frontmatter name is not loop-setup"
grep -q  'config/repo-state.md' "$SKILL" || fail "loop-setup never writes config/repo-state.md"
grep -qi 'tracker'           "$SKILL" || fail "loop-setup does not narrate the tracker mode"
grep -qi 'idea'              "$SKILL" || fail "loop-setup does not mention the idea label"
grep -q  'scripts/gen-mirrors.sh' "$SKILL" || fail "loop-setup does not cite the mirror regen command"
grep -qi 'scratch' "$SKILL" && fail "loop-setup SKILL still references the dropped .scratch fallback"
echo "structural: PASS"
[ "${LOOP_SETUP_SKIP_BEHAVIOR:-0}" = 1 ] && { echo "PASS: structural only"; exit 0; }
[ -x "$SETUP" ] || fail "skills/loop-setup/setup.sh missing (runnable core)"

# --- criterion 1a: fresh LOCAL setup renders the tracker: key; second run is a clean no-op ---
L="$(mktemp -d)"; trap 'rm -rf "$L"' EXIT
( cd "$L" && git init -q )
( cd "$L" && LOOP_TRACKER_ANSWER=local "$SETUP" </dev/null ) || fail "local setup exited non-zero"
grep -q '^tracker: local' "$L/config/repo-state.md" || fail "local config missing 'tracker: local' key"
# criterion 5: rendered local config discloses BOTH limitations, grep-verifiable
grep -qi 'cross-repo idea search' "$L/config/repo-state.md" || fail "local config omits the cross-repo-search disclosure"
grep -qi 'wayfinder requires'     "$L/config/repo-state.md" || fail "local config omits the wayfinder disclosure"
# second run: no re-ask (stdin closed), exit 0, key not duplicated, still local
( cd "$L" && "$SETUP" </dev/null ) || fail "local setup second run errored (should be idempotent)"
[ "$(grep -c '^tracker:' "$L/config/repo-state.md")" -eq 1 ] || fail "second run duplicated the tracker: key"
grep -q '^tracker: local' "$L/config/repo-state.md" || fail "second run changed the declared mode"

# --- criterion 1b: fresh GITHUB setup renders the key; dry-run skips live gh; second run idempotent ---
G="$(mktemp -d)"; trap 'rm -rf "$L" "$G"' EXIT
( cd "$G" && git init -q && git remote add origin https://example.invalid/x.git )
( cd "$G" && LOOP_TRACKER_ANSWER=github MIRRORS_JSON_FILE="$FIX" "$SETUP" --dry-run-remote </dev/null ) \
  || fail "github (dry-run) setup errored"
grep -q '^tracker: github' "$G/config/repo-state.md" || fail "github config missing 'tracker: github' key"
[ -f "$G/ISSUES.md" ] || fail "github setup did not generate mirrors"
grep -qi 'cross-repo idea search' "$G/config/repo-state.md" && fail "github config wrongly kept the local disclosure"
( cd "$G" && LOOP_TRACKER_ANSWER=github MIRRORS_JSON_FILE="$FIX" "$SETUP" --dry-run-remote </dev/null ) \
  || fail "github setup second run errored"
[ "$(grep -c '^tracker:' "$G/config/repo-state.md")" -eq 1 ] || fail "github second run duplicated the key"

# --- criterion 2: keyless legacy config re-asks and reports remote status; suggests github only when found ---
# 2a: legacy + remote present -> reports the remote URL and suggests tracker: github
LG1="$(mktemp -d)"; trap 'rm -rf "$L" "$G" "$LG1"' EXIT
( cd "$LG1" && git init -q && git remote add origin https://github.com/acme/legacy.git )
mkdir -p "$LG1/config"; printf '# legacy repo-state, no tracker key\nRemote: x\n' > "$LG1/config/repo-state.md"
# the remote report is on STDOUT now, so out1 (stdout capture) genuinely carries it
out1="$( cd "$LG1" && LOOP_TRACKER_ANSWER=github MIRRORS_JSON_FILE="$FIX" "$SETUP" --dry-run-remote </dev/null )" \
  || fail "legacy+remote setup errored"
printf '%s\n' "$out1" | grep -q 'GitHub remote found' || fail "legacy re-ask did not print the remote report on stdout"
printf '%s\n' "$out1" | grep -q 'acme/legacy' || fail "remote report did not name the remote"
printf '%s\n' "$out1" | grep -q 'suggesting tracker: github' || fail "legacy+remote did not suggest tracker: github"
grep -q '^tracker: github' "$LG1/config/repo-state.md" || fail "legacy re-ask did not write the key"
grep -q 'legacy repo-state' "$LG1/config/repo-state.md" || fail "legacy re-ask clobbered existing config content"
# 2b: legacy + NO remote -> reports no-remote on stdout and does NOT suggest github
LG2="$(mktemp -d)"; trap 'rm -rf "$L" "$G" "$LG1" "$LG2"' EXIT
( cd "$LG2" && git init -q )
mkdir -p "$LG2/config"; printf '# legacy repo-state, no tracker key\n' > "$LG2/config/repo-state.md"
out2="$( cd "$LG2" && LOOP_TRACKER_ANSWER=local "$SETUP" </dev/null )" || fail "legacy+no-remote setup errored"
printf '%s\n' "$out2" | grep -q 'No remote found' || fail "legacy no-remote case did not report absence on stdout"
printf '%s\n' "$out2" | grep -q 'suggesting tracker: github' && fail "no-remote case wrongly suggested github"
grep -q '^tracker: local' "$LG2/config/repo-state.md" || fail "legacy no-remote re-ask did not write the key"

# --- criterion 3: tracker: github with gh unauthenticated/absent fails fast, non-zero, naming the prerequisite ---
BIN="$(mktemp -d)"; F3="$(mktemp -d)"; trap 'rm -rf "$L" "$G" "$LG1" "$LG2" "$BIN" "$F3"' EXIT
cat > "$BIN/gh" <<'EOS'
#!/usr/bin/env bash
# unauthenticated stub: auth status fails
[ "$1" = "auth" ] && exit 1
exit 1
EOS
chmod +x "$BIN/gh"
( cd "$F3" && git init -q && git remote add origin https://github.com/acme/x.git )
set +e
err3="$( cd "$F3" && PATH="$BIN:$PATH" LOOP_TRACKER_ANSWER=github "$SETUP" </dev/null 2>&1 )"
rc3=$?
set -e 2>/dev/null || true
[ "$rc3" -ne 0 ] || fail "github mode with unauth gh did NOT fail fast (exit 0)"
printf '%s\n' "$err3" | grep -qi 'gh\|auth' || fail "fail-fast message does not name the gh/auth prerequisite"
echo "PASS: loop-setup declared-mode - criteria 1 (both modes idempotent), 2 (legacy re-ask), 3 (fail-fast), 5 (disclosures)"
