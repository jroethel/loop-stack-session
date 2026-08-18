#!/usr/bin/env bash
# loop-setup in gitlab mode: remote detection and suggestion, config render with the derived
# backlog group, gitlab finalize (host-scoped auth, idea label, gen-mirrors provenance guard),
# repair of a false "Remote: none" line inherited from a local-mode config, gitlab-only lines
# dropped from github and local renders, and the tracker-remote-ack off switch for a deliberate
# mode-versus-remote disagreement.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SETUP="$REPO/skills/loop-setup/setup.sh"
FIX="$REPO/tests/repo-state/fixtures/issues.json"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$SETUP" ] || fail "setup.sh missing"

BIN="$(mktemp -d)"; trap 'rm -rf "$BIN"' EXIT
LOG="$BIN/glab.calls"
cat > "$BIN/glab" <<EOF
#!/usr/bin/env bash
echo "GLAB CALLED: \$*" >> "$LOG"
if [ "\$1" = auth ] && [ "\$2" = status ]; then
  for a in "\$@"; do [ "\$a" = --hostname ] && exit 0; done
  exit 1
fi
if [ "\$1" = issue ] && [ "\$2" = list ]; then exit 0; fi
if [ "\$1" = label ] && [ "\$2" = list ]; then echo "[]"; exit 0; fi
if [ "\$1" = label ] && [ "\$2" = create ]; then exit 0; fi
exit 0
EOF
chmod +x "$BIN/glab"
export PATH="$BIN:$PATH"

# ---------- scenario A: a fresh gitlab repo ----------
A="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A"' EXIT
( cd "$A" && git init -q \
    && git remote add origin 'ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git' )

out="$( cd "$A" && LOOP_TRACKER_ANSWER=gitlab LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>/dev/null )" \
  || fail "gitlab setup exited non-zero"

printf '%s\n' "$out" | grep -q 'GitLab remote found: ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git - suggesting tracker: gitlab' \
  || fail "setup did not report the GitLab remote and suggest gitlab"

[ "$(grep -c '^tracker: gitlab$' "$A/config/repo-state.md")" -eq 1 ] \
  || fail "config does not carry exactly one 'tracker: gitlab' line"
grep -q '^Remote: ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git$' "$A/config/repo-state.md" \
  || fail "config did not record the real remote URL"
grep -q '^backlog-group: university-advancement$' "$A/config/repo-state.md" \
  || fail "config did not derive backlog-group from the remote path (criterion 6)"
TV="$(grep -E '^template-version:' "$REPO/config/repo-state.template.md" | head -1 | sed -E 's/^template-version:[[:space:]]*//; s/[[:space:]]*$//')"
grep -q "^template-version: $TV\$" "$A/config/repo-state.md" \
  || fail "gitlab render carries no current template-version stamp ($TV)"
grep -q '## Local tracker' "$A/config/repo-state.md" \
  && fail "gitlab render kept the Local tracker section"
grep -qi 'local tracker section governs local mode' "$A/config/repo-state.md" \
  && fail "gitlab render kept a dangling pointer to the stripped Local tracker section"
grep -q 'glab issue list --label idea' "$A/config/repo-state.md" \
  || fail "gitlab config does not name the glab per-repo backlog query"
[ -d "$A/docs/handoffs" ] && [ -d "$A/docs/reviews" ] && [ -d "$A/docs/archive" ] \
  || fail "docs homes were not created in gitlab mode"
[ -f "$A/ISSUES.md" ] && [ -f "$A/BACKLOG.md" ] || fail "mirrors were not generated in gitlab mode"

# the auth guard is host-scoped, and the idea label was created
grep -q 'GLAB CALLED: auth status --hostname gitlab.code.rit.edu' "$LOG" \
  || fail "gitlab finalize did not run a --hostname-scoped auth status"
grep -E 'GLAB CALLED: auth status$' "$LOG" && fail "gitlab finalize ran a BARE glab auth status"
grep -q 'GLAB CALLED: label create --name idea' "$LOG" \
  || fail "gitlab finalize did not create the idea label"

# #19: no GitHub source-of-truth text leaks into a gitlab render; the GitLab-correct text is present
grep -q '^GitHub is the single source of truth' "$A/config/repo-state.md" \
  && fail "gitlab render leaked 'GitHub is the single source of truth'"
grep -q 'GitHub (open' "$A/config/repo-state.md" \
  && fail "gitlab render leaked the GitHub Issues lane row"
grep -q 'GitHub (label' "$A/config/repo-state.md" \
  && fail "gitlab render leaked the GitHub Backlog lane row"
