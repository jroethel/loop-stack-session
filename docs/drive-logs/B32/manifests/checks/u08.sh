#!/usr/bin/env bash
# Check for U08 (loop-setup vNext). Authored by the orchestrator; the worker does not own this file.
# U08 is a check-custody exception: it owns tests/local-mode-grammar.sh and its acceptance command
# runs it, so this check audits that test for vacuity before it trusts the test's own verdict.
set -uo pipefail
fail() { echo "CHECK FAIL: $*" >&2; exit 1; }
TASKDIR="${TASKDIR:-$PWD}"
cd "$TASKDIR" || fail "no worktree at $TASKDIR"

ALW=ci/reference-allowlist.txt
EMDASH=$(printf '\xe2\x80\x94')
SKILL=skills/loop-setup/SKILL.md
TPL=skills/loop-setup/references/pointer-templates.md
TRIAGE=skills/loop-setup/references/import-triage.md
GRAMMAR=tests/local-mode-grammar.sh

fm_keys() {
  awk 'NR==1 { if ($0 != "---") exit; next } /^---[[:space:]]*$/ { exit } /^[A-Za-z][A-Za-z0-9_-]*:/ { sub(/:.*/, ""); print }' "$1"
}

OWNED="skills/loop-setup/SKILL.md
skills/loop-setup/references/import-triage.md
skills/loop-setup/references/pointer-templates.md
tests/fixtures/pre-plugin-repo/config/repo-state.md
tests/fixtures/pre-plugin-repo/README.md
tests/local-mode-grammar.sh"

