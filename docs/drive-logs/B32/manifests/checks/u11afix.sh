#!/usr/bin/env bash
# Check for U11AFIX. Authored by the orchestrator; the worker does not own this file.
set -uo pipefail
fail() { echo "CHECK FAIL: $*" >&2; exit 1; }
CMDS=/home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/u11a-sweep-commands.md
[ -s "$CMDS" ] || fail "packet missing at $CMDS"
grep -qE 'n3=\$\(gh issue list' "$CMDS" && fail "the sort-dependent n3 capture still exists in the packet"
grep -qE 'url3?=\$\(gh issue transfer[[:space:]]+3[[:space:]]' "$CMDS" || fail "no solo #3 transfer capturing its stdout URL"
loopnums=$(sed -n '/^for[[:space:]]/s/[^0-9 ]/ /gp' "$CMDS" | tr ' ' '\n' | grep -E '^[0-9]+$' | sort -un | tr '\n' ' ')
echo "loop numbers: $loopnums"
echo "$loopnums" | grep -qE '(^| )3( |$)' && fail "#3 is still inside a transfer loop; it must transfer solo"
tnums=$( { grep -oE 'gh issue transfer[[:space:]]+[0-9]+' "$CMDS" | grep -oE '[0-9]+$'; echo "$loopnums" | tr ' ' '\n'; } | grep -E '^[0-9]+$' | sort -un | tr '\n' ' ')
[ "$tnums" = "3 7 15 18 28 33 36 40 45 48 51 56 61 62 63 64 " ] || fail "transfer union is [$tnums], not the sixteen D12 requires"
grep -q 'u11b-transfer-urls.txt' "$CMDS" || fail "no URL-capture file staged for the migration map's pending cells"
grep -c '^```' "$CMDS" | awk '{ if ($1 < 6) exit 1 }' || fail "packet is not split into at least three fenced blocks (found fewer than 6 fence lines)"
grep -qiE 'stop.*(verify|confirm).*#?7|verify.*#?7.*(before|then).*(continue|proceed)' "$CMDS" || fail "no explicit stop-and-verify instruction between the dry-run and the loop"
grep -qF -- '--reason "not planned"' "$CMDS" || fail "close commands lost their --reason"
grep -qF 'user-invoked slash commands only' "$CMDS" || fail "#3 verbatim migration note lost"
grep -qF 'git rm --cached ISSUES.md BACKLOG.md WAYFINDER.md' "$CMDS" || fail "step-12 mirror deletion lost"
for lbl in idea agent:todo agent:working agent:needs-input agent:review agent:done wayfinder:map; do
  grep -E 'label create' "$CMDS" | grep -qF "$lbl" || fail "label provisioning lost: $lbl"
done
for n in 44 52 53 54 55; do
  grep -qE "gh issue comment[[:space:]]+${n}([^0-9]|$)" "$CMDS" || fail "stay-open comment lost on #$n"
done
open=$(gh issue list -R jroethel/loop-stack-session --state open --limit 100 --json number -q 'length' 2>&1) || fail "cannot read tracker: $open"
[ "$open" = "24" ] || fail "loop-stack-session shows $open open, not 24: a mutation happened"
mig=$(gh issue list -R jroethel/jrit-loop --state all --limit 100 --json number -q 'length' 2>&1) || fail "cannot read jrit-loop tracker: $mig"
[ "$mig" = "0" ] || fail "jrit-loop holds $mig issues: a transfer happened"
EMDASH=$(printf '\xe2\x80\x94'); grep -qF "$EMDASH" "$CMDS" && fail "em dash in the packet"
[ -s /home/jjrdar/repos/loop-stack-session/docs/drive-logs/B32/unit-11afix.md ] || fail "unit log missing"
echo "PASS: u11afix"