grep -q 'gh search issues' "$A/config/repo-state.md" \
  && fail "gitlab render leaked the gh cross-repo backlog view"
grep -q 'gh issue list --label idea --state open' "$A/config/repo-state.md" \
  && fail "gitlab render leaked the gh per-repo fallback"
grep -q '^GitLab is the single source of truth' "$A/config/repo-state.md" \
  || fail "gitlab render did not rewrite the source-of-truth line to GitLab"
grep -q 'GitLab (open' "$A/config/repo-state.md" \
  || fail "gitlab render did not rewrite the Issues lane row to GitLab"

# #26: the cross-repo glab backlog view carries an explicit GITLAB_HOST; the per-repo fallback does not
grep -q 'GITLAB_HOST=gitlab.code.rit.edu glab issue list --group university-advancement --label idea' "$A/config/repo-state.md" \
  || fail "gitlab render did not prefix the cross-repo glab query with GITLAB_HOST"
grep -q 'Per-repo fallback, gitlab: `glab issue list --label idea`' "$A/config/repo-state.md" \
  || fail "gitlab render altered or dropped the host-free per-repo glab fallback"

# #27: setup added docs/chain-state.md to the target repo's .gitignore, and does not duplicate it on re-run
grep -qxF 'docs/chain-state.md' "$A/.gitignore" \
  || fail "setup did not gitignore docs/chain-state.md"
( cd "$A" && LOOP_ASSUME_NO=1 "$SETUP" </dev/null >/dev/null 2>&1 ) \
  || fail "re-run of settled gitlab repo exited non-zero"
[ "$(grep -c '^docs/chain-state\.md$' "$A/.gitignore")" -eq 1 ] \
  || fail "re-running setup duplicated the chain-state gitignore line"

# ---------- scenario B: a gitlab-DECLARED config still carrying the local-tracker Remote ----------
# ---------- placeholder; the re-render must repair the false "Remote: none" line     ----------
# (The declared-local-plus-GitLab-remote disagreement - forge's actual shape - is scenario E's
# job, not this one: here existing_mode is already gitlab, so only reconcile_config's new
# none-prefix fallback is exercised.)
B="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B"' EXIT
( cd "$B" && git init -q \
    && git remote add origin 'ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git' )
mkdir -p "$B/config"
cat > "$B/config/repo-state.md" <<'EOS'
# Repo State Map

template-version: 1

Remote: none (local tracker; see the Local tracker section)

## Local tracker
placeholder
tracker: gitlab
EOS
( cd "$B" && LOOP_ASSUME_YES=1 "$SETUP" </dev/null >/dev/null 2>&1 ) \
  || fail "re-render of the mislabelled config exited non-zero"
grep -q '^Remote: ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git$' "$B/config/repo-state.md" \
  || fail "the false 'Remote: none' line survived the gitlab re-render"
grep -q 'none (local tracker' "$B/config/repo-state.md" \
  && fail "the local-tracker Remote placeholder is still present after re-render"

# ---------- scenario C: a non-inferable remote gets a report and NO suggestion ----------
C="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C"' EXIT
( cd "$C" && git init -q && git remote add origin 'https://git.example.org/team/thing.git' )
out="$( cd "$C" && LOOP_TRACKER_ANSWER=local "$SETUP" </dev/null 2>/dev/null )" \
  || fail "non-inferable-remote setup exited non-zero"
printf '%s\n' "$out" | grep -q 'Remote found: https://git.example.org/team/thing.git - no backend inferred' \
  || fail "a non-github non-gitlab remote was not reported as found-but-uninferable"
printf '%s\n' "$out" | grep -qi 'no remote found' \
  && fail "a repo WITH a remote was reported as having none (the forge bug)"

# the gitlab-only lines are DROPPED from a local render, never substituted into
grep -q '{{BACKLOG_GROUP}}' "$C/config/repo-state.md" && fail "an unsubstituted placeholder leaked into a local render"
grep -q '^backlog-group:' "$C/config/repo-state.md"   && fail "a local render kept the gitlab backlog-group key"
grep -q 'glab issue list' "$C/config/repo-state.md"   && fail "a local render kept the gitlab backlog-view lines"

# ---------- scenario C2: a github render carries the widened sentence and no gitlab lines ----------
C2="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C" "$C2"' EXIT
( cd "$C2" && git init -q && git remote add origin 'https://github.com/acme/x.git' )
( cd "$C2" && LOOP_TRACKER_ANSWER=github MIRRORS_JSON_FILE="$FIX" "$SETUP" --dry-run-remote </dev/null >/dev/null 2>&1 ) \
  || fail "github render run exited non-zero"
