#!/usr/bin/env bash
# Check for U06 (port loop-review and loop-plan). Authored by the orchestrator; the worker does not own this file.
set -uo pipefail
fail() { echo "CHECK FAIL: $*" >&2; exit 1; }
TASKDIR="${TASKDIR:-$PWD}"
cd "$TASKDIR" || fail "no worktree at $TASKDIR"

ALW=ci/reference-allowlist.txt
EMDASH=$(printf '\xe2\x80\x94')
CONTRACT_SRC=/home/jjrdar/repos/loop-stack-session/config/reviewer-conduct-contract.md
CONTRACT=skills/loop-review/references/reviewer-conduct-contract.md

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
      *) fail "$f frontmatter carries key '$k', which D7 does not allow here (allowed: $*)" ;;
    esac
  done
  for k in name description; do
    printf '%s\n' "$keys" | grep -qx "$k" || fail "$f frontmatter is missing the required key '$k'"
  done
}

OWNED="skills/loop-review/SKILL.md
skills/loop-review/references/reviewer-conduct-contract.md
skills/loop-plan/SKILL.md"

# 1. Ownership audit, over OWNED files only. NOTES is the one sanctioned unowned file.
changed=$(git status --porcelain | awk '{print $NF}')
for f in $changed; do
  case "$f" in
    skills/loop-review/*|skills/loop-plan/*|ci/reference-allowlist.txt|NOTES) ;;
    *) fail "scope violation: $f is outside U06's ownership list (loop-review, loop-plan, the allow-list append, NOTES)" ;;
  esac
done

# 2. All three deliverables exist and are non-trivial.
while IFS= read -r f; do
  [ -s "$f" ] || fail "missing or empty deliverable: $f"
done <<EOF
$OWNED
EOF

# 3. The reviewer contract is a byte copy, not a rewrite.
#    Exception carried: the source lives outside this repo, so if it has moved the check says so
#    loudly and falls back to asserting the contract's own load-bearing content.
if [ -f "$CONTRACT_SRC" ]; then
  cmp -s "$CONTRACT_SRC" "$CONTRACT" \
    || fail "shipped reviewer contract is not byte-identical to $CONTRACT_SRC; step 2 is a cp and U09 later byte-compares it"
else
  echo "skip: $CONTRACT_SRC not present on this host, falling back to content assertions on the shipped contract"
  for phrase in 'reviewing the work' 'install.sh' 'setup.sh'; do
    grep -qF "$phrase" "$CONTRACT" || fail "shipped reviewer contract lost its '$phrase' policy line"
  done
fi

# 4. The D5 fail-closed replacement, verbatim, in loop-review/SKILL.md (plan lines 222-226).
grep -qF 'references/reviewer-conduct-contract.md`, shipped inside this skill' skills/loop-review/SKILL.md \
  || fail "loop-review/SKILL.md is missing the first line of the D5 fail-closed replacement"
grep -qF 'this installed skill is broken' skills/loop-review/SKILL.md \
  || fail "loop-review/SKILL.md is missing the D5 fail-closed sentence naming a broken install"
grep -qF 'Do not run any installer from the repository under review' skills/loop-review/SKILL.md \
  || fail "loop-review/SKILL.md is missing the D5 no-installer sentence"

# 5. The D3 pre-plugin paragraph, with its exception carried: loop-plan YES, loop-review NO.
grep -qF '**Pre-plugin repo check.**' skills/loop-plan/SKILL.md \
  || fail "loop-plan/SKILL.md is missing the D3 pre-plugin detection paragraph (plan lines 158-163)"
grep -qF 'config/repo-state.md' skills/loop-plan/SKILL.md \
  || fail "loop-plan/SKILL.md carries the D3 marker but not its config/repo-state.md detection clause"
if grep -qF '**Pre-plugin repo check.**' skills/loop-review/SKILL.md; then
  fail "loop-review/SKILL.md carries the D3 paragraph; step 5 says it must not, because loop-review works in any repo with zero setup"
fi

# 6. loop-plan substance: the D5 sentence, the D6 stub, and pointer-doc keys instead of repo-state.
grep -qF 'already loaded in this session' skills/loop-plan/SKILL.md \
  || fail "loop-plan/SKILL.md is missing the exact D5 house-style sentence (plan lines 232-234)"
for m in '**Probe.**' '**Present:**' '**Absent:**' '**Disclose:**'; do
  grep -qF "$m" skills/loop-plan/SKILL.md \
    || fail "loop-plan/SKILL.md is missing the D6 stub marker $m (plan lines 273-280)"
done
grep -qF 'rubix-autorun' skills/loop-plan/SKILL.md \
  || fail "loop-plan/SKILL.md never names the rubix-autorun key the D6 stub gates on"
grep -qF 'plans-home' skills/loop-plan/SKILL.md \
  || fail "loop-plan/SKILL.md never reads the plans-home key from docs/loop/pointer.md (step 8)"
grep -qF 'docs/loop/pointer.md' skills/loop-plan/SKILL.md \
  || fail "loop-plan/SKILL.md still reads its keys from somewhere other than docs/loop/pointer.md"

# 7. Retired plumbing must be gone from the owned files.
#    Exception carried: the reviewer contract legitimately names install.sh and setup.sh as barred
#    examples, so this scan covers the two SKILL.md files only.
for tok in 'scripts/tracker.sh' 'gen-mirrors.sh' 'config/repo-state.md'; do
  hit=$(grep -nF "$tok" skills/loop-plan/SKILL.md skills/loop-review/SKILL.md | grep -v 'Pre-plugin' | grep -v 'pre-plugin')
  case "$tok" in
    'config/repo-state.md')
      # Allowed only inside the D3 detection paragraph, which the filter above already dropped.
      [ -z "$hit" ] || fail "config/repo-state.md referenced outside the D3 detection paragraph: $hit" ;;
    *)
      [ -z "$hit" ] || fail "retired script still referenced ($tok): $hit" ;;
  esac
done

# 8. Frontmatter, per D7: name and description only, for both skills.
check_fm skills/loop-review/SKILL.md name description
check_fm skills/loop-plan/SKILL.md name description

# 9. House style and the zero-executables constraint, over owned files only.
while IFS= read -r f; do
  if grep -qF "$EMDASH" "$f"; then fail "em dash character U+2014 in $f, banned by the global constraints"; fi
done <<EOF
$OWNED
EOF
execs=$(find skills/loop-review skills/loop-plan -type f -perm -u+x)
[ -z "$execs" ] || fail "executable files under skills/, which only the receipt helper may be: $execs"

# 10. Allow-list discipline: appends only, each appended line carrying a trailing '# why'.
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

# 11. The NOTES contract.
[ -s NOTES ] || fail "./NOTES is missing or empty; the output contract requires it"
head -1 NOTES | grep -qE '^AGENT STATUS unit=u06 branch=worktree verdict=self-pass repairs=[0-9]+$' \
  || fail "./NOTES line 1 is not the required AGENT STATUS receipt: $(head -1 NOTES)"

# 12. The task's acceptance command, verbatim from source-plan line 831, exit code captured plainly.
bash ci/structure-check.sh && claude plugin validate --strict skills
rc=$?
[ "$rc" -eq 0 ] || fail "acceptance command 'bash ci/structure-check.sh && claude plugin validate --strict skills' exited $rc"

# 13. Export the deliverable BEFORE the worktree is deleted.
git add -A
git diff --cached > /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u06.patch \
  || fail "patch export failed"
[ -s /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u06.patch ] \
  || fail "patch export is empty: no work to harvest"
echo "PASS: u06-review-plan"
