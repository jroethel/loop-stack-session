#!/usr/bin/env bash
# Check for U05 (port loop-brainstorm, loop-improve, loop-molt). Authored by the orchestrator; the worker does not own this file.
set -uo pipefail
fail() { echo "CHECK FAIL: $*" >&2; exit 1; }
TASKDIR="${TASKDIR:-$PWD}"
cd "$TASKDIR" || fail "no worktree at $TASKDIR"

ALW=ci/reference-allowlist.txt
EMDASH=$(printf '\xe2\x80\x94')

# Frontmatter key extractor: prints the top-level keys of the leading YAML block.
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

OWNED="skills/loop-brainstorm/SKILL.md
skills/loop-brainstorm/references/brief-pipeline.md
skills/loop-brainstorm/references/one-minute-test.md
skills/loop-brainstorm/references/tracker-scan.md
skills/loop-improve/SKILL.md
skills/loop-improve/references/audit-playbook.md
skills/loop-improve/references/brief-pipeline.md
skills/loop-improve/references/tracker-scan.md
skills/loop-molt/SKILL.md
skills/loop-molt/references/protocol.md
skills/loop-molt/references/brief-pipeline.md"

# 1. Ownership audit, over OWNED files only. NOTES is the one sanctioned unowned file.
changed=$(git status --porcelain | awk '{print $NF}')
for f in $changed; do
  case "$f" in
    skills/loop-brainstorm/*|skills/loop-improve/*|skills/loop-molt/*|ci/reference-allowlist.txt|NOTES) ;;
    *) fail "scope violation: $f is outside U05's ownership list (three skill directories, the allow-list append, NOTES)" ;;
  esac
done

# 2. All eleven deliverables exist and are non-trivial.
while IFS= read -r f; do
  [ -s "$f" ] || fail "missing or empty deliverable: $f"
done <<EOF
$OWNED
EOF

# 3. D5 byte-equality pairs, which step 16's cp commands make true by construction.
cmp -s skills/loop-brainstorm/references/brief-pipeline.md skills/loop-improve/references/brief-pipeline.md \
  || fail "brief-pipeline.md differs between loop-brainstorm and loop-improve; D5 requires byte equality, made by cp"
cmp -s skills/loop-brainstorm/references/brief-pipeline.md skills/loop-molt/references/brief-pipeline.md \
  || fail "brief-pipeline.md differs between loop-brainstorm and loop-molt; D5 requires byte equality, made by cp"
cmp -s skills/loop-brainstorm/references/tracker-scan.md skills/loop-improve/references/tracker-scan.md \
  || fail "tracker-scan.md differs between loop-brainstorm and loop-improve; D5 requires byte equality, made by cp"

# 4. The D3 pre-plugin paragraph, with its exception carried: brainstorm and improve YES, molt NO.
for f in skills/loop-brainstorm/SKILL.md skills/loop-improve/SKILL.md; do
  grep -qF '**Pre-plugin repo check.**' "$f" || fail "$f is missing the D3 pre-plugin detection paragraph (plan lines 158-163)"
  grep -qF 'config/repo-state.md' "$f" || fail "$f carries the D3 marker but not its config/repo-state.md detection clause"
done
if grep -qF '**Pre-plugin repo check.**' skills/loop-molt/SKILL.md; then
  fail "loop-molt/SKILL.md carries the D3 paragraph; step 15 says it must not, because it audits prose and not repo state"
fi

# 5. The D6 rubix-review stub, all four markers, in loop-brainstorm.
for m in '**Probe.**' '**Present:**' '**Absent:**' '**Disclose:**'; do
  grep -qF "$m" skills/loop-brainstorm/SKILL.md \
    || fail "loop-brainstorm/SKILL.md is missing the D6 stub marker $m (plan lines 273-280)"
done
grep -qF 'rubix-autorun' skills/loop-brainstorm/SKILL.md \
  || fail "loop-brainstorm/SKILL.md never names the rubix-autorun key the D6 stub gates on"
grep -qF 'docs/loop/pointer.md' skills/loop-brainstorm/SKILL.md \
  || fail "loop-brainstorm/SKILL.md still reads its keys from somewhere other than docs/loop/pointer.md"

# 6. The D5 harness-neutral house-style sentence replaces the ~/.claude/CLAUDE.md pointer.
grep -qF 'already loaded in this session' skills/loop-brainstorm/SKILL.md \
  || fail "loop-brainstorm/SKILL.md is missing the exact D5 house-style sentence (plan lines 232-234)"

# 7. Retired plumbing must be gone from the owned files.
for tok in 'scripts/tracker.sh' 'graduate-parking.sh' 'gen-mirrors.sh'; do
  hit=$(grep -rnF "$tok" skills/loop-brainstorm skills/loop-improve skills/loop-molt)
  [ -z "$hit" ] || fail "retired script still referenced ($tok), and Task 5 replaces it with direct tracker prose: $hit"
done
grep -rqF 'gh issue list' skills/loop-brainstorm \
  || fail "loop-brainstorm never names the direct 'gh issue list' call that replaces scripts/tracker.sh list"

# 8. The two known stragglers from the Check B pre-run, each with its allow-list escape carried.
if grep -rqF 'principles.md' skills/loop-brainstorm skills/loop-improve skills/loop-molt; then
  grep -qE '^[[:space:]]*principles\.md' "$ALW" \
    || fail "principles.md is still referenced and nothing in $ALW sanctions it; rewrite the prose or justify the append"
fi
bare=$(grep -n 'brief-pipeline\.md' skills/loop-improve/SKILL.md | grep -v 'references/brief-pipeline\.md')
if [ -n "$bare" ]; then
  grep -qE '^[[:space:]]*brief-pipeline\.md' "$ALW" \
    || fail "loop-improve/SKILL.md still carries a bare brief-pipeline.md that resolves nowhere: $bare"
fi

# 9. Frontmatter, per D7: name and description only, for all three skills.
check_fm skills/loop-brainstorm/SKILL.md name description
check_fm skills/loop-improve/SKILL.md name description
check_fm skills/loop-molt/SKILL.md name description

# 10. House style and the zero-executables constraint, over owned files only.
while IFS= read -r f; do
  if grep -qF "$EMDASH" "$f"; then fail "em dash character U+2014 in $f, banned by the global constraints"; fi
done <<EOF
$OWNED
EOF
execs=$(find skills/loop-brainstorm skills/loop-improve skills/loop-molt -type f -perm -u+x)
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

# 12. The NOTES contract.
[ -s NOTES ] || fail "./NOTES is missing or empty; the output contract requires it"
head -1 NOTES | grep -qE '^AGENT STATUS unit=u05 branch=worktree verdict=self-pass repairs=[0-9]+$' \
  || fail "./NOTES line 1 is not the required AGENT STATUS receipt: $(head -1 NOTES)"

# 13. The task's acceptance command, verbatim from source-plan line 794, exit code captured plainly.
bash ci/structure-check.sh && claude plugin validate --strict skills
rc=$?
[ "$rc" -eq 0 ] || fail "acceptance command 'bash ci/structure-check.sh && claude plugin validate --strict skills' exited $rc"

# 14. Export the deliverable BEFORE the worktree is deleted.
git add -A
git diff --cached > /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u05.patch \
  || fail "patch export failed"
[ -s /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u05.patch ] \
  || fail "patch export is empty: no work to harvest"
echo "PASS: u05-brainstorm-improve-molt"