grep -q '(github, gitlab, or local)' "$C2/config/repo-state.md" \
  || fail "a github render still says (github or local): setup.sh's hardcoded replacement sentence was never widened"
grep -q '^backlog-group:' "$C2/config/repo-state.md" && fail "a github render kept a bare backlog-group key"
grep -q 'glab issue list' "$C2/config/repo-state.md" && fail "a github render kept the gitlab backlog-view lines"

# ---------- scenario D: an unknown mode answer is rejected ----------
D="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C" "$C2" "$D"' EXIT
( cd "$D" && git init -q )
( cd "$D" && LOOP_TRACKER_ANSWER=bitbucket "$SETUP" </dev/null >/dev/null 2>&1 ) \
  && fail "setup accepted an unknown tracker mode"

# ---------- scenario E: THE FORGE CASE - a declared mode that disagrees with the remote ----------
# This is the shape of ~/claude/forge: tracker: local declared, GitLab remote present.
# Before this fix, setup.sh short-circuited at line 203 and none of the above was reachable there.
E="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C" "$C2" "$D" "$E"' EXIT
( cd "$E" && git init -q \
    && git remote add origin 'ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git' )
mkdir -p "$E/config" "$E/scripts"
cp "$REPO/scripts/tracker.sh" "$E/scripts/tracker.sh"; chmod +x "$E/scripts/tracker.sh"
printf 'template-version: 1\n\nRemote: none (local tracker; see the Local tracker section)\n\ntracker: local\n' \
  > "$E/config/repo-state.md"

# declining the switch leaves everything alone, but the disagreement is still STATED
out="$( cd "$E" && LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>&1 )" || fail "forge-shaped run exited non-zero"
printf '%s\n' "$out" | grep -q 'GitLab remote found' \
  || fail "a repo with a declared mode never reported its remote (the forge bug)"
printf '%s\n' "$out" | grep -q 'declared tracker: local, but the remote is gitlab' \
  || fail "setup stayed silent about a declared mode that disagrees with the remote"
[ "$(grep '^tracker:' "$E/config/repo-state.md")" = "tracker: local" ] \
  || fail "a DECLINED switch changed the tracker mode anyway"

# a declined switch names the off switch, and the ack key silences the offer without silencing
# the remote report - a deliberate tracker: local behind a remote must be recordable
printf '%s\n' "$out" | grep -q 'tracker-remote-ack' \
  || fail "the declined switch did not name the tracker-remote-ack acknowledgment key"
printf 'tracker-remote-ack: gitlab\n' >> "$E/config/repo-state.md"
out="$( cd "$E" && LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>&1 )" || fail "acknowledged run exited non-zero"
printf '%s\n' "$out" | grep -q 'but the remote is' && fail "an acknowledged disagreement was still nagged"
printf '%s\n' "$out" | grep -q 'GitLab remote found' \
  || fail "the ack silenced the remote report too (it must only silence the switch offer)"
sed -i.bak '/^tracker-remote-ack:/d' "$E/config/repo-state.md" && rm -f "$E/config/repo-state.md.bak"

# accepting the switch flips the mode AND corrects the false Remote line on the same run
out="$( cd "$E" && LOOP_ASSUME_YES=1 "$SETUP" </dev/null 2>&1 )" || fail "accepted switch exited non-zero"
[ "$(grep '^tracker:' "$E/config/repo-state.md")" = "tracker: gitlab" ] \
  || fail "an accepted switch did not flip the mode to gitlab (criterion 5)"
grep -q '^Remote: ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git$' "$E/config/repo-state.md" \
  || fail "the false 'Remote: none' line survived the accepted switch"
grep -q '^backlog-group: university-advancement$' "$E/config/repo-state.md" \
  || fail "the switched config did not derive backlog-group"

# a repo whose declared mode AGREES with its remote is never nagged
out="$( cd "$E" && "$SETUP" </dev/null 2>&1 )" || fail "settled forge-shaped re-run exited non-zero"
printf '%s\n' "$out" | grep -q 'but the remote is' && fail "an agreeing repo was offered a mode switch"

