#!/usr/bin/env bash
# migrate-tracker.sh omits --label entirely for an unlabeled local issue, and keeps it for a labeled one.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
M="$REPO/scripts/migrate-tracker.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
[ -x "$M" ] || fail "scripts/migrate-tracker.sh missing or not executable"

SB="$(mktemp -d)"; trap 'rm -rf "$SB"' EXIT
mkdir -p "$SB/docs/issues" "$SB/config"
printf 'tracker: local\n' > "$SB/config/repo-state.md"
# Unlabeled issue: the Issues lane's defined shape (empty labels:).
cat > "$SB/docs/issues/001-unlabeled.md" <<'EOS'
---
number: 1
title: unlabeled issue
labels:
state: open
updated: 2026-08-04T00:00:00Z
---
An issue with no labels.
EOS
# Labeled issue: proves the fix is selective, not a blanket drop of --label.
cat > "$SB/docs/issues/002-labeled.md" <<'EOS'
---
number: 2
title: labeled issue
labels: bug
state: open
updated: 2026-08-04T00:00:00Z
---
An issue with a label.
EOS

out="$( cd "$SB" && MIGRATE_DRY_RUN=1 bash "$M" )" || fail "migrate dry-run exited non-zero"
# The unlabeled issue's create line must carry no --label at all.
un_line="$(printf '%s\n' "$out" | grep 'gh issue create' | grep 'unlabeled issue')"
[ -n "$un_line" ] || fail "no create line emitted for the unlabeled issue"
printf '%s\n' "$un_line" | grep -q -- '--label' \
  && fail "unlabeled issue create still carries a --label argument"
# The labeled issue keeps its --label.
lb_line="$(printf '%s\n' "$out" | grep 'gh issue create' | grep 'labeled issue')"
printf '%s\n' "$lb_line" | grep -q -- "--label 'bug'" \
  || fail "labeled issue lost its --label 'bug' argument"

echo "PASS: migrate-tracker omits --label for unlabeled issues and preserves it for labeled ones"
