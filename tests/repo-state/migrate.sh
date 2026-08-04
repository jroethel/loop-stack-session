#!/usr/bin/env bash
# migrate-tracker.sh: dry-run emits one gh issue create per local issue, title/body/labels preserved.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
M="$REPO/scripts/migrate-tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$M" ] || fail "scripts/migrate-tracker.sh missing or not executable"

SB="$(mktemp -d)"; trap 'rm -rf "$SB"' EXIT
mkdir -p "$SB/docs/issues" "$SB/config"
printf 'tracker: local\n' > "$SB/config/repo-state.md"
cat > "$SB/docs/issues/001-crash-on-empty-input.md" <<'EOS'
---
number: 1
title: crash on empty input
labels: bug
state: open
updated: 2026-08-04T00:00:00Z
---
Steps to reproduce the crash.
EOS
cat > "$SB/docs/issues/002-vault-backlog-view.md" <<'EOS'
---
number: 2
title: vault backlog view
labels: idea
state: closed
updated: 2026-08-04T00:00:00Z
---
A closed idea, should still migrate then close.
EOS

out="$( cd "$SB" && MIGRATE_DRY_RUN=1 bash "$M" )" || fail "migrate dry-run exited non-zero"
creates="$(printf '%s\n' "$out" | grep -c 'gh issue create')"
[ "$creates" -eq 2 ] || fail "expected 2 gh issue create commands (one per local issue), got $creates"
printf '%s\n' "$out" | grep -q 'crash on empty input' || fail "title of issue #1 not carried into migration"
printf '%s\n' "$out" | grep -q 'vault backlog view'   || fail "title of issue #2 not carried into migration"
printf '%s\n' "$out" | grep -q -- "--label 'bug'"  || fail "labels of issue #1 not preserved"
printf '%s\n' "$out" | grep -q -- "--label 'idea'" || fail "labels of issue #2 not preserved"
printf '%s\n' "$out" | grep -q 'gh issue close'  || fail "closed local issue #2 not re-closed after migration"
# labels must be ensured on the remote BEFORE the creates (gh issue create --label X fails on an undefined label)
lbl_ln="$(printf '%s\n' "$out" | grep -n 'gh label create bug' | head -1 | cut -d: -f1)"
crt_ln="$(printf '%s\n' "$out" | grep -n 'gh issue create'     | head -1 | cut -d: -f1)"
[ -n "$lbl_ln" ] || fail "dry-run did not emit a 'gh label create bug' ensure line"
[ "$lbl_ln" -lt "$crt_ln" ] || fail "label ensure was not emitted before the issue creates"
# dry-run must NOT flip the declared mode
grep -q '^tracker: local' "$SB/config/repo-state.md" || fail "dry-run wrongly changed the tracker key"

# --- resume after partial failure: a real run skips files already carrying migrated:, recreates only the rest ---
RB="$(mktemp -d)"; RBIN="$(mktemp -d)"; trap 'rm -rf "$SB" "$RB" "$RBIN"' EXIT
GHCALLS="$RBIN/gh.calls"
cat > "$RBIN/gh" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$GHCALLS"
case "\$1" in
  auth)  exit 0 ;;
  label) exit 0 ;;
  issue) [ "\$2" = create ] && { echo "https://github.com/x/y/issues/50"; exit 0; }; exit 0 ;;
esac
exit 0
EOF
chmod +x "$RBIN/gh"
mkdir -p "$RB/docs/issues" "$RB/config" "$RB/scripts"
printf 'tracker: local\n' > "$RB/config/repo-state.md"
cp "$REPO/scripts/tracker.sh" "$RB/scripts/tracker.sh"; chmod +x "$RB/scripts/tracker.sh"
cat > "$RB/docs/issues/001-already-done.md" <<'EOS'
---
number: 1
title: already migrated issue
labels: bug
state: open
migrated: https://github.com/x/y/issues/11
updated: 2026-08-04T00:00:00Z
---
body one
EOS
cat > "$RB/docs/issues/002-still-pending.md" <<'EOS'
---
number: 2
title: still pending issue
labels: bug
state: open
updated: 2026-08-04T00:00:00Z
---
body two
EOS
( cd "$RB" && PATH="$RBIN:$PATH" bash "$M" ) >/dev/null || fail "resume (real) migration exited non-zero"
grep -q 'already migrated issue' "$GHCALLS" && fail "resume recreated issue #1 which already carried migrated:"
grep -q 'still pending issue'    "$GHCALLS" || fail "resume did not create the un-migrated issue #2"
grep -q '^migrated:' "$RB/docs/issues/002-still-pending.md" || fail "resume did not stamp issue #2 after creating it"
echo "PASS: migrate-tracker dry-run emits one create per local issue with title/labels preserved, closes closed ones; resume skips stamped files"