# ---------- scenario F: a vendored tracker.sh that rejects the mode fails the run loudly ----------
F="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C" "$C2" "$D" "$E" "$F"' EXIT
( cd "$F" && git init -q && git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git' )
mkdir -p "$F/scripts"
# A pre-gitlab tracker.sh: its mode set rejects 'gitlab'. It must report NO declared mode, so the
# run reaches determine_mode and resolves to gitlab; a stub that echoed a mode would short-circuit
# at line 203 and the call under test would never be reached.
printf '#!/usr/bin/env bash\n# legacy: predates the gitlab backend\nexit 1\n' > "$F/scripts/tracker.sh"
chmod +x "$F/scripts/tracker.sh"
# LOOP_ASSUME_NO declines the drift refresh, so the legacy copy survives to the mode set call.
out="$( cd "$F" && LOOP_TRACKER_ANSWER=gitlab LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>&1 )" \
  && fail "setup exited 0 although the vendored tracker.sh rejected the mode (silent today via >/dev/null)"
printf '%s\n' "$out" | grep -q 'accept the drift refresh' \
  || fail "the mode-set failure did not name the fix (accept the drift refresh and re-run)"

# ---------- scenario G: the gitlab finalize refuses a gen-mirrors.sh that cannot disclose GitLab ----------
# A declined gen-mirrors.sh drift refresh must not produce mirrors claiming GitHub as the source
# of truth on a GitLab repo - the file's entire purpose is disclosure.
G="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C" "$C2" "$D" "$E" "$F" "$G"' EXIT
( cd "$G" && git init -q && git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git' )
mkdir -p "$G/scripts"
printf '#!/usr/bin/env bash\n# legacy: knows only GitHub issues as a remote source\nexit 0\n' \
  > "$G/scripts/gen-mirrors.sh"
chmod +x "$G/scripts/gen-mirrors.sh"
out="$( cd "$G" && LOOP_TRACKER_ANSWER=gitlab LOOP_ASSUME_NO=1 "$SETUP" </dev/null 2>&1 )" \
  && fail "the gitlab finalize exited 0 with a gen-mirrors.sh that would disclose GitHub"
printf '%s\n' "$out" | grep -q 'drift refresh' \
  || fail "the provenance failure did not name the fix (accept the gen-mirrors.sh drift refresh)"

# ---------- scenario H: --dry-run-remote classifies a real origin; only the stub is forced github ----------
# A real GitLab origin under --dry-run-remote must be reported as GitLab, not coerced to github; a
# no-remote dry-run keeps the github stub so existing dry-run tests still see the github suggestion.
H1="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C" "$C2" "$D" "$E" "$F" "$G" "$H1"' EXIT
( cd "$H1" && git init -q \
    && git remote add origin 'ssh://git@gitlab.example.com:2222/grp/repo.git' )
mkdir -p "$H1/config" "$H1/scripts"
cp "$REPO/scripts/tracker.sh" "$H1/scripts/tracker.sh"; chmod +x "$H1/scripts/tracker.sh"
printf 'template-version: 2\n\nRemote: ssh://git@gitlab.example.com:2222/grp/repo.git\n\ntracker: gitlab\n' \
  > "$H1/config/repo-state.md"
out="$( cd "$H1" && LOOP_ASSUME_NO=1 "$SETUP" --dry-run-remote </dev/null 2>/dev/null )" \
  || fail "dry-run-remote on a real GitLab origin exited non-zero"
printf '%s\n' "$out" | grep -q 'GitLab remote found' \
  || fail "dry-run misclassified a real GitLab origin as github"
printf '%s\n' "$out" | grep -q 'GitHub remote found' \
  && fail "dry-run misclassified a real GitLab origin as github"
[ "$(grep '^tracker:' "$H1/config/repo-state.md")" = "tracker: gitlab" ] \
  || fail "dry-run flipped the declared tracker mode"

H2="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C" "$C2" "$D" "$E" "$F" "$G" "$H1" "$H2"' EXIT
( cd "$H2" && git init -q )
out="$( cd "$H2" && LOOP_TRACKER_ANSWER=local "$SETUP" --dry-run-remote </dev/null 2>/dev/null )" \
  || fail "no-remote dry-run exited non-zero"
printf '%s\n' "$out" | grep -q 'GitHub remote found' \
  || fail "no-remote dry-run lost the github stub behavior"

# ---------- scenario I: gitlab mode with no remote prints a creation hint before failing (#25) ----------
I="$(mktemp -d)"; trap 'rm -rf "$BIN" "$A" "$B" "$C" "$C2" "$D" "$E" "$F" "$G" "$H1" "$H2" "$I"' EXIT
( cd "$I" && git init -q )   # no origin remote
out="$( cd "$I" && LOOP_TRACKER_ANSWER=gitlab "$SETUP" </dev/null 2>&1 )" \
  && fail "gitlab setup with no remote exited 0 (should fail-fast on the missing host)"
printf '%s\n' "$out" | grep -q 'glab repo create <name> --private --skipGitInit' \
  || fail "gitlab no-remote path did not print the repo-creation hint"
printf '%s\n' "$out" | grep -q 'git remote add origin' \
  || fail "gitlab no-remote hint did not include the git remote add follow-up"

echo "PASS: loop-setup gitlab mode"
