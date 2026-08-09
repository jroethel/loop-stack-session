#!/usr/bin/env bash
# tracker.sh gitlab backend: mode accepts gitlab, the auth guard is host-scoped, list translates
# glab JSON to the gh shape across pages, create returns the iid, close/reopen dispatch to glab.
# A stub glab on PATH records every invocation, so "never bare glab auth status" is provable.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
T="$REPO/scripts/tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$T" ] || fail "scripts/tracker.sh missing or not executable"

BIN="$(mktemp -d)"; SB="$(mktemp -d)"; trap 'rm -rf "$BIN" "$SB"' EXIT
LOG="$BIN/glab.calls"
GHLOG="$BIN/gh.calls"

# gh stub: records any call. gitlab mode must never touch gh; the github-mode block near the
# end of this file uses it to prove the empty-label fix applies to both remote backends.
cat > "$BIN/gh" <<'STUB'
#!/usr/bin/env bash
echo "GH CALLED: $*" >> "$GH_LOG"
[ "$1" = auth ] && exit 0
if [ "$1" = issue ] && [ "$2" = create ]; then
  echo "https://github.com/acme/x/issues/77"; exit 0
fi
exit 0
STUB
chmod +x "$BIN/gh"
export GH_LOG="$GHLOG"

# The --jq expression the implementation MUST pass. The stub only translates when it sees this
# string verbatim; any drift makes the stub emit RAW GitLab JSON instead, and every assertion
# below fails. Without this, a stub that pre-translates would pass no matter what filter the
# implementation used, and the brief's highest-risk claim would be untested.
EXPECTED_JQ='.[] | {number:.iid, title:.title, labels:[.labels[]|{name:.}], updatedAt:.updated_at}'

# glab stub. Records every invocation. Mimics the real CLI's contract:
#   auth status              -> exit 1 unless --hostname is supplied (the dead-token regression)
#   auth status --hostname H -> exit 0 for gitlab.example.com
#   issue list               -> RAW GitLab REST rows, translated only if --jq matches EXPECTED_JQ
#   issue create             -> a URL line whose last path segment is the new iid
#   issue close|reopen       -> exit 0
# Stub modes, set by the caller:
#   GLAB_PAGES=1   -> page 1 returns 100 rows, page 2 returns 3, page 3+ returns nothing
#   GLAB_FAIL=1    -> issue list exits 1 (to prove a hard failure is not swallowed into [])
# Quoted heredoc: nothing expands at write time, so no escaping. The stub reads its config
# from the environment at run time instead.
cat > "$BIN/glab" <<'STUB'
#!/usr/bin/env bash
echo "GLAB CALLED: $*" >> "$GLAB_LOG"
if [ "$1" = auth ] && [ "$2" = status ]; then
  for a in "$@"; do [ "$a" = --hostname ] && exit 0; done
  exit 1
fi
if [ "$1" = issue ] && [ "$2" = list ]; then
  [ "${GLAB_FAIL:-0}" = 1 ] && { echo "ERROR 500" >&2; exit 1; }
  page=1; jqexpr=""; prev=""
  for a in "$@"; do
    case "$prev" in -p|--page) page="$a" ;; --jq) jqexpr="$a" ;; esac
    prev="$a"
  done
  rows=""
  if [ "${GLAB_PAGES:-0}" = 1 ]; then
    case "$page" in
      1) rows="$(awk 'BEGIN{for(i=1;i<=100;i++) printf "%d\tbulk %d\t\n", i, i}')" ;;
      2) rows="$(awk 'BEGIN{for(i=101;i<=103;i++) printf "%d\ttail %d\t\n", i, i}')" ;;
    esac
  elif [ "$page" = 1 ]; then
    rows="$(printf '7\ta backlog item\tidea\n4\ta plain issue\t\n')"
  fi
  [ -n "$rows" ] || exit 0
  # Emit RAW GitLab REST shape, and translate ONLY on an exact --jq match. Any drift in the
  # implementation's filter leaves the raw shape, which every assertion below rejects.
  if [ "$jqexpr" = "$EXPECTED_JQ_ENV" ]; then
    printf '%s\n' "$rows" | awk -F'\t' '{
      lbl = ($3 == "") ? "" : "{\"name\":\"" $3 "\"}"
      printf "{\"number\":%s,\"title\":\"%s\",\"labels\":[%s],\"updatedAt\":\"2026-08-01T00:00:00Z\"}\n", $1, $2, lbl
    }'
  else
    printf '%s\n' "$rows" | awk -F'\t' '{
      lbl = ($3 == "") ? "" : "\"" $3 "\""
      printf "{\"id\":%d,\"iid\":%s,\"state\":\"opened\",\"title\":\"%s\",\"labels\":[%s],\"updated_at\":\"2026-08-01T00:00:00Z\"}\n", 9000+$1, $1, $2, lbl
    }'
  fi
  exit 0