# 1. Ownership audit, over OWNED files only. NOTES is the one sanctioned unowned file.
changed=$(git status --porcelain | awk '{print $NF}')
for f in $changed; do
  case "$f" in
    skills/loop-setup/*|tests/fixtures/pre-plugin-repo/*|tests/local-mode-grammar.sh|ci/reference-allowlist.txt|NOTES) ;;
    *) fail "scope violation: $f is outside U08's ownership list (loop-setup, the fixture, the grammar test, the allow-list append, NOTES)" ;;
  esac
done

# 2. All six deliverables exist and are non-trivial.
while IFS= read -r f; do
  [ -s "$f" ] || fail "missing or empty deliverable: $f"
done <<EOF
$OWNED
EOF
[ -e skills/loop-setup/setup.sh ] && fail "setup.sh was copied in; step 2 says its 556 lines die with this port"
[ -e tests/fixtures/pre-plugin-repo/docs/loop/pointer.md ] \
  && fail "the pre-plugin fixture gained a docs/loop/pointer.md, which destroys the only thing the fixture proves"

# 3. VACUITY AUDIT OF THE SELF-OWNED TEST, against source-plan line 930.
grep -q 'set -uo pipefail' "$GRAMMAR" || fail "$GRAMMAR is missing 'set -uo pipefail'"
grep -qE 'fail *\(\)' "$GRAMMAR" || fail "$GRAMMAR is missing a fail() helper"
grep -qF 'PASS: local-mode grammar round-trip' "$GRAMMAR" \
  || fail "$GRAMMAR does not print the required 'PASS: local-mode grammar round-trip' line"
grep -qF 'mktemp' "$GRAMMAR" || fail "$GRAMMAR does not build its document in a mktemp -d; it must not write into the repo"
grep -qF 'next-number' "$GRAMMAR" || fail "$GRAMMAR never exercises the <!-- next-number: N --> marker rule from D4"
grep -qF '> receipt' "$GRAMMAR" || fail "$GRAMMAR never appends a '> receipt <UTC ISO-8601>: <text>' line as D4 requires"
grep -qF 'state:' "$GRAMMAR" || fail "$GRAMMAR never asserts the D4 state: field"
grep -qF 'labels:' "$GRAMMAR" || fail "$GRAMMAR never asserts the D4 labels: field"
net=$(grep -nE '(^|[[:space:];&|(])(gh|glab|curl|wget)[[:space:]]' "$GRAMMAR")
[ -z "$net" ] || fail "$GRAMMAR is specified as a pure-file test with no network and no tracker, but it calls out: $net"
failpaths=$(grep -cE '(fail |exit 1)' "$GRAMMAR")
[ "$failpaths" -ge 4 ] \
  || fail "$GRAMMAR has only $failpaths failure paths; D4 has four grammar rules and each needs its own, printing WHY"
# The '|| true' exception is carried: only lines that OPEN with an assertion construct are judged.
vacuous=$(grep -nE '^[[:space:]]*(\[|test |assert|grep |cmp |diff ).*\|\|[[:space:]]*true[[:space:]]*$' "$GRAMMAR")
[ -z "$vacuous" ] || fail "assertion neutered with '|| true' in $GRAMMAR: $vacuous"

# 4. loop-setup writes files itself: the managed section, the import, and the label block (steps 3, 7, 8).
grep -qF '<!-- jrit-loop:begin -->' "$SKILL" || fail "$SKILL is missing the AGENTS.md managed-section begin marker"
grep -qF '<!-- jrit-loop:end -->' "$SKILL" || fail "$SKILL is missing the AGENTS.md managed-section end marker"
grep -qF '@AGENTS.md' "$SKILL" || fail "$SKILL never writes the one-line @AGENTS.md import into CLAUDE.md (step 8)"
grep -qF 'gh label create' "$SKILL" || fail "$SKILL is missing the label-provisioning command block that Gate 0 quotes verbatim"
for lbl in idea agent:todo agent:working agent:needs-input agent:review agent:done wayfinder:map; do
  grep -qF "$lbl" "$SKILL" || fail "$SKILL's label block omits '$lbl'; the set is exactly seven and the helper depends on all of them"
done
grep -qF 'glab label create' "$SKILL" || fail "$SKILL provisions labels in github mode only; gitlab mode needs the glab equivalent"

# 5. The migration path, and the sanctioned naming of the mirrors it deletes (step 9).
grep -qi 'Migrating a pre-plugin repo' "$SKILL" || fail "$SKILL has no '## Migrating a pre-plugin repo' section (step 9)"
for m in ISSUES.md BACKLOG.md WAYFINDER.md docs/chain-state.md; do
  grep -qF "$m" "$SKILL" || fail "$SKILL's migration section never names $m, which it must list before deleting"
done
# Exception carried: this is the one file where docs/chain-state.md is allowed, because it is named to be deleted.
grep -qF 'config/repo-state.md' "$SKILL" || fail "$SKILL's migration never detects the old config/repo-state.md"

# 6. loop-setup does NOT carry the D3 paragraph (step 15), because it owns the migration itself.
if grep -qF '**Pre-plugin repo check.**' "$SKILL"; then
  fail "$SKILL carries the D3 detection paragraph; step 15 says it must not, because loop-setup owns the migration"
fi

# 7. Frontmatter, per D7 and step 14: name and description only, and the description is rewritten.
keys=$(fm_keys "$SKILL")
[ -n "$keys" ] || fail "$SKILL has no leading YAML frontmatter block"
for k in $keys; do
  case "$k" in
    name|description) ;;
    *) fail "$SKILL frontmatter carries key '$k'; D7 allows only name and description here" ;;
  esac
done
desc=$(awk 'NR==1 { if ($0 != "---") exit; next } /^---[[:space:]]*$/ { exit } /^description:/ { found=1 } found { print }' "$SKILL")
[ -n "$desc" ] || fail "$SKILL frontmatter has no description key"
for stale in 'config/repo-state.md' 'config/conventions.md' 'finalize'; do
  if printf '%s\n' "$desc" | grep -qF "$stale"; then
    fail "$SKILL's description still mentions '$stale'; step 14 requires it to name the two pointer docs and the managed section instead"
  fi
done

# 8. pointer-templates.md carries the D2 template and the D4 grammar, verbatim (step 6).
for k in 'pointer-version:' 'tracker:' 'autonomy-default:' 'rubix-autorun:' 'local-issues-file:'; do
  grep -qF "$k" "$TPL" || fail "$TPL is missing the D2 pointer-doc key $k"
done
grep -qF 'next-number' "$TPL" || fail "$TPL is missing the D4 <!-- next-number: N --> marker rule"
grep -qF '> receipt' "$TPL" || fail "$TPL is missing the D4 '> receipt <UTC ISO-8601>: <text>' comment shape"

# 9. import-triage.md: retired plumbing gone, direct tracker prose in (step 10 and step 11).
for tok in 'scripts/tracker.sh' 'gen-mirrors.sh' 'migrate-tracker.sh'; do
  if grep -qF "$tok" "$TRIAGE"; then fail "$TRIAGE still references $tok, which steps 10 and 11 delete"; fi
  if grep -qF "$tok" "$SKILL"; then fail "$SKILL still references $tok, which steps 10 and 11 delete"; fi
done
grep -qF 'issue create' "$TRIAGE" || fail "$TRIAGE never names the direct gh/glab issue create that replaces scripts/tracker.sh create"
grep -qF 'docs/loop/conventions.md' "$TRIAGE" || fail "$TRIAGE still points at config/conventions.md instead of docs/loop/conventions.md"
grep -qF 'scripts/pull.sh' "$TRIAGE" \
  || fail "$TRIAGE lost the illustrative scripts/pull.sh:42 example, which step 10 says to leave untouched"

# 10. The pre-plugin fixture is a real old-format repo (step 13).
FIX=tests/fixtures/pre-plugin-repo/config/repo-state.md
for k in 'template-version' 'rubix-autorun' 'tracker: github'; do
  grep -qF "$k" "$FIX" || fail "$FIX is missing the old-format key '$k' the migration reads"
done
for m in ISSUES.md BACKLOG.md; do
  grep -qF "$m" "$FIX" || fail "$FIX's Lanes table does not name $m as a mirror, so the fixture does not represent a pre-plugin repo"
done
grep -qi 'pointer' tests/fixtures/pre-plugin-repo/README.md \
  || fail "the fixture README does not state that this directory must never gain a docs/loop/pointer.md"

# 11. House style and the zero-executables constraint (step 16), over owned files only.
for f in "$SKILL" "$TPL" "$TRIAGE" "$FIX" tests/fixtures/pre-plugin-repo/README.md; do
  if grep -qF "$EMDASH" "$f"; then fail "em dash character U+2014 in $f, banned by the global constraints"; fi
done
execs=$(find skills/loop-setup -type f -perm -u+x)
[ -z "$execs" ] || fail "executable files under skills/loop-setup, which ships zero executables: $execs"

# 12. Allow-list discipline: appends only, each appended line carrying a trailing '# why'.
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

# 13. The NOTES contract.
[ -s NOTES ] || fail "./NOTES is missing or empty; the output contract requires it"
head -1 NOTES | grep -qE '^AGENT STATUS unit=u08 branch=worktree verdict=self-pass repairs=[0-9]+$' \
  || fail "./NOTES line 1 is not the required AGENT STATUS receipt: $(head -1 NOTES)"

# 14. The task's acceptance command, verbatim from source-plan line 913, exit code captured plainly.
bash ci/structure-check.sh && claude plugin validate --strict skills && bash tests/local-mode-grammar.sh && bash -c 'grep -q "jrit-loop:begin" skills/loop-setup/SKILL.md && grep -q "@AGENTS.md" skills/loop-setup/SKILL.md && grep -q "gh label create" skills/loop-setup/SKILL.md && grep -q "next-number" skills/loop-setup/references/pointer-templates.md && test -f tests/fixtures/pre-plugin-repo/config/repo-state.md && test ! -f tests/fixtures/pre-plugin-repo/docs/loop/pointer.md && test -z "$(find skills/loop-setup -type f -perm -u+x)"'
rc=$?
[ "$rc" -eq 0 ] || fail "acceptance command (source-plan line 913) exited $rc"

# 15. Export the deliverable BEFORE the worktree is deleted.
git add -A
git diff --cached > /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u08.patch \
  || fail "patch export failed"
[ -s /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u08.patch ] \
  || fail "patch export is empty: no work to harvest"
echo "PASS: u08-loop-setup"
