#!/usr/bin/env bash
# Check for U11a (stage the tracker sweep, Task 11 steps 1-3). Authored by the orchestrator; the worker does not own this file.
# This unit stages a bulk mutation and fires none of it, so the check proves two things:
# the staged command list is complete and correctly qualified, and the live trackers are untouched.
set -uo pipefail
fail() { echo "CHECK FAIL: $*" >&2; exit 1; }
TASKDIR="${TASKDIR:-$PWD}"
cd "$TASKDIR" || fail "no worktree at $TASKDIR"

LOGDIR=/home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32
CMDS="$LOGDIR/u11a-sweep-commands.md"
SNAP="$LOGDIR/u11a-lss-open-before.json"
MAP=docs/issue-migration-map.md
EMDASH=$(printf '\xe2\x80\x94')
TRANSFERS="7 15 18 28 40 48 51 56 45 33 61 62 63 64 36 3"

# 1. Ownership audit: this unit writes exactly one file into the jrit-loop working tree.
changed=$(git status --porcelain | awk '{print $NF}')
for f in $changed; do
  case "$f" in
    docs/issue-migration-map.md|NOTES) ;;
    *) fail "scope violation: $f is outside U11a's ownership list, which is docs/issue-migration-map.md and NOTES only" ;;
  esac
done

# 2. The three artifacts exist and are non-trivial.
[ -s "$CMDS" ] || fail "missing or empty C8 command list at $CMDS"
[ -s "$SNAP" ] || fail "missing or empty live snapshot at $SNAP"
[ -s "$MAP" ] || fail "missing or empty migration map at $MAP"

# 3. The snapshot is the live starting state, 24 open issues (source-plan step 1, verified fact line 59).
snapcount=$(jq 'length' "$SNAP" 2>&1) || fail "snapshot at $SNAP is not valid JSON: $snapcount"
[ "$snapcount" = "24" ] \
  || fail "snapshot holds $snapcount issues, not the 24 the plan and the verified facts both record; the dispositions must be re-derived against the live list"

# 4. The transfer set is exactly D12's sixteen, however the list spells the loop.
tnums=$( { grep -oE 'gh issue transfer[[:space:]]+[0-9]+' "$CMDS" | grep -oE '[0-9]+$'
           grep -E '^[[:space:]]*for[[:space:]]+[A-Za-z_]+[[:space:]]+in[[:space:]]' "$CMDS" | grep -oE '[0-9]+'
         } | sort -un | tr '\n' ' ')
expected=$(printf '%s\n' $TRANSFERS | sort -un | tr '\n' ' ')
[ "$tnums" = "$expected" ] \
  || fail "staged transfer set is [$tnums] but D12 lines 404-406 require exactly sixteen: [$expected]"

# 5. Every transfer command is qualified on both ends. The -R source is load-bearing (step 5).
grep -q 'gh issue transfer' "$CMDS" || fail "$CMDS stages no gh issue transfer command at all"
badsrc=$(grep -n 'gh issue transfer' "$CMDS" | grep -v 'jroethel/loop-stack-session')
[ -z "$badsrc" ] \
  || fail "transfer command without the load-bearing -R jroethel/loop-stack-session source qualifier: $badsrc"
baddst=$(grep -n 'gh issue transfer' "$CMDS" | grep -v 'jroethel/jrit-loop')
[ -z "$baddst" ] || fail "transfer command that does not name jroethel/jrit-loop as the destination: $baddst"

# 6. The closes are exactly three, on exactly #39, #47 and #32, each with its reason.
closenums=$(grep -oE 'gh issue close[[:space:]]+[0-9]+' "$CMDS" | grep -oE '[0-9]+$' | sort -un | tr '\n' ' ')
[ "$closenums" = "32 39 47 " ] \
  || fail "staged close set is [$closenums] but D12 lines 407-408 require exactly three: [32 39 47 ]"
badreason=$(grep -n 'gh issue close' "$CMDS" | grep -v 'not planned')
[ -z "$badreason" ] || fail "close command missing --reason \"not planned\": $badreason"