fi
if [ "$1" = issue ] && [ "$2" = create ]; then
  echo "https://gitlab.example.com/grp/sub/repo/-/issues/42"
  exit 0
fi
if [ "$1" = issue ] && { [ "$2" = close ] || [ "$2" = reopen ]; }; then exit 0; fi
exit 0
STUB
chmod +x "$BIN/glab"
export PATH="$BIN:$PATH"
export GLAB_LOG="$LOG"
export EXPECTED_JQ_ENV="$EXPECTED_JQ"

cd "$SB" && git init -q && mkdir -p config
git remote add origin 'ssh://git@gitlab.example.com:2222/grp/sub/repo.git'

# --- mode: gitlab is a peer third value ---
[ "$("$T" mode set gitlab)" = "gitlab" ] || fail "mode set gitlab did not echo gitlab"
[ "$("$T" mode get)" = "gitlab" ]        || fail "mode get did not read back gitlab"
[ "$(grep -c '^tracker:' config/repo-state.md)" -eq 1 ] || fail "mode set duplicated the tracker: line"
"$T" mode set banana >/dev/null 2>&1 && fail "mode set accepted an unknown backend"

# --- list: gh-shaped translation, paginated, valid single-line array ---
out="$("$T" list)" || fail "list exited non-zero in gitlab mode"
[ "${out#\[}" != "$out" ] || fail "list output does not start with ["
[ "${out%\]}" != "$out" ] || fail "list output does not end with ]"
[ "$(printf '%s\n' "$out" | grep -c .)" -eq 1 ] || fail "list emitted more than one line"
printf '%s' "$out" | grep -q '"number":7'  || fail "list lost issue 7"
printf '%s' "$out" | grep -q '"number":4'  || fail "list lost issue 4"
printf '%s' "$out" | grep -q '"name":"idea"' || fail "list lost the idea label"
printf '%s' "$out" | grep -q '},{'         || fail "list did not comma-join the two rows"
printf '%s' "$out" | grep -q ',,'          && fail "list emitted an empty element"

# --- the RAW GitLab shape must never reach a consumer ---
# The stub only translates on an exact --jq match; these three assertions are what makes the
# translation expression itself the thing under test rather than the stub's generosity.
printf '%s' "$out" | grep -q '"iid"'        && fail "raw glab shape leaked through: --jq did not translate"
printf '%s' "$out" | grep -q '"updated_at"' && fail "raw updated_at leaked through instead of updatedAt"
printf '%s' "$out" | grep -q '"state"'      && fail "raw state field leaked into the gh-shaped output"
grep -qF -- "--jq $EXPECTED_JQ" "$LOG" \
  || fail "list did not pass the expected --jq translation expression verbatim"

# --- open-only is an ABSENCE of flags: glab issue list has no --state, and defaults to open ---
grep -qE -- '--all|(^| )-A( |$)'    "$LOG" && fail "list passed --all, which would include closed issues"
grep -qE -- '--closed|(^| )-c( |$)' "$LOG" && fail "list passed --closed"

# --- the auth guard is host-scoped and resolves the host from the remote ---
grep -q 'GLAB CALLED: auth status --hostname gitlab.example.com' "$LOG" \
  || fail "guard did not run a --hostname-scoped auth status"
grep -E 'GLAB CALLED: auth status$' "$LOG" \
  && fail "guard ran a BARE glab auth status (regression: a dead token on another host fails it)"

# --- list asked for 100 per page and started at page 1 ---
grep -q -- '--per-page 100' "$LOG" || fail "list did not request 100 items per page"
grep -q -- '--page 1'       "$LOG" || fail "list did not request page 1"

# --- pagination actually crosses a page boundary (100 on page 1, 3 on page 2, then stop) ---
: > "$LOG"
out="$(GLAB_PAGES=1 "$T" list)" || fail "paginated list exited non-zero"
[ "$(printf '%s' "$out" | grep -o '"number":' | wc -l)" -eq 103 ] \
  || fail "paginated list returned $(printf '%s' "$out" | grep -o '"number":' | wc -l) rows, expected 103"
