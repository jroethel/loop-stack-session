#!/usr/bin/env bash
# Check for U07 (port loop-track, loop-auto, handoff, wayfinder). Authored by the orchestrator; the worker does not own this file.
set -uo pipefail
fail() { echo "CHECK FAIL: $*" >&2; exit 1; }
TASKDIR="${TASKDIR:-$PWD}"
cd "$TASKDIR" || fail "no worktree at $TASKDIR"

ALW=ci/reference-allowlist.txt
EMDASH=$(printf '\xe2\x80\x94')

fm_keys() {
  awk 'NR==1 { if ($0 != "---") exit; next } /^---[[:space:]]*$/ { exit } /^[A-Za-z][A-Za-z0-9_-]*:/ { sub(/:.*/, ""); print }' "$1"
}
check_fm() {
  f="$1"; shift
  allowed=" $* "
  keys=$(fm_keys "$f")
  [ -n "$keys" ] || fail "$f has no leading YAML frontmatter block; D7 requires name and description"
  for k in $keys; do
    case "$allowed" in
      *" $k "*) ;;
      *) fail "$f frontmatter carries key '$k', which D7 does not allow for this skill (allowed: $*)" ;;
    esac
  done
  for k in name description; do
    printf '%s\n' "$keys" | grep -qx "$k" || fail "$f frontmatter is missing the required key '$k'"
  done
}

OWNED="skills/loop-track/SKILL.md
skills/loop-auto/SKILL.md
skills/handoff/SKILL.md
skills/handoff/agents/openai.yaml
skills/wayfinder/SKILL.md"

