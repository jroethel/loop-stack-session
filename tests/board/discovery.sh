#!/usr/bin/env bash
# board.sh discover walks roots to depth 2, emits 9-field rows only for included git repos,
# excludes clean third-party clones (HTTPS and SSH remotes), includes dirty ones, and reports
# non-git dirs as skip comments.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkrepo() { mkdir -p "$1"; git -C "$1" init -q; git -C "$1" config user.email a@b.c; git -C "$1" config user.name t; }
commit() { ( cd "$1"; echo x > f; git add f; git commit -qm c ); }

root="$tmp/create"
mkrepo "$root/conforming"; mkdir -p "$root/conforming/config"; echo k > "$root/conforming/config/repo-state.md"; commit "$root/conforming"
mkrepo "$root/mine"; git -C "$root/mine" remote add origin https://github.com/jroethel/mine.git; commit "$root/mine"
mkrepo "$root/mine-ssh"; git -C "$root/mine-ssh" remote add origin git@github.com:jroethel/x.git; commit "$root/mine-ssh"
mkrepo "$root/thirdparty"; git -C "$root/thirdparty" remote add origin https://github.com/someoneelse/lib.git; commit "$root/thirdparty"
mkrepo "$root/tp-ssh"; git -C "$root/tp-ssh" remote add origin git@github.com:someoneelse/lib.git; commit "$root/tp-ssh"
mkrepo "$root/dirty"; git -C "$root/dirty" remote add origin https://github.com/someoneelse/dirty.git; commit "$root/dirty"; echo change >> "$root/dirty/f"
mkdir -p "$root/notgit"                                  # non-git dir, must be skipped and counted
mkdir -p "$root/nest/deep"; mkrepo "$root/nest/deep"; git -C "$root/nest/deep" remote add origin git@github.com:jroethel/deep.git; commit "$root/nest/deep"

# HOME is pointed at the fixture: keys are $HOME-relative by contract, and a scan root outside
# $HOME keys absolute (the renderer resolves a resume `cd` from the key)
out="$(HOME="$tmp" LOOP_BOARD_ROOTS="$root" LOOP_BOARD_OWNER=jroethel bash "$REPO/scripts/board.sh" discover 2>"$tmp/err")" || fail "discover exited non-zero"

field() { awk -F'\t' -v k="$1" -v c="$2" '$2==k{print $c}' <<<"$out"; }
grep -q "create/conforming" <<<"$out" || fail "conforming repo missing"
[ "$(field create/conforming 4)" = yes ] || fail "conforming flag wrong"
grep -q "create/mine" <<<"$out" || fail "https owner-matched repo missing"
grep -q "create/mine-ssh" <<<"$out" || fail "ssh owner-matched repo missing"
grep -q "create/thirdparty" <<<"$out" && fail "clean https third-party clone should be excluded"
grep -q "create/tp-ssh" <<<"$out" && fail "clean ssh third-party clone should be excluded"
grep -q "create/dirty" <<<"$out" || fail "dirty third-party clone should be included (uncommitted)"
[ "$(field create/dirty 7)" -ge 1 ] || fail "uncommitted count not reported"
grep -q "create/nest/deep" <<<"$out" || fail "depth-2 repo missing"
awk -F'\t' 'NF!=9{exit 3}' <<<"$out" || fail "a row does not have 9 fields"

# a scan root outside $HOME keys by absolute path, never a root-relative key the renderer would
# then resolve against the wrong $HOME
out2="$(HOME="$tmp/elsewhere" LOOP_BOARD_ROOTS="$root" LOOP_BOARD_OWNER=jroethel bash "$REPO/scripts/board.sh" discover 2>/dev/null)"
awk -F'\t' -v k="$root/conforming" '$2==k{f=1} END{exit f?0:1}' <<<"$out2" \
  || fail "a repo under a non-\$HOME scan root must key by absolute path"
grep -qE 'skipped: [0-9]+ non-git' "$tmp/err" || fail "non-git dirs not reported to stderr"
echo "PASS: discovery includes/excludes correctly over https+ssh, 9 fields, skip count reported"