printf '%s' "$out" | grep -q ',,' && fail "page join produced an empty element"
printf '%s' "$out" | grep -q '"number":100,' || fail "last row of page 1 was lost at the join"
printf '%s' "$out" | grep -q '"number":101,' || fail "first row of page 2 was lost at the join"
[ "$(printf '%s\n' "$out" | grep -c .)" -eq 1 ] || fail "paginated list emitted more than one line"
grep -q -- '--page 2' "$LOG" || fail "list did not request page 2 after a full page"
grep -q -- '--page 3' "$LOG" && fail "list requested page 3 after a short page (must stop)"

# --- a glab failure is a hard failure, never a silently empty array ---
: > "$LOG"
out="$(GLAB_FAIL=1 "$T" list 2>/dev/null)"; rc=$?
[ "$rc" -ne 0 ] || fail "list exited 0 when glab failed (an empty mirror would render with no error)"
[ "$out" = "[]" ] && fail "list printed [] on a glab failure instead of failing"

# --- create returns the bare iid parsed from the issue URL ---
n="$("$T" create --label idea --title "new thing" --body "some body")" \
  || fail "create exited non-zero in gitlab mode"
[ "$n" = "42" ] || fail "create returned '$n', expected the iid 42"
grep -q -- '--no-editor' "$LOG" || fail "create did not pass --no-editor (would block on an editor)"
grep -q -- '--yes'       "$LOG" || fail "create did not pass --yes (would block on a prompt)"

# --- create with an empty label must not pass a bare -l "" ---
: > "$LOG"
"$T" create --label "" --title "no label" --body b >/dev/null || fail "create failed with an empty label"
grep -qE -- "-l( |$)" "$LOG" && fail "create passed -l with an empty label value"

# --- close and reopen dispatch to glab with the iid ---
"$T" close 42  >/dev/null 2>&1 || fail "close exited non-zero in gitlab mode"
"$T" reopen 42 >/dev/null 2>&1 || fail "reopen exited non-zero in gitlab mode"
grep -q 'GLAB CALLED: issue close 42'  "$LOG" || fail "close did not call glab issue close 42"
grep -q 'GLAB CALLED: issue reopen 42' "$LOG" || fail "reopen did not call glab issue reopen 42"

# --- zero gh in gitlab mode (must be asserted BEFORE the github-mode block below) ---
[ -f "$GHLOG" ] && fail "gitlab mode invoked gh: $(cat "$GHLOG")"

# --- an unknown mode FAILS; it must never fall through to the local backend ---
"$T" mode set gitlab >/dev/null
sed -i.bak 's/^tracker: gitlab$/tracker: bitbucket/' config/repo-state.md
"$T" list   >/dev/null 2>&1 && fail "list silently accepted an unknown tracker mode"
"$T" create --label idea --title x --body y >/dev/null 2>&1 \
  && fail "create silently accepted an unknown tracker mode"
[ -d docs/issues ] && fail "an unknown mode fell through to the LOCAL backend and wrote docs/issues/"
"$T" mode set gitlab >/dev/null

# --- the empty-label fix applies to the github branch too, not just gitlab ---
"$T" mode set github >/dev/null
: > "$GHLOG"
n="$("$T" create --label "" --title "no label on github" --body b)" \
  || fail "github create failed with an empty label"
[ "$n" = "77" ] || fail "github create returned '$n', expected 77"
grep -qE -- '--label( |$)' "$GHLOG" && fail "github create passed --label with an empty value"
"$T" create --label idea --title "labelled" --body b >/dev/null || fail "github create failed with a label"
grep -q -- '--label idea' "$GHLOG" || fail "github create dropped a non-empty label"
"$T" mode set gitlab >/dev/null

# --- host and group derivation across all three remote URL forms ---
check_url() {  # $1 = url, $2 = expected host, $3 = expected group
  git remote set-url origin "$1"
  h="$("$T" host)"  || fail "host failed for $1"
  g="$("$T" group)" || fail "group failed for $1"
  [ "$h" = "$2" ] || fail "host for $1 was '$h', expected '$2'"
  [ "$g" = "$3" ] || fail "group for $1 was '$g', expected '$3'"
}
check_url 'ssh://git@gitlab.code.rit.edu:2222/university-advancement/crm/forge.git' \
          'gitlab.code.rit.edu' 'university-advancement'
check_url 'git@gitlab.example.com:grp/sub/repo.git' 'gitlab.example.com' 'grp'
check_url 'https://gitlab.example.com/grp/sub/repo.git' 'gitlab.example.com' 'grp'

echo "PASS: tracker gitlab backend"