# 7. The label provisioning of the destination (step 4), all seven.
for lbl in idea agent:todo agent:working agent:needs-input agent:review agent:done wayfinder:map; do
  grep -E 'label create' "$CMDS" | grep -qF "$lbl" \
    || fail "$CMDS never stages 'gh label create' for the label '$lbl' on the destination repo"
done

# 8. The five issues that stay open each get their comment (steps 9, 10, 11).
for n in 44 52 53 54 55; do
  grep -qE "gh issue comment[[:space:]]+${n}([^0-9]|$)" "$CMDS" \
    || fail "no comment staged on #$n, which stays open and must be annotated so a later sweep does not re-dispose it"
done

# 9. The #3 migration note, verbatim (step 6), and the step-12 mirror deletion in its narrowed form.
grep -qF 'user-invoked slash commands only' "$CMDS" \
  || fail "$CMDS does not carry #3's verbatim migration note about /goal and /loop"
grep -qF 'git rm --cached ISSUES.md BACKLOG.md WAYFINDER.md' "$CMDS" \
  || fail "$CMDS does not stage the step-12 mirror deletion in the explicit 'git rm --cached ISSUES.md BACKLOG.md WAYFINDER.md' form"

# 10. The migration map is a real skeleton: one row per migrated issue, new URL marked pending.
for n in $TRANSFERS; do
  grep -qE "^\|[[:space:]]*#?${n}[[:space:]]*\|" "$MAP" \
    || fail "migration map has no row for old issue #$n; sixteen renumbered issues with no record is sixteen dead cross-references"
done
grep -qi 'pending' "$MAP" || fail "migration map does not mark the new-URL column as pending; U11b fills it at transfer time"

# 11. ZERO MUTATIONS. This is the assertion the unit exists to satisfy.
open=$(gh issue list -R jroethel/loop-stack-session --state open --limit 100 --json number -q 'length' 2>&1) \
  || fail "could not read the loop-stack-session tracker, so the no-mutation claim is unproven: $open"
[ "$open" = "24" ] \
  || fail "loop-stack-session now shows $open open issues, not 24: U11a is staging only and any mutation is an immediate fail"
for n in 39 47 32; do
  s=$(gh issue view "$n" -R jroethel/loop-stack-session --json state -q .state 2>&1) \
    || fail "could not read the state of loop-stack-session #$n: $s"
  [ "$s" = "OPEN" ] \
    || fail "loop-stack-session #$n is $s, not OPEN: U11a staged a close instead of leaving it for C8"
done
mig=$(gh issue list -R jroethel/jrit-loop --state all --limit 100 --json number -q 'length' 2>&1) \
  || fail "could not read the jrit-loop tracker, so the no-mutation claim is unproven: $mig"
[ "$mig" = "0" ] \
  || fail "jrit-loop already holds $mig issues: U11a transferred something it was forbidden to transfer"

# 12. The NOTES contract, including the explicit mutation count.
[ -s NOTES ] || fail "./NOTES is missing or empty; the output contract requires it"
head -1 NOTES | grep -qE '^AGENT STATUS unit=u11a branch=worktree verdict=self-pass repairs=[0-9]+$' \
  || fail "./NOTES line 1 is not the required AGENT STATUS receipt: $(head -1 NOTES)"
grep -qF 'MUTATIONS EXECUTED: 0' NOTES \
  || fail "./NOTES does not carry the required 'MUTATIONS EXECUTED: 0' line"

# 13. House style over the files this unit wrote.
for f in "$CMDS" "$MAP"; do
  if grep -qF "$EMDASH" "$f"; then fail "em dash character U+2014 in $f, banned by the global constraints"; fi
done

# 14. Export the deliverable BEFORE the worktree is deleted.
git add -A
git diff --cached > /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u11a.patch \
  || fail "patch export failed"
[ -s /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/patches/u11a.patch ] \
  || fail "patch export is empty: no work to harvest"
echo "PASS: u11a-sweep-staging"