# 1. Ownership audit, over OWNED files only. NOTES is the one sanctioned unowned file.
changed=$(git status --porcelain | awk '{print $NF}')
for f in $changed; do
  case "$f" in
    skills/loop-track/*|skills/loop-auto/*|skills/handoff/*|skills/wayfinder/*|ci/reference-allowlist.txt|NOTES) ;;
    *) fail "scope violation: $f is outside U07's ownership list (four skill directories, the allow-list append, NOTES)" ;;
  esac
done

# 2. All five deliverables exist and are non-trivial.
while IFS= read -r f; do
  [ -s "$f" ] || fail "missing or empty deliverable: $f"
done <<EOF
$OWNED
EOF

# 3. The two retired shell scripts must not have survived the copy (step 1).
for dead in skills/loop-track/loop-track.sh skills/loop-auto/loop-auto.sh; do
  [ -e "$dead" ] && fail "$dead survived the port; step 1 deletes it and the plugin ships no skill executables"
done

# 4. The D3 pre-plugin paragraph, verbatim, in all four SKILL.md files (D3 names them among its eight).
for f in skills/loop-track/SKILL.md skills/loop-auto/SKILL.md skills/handoff/SKILL.md skills/wayfinder/SKILL.md; do
  grep -qF '**Pre-plugin repo check.**' "$f" || fail "$f is missing the D3 pre-plugin detection paragraph (plan lines 158-163)"
  grep -qF 'docs/loop/pointer.md' "$f" || fail "$f never names docs/loop/pointer.md, which every ported skill now reads"
done

# 5. loop-auto: the chain-state mechanism is dead, body AND frontmatter (step 5 and step 7).
if grep -qF 'docs/chain-state.md' skills/loop-auto/SKILL.md; then
  fail "loop-auto/SKILL.md still names docs/chain-state.md, a banned token; step 7 warns it hides in the frontmatter description"
fi
grep -qF 'autonomy-default' skills/loop-auto/SKILL.md \
  || fail "loop-auto/SKILL.md never names the autonomy-default key that replaces the chain-state mechanism"
for gate in ASK STOP BATCH DEFAULT; do
  grep -qF "$gate" skills/loop-auto/SKILL.md \
    || fail "loop-auto/SKILL.md lost the gate class '$gate'; step 6 keeps all four verbatim as policy"
done

# 6. loop-track: the invocation block became direct tracker prose (steps 2 and 3).
grep -qF 'gh issue create' skills/loop-track/SKILL.md \
  || fail "loop-track/SKILL.md never names the direct 'gh issue create' call that replaces the loop-track.sh block"
grep -qF 'docs/loop/conventions.md' skills/loop-track/SKILL.md \
  || fail "loop-track/SKILL.md still points at config/conventions.md instead of docs/loop/conventions.md (step 3)"
if grep -qF 'loop-track.sh' skills/loop-track/SKILL.md; then
  fail "loop-track/SKILL.md still invokes loop-track.sh, which no longer ships"
fi

# 7. handoff: mirrors and lifecycle linting are not ported (step 9).
for tok in 'gen-mirrors.sh' 'lifecycle-lint.sh'; do
  if grep -qF "$tok" skills/handoff/SKILL.md; then
    fail "handoff/SKILL.md still references $tok, which step 9 deletes entirely"
  fi
done
grep -qF 'handoffs-home' skills/handoff/SKILL.md \
  || fail "handoff/SKILL.md never reads the handoffs-home key from docs/loop/pointer.md (step 9)"

# 8. wayfinder: routing defers to loop-drive, and the #44 child-issue claim is corrected (steps 14, 15).
if grep -qF 'config/routing/model-benchmarks.md' skills/wayfinder/SKILL.md; then
  fail "wayfinder/SKILL.md still names config/routing/model-benchmarks.md; step 14 replaces it with prose deferring to loop-drive"
fi
grep -qF 'loop-drive' skills/wayfinder/SKILL.md \
  || fail "wayfinder/SKILL.md never defers routing to the loop-drive skill, which step 14 requires"
grep -qF 'Blocked by:' skills/wayfinder/SKILL.md \
  || fail "wayfinder/SKILL.md never names the 'Blocked by: #N' body convention, which is the step-15 fix for loop-stack-session #44"

# 9. Frontmatter, exactly per the D7 table.
check_fm skills/loop-track/SKILL.md name description
check_fm skills/loop-auto/SKILL.md name description
check_fm skills/handoff/SKILL.md name description argument-hint disable-model-invocation
check_fm skills/wayfinder/SKILL.md name description disable-model-invocation
for f in skills/handoff/SKILL.md skills/wayfinder/SKILL.md; do
  fm_keys "$f" | grep -qx 'disable-model-invocation' || fail "$f is missing the D7 key disable-model-invocation"
done
fm_keys skills/handoff/SKILL.md | grep -qx 'argument-hint' || fail "handoff/SKILL.md is missing the D7 key argument-hint"

# 10. House style and the zero-executables constraint (step 19), over owned files only.
for f in skills/loop-track/SKILL.md skills/loop-auto/SKILL.md skills/handoff/SKILL.md skills/wayfinder/SKILL.md; do
  if grep -qF "$EMDASH" "$f"; then fail "em dash character U+2014 in $f, banned by the global constraints"; fi
done
execs=$(find skills/loop-track skills/loop-auto skills/handoff skills/wayfinder -type f -perm -u+x)
[ -z "$execs" ] || fail "executable files under skills/, which only the receipt helper may be: $execs"

# 11. Allow-list discipline: appends only, each appended line carrying a trailing '# why'.
[ -f "$ALW" ] || fail "$ALW is missing from the base tree; U03 owns and creates it"
alwdiff=$(git diff HEAD -- "$ALW")
dels=$(printf '%s\n' "$alwdiff" | sed -n 's/^-\([^-].*\)$/\1/p')
adds=$(printf '%s\n' "$alwdiff" | sed -n 's/^+\([^+].*\)$/\1/p')
while IFS= read -r line; do
  [ -n "$line" ] || continue
  printf '%s\n' "$adds" | grep -Fxq "$line" \
    || fail "pre-existing allow-list line deleted or rewritten, which is forbidden: $line"
done <<EOF
$dels
EOF
while IFS= read -r line; do
  [ -n "$line" ] || continue
  printf '%s\n' "$line" | grep -qE '^[[:space:]]*#' && continue
  printf '%s\n' "$line" | grep -q '# why' \
    || fail "appended allow-list line carries no trailing '# why' justification: $line"
done <<EOF
$adds
EOF

# 12. The NOTES contract, including the two --help findings step 15 owes the commit message.
[ -s NOTES ] || fail "./NOTES is missing or empty; the output contract requires it"
head -1 NOTES | grep -qE '^AGENT STATUS unit=u07 branch=worktree verdict=self-pass repairs=[0-9]+$' \
  || fail "./NOTES line 1 is not the required AGENT STATUS receipt: $(head -1 NOTES)"
grep -q 'GH/GLAB CHILD-ISSUE FINDINGS:' NOTES \
  || fail "./NOTES carries no 'GH/GLAB CHILD-ISSUE FINDINGS:' line; step 15 owes the orchestrator the two --help observations"

# 13. The task's acceptance command, verbatim from source-plan line 867, exit code captured plainly.
bash ci/structure-check.sh && bash ci/budget-check.sh && claude plugin validate --strict skills
rc=$?
[ "$rc" -eq 0 ] || fail "acceptance command 'bash ci/structure-check.sh && bash ci/budget-check.sh && claude plugin validate --strict skills' exited $rc"

# 14. Export the deliverable BEFORE the worktree is deleted.
git add -A
git diff --cached > /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u07.patch \
  || fail "patch export failed"
[ -s /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u07.patch ] \
  || fail "patch export is empty: no work to harvest"
echo "PASS: u07-track-auto-handoff-wayfinder"
