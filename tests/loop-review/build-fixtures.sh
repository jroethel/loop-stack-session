#!/usr/bin/env bash
# Builds two fixture repos under $1: "with-spec" and "no-spec".
# Base commit is tagged 'base' and does NOT contain parse_amount, so the HEAD
# commit's guard-less parse_amount is part of the reviewed diff base...HEAD.
set -euo pipefail
ROOT="${1:?usage: build-fixtures.sh <tmpdir>}"

seed_repo() {
  # $1 = repo dir, $2 = "with-spec" | "no-spec"
  local dir="$1" mode="$2"
  mkdir -p "$dir/src"
  git -C "$dir" init -q
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name test
  # base: a stub with NO parse_amount, so parse_amount (and its missing guard) is added in the diff.
  printf 'def cli(args):\n    return None\n' > "$dir/src/money.py"
  git -C "$dir" add -A
  git -C "$dir" commit -q -m "base: cli stub"
  git -C "$dir" tag base
  if [ "$mode" = with-spec ]; then
    # Branch name contains the plan's topic slug ("money") so branch-match resolves.
    git -C "$dir" checkout -q -b money-cli
    mkdir -p "$dir/docs/plans"
    cat > "$dir/docs/plans/2099-01-01-money-plan.md" <<'SPEC'
# Money Plan
- parse_amount MUST reject negative inputs by raising ValueError.
- Add a --verbose flag to the CLI.
SPEC
    # A NEWER, unrelated plan: most-recent-by-date would wrongly pick this;
    # branch-match must still resolve the money plan, not this decoy.
    cat > "$dir/docs/plans/2099-02-01-widget-plan.md" <<'SPEC2'
# Widget Plan
- Add a Widget renderer.
SPEC2
    git -C "$dir" add -A
    git -C "$dir" commit -q -m "spec: money + widget plans"
  else
    git -C "$dir" checkout -q -b work   # non-matching branch, no docs/ at all
  fi
  # HEAD: the change under review. All three defects are inside base...HEAD:
  #  - parse_amount added WITHOUT the required negative guard  (missing req -> Spec)
  #  - an unrequested --export-json flag                       (scope creep -> Spec)
  #  - a Mysterious Name `d`                                   (smell       -> Standards)
  cat > "$dir/src/money.py" <<'CODE'
def parse_amount(s):
    return int(s)

def d(x):
    return x * 100

def cli(args):
    if "--export-json" in args:
        return "{}"
    return d(parse_amount(args[0]))
CODE
  git -C "$dir" add -A
  git -C "$dir" commit -q -m "feat: parse_amount + cli"
}

seed_repo "$ROOT/with-spec" with-spec
seed_repo "$ROOT/no-spec" no-spec
